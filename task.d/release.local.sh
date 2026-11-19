#!/usr/bin/env sh
# qouver release hook: stamps the new version into the root and web package.json files.
# Called by task.d/release.sh as: sh task.d/release.local.sh <new> <old>
set -eu
cd "$(dirname "$0")/.."

new=$1

for f in package.json apps/web/package.json; do
  [ -f "$f" ] || continue
  sed -i.bak -E "0,/\"version\": *\"[^\"]*\"/s//\"version\": \"$new\"/" "$f"
  rm -f "$f.bak"
done

git add package.json apps/web/package.json
