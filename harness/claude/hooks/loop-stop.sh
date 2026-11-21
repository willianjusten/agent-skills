#!/bin/bash
# Stop hook for long runs (see docs/loop-log.md). While a run is active, budget
# remains and the run is not done, it blocks the stop with the next unchecked
# direction from the loop log, or with the review-cycle instruction once the list is
# done. A no-op outside a run. Fails open: no jq, unparsable input, a missing or
# unreadable log all allow the stop, so a broken run never traps a session.
#
# Active run: a marker file named .loop-active, found by walking up from the hook's
# cwd. It holds {"log": "<path, relative to the marker's folder or absolute>",
# "session_id": "<optional>"}; with a session_id, only that session is looped.
# Removing the marker ends the run.
#
# Allows the stop when: no marker, other session, log missing, Status: done, budget
# spent (cycle count or end time), or the agent stopped twice with the loop log and
# the working tree unchanged (loop breaker, state kept in .loop-active.state).
# LOOP_NOW (epoch seconds) overrides the clock, for tests.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
jq -e . >/dev/null 2>&1 <<<"$input" || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input")
session_id=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

run_dir=$(cd "$cwd" && pwd -P)
while [ ! -f "$run_dir/.loop-active" ]; do
  [ "$run_dir" = "/" ] && exit 0
  run_dir=$(dirname "$run_dir")
done
marker="$run_dir/.loop-active"

marker_session=$(jq -r '.session_id // empty' "$marker" 2>/dev/null) || exit 0
[ -z "$marker_session" ] || [ "$marker_session" = "$session_id" ] || exit 0
log_path=$(jq -r '.log // empty' "$marker" 2>/dev/null)
[ -n "$log_path" ] || exit 0
case "$log_path" in /*) ;; *) log_path="$run_dir/$log_path" ;; esac
[ -r "$log_path" ] || exit 0

header() { sed -n "s/^$1:[[:space:]]*//p" "$log_path" | head -1; }
section_lines() { awk -v name="$1" '/^## / { in_section = ($0 == "## " name); next } in_section' "$log_path"; }

[ "$(header Status | tr '[:upper:]' '[:lower:]')" = "done" ] && exit 0

now=${LOOP_NOW:-$(date -u +%s)}
budget=$(header Budget)
cycles_done=$(section_lines Cycles | grep -c '^- ')
if [[ "$budget" =~ ^([0-9]+)[[:space:]]+cycles?$ ]]; then
  [ "$cycles_done" -ge "${BASH_REMATCH[1]}" ] && exit 0
elif [[ "$budget" =~ ends[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8})Z ]]; then
  end_iso="${BASH_REMATCH[1]}Z"
  end_epoch=$(jq -nr --arg t "$end_iso" '$t | fromdateiso8601' 2>/dev/null) || exit 0
  [ "$now" -ge "$end_epoch" ] && exit 0
else
  exit 0 # no parsable budget: do not loop
fi

# Loop breaker: the same log and tree as at the previous block means the agent did nothing.
state_file="$marker.state"
fingerprint=$( { cat "$log_path"; git -C "$run_dir" status --porcelain -- . ':!.loop-active*' 2>/dev/null; git -C "$run_dir" diff 2>/dev/null; } | cksum)
if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$fingerprint" ]; then
  exit 0
fi
echo "$fingerprint" >"$state_file"

next_direction=$(section_lines Directions | sed -n 's/^- \[ \][[:space:]]*//p' | head -1)
if [ -n "$next_direction" ]; then
  reason="Loop budget remains. Next direction from the loop log ($log_path): $next_direction. Do it, tick its box and add a line under Cycles."
else
  reason="Loop budget remains and every direction is checked. Run a review cycle: review the current state against the brief, add new unchecked directions to the loop log ($log_path) for what still falls short, or set Status: done if nothing does."
fi
jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
