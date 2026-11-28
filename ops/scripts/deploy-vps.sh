#!/usr/bin/env bash
#
# deploy-vps.sh — automated deploy script for Qouver (spec: uniform with cbs & fond)
#
# Triggered by the repository push webhook through the webhook daemon (same
# trigger as the other apps), for the commit GitHub just pushed:
#   $1 = repository.name
#   $2 = ref
#   $3 = commit sha GitHub pushed (payload.after)
#
# This script copies itself mid-run and re-execs the copy just swapped in, so a
# fix merged to it applies in the same deploy, not one deploy later.
set -euo pipefail

REPO="${1:-qouver}"
REF="${2:-}"
TRIGGER_REV="${3:-}"

APP_DIR="${QOUVER_APP_DIR:-/srv/qouver/apps/qouver}"
MONO_DIR="$APP_DIR/monorepo"
BIN_DIR="$APP_DIR/bin"
LOG="$APP_DIR/logs/deploy.log"
STATE_FILE="$APP_DIR/.deployed_rev"
LOCK_FILE="$APP_DIR/.deploy.lock"
WEB_DIR="$APP_DIR/web"
HEALTH_URL="${QOUVER_HEALTH_URL:-http://127.0.0.1:8091/healthz}"

mkdir -p "$APP_DIR/logs" "$BIN_DIR" "$APP_DIR/env" "$APP_DIR/scripts"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }
die() { log "ERROR: $*"; exit 1; }

# The web container reports the revision it was built from in /healthz, so a
# restart that silently kept the old image is caught instead of passing.
WEB_HEALTH_URL="${QOUVER_WEB_HEALTH_URL:-http://127.0.0.1:8093/healthz}"
WEB_UNIT="qouver-web.container"

rollback_web() {
  if podman image exists localhost/qouver-web:prev; then
    log "==> Rollback web image: localhost/qouver-web:prev -> :local"
    podman tag localhost/qouver-web:prev localhost/qouver-web:local \
      && systemctl --user restart qouver-web 2>&1 | tee -a "$LOG" || true
  else
    log "==> Rollback web image skipped: no localhost/qouver-web:prev"
  fi
  if [ -d "$APP_DIR/web.prev" ]; then
    rm -rf "$APP_DIR/web"
    mv "$APP_DIR/web.prev" "$APP_DIR/web"
    restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
    log "==> Web assets restored from web.prev"
  fi
}

wait_healthy_web() {
  local want="$1" body rev part
  rev=""; part=""
  for _ in $(seq 1 15); do
    body=$(curl -fsS --max-time 3 "$WEB_HEALTH_URL" 2>/dev/null || true)
    if [ -n "$body" ]; then
      rev=$(printf '%s' "$body" | sed -n 's/.*"rev":"\([^"]*\)".*/\1/p')
      part=$(printf '%s' "$body" | sed -n 's/.*"part":"\([^"]*\)".*/\1/p')
      if [ "$part" = "web" ] && [ "$rev" = "$want" ]; then
        log "==> qouver-web healthy rev=$rev"
        return 0
      fi
    fi
    sleep 2
  done
  log "ERROR: $WEB_HEALTH_URL did not report rev=$want (got rev=${rev:-<empty>} part=${part:-<empty>}) — rolling the web image back and aborting"
  rollback_web
  exit 1
}

# CI publishes an image only after every gate job is green, and the push reaches
# this host before that. A tag that is not in the registry yet is therefore
# waited for, not read as "this half did not change": the single attempt used to
# keep the previous revision for good whenever the gate was slower than the
# webhook. Anything other than a missing tag (auth, network, 5xx) fails at once.
# 45 x 20s = 15 min covers gate + queue + build on a busy runner.
IMAGE_WAIT_ATTEMPTS="${QOUVER_IMAGE_WAIT_ATTEMPTS:-45}"

# 0 = pulled, 1 = still absent after the window, 2 = a real pull error
pull_when_published() {
  local ref="$1" out="$2" attempt=1
  while :; do
    if podman pull "$ref" >"$out" 2>&1; then return 0; fi
    if ! grep -qiE 'manifest unknown|no such manifest|manifest for .* not found|name unknown' "$out"; then
      return 2
    fi
    [ "$attempt" -lt "$IMAGE_WAIT_ATTEMPTS" ] || return 1
    log "==> $ref not in the registry yet (gate or image job still running), attempt $attempt of $IMAGE_WAIT_ATTEMPTS"
    attempt=$((attempt + 1))
    sleep 20
  done
}

