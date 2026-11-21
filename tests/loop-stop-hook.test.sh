#!/bin/bash
# Tests for harness/claude/hooks/loop-stop.sh, the Stop hook of long runs: it blocks
# the stop with the next direction or the review-cycle instruction while budget
# remains, and allows it when the budget is spent, the run is done, no run is
# active, or the agent stopped twice with nothing changed. Format: skills/orchestration/creative-loop/references/loop-log.md.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/loop-stop.sh"
. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
run="$work/run"
mkdir -p "$run/sub"
git -C "$run" init -q
now=$(date -u -d '2026-06-01T12:00:00Z' +%s 2>/dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' 2026-06-01T12:00:00Z +%s)

# write_log <budget> <status> <direction lines...>; $extra_cycles adds lines under Cycles.
write_log() {
  local budget="$1" status="$2"
  shift 2
  {
    echo "# Loop: sample"
    echo "Brief: make it better"
    echo "Started: 2026-06-01T11:00:00Z"
    echo "Budget: $budget"
    echo "Mode: autonomous"
    echo "Attempts: 1"
    echo "Status: $status"
    echo
    echo "## Directions"
    printf '%s\n' "$@"
    echo
    echo "## Cycles"
    echo "- 1 2026-06-01T11:10:00Z first pass"
    [ -n "${extra_cycles:-}" ] && printf '%s\n' "$extra_cycles"
    echo
    echo "## Notes"
    echo "- [ ] not a direction"
  } >"$run/loop.md"
}
start_run() { echo '{"log": "loop.md"}' >"$run/.loop-active"; rm -f "$run/.loop-active.state"; }
# run_hook [cwd] [session]: sets hook_output and hook_status.
run_hook() {
  hook_output=$(jq -n --arg cwd "${1:-$run}" --arg sid "${2:-s1}" \
    '{session_id: $sid, cwd: $cwd, hook_event_name: "Stop", stop_hook_active: false}' |
    LOOP_NOW="$now" bash "$HOOK" 2>&1)
  hook_status=$?
}
expect_allow() {
  run_hook "${2:-}" "${3:-}"
  if [ "$hook_status" -eq 0 ] && [ -z "$hook_output" ]; then pass "$1"; else fail "$1" "$hook_status $hook_output"; fi
}
expect_block() { # <name> <reason fragment>
  run_hook
  if [ "$hook_status" -eq 0 ] && [ "$(jq -r .decision <<<"$hook_output" 2>/dev/null)" = "block" ] &&
    jq -r .reason <<<"$hook_output" | grep -qF -- "$2"; then pass "$1"; else fail "$1" "$hook_status $hook_output"; fi
}

write_log "45 minutes, ends 2026-06-01T12:45:00Z" running "- [x] done one" "- [ ] second direction" "- [ ] third"
expect_allow "allows outside a run (no marker)"
start_run
expect_block "blocks with the first unchecked direction" "second direction"
expect_allow "allows when the agent stops again with log and tree unchanged (loop breaker)"
echo "- [x] second direction" >>"$run/notes.txt"
expect_block "blocks again after the tree changed" "second direction"
start_run
expect_block "walking up from a subfolder finds the run" "second direction"
rm -f "$run/.loop-active.state"
sub_output=$(jq -n --arg cwd "$run/sub" '{session_id: "s1", cwd: $cwd}' | LOOP_NOW="$now" bash "$HOOK")
if [ "$(jq -r .decision <<<"$sub_output")" = "block" ]; then pass "a stop from a subfolder still blocks"; else fail "a stop from a subfolder still blocks" "$sub_output"; fi

write_log "45 minutes, ends 2026-06-01T12:45:00Z" running "- [x] done one" "- [x] second"
start_run
expect_block "falls back to the review-cycle instruction when every direction is checked" "review cycle"

write_log "45 minutes, ends 2026-06-01T11:59:00Z" running "- [ ] open"
start_run
expect_allow "allows when the end time has passed"

write_log "1 cycle" running "- [ ] open"
start_run
expect_allow "allows when the cycle budget is spent"
write_log "3 cycles" running "- [ ] open"
start_run
expect_block "blocks while cycles remain" "open"

write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [ ] open"
start_run
expect_block "blocks Status: done while budget remains, with the review cycle" "review cycle"
dry_two="- 2 2026-06-01T11:20:00Z review: dry, checked the brief, rejected a dash
- 3 2026-06-01T11:30:00Z Review: dry, checked menus, rejected a second boss"
extra_cycles="$dry_two" write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [x] one"
start_run
expect_allow "allows Status: done early after two dry reviews with every direction checked"
extra_cycles="- 2 2026-06-01T11:20:00Z review: dry, nothing found" write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [x] one"
start_run
expect_block "blocks Status: done after only one dry review" "dry reviews"
extra_cycles="- 2 2026-06-01T11:20:00Z review: dry, nothing found
- 3 2026-06-01T11:30:00Z added crates, the earlier review: dry was wrong" write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [x] one"
start_run
expect_block "a line that only mentions review: dry later does not count as a dry review" "dry reviews"
extra_cycles="$dry_two
- 4 2026-06-01T11:40:00Z added crates" write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [x] one"
start_run
expect_block "blocks Status: done when work followed the dry reviews" "review cycle"
extra_cycles="$dry_two" write_log "45 minutes, ends 2026-06-01T12:45:00Z" done "- [x] one" "- [ ] new idea"
start_run
expect_block "blocks Status: done with dry reviews but an open direction" "review cycle"
extra_cycles="$dry_two" write_log "45 minutes, ends 2026-06-01T12:45:00Z" running "- [x] one"
start_run
expect_block "blocks dry reviews while Status is still running" "review: dry"
write_log "45 minutes, ends 2026-06-01T12:45:00Z" stopped "- [ ] open"
start_run
expect_allow "allows when Status is stopped"
write_log "45 minutes, ends 2026-06-01T11:59:00Z" done "- [ ] open"
start_run
expect_allow "allows Status: done after the budget is spent"

write_log "45 minutes, ends 2026-06-01T12:45:00Z" running "- [ ] open"
echo '{"log": "loop.md", "session_id": "other"}' >"$run/.loop-active"
rm -f "$run/.loop-active.state"
expect_allow "allows for a session other than the marker's"
echo '{"log": "missing.md"}' >"$run/.loop-active"
expect_allow "allows when the log is missing"
start_run
echo "not json" | bash "$HOOK" >/dev/null 2>&1 && pass "allows on unparsable input" || fail "allows on unparsable input"

# A marker without a session id binds to the first session; a second one is allowed.
start_run
expect_block "a marker without a session id loops the first session" "open"
[ "$(jq -r .session_id "$run/.loop-active")" = s1 ] && pass "the hook binds the marker to that session" || fail "the hook binds the marker to that session"
expect_allow "a second session is not blocked" "" s2

# The loop breaker watches the repo that holds the log, not the session folder.
lab="$work/lab"
mkdir -p "$lab/app" "$work/session"
git -C "$lab" init -q
cp "$run/loop.md" "$lab/app/loop.md"
echo '{"log": "'"$lab"'/app/loop.md", "session_id": "s1"}' >"$work/session/.loop-active"
hook_in_session() {
  jq -n --arg cwd "$work/session" '{session_id: "s1", cwd: $cwd}' | LOOP_NOW="$now" bash "$HOOK" 2>&1
}
[ "$(jq -r .decision <<<"$(hook_in_session)")" = block ] && pass "lab run blocks" || fail "lab run blocks"
echo change >"$lab/app/work.txt"
[ "$(jq -r .decision <<<"$(hook_in_session)")" = block ] && pass "a change in the lab tree lets the next stop block again" || fail "a change in the lab tree lets the next stop block again"
[ -z "$(hook_in_session)" ] && pass "lab tree unchanged: loop breaker allows" || fail "lab tree unchanged: loop breaker allows"

# Stale marker: older than the budget plus a margin.
write_log "45 minutes, ends 2026-06-01T12:45:00Z" running "- [ ] open"
start_run
touch -t 202605010000 "$run/.loop-active"
expect_allow "allows a marker older than the budget plus a margin"

# A marker at or above HOME is ignored.
fake_home="$work/home"
mkdir -p "$fake_home/proj"
echo '{"log": "'"$run"'/loop.md"}' >"$work/.loop-active"
home_output=$(jq -n --arg cwd "$fake_home/proj" '{session_id: "s1", cwd: $cwd}' | HOME="$fake_home" LOOP_NOW="$now" bash "$HOOK" 2>&1)
[ -z "$home_output" ] && pass "ignores a marker above HOME" || fail "ignores a marker above HOME" "$home_output"
rm -f "$work/.loop-active"
echo '{"log": "'"$run"'/loop.md"}' >"$fake_home/.loop-active"
home_output=$(jq -n --arg cwd "$fake_home/proj" '{session_id: "s1", cwd: $cwd}' | HOME="$fake_home" LOOP_NOW="$now" bash "$HOOK" 2>&1)
[ -z "$home_output" ] && pass "ignores a marker at HOME" || fail "ignores a marker at HOME" "$home_output"

[ "$failures" -eq 0 ] || exit 1
