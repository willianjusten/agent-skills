#!/bin/bash
# Tests for harness/claude/hooks/verify-gate.sh: builds throwaway git repos and
# feeds Stop payloads. Package managers are stubs on PATH that log their name
# and print or fail as told by STUB_EXIT and STUB_LINES.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/verify-gate.sh"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
STUB_DIR="$WORK_DIR/bin"
PM_LOG="$WORK_DIR/pm.log"
failures=0

mkdir -p "$STUB_DIR"
for package_manager in npm pnpm yarn bun; do
  cat >"$STUB_DIR/$package_manager" <<EOF
#!/bin/bash
echo $package_manager >>"$PM_LOG"
for line_number in \$(seq 1 "\${STUB_LINES:-0}"); do echo "verify line \$line_number"; done
exit "\${STUB_EXIT:-0}"
EOF
  chmod +x "$STUB_DIR/$package_manager"
done

# make_repo <name> <package.json> [lockfile]: a repo on main with one commit,
# then a feature branch. Prints the repo path.
make_repo() {
  local repo_dir="$WORK_DIR/$1" package_json="$2" lockfile="$3"
  mkdir -p "$repo_dir"
  (
    cd "$repo_dir" || exit 1
    git init -q -b main
    git config user.email test@example.com
    git config user.name test
    echo "$package_json" >package.json
    [ -n "$lockfile" ] && touch "$lockfile"
    git add -A
    git commit -q -m initial
    git checkout -q -b feature
  )
  echo "$repo_dir"
}

add_change() {
  echo "change" >>"$1/README.md"
  git -C "$1" add README.md
}

# run_hook <repo> <stop_hook_active>: prints stderr, returns the hook exit code.
run_hook() {
  local repo_dir="$1" stop_hook_active="$2"
  : >"$PM_LOG"
  jq -n --arg cwd "$repo_dir" --argjson active "$stop_hook_active" \
    '{hook_event_name: "Stop", cwd: $cwd, stop_hook_active: $active}' |
    (cd "$repo_dir" && PATH="$STUB_DIR:$PATH" bash "$HOOK" 2>&1 >/dev/null)
}

fail() {
  echo "FAIL $1"
  failures=$((failures + 1))
}

# pass_if_clean <name> <failures before the case>: prints ok when the case added no failures.
pass_if_clean() {
  [ "$failures" = "$2" ] && echo "ok   $1"
}

# expect_exit <name> <expected code> <repo> <stop_hook_active>
expect_exit() {
  local output actual_code
  output=$(run_hook "$3" "$4")
  actual_code=$?
  if [ "$actual_code" = "$2" ]; then echo "ok   $1"; else fail "$1: exit $actual_code, expected $2. Output: $output"; fi
}

VERIFY_JSON='{"scripts":{"verify":"true"}}'

failing_repo=$(make_repo failing "$VERIFY_JSON")
add_change "$failing_repo"
export STUB_EXIT=1 STUB_LINES=100
failures_before=$failures
stderr_output=$(run_hook "$failing_repo" false)
actual_code=$?
[ "$actual_code" = 2 ] || fail "failing verify: exit $actual_code, expected 2"
stderr_lines=$(printf '%s\n' "$stderr_output" | wc -l | tr -d ' ')
[ "$stderr_lines" -le 41 ] || fail "failing verify: $stderr_lines stderr lines, expected at most 41"
[[ "$stderr_output" == *"verify line 100"* ]] || fail "failing verify: last output line missing"
[[ "$stderr_output" != *"verify line 60"$'\n'* ]] || fail "failing verify: output not cut to the tail"
pass_if_clean "failing verify exits 2 with at most 41 lines" "$failures_before"

expect_exit "stop_hook_active skips the gate" 0 "$failing_repo" true
unset STUB_EXIT STUB_LINES

expect_exit "passing verify" 0 "$failing_repo" false

no_verify_repo=$(make_repo no-verify '{"scripts":{"test":"true"}}')
add_change "$no_verify_repo"
STUB_EXIT=1 expect_exit "no verify script" 0 "$no_verify_repo" false

no_package_repo="$WORK_DIR/no-package"
mkdir -p "$no_package_repo" && git -C "$no_package_repo" init -q -b main
STUB_EXIT=1 expect_exit "no package.json" 0 "$no_package_repo" false

clean_repo=$(make_repo clean "$VERIFY_JSON")
STUB_EXIT=1 expect_exit "no changes from main" 0 "$clean_repo" false
[ -s "$PM_LOG" ] && fail "no changes from main: verify ran"

for case in "pnpm-lock.yaml pnpm" "yarn.lock yarn" "bun.lockb bun" "bun.lock bun" " npm"; do
  read -r lockfile expected_pm <<<"$case"
  [ -z "$expected_pm" ] && expected_pm=$lockfile && lockfile=""
  pm_repo=$(make_repo "pm-$expected_pm-${lockfile:-none}" "$VERIFY_JSON" "$lockfile")
  add_change "$pm_repo"
  run_hook "$pm_repo" false >/dev/null
  actual_pm=$(cat "$PM_LOG")
  if [ "$actual_pm" = "$expected_pm" ]; then
    echo "ok   lockfile '${lockfile:-none}' picks $expected_pm"
  else
    fail "lockfile '${lockfile:-none}': ran '$actual_pm', expected $expected_pm"
  fi
done

[ $failures -eq 0 ]
