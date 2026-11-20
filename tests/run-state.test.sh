#!/bin/bash
# Tests for run_state.py at its command line: continue wording, missing files,
# malformed entries, accept counts, phase timing, locks and variant answers.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO_ROOT/skills/orchestration/conduct/scripts/run_state.py"
. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
run="$work/RUN.md"
state() { python3 -I "$SCRIPT" "$@"; }
expect() {
  local description="$1" expected="$2" actual
  shift 2
  actual=$("$@" 2>&1)
  [ "$actual" = "$expected" ] && pass "$description" || fail "$description" "expected '$expected', got '$actual'"
}

# continue names the phase and the last entry
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:10:00Z | phase | polish
- 2026-11-19T01:20:00Z | wip | playable | http://x
LOG
expect "continue names the last phase and the last entry with its kind" "continue: phase=polish | last=wip: playable | http://x" state next "$run"
printf -- '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md\n- 2026-11-19T01:05:00Z | step | scaffolded\n' >"$run"
expect "continue before any phase names setup" "continue: phase=setup | last=step: scaffolded" state next "$run"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:10:00Z | phase | brief
- 2026-11-19T01:20:00Z | stop | x | y | z
- 2026-11-19T02:20:00Z | answer | go
- 2026-11-19T02:21:00Z | resume | from x
- 2026-11-19T02:22:00Z | note | aside
LOG
expect "a note after resume does not change the continue line" "continue: phase=brief | last=resume: from x" state next "$run"

# a missing RUN.md is an error unless next allows it
status=0; out=$(state budget "$work/none.md" 2>&1) || status=$?
{ [ "$status" -eq 2 ] && echo "$out" | grep -q "none.md"; } && pass "budget on a missing file exits 2 naming the file" || fail "budget on a missing file exits 2 naming the file" "$status: $out"
status=0; out=$(state next "$work/none.md" 2>&1) || status=$?
[ "$status" -eq 2 ] && pass "next on a missing file exits 2" || fail "next on a missing file exits 2" "$status: $out"
expect "next --allow-missing prints start" "start" state next "$work/none.md" --allow-missing
status=0; state limits "$work/none.md" >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] && pass "limits on a missing file exits 2" || fail "limits on a missing file exits 2"

# malformed entries are reported, not dropped silently
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' '- 2026-11-19T01:30:00Z | Answer | second' '- 2026-11-19T01:40:00 | answer | no zulu' '- 2026-13-19T01:40:00Z | step | month 13' '- plain bullet without bars' >"$run"
status=0; out=$(state next "$run" 2>"$work/err") || status=$?
err=$(cat "$work/err")
{ [ "$status" -eq 0 ] && [ "$out" = "continue: phase=setup | last=start: pitch=PITCH.md" ] && ! echo "$err$out" | grep -q Traceback; } && pass "malformed entries do not crash next" || fail "malformed entries do not crash next" "$status: $out $err"
[ "$(echo "$err" | grep -c 'skipped')" -eq 3 ] && pass "each malformed entry is named on stderr" || fail "each malformed entry is named on stderr" "$err"

# rounds must be whole
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md rounds=2.5" >"$run"
status=0; out=$(state limits "$run" 2>&1) || status=$?
{ [ "$status" -eq 1 ] && echo "$out" | grep -q "whole number" && ! echo "$out" | grep -q Traceback; } && pass "rounds=2.5 is refused with a message" || fail "rounds=2.5 is refused with a message" "$status: $out"

# limits and accepts
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md process=minimal" >"$run"
expect "limits prints autoAccepts with its default" "mode=review process=minimal rounds=2 hours=6 autoAccepts=3" state limits "$run"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md autoAccepts=2
- 2026-11-19T02:00:00Z | accept | round 1 | a.png | moved
- 2026-11-19T03:00:00Z | stop | references | red | p
- 2026-11-19T04:00:00Z | answer | accepted
- 2026-11-19T04:01:00Z | resume | from references
- 2026-11-19T05:00:00Z | accept | round 2 | b.png | moved
LOG
expect "accepts counts only the accepts since the last answer" "accepts-since-answer=1 of 2" state accepts "$run"
echo "- 2026-11-19T06:00:00Z | accept | round 3 | c.png | moved" >>"$run"
expect "accepts at the limit" "accepts-since-answer=2 of 2" state accepts "$run"
echo "- 2026-11-19T06:30:00Z | budget | autoAccepts=5" >>"$run"
expect "a budget line raises the accept limit" "accepts-since-answer=2 of 5" state accepts "$run"

