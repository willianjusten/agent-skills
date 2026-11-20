#!/bin/bash
# Tests for the conductor: RUN.md resume parsing and budget stops (run_state.py),
# the agent and skill frontmatter, and the dependency declaration that
# `install.sh check` validates (that gate runs before this suite).

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO_ROOT/skills/orchestration/conduct/scripts/run_state.py"
AGENT="$REPO_ROOT/agents/orchestration/conductor.md"
SKILL="$REPO_ROOT/skills/orchestration/conduct/SKILL.md"
REFERENCES="$REPO_ROOT/skills/orchestration/conduct/references"
. "$(dirname "$0")/lib.sh"


work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
run="$work/RUN.md"
# the conductor and the references it reads at its steps are one text for wording checks
CONDUCT_TEXT="$work/conduct-text.md"
cat "$AGENT" "$REFERENCES"/*.md >"$CONDUCT_TEXT"

next_state() { python3 -I "$SCRIPT" next "$run" --allow-missing; }
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
expect_next "an unfinished step resumes after the last step" "continue: phase=setup | last=assumption: art bible approved on Will's behalf"

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
expect_next "after resume the run continues" "continue: phase=setup | last=resume: from target-frames"

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
# process setting: the round limit follows process=minimal|standard|full
process_limits() { python3 -I "$SCRIPT" limits "$run"; }
for case in "minimal:2" "standard:6" "full:6"; do
  setting="${case%%:*}"; expected_rounds="${case##*:}"
  printf -- '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md process=%s\n' "$setting" >"$run"
  out=$(process_limits); status=$?
  [ "$status" -eq 0 ] && [ "$out" = "process=$setting rounds=$expected_rounds hours=6 autoAccepts=3" ] && pass "process=$setting reports $expected_rounds rounds" || fail "process=$setting reports $expected_rounds rounds" "status $status: $out"
done
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md" >"$run"
out=$(process_limits)
[ "$out" = "process=standard rounds=6 hours=6 autoAccepts=3" ] && pass "no process setting means standard" || fail "no process setting means standard" "$out"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md process=minimal rounds=4" >"$run"
out=$(process_limits)
[ "$out" = "process=minimal rounds=4 hours=6 autoAccepts=3" ] && pass "an explicit rounds= beats the process default" || fail "an explicit rounds= beats the process default" "$out"
echo "- 2026-11-19T02:00:00Z | budget | process=full" >>"$run"
out=$(process_limits)
[ "$out" = "process=full rounds=4 hours=6 autoAccepts=3" ] && pass "a budget line can change the process" || fail "a budget line can change the process" "$out"
printf -- '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md process=minimal\n- 2026-11-19T01:30:00Z | round | 1 | a\n- 2026-11-19T01:40:00Z | round | 2 | b\n' >"$run"
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 3 ] && [ "$out" = "stop: rounds spent (2 of 2)" ] && pass "process=minimal stops the budget after 2 rounds" || fail "process=minimal stops the budget after 2 rounds" "status $status: $out"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md process=turbo" >"$run"
out=$(process_limits 2>&1); status=$?
[ "$status" -eq 1 ] && echo "$out" | grep -q "minimal, standard or full" && pass "an unknown process is refused" || fail "an unknown process is refused" "status $status: $out"

out=$(budget not-a-time 2>&1); status=$?
{ [ "$status" -ne 0 ] && ! echo "$out" | grep -q Traceback && echo "$out" | grep -q "not-a-time"; } && pass "a bad --now is named, not a traceback" || fail "a bad --now is named, not a traceback" "$out"

# an answer with no stop pending is notes for the next round
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T02:00:00Z | stop | look-variants | pick a look | p.html
- 2026-11-19T02:30:00Z | answer | second look
- 2026-11-19T02:31:00Z | resume | from look-variants
- 2026-11-19T03:00:00Z | wip | first slice playable
LOG
expect_next "an answer after a stop still resumes the stop" "continue: phase=setup | last=wip: first slice playable"
echo "- 2026-11-19T03:10:00Z | answer | make the enemies slower" >>"$run"
out=$(next_state 2>&1)
[ "$out" = "$(printf 'continue: phase=setup | last=wip: first slice playable\nnotes for the next round: make the enemies slower')" ] \
  && pass "an answer with no pending stop is reported as notes, and the run keeps going" \
  || fail "an answer with no pending stop is reported as notes, and the run keeps going" "$out"
echo "- 2026-11-19T03:12:00Z | answer | and louder hits" >>"$run"
next_state | grep -c '^notes for the next round' | grep -qx 2 && pass "every unread answer is listed as notes" || fail "every unread answer is listed as notes"
cp "$run" "$work/notes.base"
echo "- 2026-11-19T03:15:00Z | resume | from first slice playable" >>"$run"
next_state | grep -c '^notes for the next round' | grep -qx 2 && pass "a resume line keeps the notes for the next round" || fail "a resume line keeps the notes for the next round"
cp "$work/notes.base" "$run"
echo "- 2026-11-19T03:20:00Z | step | round 1 reads the notes" >>"$run"
echo "- 2026-11-19T03:21:00Z | round-start | 1 | branch=none base=none" >>"$run"
echo "- 2026-11-19T03:30:00Z | answer | during the round" >>"$run"
expect_next "a round start consumes the notes, and an answer during the round is kept for the next" "$(printf 'redo: round 1 (branch check failed, read the branch before respawning)\nnotes for the next round: during the round')"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T02:00:00Z | stop | look-variants | pick a look | p.html
- 2026-11-19T02:30:00Z | answer | second look
LOG
expect_next "an answer right after a stop is an answer, not notes" "resume: look-variants | second look"

# phases: time per phase from `phase` lines, summed across sittings
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:10:00Z | phase | brief
- 2026-11-19T01:40:00Z | phase | first-playable
- 2026-11-19T02:40:00Z | stop | look-variants | pick one | packet.md
- 2026-11-19T09:00:00Z | answer | the second one
- 2026-11-19T10:00:00Z | resume | from look-variants
- 2026-11-19T10:30:00Z | note | aside
- 2026-11-19T10:45:00Z | phase | polish
- 2026-11-19T11:45:00Z | phase | first-playable
- 2026-11-19T12:00:00Z | done | delivered
LOG
phases() { python3 -I "$SCRIPT" phases "$run" --now "${1:-2026-11-19T13:00:00Z}"; }
expected=$'setup 10m\nbrief 30m\nfirst-playable 2h\npolish 1h\ntotal 3h 40m'
out=$(phases)
[ "$out" = "$expected" ] && pass "phases prints time per phase, summed across sittings, waiting excluded" || fail "phases prints time per phase, summed across sittings, waiting excluded" "$out"

cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:30:00Z | phase | brief
LOG
out=$(phases 2026-11-19T02:00:00Z)
[ "$out" = $'setup 30m\nbrief 30m\ntotal 1h' ] && pass "an open sitting counts to now" || fail "an open sitting counts to now" "$out"

printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$run"
out=$(phases 2026-11-19T01:20:00Z)
[ "$out" = $'setup 20m\ntotal 20m' ] && pass "a run with no phase line reports setup" || fail "a run with no phase line reports setup" "$out"
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
grep -q "run_state.py\` lock acquire\|run_state.py lock acquire" "$AGENT" && grep -q "lock release" "$CONDUCT_TEXT" && pass "the conductor takes and releases the lock" || fail "the conductor takes and releases the lock"

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
[ "$output" = "continue: phase=setup | last=round: 1 | lighting kept" ] && pass "a logged round is no longer pending" || fail "a logged round is no longer pending" "$output"
grep -q "round-start" "$CONDUCT_TEXT" && grep -q "read result" "$CONDUCT_TEXT" && grep -q "redo" "$CONDUCT_TEXT" && pass "the conductor records the round branch and states the resume rule" || fail "the conductor records the round branch and states the resume rule"

# notifications and the wip line
grep -q "PushNotification" "$SKILL" && grep -qi "main thread" "$SKILL" && grep -q "stop line" "$SKILL" && pass "/conduct sends the notification from the main thread with the stop line" || fail "/conduct sends the notification from the main thread with the stop line"
grep -qi "at every stop and at delivery\|every stop and at .done" "$SKILL" && pass "/conduct notifies at every stop and at delivery" || fail "/conduct notifies at every stop and at delivery"
grep -q 'append `wip |' "$AGENT" && grep -qi "keep going\|keeps going\|do not stop" "$AGENT" && pass "the conductor writes a wip line and keeps running" || fail "the conductor writes a wip line and keeps running"
grep -q "notes for the next round" "$CONDUCT_TEXT" && pass "the conductor reads unprompted answers as round notes" || fail "the conductor reads unprompted answers as round notes"

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
grep -q "polish-director" "$CONDUCT_TEXT" && grep -q "Agent tool" "$CONDUCT_TEXT" && pass "the conductor runs the director as a nested subagent" || fail "the conductor runs the director as a nested subagent"
grep -q "Nesting" "$CONDUCT_TEXT" && pass "the conductor documents the nesting depth" || fail "the conductor documents the nesting depth"

grep -q "run_state.py.* phases\|\`phases\`" "$CONDUCT_TEXT" && grep -q '^- `phase`: text is the phase name' "$CONDUCT_TEXT" && pass "the conductor logs phases and reads their timing" || fail "the conductor logs phases and reads their timing"
hand_off=$(cat "$REFERENCES/hand-off.md")
echo "$hand_off" | grep -qi "phase timing" && pass "the hand-off template includes phase timing" || fail "the hand-off template includes phase timing"

# process setting text: the skill, the conductor and the README name it
grep -q 'process=minimal|standard|full' "$SKILL" && pass "conduct accepts process=" || fail "conduct accepts process="
grep -q 'no art bible document' "$CONDUCT_TEXT" && grep -q 'reference discrimination judge' "$CONDUCT_TEXT" && grep -q 'limits' "$AGENT" && pass "the conductor describes what each process setting changes" || fail "the conductor describes what each process setting changes"

# the process table in run-md.md is the one place the round counts are written: it matches run_state.py
for setting in minimal standard full; do
  table_rounds=$(grep "^| \`$setting\` |" "$REFERENCES/run-md.md" | awk -F'|' '{gsub(/ /, "", $4); print $4}')
  script_rounds=$(printf -- '- 2026-11-19T01:00:00Z | start | process=%s\n' "$setting" >"$run"; python3 -I "$SCRIPT" limits "$run" | sed 's/.*rounds=\([0-9]*\).*/\1/')
  [ -n "$table_rounds" ] && [ "$table_rounds" = "$script_rounds" ] && pass "run-md.md gives process=$setting $script_rounds rounds, as run_state.py does" || fail "run-md.md gives process=$setting $script_rounds rounds, as run_state.py does" "table '$table_rounds'"
