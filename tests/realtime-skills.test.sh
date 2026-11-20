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

# review fixes: art bible templates stay identical, asset-pipeline steps stay short, packs are examples
cmp -s "$REPO_ROOT/skills/game/game-brief/references/art-bible-template.md" "$REPO_ROOT/skills/realtime/art-bible/references/art-bible-template.md" && pass "the two art-bible templates are identical" || fail "the two art-bible templates are identical"
if grep -rn 'Kenney or Quaternius' "$REPO_ROOT/skills/realtime/art-bible" "$REPO_ROOT/skills/game/game-brief" | grep -v 'for example Kenney or Quaternius' >/dev/null; then fail "art-bible and game-brief name pack families as examples"; else pass "art-bible and game-brief name pack families as examples"; fi
grep -q 'for example Kenney, is a source, not an API' "$REPO_ROOT/skills/realtime/art-bible/SKILL.md" && pass "art-bible says a pack family is a source, not an API" || fail "art-bible says a pack family is a source, not an API"
ASSET_SKILL="$REPO_ROOT/skills/realtime/asset-pipeline/SKILL.md"
for step in 2 3 7; do
  length=$(grep "^$step\. " "$ASSET_SKILL" | wc -c)
  [ "$length" -lt 700 ] && pass "asset-pipeline step $step is a table-of-contents line" || fail "asset-pipeline step $step is a table-of-contents line" "$length bytes"
done
[ -f "$REPO_ROOT/skills/realtime/asset-pipeline/references/sources.md" ] && grep -q 'code-only' "$REPO_ROOT/skills/realtime/asset-pipeline/references/sources.md" && grep -q 'sources.md' "$ASSET_SKILL" && pass "asset-pipeline source order and code-only detail live in references/sources.md" || fail "asset-pipeline source order and code-only detail live in references/sources.md"

[ "$failures" -eq 0 ] || exit 1
