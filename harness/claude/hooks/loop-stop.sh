#!/bin/bash
# Stop hook for long runs (format: skills/orchestration/creative-loop/references/loop-log.md). While a run is active, budget
# remains and the run is not stopped, it blocks the stop with the next unchecked
# direction from the loop log, or with the review-cycle instruction once the list is
# done. A no-op outside a run. Fails open: no jq, unparsable input, a missing or
# unreadable log all allow the stop, so a broken run never traps a session.
#
# Active run: a marker file named .loop-active, found by walking up from the hook's
# cwd, never at or above $HOME. It holds {"log": "<path, relative to the marker's
# folder or absolute>", "session_id": "<optional>"}; only that session is looped.
# A marker without a session_id is bound to the first session that stops under it:
# the hook writes that session_id into the marker. Removing the marker ends the run.
#
# Allows the stop when: no marker, other session, log missing, Status: stopped (the user's early
# end; Status: done does not allow while budget remains), budget
# spent (cycle count or end time), a stale marker (older than the budget plus an
# hour; 7 days for a cycle budget), or the agent stopped twice with the loop log
# and the repo that holds it unchanged (loop breaker, state kept in
# .loop-active.state). A user interrupt does not fire Stop, so it needs no case.
# LOOP_NOW (epoch seconds) overrides the clock, for tests.

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)
jq -e . >/dev/null 2>&1 <<<"$input" || exit 0
cwd=$(jq -r '.cwd // empty' <<<"$input")
session_id=$(jq -r '.session_id // empty' <<<"$input")
[ -n "$cwd" ] && [ -d "$cwd" ] || exit 0

run_dir=$(cd "$cwd" && pwd -P)
home_dir=$(cd "${HOME:-/}" 2>/dev/null && pwd -P)
while [ ! -f "$run_dir/.loop-active" ]; do
  run_dir=$(dirname "$run_dir")
  # A marker at or above the home folder is never a run's.
  [ "$run_dir" = "/" ] || [ "$run_dir" = "$home_dir" ] && exit 0
done
[ "$run_dir" = "$home_dir" ] && exit 0
marker="$run_dir/.loop-active"

# Read before binding: rewriting the marker would reset its age.
marker_mtime=$(stat -c %Y "$marker" 2>/dev/null || stat -f %m "$marker" 2>/dev/null) || exit 0
marker_session=$(jq -r '.session_id // empty' "$marker" 2>/dev/null) || exit 0
if [ -z "$marker_session" ]; then
  [ -n "$session_id" ] || exit 0
  bound_marker=$(jq --arg sid "$session_id" '. + {session_id: $sid}' "$marker" 2>/dev/null) || exit 0
  printf '%s\n' "$bound_marker" >"$marker"
elif [ "$marker_session" != "$session_id" ]; then
  exit 0
fi
log_path=$(jq -r '.log // empty' "$marker" 2>/dev/null)
[ -n "$log_path" ] || exit 0
case "$log_path" in /*) ;; *) log_path="$run_dir/$log_path" ;; esac
[ -r "$log_path" ] || exit 0

header() { sed -n "s/^$1:[[:space:]]*//p" "$log_path" | head -1; }
section_lines() { awk -v name="$1" '/^## / { in_section = ($0 == "## " name); next } in_section' "$log_path"; }

# Only the user ends a run early. Status: done while budget remains does not allow the stop.
run_status=$(header Status | tr '[:upper:]' '[:lower:]')
[ "$run_status" = "stopped" ] && exit 0

now=${LOOP_NOW:-$(date -u +%s)}
STALE_MARGIN_SECONDS=3600
max_marker_age=$((7 * 24 * 3600)) # cycle budgets have no end time
budget=$(header Budget)
cycles_done=$(section_lines Cycles | grep -c '^- ')
if [[ "$budget" =~ ^([0-9]+)[[:space:]]+cycles?$ ]]; then
  [ "$cycles_done" -ge "${BASH_REMATCH[1]}" ] && exit 0
elif [[ "$budget" =~ ends[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8})Z ]]; then
  end_iso="${BASH_REMATCH[1]}Z"
  end_epoch=$(jq -nr --arg t "$end_iso" '$t | fromdateiso8601' 2>/dev/null) || exit 0
  [ "$now" -ge "$end_epoch" ] && exit 0
  start_epoch=$(jq -nr --arg t "$(header Started)" '$t | fromdateiso8601' 2>/dev/null) || start_epoch=$now
  max_marker_age=$((end_epoch - start_epoch + STALE_MARGIN_SECONDS))
else
  exit 0 # no parsable budget: do not loop
fi

[ $((now - marker_mtime)) -gt "$max_marker_age" ] && exit 0

# Loop breaker: the same log and tree as at the previous block means the agent did nothing.
# The tree is the repo that holds the log (the lab worktree), not the session folder.
state_file="$marker.state"
log_dir=$(dirname "$log_path")
fingerprint=$( { cat "$log_path"; git -C "$log_dir" status --porcelain -uall 2>/dev/null | grep -v '\.loop-active'; git -C "$log_dir" diff 2>/dev/null; } | cksum)
if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$fingerprint" ]; then
  exit 0
fi
echo "$fingerprint" >"$state_file"

next_direction=$(section_lines Directions | sed -n 's/^- \[ \][[:space:]]*//p' | head -1)
if [ "$run_status" = "done" ]; then
  reason="Status is done but budget remains: finishing early earns nothing. Set Status back to running and run a review cycle: take fresh shots, review the current state against the brief, add new unchecked directions to the loop log ($log_path) for what still falls short, and do them. Only the user's Status: stopped ends the run before the budget is spent."
elif [ -n "$next_direction" ]; then
  reason="Loop budget remains. Next direction from the loop log ($log_path): $next_direction. Do it, tick its box and add a line under Cycles."
else
  reason="Loop budget remains and every direction is checked. Run a review cycle: review the current state against the brief, add new unchecked directions to the loop log ($log_path) for what still falls short, or set Status: done if nothing does."
fi
jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