# A tag is a file name until the bytes state their own digest. Resolve the digest
# of what was just pulled, then verify and tag that digest, so a tag moved
# between pull and verify cannot point the local tag at unverified bytes.
#
# One tag carries TWO digests: the multi-arch image index that CI signed, and the
# per-arch manifest podman resolved to. Their order in RepoDigests is not stable,
# so `head -1` was a coin flip — on 2026-11-16 in fond it picked the per-arch digest,
# cosign rejected it and the deploy aborted with the web left on the old image. The
# manifest list in the registry says which digests are its children (mediaType
# decides, not position); the index is the one left over. No index means an empty
# result and a loud failure in the caller — never a per-arch digest presented as
# the signed one.
INDEX_MEDIA_TYPES="application/vnd.oci.image.index.v1+json application/vnd.docker.distribution.manifest.list.v2+json"
pulled_digest() {
  local ref="$1" list media children cand index=""
  list="$(podman manifest inspect "$ref" 2>/dev/null || true)"
  media="$(printf '%s' "$list" | sed -n 's/.*"mediaType" *: *"\([^"]*\)".*/\1/p' | head -1)"
  case " $INDEX_MEDIA_TYPES " in
    *" ${media:-none} "*) ;;
    *) return 0 ;;
  esac
  # Index manifests hold no layer/config digests, only their children's.
  # The same digest is recorded under two repository names once the image has
  # also been tagged :local (ghcr.io/... and localhost/...). Count distinct
  # digests, or a re-deploy of the same commit looks like two non-children and
  # returns empty — measured on qouver1, 2026-11-16.
  children=" $(printf '%s' "$list" | sed -n 's/.*"digest" *: *"\(sha256:[0-9a-f]*\)".*/\1/p' | tr '\n' ' ') "
  while read -r cand; do
    [ -n "$cand" ] || continue
    case "$children" in *" ${cand##*@} "*) continue ;; esac
    # Two non-children is an unknown shape: return empty rather than guess.
    [ -z "$index" ] || return 0
    index="$cand"
  done <<EOF
$(podman image inspect -f '{{range .RepoDigests}}{{println .}}{{end}}' "$ref" 2>/dev/null \
    | grep -F '@sha256:' | sort | awk -F'@' '!seen[$2]++' || true)
EOF
  printf '%s' "$index"
}

# CI signs the image right after pushing it, so the signature artifact is not
# readable for a few seconds: on 2026-11-16 a verify ~5s after the pull failed
# while the same digest passed seconds later. The retry window is bounded in
# time, not in attempts, and the gap grows between tries, so a signing step that
# lands late is still caught: on 2026-11-16 16:46 a 15s window was not enough
# and the deploy needed a hand rerun. Past the window the same fail-closed abort
# as before — an unverified digest is never tagged, and a registry that never
# answers is not a pass.
COSIGN_WINDOW="${COSIGN_WINDOW:-90}"        # total seconds of tolerance
COSIGN_RETRY_DELAY="${COSIGN_RETRY_DELAY:-3}"   # first gap, doubles per attempt
COSIGN_RETRY_MAX="${COSIGN_RETRY_MAX:-10}"      # gap ceiling
verify_signature() {
  local digest="$1" attempt=1 delay="$COSIGN_RETRY_DELAY" start remain err
  start="$(date +%s)"
  while :; do
    # stderr only: that is where cosign puts the reason it rejected the digest.
    if err="$(cosign verify "$digest" \
      --certificate-identity-regexp "^https://github.com/qouver/qouver/" \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com 2>&1 >/dev/null)"; then
      if [ "$attempt" -gt 1 ]; then
        log "==> cosign verify passed on attempt $attempt for ${digest##*@} ($(( $(date +%s) - start ))s into the window)"
      fi
      return 0
    fi
    remain=$(( COSIGN_WINDOW - ( $(date +%s) - start ) ))
    if [ "$remain" -le 0 ]; then
      log "ERROR: cosign verify failed for revision ${REV:-unknown} after ${COSIGN_WINDOW}s (${attempt} attempts, digest ${digest##*@}), last cosign error: $(printf '%s\n' "$err" | grep -v '^[[:space:]]*$' | tail -n 1)"
      return 1
    fi
    [ "$delay" -le "$remain" ] || delay="$remain"
    log "==> cosign verify did not pass for ${digest##*@} (attempt $attempt, ${remain}s of window left), retrying in ${delay}s"
    attempt=$((attempt + 1))
    sleep "$delay"
    delay=$(( delay * 2 ))
    [ "$delay" -le "$COSIGN_RETRY_MAX" ] || delay="$COSIGN_RETRY_MAX"
  done
}

