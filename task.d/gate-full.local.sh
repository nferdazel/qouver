#!/usr/bin/env sh
# qouver test hook for `./task gate-full`: unit/property/contract tests, then the build and the
# e2e + axe audit. This is `./task ci` without repeating the static checks `gate` already ran.
set -eu
cd "$(dirname "$0")/.."

sh ./task test
sh ./task build
sh ./task e2e
