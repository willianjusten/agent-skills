#!/bin/bash
# Tests for the conductor: RUN.md resume parsing and budget stops (run_state.py),
# the agent and skill frontmatter, and the dependency declaration that
# `install.sh check` validates.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO_ROOT/skills/orchestration/conduct/scripts/run_state.py"
AGENT="$REPO_ROOT/agents/orchestration/conductor.md"
SKILL="$REPO_ROOT/skills/orchestration/conduct/SKILL.md"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

frontmatter() { awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1"; }
field() { frontmatter "$1" | awk -v key="$2" -F': *' '$1 == key { print $2; exit }'; }
meta() { frontmatter "$1" | awk -v key="$2" '$1 == key ":" { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }'; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
run="$work/RUN.md"

next_state() { python3 -I "$SCRIPT" next "$run"; }
expect_next() {
  local description="$1" expected="$2" actual
  actual=$(next_state 2>&1)
  [ "$actual" = "$expected" ] && pass "$description" || fail "$description" "expected '$expected', got '$actual'"
}

[ -f "$SCRIPT" ] || { fail "run_state.py exists"; exit 1; }

# next: resume parsing
rm -f "$run"
expect_next "no RUN.md means start" "start"

cat >"$run" <<'LOG'
# RUN

- 2026-11-19T01:00:00Z | start | pitch=PITCH.md rounds=6 hours=4
- 2026-11-19T01:05:00Z | step | brief written
- 2026-11-19T01:10:00Z | assumption | art bible approved on Will's behalf
LOG
expect_next "an unfinished step resumes after the last step" "continue: art bible approved on Will's behalf"

echo "- 2026-11-19T01:30:00Z | stop | target-frames | 3 target frames ready, review packet .verify/x/review-packet.html" >>"$run"
expect_next "a stop with no answer keeps waiting" "waiting: target-frames"

echo "- 2026-11-19T01:30:05Z | note | notification fallback: target-frames" >>"$run"
expect_next "a note after a stop does not end the wait" "waiting: target-frames"
echo "- 2026-11-19T03:02:00Z | budget | hours=8" >>"$run"
expect_next "a budget line after a stop does not end the wait" "waiting: target-frames"

echo "- 2026-11-19T07:30:00Z | answer | approved target hero" >>"$run"
expect_next "an appended answer resumes the stopped phase" "resume: target-frames | approved target hero"
echo "- 2026-11-19T07:30:30Z | budget | hours=8" >>"$run"
expect_next "a budget line after the answer still resumes with the answer" "resume: target-frames | approved target hero"

echo "- 2026-11-19T07:31:00Z | resume | from target-frames" >>"$run"
expect_next "after resume the run continues" "continue: from target-frames"

echo "- 2026-11-19T09:00:00Z | done | delivered" >>"$run"
expect_next "a done run stays done" "done"

printf '%s\n' 'garbage line' '- not | a | valid timestamp' >"$work/junk.md"
if python3 -I "$SCRIPT" next "$work/junk.md" >/dev/null 2>&1; then
  pass "lines that are not entries are ignored"
else
  fail "lines that are not entries are ignored"
fi

# budget
budget() { python3 -I "$SCRIPT" budget "$run" --now "$1"; }
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md rounds=1 hours=4
- 2026-11-19T01:20:00Z | step | first playable
LOG
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 0 ] && [ "$out" = "ok" ] && pass "a fresh run is inside budget" || fail "a fresh run is inside budget" "$out"

echo "- 2026-11-19T02:00:00Z | round | 1 | kept lighting" >>"$run"
out=$(budget 2026-11-19T02:10:00Z); status=$?
[ "$status" -eq 3 ] && [ "$out" = "stop: rounds spent (1 of 1)" ] && pass "a budget of 1 round stops after one round" || fail "a budget of 1 round stops after one round" "status $status: $out"

echo "- 2026-11-19T02:15:00Z | budget | rounds=3" >>"$run"
out=$(budget 2026-11-19T02:20:00Z); status=$?
[ "$status" -eq 0 ] && pass "a budget entry from the user raises the limit" || fail "a budget entry from the user raises the limit" "status $status: $out"

out=$(budget 2026-11-19T05:30:00Z); status=$?
[ "$status" -eq 3 ] && echo "$out" | grep -q "hours spent" && pass "hours spent stops the run" || fail "hours spent stops the run" "status $status: $out"

echo "- 2026-11-19T05:40:00Z | resume | from budget" >>"$run"
out=$(budget 2026-11-19T06:00:00Z); status=$?
[ "$status" -eq 0 ] && pass "a sitting that ended without a stop counts only to its last entry" || fail "a sitting that ended without a stop counts only to its last entry" "status $status: $out"

# hours are active run time summed across sittings, not the time since the last resume
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T03:00:00Z | stop | target-frames | pick one | packet.md
- 2026-11-19T09:00:00Z | answer | the second one
- 2026-11-19T10:00:00Z | resume | from target-frames
LOG
out=$(budget 2026-11-19T11:30:00Z); status=$?
[ "$status" -eq 0 ] && pass "the wait for an answer does not use up hours" || fail "the wait for an answer does not use up hours" "status $status: $out"
out=$(budget 2026-11-19T14:30:00Z); status=$?
[ "$status" -eq 3 ] && [ "$out" = "stop: hours spent (6.5 of 6)" ] && pass "hours add up across sittings" || fail "hours add up across sittings" "status $status: $out"
echo "- 2026-11-19T14:00:00Z | budget | hours=8" >>"$run"
out=$(budget 2026-11-19T14:30:00Z); status=$?
[ "$status" -eq 0 ] && pass "a budget entry raises the hours limit" || fail "a budget entry raises the hours limit" "status $status: $out"

# lines the user writes while the run waits do not count as run time
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T02:00:00Z | step | first playable
- 2026-11-19T09:00:00Z | answer | use packs
- 2026-11-19T09:05:00Z | budget | hours=6
- 2026-11-19T10:00:00Z | resume | from first playable
LOG
out=$(python3 -I "$SCRIPT" budget "$run" --now 2026-11-19T14:30:00Z); status=$?
[ "$status" -eq 0 ] && pass "answer and budget lines after a crashed sitting do not extend it" || fail "answer and budget lines after a crashed sitting do not extend it" "status $status: $out"
out=$(python3 -I "$SCRIPT" budget "$run" --now 2026-11-19T15:30:00Z); status=$?
[ "$status" -eq 3 ] && [ "$out" = "stop: hours spent (6.5 of 6)" ] && pass "the crashed sitting counts to its last run entry" || fail "the crashed sitting counts to its last run entry" "status $status: $out"

printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$run"
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 0 ] && pass "defaults are 6 rounds and 6 hours" || fail "defaults are 6 rounds and 6 hours" "$out"
out=$(budget 2026-11-19T07:30:00Z); status=$?
[ "$status" -eq 3 ] && [ "$out" = "stop: hours spent (6.5 of 6)" ] && pass "the default hour budget is 6" || fail "the default hour budget is 6" "status $status: $out"
for round in 1 2 3 4 5 6; do echo "- 2026-11-19T01:3${round}:00Z | round | $round | x" >>"$run"; done
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 3 ] && echo "$out" | grep -q "6 of 6" && pass "the default round budget is 6" || fail "the default round budget is 6" "$out"

