#!/usr/bin/env bash
#
# deploy-vps.sh — automated deploy script for Qouver (spec: uniform with cbs & fond)
#
# Triggered by the CI deploy job (.github/workflows/ci.yml) through the webhook
# daemon, for a commit whose CI run is already green:
#   $1 = repository.name
#   $2 = ref
#   $3 = commit sha the green CI run belongs to (payload.after)
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

# 1. Ref guard (fail-closed)
if [ "$REF" != "refs/heads/main" ]; then
  log "Ref $REF is not refs/heads/main — skipping deploy."
  exit 0
fi

# 1b. Trigger commit (fail-closed). The only caller is the CI deploy job, which
# names the commit its run went green for. A trigger without a commit cannot be
# verified against HEAD, so it does not build. No override, no fallback.
if [ -z "$TRIGGER_REV" ]; then
  die "No trigger commit (arg 3) — refusing to build without a commit to verify"
fi

# 2. Concurrency lock
exec 200>"$LOCK_FILE"
flock -w 1200 200 || die "Another deploy is still running after 1200s ($LOCK_FILE locked)"

log "==> Deploy triggered for $REPO ($REF)"

# 3. Setup environment PATH (fnm / node / corepack / pnpm)
if [ -d "$HOME/.local/share/fnm" ]; then
  export PATH="$HOME/.local/share/fnm/current/bin:$HOME/.local/share/fnm/aliases/default/bin:$HOME/.local/share/pnpm/bin:$HOME/.local/bin:$PATH"
  eval "$(fnm env 2>/dev/null)" || true
fi

if command -v pnpm >/dev/null 2>&1; then
  PNPM_CMD="pnpm"
elif command -v corepack >/dev/null 2>&1; then
  PNPM_CMD="corepack pnpm"
else
  die "pnpm or corepack not found in PATH: $PATH"
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

# 4a. Trigger gate (fail-closed, no API call). CI is the only thing that says a
# commit is green, and it says so to this script by naming the sha in the
# trigger. If HEAD moved past the triggered commit, the deploy would build code
# nobody verified, so it stops before any swap or build.
if [ "$REV" != "$TRIGGER_REV" ]; then
  die "Trigger commit $TRIGGER_REV does not match HEAD $REV — refusing to build"
fi
log "==> Trigger commit verified: $REV"

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
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  TMP_SCRIPT="$SELF_SCRIPT.new.$$"
  cp -f "$REPO_SCRIPT" "$TMP_SCRIPT" && chmod +x "$TMP_SCRIPT" && mv -f "$TMP_SCRIPT" "$SELF_SCRIPT" \
    && log "==> scripts/deploy-vps.sh updated from repo (applies on next deploy)"
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

# 5. Build static web (SvelteKit)
log "==> Building web assets with $PNPM_CMD..."
cd "$MONO_DIR"
$PNPM_CMD install --frozen-lockfile
$PNPM_CMD --filter @qouver/api-client gen
$PNPM_CMD --filter @qouver/web build

# Swap web assets safely
WEB_NEW="$APP_DIR/web.new"
rm -rf "$WEB_NEW"
cp -a "$MONO_DIR/apps/web/build" "$WEB_NEW"
rm -rf "$APP_DIR/web.prev"
[ -d "$APP_DIR/web" ] && mv "$APP_DIR/web" "$APP_DIR/web.prev"
mv "$WEB_NEW" "$APP_DIR/web"
restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
log "==> Web assets swapped"

# 6. Build Nim API container image with Podman
log "==> Building Nim API container (Podman)..."
cd "$MONO_DIR"
if podman image exists localhost/qouver-api:local; then
  podman tag localhost/qouver-api:local localhost/qouver-api:prev 2>/dev/null || true
fi
podman build -t localhost/qouver-api:local \
  --build-arg GIT_REV="$REV" \
  -f apps/api/Dockerfile .

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

# 10. Record deployed revision
printf '%s\n' "$REV" > "$STATE_FILE"
log "==> Deployment completed successfully for $REPO ($REV)"
