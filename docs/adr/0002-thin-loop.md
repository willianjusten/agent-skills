# The thin loop

Status: accepted. Builds on [0001](0001-leaf-and-orchestrator-skills.md): the leaf and orchestrator rule stays.

## Context

The first creative harness ran a whole build in the background through nested agents, with blind model judges scoring polish rounds. Tests showed it was invisible (the terminal showed nothing for hours), fragile (sittings ended mid-round, agents wrote to the same worktree, gates failed for reasons outside the app) and beaten by a plain single agent: one prompt, a screenshot tool and no harness built a game the user preferred in 29 minutes, three parallel plain attempts each finished a complete game in 45 minutes or less, and one agent inside the lab matched the best of them in 23.

## Decision

1. **One agent, your own session.** `creative-loop` runs in the session you started, so every step is visible and steerable through the `## Notes` of the loop log. It is an orchestrator that runs `ideation`, `brief`, `three-build` and `game-feel`.
2. **Inner and outer loop.** The inner loop is edit, shot, look, check, commit. The outer loop is the Stop hook: when the agent tries to stop before its budget is spent, the hook blocks and hands back the next direction from the log. The hook only reads a file and fails open, so it is a no-op for every session without a `.loop-active` marker.
3. **No model taste judges.** Guardrails are scripts that pass or fail (`pnpm check` in the loop, `pnpm verify` at delivery). Taste is judged by the user from the recorded video. Two blind judge panels disagreed with the user twice; a judge may not decide taste. This is the rule that guards the decision.
4. **Parallel attempts are optional.** Two or three independent builds of one brief, picked by the user from a stacked video. The user's pick is never delegated.
5. **Overnight is the same loop.** A larger budget plus rules: no merge, push, deploy, deletion or spending.

## Consequences

- Removed: the background multi-agent run flow, its run log and stop points, polish rounds, the judge agents and the per-worker write hook. The `agents/` folder is empty and stays supported by `install.sh`.
- The loop log (`LOOP.md`) is the only run state; see `docs/loop-log.md`.
- The budget is enforced by one small hook instead of by prompt discipline, which is what made the old flow stop early.
- Claude Code ends a session after 8 consecutive blocked stops without a tool call, so the skill requires tool calls after every block.
