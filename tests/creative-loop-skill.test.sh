#!/bin/bash
# Tests for the creative-loop skill: orchestrator shape, safety text, start-run.sh (hermetic),
# and an opt-in dry run against a lab checkout (LAB_ROOT=<worktree>, slow, skipped otherwise).

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/skills/orchestration/creative-loop"
SKILL="$SKILL_DIR/SKILL.md"
START="$SKILL_DIR/scripts/start-run.sh"
HOOK="$REPO_ROOT/harness/claude/hooks/loop-stop.sh"
FIXTURE_BRIEF="$REPO_ROOT/tests/fixtures/loop-brief/BRIEF.md"
. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
lab_cleanup="" # set by the opt-in dry run
trap '[ -z "$lab_cleanup" ] || $lab_cleanup; rm -rf "$work"' EXIT

# Shape
[ "$(field "$SKILL" name)" = creative-loop ] && pass "name is creative-loop" || fail "name is creative-loop" "$(field "$SKILL" name)"
[ "$(field "$SKILL" disable-model-invocation)" = true ] && pass "run by name only" || fail "run by name only" "disable-model-invocation: $(field "$SKILL" disable-model-invocation)"
[ "$(meta "$SKILL" uses)" = "ideation brief three-build game-feel game-design ui-polish" ] && pass "uses the six skills" || fail "uses the six skills" "$(meta "$SKILL" uses)"
[ -f "$SKILL_DIR/README.md" ] && pass "has a README" || fail "has a README"

# Text assertions: overnight safety and unattended behaviour
assert_text() { # <name> <pattern> [file]
  if grep -qiE -- "$2" "${3:-$SKILL}"; then pass "$1"; else fail "$1" "missing: $2"; fi
}
assert_text "forbids merge" 'never merge'
assert_text "forbids push" 'never push'
assert_text "forbids deploy" 'never deploy'
assert_text "forbids branch deletion" 'never delete a branch'
assert_text "forbids spending money" 'never spend money'
assert_text "never works on the default branch" 'never work on the default branch'
assert_text "run branch in a worktree" 'git worktree add -b loop/'
assert_text "two failed tries cut the item" 'two failed tries'
assert_text "keeps the best version" 'keep the best, not the latest'
assert_text "re-reads pillars and logs a verdict" 'pillars.*On track'
assert_text "blocked stops need tool calls" '8 consecutive blocked stops'
assert_text "defaults are logged when unattended" 'Default: '
[ -f "$SKILL_DIR/references/loop-log.md" ] && pass "ships the loop log reference" || fail "ships the loop log reference"
assert_text "links the log format reference" 'references/loop-log.md'
assert_text "hand-off runs verify" 'pnpm verify' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off runs record" 'pnpm record' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off sends files" 'SendUserFile' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off notifies" 'PushNotification' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off gives play links" 'Play it' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off links demo and tune" '\?demo=1., .\?tune' "$SKILL_DIR/references/hand-off.md"
assert_text "hand-off forbids merge, push, deploy, delete" 'not merge, push, deploy or delete' "$SKILL_DIR/references/hand-off.md"

