#!/bin/bash
# Tests for the realtime-judge blind-pair script: neutral labels, recorded mapping,
# lower score counts, keep on win or tie.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO_ROOT/skills/realtime/realtime-judge/scripts/blind_pair.py"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
printf 'IMG-ONE' > "$work/before.png"
printf 'IMG-TWO' > "$work/after.png"

run() { python3 -I "$SCRIPT" "$@"; }
prepare() { run prepare --before "$work/before.png" --after "$work/after.png" --judge-dir "$1" --mapping "$2" "${@:3}"; }
x_side() { python3 -c "import json; print(json.load(open('$1'))['X'])"; }

# prepare: judges get x.png and y.png only, nothing naming before or after
prepare "$work/judge" "$work/mapping.json" --seed 1 > /dev/null
files=$(ls "$work/judge" | tr '\n' ' ')
[ "$files" = "x.png y.png " ] && pass "judge dir holds only x.png and y.png" || fail "judge dir holds only x.png and y.png" "found: $files"

if grep -rqiE 'before|after' "$work/judge"; then
  fail "judge dir leaks no before or after text"
else
  pass "judge dir leaks no before or after text"
fi

x_bytes=$(cat "$work/judge/x.png")
case "$(x_side "$work/mapping.json"):$x_bytes" in
  before:IMG-ONE | after:IMG-TWO) pass "mapping records which capture is X" ;;
  *) fail "mapping records which capture is X" "$(x_side "$work/mapping.json"):$x_bytes" ;;
esac

# the same seed repeats; different seeds produce both orders
prepare "$work/j2" "$work/m2.json" --seed 1 > /dev/null
cmp -s "$work/mapping.json" "$work/m2.json" && pass "same seed repeats the assignment" || fail "same seed repeats the assignment"

orders=""
for seed in 1 2 3 4 5 6 7 8 9 10 11 12; do
  prepare "$work/js" "$work/ms.json" --seed "$seed" > /dev/null
  orders="$orders $(x_side "$work/ms.json")"
done
case "$orders" in
  *before*after* | *after*before*) pass "both orders occur across seeds" ;;
  *) fail "both orders occur across seeds" "$orders" ;;
esac

prepare "$work/jn" "$work/mn.json" > /dev/null && pass "prepare works without a seed" || fail "prepare works without a seed"

out=$(prepare "$work/jq" "$work/mq.json" --seed 3)
if echo "$out" | grep -qiE 'before|after'; then
  fail "prepare output does not reveal the mapping" "$out"
else
  pass "prepare output does not reveal the mapping"
fi

# decide: mappings with a known order
echo '{"X":"before","Y":"after","seed":0}' > "$work/before-is-x.json"
echo '{"X":"after","Y":"before","seed":0}' > "$work/after-is-x.json"

decision() {
  run decide --mapping "$1" --visual "$2" --feel "$3" |
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d['decision'], d['before_counted'], d['after_counted'])"
}

result=$(decision "$work/before-is-x.json" X=6,Y=8 X=6,Y=9)
[ "$result" = "keep 6 8" ] && pass "clear improvement is kept (lower of 8 and 9 counts)" || fail "clear improvement is kept" "$result"

result=$(decision "$work/before-is-x.json" X=7,Y=4 X=7,Y=6)
[ "$result" = "reject 7 4" ] && pass "worse change is rejected" || fail "worse change is rejected" "$result"

result=$(decision "$work/after-is-x.json" X=8,Y=7 X=8,Y=7)
[ "$result" = "reject 7 8" ] && fail "label order is mapped back" "$result"
[ "$result" = "keep 7 8" ] && pass "label order is mapped back (X is after)" || fail "label order is mapped back" "$result"

result=$(decision "$work/before-is-x.json" X=7,Y=7 X=7,Y=7)
[ "$result" = "keep 7 7" ] && pass "tie is kept" || fail "tie is kept" "$result"

result=$(decision "$work/before-is-x.json" X=8,Y=9 X=8,Y=6)
[ "$result" = "reject 8 6" ] && pass "one judge disliking the change drags it down" || fail "lower score counts" "$result"

if run decide --mapping "$work/before-is-x.json" --visual X=6,Y=8 --feel X=6,Y=9 --markdown | grep -q 'Visual'; then
  pass "markdown packet section lists both judges"
else
  fail "markdown packet section lists both judges"
fi

if run decide --mapping "$work/before-is-x.json" --visual X=6,Y=11 --feel X=6,Y=9 > /dev/null 2>&1; then
  fail "scores outside 1-10 are refused"
else
  pass "scores outside 1-10 are refused"
fi

# motion: a third lens, judged on folders of sheets rather than single images
mkdir -p "$work/motion-before" "$work/motion-after"
printf 'STRIP-ONE' > "$work/motion-before/strip.png"; printf 'CROPS-ONE' > "$work/motion-before/crops.png"
printf 'STRIP-TWO' > "$work/motion-after/strip.png"; printf 'CROPS-TWO' > "$work/motion-after/crops.png"
run prepare --before "$work/motion-before" --after "$work/motion-after" --judge-dir "$work/judge-motion" --mapping "$work/mapping-motion.json" --seed 4 > /dev/null
listing=$(cd "$work/judge-motion" && find . -type f | sort | tr '\n' ' ')
[ "$listing" = "./x/crops.png ./x/strip.png ./y/crops.png ./y/strip.png " ] && pass "folder prepare gives x/ and y/ with the same file names" || fail "folder prepare gives x/ and y/ with the same file names" "found: $listing"
case "$(x_side "$work/mapping-motion.json"):$(cat "$work/judge-motion/x/strip.png")" in
  before:STRIP-ONE | after:STRIP-TWO) pass "folder mapping records which folder is X" ;;
  *) fail "folder mapping records which folder is X" ;;
esac

motion_decision() {
  run decide --mapping "$1" "${@:2}" |
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d['decision'], d['before_counted'], d['after_counted'])"
}

result=$(motion_decision "$work/before-is-x.json" --motion X=4,Y=7)
[ "$result" = "keep 4 7" ] && pass "motion alone decides a motion moment" || fail "motion alone decides a motion moment" "$result"

result=$(motion_decision "$work/before-is-x.json" --motion X=7,Y=5)
[ "$result" = "reject 7 5" ] && pass "worse motion is rejected" || fail "worse motion is rejected" "$result"

result=$(motion_decision "$work/before-is-x.json" --visual X=6,Y=8 --feel X=6,Y=8 --motion X=6,Y=5)
[ "$result" = "reject 6 5" ] && pass "with three lenses the motion score counts like the other two" || fail "with three lenses the motion score counts like the other two" "$result"

if run decide --mapping "$work/before-is-x.json" --visual X=6,Y=8 --motion X=6,Y=8 > /dev/null 2>&1; then
  fail "visual without feel is refused"
else
  pass "visual without feel is refused"
fi

if run decide --mapping "$work/before-is-x.json" > /dev/null 2>&1; then
  fail "decide without any lens is refused"
else
  pass "decide without any lens is refused"
fi

if run decide --mapping "$work/before-is-x.json" --motion X=4,Y=7 --markdown | grep -q 'Motion judge'; then
  pass "markdown lists the motion judge"
else
  fail "markdown lists the motion judge"
fi

[ "$failures" -eq 0 ] || { echo "$failures failure(s)" >&2; exit 1; }
