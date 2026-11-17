#!/bin/bash
# Tests for the own realtime skills: each is personal-scoped (so it never reaches
# Spoke), ships a README, names itself after its folder, and carries no machine paths.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
REALTIME="$REPO_ROOT/skills/realtime"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

for skill in three-build three-tsl three-verify; do
  file="$REALTIME/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "$skill exists under skills/realtime"
    continue
  fi
  pass "$skill exists under skills/realtime"

  name=$(awk -F': *' '$1 == "name" { print $2; exit }' "$file")
  [ "$name" = "$skill" ] && pass "$skill frontmatter name equals its folder" || fail "$skill frontmatter name equals its folder" "found '$name'"

  scope=$(awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }' "$file")
  [ "$scope" = "personal" ] && pass "$skill is scoped personal" || fail "$skill is scoped personal" "found '$scope'"

  [ -f "$REALTIME/$skill/README.md" ] && pass "$skill has a README" || fail "$skill has a README"

  if grep -rEn '/Users/[a-z]|/home/[a-z]' "$REALTIME/$skill" >/dev/null; then
    fail "$skill has no machine paths" "$(grep -rEn '/Users/[a-z]|/home/[a-z]' "$REALTIME/$skill")"
  else
    pass "$skill has no machine paths"
  fi
done

[ "$failures" -eq 0 ] || exit 1
