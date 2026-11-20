#!/bin/bash
# Tests for the orchestrator dependency check: an orchestrator (any agent, or a
# skill under skills/orchestration/) lists the skills and agents it runs in
# metadata.uses; `install.sh check` fails when one is missing or scoped where
# the orchestrator cannot see it. Runs against a fixture copy of the repo.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

write_skill() {
  local root="$1" category="$2" name="$3" scope="$4" uses="${5:-}"
  mkdir -p "$root/skills/$category/$name"
  {
    printf -- '---\nname: %s\ndescription: Test skill.\nmetadata:\n  scope: %s\n' "$name" "$scope"
    [ -n "$uses" ] && printf '  uses: %s\n' "$uses"
    printf -- '---\n\nBody.\n'
  } >"$root/skills/$category/$name/SKILL.md"
  echo "# $name" >"$root/skills/$category/$name/README.md"
}

write_agent() {
  local root="$1" name="$2" scope="$3" uses="${4:-}"
  mkdir -p "$root/agents/test"
  {
    printf -- '---\nname: %s\ndescription: Use when testing.\nmodel: opus\nmetadata:\n  scope: %s\n' "$name" "$scope"
    [ -n "$uses" ] && printf '  uses: %s\n' "$uses"
    printf -- '---\n\nBody.\n'
  } >"$root/agents/test/$name.md"
}

make_fixture() {
  local root="$1"
  mkdir -p "$root/harness/shared" "$root/harness/claude" "$root/skills" "$root/agents"
  cp "$REPO_ROOT/install.sh" "$root/install.sh"
  echo '{}' >"$root/scopes.json"
  local validator_dir="$root/vendor/robonuggets/skill-creator-plus/.agents/skills/skill-creator-plus/scripts"
  mkdir -p "$validator_dir"
  echo 'print("stub")' >"$validator_dir/validate_skill.py"
  write_skill "$root" engineering shared-leaf both
  write_skill "$root" engineering personal-leaf personal
  write_skill "$root" engineering off-leaf off
  write_agent "$root" helper-agent personal
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
home="$work/home"
mkdir -p "$home"

# Runs check on a fresh fixture after $1 sets up the orchestrator; sets $status and $output.
run_check() {
  local setup="$1" root="$work/repo"
  rm -rf "$root"
  make_fixture "$root"
  "$setup" "$root"
  output=$(HOME="$home" "$root/install.sh" check 2>&1)
  status=$?
}

expect_pass() {
  run_check "$2"
  [ "$status" -eq 0 ] && pass "$1" || fail "$1" "$output"
}

expect_fail() {
  local description="$1" setup="$2" message="$3"
  run_check "$setup"
  if [ "$status" -ne 0 ] && echo "$output" | grep -qF "$message"; then
    pass "$description"
  else
    fail "$description" "$output"
  fi
}

ok_skill() { write_skill "$1" orchestration conductor personal "shared-leaf, personal-leaf helper-agent"; }
missing_skill() { write_skill "$1" orchestration conductor personal "shared-leaf ghost-skill"; }
narrow_skill() { write_skill "$1" orchestration conductor both "personal-leaf"; }
off_dep() { write_skill "$1" orchestration conductor personal "off-leaf"; }
ok_agent() { write_agent "$1" boss personal "shared-leaf helper-agent"; }
missing_agent() { write_agent "$1" boss personal "ghost-agent"; }
narrow_agent() { write_agent "$1" boss both "helper-agent"; }
both_sees_both() { write_skill "$1" orchestration conductor both "shared-leaf"; }
leaf_with_uses() { write_skill "$1" engineering sibling-namer personal "shared-leaf"; }

expect_pass "check passes on an orchestrator skill whose dependencies are all visible" ok_skill
expect_pass "check passes on an orchestrator scoped both naming a both skill" both_sees_both
expect_pass "check passes on an orchestrator agent whose dependencies are all visible" ok_agent
expect_fail "check fails on an orchestrator skill naming a missing skill" missing_skill "ghost-skill: not found"
expect_fail "check fails on an orchestrator agent naming a missing agent" missing_agent "ghost-agent: not found"
expect_fail "check fails on a both orchestrator naming a personal skill" narrow_skill "personal-leaf: scoped personal, not visible to a both orchestrator"
expect_fail "check fails on a both agent naming a personal agent" narrow_agent "helper-agent: scoped personal, not visible to a both orchestrator"
expect_fail "check fails on an orchestrator naming a skill scoped off" off_dep "off-leaf: scoped off"
expect_fail "check fails on a leaf skill that declares uses" leaf_with_uses "only orchestrators"

[ "$failures" -eq 0 ] || exit 1
