# Checkpoints

Read at step 4 (baseline), step 6 (every round) and step 8 of the conductor. Checks earn their time at a few rigorous points, not every round: the run spends its hours on coding and improving the app, and the middle rounds stay light. Never put a time cap on a round or a worker; make the checks lighter instead.

## Tiers

| Tier | When | Commands |
| ---- | ---- | -------- |
| Between edits | while coding | `pnpm shot <app> <t...>` only |
| Light | every round | `pnpm check`, one `pnpm verify <app> --round <label> --round-notes <file>` per try, and the judges. No `--layer-cost`, no `--record-seconds 45` (unless the round judges motion of real play: combat or a moving effect), no `--no-webgpu`, no e2e suites, no `--uncapped` |
| Checkpoint | see below | `pnpm verify <app> --layer-cost --record-seconds 45`, `--no-webgpu` when shaders changed since the last checkpoint, the e2e suites (`pnpm test:e2e:fast`, `pnpm test:e2e:slow`) when `packages/` or `templates/` changed since the last checkpoint, the 1080p check where the pitch asks for one, and a read of every reference capture (through a subagent that returns text) |

A light round that changed a layer's files adds `--layer-cost`: the layer cost reuses its stored report while the build is unchanged, so this is cheap.

## When a checkpoint runs

The baseline, every third polish round, the round before the trailer round, and delivery. `python3 -I <conduct skill dir>/scripts/run_state.py checkpoint RUN.md` prints `checkpoint-due` or `light` for the next round: run it at the round boundary, after `budget`. Tell the director the tier as `tier: light|checkpoint`. After a checkpoint, append `checkpoint | <round label> | <what ran>`. In `mode=review` a round is light unless due, and the hand-off says which tier ran.

## A checkpoint that fails

Each round is a merge on the run's branch. Find the round since the last checkpoint that caused the failure: re-run the failing check at the round merges, newest first, until it passes. Revert that round's merge, append a `revert` line naming the check and the round, and continue. The light rounds trade earlier detection for speed; this is the recovery. A gate still failing after two fix attempts stays a stop point.

## Check time against work time

After each round append `checks | <round label> | <minutes>`: the wall minutes spent in checks (verify, `pnpm check`, e2e, the judges' capture runs). `run_state.py checks RUN.md` prints `checks=<M>m run=<R>m share=<P>%`. When it adds a `lighter:` line (checks took more than half of the last round), the next light round drops a flag or a step from its set (`--record-seconds`, then one verify per try instead of per edit batch), says which in a `step` line, and the hand-off notes it. This never limits the round's work. The hand-off and the review packet's hand-off line report the share.
