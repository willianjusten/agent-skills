#!/bin/bash
# Tests for subagent install support: install.sh links agents/<category>/<name>.md
# into ~/.claude/agents/ by scope, `install.sh check` validates agent frontmatter,
# and Spoke gains nothing from agents. Runs install.sh from a fixture copy of the
# repo with a temp HOME and SPOKE_DIR, so it needs no network and touches no real
# config.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

write_agent() {
  local path="$1" frontmatter="$2"
  mkdir -p "$(dirname "$path")"
  printf -- '---\n%s\n---\n\nYou are a test agent.\n' "$frontmatter" >"$path"
}

write_skill() {
  local dir="$1" name="$2"
  mkdir -p "$dir/$name"
  printf -- '---\nname: %s\ndescription: Test skill.\n---\n\nBody.\n' "$name" >"$dir/$name/SKILL.md"
}

# A repo copy with one fake vendored source already installed (lock matches its
# last-installed copy), so install.sh never calls the skills CLI.
make_fixture() {
  local root="$1"
  mkdir -p "$root/harness/shared" "$root/harness/claude" "$root/skills"
  cp "$REPO_ROOT/install.sh" "$root/install.sh"
  local source_dir="$root/vendor/example/skills"
  mkdir -p "$source_dir/.agents/skills"
  write_skill "$source_dir/.agents/skills" shared-skill
  write_skill "$source_dir/.agents/skills" private-skill
  printf '{"version":2,"skills":{"shared-skill":{},"private-skill":{}}}\n' >"$source_dir/skills-lock.json"
  cp "$source_dir/skills-lock.json" "$source_dir/.installed-lock.json"
  printf '{"example/skills":{"shared-skill":"both","private-skill":"personal"}}\n' >"$root/scopes.json"

  write_agent "$root/agents/realtime/sample-builder.md" "name: sample-builder
description: Use when building a sample.
model: opus
metadata:
  scope: personal"
  write_agent "$root/agents/realtime/sample-off.md" "name: sample-off
description: Use never.
model: haiku
metadata:
  scope: off"
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fixture="$work/repo"
home="$work/home"
spoke="$work/spoke"
mkdir -p "$home" "$spoke"
make_fixture "$fixture"

install_output=$(HOME="$home" SPOKE_DIR="$spoke" "$fixture/install.sh" 2>&1)
install_status=$?
if [ "$install_status" -eq 0 ]; then
  pass "install.sh runs in the fixture"
else
  fail "install.sh runs in the fixture" "$install_output"
fi

missing_steps=""
for step in "Checking prerequisites" "Linking harness files" "Restoring vendored skills" "Linking skills" "Linking agents" "Updating Spoke"; do
  printf '%s\n' "$install_output" | grep -qx "==> $step" || missing_steps="$missing_steps $step;"
done
if [ -z "$missing_steps" ]; then
  pass "install.sh announces each step as it starts"
else
  fail "install.sh announces each step as it starts" "missing:$missing_steps"
fi

git_fixture="$work/git-repo"
make_fixture "$git_fixture"
git -C "$git_fixture" init -q
mkdir -p "$work/git-home"
HOME="$work/git-home" SPOKE_DIR="$work/no-spoke" "$git_fixture/install.sh" >/dev/null 2>&1
if [ "$(git -C "$git_fixture" config --get core.hooksPath)" = ".githooks" ]; then
  pass "install.sh points core.hooksPath at .githooks in a git checkout"
else
  fail "install.sh points core.hooksPath at .githooks in a git checkout" "$(git -C "$git_fixture" config --get core.hooksPath)"
fi

hook_link="$home/.claude/hooks/write-scope.sh"
if [ -L "$hook_link" ] && [ "$(readlink "$hook_link")" = "$fixture/harness/claude/hooks/write-scope.sh" ]; then
  pass "the write-scope hook is linked into ~/.claude/hooks"
else
  fail "the write-scope hook is linked into ~/.claude/hooks" "$(ls -la "$home/.claude/hooks" 2>&1)"
fi

linked_agent="$home/.claude/agents/sample-builder.md"
if [ -L "$linked_agent" ] && [ "$(readlink "$linked_agent")" = "$fixture/agents/realtime/sample-builder.md" ]; then
  pass "a personal agent is linked into ~/.claude/agents"
else
  fail "a personal agent is linked into ~/.claude/agents" "$(ls -la "$home/.claude/agents" 2>&1)"
fi

if [ ! -e "$home/.claude/agents/sample-off.md" ]; then
  pass "an agent scoped off is not linked"
else
  fail "an agent scoped off is not linked"
fi

spoke_entries=$(ls -A "$fixture/dist/spoke" 2>/dev/null)
if [ -d "$fixture/dist/spoke" ] && [ -z "$spoke_entries" ]; then
  pass "dist/spoke gains no entries from agents"
else
  fail "dist/spoke gains no entries from agents" "$spoke_entries"
fi

overrides=$(jq -c '.skillOverrides' "$spoke/.claude/settings.local.json" 2>&1)
if [ "$overrides" = '{"private-skill":"off"}' ]; then
  pass "Spoke switches off only personal skills: no agents, both skills stay on"
else
  fail "Spoke switches off only personal skills: no agents, both skills stay on" "$overrides"
fi

# `check` needs the skill validator on disk; the fixture has no own skills, so a stub does.
validator_dir="$fixture/vendor/robonuggets/skill-creator-plus/.agents/skills/skill-creator-plus/scripts"
mkdir -p "$validator_dir"
echo 'print("stub")' >"$validator_dir/validate_skill.py"

check_output=$(HOME="$home" "$fixture/install.sh" check 2>&1)
if [ $? -eq 0 ]; then
  pass "check passes on agents with name, description, model and scope"
else
  fail "check passes on agents with name, description, model and scope" "$check_output"
fi

for missing_field in name description model; do
  broken="$fixture/agents/realtime/broken.md"
  frontmatter="name: broken
description: Use when broken.
model: opus
metadata:
  scope: personal"
  write_agent "$broken" "$(echo "$frontmatter" | grep -v "^$missing_field:")"
  check_output=$(HOME="$home" "$fixture/install.sh" check 2>&1)
  if [ $? -ne 0 ] && echo "$check_output" | grep -q "$missing_field"; then
    pass "check fails on an agent missing $missing_field"
  else
    fail "check fails on an agent missing $missing_field" "$check_output"
  fi
  rm -f "$broken"
done

# Check is the gate for agent scopes; install skips a spoke agent with the same message.
spoke_agent="$fixture/agents/realtime/spoke-agent.md"
write_agent "$spoke_agent" "name: spoke-agent
description: Use when testing spoke scope.
model: opus
metadata:
  scope: spoke"
scope_message="metadata.scope must be personal, both or off (found 'spoke')"
check_output=$(HOME="$home" "$fixture/install.sh" check 2>&1)
if [ $? -ne 0 ] && echo "$check_output" | grep -qF "$scope_message"; then
  pass "check fails on an agent scoped spoke"
else
  fail "check fails on an agent scoped spoke" "$check_output"
fi
install_output=$(HOME="$home" SPOKE_DIR="$spoke" "$fixture/install.sh" 2>&1)
if [ ! -e "$home/.claude/agents/spoke-agent.md" ] && echo "$install_output" | grep -qF "$scope_message, not linked: spoke-agent"; then
  pass "install skips an agent scoped spoke with the message check gives"
else
  fail "install skips an agent scoped spoke with the message check gives" "$install_output"
fi
rm -f "$spoke_agent"

# The same fixture covers vendor restore: a store directory the lock does not list is deleted, and said so.
unlocked_dir="$fixture/vendor/example/skills/.agents/skills/unlocked-skill"
write_skill "$fixture/vendor/example/skills/.agents/skills" unlocked-skill
install_output=$(HOME="$home" SPOKE_DIR="$spoke" "$fixture/install.sh" 2>&1)
if [ ! -e "$unlocked_dir" ] && echo "$install_output" | grep -qF "removed directory $unlocked_dir (example/skills skill not in its skills-lock.json)"; then
  pass "install deletes a store directory not in the lock and says why"
else
  fail "install deletes a store directory not in the lock and says why" "$install_output"
fi

[ "$failures" -eq 0 ] || exit 1
