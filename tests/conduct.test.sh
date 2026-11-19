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

echo "- 2026-11-19T07:30:00Z | answer | approved target hero" >>"$run"
expect_next "an appended answer resumes the stopped phase" "resume: target-frames | approved target hero"

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
[ "$status" -eq 0 ] && pass "the hour clock restarts at a resume" || fail "the hour clock restarts at a resume" "status $status: $out"

printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$run"
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 0 ] && pass "defaults are 6 rounds and 4 hours" || fail "defaults are 6 rounds and 4 hours" "$out"
for round in 1 2 3 4 5 6; do echo "- 2026-11-19T01:3${round}:00Z | round | $round | x" >>"$run"; done
out=$(budget 2026-11-19T02:00:00Z); status=$?
[ "$status" -eq 3 ] && echo "$out" | grep -q "6 of 6" && pass "the default round budget is 6" || fail "the default round budget is 6" "$out"

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

# install check accepts the declared uses
if output=$(cd "$REPO_ROOT" && ./install.sh check 2>&1); then
  pass "install.sh check passes with the conductor's uses"
else
  fail "install.sh check passes with the conductor's uses" "$(echo "$output" | grep '^ERROR' | head -5)"
fi

[ "$failures" -eq 0 ] || exit 1
