#!/bin/bash
# Game UI guidance: the brief asks for a Screens section and where each feature is shown; menu, HUD, feel and music
# rules live in game-design and the build skills point there; the loop's review removes as well as adds.

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
assert_text "loop cycle line names what moved behind a button" 'moved behind a button' "$LOOP/references/profile-game.md"
assert_text "UI pass reads the screens sheet" 'check/ui/screens.png' "$LOOP/references/ui-pass.md"
assert_text "UI pass removes one thing" 'Remove one thing' "$LOOP/references/ui-pass.md"
assert_text "UI pass checks phones only when asked" 'only when the user asked for mobile' "$LOOP/references/ui-pass.md"
assert_text "hand-off sends the screens sheet" 'screens.png' "$LOOP/references/hand-off.md"

THREE="$REPO_ROOT/skills/realtime/three-build/SKILL.md"
assert_text "three-build: menus and HUD point to game-design ui-ux" 'game-design.*ui-ux.md' "$THREE"
assert_text "three-build: one spacing scale" 'one spacing scale' "$THREE"
assert_text "three-build: reads ui layout lines and check ui shots" 'ui layout.*check/ui/' "$THREE"

DESIGN="$REPO_ROOT/skills/game/game-design/references"
assert_text "game-design ui-ux: one decision per screen" 'One decision per screen' "$DESIGN/ui-ux.md"
assert_text "game-design ui-ux: settings and stats behind a button" 'behind a button' "$DESIGN/ui-ux.md"
assert_text "game-design ui-ux: HUD in two tiers" 'HUD in two tiers' "$DESIGN/ui-ux.md"
assert_text "game-design feel: static menus stay calm" 'Static menus get calm presses' "$DESIGN/feel.md"
assert_text "game-design sound: music is a composition with sections" 'composition with sections' "$DESIGN/sound.md"
assert_text "game-design sound: nothing repeats exactly for 30 to 60 s" 'Nothing repeats exactly' "$DESIGN/sound.md"
assert_text "game-design sound: layers carry dynamics" 'Layers carry dynamics' "$DESIGN/sound.md"
assert_text "UI pass holds screens to game-design ui-ux" 'game-design.*ui-ux.md' "$LOOP/references/ui-pass.md"
assert_text "game-feel points feedback at game-design feel" 'game-design.*feel.md' "$REPO_ROOT/skills/game/game-feel/SKILL.md"

[ "$failures" -eq 0 ] || exit 1
