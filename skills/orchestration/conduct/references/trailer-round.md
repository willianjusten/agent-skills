# Trailer round

Read at step 7b of the conductor. The trailer is the app's directed shot list (`src/trailer.ts`: cameras, shot order, a final reveal), played by `?autopilot=1` and recorded by `pnpm verify <app> --trailer`. This round judges and directs it like any other round. It runs inside the delivery reserve, so it is the last work before delivery, and it is not a numbered polish round: it never counts against `rounds=N`.

## When it runs

- `mode=overnight`: once `budget` prints `reserve:`, or earlier when `rows` prints `all-at-target=yes`.
- `mode=review`: offered at the last round. The last `stop | round-review` hand-off adds the choice "run the trailer round" before delivery; the answer `trailer` runs it, any other answer goes to delivery.
- Skipped, with `step | trailer round skipped: <reason>`, when `app.json` declares no `trailer`, or when the reserve left is under 15 minutes.

## Steps

1. Declare the row once: `row | trailer | turn 0 | score -/- of target <T> | pending | approach: none` (it scores motion only: later turns read `score <V>/-`), with the target from `COMPONENTS.md` (default: both counted motion scores at or above the other rows' target).
2. **Record.** `pnpm verify <app> --trailer --round trailer-baseline` (one run: it records into `.verify/<app>/trailer/` and snapshots the round): `play.mp4` and `play-contact-sheet.png`, one tile per second. Recordings of one app repeat closely but not byte for byte; the trailer is for presenting, judged on its direction, never used as a test or reference. Done when the sheet exists.
3. **Judge the baseline, blind.** Cut a before/after strip and burst from `play.mp4` (60 fps, frame at time t is ffmpeg `-ss t`) and follow `motion-review` with a `motion-judge`: each shot's contact-sheet tiles, plus a burst across every cut and the final reveal. `--motion --from-recording` reads only the play recording, not the trailer. Ask the judge for absolute scores against the row's target, and note per shot what is wrong (a cut that jumps, a shot that shows empty sky, a reveal that starts late).
4. **Direct.** Edit the shot list in the app's `src/trailer.ts` (shot kinds `chase`, `side`, `orbit`, `flyby`, `wide`, `reveal`; `blendSeconds` for an eased cut; the lengths add up to `trailer.seconds` in `app.json`) to fix the worst shot first. Work in the round's worktree, one change at a time, checking it with `pnpm shot` at the shot times (`three-verify` step 6, with the trailer's query; about 3 s) instead of a full recording. Keep at least three shot kinds. Done when the shots show the change.
5. **Record, judge, decide.** Record again (`--trailer --round trailer-t1`), judge blind as in step 3, and keep the change on a win or tie of the counted motion score, revert it otherwise (a reverted try is still recorded with `--round trailer-t1-reverted` before the revert). At most three tries; two in a row that do not improve it end the round.
6. Append `row | trailer | turn N | score <V>/<F> of target <T> | kept|reverted | approach: <text>` (V is the counted motion score, F is `-`: `rows` counts the lone number), plus `judge` and `revert` lines as in a polish round. Run `pnpm check` and `pnpm verify <app>` (the trailer change must not move any reference capture; never accept one here). Done when the last kept recording is the one in `.verify/<app>/trailer/` and the lines are written.

The packet's "Trailer" section and the `evolution.html` timeline show the recording; the hand-off links both, plus the `play.mp4` path.