# run modes: overnight is uncapped and look=auto, review stops after every round
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md" >"$run"
expect "no mode means review" "mode=review process=standard rounds=6 hours=6 autoAccepts=3" state limits "$run"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight hours=8" >"$run"
expect "overnight limits are unlimited, hours set the budget" "mode=overnight process=standard rounds=unlimited hours=8 autoAccepts=unlimited" state limits "$run"
expect "overnight accepts print unlimited" "accepts-since-answer=0 of unlimited" state accepts "$run"
expect "overnight implies look=auto" "look=auto target=no
state=none" state look "$run"
echo "- 2026-11-19T01:30:00Z | accept | round 1 | a.png | moved" >>"$run"
echo "- 2026-11-19T01:40:00Z | accept | round 1 | b.png | moved" >>"$run"
echo "- 2026-11-19T01:50:00Z | accept | round 2 | c.png | moved" >>"$run"
expect "overnight accepts still count" "accepts-since-answer=3 of unlimited" state accepts "$run"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight autoAccepts=2 rounds=4 look=ask" >"$run"
expect "explicit autoAccepts and rounds beat overnight" "mode=overnight process=standard rounds=4 hours=6 autoAccepts=2" state limits "$run"
expect "explicit look=ask beats overnight" "look=ask target=no
state=none" state look "$run"
echo "- 2026-11-19T02:00:00Z | budget | mode=review" >>"$run"
expect "a budget line can switch the mode back" "mode=review process=standard rounds=4 hours=6 autoAccepts=2" state limits "$run"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight" >"$run"
for round in 1 2 3 4 5 6 7; do echo "- 2026-11-19T01:0${round}:00Z | round | $round | x" >>"$run"; done
expect "overnight is not stopped by the default round limit" "ok" state budget "$run" --now 2026-11-19T03:00:00Z
status=0; out=$(state budget "$run" --now 2026-11-19T08:00:00Z 2>&1) || status=$?
{ [ "$status" -eq 3 ] && echo "$out" | grep -q "hours spent"; } && pass "overnight stops when the hours are spent" || fail "overnight stops when the hours are spent" "$status: $out"
echo "- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=nightly" >"$run"
status=0; out=$(state limits "$run" 2>&1) || status=$?
{ [ "$status" -eq 1 ] && echo "$out" | grep -q "overnight or review"; } && pass "an unknown mode is refused" || fail "an unknown mode is refused" "$status: $out"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=review
- 2026-11-19T01:10:00Z | round-start | 1 | branch=r1 base=abc
- 2026-11-19T01:50:00Z | round | 1 | done
LOG
expect "review mode waits for the round review after a round" "waiting: round-review" state next "$run"
echo "- 2026-11-19T02:00:00Z | answer | keep, but less bloom" >>"$run"
expect "the answer to the round review resumes it, with no stray note" "resume: round-review | keep, but less bloom" state next "$run"
echo "- 2026-11-19T02:01:00Z | resume | from round-review" >>"$run"
expect "after the resume the run continues" "continue: phase=setup | last=resume: from round-review" state next "$run"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:50:00Z | round | 1 | done
- 2026-11-19T01:51:00Z | stop | round-review | read the packet | p
LOG
expect "a logged round-review stop reads as any stop" "waiting: round-review" state next "$run"
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight
- 2026-11-19T01:50:00Z | round | 1 | done
LOG
expect "overnight carries on after a round" "continue: phase=setup | last=round: 1 | done" state next "$run"

