#!/bin/bash
# Runs every tests/*.test.sh in parallel and exits non-zero if any of them fails.
# Run one file on its own with `bash tests/<name>.test.sh`.
# Each test works in its own mktemp directory; output is printed per file, in name order.

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
output_dir=$(mktemp -d)
trap 'rm -rf "$output_dir"' EXIT
test_files=()
failed_tests=()

for test_file in "$TESTS_DIR"/*.test.sh; do
  [ -e "$test_file" ] || continue
  test_files+=("$test_file")
  (bash "$test_file" >"$output_dir/$(basename "$test_file").out" 2>&1; echo $? >"$output_dir/$(basename "$test_file").status") &
done
wait

for test_file in "${test_files[@]}"; do
  name=$(basename "$test_file")
  echo "== $name"
  cat "$output_dir/$name.out"
  [ "$(cat "$output_dir/$name.status")" -eq 0 ] || failed_tests+=("$name")
done

if [ ${#failed_tests[@]} -gt 0 ]; then
  echo "FAILED: ${failed_tests[*]}" >&2
  exit 1
fi
echo "All tests passed."
