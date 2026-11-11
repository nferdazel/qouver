#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="${1:-http://127.0.0.1:8091/healthz}"

echo "Checking health endpoint: $ENDPOINT..."
BODY=$(curl -s --max-time 5 "$ENDPOINT" || true)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$ENDPOINT")

if [ "$STATUS" != "200" ]; then
  echo "ERROR: Service returned status $STATUS"
  exit 1
fi
echo "OK: Service returned 200"

# The binary reports the commit it was built from, so a running container can be
# traced back to a deploy without inspecting the host.
REVISION=$(printf '%s' "$BODY" | sed -n 's/.*"revision":"\([^"]*\)".*/\1/p')
if [ -z "$REVISION" ]; then
  echo "ERROR: health payload has no revision field"
  exit 1
fi
echo "OK: revision $REVISION"