# 1. Ref guard (fail-closed)
if [ "$REF" != "refs/heads/main" ]; then
  log "Ref $REF is not refs/heads/main — skipping deploy."
  exit 0
fi

# 1b. Trigger commit (fail-closed). The webhook names the pushed commit in
# payload.after. A trigger without a commit cannot be verified against HEAD, so
# it does not build. No override, no fallback.
if [ -z "$TRIGGER_REV" ]; then
  die "No trigger commit (arg 3) — refusing to build without a commit to verify"
fi

# 2. Concurrency lock
exec 200>"$LOCK_FILE"
flock -w 1200 200 || die "Another deploy is still running after 1200s ($LOCK_FILE locked)"

log "==> Deploy triggered for $REPO ($REF)"

# 3. Setup environment PATH (fnm / node) — kept for the BUILD_MODE=host escape hatch.
if [ -d "$HOME/.local/share/fnm" ]; then
  export PATH="$HOME/.local/share/fnm/current/bin:$HOME/.local/share/fnm/aliases/default/bin:$HOME/.local/share/pnpm/bin:$HOME/.local/bin:$PATH"
  eval "$(fnm env 2>/dev/null)" || true
fi

# 4. Fetch latest commit
if [ ! -d "$MONO_DIR/.git" ]; then
  log "==> Cloning repository into $MONO_DIR"
  git clone github-qouver:qouver/qouver.git "$MONO_DIR"
fi

cd "$MONO_DIR"
log "==> Updating monorepo to origin/main"
git fetch origin main
git reset --hard origin/main
REV=$(git rev-parse HEAD)
log "==> Building commit: $REV"

# 4a. Trigger gate (fail-closed, no API call). The webhook names the commit it is
# deploying; the script deploys exactly that commit. If HEAD moved past it, the
# deploy would ship code nobody triggered, so it stops before any swap or build.
if [ "$REV" != "$TRIGGER_REV" ]; then
  die "Trigger commit $TRIGGER_REV does not match HEAD $REV — refusing to build"
fi
log "==> Trigger commit verified: $REV"

# 4a-2. No image to wait for: a commit touching only docs, workflow files or root
# markdown produces no image at all (the `changes` job reaches the same verdict
# from `before..after`), so waiting the window for one would hold the deploy lock
# for nothing. The previous main tip is HEAD^, the same commit GitHub sends as
# `before` on a push, so this mirrors CI's filter instead of guessing from a
# state file that can lag several commits behind.
#
# It does NOT exit here. An ops-only commit still carries the quadlet unit and
# the helper scripts, and until 2026-11-16 this branch returned before step 7
# could install the unit: a unit fix merged to main sat in the repo until the
# next image-bearing deploy (BACKLOG CM-05). Step 4c handles that payload.
OPS_ONLY=0
PREV_MAIN="$(git rev-parse "${REV}^" 2>/dev/null || true)"
if [ -n "$PREV_MAIN" ] && [ "$PREV_MAIN" != "$REV" ]; then
  CHANGED="$(git diff --name-only "$PREV_MAIN" "$REV" || true)"
  if [ -n "$CHANGED" ] && ! printf '%s\n' "$CHANGED" | grep -qvE '^(docs/|\.github/|ops/|[^/]*\.md$)'; then
    OPS_ONLY=1
    log "==> Only docs/workflow/ops paths changed in $REV; no image to wait for"
  fi
fi

