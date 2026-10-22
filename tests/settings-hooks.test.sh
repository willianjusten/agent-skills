#!/bin/bash
# Tests for harness/claude/settings.json: hooks stay stack-agnostic, so no hook
# command runs the project's toolchain (verify, a package manager, node or a
# version manager), and Stop still plays the Glass sound.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SETTINGS="$REPO_ROOT/harness/claude/settings.json"
failures=0

hook_commands=$(jq -r '.hooks // {} | .[][] | .hooks[]? | .command // empty' "$SETTINGS")
stop_commands=$(jq -r '.hooks.Stop // [] | .[] | .hooks[]? | .command // empty' "$SETTINGS")

toolchain_pattern='(^|[^[:alnum:]_-])(verify|npm|npx|pnpm|yarn|bun|node|mise|nvm)([^[:alnum:]_]|$)'
toolchain_hooks=$(echo "$hook_commands" | grep -E "$toolchain_pattern")
if [ -n "$toolchain_hooks" ]; then
  echo "FAIL no hook runs the project toolchain: $toolchain_hooks"
  failures=$((failures + 1))
else
  echo "ok   no hook runs the project toolchain"
fi

if echo "$stop_commands" | grep -q 'Glass.aiff'; then
  echo "ok   Stop plays the Glass sound"
else
  echo "FAIL Stop plays the Glass sound: $stop_commands"
  failures=$((failures + 1))
fi

[ "$failures" -eq 0 ] || exit 1
