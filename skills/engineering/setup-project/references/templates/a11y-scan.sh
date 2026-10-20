#!/bin/bash
# Runs axe-core on each URL in a real browser through the agent-browser CLI and fails
# when any page has a violation at a blocking impact. Needs `axe-core` as a dev
# dependency and the agent-browser CLI on PATH; the project's own dev server must be up.
# Usage: scripts/a11y-scan.sh <url> [url...]
set -euo pipefail

# axe-core impacts, lowest to highest: minor, moderate, serious, critical.
BLOCKING_IMPACTS="serious critical"
SESSION="a11y-scan-$$"

[ "$#" -gt 0 ] || { echo "usage: $0 <url> [url...]" >&2; exit 2; }
command -v agent-browser >/dev/null || { echo "a11y-scan needs the agent-browser CLI" >&2; exit 2; }
axe_source=$(node -p "require.resolve('axe-core/axe.min.js')" 2>/dev/null) ||
  { echo "a11y-scan needs axe-core: install it as a dev dependency" >&2; exit 2; }

trap 'agent-browser --session "$SESSION" close >/dev/null 2>&1 || true' EXIT

failed_pages=0
for url in "$@"; do
  agent-browser --session "$SESSION" open "$url" >/dev/null
  # eval prints the result as JSON; the script returns a JSON string, so it is decoded twice.
  violations_json=$(agent-browser --session "$SESSION" eval "$(cat "$axe_source"); axe.run().then(result => JSON.stringify(result.violations))")
  report=$(BLOCKING_IMPACTS="$BLOCKING_IMPACTS" node -e '
    const blocking = process.env.BLOCKING_IMPACTS.split(" ")
    const violations = JSON.parse(JSON.parse(require("fs").readFileSync(0, "utf8")))
    for (const violation of violations.filter((candidate) => blocking.includes(candidate.impact)))
      for (const node of violation.nodes)
        console.log(`${violation.impact} ${violation.id}: ${node.target.join(" ")} - ${violation.help}`)
  ' <<<"$violations_json")
  if [ -n "$report" ]; then
    echo "FAIL $url"
    echo "$report" | sed 's/^/  /'
    failed_pages=$((failed_pages + 1))
  else
    echo "ok   $url"
  fi
done

[ "$failed_pages" -eq 0 ] || { echo "$failed_pages page(s) with $BLOCKING_IMPACTS violations" >&2; exit 1; }