# 4b. Quadlet hardening gate (fail-closed). The VPS unit runs with
# NoNewPrivileges, DropCapability=ALL and ReadOnly; never overwrite it with a
# weaker copy from the monorepo (2026-11-10 22:18). Abort before building.
UNIT_SRC="$MONO_DIR/ops/systemd/qouver-api.container"
[ -f "$UNIT_SRC" ] || die "Quadlet unit missing: $UNIT_SRC — deploy aborted, unit on VPS untouched."
for key in NoNewPrivileges=true DropCapability=ALL ReadOnly=true; do
  k="${key%%=*}"; v="${key#*=}"
  if ! grep -qEi "^[[:space:]]*${k}[[:space:]]*=[[:space:]]*${v}[[:space:]]*$" "$UNIT_SRC"; then
    die "Quadlet hardening gate failed: $UNIT_SRC lacks ${key} — deploy aborted, unit on VPS untouched."
  fi
done
log "==> Quadlet hardening gate passed (NoNewPrivileges, DropCapability=ALL, ReadOnly)"

# Rehearsal: DEPLOY_DRY_RUN=1 stops here, before any build, restart or write.
if [ "${DEPLOY_DRY_RUN:-0}" = "1" ]; then
  log "==> DRY RUN: gate passed for commit $REV, stopping before build"
  if diff -u "$HOME/.config/containers/systemd/qouver-api.container" "$UNIT_SRC"; then
    log "==> DRY RUN: live unit already matches, nothing to write"
  else
    log "==> DRY RUN: live unit would be replaced (mode 600), service restarted after build"
  fi
  exit 0
fi

# Self-update deploy script safely using rename
REPO_SCRIPT="$MONO_DIR/ops/scripts/deploy-vps.sh"
SELF_SCRIPT="$APP_DIR/scripts/deploy-vps.sh"
SCRIPT_SWAPPED=0
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  TMP_SCRIPT="$SELF_SCRIPT.new.$$"
  cp -f "$REPO_SCRIPT" "$TMP_SCRIPT" && chmod +x "$TMP_SCRIPT" && mv -f "$TMP_SCRIPT" "$SELF_SCRIPT" \
    && SCRIPT_SWAPPED=1 && log "==> scripts/deploy-vps.sh updated from repo"
fi

# A script replaced mid-run keeps running the old text, so a commit that moves
# a build path fails once for no reason. Re-exec into the copy just swapped in;
# the lock and its fd survive exec, and the second pass finds nothing to sync.
if [ "$SCRIPT_SWAPPED" = "1" ]; then
  log "==> Re-executing the updated deploy-vps.sh"
  exec "$SELF_SCRIPT" "$@"
fi

# Sync helper scripts so the server copies do not drift from the repo.
for helper in smoke.sh rollback.sh; do
  SRC="$MONO_DIR/ops/scripts/$helper"
  DST="$APP_DIR/scripts/$helper"
  if [ -f "$SRC" ] && ! cmp -s "$SRC" "$DST"; then
    cp -f "$SRC" "$DST.new.$$" && chmod +x "$DST.new.$$" && mv -f "$DST.new.$$" "$DST" \
      && log "==> scripts/$helper updated from repo"
  fi
done

