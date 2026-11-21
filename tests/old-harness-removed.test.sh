#!/bin/bash
# The conductor flow is gone: none of the removed skills, agents, hook or scripts exist.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

removed_skills="conduct realtime-judge motion-review target-loop art-bible three-verify"
removed_agents="conductor polish-director polish-worker visual-judge feel-judge motion-judge asset-wrangler"

for skill in $removed_skills; do
  if find "$REPO_ROOT/skills" -type d -name "$skill" | grep -q .; then fail "skill $skill is removed"; else pass "skill $skill is removed"; fi
done
for agent in $removed_agents; do
  if find "$REPO_ROOT/agents" -name "$agent.md" | grep -q .; then fail "agent $agent is removed"; else pass "agent $agent is removed"; fi
done
[ ! -e "$REPO_ROOT/harness/claude/hooks/write-scope.sh" ] && pass "the write-scope hook is removed" || fail "the write-scope hook is removed"
if find "$REPO_ROOT/skills" -name 'run_state*' | grep -q .; then fail "the run-state scripts are removed"; else pass "the run-state scripts are removed"; fi
[ "$(jq -r '.["MengTo/Skills"]["workflow-score-to-target"]' "$REPO_ROOT/scopes.json")" = "off" ] && pass "workflow-score-to-target is scoped off" || fail "workflow-score-to-target is scoped off"