# pending round: explain why a round is redone
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T01:10:00Z | round-start | 1 | branch=round-1
LOG
expect "a round-start with no base says so" "redo: round 1 (no branch and base recorded)" state next "$run"
repo="$work/repo"; mkdir "$repo"
git -C "$repo" init -q && git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
printf -- '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md\n- 2026-11-19T01:10:00Z | round-start | 1 | branch=gone base=%s\n' "$(git -C "$repo" rev-parse HEAD)" >"$repo/RUN.md"
expect "a failed branch check says so and is not a silent redo" "redo: round 1 (branch check failed, read the branch before respawning)" state next "$repo/RUN.md"

# phase names
expect "phase-names lists the phases in run order" "brief art-bible first-playable look-variants checklist polish reference-judge deliver" bash -c "python3 -I '$SCRIPT' phase-names | tr '\n' ' ' | sed 's/ \$//'"

# phases: a crashed sitting is not counted twice
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md
- 2026-11-19T02:00:00Z | step | work
- 2026-11-19T10:00:00Z | resume | from work
- 2026-11-19T10:30:00Z | step | more
LOG
expect "phases counts a crashed sitting once" $'setup 1h 30m\ntotal 1h 30m' state phases "$run" --now 2026-11-19T10:30:00Z
out=$(state budget "$run" --now 2026-11-19T10:30:00Z)
expect "budget and phases agree on active time" "ok" echo "$out"

# lock
lock_dir="$work/lock"; mkdir "$lock_dir"; touch "$lock_dir/RUN.md"
for owner in a b c d e f g h; do
  (python3 -I "$SCRIPT" lock acquire "$lock_dir/RUN.md" --owner "$owner" >"$lock_dir/out.$owner" 2>&1; echo $? >"$lock_dir/status.$owner") &
done
wait
winners=$(grep -lx 0 "$lock_dir"/status.* | wc -l | tr -d ' ')
[ "$winners" -eq 1 ] && pass "eight racing acquires leave exactly one holder" || fail "eight racing acquires leave exactly one holder" "$winners winners"
leftovers=$(ls -A "$lock_dir" | grep -v '^out\.\|^status\.\|^RUN.md$' | tr '\n' ' ')
[ "$leftovers" = "RUN.md.lock " ] && pass "a lock leaves no temp files" || fail "a lock leaves no temp files" "$leftovers"
rm -f "$lock_dir/RUN.md.lock"
python3 -I "$SCRIPT" lock acquire "$lock_dir/RUN.md" --owner old --now 2026-11-19T01:00:00Z >/dev/null
out=$(python3 -I "$SCRIPT" lock acquire "$lock_dir/RUN.md" --owner new --now 2026-11-19T04:00:00Z)
echo "$out" | grep -q "took over" && grep -q '^owner=new' "$lock_dir/RUN.md.lock" && pass "a stale lock is taken over and the owner confirmed" || fail "a stale lock is taken over and the owner confirmed" "$out"

# variant answers
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' '- 2026-11-19T01:30:00Z | stop | look-variants | pick one of variants=look,use,1,dusk | p.html' >"$run"
for case in "look|chosen look" "use, darker|chosen use | darker" "1|chosen 1" "pick dusk|chosen dusk" "2|chosen use"; do
  answer="${case%%|*}"; expected="${case#*|}"
  head -2 "$run" >"$work/look.run"; echo "- 2026-11-19T02:00:00Z | answer | $answer" >>"$work/look.run"
  actual=$(state look "$work/look.run" | tail -1)
  [ "$actual" = "state=$expected" ] && pass "variant answer '$answer'" || fail "variant answer '$answer'" "expected 'state=$expected', got '$actual'"
done


expect_last() {
  local description="$1" expected="$2" actual
  shift 2
  actual=$("$@" 2>&1 | grep -E "^(next|all-at-target)" | grep -F "${expected%%[:=]*}" | head -1)
  [ "$actual" = "$expected" ] && pass "$description" || fail "$description" "expected '$expected', got '$actual'"
}