assert_text "review cycle runs the UI pass" 'run the UI pass'
assert_text "UI pass reads the check ui shots" 'check/ui/' "$SKILL_DIR/references/ui-pass.md"
assert_text "UI pass fixes ui layout FAILs" 'ui layout. FAIL' "$SKILL_DIR/references/ui-pass.md"
assert_text "UI pass holds screens to game-design ui-ux" 'game-design.*ui-ux.md' "$SKILL_DIR/references/ui-pass.md"
UIUX="$REPO_ROOT/skills/game/game-design/references/ui-ux.md"
assert_text "ui-ux: one strongest action per screen" 'one strongest action' "$UIUX"
assert_text "UI pass: one spacing scale" 'one spacing scale' "$SKILL_DIR/references/ui-pass.md"
assert_text "UI pass: ui-polish only if installed" 'ui-polish. is installed' "$SKILL_DIR/references/ui-pass.md"
UIPASS="$SKILL_DIR/references/ui-pass.md"
assert_text "ui-ux: one decision per screen" 'one decision per screen' "$UIUX"
assert_text "ui-ux: icons in the grid, detail on focus" 'icons.*only the focused item shows detail' "$UIUX"
assert_text "ui-ux: detail shown once" 'shows detail, once' "$UIUX"
assert_text "ui-ux: hide locked items" 'hide locked items' "$UIUX"
assert_text "ui-ux: no permanent controls legend" 'no permanent legend' "$UIUX"
assert_text "ui-ux: HUD in two tiers, at most 5 groups" 'two tiers.*at most 5 groups' "$UIUX"
assert_text "UI pass: acts on new ui layout INFO lines" 'duplicate phrases.*font-size count' "$UIPASS"
assert_text "the list, not the clock, decides the end" 'the list, not the clock, decides the end'
assert_text "review cycles list new ideas" 'list new ideas'
assert_text "done needs two dry reviews" 'two dry reviews in a row'
assert_text "the budget is a ceiling" 'budget is a ceiling'
assert_text "documents Status: stopped for the user" 'Status: stopped. is the user.s early exit'
assert_text "log reference documents dry reviews" 'review: dry' "$SKILL_DIR/references/loop-log.md"
assert_text "log reference documents stopped" 'stopped. is the user.s early exit' "$SKILL_DIR/references/loop-log.md"
assert_text "hand-off sets done if not already" 'set .Status: done. if it is not already' "$SKILL_DIR/references/hand-off.md"
assert_text "checks the Stop hook is installed" 'names .loop-stop.sh.'
assert_text "works in place on an existing branch" 'work in place on that branch'
PROFILES="$SKILL_DIR/references"
assert_text "game rules only under the game profile" 'Game rules apply only under the game profile'
assert_text "game profile: sound the game-feel way" 'game-feel. way' "$PROFILES/profile-game.md"
assert_text "game profile: game-design review order" 'Reviewing a build' "$PROFILES/profile-game.md"
assert_text "game profile: holds screens to ui-ux" 'game-design.*ui-ux.md' "$PROFILES/profile-game.md"
for profile in experiment site; do
  if grep -qE 'game-feel|game-design|HUD' "$PROFILES/profile-$profile.md"; then fail "$profile profile has no game rules" "$(grep -nE 'game-feel|game-design|HUD' "$PROFILES/profile-$profile.md")"; else pass "$profile profile has no game rules"; fi
done
if awk 'NR > 1 && /^---$/ { body = 1; next } body' "$SKILL" | grep -qE 'game-feel|Reviewing a build'; then fail "SKILL.md leaves game rules to the profile"; else pass "SKILL.md leaves game rules to the profile"; fi
DIRECTIONS="$SKILL_DIR/references/directions.md"
assert_text "links the directions sources" 'references/directions.md'
assert_text "directions: asks for the source" 'Ask the user which one' "$DIRECTIONS"
assert_text "directions: GitHub sub-issues in order" 'sub_issues' "$DIRECTIONS"
assert_text "directions: scratch tickets set to done" 'Status:. to .done' "$DIRECTIONS"
assert_text "directions: GitHub closed only at hand-off" 'at hand-off.*gh issue close' "$DIRECTIONS"
assert_text "directions: no other tracker writes" 'never assign, label, reopen or create tickets' "$DIRECTIONS"

