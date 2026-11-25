#!/bin/bash
# Tests for the setup-creative-loop skill: shape, the steps that keep a setup honest, and the bundled
# scripts' URL and file-name helpers (hermetic: no browser, no Playwright).

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/skills/orchestration/setup-creative-loop"
SKILL="$SKILL_DIR/SKILL.md"
. "$(dirname "$0")/lib.sh"

[ "$(field "$SKILL" name)" = setup-creative-loop ] && pass "name is setup-creative-loop" || fail "name is setup-creative-loop"
[ "$(field "$SKILL" disable-model-invocation)" = true ] && pass "run by name only" || fail "run by name only"
[ "$(meta "$SKILL" uses)" = creative-loop ] && pass "uses creative-loop" || fail "uses creative-loop" "$(meta "$SKILL" uses)"
[ -f "$SKILL_DIR/README.md" ] && pass "has a README" || fail "has a README"

assert_text() { # <name> <pattern> [file]
  if grep -qiE -- "$2" "${3:-$SKILL}"; then pass "$1"; else fail "$1" "missing: $2"; fi
}
assert_text "the lab needs no setup" 'named .lab., say the loop uses its built-in lab adapter and stop'
assert_text "writes the adapter file" '\.claude/creative-loop\.json'
assert_text "follows the loop's adapter reference" 'creative-loop. .references/adapter.md'
assert_text "nothing committed" 'nothing committed'
assert_text "asks before adding a dependency" 'ask first'
assert_text "dry-runs every command" 'Every command runs once'
assert_text "copies the bundled scripts into the repo" 'scripts/creative-loop/'

for script in shot record; do
  node --check "$SKILL_DIR/scripts/$script.mjs" 2>/dev/null && pass "$script.mjs parses" || fail "$script.mjs parses"
done
helpers=$(cd "$SKILL_DIR/scripts" && node --input-type=module -e '
  import { pageUrl, fileSlug } from "./shot.mjs";
  console.log([
    pageUrl("http://localhost:3000/next", "?stop=wide"),
    pageUrl("http://localhost:3000/next", "#lab"),
    pageUrl("http://localhost:3000/next", "/about"),
    pageUrl("http://localhost:3000/next", ""),
    fileSlug("?stop=wide&time=night"),
    fileSlug(""),
  ].join("\n"));
' 2>&1)
expected=$(printf '%s\n' "http://localhost:3000/next?stop=wide" "http://localhost:3000/next#lab" "http://localhost:3000/about" "http://localhost:3000/next" "stop-wide-time-night" "start")
[ "$helpers" = "$expected" ] && pass "page URLs and file names" || fail "page URLs and file names" "$helpers"

[ "$failures" -eq 0 ] || exit 1
