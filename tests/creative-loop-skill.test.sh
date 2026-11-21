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
[ "$(meta "$SKILL" uses)" = "ideation brief three-build game-feel" ] && pass "uses the four skills" || fail "uses the four skills" "$(meta "$SKILL" uses)"
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
assert_text "hand-off forbids merge, push, deploy, delete" 'not merge, push, deploy or delete' "$SKILL_DIR/references/hand-off.md"

assert_text "the list, not the clock, decides the end" 'the list, not the clock, decides the end'
assert_text "review cycles list new ideas" 'list new ideas'
assert_text "done needs two dry reviews" 'two dry reviews in a row'
assert_text "the budget is a ceiling" 'budget is a ceiling'
assert_text "documents Status: stopped for the user" 'Status: stopped. is the user.s early exit'
assert_text "log reference documents dry reviews" 'review: dry' "$SKILL_DIR/references/loop-log.md"
assert_text "log reference documents stopped" 'stopped. is the user.s early exit' "$SKILL_DIR/references/loop-log.md"
assert_text "hand-off sets done if not already" 'set .Status: done. if it is not already' "$SKILL_DIR/references/hand-off.md"

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
