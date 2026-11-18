#!/bin/bash
# Tests for harness/claude/hooks/write-scope.sh, the PreToolUse hook of the polish
# workers: a worker may write only inside the folders its area declares in
# .polish-scope.json at the worktree root, and shared files are reserved for the
# director. The hook gets the tool call as JSON on stdin and blocks with exit 2.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/write-scope.sh"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
worktree="$work/worktree"
mkdir -p "$worktree/app/src/lighting" "$worktree/app/src/vfx" "$worktree/app/src/ui"
cat >"$worktree/.polish-scope.json" <<'JSON'
{
  "area": "lighting",
  "allow": ["app/src/lighting/", "app/public/lighting/"],
  "shared": ["app/package.json", "app/src/main.ts", "app/src/lighting/shared.ts"]
}
JSON

# run_hook <tool> <path> [cwd]: prints the hook's stderr and sets hook_status.
run_hook() {
  local tool="$1" path="$2" cwd="${3:-$worktree}"
  hook_output=$(jq -n --arg tool "$tool" --arg path "$path" --arg cwd "$cwd" \
    '{tool_name: $tool, cwd: $cwd, tool_input: {file_path: $path}}' | bash "$HOOK" 2>&1)
  hook_status=$?
}

expect_allowed() {
  run_hook "$2" "$3" "${4:-}"
  [ "$hook_status" -eq 0 ] && pass "$1" || fail "$1" "status $hook_status: $hook_output"
}

expect_blocked() {
  run_hook "$2" "$3" "${4:-}"
  if [ "$hook_status" -eq 2 ] && [ -n "$hook_output" ]; then
    pass "$1"
  else
    fail "$1" "status $hook_status: $hook_output"
  fi
}

expect_allowed "a write inside the area folder is allowed" Write "$worktree/app/src/lighting/rig.ts"
expect_allowed "an edit in a nested folder of the area is allowed" Edit "$worktree/app/src/lighting/rigs/key.ts"
expect_allowed "a relative path inside the area is allowed" Edit "app/public/lighting/probe.hdr"
expect_allowed "a write from a subfolder cwd is resolved against the worktree" Write "$worktree/app/src/lighting/rig.ts" "$worktree/app/src"
expect_blocked "a write in another area folder is blocked" Write "$worktree/app/src/vfx/sparks.ts"
expect_blocked "a write outside the repo is blocked" Write "$work/elsewhere/notes.txt"
expect_blocked "a path that climbs out of the area with .. is blocked" Edit "$worktree/app/src/lighting/../vfx/sparks.ts"
expect_blocked "a sibling folder sharing the area's name prefix is blocked" Write "$worktree/app/src/lighting-extra/rig.ts"
expect_blocked "a shared file is reserved for the director" Edit "$worktree/app/package.json"
expect_blocked "a shared file inside the area folder is still reserved" Edit "$worktree/app/src/lighting/shared.ts"
expect_blocked "the scope file itself cannot be edited by a worker" Write "$worktree/.polish-scope.json"
expect_blocked "MultiEdit is checked like Edit" MultiEdit "$worktree/app/src/ui/panel.ts"
expect_blocked "NotebookEdit is checked like Edit" NotebookEdit "$worktree/app/src/ui/panel.ts"
expect_allowed "tools that write nothing are left alone" Read "$worktree/app/package.json"

mkdir -p "$work/unscoped"
expect_blocked "with no scope file the hook fails closed" Write "$work/unscoped/file.ts" "$work/unscoped"

block_message=$(jq -n --arg path "$worktree/app/src/vfx/sparks.ts" --arg cwd "$worktree" \
  '{tool_name: "Write", cwd: $cwd, tool_input: {file_path: $path}}' | bash "$HOOK" 2>&1)
if echo "$block_message" | grep -q "lighting" && echo "$block_message" | grep -q "app/src/lighting/"; then
  pass "the block message names the area and its folders"
else
  fail "the block message names the area and its folders" "$block_message"
fi

[ "$failures" -eq 0 ] || exit 1
