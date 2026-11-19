# How the creative flow works

From a spark of an idea to a judged build, with Will approving only taste. Everything after the approved pitch runs on its own and stops only at a stop point.

```mermaid
flowchart TD
  I[ideation] --> P[/PITCH.md, Approved by/]
  P --> C["/conduct (starts the conductor)"]
  C --> B[brief: game-brief or creative-brief]
  B --> A[art-bible, signed on your behalf]
  A --> T[first playable, then target-loop]
  T --> S1{{Stop 1: you approve a target}}
  S1 --> K[COMPONENTS.md checklist]
  K --> R[polish round: polish-director]
  R --> J[blind judges]
  J -->|components short of target| R
  J --> RJ[reference judge vs target]
  RJ --> D[delivery: DECISIONS.md, done]
```

## The phases

| Phase | Who runs it | Output |
| ----- | ----------- | ------ |
| Ideation | `ideation` skill, with you | `PITCH.md` with an `Approved by` line |
| Start | `/conduct <pitch or app folder>` | the conductor in the background |
| Brief | conductor, via `game-brief` (game) or `creative-brief` (piece) | `GDD.md` or `TREATMENT.md`, "Not this" list |
| Art bible | conductor, via `art-bible` | palette and asset levels (`placeholder` or `free`; `premium` stays locked) |
| Target | conductor builds the first look with `three-build` and `three-verify`, then `target-loop` | captures and a prepared target; stop 1 |
| Checklist | conductor | `COMPONENTS.md`: target, folder and judge lens per component |
| Polish rounds | `polish-director` per round | workers change components in worktrees, `pnpm verify <app> --layer-cost`, blind judges, review packet |
| Reference judge | conductor, `realtime-judge` | 12 trials against the target; 7 or fewer correct passes |
| Delivery | conductor | `pnpm check`, `pnpm verify`, `DECISIONS.md`, `done` in `RUN.md` |

## Leaf versus orchestrator

A **leaf** skill works alone and names no sibling (`three-verify`, `art-bible`, `target-loop`). An **orchestrator** is an agent in `agents/` or a skill in `skills/orchestration/` and may name and run others. `./install.sh check` fails when an orchestrator names a skill or agent that is missing or scoped where it cannot see it. Why: [ADR 0001](adr/0001-leaf-and-orchestrator-skills.md).

## Nesting depth

```text
main thread (/conduct, returns at once)
  conductor                  level 1, background
    polish-director          level 2
      polish-worker, visual-judge, feel-judge, motion-judge, merger   level 3
```

Three levels is the limit. A level-3 agent never spawns. The conductor runs the reference judges itself (level 2). A director run directly from the main thread has the same workers and judges one level shallower.

## Stop points, budgets, RUN.md

The conductor never asks a question mid-run. Every call it makes instead is logged as an `assumption`. It stops, notifies you and ends at:

- target frames chosen (always)
- polish plateau (judges flat two rounds, or every component at target)
- a judge split on a taste call
- a gate still failing after two fix attempts
- a spent budget: 6 polish rounds or 6 hours of active run time, where waiting for an answer is free; override with `rounds=N hours=H` on `/conduct`
- any stop the brief adds

To answer a stop, append `- <UTC timestamp> | answer | <text>` to the app's `RUN.md` and run `/conduct <app>` again.

`RUN.md` lives in the app folder, is committed and append-only. Each line is `- <UTC timestamp> | <kind> | <text>`; kinds are `start`, `step`, `assumption`, `judge`, `revert`, `round`, `stop`, `answer`, `resume`, `budget`, `note` and `done`. `run_state.py` (in `skills/orchestration/conduct/scripts/`) reads it:

```bash
python3 -I skills/orchestration/conduct/scripts/run_state.py next <app>/RUN.md     # start, done, waiting, resume or continue
python3 -I skills/orchestration/conduct/scripts/run_state.py budget <app>/RUN.md   # ok, or stop: ... with exit 3
python3 -I skills/orchestration/conduct/scripts/run_state.py lock status <app>/RUN.md
```

**The lock.** One conductor per app: it takes `RUN.md.lock` first (`lock acquire --owner <id>`), refreshes it at each phase end and releases it before writing `stop` or `done`. A second start gets exit 4 and ends. A lock unrefreshed for 2 hours is stale and can be taken over. The lock is never committed.

## What never happens

Nobody but you approves a target, loosens a gate, edits `assets.manifest.json` or `targets/`, merges into the default branch or pushes. Judges are advisory; `verify` gates are the hard checks. Run limits and permissions options: see `.scratch/lab-platform/conductor-launch-options.md` (local notes, not committed).
