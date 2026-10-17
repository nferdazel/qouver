#!/usr/bin/env bash
#
# deploy-vps.sh — automated deploy script for Qouver (spec: uniform with cbs & fond)
#
# Triggered by webhook daemon on push to refs/heads/main:
#   $1 = repository.name
#   $2 = ref
#
set -euo pipefail

REPO="${1:-qouver}"
REF="${2:-refs/heads/main}"

APP_DIR="${QOUVER_APP_DIR:-/srv/qouver/apps/qouver}"
MONO_DIR="$APP_DIR/monorepo"
BIN_DIR="$APP_DIR/bin"
LOG="$APP_DIR/logs/deploy.log"
STATE_FILE="$APP_DIR/.deployed_rev"
LOCK_FILE="$APP_DIR/.deploy.lock"
WEB_DIR="$APP_DIR/web"
HEALTH_URL="http://127.0.0.1:8091/healthz"

mkdir -p "$APP_DIR/logs" "$BIN_DIR" "$APP_DIR/env" "$APP_DIR/scripts"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }
die() { log "ERROR: $*"; exit 1; }

# 1. Ref guard (fail-closed)
if [ "$REF" != "refs/heads/main" ]; then
  log "Ref $REF is not refs/heads/main — skipping deploy."
  exit 0
fi

# 2. Concurrency lock
exec 200>"$LOCK_FILE"
flock -n 200 || die "Another deploy is running ($LOCK_FILE locked)"

log "==> Deploy triggered for $REPO ($REF)"

# 3. Setup environment PATH (fnm / node / corepack / pnpm)
if [ -d "$HOME/.local/share/fnm" ]; then
  export PATH="$HOME/.local/share/fnm/current/bin:$HOME/.local/share/fnm/aliases/default/bin:$HOME/.local/bin:$PATH"
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

# Self-update deploy script safely using rename
REPO_SCRIPT="$MONO_DIR/ops/scripts/deploy-vps.sh"
SELF_SCRIPT="$APP_DIR/scripts/deploy-vps.sh"
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  TMP_SCRIPT="$SELF_SCRIPT.new.$$"
  cp -f "$REPO_SCRIPT" "$TMP_SCRIPT" && chmod +x "$TMP_SCRIPT" && mv -f "$TMP_SCRIPT" "$SELF_SCRIPT" \
    && log "==> scripts/deploy-vps.sh updated from repo (applies on next deploy)"
fi

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
podman build -t localhost/qouver-api:local -f deploy/qouver-api.Dockerfile .

# 7. Sync systemd quadlet container definition
UNIT_DIR="$HOME/.config/containers/systemd"
mkdir -p "$UNIT_DIR"
if [ -f "$MONO_DIR/deploy/qouver-api.container" ]; then
  cp -f "$MONO_DIR/deploy/qouver-api.container" "$UNIT_DIR/qouver-api.container"
fi

# 8. Restart API container
log "==> Reloading systemd and restarting qouver-api..."
systemctl --user daemon-reload
systemctl --user restart qouver-api

# 9. Health check gate
log "==> Verifying health gate ($HEALTH_URL)..."
HEALTHY=0
for i in $(seq 1 15); do
  if curl -s -f "$HEALTH_URL" >/dev/null 2>&1; then
    HEALTHY=1
    break
  fi
  sleep 2
done

if [ "$HEALTHY" -eq 1 ]; then
  log "==> Health gate passed (200 OK)"
else
  log "ERROR: Health gate failed ($HEALTH_URL not responding). Rolling back..."
  if podman image exists localhost/qouver-api:prev; then
    podman tag localhost/qouver-api:prev localhost/qouver-api:local
    systemctl --user restart qouver-api || true
  fi
  if [ -d "$APP_DIR/web.prev" ]; then
    rm -rf "$APP_DIR/web"
    mv "$APP_DIR/web.prev" "$APP_DIR/web"
    restorecon -RF "$APP_DIR/web/" 2>/dev/null || true
  fi
  exit 1
fi

# 10. Record deployed revision
printf '%s\n' "$REV" > "$STATE_FILE"
log "==> Deployment completed successfully for $REPO ($REV)"
