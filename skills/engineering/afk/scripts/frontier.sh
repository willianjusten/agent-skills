#!/bin/bash
# Usage: frontier.sh <feature folder> [running ticket number...]
#
# Prints, one per line, the ticket numbers that may start now:
# - Status is ready-for-agent and every ticket in Blocked by is done and not
#   running (a running ticket may read done before its merge lands);
# - at most 2 run at once, counting the running ones passed as arguments;
# - no two share an Areas entry (case-insensitive), running ones included.
# Lowest number wins a free slot.

MAX_RUNNING=2
feature_folder="$1"
shift
running_numbers=("$@")
issues_dir="$feature_folder/issues"

if [ ! -d "$issues_dir" ]; then
  echo "frontier.sh: no issues/ under $feature_folder" >&2
  exit 1
fi

# field <file> <name>: the value of a plain "Name: value" line.
field() {
  sed -n "s/^$2:[[:space:]]*//p" "$1" | head -1 | tr -d '\r'
}

ticket_file() {
  ls "$issues_dir/$1"-*.md 2>/dev/null | head -1
}

# areas <file>: one lowercase area per line.
areas() {
  field "$1" Areas | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]' | grep -v '^$'
}

blockers_done() {
  local blocked_by blocker blocker_file
  blocked_by=$(field "$1" "Blocked by")
  for blocker in $(echo "$blocked_by" | grep -oE '[0-9]+'); do
    blocker=$(printf '%02d' "$((10#$blocker))")
    [[ " ${running_numbers[*]} " == *" $blocker "* ]] && return 1
    blocker_file=$(ticket_file "$blocker")
    [ -n "$blocker_file" ] && [ "$(field "$blocker_file" Status)" = "done" ] || return 1
  done
  return 0
}

taken_areas=""
running_count=0
for number in "${running_numbers[@]}"; do
  running_file=$(ticket_file "$number")
  [ -n "$running_file" ] && taken_areas+="$(areas "$running_file")"$'\n'
  running_count=$((running_count + 1))
done

for ticket in "$issues_dir"/[0-9]*.md; do
  [ -e "$ticket" ] || continue
  [ "$running_count" -ge "$MAX_RUNNING" ] && break
  number=$(basename "$ticket" | grep -oE '^[0-9]+')
  [[ " ${running_numbers[*]} " == *" $number "* ]] && continue
  [ "$(field "$ticket" Status)" = "ready-for-agent" ] || continue
  blockers_done "$ticket" || continue
  ticket_areas=$(areas "$ticket")
  if [ -n "$ticket_areas" ] && [ -n "$taken_areas" ] &&
    grep -qxFf <(echo "$ticket_areas") <(echo "$taken_areas"); then
    continue
  fi
  echo "$number"
  taken_areas+="$ticket_areas"$'\n'
  running_count=$((running_count + 1))
done
