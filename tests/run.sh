#!/bin/bash
# Runs every tests/*.test.sh and exits non-zero if any of them fails.

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
failed_tests=()

for test_file in "$TESTS_DIR"/*.test.sh; do
  [ -e "$test_file" ] || continue
  echo "== $(basename "$test_file")"
  bash "$test_file" || failed_tests+=("$(basename "$test_file")")
done

if [ ${#failed_tests[@]} -gt 0 ]; then
  echo "FAILED: ${failed_tests[*]}" >&2
  exit 1
fi
echo "All tests passed."
