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
REF="${2:-}"

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
flock -w 1200 200 || die "Another deploy is still running after 1200s ($LOCK_FILE locked)"

log "==> Deploy triggered for $REPO ($REF)"

# CI gate override: explicit, default off, and loud at the top of the run.
if [ "${DEPLOY_SKIP_CI_GATE:-0}" = "1" ]; then
  log "==> CI GATE OVERRIDDEN (DEPLOY_SKIP_CI_GATE=1): this deploy builds without verifying CI for the commit"
fi

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

# 4a. CI gate (fail-closed). The deploy never builds a commit whose push CI run
# is not green. On 2026-11-13 the build for f9ecf4b started 17:56:42 WIB while
# CI run 43413033021 reached success at 17:58:33 WIB, so production carried the
# new build before its own CI finished. Polls the push run for exactly $REV.
if [ "${DEPLOY_SKIP_CI_GATE:-0}" != "1" ]; then
  CI_GATE_REPO="${CI_GATE_REPO:-nferdazel/qouver}"
  CI_GATE_API="https://api.github.com/repos/$CI_GATE_REPO"
  CI_GATE_ENV_FILE="$APP_DIR/env/deploy.env"
  CI_GATE_TIMEOUT="${CI_GATE_TIMEOUT_SEC:-240}"
  CI_GATE_INTERVAL="${CI_GATE_INTERVAL_SEC:-10}"

  # Token from the VPS environment file or the process environment, never the
  # repo. The API answers anonymously for this public repo (60 req/h) and the
  # gate names the mode it used, so a missing token is visible, never silent.
  # shellcheck source=/dev/null
  if [ -z "${QOUVER_GITHUB_TOKEN:-}" ] && [ -f "$CI_GATE_ENV_FILE" ]; then
    set -a; . "$CI_GATE_ENV_FILE"; set +a
  fi
  CI_TOKEN="${QOUVER_GITHUB_TOKEN:-${GITHUB_TOKEN:-}}"
  CURL_AUTH=()
  CI_AUTH_MODE="anonymous"
  if [ -n "$CI_TOKEN" ]; then
    CURL_AUTH=(-H "Authorization: Bearer $CI_TOKEN")
    CI_AUTH_MODE="token"
  fi
  log "==> CI gate: waiting for push CI on $REV (auth=$CI_AUTH_MODE, budget ${CI_GATE_TIMEOUT}s)"

  ci_gate_start=$(date +%s)
  ci_gate_last="no run yet"
  while :; do
    if [ $(( $(date +%s) - ci_gate_start )) -ge "$CI_GATE_TIMEOUT" ]; then
      die "CI gate: no green push run for $REV within ${CI_GATE_TIMEOUT}s (last seen: $ci_gate_last) — refusing to build"
    fi

    CI_RESP=$(curl -sS --max-time 10 "${CURL_AUTH[@]}" \
      -H "Accept: application/vnd.github+json" \
      -w '\n%{http_code}' \
      "$CI_GATE_API/actions/runs?head_sha=$REV&event=push" 2>/dev/null) || CI_RESP=$'\n000'
    CI_CODE="${CI_RESP##*$'\n'}"
    CI_BODY="${CI_RESP%$'\n'*}"
    [ "$CI_CODE" = "200" ] || die "CI gate: GitHub API returned HTTP $CI_CODE for $REV — refusing to build (auth=$CI_AUTH_MODE)"

    CI_BODY=$(printf '%s' "$CI_BODY" | tr -d ' \n\r\t')
    CI_TOTAL=$(printf '%s' "$CI_BODY" | grep -o '"total_count":[0-9]*' | head -1 | cut -d: -f2 || true)
    [ -n "$CI_TOTAL" ] || die "CI gate: unreadable GitHub API response for $REV — refusing to build"

    CI_RUNS=0
    CI_ALL_GREEN=1
    if [ "$CI_TOTAL" -gt 0 ]; then
      CI_OBJS=$(printf '%s' "$CI_BODY" | sed 's/{"id":/\n{"id":/g' | grep '^{"id":' || true)
      while IFS= read -r ci_obj; do
        # Only workflow run objects carry workflow_id; the same response embeds
        # the repository, actor and head commit objects, which are not runs.
        case "$ci_obj" in
          *'"workflow_id":'*) : ;;
          *) continue ;;
        esac
        ci_id=$(printf '%s' "$ci_obj" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || true)
        ci_state=$(printf '%s' "$ci_obj" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
        ci_concl=$(printf '%s' "$ci_obj" | grep -o '"conclusion":"[^"]*"' | head -1 | cut -d'"' -f4 || true)
        CI_RUNS=$((CI_RUNS + 1))
        CI_RUN_ID="$ci_id"
        ci_gate_last="run $ci_id ${ci_concl:-$ci_state}"
        if [ "$ci_state" = "completed" ] && [ "$ci_concl" != "success" ]; then
          die "CI gate: run $ci_id for $REV concluded '${ci_concl:-none}' — refusing to build"
        fi
        if [ "$ci_state" != "completed" ]; then
          CI_ALL_GREEN=0
        fi
      done <<< "$CI_OBJS"
    fi

    if [ "$CI_RUNS" -gt 0 ] && [ "$CI_ALL_GREEN" -eq 1 ]; then
      ci_gate_elapsed=$(( $(date +%s) - ci_gate_start ))
      if [ "$ci_gate_elapsed" -ge 60 ]; then
        ci_gate_dur="$((ci_gate_elapsed / 60))m$((ci_gate_elapsed % 60))s"
      else
        ci_gate_dur="${ci_gate_elapsed}s"
      fi
      log "==> CI gate: run $CI_RUN_ID success ($ci_gate_dur)"
      break
    fi

    sleep "$CI_GATE_INTERVAL"
  done
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
  -f ops/container/qouver-api.Dockerfile .

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

# 9. Health check gate
log "==> Verifying health gate ($HEALTH_URL)..."
HEALTHY=0
for i in $(seq 1 15); do
  if curl -s -f --max-time 3 "$HEALTH_URL" >/dev/null 2>&1; then
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

# 9b. Drop dangling images; :local and :prev stay (the retention contract)
podman image prune -f >/dev/null 2>&1 || true

# 10. Record deployed revision
printf '%s\n' "$REV" > "$STATE_FILE"
log "==> Deployment completed successfully for $REPO ($REV)"
