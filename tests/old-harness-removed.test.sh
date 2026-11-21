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
  if [ -d "$REPO_ROOT/agents" ] && find "$REPO_ROOT/agents" -name "$agent.md" | grep -q .; then fail "agent $agent is removed"; else pass "agent $agent is removed"; fi
done
[ ! -e "$REPO_ROOT/harness/claude/hooks/write-scope.sh" ] && pass "the write-scope hook is removed" || fail "the write-scope hook is removed"
if find "$REPO_ROOT/skills" -name 'run_state*' | grep -q .; then fail "the run-state scripts are removed"; else pass "the run-state scripts are removed"; fi
[ "$(jq -r '.["MengTo/Skills"]["workflow-score-to-target"]' "$REPO_ROOT/scopes.json")" = "off" ] && pass "workflow-score-to-target is scoped off" || fail "workflow-score-to-target is scoped off"

# The updated leaf skills teach the slim lab: none names a removed sibling skill, lab module, gate or file.
removed_names='three-verify|art-bible|conduct|polish-director|assetLevel|assetMode": "placeholder|TREATMENT\.md|playtest\.ts|captures\.json|--accept|--trailer|autopilot|__game|zzfx|ZzFX|--level premium'
for skill_dir in skills/realtime/three-build skills/realtime/asset-pipeline skills/game/game-feel; do
  if hits=$(grep -rEn "$removed_names" "$REPO_ROOT/$skill_dir"); then fail "$skill_dir names no removed piece" "$hits"; else pass "$skill_dir names no removed piece"; fi
done

# The docs name no removed skill, agent, hook or file. ADR 0001 is history and is skipped.
removed_doc_names='conductor|/conduct\b|polish-director|polish-worker|visual-judge|feel-judge|motion-judge|asset-wrangler|realtime-judge|motion-review|target-loop|art-bible|three-verify|write-scope|RUN\.md|run_state|COMPONENTS\.md|polish-scope|stop point'
doc_files=$(find "$REPO_ROOT/README.md" "$REPO_ROOT/GLOSSARY.md" "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/docs" -type f \( -name '*.md' -o -name '*.svg' \) ! -path '*/docs/adr/0001-*')
if hits=$(echo "$doc_files" | xargs grep -En "$removed_doc_names"); then fail "the docs name no removed piece" "$hits"; else pass "the docs name no removed piece"; fi

[ "$failures" -eq 0 ] || exit 1
