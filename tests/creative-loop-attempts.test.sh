#!/bin/bash
# Tests for attempts mode of the creative-loop skill: the attempts argument and the worktree plan
# printed by plan-attempts.sh, plus start-run.sh --attempts and --no-marker. Hermetic.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/skills/orchestration/creative-loop"
SKILL="$SKILL_DIR/SKILL.md"
PLAN="$SKILL_DIR/scripts/plan-attempts.sh"
START="$SKILL_DIR/scripts/start-run.sh"
FIXTURE_BRIEF="$REPO_ROOT/tests/fixtures/loop-brief/BRIEF.md"
. "$(dirname "$0")/lib.sh"

work=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$work"' EXIT

lab="$work/lab"
mkdir -p "$lab"
git -C "$lab" init -q -b main
git -C "$lab" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

# Three attempts: letters a b c, branch and worktree per attempt, run id inside both
plan=$("$PLAN" --lab "$lab" --app tides --attempts 3 --run-id r1 2>&1) && pass "plan runs for 3 attempts" || fail "plan runs for 3 attempts" "$plan"
[ "$(echo "$plan" | grep -c '^attempt ')" = 3 ] && pass "one plan line per attempt" || fail "one plan line per attempt" "$plan"
echo "$plan" | grep -qx "attempt a branch=loop/tides-r1-a worktree=$work/lab-tides-r1-a" && pass "attempt a line" || fail "attempt a line" "$plan"
echo "$plan" | grep -qx "attempt c branch=loop/tides-r1-c worktree=$work/lab-tides-r1-c" && pass "attempt c line" || fail "attempt c line" "$plan"

# Two attempts and one attempt
[ "$("$PLAN" --lab "$lab" --app tides --attempts 2 --run-id r1 | grep -c '^attempt ')" = 2 ] && pass "2 attempts" || fail "2 attempts"
[ "$("$PLAN" --lab "$lab" --app tides --attempts 1 --run-id r1 | grep -c '^attempt ')" = 1 ] && pass "1 attempt" || fail "1 attempt"

# Out of range or malformed counts are refused
for bad in 0 4 x "" 2.5; do
  if "$PLAN" --lab "$lab" --app tides --attempts "$bad" --run-id r1 >/dev/null 2>&1; then fail "refuses --attempts '$bad'"; else pass "refuses --attempts '$bad'"; fi
done

# No collisions across attempts: all branches and worktrees are distinct
[ "$(echo "$plan" | grep -o 'branch=[^ ]*' | sort -u | wc -l | tr -d ' ')" = 3 ] && pass "branches distinct" || fail "branches distinct"
[ "$(echo "$plan" | grep -o 'worktree=[^ ]*' | sort -u | wc -l | tr -d ' ')" = 3 ] && pass "worktrees distinct" || fail "worktrees distinct"

# No collisions across runs: the default run id differs when the clock does, and an explicit id changes every name
other=$("$PLAN" --lab "$lab" --app tides --attempts 3 --run-id r2)
[ -z "$(comm -12 <(echo "$plan" | grep -o 'branch=[^ ]*' | sort) <(echo "$other" | grep -o 'branch=[^ ]*' | sort))" ] && pass "runs do not share branches" || fail "runs do not share branches"
a_default=$(PLAN_NOW=1000 "$PLAN" --lab "$lab" --app tides --attempts 1 | head -1)
b_default=$(PLAN_NOW=2000 "$PLAN" --lab "$lab" --app tides --attempts 1 | head -1)
[ "$a_default" != "$b_default" ] && pass "default run id follows the clock" || fail "default run id follows the clock" "$a_default"

# A branch or worktree path that already exists is refused, not reused
git -C "$lab" branch loop/tides-r1-b
if "$PLAN" --lab "$lab" --app tides --attempts 3 --run-id r1 >/dev/null 2>&1; then fail "refuses an existing branch"; else pass "refuses an existing branch"; fi
git -C "$lab" branch -q -D loop/tides-r1-b
mkdir -p "$work/lab-tides-r1-c"
if "$PLAN" --lab "$lab" --app tides --attempts 3 --run-id r1 >/dev/null 2>&1; then fail "refuses an existing worktree path"; else pass "refuses an existing worktree path"; fi
rmdir "$work/lab-tides-r1-c"

# Not a git repo
if "$PLAN" --lab "$work" --app tides --attempts 2 --run-id r1 >/dev/null 2>&1; then fail "refuses a non-repo lab"; else pass "refuses a non-repo lab"; fi

# start-run.sh: --attempts sets the header, --no-marker writes no marker
app="$work/repo/apps/tides"
mkdir -p "$app" "$work/session"
cp "$FIXTURE_BRIEF" "$app/BRIEF.md"
git -C "$work/repo" init -q
(cd "$work/session" && "$START" --app-dir "$app" --budget 8h --mode overnight --attempts 3 --no-marker >/dev/null 2>&1) && pass "start-run with --attempts --no-marker" || fail "start-run with --attempts --no-marker"
grep -q '^Attempts: 3$' "$app/LOOP.md" && pass "header says Attempts: 3" || fail "header says Attempts: 3"
[ ! -e "$work/session/.loop-active" ] && pass "no marker written" || fail "no marker written"

# Skill text: argument and rules
assert_text() { if grep -qiE -- "$2" "${3:-$SKILL}"; then pass "$1"; else fail "$1" "missing: $2"; fi; }
assert_text "documents --attempts" '\-\-attempts 1\.\.3|--attempts <1-3>'
assert_text "names the plan script" 'plan-attempts\.sh'
assert_text "orchestrator is each attempt's outer loop" 'outer loop for each attempt'
assert_text "hook does not drive subagents" 'does not drive subagents|hook drives only'
assert_text "one status line per report" 'one status line'
assert_text "stacked video" 'stacked'
assert_text "continues from the picked attempt alone" 'picked attempt alone'
assert_text "overnight pick waits for morning" 'pick waits for (the )?morning'
assert_text "never deletes the other attempts" 'never delete'

[ "$failures" -eq 0 ] || exit 1
