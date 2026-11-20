# Polish rounds and autonomous accepts

Read at step 6 of the conductor.

## Per round

1. Run `run_state.py budget`; on a stop, log it and stop. Run `next` too, so notes the user added reach this round.
2. Create the round branch from the run's branch and append `round-start | N | branch=<round branch> base=<sha of the run's branch>` before spawning, so a cut-off never loses the round.
3. On resume, `read result` means the director already committed on that branch: do not respawn it, read the branch's commits and report, then merge and log the round as below. `redo` means the round left nothing, so spawn the director again on the same branch.
4. Spawn `polish-director` with the Agent tool. Tell it the app's worktree and directory, `COMPONENTS.md` as the checklist, the target id (or, with no target, the chosen look's benchmark path), the process setting, whether it may accept references (below), the round's notes and the regression moment (the name the director reported after round 1, which you log as `step | regression moment: <name>` and pass unchanged to every later round). Wait for its reply.
5. Merge the round branch into the run's branch, then run `pnpm verify <app>` there (add `--record-seconds 45` for the play recording the packet shows) so `.verify/<app>/review-packet.html` in the run's worktree is current: the hand-off links it first.
6. Read the director's report, the packet and the judge scores. Append `round | N | <summary>`, a `judge` line per moment and a `revert` line per rejected component. Update the checklist status in `RUN.md`, never by editing `COMPONENTS.md` targets.
7. In `mode=review`, append `stop | round-review | ...` and end, as `references/run-modes.md` says. In `mode=overnight`, go straight to the next round's budget check.

Continue until a stop point or every component is at target. When every component is at target, `process=full` goes to step 7 and the other settings to step 8, after any plateau stop that applies.

## Accepting references

The user allows autonomous accepts so a run can go on overnight. Run `run_state.py accepts RUN.md`: while it prints `accepts-since-answer=K of N` with K below N, or `of unlimited` (overnight with no `autoAccepts=N`), tell the director it may run `pnpm verify <app> --accept` this round, under its own conditions. Append one `accept | round N | <capture names> | <why each changed>` line per round it accepted. Before you let the director accept in `mode=overnight`, spawn a reviewer subagent to read the old and new capture of each changed reference side by side and return text; log its verdict in the `accept` line, and without a verdict do not allow the accept. At the limit, do not allow it: a red reference gate is then the stop point "references accepted autonomously", and the hand-off lists every autonomously accepted capture for the user to review.
