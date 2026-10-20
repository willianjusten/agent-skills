#!/bin/bash
# Tests for harness/claude/hooks/ticket-lint.sh: feeds PostToolUse payloads and
# checks the exit code and stderr for each ticket fixture.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/ticket-lint.sh"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT
failures=0

write_ticket() {
  local relative_path="$1" fields="$2"
  mkdir -p "$(dirname "$FIXTURE_DIR/$relative_path")"
  printf '# 01: Fixture\n\n%s\n\n## What to build\n\nSomething.\n' "$fields" >"$FIXTURE_DIR/$relative_path"
  echo "$FIXTURE_DIR/$relative_path"
}

run_hook() {
  local file_path="$1"
  jq -n --arg file_path "$file_path" '{tool_name: "Write", tool_input: {file_path: $file_path}}' | bash "$HOOK" 2>&1
}

# expect <name> <file> <exit code> [substring...]: every substring must appear in the output.
expect() {
  local name="$1" file_path="$2" expected_code="$3"
  shift 3
  local output actual_code
  output=$(run_hook "$file_path")
  actual_code=$?
  if [ "$actual_code" != "$expected_code" ]; then
    echo "FAIL $name: exit $actual_code, expected $expected_code. Output: $output"
    failures=$((failures + 1))
    return
  fi
  local expected_text
  for expected_text in "$@"; do
    if [[ "$output" != *"$expected_text"* ]]; then
      echo "FAIL $name: output missing '$expected_text'. Output: $output"
      failures=$((failures + 1))
      return
    fi
  done
  if [ $# -eq 0 ] && [ -n "$output" ]; then
    echo "FAIL $name: expected no output, got: $output"
    failures=$((failures + 1))
    return
  fi
  echo "ok   $name"
}

VALID_FIELDS='Status: ready-for-agent
Blocked by: 02, 03
Areas: harness/hooks, settings
Tests: tdd'

valid=$(write_ticket ".scratch/feature/issues/01-valid.md" "$VALID_FIELDS")
expect "valid ticket passes" "$valid" 0

no_blockers=$(write_ticket ".scratch/feature/issues/02-no-blockers.md" "${VALID_FIELDS/Blocked by: 02, 03/Blocked by: None}")
expect "Blocked by: None passes" "$no_blockers" 0

missing=$(write_ticket ".scratch/feature/issues/03-missing.md" "$(printf '%s\n' "$VALID_FIELDS" | grep -v '^Areas:')")
expect "missing Areas fails" "$missing" 2 "Areas: missing"

bold=$(write_ticket ".scratch/feature/issues/04-bold.md" "${VALID_FIELDS/Status: ready-for-agent/**Status:** ready-for-agent}")
expect "bold Status fails" "$bold" 2 "Status: bold"

bad_tests=$(write_ticket ".scratch/feature/issues/05-bad-tests.md" "${VALID_FIELDS/Tests: tdd/Tests: unit}")
expect "invalid Tests value fails" "$bad_tests" 2 "Tests: invalid value 'unit'"

bad_status=$(write_ticket ".scratch/feature/issues/06-bad-status.md" "${VALID_FIELDS/Status: ready-for-agent/Status: todo}")
expect "invalid Status value fails" "$bad_status" 2 "Status: invalid value 'todo'"

bad_blocked=$(write_ticket ".scratch/feature/issues/07-bad-blocked.md" "${VALID_FIELDS/Blocked by: 02, 03/Blocked by: ticket two}")
expect "invalid Blocked by value fails" "$bad_blocked" 2 "Blocked by: invalid value 'ticket two'"

several=$(write_ticket ".scratch/feature/issues/08-several.md" "Status: done")
expect "names every missing field" "$several" 2 "Blocked by: missing" "Areas: missing" "Tests: missing"

outside=$(write_ticket ".scratch/feature/spec.md" "Status: spec")
expect "spec outside issues/ is ignored" "$outside" 0

not_scratch=$(write_ticket "docs/issues/01-other.md" "nothing here")
expect "issues/ outside .scratch is ignored" "$not_scratch" 0

expect "missing file_path is ignored" "" 0

for real_ticket in "$REPO_ROOT"/.scratch/harness-upgrade/issues/*.md; do
  [ -e "$real_ticket" ] || continue
  expect "real ticket $(basename "$real_ticket")" "$real_ticket" 0
done

[ $failures -eq 0 ]
