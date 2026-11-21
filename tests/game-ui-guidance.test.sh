#!/bin/bash
# Game UI guidance: the brief asks for a Screens section and where each feature is shown; the game skills keep menus
# and HUD to one primary action with detail behind a button or submenu; the loop's review removes as well as adds;
# music guidance asks for a musical idea with sections and dynamics.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

assert_text() { # <name> <pattern> <file>
  if grep -qiE -- "$2" "$3"; then pass "$1"; else fail "$1" "missing: $2"; fi
}
BRIEF="$REPO_ROOT/skills/product/brief"
assert_text "brief template has a Screens section" '^## Screens' "$BRIEF/references/brief-template.md"
assert_text "Screens lists what sits behind a button or submenu" 'Behind a button' "$BRIEF/references/brief-template.md"
assert_text "brief checks each screen has one primary action" 'exactly one primary action' "$BRIEF/SKILL.md"
assert_text "Screens lists the decision it asks" 'Decision it asks' "$BRIEF/references/brief-template.md"
assert_text "Screens lists what is hidden until available" 'Hidden until available' "$BRIEF/references/brief-template.md"
assert_text "Screens lists where controls help lives" 'Controls help' "$BRIEF/references/brief-template.md"
assert_text "brief checks one decision and controls help location" 'one decision.*controls help' "$BRIEF/SKILL.md"
assert_text "brief features name the screen they are shown on" 'Shown on' "$BRIEF/references/brief-template.md"
assert_text "brief cuts a feature that only adds to a full screen" 'what it displaces' "$BRIEF/SKILL.md"

LOOP="$REPO_ROOT/skills/orchestration/creative-loop"
assert_text "loop review names one thing to remove or simplify" 'one thing to remove or simplify' "$LOOP/SKILL.md"
assert_text "loop ideas include removals" 'removals and simplifications' "$LOOP/SKILL.md"
assert_text "loop cycle line names what moved behind a button" 'moved behind a button' "$LOOP/SKILL.md"
assert_text "UI pass reads the screens sheet" 'check/ui/screens.png' "$LOOP/references/ui-pass.md"
assert_text "UI pass removes one thing" 'Remove one thing' "$LOOP/references/ui-pass.md"
assert_text "UI pass checks phones only when asked" 'only when the user asked for mobile' "$LOOP/references/ui-pass.md"
assert_text "hand-off sends the screens sheet" 'screens.png' "$LOOP/references/hand-off.md"

THREE="$REPO_ROOT/skills/realtime/three-build/SKILL.md"
assert_text "three-build: one primary action per screen" 'one primary action per screen' "$THREE"
assert_text "three-build: one spacing scale" 'one spacing scale' "$THREE"
assert_text "three-build: reads ui layout lines and check ui shots" 'ui layout.*check/ui/' "$THREE"

FEEL="$REPO_ROOT/skills/game/game-feel/SKILL.md"
assert_text "game-feel: UI feedback stays calm" 'UI feedback .* stays calm' "$FEEL"
assert_text "game-feel: detail behind a button or submenu" 'behind a button or submenu' "$FEEL"
assert_text "game-feel music: a musical idea, not a texture" 'musical idea, not a texture' "$REPO_ROOT/skills/game/game-feel/references/audio.md"
assert_text "game-feel music: sections against repetition" 'sections \(intro' "$REPO_ROOT/skills/game/game-feel/references/audio.md"
assert_text "game-feel music: intensity changes which layers play" 'changes which layers play' "$REPO_ROOT/skills/game/game-feel/references/audio.md"

[ "$failures" -eq 0 ] || exit 1
