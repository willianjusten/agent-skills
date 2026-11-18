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
expect_allowed "the scope file is found from the target, so a worker started elsewhere still follows it" Write "$worktree/app/src/lighting/rig.ts" "$work"
expect_blocked "a write in another area folder is blocked" Write "$worktree/app/src/vfx/sparks.ts"
expect_blocked "a write outside the repo is blocked" Write "$work/elsewhere/notes.txt"
expect_blocked "a path that climbs out of the area with .. is blocked" Edit "$worktree/app/src/lighting/../vfx/sparks.ts"
expect_blocked "a sibling folder sharing the area's name prefix is blocked" Write "$worktree/app/src/lighting-extra/rig.ts"
expect_blocked "a shared file is reserved for the director" Edit "$worktree/app/package.json"
expect_blocked "a shared file inside the area folder is still reserved" Edit "$worktree/app/src/lighting/shared.ts"
expect_blocked "the scope file itself cannot be edited by a worker" Write "$worktree/.polish-scope.json"
expect_blocked "a worker cannot plant a nested scope file inside its own folder" Write "$worktree/app/src/lighting/.polish-scope.json"
expect_blocked "MultiEdit is checked like Edit" MultiEdit "$worktree/app/src/ui/panel.ts"
expect_blocked "NotebookEdit is checked like Edit" NotebookEdit "$worktree/app/src/ui/panel.ts"
expect_allowed "tools that write nothing are left alone" Read "$worktree/app/package.json"

mkdir -p "$work/unscoped"
expect_blocked "a path under no scope file is blocked even from a scoped cwd" Write "$work/unscoped/file.ts" "$worktree"
expect_blocked "with no scope file the hook fails closed" Write "$work/unscoped/file.ts" "$work/unscoped"

# Fail closed on bad input.
raw_status() {
  hook_output=$(printf '%s' "$1" | bash "$HOOK" 2>&1)
  hook_status=$?
}
expect_raw_blocked() {
  raw_status "$2"
  if [ "$hook_status" -eq 2 ] && [ -n "$hook_output" ]; then pass "$1"; else fail "$1" "status $hook_status: $hook_output"; fi
}
expect_raw_blocked "unparsable stdin is blocked" "not json {"
expect_raw_blocked "an empty tool name is blocked" "{\"cwd\": \"$worktree\", \"tool_input\": {\"file_path\": \"$worktree/app/src/lighting/a.ts\"}}"
expect_raw_blocked "a write tool with an empty path is blocked" "{\"tool_name\": \"Write\", \"cwd\": \"$worktree\", \"tool_input\": {\"file_path\": \"\"}}"
hook_output=$(jq -n --arg path "$worktree/app/src/lighting/a.ts" '{tool_name: "Write", tool_input: {file_path: $path}}' | PATH=/nonexistent /bin/bash "$HOOK" 2>&1)
hook_status=$?
if [ "$hook_status" -eq 2 ] && echo "$hook_output" | grep -q jq; then pass "a missing jq is blocked"; else fail "a missing jq is blocked" "status $hook_status: $hook_output"; fi

# Symlinks cannot carry a write out of the scope.
mkdir -p "$work/outside"
ln -s "$work/outside" "$worktree/app/src/lighting/escape"
ln -s "$worktree/app/src/vfx/sparks.ts" "$worktree/app/src/lighting/alias.ts"
ln -s "$worktree/app/package.json" "$worktree/app/src/lighting/pkg-link.json"
expect_blocked "a write through a symlinked folder that leaves the scope is blocked" Write "$worktree/app/src/lighting/escape/new.txt"
expect_blocked "a write to a symlink that points at another area is blocked" Write "$worktree/app/src/lighting/alias.ts"
expect_blocked "a symlink to a shared file is still the shared file" Edit "$worktree/app/src/lighting/pkg-link.json"
ln -s "$worktree/app/src/lighting" "$worktree/app/src/ui/into-lighting"
expect_allowed "a symlink into the area folder resolves to an allowed path" Write "$worktree/app/src/ui/into-lighting/rig.ts"

# Shared files compare case-insensitively.
expect_blocked "a shared file is blocked whatever its case" Edit "$worktree/App/Package.json"

# Scope files that would widen the area are refused.
widen_worktree() {
  local entry="$1"
  rm -rf "$work/wide" && mkdir -p "$work/wide/src"
  jq -n --arg entry "$entry" '{area: "wide", allow: [$entry], shared: []}' >"$work/wide/.polish-scope.json"
}
for entry in "." "" "./" "src/.." ".."; do
  widen_worktree "$entry"
  expect_blocked "the allow entry \"$entry\" is refused" Write "$work/wide/src/file.ts" "$work/wide"
done
widen_worktree "src/"
expect_allowed "a normal allow entry still works in the same layout" Write "$work/wide/src/file.ts" "$work/wide"

block_message=$(jq -n --arg path "$worktree/app/src/vfx/sparks.ts" --arg cwd "$worktree" \
  '{tool_name: "Write", cwd: $cwd, tool_input: {file_path: $path}}' | bash "$HOOK" 2>&1)
if echo "$block_message" | grep -q "lighting" && echo "$block_message" | grep -q "app/src/lighting/"; then
  pass "the block message names the area and its folders"
else
  fail "the block message names the area and its folders" "$block_message"
fi

[ "$failures" -eq 0 ] || exit 1