# start-run.sh, hermetic
make_app() { # <dir>
  mkdir -p "$1"
  cp "$FIXTURE_BRIEF" "$1/BRIEF.md"
  printf '# Loop: __TITLE__\nBrief: BRIEF.md\nStarted:\nBudget:\nMode:\nAttempts:\nStatus:\n\n## Directions\n\n## Cycles\n\n## Notes\n\n## Open items\n' >"$1/LOOP.md"
}
repo="$work/repo"
mkdir -p "$repo"
git -C "$repo" init -q
make_app "$repo/apps/coin-dash"
session_folder="$work/session"
mkdir -p "$session_folder"
git -C "$session_folder" init -q
start_output=$(cd "$session_folder" && "$START" --app-dir "$repo/apps/coin-dash" --budget 20cycles --mode overnight --title "Coin Dash" --session-id s1 2>&1) &&
  pass "start-run.sh runs" || fail "start-run.sh runs" "$start_output"
log="$repo/apps/coin-dash/LOOP.md"
for expected in '^Budget: 20 cycles$' '^Mode: overnight$' '^Attempts: 1$' '^Status: running$' '^Started: .*Z$' '^- \[ \] Make the coins pop' '^- \[ \] Tighten the timer'; do
  grep -qE -- "$expected" "$log" && pass "log has $expected" || fail "log has $expected" "$(cat "$log")"
done
[ "$(grep -c '^- \[ \]' "$log")" -eq 3 ] && pass "three directions from the brief" || fail "three directions from the brief"
[ "$(jq -r .session_id "$session_folder/.loop-active")" = s1 ] && pass "marker has the session id" || fail "marker has the session id"
[ "$(jq -r .log "$session_folder/.loop-active")" = "$log" ] && pass "marker names the log" || fail "marker names the log"
grep -qxF '.loop-active*' "$repo/.gitignore" && pass "run repo ignores the marker" || fail "run repo ignores the marker"
grep -qxF '.loop-active*' "$session_folder/.git/info/exclude" && pass "session repo ignores the marker" || fail "session repo ignores the marker"
hook_output=$(jq -n --arg cwd "$session_folder" '{session_id: "s1", cwd: $cwd}' | bash "$HOOK" 2>&1)
if [ "$(jq -r .decision <<<"$hook_output" 2>/dev/null)" = block ] && jq -r .reason <<<"$hook_output" | grep -qF 'Make the coins pop'; then
  pass "the hook accepts the log and hands out the first direction"
else fail "the hook accepts the log and hands out the first direction" "$hook_output"; fi

( cd "$session_folder" && "$START" --app-dir "$repo/apps/coin-dash" --budget 45m >/dev/null 2>&1 ) && pass "restart without cycles is allowed" || fail "restart without cycles is allowed"
grep -qE '^Budget: 45 minutes, ends .*Z$' "$log" && pass "minutes budget has an end time" || fail "minutes budget has an end time"
sed -i.bak '/^## Cycles/a\
- 1 2026-06-01T11:10:00Z did a thing
' "$log" && rm -f "$log.bak"
if ( cd "$session_folder" && "$START" --app-dir "$repo/apps/coin-dash" >/dev/null 2>&1 ); then fail "refuses to overwrite cycles"; else pass "refuses to overwrite cycles"; fi

# --directions-from replaces the brief's list; ticked lines stay ticked
printf -- '- [x] Build the hub (#327)\nTime of day (#318)\n\n2. Night city (#319)\n- [X] Entrance\n' >"$work/directions.txt"
( cd "$session_folder" && "$START" --app-dir "$repo/apps/coin-dash" --directions-from "$work/directions.txt" --force >/dev/null 2>&1 ) &&
  pass "start-run.sh takes --directions-from" || fail "start-run.sh takes --directions-from"