# 4c. Ops-only commit: the unit and the helper scripts above are the whole
# payload, so no image is pulled and .deployed_rev keeps the image's revision.
# Install the unit only when it differs, restart only then, and prove the
# service answers before claiming the deploy; a unit that breaks the API is
# rolled back to the previous file, which is what step 9 does for an image.
if [ "$OPS_ONLY" = "1" ]; then
  UNIT_DIR="$HOME/.config/containers/systemd"
  UNIT_LIVE="$UNIT_DIR/qouver-api.container"
  mkdir -p "$UNIT_DIR"

  # The web unit travels in the same ops-only payload. Install it before the
  # API branch below can exit 0 on "api unit already matches", or a web-only
  # unit change would never reach the host.
  WEB_UNIT_SRC="$MONO_DIR/ops/systemd/$WEB_UNIT"
  if [ -f "$WEB_UNIT_SRC" ] && ! cmp -s "$WEB_UNIT_SRC" "$UNIT_DIR/$WEB_UNIT"; then
    install -m 600 "$WEB_UNIT_SRC" "$UNIT_DIR/$WEB_UNIT.new.$$" \
      && mv -f "$UNIT_DIR/$WEB_UNIT.new.$$" "$UNIT_DIR/$WEB_UNIT" \
      || die "Could not install $WEB_UNIT_SRC — web unit untouched"
    log "==> Ops-only commit $REV: quadlet unit $WEB_UNIT updated"
    systemctl --user daemon-reload
    if podman image exists localhost/qouver-web:local; then
      systemctl --user restart qouver-web 2>&1 | tee -a "$LOG" \
        || log "WARNING: restart qouver-web returned non-zero; checking the web health gate anyway"
      wait_healthy_web "$(cat "$STATE_FILE" 2>/dev/null || true)"
    else
      log "==> No localhost/qouver-web:local yet; $WEB_UNIT will start on the next image deploy"
    fi
  fi

  if cmp -s "$UNIT_SRC" "$UNIT_LIVE"; then
    log "==> Ops-only commit $REV: live unit already matches, nothing to deploy or restart"
    exit 0
  fi
  UNIT_BAK=""
  if [ -f "$UNIT_LIVE" ]; then
    UNIT_BAK="$UNIT_LIVE.bak-$(date '+%Y%m%d-%H%M%S')"
    cp -p "$UNIT_LIVE" "$UNIT_BAK" || die "Could not back up $UNIT_LIVE — unit untouched"
  fi
  install -m 600 "$UNIT_SRC" "$UNIT_LIVE.new.$$" \
    && mv -f "$UNIT_LIVE.new.$$" "$UNIT_LIVE" \
    || die "Could not install $UNIT_SRC"
  log "==> Ops-only commit $REV: quadlet unit updated (backup ${UNIT_BAK:-none}), restarting qouver-api"
  systemctl --user daemon-reload
  systemctl --user restart qouver-api || true
  OPS_HEALTHY=0
  for i in $(seq 1 15); do
    if curl -s -f --max-time 3 "$HEALTH_URL" >/dev/null 2>&1; then OPS_HEALTHY=1; break; fi
    sleep 2
  done
  if [ "$OPS_HEALTHY" = "1" ]; then
    # No revision check here: the image did not change, so $REV is not what the
    # container reports. The running image's revision is .deployed_rev, untouched.
    log "==> Health gate passed after the unit-only restart ($HEALTH_URL 200, image unchanged at $(cat "$STATE_FILE" 2>/dev/null || echo unknown))"
    exit 0
  fi
  log "ERROR: qouver-api did not answer $HEALTH_URL after the unit-only restart — restoring the previous unit"
  if [ -n "$UNIT_BAK" ] && [ -f "$UNIT_BAK" ]; then
    install -m 600 "$UNIT_BAK" "$UNIT_LIVE"
    systemctl --user daemon-reload
    systemctl --user restart qouver-api || true
    ROLLED_OK=0
    for i in $(seq 1 15); do
      if curl -s -f --max-time 3 "$HEALTH_URL" >/dev/null 2>&1; then ROLLED_OK=1; break; fi
      sleep 2
    done
    if [ "$ROLLED_OK" = "1" ]; then
      log "==> Unit rollback verified: previous unit restored from $(basename "$UNIT_BAK") and the service answers"
    else
      log "WARNING: service still not answering $HEALTH_URL after restoring $(basename "$UNIT_BAK") — needs a human"
    fi
  else
    log "WARNING: no previous unit to restore — the installed unit stays, needs a human"
  fi
  exit 1
fi

