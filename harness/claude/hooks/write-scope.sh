#!/bin/bash
# PreToolUse hook for the polish workers (see agents/realtime/polish-worker.md).
# A worker may write only inside the folders its area declares in
# .polish-scope.json, found by walking up from the file being written; shared files
# listed there stay reserved for the polish director. Blocks with exit 2 and a
# message on stderr. Fails closed: no jq, unparsable input, an empty tool name or
# path, a missing or malformed scope file and an allow entry that would cover the
# whole worktree all block. Paths are resolved physically (symlinks followed, also
# for files that do not exist yet) before they are compared.
#
# .polish-scope.json: {"area": "...", "allow": ["dir/"], "shared": ["file"]},
# every path relative to the folder holding the file. The shared list and the scope
# file name are compared case-insensitively, because the default macOS filesystem
# is; the allow list stays case-sensitive, which can only block more.

block() {
  echo "write-scope: $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || block "jq is not installed, so the scope cannot be checked; install jq"

input=$(cat)
jq -e . >/dev/null 2>&1 <<<"$input" || block "the tool call on stdin is not valid JSON"
tool_name=$(jq -r '.tool_name // empty' <<<"$input")
[ -n "$tool_name" ] || block "the tool call has no tool name"
case "$tool_name" in
  Write | Edit | MultiEdit | NotebookEdit) ;;
  *) exit 0 ;;
esac

target_path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
session_cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$session_cwd" ] || session_cwd=$PWD

lowercase() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Physical path: absolute, no . or .. segments, every symlink followed. Works for
# paths that do not exist yet because it walks component by component.
resolve_path() {
  local pending="$1" resolved="" component link_target hops=0
  while [ -n "$pending" ]; do
    component=${pending%%/*}
    if [ "$component" = "$pending" ]; then pending=""; else pending=${pending#*/}; fi
    case "$component" in
      "" | .) continue ;;
      ..) resolved=${resolved%/*}; continue ;;
    esac
    if [ -L "$resolved/$component" ]; then
      hops=$((hops + 1))
      [ "$hops" -le 40 ] || block "too many symlinks while resolving $1"
      link_target=$(readlink "$resolved/$component")
      case "$link_target" in
        /*) resolved=""; pending="$link_target/$pending" ;;
        *) pending="$link_target/$pending" ;;
      esac
    else
      resolved="$resolved/$component"
    fi
  done
  printf '%s\n' "${resolved:-/}"
}

[ -n "$target_path" ] || block "a write call came without a path"
case "$target_path" in
  /*) ;;
  *) target_path="$session_cwd/$target_path" ;;
esac
target_path=$(resolve_path "$target_path") || exit 2
[ "$(lowercase "$(basename "$target_path")")" = ".polish-scope.json" ] && block "scope files are owned by the polish director"

scope_root=$(dirname "$target_path")
while [ ! -f "$scope_root/.polish-scope.json" ]; do
  [ "$scope_root" = "/" ] && block "$target_path is under no .polish-scope.json, so no polish area owns it; ask the polish director"
  scope_root=$(dirname "$scope_root")
done
scope_file="$scope_root/.polish-scope.json"
jq -e . "$scope_file" >/dev/null 2>&1 || block "$scope_file is not valid JSON"
area=$(jq -r '.area // "unnamed"' "$scope_file")
root_resolved=$(resolve_path "$scope_root") || exit 2

shared_paths=$(jq -r '.shared[]?' "$scope_file") || block "cannot read the shared list in $scope_file"
target_lowercase=$(lowercase "$target_path")
while IFS= read -r shared_path; do
  [ -n "$shared_path" ] || continue
  shared_resolved=$(resolve_path "$root_resolved/$shared_path") || exit 2
  [ "$target_lowercase" = "$(lowercase "$shared_resolved")" ] &&
    block "$target_path is a shared file, reserved for the polish director; ask the director to change it"
done <<<"$shared_paths"

allowed_entries=$(jq -r '.allow[]?' "$scope_file") || block "cannot read the allow list in $scope_file"
allowed_folders=""
is_allowed=false
while IFS= read -r allowed_folder; do
  if [ -z "$allowed_folder" ]; then
    [ -z "$allowed_entries" ] && break
    block "an empty allow entry in $scope_file would cover the whole worktree"
  fi
  folder_path=$(resolve_path "$root_resolved/$allowed_folder") || exit 2
  case "$folder_path/" in
    "$root_resolved/") block "the allow entry \"$allowed_folder\" in $scope_file would cover the whole worktree" ;;
    "$root_resolved"/*) ;;
    *) block "the allow entry \"$allowed_folder\" in $scope_file points outside the worktree" ;;
  esac
  case "$target_path" in
    "$folder_path"/*) is_allowed=true ;;
  esac
  allowed_folders="$allowed_folders $allowed_folder"
done <<<"$allowed_entries"

[ "$is_allowed" = true ] && exit 0
block "the $area worker may write only inside:$allowed_folders (not $target_path)"
