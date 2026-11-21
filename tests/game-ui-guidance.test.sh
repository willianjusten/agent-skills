#!/bin/bash
# Game UI guidance: the brief asks for a Screens section; the game skills keep menus and HUD
# to one primary action with detail behind a button or submenu.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

assert_text() { # <name> <pattern> <file>
  if grep -qiE -- "$2" "$3"; then pass "$1"; else fail "$1" "missing: $2"; fi
}
BRIEF="$REPO_ROOT/skills/product/brief"
assert_text "brief template has a Screens section" '^## Screens' "$BRIEF/references/brief-template.md"
assert_text "Screens lists the primary action" 'Primary action' "$BRIEF/references/brief-template.md"
assert_text "Screens lists what sits behind a button or submenu" 'Behind a button or submenu' "$BRIEF/references/brief-template.md"
assert_text "brief checks each screen has one primary action" 'exactly one primary action' "$BRIEF/SKILL.md"

THREE="$REPO_ROOT/skills/realtime/three-build/SKILL.md"
assert_text "three-build: one primary action per screen" 'one primary action per screen' "$THREE"
assert_text "three-build: one spacing scale" 'one spacing scale' "$THREE"
assert_text "three-build: reads ui layout lines and check ui shots" 'ui layout.*check/ui/' "$THREE"

FEEL="$REPO_ROOT/skills/game/game-feel/SKILL.md"
assert_text "game-feel: UI feedback stays calm" 'UI feedback .* stays calm' "$FEEL"
assert_text "game-feel: detail behind a button or submenu" 'behind a button or submenu' "$FEEL"

for skill in "$THREE" "$FEEL"; do
  if grep -qE 'ui-polish|creative-loop|\bbrief\b skill' "$skill"; then fail "leaf names no sibling: $skill"; else pass "leaf names no sibling: $(basename "$(dirname "$skill")")"; fi
done

[ "$failures" -eq 0 ] || exit 1
