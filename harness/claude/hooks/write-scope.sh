#!/bin/bash
# PreToolUse hook for the polish workers (see agents/realtime/polish-worker.md).
# A worker may write only inside the folders its area declares in
# .polish-scope.json, found by walking up from the session's cwd; shared files
# listed there stay reserved for the polish director. Blocks with exit 2 and a
# message on stderr; fails closed when no scope file is found. Needs jq.
#
# .polish-scope.json: {"area": "...", "allow": ["dir/"], "shared": ["file"]},
# every path relative to the folder holding the file.

input=$(cat)
tool_name=$(jq -r '.tool_name // empty' <<<"$input")
case "$tool_name" in
  Write | Edit | MultiEdit | NotebookEdit) ;;
  *) exit 0 ;;
esac

target_path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
session_cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$session_cwd" ] || session_cwd=$PWD

block() {
  echo "write-scope: $1" >&2
  exit 2
}

# Lexical normalization: absolute path, no . or .. segments, no trailing slash.
normalize_path() {
  awk -v path="$1" 'BEGIN {
    count = split(path, parts, "/"); depth = 0
    for (i = 1; i <= count; i++) {
      if (parts[i] == "" || parts[i] == ".") continue
      if (parts[i] == "..") { if (depth > 0) depth--; continue }
      stack[++depth] = parts[i]
    }
    out = ""
    for (i = 1; i <= depth; i++) out = out "/" stack[i]
    print (out == "" ? "/" : out)
  }'
}

scope_root=$session_cwd
while [ ! -f "$scope_root/.polish-scope.json" ]; do
  [ "$scope_root" = "/" ] && block "no .polish-scope.json above $session_cwd, so this worker has no declared folder; ask the polish director"
  scope_root=$(dirname "$scope_root")
done
scope_file="$scope_root/.polish-scope.json"
area=$(jq -r '.area // "unnamed"' "$scope_file")

[ -n "$target_path" ] || block "the $area worker made a write call without a path"
case "$target_path" in
  /*) ;;
  *) target_path="$session_cwd/$target_path" ;;
esac
target_path=$(normalize_path "$target_path")

root_normalized=$(normalize_path "$scope_root")
[ "$target_path" = "$root_normalized/.polish-scope.json" ] && block "the scope file is owned by the polish director"

while IFS= read -r shared_path; do
  [ -n "$shared_path" ] || continue
  [ "$target_path" = "$(normalize_path "$root_normalized/$shared_path")" ] &&
    block "$target_path is a shared file, reserved for the polish director; ask the director to change it"
done < <(jq -r '.shared[]?' "$scope_file")

allowed_folders=""
while IFS= read -r allowed_folder; do
  [ -n "$allowed_folder" ] || continue
  folder_path=$(normalize_path "$root_normalized/$allowed_folder")
  case "$target_path" in
    "$folder_path"/*) exit 0 ;;
  esac
  allowed_folders="$allowed_folders $allowed_folder"
done < <(jq -r '.allow[]?' "$scope_file")

block "the $area worker may write only inside:$allowed_folders (not $target_path)"
