#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="${1:-http://127.0.0.1:8091/healthz}"

echo "Checking health endpoint: $ENDPOINT..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$ENDPOINT")

if [ "$STATUS" = "200" ]; then
  echo "OK: Service returned 200"
  exit 0
else
  echo "ERROR: Service returned status $STATUS"
  exit 1
fi
