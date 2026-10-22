#!/bin/bash
# Tests for harness/claude/settings.json: hooks stay stack-agnostic, so no hook
# command runs the project's toolchain (verify, a package manager or node).

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SETTINGS="$REPO_ROOT/harness/claude/settings.json"
failures=0

hook_commands=$(jq -r '.hooks // {} | .[][] | .hooks[]? | .command // empty' "$SETTINGS")

toolchain_pattern='(^|[^[:alnum:]_-])(verify|npm|npx|pnpm|yarn|bun|node|mise|nvm)([^[:alnum:]_]|$)'
while IFS= read -r hook_command; do
  [ -n "$hook_command" ] || continue
  if echo "$hook_command" | grep -Eq "$toolchain_pattern"; then
    echo "FAIL hook runs the project toolchain: $hook_command"
    failures=$((failures + 1))
  fi
done <<<"$hook_commands"

if ! echo "$hook_commands" | grep -q 'Glass.aiff'; then
  echo "FAIL Stop no longer plays the Glass sound"
  failures=$((failures + 1))
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
echo "ok"