# a bad clock value is named, not a traceback
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$run"
out=$(budget not-a-time 2>&1); status=$?
{ [ "$status" -ne 0 ] && ! echo "$out" | grep -q Traceback && echo "$out" | grep -q "not-a-time"; } && pass "a bad --now is named, not a traceback" || fail "a bad --now is named, not a traceback" "$out"

# agent and skill
[ -f "$AGENT" ] && pass "the conductor agent exists under agents/orchestration" || fail "the conductor agent exists under agents/orchestration"
[ "$(field "$AGENT" name)" = "conductor" ] && pass "the agent name equals its file name" || fail "the agent name equals its file name"
[ "$(field "$AGENT" model)" = "fable" ] && pass "the conductor runs on fable" || fail "the conductor runs on fable"
tools=$(field "$AGENT" tools)
echo "$tools" | grep -qw Agent && echo "$tools" | grep -qw PushNotification && ! echo "$tools" | grep -qi spoke \
  && pass "the conductor can spawn agents and notify, with no Spoke tool" || fail "the conductor can spawn agents and notify, with no Spoke tool" "$tools"
uses=$(meta "$AGENT" uses)
for dependency in polish-director realtime-judge target-loop art-bible three-verify motion-review ideation game-brief creative-brief; do
  echo " $uses " | grep -q " $dependency " && pass "the conductor names $dependency in uses" || fail "the conductor names $dependency in uses"