# rows: turns, counted score, target and the pick order
cat >"$run" <<'LOG'
- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight
- 2026-11-19T01:05:00Z | row | water | turn 0 | score -/- of target 8 | pending | approach: none
- 2026-11-19T01:05:01Z | row | creatures | turn 0 | score -/- of target 8 | pending | approach: none
- 2026-11-19T01:05:02Z | row | sound | turn 0 | score -/- of target 7 | pending | approach: none
- 2026-11-19T01:05:03Z | row | sky | turn 0 | score -/- of target 8 | pending | approach: none
- 2026-11-19T01:20:00Z | row | sky | turn 1 | score 7/6 of target 8 | kept | approach: warmer gradient
- 2026-11-19T01:30:00Z | row | water | turn 1 | score 6/7 of target 8 | reverted | approach: foam sprites
LOG
out=$(state rows "$run")
echo "$out" | grep -q '^sky turns=1 score=7/6 counted=6 target=8 at-target=no last=kept$' && pass "rows prints a worked row" || fail "rows prints a worked row" "$out"
echo "$out" | grep -q '^creatures turns=0 score=- counted=- target=8 at-target=no last=none$' && pass "rows prints a never-worked row" || fail "rows prints a never-worked row" "$out"
expect_last "never-worked rows go first, then a lost row with a new approach" "next: creatures, sound, water (new approach), sky" state rows "$run"
printf '%s\n' '- 2026-11-19T01:40:00Z | row | creatures | turn 1 | score 8/9 of target 8 | kept | approach: rig' '- 2026-11-19T01:50:00Z | row | sound | turn 1 | score 7/7 of target 7 | kept | approach: synth' >>"$run"
out=$(state rows "$run")
echo "$out" | grep -q '^creatures .* counted=8 target=8 at-target=yes' && pass "a counted score at target is at target" || fail "a counted score at target is at target" "$out"
expect_last "rows at target leave the pick list" "next: water (new approach), sky" state rows "$run"
printf '%s\n' '- 2026-11-19T02:00:00Z | row | water | turn 2 | score 6/7 of target 8 | reverted | approach: mist mesh' >>"$run"
out=$(state rows "$run")
echo "$out" | grep -q '^water turns=2 .* last=reverted lost=2$' && pass "two losses show as lost=2" || fail "two losses show as lost=2" "$out"
expect_last "a row lost twice is shrunk, after the row with fewer turns" "next: sky, water (shrink scope)" state rows "$run"
printf '%s\n' '- 2026-11-19T02:10:00Z | row | sky | turn 2 | score 8/8 of target 8 | kept | approach: sun shafts' '- 2026-11-19T02:20:00Z | row | water | turn 3 | score 8/8 of target 8 | kept | approach: small pond only' >>"$run"
expect_last "every row at target" "all-at-target=yes" state rows "$run"
echo "- 2026-11-19T02:30:00Z | row | oops | turn x" >>"$run"
out=$(state rows "$run" 2>&1)
echo "$out" | grep -q 'oops' && echo "$out" | grep -q 'not a valid row' && pass "a malformed row line is named, not silently dropped" || fail "a malformed row line is named" "$out"
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md' >"$work/norows.md"
expect "no rows logged" "no rows logged" state rows "$work/norows.md"

# budget reserve
printf '%s\n' '- 2026-11-19T01:00:00Z | start | pitch=PITCH.md mode=overnight hours=6' >"$run"
expect "budget is ok before the reserve" "ok" state budget "$run" --now 2026-11-19T06:00:00Z
status=0; out=$(state budget "$run" --now 2026-11-19T06:20:00Z 2>&1) || status=$?
{ [ "$status" -eq 0 ] && [ "$out" = "reserve: 40m left of 6h, delivery reserve 40m" ]; } && pass "budget reports reserve at the default 40 minutes" || fail "budget reports reserve at the default" "$status: $out"
echo "- 2026-11-19T01:00:01Z | budget | reserve=60" >>"$run"
expect "reserve=N sets the delivery reserve" "reserve: 55m left of 6h, delivery reserve 60m" state budget "$run" --now 2026-11-19T06:05:00Z
status=0; out=$(state budget "$run" --now 2026-11-19T07:00:00Z 2>&1) || status=$?
{ [ "$status" -eq 3 ] && echo "$out" | grep -q "hours spent"; } && pass "a spent budget still stops" || fail "a spent budget still stops" "$status: $out"

[ "$failures" -eq 0 ] || exit 1
