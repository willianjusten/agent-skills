#!/bin/bash
# Prints the worktree and branch plan for attempts mode, one line per attempt, and creates nothing.
# Usage: plan-attempts.sh --lab <path> --app <name> --attempts <1..3> [--run-id <id>]
# Line:  attempt <letter> branch=loop/<app>-<run-id>-<letter> worktree=<lab-parent>/<lab-dir>-<app>-<run-id>-<letter>
# Names carry the run id and the attempt letter, so attempts and runs never collide.
# Refuses a branch or a path that already exists. PLAN_NOW fixes the clock for the default run id.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

lab="" app="" attempts="" run_id=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lab) option_value --lab $#; lab="$2"; shift 2 ;;
    --app) option_value --app $#; app="$2"; shift 2 ;;
    --attempts) option_value --attempts $#; attempts="$2"; shift 2 ;;
    --run-id) option_value --run-id $#; run_id="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$attempts" in [1-9]) [ "$attempts" -le "$MAX_ATTEMPTS" ] || attempts="" ;; *) attempts="" ;; esac
[ -n "$attempts" ] || { echo "--attempts must be between 1 and $MAX_ATTEMPTS" >&2; exit 2; }
[ -n "$app" ] || { echo "--app is required" >&2; exit 2; }
git -C "$lab" rev-parse --show-toplevel >/dev/null 2>&1 || { echo "--lab must be a git checkout" >&2; exit 2; }
lab_root="$(cd "$lab" && git rev-parse --show-toplevel)"
if [ -z "$run_id" ]; then
  now_epoch="${PLAN_NOW:-$(date -u +%s)}"
  run_id="$(format_utc "$now_epoch" %m%d%H%M%S)"
fi
case "$run_id" in *[!a-zA-Z0-9]* | "") echo "--run-id must be letters and digits" >&2; exit 2 ;; esac

lab_parent="$(dirname "$lab_root")"
lab_name="$(basename "$lab_root")"
status=0
for index in $(seq 1 "$attempts"); do
  letter="$(attempt_letter "$index")"
  branch="loop/$app-$run_id-$letter"
  worktree="$lab_parent/$lab_name-$app-$run_id-$letter"
  if git -C "$lab_root" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "branch already exists: $branch" >&2; status=1
  fi
  if [ -e "$worktree" ]; then
    echo "path already exists: $worktree" >&2; status=1
  fi
  echo "attempt $letter branch=$branch worktree=$worktree"
done
exit "$status"
