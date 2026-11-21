#!/bin/bash
# Starts a loop run: fills the app's LOOP.md (header and directions from BRIEF.md),
# writes .loop-active in the current folder and ignores .loop-active* in git.
# Usage: start-run.sh --app-dir <dir> --budget <45m|8h|20cycles> --mode <review|overnight>
#        --title <title> [--session-id <id>] [--attempts <n>] [--no-marker] [--force]
# The marker takes the session id from --session-id, else $CLAUDE_SESSION_ID; with neither, the
# Stop hook binds the marker to the first session that stops under it.
# Log format: ../references/loop-log.md.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
command -v jq >/dev/null 2>&1 || { echo "jq is required (brew install jq)" >&2; exit 1; }

app_dir="" budget="" mode="review" title="" session_id="" attempts=1 no_marker=0 force=0
while [ $# -gt 0 ]; do
  case "$1" in
    --app-dir) option_value --app-dir $#; app_dir="$2"; shift 2 ;;
    --budget) option_value --budget $#; budget="$2"; shift 2 ;;
    --mode) option_value --mode $#; mode="$2"; shift 2 ;;
    --title) option_value --title $#; title="$2"; shift 2 ;;
    --session-id) option_value --session-id $#; session_id="$2"; shift 2 ;;
    --attempts) option_value --attempts $#; attempts="$2"; shift 2 ;;
    --no-marker) no_marker=1; shift ;;
    --force) force=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -d "$app_dir" ] || { echo "--app-dir must be an existing folder" >&2; exit 2; }
case "$mode" in review | overnight) ;; *) echo "--mode must be review or overnight" >&2; exit 2 ;; esac
[ -n "$title" ] || title="$(basename "$app_dir")"
if [ -z "$budget" ]; then
  if [ "$mode" = overnight ]; then budget="$DEFAULT_OVERNIGHT_BUDGET"; else budget="$DEFAULT_REVIEW_BUDGET"; fi
fi

app_dir="$(cd "$app_dir" && pwd)"
log_path="$app_dir/LOOP.md"
if [ -s "$log_path" ] && awk '/^## / { in_cycles = ($0 == "## Cycles"); next } in_cycles && /^- /' "$log_path" | grep -q . && [ "$force" -eq 0 ]; then
  echo "refusing to overwrite a log that already has cycles (use --force)" >&2
  exit 1
fi

utc_timestamp() { format_utc "$1" %Y-%m-%dT%H:%M:%SZ; }
now_epoch="$(date -u +%s)"
normalized_budget="$(echo "$budget" | tr -d ' ' | tr 'A-Z' 'a-z')"
budget_amount="$(echo "$normalized_budget" | sed 's/[^0-9].*//')"
case "$normalized_budget" in
  *cycles | *cycle)
    budget_line="$budget_amount cycles" ;;
  *h | *hours | *hour)
    budget_line="$budget_amount hours, ends $(utc_timestamp $((now_epoch + budget_amount * SECONDS_PER_HOUR)))" ;;
  *m | *min | *mins | *minutes | *minute)
    budget_line="$budget_amount minutes, ends $(utc_timestamp $((now_epoch + budget_amount * SECONDS_PER_MINUTE)))" ;;
  *) echo "budget must look like 45m, 8h or 20cycles" >&2; exit 2 ;;
esac

brief_path="$app_dir/BRIEF.md"
directions=""
if [ -f "$brief_path" ]; then
  # The numbered lines under the heading that contains "Next directions".
  directions="$(awk '
    /^#+[ \t]/ { in_section = ($0 ~ /[Nn]ext [Dd]irections/); next }
    in_section && /^[ \t]*[0-9]+[.)][ \t]+/ { sub(/^[ \t]*[0-9]+[.)][ \t]+/, ""); print "- [ ] " $0 }
  ' "$brief_path")"
fi

{
  echo "# Loop: $title"
  echo "Brief: BRIEF.md"
  echo "Started: $(utc_timestamp "$now_epoch")"
  echo "Budget: $budget_line"
  echo "Mode: $mode"
  echo "Attempts: $attempts"
  echo "Status: running"
  echo
  echo "## Directions"
  [ -n "$directions" ] && echo "$directions"
  echo
  echo "## Cycles"
  echo
  echo "## Notes"
  [ -n "$directions" ] || echo "Default: the brief has no Next directions list, so the run starts with review cycles."
  echo
  echo "## Open items"
} >"$log_path"

run_folder="$(pwd)"
session_id="${session_id:-${CLAUDE_SESSION_ID:-}}"
# With --no-marker (attempts mode) the orchestrator is the outer loop and the Stop hook must not block it.
if [ "$no_marker" -eq 0 ]; then
  jq -n --arg log "$log_path" --arg sid "$session_id" \
    'if $sid == "" then {log: $log} else {log: $log, session_id: $sid} end' >"$run_folder/.loop-active"
fi
rm -f "$run_folder/.loop-active.state"

# Keep the marker out of commits: .gitignore in the run's repo, info/exclude in the session folder's repo.
if repo_root="$(git -C "$app_dir" rev-parse --show-toplevel 2>/dev/null)"; then
  grep -qxF '.loop-active*' "$repo_root/.gitignore" 2>/dev/null || echo '.loop-active*' >>"$repo_root/.gitignore"
fi
if exclude_file="$(git -C "$run_folder" rev-parse --git-path info/exclude 2>/dev/null)"; then
  case "$exclude_file" in /*) ;; *) exclude_file="$run_folder/$exclude_file" ;; esac
  mkdir -p "$(dirname "$exclude_file")"
  grep -qxF '.loop-active*' "$exclude_file" 2>/dev/null || echo '.loop-active*' >>"$exclude_file"
fi

echo "log: $log_path"
[ "$no_marker" -eq 1 ] || echo "marker: $run_folder/.loop-active"
echo "Status: running"