done
grep -rEn '/Users/[a-z]|/home/[a-z]' "$AGENT" "$SKILL" >/dev/null && fail "conductor files have no machine paths" || pass "conductor files have no machine paths"
frontmatter "$SKILL" | grep -q '^disable-model-invocation: true' && pass "/conduct runs only by name" || fail "/conduct runs only by name"
[ "$(field "$SKILL" name)" = "conduct" ] && pass "the skill name equals its folder" || fail "the skill name equals its folder"
[ -f "$REPO_ROOT/skills/orchestration/conduct/README.md" ] && pass "the skill has a README" || fail "the skill has a README"

# run lock: one conductor per RUN.md
lock="$work/RUN.md.lock"
rm -f "$lock"
lock_cmd() { python3 -I "$SCRIPT" lock "$@"; }
lock_cmd status "$run" 2>&1 | grep -q '^free' && pass "lock: no lock file reads as free" || fail "lock: no lock file reads as free"
output=$(lock_cmd acquire "$run" --owner alpha --now 2026-11-19T01:00:00Z 2>&1)
{ [ $? -eq 0 ] && [ -f "$lock" ]; } && pass "lock: acquire creates the lock" || fail "lock: acquire creates the lock" "$output"
grep -q 'alpha' "$lock" && grep -q '2026-11-19T01:00:00Z' "$lock" && pass "lock: file holds owner and start time" || fail "lock: file holds owner and start time" "$(cat "$lock")"
output=$(lock_cmd acquire "$run" --owner beta --now 2026-11-19T01:10:00Z 2>&1)
status=$?
{ [ "$status" -eq 4 ] && echo "$output" | grep -q 'alpha'; } && pass "lock: a second owner is refused with exit 4 naming the holder" || fail "lock: a second owner is refused with exit 4 naming the holder" "status $status: $output"
grep -q 'alpha' "$lock" && pass "lock: a refused acquire leaves the holder in place" || fail "lock: a refused acquire leaves the holder in place"
lock_cmd acquire "$run" --owner alpha --now 2026-11-19T01:20:00Z >/dev/null 2>&1 && grep -q '2026-11-19T01:20:00Z' "$lock" && pass "lock: the holder re-acquiring refreshes the lock" || fail "lock: the holder re-acquiring refreshes the lock"
output=$(lock_cmd release "$run" --owner beta 2>&1)
{ [ $? -eq 4 ] && [ -f "$lock" ]; } && pass "lock: another owner cannot release" || fail "lock: another owner cannot release" "$output"
lock_cmd release "$run" --owner alpha >/dev/null 2>&1 && [ ! -f "$lock" ] && pass "lock: the holder releases" || fail "lock: the holder releases"
lock_cmd release "$run" --owner alpha >/dev/null 2>&1 && pass "lock: releasing a free lock is fine" || fail "lock: releasing a free lock is fine"
lock_cmd acquire "$run" --owner alpha --now 2026-11-19T01:00:00Z >/dev/null 2>&1
output=$(lock_cmd acquire "$run" --owner beta --now 2026-11-19T02:59:00Z 2>&1)
[ $? -eq 4 ] && pass "lock: just under the stale timeout is still held" || fail "lock: just under the stale timeout is still held" "$output"
output=$(lock_cmd acquire "$run" --owner beta --now 2026-11-19T03:01:00Z 2>&1)
{ [ $? -eq 0 ] && grep -q 'beta' "$lock" && echo "$output" | grep -qi 'stale'; } && pass "lock: past the stale timeout the lock is taken over" || fail "lock: past the stale timeout the lock is taken over" "$output"
lock_cmd status "$run" --now 2026-11-19T03:02:00Z 2>&1 | grep -q 'held by beta' && pass "lock: status names the holder" || fail "lock: status names the holder"
rm -f "$lock"
grep -q "run_state.py lock acquire" "$SKILL" && pass "/conduct checks the lock" || fail "/conduct checks the lock"
grep -q "run_state.py\` lock acquire\|run_state.py lock acquire" "$AGENT" && grep -q "lock release" "$AGENT" && pass "the conductor takes and releases the lock" || fail "the conductor takes and releases the lock"

