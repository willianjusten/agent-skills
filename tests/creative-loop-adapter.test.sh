#!/bin/bash
# Tests for the creative-loop adapter: the lab default matches the lab commands the skill text names,
# the documented example parses with every required field, and the skill text points at the adapter.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL_DIR="$REPO_ROOT/skills/orchestration/creative-loop"
SKILL="$SKILL_DIR/SKILL.md"
LAB_ADAPTER="$SKILL_DIR/references/adapter-lab.json"
ADAPTER_DOC="$SKILL_DIR/references/adapter.md"
. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

REQUIRED_FIELDS="profile brief directions dev shot check verify record out"

has_required_fields() { # <name> <json file>
  local missing="" field_name
  for field_name in $REQUIRED_FIELDS; do
    jq -e --arg key "$field_name" 'has($key) and .[$key] != null' "$2" >/dev/null || missing="$missing $field_name"
  done
  [ -z "$missing" ] && pass "$1 has every required field" || fail "$1 has every required field" "missing:$missing"
}

jq -e . "$LAB_ADAPTER" >/dev/null && pass "lab adapter is valid JSON" || fail "lab adapter is valid JSON"
has_required_fields "lab adapter" "$LAB_ADAPTER"

# The lab default and the skill's lab literals must not drift apart
lab_text=$(cat "$SKILL" "$SKILL_DIR"/references/*.md)
for command_key in shot check verify record scaffold; do
  command_name=$(jq -r --arg key "$command_key" '.[$key]' "$LAB_ADAPTER" | awk '{ print $1, $2 }')
  grep -qF -- "$command_name" <<<"$lab_text" && pass "lab $command_key ($command_name) is named in the skill" || fail "lab $command_key ($command_name) is named in the skill"
done
[ "$(jq -r .out "$LAB_ADAPTER")" = ".verify/{app}" ] && pass "lab output folder is .verify/<app>" || fail "lab output folder is .verify/<app>"
[ "$(jq -r .directions.source "$LAB_ADAPTER")" = brief ] && pass "lab directions come from the brief" || fail "lab directions come from the brief"

# The documented example is a complete adapter
awk '/^```json$/ { inside = 1; next } /^```$/ { inside = 0 } inside' "$ADAPTER_DOC" >"$work/example.json"
jq -e . "$work/example.json" >/dev/null && pass "adapter.md example is valid JSON" || fail "adapter.md example is valid JSON" "$(cat "$work/example.json")"
has_required_fields "adapter.md example" "$work/example.json"
for field_name in $REQUIRED_FIELDS checkSlow install scaffold; do
  grep -qF "| \`$field_name\` |" "$ADAPTER_DOC" && pass "adapter.md documents $field_name" || fail "adapter.md documents $field_name"
done

# The skill finds the adapter and stops without one
grep -qF 'references/adapter.md' "$SKILL" && pass "SKILL.md links the adapter reference" || fail "SKILL.md links the adapter reference"
grep -qF '.claude/creative-loop.json' "$ADAPTER_DOC" && pass "adapter lives at .claude/creative-loop.json" || fail "adapter lives at .claude/creative-loop.json"
grep -qF '/setup-creative-loop' "$ADAPTER_DOC" && pass "no adapter sends the user to /setup-creative-loop" || fail "no adapter sends the user to /setup-creative-loop"
grep -rqF '/Users/' "$SKILL_DIR" && fail "no machine paths in the skill" "$(grep -rlF '/Users/' "$SKILL_DIR")" || pass "no machine paths in the skill"

[ "$failures" -eq 0 ] || exit 1
