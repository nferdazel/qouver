#!/usr/bin/env sh
# qouver static checks for `./task gate`: Nim check, package typecheck, Svelte check and the
# OpenAPI contract sync. Needs the toolchains but installs nothing and never talks to a database.
set -eu
cd "$(dirname "$0")/.."

sh ./task check
