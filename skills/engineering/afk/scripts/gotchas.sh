#!/bin/bash
# Usage: gotchas.sh [repo root]
#
# Checks <repo root>/docs/GOTCHAS.md and prints one finding per line:
#   stale <line>: `<name>` not found   a backticked name on that line is neither
#                                      in any other tracked file nor an existing path
#   long: <count> lines, limit 30      the file has grown past its budget
# Lines that name nothing in backticks are never stale. No file, no output.

MAX_LINES=30
repo_root="${1:-.}"
gotchas_file="$repo_root/docs/GOTCHAS.md"

[ -f "$gotchas_file" ] || exit 0

name_exists() {
  [ -e "$repo_root/$1" ] && return 0
  git -C "$repo_root" grep -qwF -e "$1" -- . ':!docs/GOTCHAS.md' 2>/dev/null
}

line_number=0
while IFS= read -r line || [ -n "$line" ]; do
  line_number=$((line_number + 1))
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! name_exists "$name"; then
      echo "stale $line_number: \`$name\` not found"
      break
    fi
  done < <(echo "$line" | grep -oE '`[^`]+`' | tr -d '`')
done <"$gotchas_file"

line_count=$(wc -l <"$gotchas_file" | tr -d ' ')
[ "$line_count" -gt "$MAX_LINES" ] && echo "long: $line_count lines, limit $MAX_LINES"
exit 0
