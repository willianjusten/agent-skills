#!/bin/bash
# PostToolUse hook for Write|Edit. Checks tickets at .scratch/<feature>/issues/*.md
# against the ticket contract in ~/.claude/matt-skills/issue-tracker.md.
# Exit 2 sends the list of missing or invalid fields back to the agent.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] && cd "$HOOK_CWD"

[[ "$FILE_PATH" =~ (^|/)\.scratch/[^/]+/issues/[^/]+\.md$ ]] || exit 0
[ -f "$FILE_PATH" ] || exit 0

STATUS_VALUES="needs-triage needs-info ready-for-agent ready-for-human in-progress done wontfix"
TESTS_VALUES="tdd e2e verify-only"
problems=()

# Prints the value of the first plain `Field: value` line, or fails when there is none.
field_value() {
  local line
  line=$(grep -m1 -E "^$1:" "$FILE_PATH") || return 1
  line="${line#"$1:"}"
  line="${line#"${line%%[![:space:]]*}"}"
  echo "${line%"${line##*[![:space:]]}"}"
}

# Sets FIELD_VALUE when the field is present and not empty; records a problem otherwise.
require_field() {
  local value
  if ! value=$(field_value "$1"); then
    if grep -qE "^\*\*$1(:\*\*|\*\*:)" "$FILE_PATH"; then
      problems+=("$1: bold; write it as a plain '$1: <value>' line")
    else
      problems+=("$1: missing")
    fi
    return 1
  fi
  if [ -z "$value" ]; then
    problems+=("$1: empty")
    return 1
  fi
  FIELD_VALUE="$value"
}

is_one_of() {
  local allowed
  for allowed in $2; do
    [ "$1" = "$allowed" ] && return 0
  done
  return 1
}

if require_field "Status"; then
  is_one_of "$FIELD_VALUE" "$STATUS_VALUES" || problems+=("Status: invalid value '$FIELD_VALUE'; expected one of: $STATUS_VALUES")
fi

if require_field "Blocked by"; then
  [[ "$FIELD_VALUE" =~ ^(None|[0-9]+(,[[:space:]]*[0-9]+)*)$ ]] ||
    problems+=("Blocked by: invalid value '$FIELD_VALUE'; expected 'None' or ticket numbers like '02, 03'")
fi

require_field "Areas"

if require_field "Tests"; then
  is_one_of "$FIELD_VALUE" "$TESTS_VALUES" || problems+=("Tests: invalid value '$FIELD_VALUE'; expected one of: $TESTS_VALUES")
fi

[ ${#problems[@]} -eq 0 ] && exit 0

{
  echo "Ticket $FILE_PATH breaks the ticket contract (see ~/.claude/matt-skills/issue-tracker.md):"
  printf -- '- %s\n' "${problems[@]}"
} >&2
exit 2