# 5. Static web: pull the image CI built and signed, then extract its tree.
#    The host never runs `pnpm build` any more — every build happens on GitHub.
log "==> Web: pulling the signed web image..."
SHORT_WEB="$(printf '%s' "$REV" | cut -c1-7)"
WEB_IMAGE="ghcr.io/qouver/qouver-web:sha-${SHORT_WEB}"
WEB_PULLED=0
PULL_OUT="$(mktemp)"
RC=0
pull_when_published "$WEB_IMAGE" "$PULL_OUT" || RC=$?
if [ "$RC" = "0" ]; then
  rm -f "$PULL_OUT"
  WEB_DIGEST="$(pulled_digest "$WEB_IMAGE")"
  [ -n "$WEB_DIGEST" ] || die "Pulled $WEB_IMAGE but it reports no digest — web assets untouched"
  # sha-<7> is a filename until the image proves which commit it is.
  WEB_REV="$(podman inspect -f '{{ index .Labels "org.opencontainers.image.revision" }}' "$WEB_DIGEST" 2>/dev/null || true)"
  if [ "$WEB_REV" != "$REV" ]; then
    die "Web image $WEB_IMAGE says revision '${WEB_REV}', payload says $REV — web assets untouched"
  fi
  verify_signature "$WEB_DIGEST" \
    || die "cosign verify failed for $WEB_DIGEST — web assets untouched"
  WEB_PULLED=1
  log "==> Web image pulled, digest ${WEB_DIGEST##*@} verified (revision $WEB_REV)"
elif [ "$RC" = "1" ]; then
  # Absent after the whole window. On a push to main CI publishes both images
  # whenever the gate is green, regardless of the path filter, and an ops-only
  # commit never reaches this step — so a tag that is still missing here means
  # the gate or the image job failed. Until 2026-11-16 this branch logged
  # "keeping the current web assets" and carried on to exit 0: a red gate on
  # main reported a successful deploy while production served the old revision.
  rm -f "$PULL_OUT"
  die "No web image for ${SHORT_WEB} after the wait window: the gate or the image job did not publish it — deploy aborted, web assets untouched"
else
  TAIL_OUT="$(tail -3 "$PULL_OUT" 2>/dev/null || true)"
  rm -f "$PULL_OUT"
  die "Web image pull failed and this is NOT 'not built': $TAIL_OUT"
fi

if [ "$WEB_PULLED" = "1" ]; then
  WEB_CTR="qouver-web-extract.$$"
  podman rm -f "$WEB_CTR" >/dev/null 2>&1 || true
  # Created from the digest that was verified above, not from the mutable tag.
  podman create --name "$WEB_CTR" "$WEB_DIGEST" >/dev/null
  WEB_NEW="$APP_DIR/web.new"
  rm -rf "$WEB_NEW"
  mkdir -p "$WEB_NEW"
  podman cp "$WEB_CTR:/usr/share/nginx/html/." "$WEB_NEW/"
  podman rm -f "$WEB_CTR" >/dev/null
  rm -rf "$APP_DIR/web.prev"
  if [ -d "$APP_DIR/web" ]; then mv "$APP_DIR/web" "$APP_DIR/web.prev"; fi
  mv "$WEB_NEW" "$APP_DIR/web"
  restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
  log "==> Web assets swapped from $WEB_DIGEST"

  # 5b. The same image serves qouver.com through the container since 2026-11-19.
  #     The tree above stays on disk as the rollback target (two good deploys),
  #     but from here on the container is what answers, so it has to be the
  #     revision that was just verified.
  WEB_UNIT_SRC="$MONO_DIR/ops/systemd/$WEB_UNIT"
  [ -f "$WEB_UNIT_SRC" ] \
    || die "Quadlet unit missing: $WEB_UNIT_SRC — deploy aborted, web container untouched"
  if podman image exists localhost/qouver-web:local; then
    podman tag localhost/qouver-web:local localhost/qouver-web:prev 2>/dev/null || true
  fi
  podman tag "$WEB_DIGEST" localhost/qouver-web:local
  podman rmi "$WEB_IMAGE" >/dev/null 2>&1 || true   # :local and :prev stay the only tags
  UNIT_DIR="$HOME/.config/containers/systemd"
  mkdir -p "$UNIT_DIR"
  if ! cmp -s "$WEB_UNIT_SRC" "$UNIT_DIR/$WEB_UNIT"; then
    install -m 600 "$WEB_UNIT_SRC" "$UNIT_DIR/$WEB_UNIT.new.$$" \
      && mv -f "$UNIT_DIR/$WEB_UNIT.new.$$" "$UNIT_DIR/$WEB_UNIT" \
      || die "Could not install $WEB_UNIT_SRC — web container untouched"
    log "==> Quadlet unit $WEB_UNIT installed"
    systemctl --user daemon-reload
    systemctl --user enable qouver-web >/dev/null 2>&1 || true
  fi
  systemctl --user restart qouver-web 2>&1 | tee -a "$LOG" \
    || log "WARNING: restart qouver-web returned non-zero; checking the web health gate anyway"
  wait_healthy_web "$REV"
