#!/usr/bin/env bash
# path-filter-test.sh — table test for the CI "what changed" filter.
#
# The filter lives in .github/workflows/ci.yml (job `changes`). A filter is a
# decision about production, so it gets a test: this file holds the same `only`
# logic and a table of diffs with the expected answer. A change to ci.yml that
# narrows a pattern shows up here as a red run instead of a deploy that quietly
# serves the previous artifact.
#
# The rule under test: the default is BUILD. A path matched by neither list
# leaves both outputs true, and only docs / CI / markdown turn both off.
#
# Usage: ./ops/scripts/path-filter-test.sh      (exit 0 = table matches)
set -uo pipefail

decide() { # stdin: newline-separated changed paths -> "api web deploy"
  local FILES
  FILES="$(cat)"
  [ -n "$FILES" ] || FILES="__all__"
  only() { [ "$FILES" = "__all__" ] && return 1; ! printf '%s\n' "$FILES" | grep -qvE "$1"; }
  local api=true web=true deploy=true
  if only '^(docs/|\.github/|[^/]*\.md$)'; then
    api=false; web=false; deploy=false
  elif only '^(docs/|\.github/|ops/|[^/]*\.md$)'; then
    api=false; web=false
  else
    only '^(apps/web/|packages/ui/|packages/api-client/|pnpm-lock\.yaml$|pnpm-workspace\.yaml$|package\.json$)' && api=false
    only '^(apps/api/|shared/|modules/|qouver\.nimble$|config\.nims$)' && web=false
  fi
  printf '%s %s %s\n' "$api" "$web" "$deploy"
}

FAILS=0
CASES=0
check() { # $1 = changed paths, $2 = expected "api web deploy"
  CASES=$((CASES+1))
  local got
  got="$(printf '%s\n' "$1" | decide)"
  if [ "$got" = "$2" ]; then
    printf '  ok   %-42s -> %s\n' "$(printf '%s' "$1" | tr '\n' ',')" "$got"
  else
    printf '  FAIL %-42s -> %s (expected %s)\n' "$(printf '%s' "$1" | tr '\n' ',')" "$got" "$2"
    FAILS=$((FAILS+1))
  fi
}

check "apps/api/src/routes.nim"                "true false true"   # backend only
check "shared/db/pool.nim"                     "true false true"   # backend only
check "config.nims"                            "true false true"   # backend only
check "apps/web/src/routes/+page.svelte"       "false true true"   # frontend only
check "apps/web/package.json"                  "false true true"   # frontend manifest
check "packages/ui/button.ts"                  "false true true"   # web-only package
check "pnpm-lock.yaml"                         "false true true"   # frontend dependency bump
check "pnpm-workspace.yaml"                    "false true true"
check "package.json"                           "false true true"   # web build reads it
check "qouver.nimble"                          "true false true"   # Nim manifest: api only
check "ops/scripts/deploy-vps.sh"              "false false true"  # no image, but deploy
check "docs/DEPLOY-FLOW.md"                    "false false false" # cannot reach runtime
check "README.md"                              "false false false"
check ".github/workflows/ci.yml"               "false false false"
check "tools/whatever/new.txt"                 "true true true"    # unknown: build, never guess
check "migrations/0007_add_col.sql"            "true true true"    # unknown: build, never guess
check "apps/api/src/x.nim
apps/web/src/y.svelte"                          "true true true"    # both sides
check "ops/scripts/x.sh
apps/web/src/a.svelte"                          "true true true"    # conservative: both
check "docs/x.md
package.json"                                   "true true true"    # not every path is docs
check ""                                        "true true true"    # no diff: assume everything

printf '\n%s cases, %s failed\n' "$CASES" "$FAILS"
[ "$FAILS" -eq 0 ]
