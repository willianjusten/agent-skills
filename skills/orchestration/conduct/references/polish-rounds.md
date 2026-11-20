# Polish rounds and autonomous accepts

Read at step 6 of the conductor.

## Per round

1. Run `run_state.py budget`; on a stop, log it and stop. On `reserve:` in `mode=overnight`, end the polish rounds and go to the trailer round (`references/trailer-round.md`) and delivery (see Use the whole budget below). Run `next` and `rows` too, so the user's notes and the row order reach this round, and `checkpoint` for the round's check tier (`references/checkpoints.md`).
2. Create the round branch from the run's branch and append `round-start | N | branch=<round branch> base=<sha of the run's branch>` before spawning, so a cut-off never loses the round.
3. On resume, `read result` means the director already committed on that branch: do not respawn it, read the branch's commits and report, then merge and log the round as below. `redo` means the round left nothing, so spawn the director again on the same branch.
4. Spawn `polish-director` with the Agent tool. Tell it the app's worktree and directory, `COMPONENTS.md` as the checklist, the target id (or, with no target, the art-bible reference image path, or nothing: then no gap score is reported), the process setting, whether it may accept references (below), the round's notes, the `rows` output (the director picks from its `next:` line) the round label `r<N>`, `tier: light` or `tier: checkpoint`, with a scratch folder for the round's notes file, and the regression moment (the name the director reported after round 1, which you log as `step | regression moment: <name>` and pass unchanged to every later round). Wait for its reply.
5. Merge the round branch into the run's branch, then run `pnpm verify <app> --round r<N> --round-notes <notes file>` there (a light round adds `--record-seconds 45` only when it judges motion of real play; a checkpoint round runs the full set from `references/checkpoints.md` here; the director's notes file holds the counted scores and kept flags, `references/evolution-sound.md`) so `.verify/<app>/review-packet.html` in the run's worktree is current: the hand-off links it first.
6. Read the director's report, the packet and the judge scores. Append `round | N | <summary>`, a `judge` line per moment, a `row` line per row the round worked (turn number, the row's counted visual and feel scores with `-` for a side that row does not score, `kept` or `reverted`, `gate=pass|fail` on the `sound` row, the director's written approach) and a `revert` line per rejected component. The director records each reverted try itself (`r<N>-try<K>-reverted`, before the revert), so the Evolution shows it. Append `checks | r<N> | <minutes>` (wall minutes in checks) and, after a checkpoint round, `checkpoint | r<N> | <what ran>`; on a failed checkpoint find and revert the round that caused it (`references/checkpoints.md`). Update the checklist status in `RUN.md`, never by editing `COMPONENTS.md` targets.
7. In `mode=review`, append `stop | round-review | ...` (naming the tier that ran) and end, as `references/run-modes.md` says. In `mode=overnight`, go straight to the next round's budget check.

Continue until a stop point or every component is at target (in `mode=overnight`, see below). When every component is at target, `process=full` goes to step 7 and the other settings to step 8, after any plateau stop that applies.

## Accepting references

The user allows autonomous accepts so a run can go on overnight. Run `run_state.py accepts RUN.md`: while it prints `accepts-since-answer=K of N` with K below N, or `of unlimited` (overnight with no `autoAccepts=N`), tell the director it may run `pnpm verify <app> --accept` this round, under its own conditions. Append one `accept | round N | <capture names> | <why each changed>` line per round it accepted. Before you let the director accept in `mode=overnight`, spawn a reviewer subagent to read the old and new capture of each changed reference side by side and return text; log its verdict in the `accept` line, and without a verdict do not allow the accept. At the limit, do not allow it: a red reference gate is then the stop point "references accepted autonomously", and the hand-off lists every autonomously accepted capture for the user to review.

## Use the whole budget (overnight)

`mode=overnight` polishes until the budget is spent, not until the first plateau.

- **At target** means both counted judges score the row's moment at or above the row's target on the anchored rubric: an absolute score, not the before/after win. `rows` prints `all-at-target=yes` only then; that is the only early delivery.
- **Otherwise** keep running rounds until `budget` prints `reserve:`, then append `step | delivery reserve reached`, run the trailer round (`references/trailer-round.md`) and deliver. Time left is for the next round, so a plateau, a flat round or a round that kept nothing is not a reason to deliver.
- **Flat rounds change approach.** Rows come from the `next:` line: never-worked rows first, then fewest turns, so no row gets a third turn before every row has had one. A row that lost is retried only with a written approach different from every earlier one (the director logs it in the `row` line). A row that lost twice with two different approaches is shrunk to a smaller scope (one moment, one effect) rather than dropped; `rows` names a retry that repeated its approach, which needs a new one first.
- **No plateau stop.** The plateau stop and the "every component at target" stop of `look=ask` do not apply; the stops are a gate failing after two fix attempts and a spent budget.
