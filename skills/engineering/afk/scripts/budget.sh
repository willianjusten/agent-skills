#!/bin/bash
# Usage: budget.sh [usage cache]   (or set AFK_USAGE_CACHE)
#
# Reads the 5-hour window from the statusline usage cache and prints one line:
#   go <percent>     below 80%: start implementers
#   hold <percent>   80% or more: start no new implementers
#   stop <percent>   90% or more: let running ones finish, then report
#   go unknown       cache missing, unreadable or from a window that already reset
# The cache comes from an undocumented endpoint, so an unknown reading never stops a run.

HOLD_PERCENT=80
STOP_PERCENT=90
cache_file="${1:-${AFK_USAGE_CACHE:-$HOME/.cache/claude-statusline/usage-api.json}}"

session_percent=$(jq -r '
  (.session_resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601) as $resets_at
  | if $resets_at > now then (.session | tonumber) else empty end
' "$cache_file" 2>/dev/null)

if ! [[ "$session_percent" =~ ^[0-9]+$ ]]; then
  echo "go unknown"
elif [ "$session_percent" -ge "$STOP_PERCENT" ]; then
  echo "stop $session_percent"
elif [ "$session_percent" -ge "$HOLD_PERCENT" ]; then
  echo "hold $session_percent"
else
  echo "go $session_percent"
fi