fi

# 6. API image: pull the one CI built and signed, retag to :local / :prev.
#    BUILD_MODE=host keeps the old compile path as the manual escape hatch for
#    the day GitHub or the registry is down (DEPLOY-FLOW.md §1); never default.
SHORT="$(printf '%s' "$REV" | cut -c1-7)"
IMAGE_REF="ghcr.io/qouver/qouver-api:sha-${SHORT}"
IMAGE_PULLED=0

if [ "${BUILD_MODE:-registry}" = "host" ]; then
  log "==> BUILD_MODE=host: building the Nim API container on the host..."
  cd "$MONO_DIR"
  if podman image exists localhost/qouver-api:local; then
    podman tag localhost/qouver-api:local localhost/qouver-api:prev 2>/dev/null || true
  fi
  /srv/qouver/bin/qouver-build-lock qouver -- podman build -t localhost/qouver-api:local \
    --build-arg GIT_REV="$REV" \
    -f apps/api/Dockerfile .
  IMAGE_PULLED=1
else
  log "==> Pulling API image $IMAGE_REF..."
  PULL_OUT="$(mktemp)"
  RC=0
  pull_when_published "$IMAGE_REF" "$PULL_OUT" || RC=$?
  if [ "$RC" = "0" ]; then
    IMAGE_DIGEST="$(pulled_digest "$IMAGE_REF")"
    [ -n "$IMAGE_DIGEST" ] || { rm -f "$PULL_OUT"; die "Pulled $IMAGE_REF but it reports no digest — running container untouched"; }
    # sha-<short> is a filename until the image proves which commit it is.
    IMAGE_REV="$(podman inspect -f '{{ index .Labels "org.opencontainers.image.revision" }}' "$IMAGE_DIGEST" 2>/dev/null || true)"
    if [ "$IMAGE_REV" != "$REV" ]; then
      rm -f "$PULL_OUT"
      die "Image $IMAGE_REF says revision '${IMAGE_REV}', payload says $REV — running container untouched"
    fi
    verify_signature "$IMAGE_DIGEST" \
      || { rm -f "$PULL_OUT"; die "cosign verify failed for $IMAGE_DIGEST — running container untouched"; }
    if podman image exists localhost/qouver-api:local; then
      podman tag localhost/qouver-api:local localhost/qouver-api:prev 2>/dev/null || true
    fi
    podman tag "$IMAGE_DIGEST" localhost/qouver-api:local
    podman rmi "$IMAGE_REF" >/dev/null 2>&1 || true   # :local and :prev stay the only local tags
    IMAGE_PULLED=1
    rm -f "$PULL_OUT"
    log "==> Image pulled, digest ${IMAGE_DIGEST##*@} verified and tagged :local (revision $IMAGE_REV)"
  elif [ "$RC" = "1" ]; then
    # Same fail-closed rule as the web pull above: on main a green gate always
    # publishes both images, so a missing API tag means the gate or the API image
    # job failed. The web tree may already have been swapped by this run, so put
    # it back before aborting — never leave a new web on top of the old API.
    rm -f "$PULL_OUT"
    if [ "$WEB_PULLED" = "1" ]; then
      rollback_web
      log "==> Web container rolled back to web.prev (this run had already moved it)"
    fi
    die "No API image for ${SHORT} after the wait window: the gate or the image job did not publish it — deploy aborted, running container untouched"
  else
    # A dead registry, an expired token or a 502 is NOT "not built". Fail closed.
    TAIL_OUT="$(tail -3 "$PULL_OUT" 2>/dev/null || true)"
    rm -f "$PULL_OUT"
    die "Registry pull failed and this is NOT 'not built': $TAIL_OUT"
  fi
fi

# Every path above either pulled a verified image or aborted, so reaching here
# without one is a bug in this script, not a reason to report a quiet success.
[ "$IMAGE_PULLED" = "1" ] \
  || die "No verified API image for ${SHORT} reached the swap step — deploy aborted, running container untouched"

