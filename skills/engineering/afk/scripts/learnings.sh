#!/bin/bash
# Usage: learnings.sh <feature folder> [ticket number...]
#
# Prints "NN: <learning>" for every "Learning: <one line>" an implementer wrote
# under a ticket's ## Done section (a leading "- " is allowed). With ticket
# numbers, only those tickets are read: pass the ones this run finished.

feature_folder="$1"
shift
issues_dir="$feature_folder/issues"

if [ ! -d "$issues_dir" ]; then
  echo "learnings.sh: no issues/ under $feature_folder" >&2
  exit 1
fi

wanted_numbers=()
for number in "$@"; do
  wanted_numbers+=("$(printf '%02d' "$((10#$number))")")
done

for ticket in "$issues_dir"/[0-9]*.md; do
  [ -e "$ticket" ] || continue
  number=$(basename "$ticket" | grep -oE '^[0-9]+')
  if [ ${#wanted_numbers[@]} -gt 0 ] && [[ " ${wanted_numbers[*]} " != *" $number "* ]]; then
    continue
  fi
  awk -v number="$number" '
    /^## / { in_done = ($0 ~ /^## Done[[:space:]]*$/); next }
    in_done && sub(/^(- )?Learning:[[:space:]]*/, "") { sub(/\r$/, ""); print number ": " $0 }
  ' "$ticket"
done