directions_section=$(awk '/^## / { in_section = ($0 == "## Directions"); next } in_section && /^- /' "$log")
expected_directions=$(printf -- '- [x] Build the hub (#327)\n- [ ] Time of day (#318)\n- [ ] Night city (#319)\n- [x] Entrance')
[ "$directions_section" = "$expected_directions" ] && pass "directions come from the file, ticks kept" || fail "directions come from the file, ticks kept" "$directions_section"
hook_output=$(jq -n --arg cwd "$session_folder" '{session_id: "s1", cwd: $cwd}' | bash "$HOOK" 2>&1)
jq -r .reason <<<"$hook_output" | grep -qF 'Time of day (#318)' && pass "the hook skips a ticked direction" || fail "the hook skips a ticked direction" "$hook_output"
if ( cd "$session_folder" && "$START" --app-dir "$repo/apps/coin-dash" --directions-from "$work/missing.txt" --force >/dev/null 2>&1 ); then fail "refuses a missing directions file"; else pass "refuses a missing directions file"; fi

# A session inside the run's repo (working in place): info/exclude only, the tracked .gitignore is left alone
in_place="$work/in-place"
mkdir -p "$in_place"
git -C "$in_place" init -q
make_app "$in_place/docs/world"
( cd "$in_place" && "$START" --app-dir "$in_place/docs/world" --budget 20cycles --session-id s2 >/dev/null 2>&1 ) &&
  pass "start-run.sh runs in place" || fail "start-run.sh runs in place"
[ ! -e "$in_place/.gitignore" ] && pass "in place: no .gitignore edit" || fail "in place: no .gitignore edit" "$(cat "$in_place/.gitignore")"
grep -qxF '.loop-active*' "$in_place/.git/info/exclude" && pass "in place: info/exclude ignores the marker" || fail "in place: info/exclude ignores the marker"
[ -z "$(git -C "$in_place" status --short --untracked-files=all -- .loop-active)" ] && pass "in place: marker is not untracked" || fail "in place: marker is not untracked"

# Opt-in dry run against a lab checkout. Needs pnpm, a built lab and a browser; set LAB_ROOT to a throwaway lab worktree.
if [ -n "${LAB_ROOT:-}" ]; then
  app=loop-dry-run
  rm -rf "$LAB_ROOT/apps/games/$app"
  lab_status_before=$(git -C "$LAB_ROOT" status --short)
  cleanup_lab() { rm -rf "$LAB_ROOT/apps/games/$app"; git -C "$LAB_ROOT" checkout -q -- pnpm-lock.yaml .gitignore 2>/dev/null; }
  lab_cleanup=cleanup_lab
  if (cd "$LAB_ROOT" && pnpm create-app game "$app" >"$work/create.log" 2>&1); then pass "dry run: scaffolds from the game template"; else fail "dry run: scaffolds from the game template" "$(tail -5 "$work/create.log")"; fi
  cp "$FIXTURE_BRIEF" "$LAB_ROOT/apps/games/$app/BRIEF.md"
  run_folder="$work/dry-session"
  mkdir -p "$run_folder"
  if (cd "$run_folder" && "$START" --app-dir "$LAB_ROOT/apps/games/$app" --budget 20cycles --title "Coin Dash" --session-id dry >/dev/null 2>&1); then pass "dry run: writes the loop log"; else fail "dry run: writes the loop log"; fi
  dry_hook=$(jq -n --arg cwd "$run_folder" '{session_id: "dry", cwd: $cwd}' | bash "$HOOK" 2>&1)
  [ "$(jq -r .decision <<<"$dry_hook" 2>/dev/null)" = block ] && pass "dry run: the hook reads the log" || fail "dry run: the hook reads the log" "$dry_hook"
  if (cd "$LAB_ROOT" && pnpm check "$app" >"$work/check.log" 2>&1); then pass "dry run: pnpm check is green"; else fail "dry run: pnpm check is green" "$(tail -25 "$work/check.log")"; fi
  cleanup_lab
  [ "$(git -C "$LAB_ROOT" status --short)" = "$lab_status_before" ] && pass "dry run: lab left as found" || fail "dry run: lab left as found"
else
  echo "skip dry run (run it with: LAB_ROOT=<path to a throwaway lab worktree> bash tests/creative-loop-skill.test.sh)"
fi

[ "$failures" -eq 0 ] || exit 1
