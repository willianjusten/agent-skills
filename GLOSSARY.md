# Glossary

Terms used across the skills and harness in this repo.

- **Leaf skill**: a skill that works alone and names no sibling skill in this repo. Most skills are leaves.
- **Orchestrator**: a skill in `skills/orchestration/` (or an agent in `agents/`) that runs other skills. It may name them; `install.sh check` verifies each one is installed where the orchestrator can see it. See `docs/adr/0001-leaf-and-orchestrator-skills.md`.
- **Pitch**: the one-page concept that ends ideation and that Will approves.
- **Brief**: the one-page `BRIEF.md` written from the pitch: promise, Not this, features with checks, demo mode and the ordered Next directions list.
- **Loop**: one `/creative-loop` run on one app, from a pitch or brief to a checked, recorded build, on its own branch and in the user's session. See `docs/adr/0002-thin-loop.md`.
- **Inner loop**: edit, shot, look, check, commit. Takes minutes and ends with one `## Cycles` line.
- **Outer loop**: the Stop hook. Each time the agent tries to stop before the run is finished, it hands back the next direction or a review cycle. The run is finished after two dry reviews in a row with every direction checked, or when the budget is spent.
- **Direction**: one line of the brief's Next directions list, copied into the log as `- [ ]` and ticked when met.
- **Attempt**: one of two or three parallel builds of the same brief (`--attempts`), each on its own branch and worktree. The user picks one.
- **Check**: a script that passes or fails (`pnpm check <app>`); the only guardrail inside the loop. No model judges taste.
- **Demo mode**: what an app does with no input (`?demo=1`), so a recorder sees a full loop.
- **Hand-off**: the end of a run: log closed, `pnpm check`, `pnpm record`, `pnpm verify`, `summary.md`, files and a notification sent. Nothing is merged or pushed.
- **Loop log**: the app's `LOOP.md`: header, `## Directions`, `## Cycles`, `## Notes` and `## Open items`. Read by the Stop hook. Format in `skills/orchestration/creative-loop/references/loop-log.md`.
- **Budget**: the ceiling of a run, in minutes, hours or cycles. The hook lets the agent stop when it is spent, but a run normally ends earlier, on two dry reviews.
- **Dry review**: a review cycle that found nothing short of the brief and no idea worth doing, logged `- <n> <time> review: dry, ...`.
