#!/bin/bash
# Stop and SubagentStop hook, no matcher. Blocks an agent from finishing while
# the project's verify script fails on a branch with changes from the default branch.
# Output is capped at 40 lines plus a header (spec: Token budget).

INPUT=$(cat)
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] && cd "$HOOK_CWD"

jq -e '.scripts.verify' package.json >/dev/null 2>&1 || exit 0
DEFAULT_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
BASE=$(git merge-base HEAD "${DEFAULT_BRANCH:-main}" 2>/dev/null) || exit 0
git diff --quiet "$BASE" && exit 0

PACKAGE_MANAGER=npm
[ -f pnpm-lock.yaml ] && PACKAGE_MANAGER=pnpm
[ -f yarn.lock ] && PACKAGE_MANAGER=yarn
{ [ -f bun.lockb ] || [ -f bun.lock ]; } && PACKAGE_MANAGER=bun

VERIFY_OUTPUT=$("$PACKAGE_MANAGER" run --silent verify 2>&1) || {
  echo "verify failed; fix it before finishing:" >&2
  echo "$VERIFY_OUTPUT" | tail -40 >&2
  exit 2
}
exit 0
