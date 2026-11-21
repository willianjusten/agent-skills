# Skills name siblings through uses

Status: accepted. Supersedes [0001](0001-leaf-and-orchestrator-skills.md).

## Context

0001 banned leaf skills from naming a sibling, because a skill that quietly relied on one broke wherever the sibling was scoped off. It already had the real fix: `metadata.uses` plus `install.sh check`, which turns a missing or out-of-scope dependency into an install error. The ban now costs more than it saves. Nearly every skill is `personal` and installed together, and design knowledge (menus, copy, sound, difficulty) was copied into `brief`, `game-feel`, `three-build` and the loop's UI pass because none of them could point at one home for it.

## Decision

Any skill or agent may name a sibling skill or agent from this repo, as long as it lists it in `metadata.uses`. `install.sh check` fails when:

- a skill names a sibling in backticks (`` `name` ``) without listing it in `uses`;
- a listed dependency is missing, scoped `off`, or scoped narrower than the namer (a `both` skill needs `both` dependencies; a `personal` one cannot use `spoke`).

`skills/orchestration/` stays as the category for skills whose main job is running others, such as `creative-loop`. It no longer grants a permission.

## Consequences

- Shared knowledge lives in one skill and others point at it, instead of each carrying a copy.
- A skill that names a sibling no longer works alone when that sibling is off; `check` makes that visible at install time, not mid-run.
- Upstream (vendored or third-party) skills are still named as "if installed" with a one-line fallback; `uses` covers only this repo.