# resume after a cut-off: a recorded round branch with later commits is read, not redone
repo="$work/repo"
git init -q "$repo" && git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
base_sha=$(git -C "$repo" rev-parse HEAD)
git -C "$repo" branch round-1
mkdir -p "$repo/app"
cutoff_run="$repo/app/RUN.md"
cat >"$cutoff_run" <<LOG
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:10:00Z | round-start | 1 | branch=round-1 base=$base_sha
LOG
output=$(python3 -I "$SCRIPT" next "$cutoff_run" 2>&1)
[ "$output" = "redo: round 1" ] && pass "a round branch with no new commits is redone" || fail "a round branch with no new commits is redone" "$output"
git -C "$repo" checkout -q round-1 && git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m "polish: lighting"
output=$(python3 -I "$SCRIPT" next "$cutoff_run" 2>&1)
[ "$output" = "read result: round 1 branch round-1" ] && pass "a round branch with later commits is read, not redone" || fail "a round branch with later commits is read, not redone" "$output"
echo "- 2026-11-19T02:00:00Z | round | 1 | lighting kept" >>"$cutoff_run"
output=$(python3 -I "$SCRIPT" next "$cutoff_run" 2>&1)
[ "$output" = "continue: 1 | lighting kept" ] && pass "a logged round is no longer pending" || fail "a logged round is no longer pending" "$output"
grep -q "round-start" "$AGENT" && grep -q "read result" "$AGENT" && grep -q "redo" "$AGENT" && pass "the conductor records the round branch and states the resume rule" || fail "the conductor records the round branch and states the resume rule"

# nesting: main -> conductor -> polish-director -> worker or judge, three levels at most
if grep -rEn 'claude +(--agent|-p)' "$REPO_ROOT/skills" "$REPO_ROOT/agents" "$REPO_ROOT/README.md" >/dev/null; then
  fail "no headless claude launch in skills, agents or the README" "$(grep -rEn 'claude +(--agent|-p)' "$REPO_ROOT/skills" "$REPO_ROOT/agents" "$REPO_ROOT/README.md" | head -5)"
else
  pass "no headless claude launch in skills, agents or the README"
fi
for spawner in "$AGENT" "$REPO_ROOT/agents/realtime/polish-director.md"; do
  field "$spawner" tools | grep -qw Agent && pass "$(basename "$spawner") has the Agent tool" || fail "$(basename "$spawner") has the Agent tool"
done
for leaf in polish-worker visual-judge feel-judge motion-judge; do
  field "$REPO_ROOT/agents/realtime/$leaf.md" tools | grep -qw Agent && fail "$leaf has no Agent tool, so depth stops at three" || pass "$leaf has no Agent tool, so depth stops at three"
done
grep -q "run_in_background" "$SKILL" && grep -q "Agent tool" "$SKILL" && pass "/conduct starts the conductor as a background subagent" || fail "/conduct starts the conductor as a background subagent"
grep -q "polish-director" "$AGENT" && grep -q "Agent tool" "$AGENT" && pass "the conductor runs the director as a nested subagent" || fail "the conductor runs the director as a nested subagent"
grep -q "Nesting" "$AGENT" && pass "the conductor documents the nesting depth" || fail "the conductor documents the nesting depth"

# install check accepts the declared uses
if output=$(cd "$REPO_ROOT" && ./install.sh check 2>&1); then
  pass "install.sh check passes with the conductor's uses"
else
  fail "install.sh check passes with the conductor's uses" "$(echo "$output" | grep '^ERROR' | head -5)"
fi

[ "$failures" -eq 0 ] || exit 1
