#!/bin/bash
# Tests for the afk skill's scripts: frontier.sh picks which tickets may start,
# budget.sh turns the statusline usage cache into go, hold or stop.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
FRONTIER="$REPO_ROOT/skills/engineering/afk/scripts/frontier.sh"
BUDGET="$REPO_ROOT/skills/engineering/afk/scripts/budget.sh"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT
failures=0

# write_ticket <feature> <NN> <status> <blocked by> <areas>
write_ticket() {
  local feature="$1" number="$2" status="$3" blocked_by="$4" areas="$5"
  mkdir -p "$FIXTURE_DIR/$feature/issues"
  printf '# %s: Fixture\n\nStatus: %s\nBlocked by: %s\nAreas: %s\nTests: tdd\n\n## What to build\n\nSomething.\n' \
    "$number" "$status" "$blocked_by" "$areas" >"$FIXTURE_DIR/$feature/issues/$number-fixture.md"
}

# write_cache <name> <session percent> <seconds until the window resets>
write_cache() {
  local name="$1" session_percent="$2" seconds_until_reset="$3" resets_at
  resets_at=$(jq -rn --argjson offset "$seconds_until_reset" 'now + $offset | floor | todate | sub("Z$"; ".123456+00:00")')
  jq -n --arg session "$session_percent" --arg resets_at "$resets_at" \
    '{session: $session, weekly: "10", session_resets_at: $resets_at, weekly_resets_at: $resets_at}' >"$FIXTURE_DIR/$name.json"
  echo "$FIXTURE_DIR/$name.json"
}

# expect <name> <expected output> <command...>: stdout must equal the expected output exactly.
expect() {
  local name="$1" expected_output="$2"
  shift 2
  local actual_output
  actual_output=$("$@" 2>&1)
  if [ "$actual_output" != "$expected_output" ]; then
    printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$name" "$expected_output" "$actual_output"
    failures=$((failures + 1))
    return
  fi
  echo "ok   $name"
}

# Toy spec: 02 is blocked by 01; 01 and 03 share the "billing" area.
write_ticket toy 01 ready-for-agent None "billing, api"
write_ticket toy 02 ready-for-agent 01 "ui"
write_ticket toy 03 ready-for-agent None "Billing"
write_ticket toy 04 ready-for-human None "docs"
write_ticket toy 05 needs-info None "docs"
printf '# Spec\n\nStatus: spec\n' >"$FIXTURE_DIR/toy/spec.md"

expect "first wave starts 01 only: 02 blocked, 03 overlaps 01" "01" bash "$FRONTIER" "$FIXTURE_DIR/toy"
expect "03 waits while 01 runs" "" bash "$FRONTIER" "$FIXTURE_DIR/toy" 01

write_ticket toy 01 done None "billing, api"
expect "after 01 is done, 02 and 03 start together" "$(printf '02\n03')" bash "$FRONTIER" "$FIXTURE_DIR/toy"
expect "one running slot left takes the lowest number" "03" bash "$FRONTIER" "$FIXTURE_DIR/toy" 02
expect "two running means no free slot" "" bash "$FRONTIER" "$FIXTURE_DIR/toy" 02 03
expect "a done ticket still awaiting its merge does not unblock dependents" "" bash "$FRONTIER" "$FIXTURE_DIR/toy" 01

write_ticket toy 02 done 01 "ui"
write_ticket toy 03 done None "Billing"
expect "frontier is empty once every agent ticket is done" "" bash "$FRONTIER" "$FIXTURE_DIR/toy"

write_ticket chain 01 needs-info None "a"
write_ticket chain 02 ready-for-agent 01 "b"
write_ticket chain 03 ready-for-agent 09 "c"
expect "needs-info and missing blockers keep dependents out" "" bash "$FRONTIER" "$FIXTURE_DIR/chain"

expect "missing feature folder fails" "frontier.sh: no issues/ under $FIXTURE_DIR/none" bash "$FRONTIER" "$FIXTURE_DIR/none"

expect "below 80% is go" "go 79" bash "$BUDGET" "$(write_cache low 79 3600)"
expect "85% holds new implementers" "hold 85" bash "$BUDGET" "$(write_cache mid 85 3600)"
expect "exactly 80% holds" "hold 80" bash "$BUDGET" "$(write_cache edge 80 3600)"
expect "95% stops the run" "stop 95" bash "$BUDGET" "$(write_cache high 95 3600)"
expect "exactly 90% stops" "stop 90" bash "$BUDGET" "$(write_cache edge90 90 3600)"
expect "a window that already reset is unknown" "go unknown" bash "$BUDGET" "$(write_cache expired 95 -60)"
expect "a missing cache is unknown" "go unknown" bash "$BUDGET" "$FIXTURE_DIR/missing.json"
expect "AFK_USAGE_CACHE points at another cache" "hold 85" env AFK_USAGE_CACHE="$FIXTURE_DIR/mid.json" bash "$BUDGET"
printf 'not json' >"$FIXTURE_DIR/broken.json"
expect "an unreadable cache is unknown" "go unknown" bash "$BUDGET" "$FIXTURE_DIR/broken.json"

[ "$failures" -eq 0 ] || exit 1
