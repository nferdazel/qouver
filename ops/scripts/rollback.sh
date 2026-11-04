#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="qouver-api"
IMAGE_NAME="qouver-api"

if ! podman image exists "localhost/${IMAGE_NAME}:prev"; then
  echo "ERROR: localhost/${IMAGE_NAME}:prev not found; nothing to roll back to."
  exit 1
fi

echo "==> Rolling back to previous container image..."
podman tag "localhost/${IMAGE_NAME}:prev" "localhost/${IMAGE_NAME}:local"
systemctl --user restart "$SERVICE_NAME"

echo "==> Verifying rollback health..."
"$(dirname "$0")/smoke.sh"
echo "==> Rollback complete and verified."
