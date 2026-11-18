#!/bin/bash
# Tests for the motion-review skill and its motion-judge agent: a standalone folder
# shuffle that leaks nothing, a decision on the motion score, and the repo's skill
# and agent shape (personal scope, README, names, no machine paths).

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/skills/creative/motion-review"
SCRIPT="$SKILL_DIR/scripts/blind_motion.py"
AGENT="$REPO_ROOT/agents/realtime/motion-judge.md"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

frontmatter() { awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1"; }
field() { frontmatter "$1" | awk -v key="$2" -F': *' '$1 == key { print $2; exit }'; }
scope_of() { frontmatter "$1" | awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }'; }

# shape of the skill and the agent
[ "$(field "$SKILL_DIR/SKILL.md" name)" = "motion-review" ] && pass "skill name equals its folder" || fail "skill name equals its folder"
[ "$(scope_of "$SKILL_DIR/SKILL.md")" = "personal" ] && pass "skill is scoped personal" || fail "skill is scoped personal"
[ -f "$SKILL_DIR/README.md" ] && pass "skill has a README" || fail "skill has a README"
[ -f "$SKILL_DIR/references/rubric.md" ] && grep -q '^| 10 |' "$SKILL_DIR/references/rubric.md" && pass "skill ships an anchored motion rubric" || fail "skill ships an anchored motion rubric"
if grep -rqE 'realtime-judge|blind_pair' "$SKILL_DIR"; then
  fail "skill works alone, naming no sibling skill"
else
  pass "skill works alone, naming no sibling skill"
fi

[ "$(field "$AGENT" name)" = "motion-judge" ] && pass "agent name equals its file name" || fail "agent name equals its file name"
[ "$(field "$AGENT" model)" = "opus" ] && pass "agent runs on opus like the other judges" || fail "agent runs on opus like the other judges"
[ "$(field "$AGENT" tools)" = "Read" ] && pass "agent can only read" || fail "agent can only read" "tools: '$(field "$AGENT" tools)'"
[ "$(scope_of "$AGENT")" = "personal" ] && pass "agent is scoped personal" || fail "agent is scoped personal"

if grep -rEn '/Users/[a-z]|/home/[a-z]' "$SKILL_DIR" "$AGENT" >/dev/null; then
  fail "no machine paths"
else
  pass "no machine paths"
fi

# blind shuffle of two motion folders
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/before" "$work/after"
for sheet in strip crops burst; do
  printf "$sheet-ONE" > "$work/before/$sheet.png"
  printf "$sheet-TWO" > "$work/after/$sheet.png"
done

run() { python3 -I "$SCRIPT" "$@"; }
x_side() { python3 -c "import json; print(json.load(open('$1'))['X'])"; }

out=$(run prepare --before "$work/before" --after "$work/after" --judge-dir "$work/judge" --mapping "$work/mapping.json" --seed 2)
listing=$(cd "$work/judge" && find . -type f | sort | tr '\n' ' ')
[ "$listing" = "./x/burst.png ./x/crops.png ./x/strip.png ./y/burst.png ./y/crops.png ./y/strip.png " ] && pass "judge dir holds x/ and y/ with the same sheets" || fail "judge dir holds x/ and y/ with the same sheets" "found: $listing"

if grep -rqiE 'before|after' "$work/judge" || echo "$out" | grep -qiE 'before|after'; then
  fail "neither the judge dir nor the output names before or after"
else
  pass "neither the judge dir nor the output names before or after"
fi

case "$(x_side "$work/mapping.json"):$(cat "$work/judge/x/strip.png")" in
  before:strip-ONE | after:strip-TWO) pass "mapping records which folder is X" ;;
  *) fail "mapping records which folder is X" ;;
esac

orders=""
for seed in 1 2 3 4 5 6 7 8 9 10 11 12; do
  run prepare --before "$work/before" --after "$work/after" --judge-dir "$work/js-$seed" --mapping "$work/ms.json" --seed "$seed" > /dev/null
  orders="$orders $(x_side "$work/ms.json")"
done
case "$orders" in
  *before*after* | *after*before*) pass "both orders occur across seeds" ;;
  *) fail "both orders occur across seeds" "$orders" ;;
esac

mkdir -p "$work/odd"
printf 'x' > "$work/odd/strip.png"
if run prepare --before "$work/before" --after "$work/odd" --judge-dir "$work/jo" --mapping "$work/mo.json" > /dev/null 2>&1; then
  fail "folders with different sheets are refused"
else
  pass "folders with different sheets are refused"
fi

# decide on the motion score
echo '{"X":"before","Y":"after","seed":0}' > "$work/before-is-x.json"
echo '{"X":"after","Y":"before","seed":0}' > "$work/after-is-x.json"
decision() { run decide --mapping "$1" --motion "$2" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['decision'], d['before'], d['after'])"; }

result=$(decision "$work/before-is-x.json" X=4,Y=7)
[ "$result" = "keep 4 7" ] && pass "better motion is kept" || fail "better motion is kept" "$result"
result=$(decision "$work/after-is-x.json" X=4,Y=7)
[ "$result" = "reject 7 4" ] && pass "label order is mapped back" || fail "label order is mapped back" "$result"
result=$(decision "$work/before-is-x.json" X=6,Y=6)
[ "$result" = "keep 6 6" ] && pass "tie is kept" || fail "tie is kept" "$result"

if run decide --mapping "$work/before-is-x.json" --motion X=0,Y=7 > /dev/null 2>&1; then
  fail "scores outside 1-10 are refused"
else
  pass "scores outside 1-10 are refused"
fi
run decide --mapping "$work/before-is-x.json" --motion X=4,Y=7 --markdown | grep -q 'Motion judge' && pass "markdown names the motion judge" || fail "markdown names the motion judge"

[ "$failures" -eq 0 ] || { echo "$failures failure(s)" >&2; exit 1; }
