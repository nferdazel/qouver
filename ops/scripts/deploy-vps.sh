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
pulled_digest() {
  podman image inspect -f '{{range .RepoDigests}}{{println .}}{{end}}' "$1" 2>/dev/null \
    | grep -F '@sha256:' | head -1
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
  git clone github-qouver:nferdazel/qouver.git "$MONO_DIR"
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

# 4a-2. Nothing to deploy: a commit touching only docs, workflow files or root
# markdown produces no image at all (the `changes` job reaches the same verdict
# from `before..after`), so waiting the window for one would hold the deploy lock
# for nothing. The previous main tip is HEAD^, the same commit GitHub sends as
# `before` on a push, so this mirrors CI's filter instead of guessing from a
# state file that can lag several commits behind.
PREV_MAIN="$(git rev-parse "${REV}^" 2>/dev/null || true)"
if [ -n "$PREV_MAIN" ] && [ "$PREV_MAIN" != "$REV" ]; then
  CHANGED="$(git diff --name-only "$PREV_MAIN" "$REV" || true)"
  if [ -n "$CHANGED" ] && ! printf '%s\n' "$CHANGED" | grep -qvE '^(docs/|\.github/|ops/|[^/]*\.md$)'; then
    log "==> Only docs/workflow/ops paths changed in $REV; no image to wait for, nothing to deploy"
    exit 0
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

# 5. Static web: pull the image CI built and signed, then extract its tree.
#    The host never runs `pnpm build` any more — every build happens on GitHub.
log "==> Web: pulling the signed web image..."
SHORT_WEB="$(printf '%s' "$REV" | cut -c1-7)"
WEB_IMAGE="ghcr.io/nferdazel/qouver-web:sha-${SHORT_WEB}"
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
  cosign verify "$WEB_DIGEST" \
    --certificate-identity-regexp "^https://github.com/nferdazel/qouver/" \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com >/dev/null 2>&1 \
    || die "cosign verify failed for $WEB_DIGEST — web assets untouched"
  WEB_PULLED=1
  log "==> Web image pulled, digest ${WEB_DIGEST##*@} verified (revision $WEB_REV)"
elif [ "$RC" = "1" ]; then
  # Still absent after the whole window: the gate went red or this commit
  # changed no web path. Either way nothing runs, and the old tree keeps serving.
  log "==> No web image for ${SHORT_WEB} after the wait window; keeping the current web assets"
  rm -f "$PULL_OUT"
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
  podman rmi "$WEB_DIGEST" >/dev/null 2>&1 || true
  rm -rf "$APP_DIR/web.prev"
  if [ -d "$APP_DIR/web" ]; then mv "$APP_DIR/web" "$APP_DIR/web.prev"; fi
  mv "$WEB_NEW" "$APP_DIR/web"
  restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
  log "==> Web assets swapped from $WEB_DIGEST"
fi

# 6. API image: pull the one CI built and signed, retag to :local / :prev.
#    BUILD_MODE=host keeps the old compile path as the manual escape hatch for
#    the day GitHub or the registry is down (DEPLOY-FLOW.md §1); never default.
SHORT="$(printf '%s' "$REV" | cut -c1-7)"
IMAGE_REF="ghcr.io/nferdazel/qouver-api:sha-${SHORT}"
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
    cosign verify "$IMAGE_DIGEST" \
      --certificate-identity-regexp "^https://github.com/nferdazel/qouver/" \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com >/dev/null 2>&1 \
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
    # Absent for the whole window: the gate went red or this commit changed no
    # API path. Either way the running container is untouched.
    rm -f "$PULL_OUT"
    log "==> No API image for ${SHORT} after the wait window; keeping the running container"
  else
    # A dead registry, an expired token or a 502 is NOT "not built". Fail closed.
    TAIL_OUT="$(tail -3 "$PULL_OUT" 2>/dev/null || true)"
    rm -f "$PULL_OUT"
    die "Registry pull failed and this is NOT 'not built': $TAIL_OUT"
  fi
fi

# Web assets were swapped above; an API that did not change needs no restart.
if [ "$IMAGE_PULLED" != "1" ]; then
  log "==> Web assets only for ${SHORT}; API container left running, no restart"
  exit 0
fi

# 7. Sync systemd quadlet container definition (mode 600, verified above)
UNIT_DIR="$HOME/.config/containers/systemd"
mkdir -p "$UNIT_DIR"
install -m 600 "$UNIT_SRC" "$UNIT_DIR/qouver-api.container.new.$$" \
  && mv -f "$UNIT_DIR/qouver-api.container.new.$$" "$UNIT_DIR/qouver-api.container" \
  || die "Could not install $UNIT_SRC"

# 8. Restart API container
log "==> Reloading systemd and restarting qouver-api..."
systemctl --user daemon-reload
systemctl --user restart qouver-api

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
    systemctl --user restart qouver-api || true
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
  if [ -d "$APP_DIR/web.prev" ]; then
    rm -rf "$APP_DIR/web"
    mv "$APP_DIR/web.prev" "$APP_DIR/web"
    restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
    log "==> Web assets restored from web.prev"
  fi
  exit 1
fi

# 9b. Drop dangling images; :local and :prev stay (the retention contract)
podman image prune -f >/dev/null 2>&1 || true

# 10. Record deployed revision (and the digest it resolved to, when pulled)
printf '%s\n' "$REV" > "$STATE_FILE"
[ -n "${IMAGE_DIGEST:-}" ] && printf '%s %s\n' "$REV" "${IMAGE_DIGEST##*@}" > "$APP_DIR/.deployed_image"
log "==> Deployment completed successfully for $REPO ($REV)"
