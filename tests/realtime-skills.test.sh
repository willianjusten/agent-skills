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

scope_of() {
  awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }' "$1"
}

has_machine_path() { grep -rEn '/Users/[a-z]|/home/[a-z]' "$@"; }

for skill in three-build three-tsl three-verify asset-pipeline realtime-judge target-loop; do
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

agent="$REPO_ROOT/agents/realtime/asset-wrangler.md"
if [ -f "$agent" ]; then
  pass "asset-wrangler exists under agents/realtime"
  agent_field() { awk -v key="$1" -F': *' '$1 == key { print $2; exit }' "$agent"; }
  [ "$(agent_field name)" = "asset-wrangler" ] && pass "asset-wrangler name equals its file name" || fail "asset-wrangler name equals its file name"
  [ "$(agent_field model)" = "haiku" ] && pass "asset-wrangler runs on haiku" || fail "asset-wrangler runs on haiku" "found '$(agent_field model)'"
  agent_scope=$(scope_of "$agent")
  [ "$agent_scope" = "personal" ] && pass "asset-wrangler is scoped personal" || fail "asset-wrangler is scoped personal" "found '$agent_scope'"
  if has_machine_path "$agent" >/dev/null; then fail "asset-wrangler has no machine paths"; else pass "asset-wrangler has no machine paths"; fi
else
  fail "asset-wrangler exists under agents/realtime"
fi

[ "$failures" -eq 0 ] || exit 1