done

# look variants: the first stop, look=auto and the optional target
look() { python3 -I "$SCRIPT" look "$run"; }
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:30:00Z | stop | look-variants | pick one of variants=dusk,neon,noon | packet.html
LOG
[ "$(look)" = "look=ask target=no
state=pending" ] && pass "a look-variants stop with no answer is pending, look=ask and no target by default" || fail "a look-variants stop with no answer is pending" "$(look)"
for case in "neon|chosen neon" "Noon, less bloom|chosen noon | less bloom" "pick dusk: warmer fog|chosen dusk | warmer fog" "the second, darker|unclear | the second, darker" "variant 2, darker|chosen neon | darker" "3|chosen noon" "mauve|unclear | mauve"; do
  answer="${case%%|*}"; expected="${case#*|}"
  cp "$run" "$work/look.base"
  echo "- 2026-11-19T02:00:00Z | answer | $answer" >>"$run"
  actual=$(look | tail -1)
  [ "$actual" = "state=$expected" ] && pass "answer '$answer' names a variant" || fail "answer '$answer' names a variant" "expected 'state=$expected', got '$actual'"
  cp "$work/look.base" "$run"
done
echo "- 2026-11-19T02:00:00Z | answer | neon, less bloom" >>"$run"
expect_next "the look answer resumes the look-variants stop" "resume: look-variants | neon, less bloom"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md look=auto target=yes
- 2026-11-19T01:30:00Z | assumption | look=auto dusk | fits the quiet harbour mood
LOG
[ "$(look)" = "look=auto target=yes
state=auto dusk" ] && pass "an assumption for look=auto names the picked preset" || fail "an assumption for look=auto names the picked preset" "$(look)"
expect_next "look=auto leaves no stop to wait for" "continue: phase=setup | last=assumption: look=auto dusk | fits the quiet harbour mood"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md look=auto
- 2026-11-19T01:30:00Z | assumption | look=auto dusk | fits the quiet harbour mood
- 2026-11-19T01:40:00Z | stop | look-variants | pick one of variants=dusk,neon,noon | packet.html
- 2026-11-19T02:00:00Z | answer | neon, warmer
LOG
[ "$(look | tail -1)" = "state=chosen neon | warmer" ] && pass "a later answer naming a variant overrides an earlier look=auto assumption" || fail "a later answer naming a variant overrides an earlier look=auto assumption" "$(look)"
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$run"
[ "$(look | tail -1)" = "state=none" ] && pass "a run with no look decision reports none" || fail "a run with no look decision reports none"

grep -q 'run_state.py` look' "$CONDUCT_TEXT" || grep -q 'run_state.py look' "$CONDUCT_TEXT" && grep -q 'verify <app> --variants' "$CONDUCT_TEXT" && grep -q 'stop | look-variants' "$AGENT" && pass "the conductor stops for look variants captured with verify --variants" || fail "the conductor stops for look variants captured with verify --variants"
grep -q 'look=auto' "$CONDUCT_TEXT" && grep -q 'assumption | look=auto' "$CONDUCT_TEXT" && grep -q 'target=yes' "$CONDUCT_TEXT" && pass "the conductor handles look=auto and the optional target" || fail "the conductor handles look=auto and the optional target"
grep -qi 'only a judge split, a failing gate, a spent budget and delivery' "$CONDUCT_TEXT" && pass "with look=auto the stops are judge split, failing gate, spent budget and delivery" || fail "with look=auto the stops are judge split, failing gate, spent budget and delivery"
grep -q 'chosen look' "$CONDUCT_TEXT" && grep -qi 'benchmark' "$CONDUCT_TEXT" && pass "the chosen look is the benchmark when no target exists" || fail "the chosen look is the benchmark when no target exists"
grep -q 'look=auto' "$SKILL" && pass "conduct accepts look=auto" || fail "conduct accepts look=auto"
grep -qi 'without a target' "$REPO_ROOT/skills/realtime/target-loop/SKILL.md" && grep -qi 'chose' "$REPO_ROOT/skills/realtime/target-loop/SKILL.md" && pass "target-loop uses the chosen look as the benchmark with no target" || fail "target-loop uses the chosen look as the benchmark with no target"
grep -qi 'no target, the capture of the look the user chose' "$REPO_ROOT/skills/realtime/realtime-judge/SKILL.md" && pass "realtime-judge benchmarks against the chosen look with no target" || fail "realtime-judge benchmarks against the chosen look with no target"

# baseline, feature list and balance band
GDD_TEMPLATE="$REPO_ROOT/skills/game/game-brief/references/gdd-template.md"
grep -q '"Baseline" component' "$CONDUCT_TEXT" && grep -q 'without asking' "$CONDUCT_TEXT" && grep -q 'results.json' "$CONDUCT_TEXT" && pass "the conductor adds a Baseline component from the baseline check" || fail "the conductor adds a Baseline component from the baseline check"
grep -q 'No <item>: <reason>' "$CONDUCT_TEXT" && grep -q 'DECISIONS.md' "$CONDUCT_TEXT" && grep -q 'assumption | baseline: no <item>' "$CONDUCT_TEXT" && pass "a ruled-out baseline item is skipped with a DECISIONS.md reason" || fail "a ruled-out baseline item is skipped with a DECISIONS.md reason"
grep -q 'src/features.ts' "$CONDUCT_TEXT" && grep -q 'outside its band' "$CONDUCT_TEXT" && grep -q 'COMPONENTS.md\|row' "$AGENT" && pass "the conductor turns failing features and out-of-band balance into rows" || fail "the conductor turns failing features and out-of-band balance into rows"
grep -q '^## Feature list' "$GDD_TEMPLATE" && grep -q '^## Balance band' "$GDD_TEMPLATE" && pass "the GDD template has the feature list and the balance band" || fail "the GDD template has the feature list and the balance band"
grep -q 'feature list' "$REPO_ROOT/skills/game/game-brief/SKILL.md" && grep -q 'balance band' "$REPO_ROOT/skills/game/game-brief/SKILL.md" && pass "game-brief fills the feature list and the balance band" || fail "game-brief fills the feature list and the balance band"


# review fixes: phases, process fallbacks, stops, resume wording
PHASES=$(python3 -I "$SCRIPT" phase-names | tr '\n' ' ')
listed=$(grep '^- `phase`: text is the phase name' "$REFERENCES/run-md.md" | sed 's/^[^:]*:[^:]*://' | grep -o '`[a-z-]*`' | tr -d '`' | tr '\n' ' ')
[ "$listed" = "$PHASES" ] && pass "run-md.md lists the phase names run_state.py reports, in run order" || fail "run-md.md lists the phase names run_state.py reports, in run order" "$listed vs $PHASES"
for phase in $PHASES; do
  grep -q "phase | $phase\`" "$AGENT" && pass "phase $phase is appended by a step" || fail "phase $phase is appended by a step"
done
grep -q 'at every round boundary' "$CONDUCT_TEXT" && pass "the conductor re-reads next at each round boundary" || fail "the conductor re-reads next at each round boundary"
grep -q 'phase=<name>' "$AGENT" && grep -q 'phase=<phase>' "$REFERENCES/run-md.md" && pass "continue resumes the phase the next line names" || fail "continue resumes the phase the next line names"
grep -q 'step 2 also fixes what step 3 would have' "$CONDUCT_TEXT" && grep -q 'from the brief and the pitch' "$CONDUCT_TEXT" && pass "process=minimal chooses the asset source in the brief and writes presets from the brief" || fail "process=minimal chooses the asset source in the brief and writes presets from the brief"
grep -q 'Only with `process=full`' "$CONDUCT_TEXT" && pass "the reference judge runs only with process=full" || fail "the reference judge runs only with process=full"
grep -q 'run_state.py limits RUN.md` prints' "$CONDUCT_TEXT" && ! grep -q '6 rounds, 6 hours of active run time per run' "$CONDUCT_TEXT" && pass "the budget stop reads the limits from run_state.py" || fail "the budget stop reads the limits from run_state.py"
grep -q 'regression moment' "$CONDUCT_TEXT" && grep -q 'regression moment: <name>' "$CONDUCT_TEXT" && pass "the conductor logs and passes the regression moment" || fail "the conductor logs and passes the regression moment"
DIRECTOR="$REPO_ROOT/agents/realtime/polish-director.md"
grep -q 'regression moment is a named capture' "$DIRECTOR" && grep -q 'judges the regression moment alone' "$DIRECTOR" && pass "the director fixes one named regression moment and handles a round with no changed capture" || fail "the director fixes one named regression moment and handles a round with no changed capture"
grep -q 'Under every setting, a round that changes combat' "$DIRECTOR" && pass "combat motion is judged from the recording under every process setting" || fail "combat motion is judged from the recording under every process setting"
grep -q -- '--questions' "$DIRECTOR" && grep -q 'no new `no` answer' "$DIRECTOR" && pass "the director passes --questions for still moments and rejects any new no" || fail "the director passes --questions for still moments and rejects any new no"
MOTION="$REPO_ROOT/skills/creative/motion-review/SKILL.md"
grep -q -- '--motion --from-recording <from>-<to>' "$MOTION" && grep -q 'play/play-contact-sheet.png' "$MOTION" && grep -q 'motion-play/judge/' "$MOTION" && grep -q 'cannot use `--against`' "$MOTION" && pass "motion-review documents the real-play recording range" || fail "motion-review documents the real-play recording range"
look_stops=$(sed -n '/^## Stop points/,/^At a stop/p' "$AGENT")
echo "$look_stops" | grep -q 'With `look=ask` (default) also: look variant chosen' && ! echo "$look_stops" | grep -q '^Always: look variant' && pass "the Always stop list holds only the stops that survive look=auto" || fail "the Always stop list holds only the stops that survive look=auto"

[ "$failures" -eq 0 ] || exit 1