# 7. Sync systemd quadlet container definition (mode 600, verified above)
UNIT_DIR="$HOME/.config/containers/systemd"
mkdir -p "$UNIT_DIR"
install -m 600 "$UNIT_SRC" "$UNIT_DIR/qouver-api.container.new.$$" \
  && mv -f "$UNIT_DIR/qouver-api.container.new.$$" "$UNIT_DIR/qouver-api.container" \
  || die "Could not install $UNIT_SRC"

# 8. Restart API container. A container that exits before it reports ready
# makes `systemctl restart` return non-zero immediately (Type=notify, the unit
# goes straight to auto-restart), which under `set -e` used to abort the run
# before the gate: no rollback, and the state file still naming the old
# revision. A failed restart is therefore not fatal; the gate decides.
log "==> Reloading systemd and restarting qouver-api..."
systemctl --user daemon-reload
systemctl --user restart qouver-api \
  || log "WARNING: restart returned non-zero; unit may be crash-looping, checking the health gate anyway..."

# 9. Health check gate. A 200 alone is not proof: the container that answers
# must report the revision this deploy built, otherwise a restart that silently
# kept the old image would pass the gate and record the new revision anyway.
log "==> Verifying health gate ($HEALTH_URL)..."
HEALTHY=0
LIVE_REV=""
for i in $(seq 1 15); do
  LIVE_REV=$(curl -s -f --max-time 3 "$HEALTH_URL" 2>/dev/null \
    | sed -n 's/.*"revision"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{40\}\)".*/\1/p' || true)
  if [ "$LIVE_REV" = "$REV" ]; then
    HEALTHY=1
    break
  fi
  sleep 2
done

if [ "$HEALTHY" -eq 1 ]; then
  log "==> Health gate passed (200 OK, revision $LIVE_REV)"
else
  PREV_REV=$(cat "$STATE_FILE" 2>/dev/null || true)
  log "ERROR: Health gate failed ($HEALTH_URL did not serve revision $REV, last seen: ${LIVE_REV:-no answer}). Rolling back to ${PREV_REV:-previous image}..."
  if podman image exists localhost/qouver-api:prev; then
    podman tag localhost/qouver-api:prev localhost/qouver-api:local
    # Rule 8 applies to the restore restart too: a non-zero exit is a warning,
    # never a reason to skip the verification below and the web restore after it.
    systemctl --user restart qouver-api \
      || log "WARNING: ROLLBACK restart returned non-zero; unit may be crash-looping, verifying the rollback anyway..."
    ROLLED_REV=""
    for i in $(seq 1 15); do
      ROLLED_REV=$(curl -s -f --max-time 3 "$HEALTH_URL" 2>/dev/null \
        | sed -n 's/.*"revision"[[:space:]]*:[[:space:]]*"\([0-9a-f]\{40\}\)".*/\1/p' || true)
      [ -n "$ROLLED_REV" ] && break
      sleep 2
    done
    if [ -n "$PREV_REV" ] && [ "$ROLLED_REV" = "$PREV_REV" ]; then
      log "==> Rollback verified: serving previous revision $PREV_REV"
    elif [ -n "$ROLLED_REV" ]; then
      log "WARNING: rollback is serving ${ROLLED_REV}, expected ${PREV_REV:-unknown}"
    else
      log "WARNING: rollback could not be verified ($HEALTH_URL not answering)"
    fi
  else
    log "ERROR: no localhost/qouver-api:prev image to roll back to"
  fi
  if [ "$WEB_PULLED" = "1" ]; then
    rollback_web
  fi
  exit 1
fi

# 9b. Drop dangling images; :local and :prev stay (the retention contract)
podman image prune -f >/dev/null 2>&1 || true

# 10. Record deployed revision (and the digest it resolved to, when pulled)
printf '%s\n' "$REV" > "$STATE_FILE"
[ -n "${IMAGE_DIGEST:-}" ] && printf '%s %s\n' "$REV" "${IMAGE_DIGEST##*@}" > "$APP_DIR/.deployed_image"
log "==> Deployment completed successfully for $REPO ($REV)"
