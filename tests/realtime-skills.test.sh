#!/bin/bash
# Tests for the own realtime skills: each is personal-scoped (so it never reaches
# Spoke), ships a README, names itself after its folder, and carries no machine paths.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
REALTIME="$REPO_ROOT/skills/realtime"
. "$(dirname "$0")/lib.sh"

scope_of() {
  awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }' "$1"
}

has_machine_path() { grep -rEn '/Users/[a-z]|/home/[a-z]' "$@"; }

for skill in three-build three-tsl asset-pipeline; do
  file="$REALTIME/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "$skill exists under skills/realtime"
    continue
  fi
  pass "$skill exists under skills/realtime"

  name=$(awk -F': *' '$1 == "name" { print $2; exit }' "$file")
  [ "$name" = "$skill" ] && pass "$skill frontmatter name equals its folder" || fail "$skill frontmatter name equals its folder" "found '$name'"

  scope=$(scope_of "$file")
  [ "$scope" = "personal" ] && pass "$skill is scoped personal" || fail "$skill is scoped personal" "found '$scope'"

  [ -f "$REALTIME/$skill/README.md" ] && pass "$skill has a README" || fail "$skill has a README"

  if paths=$(has_machine_path "$REALTIME/$skill"); then
    fail "$skill has no machine paths" "$paths"
  else
    pass "$skill has no machine paths"
  fi
done

ASSET_SKILL="$REPO_ROOT/skills/realtime/asset-pipeline/SKILL.md"
for step in 2 3 7; do
  length=$(grep "^$step\. " "$ASSET_SKILL" | wc -c)
  [ "$length" -lt 700 ] && pass "asset-pipeline step $step is a table-of-contents line" || fail "asset-pipeline step $step is a table-of-contents line" "$length bytes"
done
[ -f "$REPO_ROOT/skills/realtime/asset-pipeline/references/sources.md" ] && grep -q 'code-only' "$REPO_ROOT/skills/realtime/asset-pipeline/references/sources.md" && grep -q 'sources.md' "$ASSET_SKILL" && pass "asset-pipeline source order and code-only detail live in references/sources.md" || fail "asset-pipeline source order and code-only detail live in references/sources.md"

[ "$failures" -eq 0 ] || exit 1
