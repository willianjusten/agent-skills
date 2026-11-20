# Hand-off

Read at a stop or at `done`, before returning.

Your final result is a short message the user reads in the chat to play and check the build; the review packet holds the detail, so do not repeat it and do not write a file. In order, briefly:

1. **Headline.** One or two sentences: what is ready to play, which round, and whether every gate passes.
2. **Play it.** The dev command (`pnpm --dir <app dir> dev`), then links relative to the port it prints: the start, and one per moment worth checking, built from the game's debug controls (for example `?startWave=6&loadout=...`), plus `?tune` for the panel. The caller starts the server and fills in the port.
3. **What changed.** One line per change the player can see or hear, with how to reach it.
4. **Known problems.** What the round did not fix, and anything nobody has seen or heard yet.
5. **Checks.** One line: gates pass or which fail, and the judge result. Then the check share from `run_state.py checks RUN.md` (for example `Checks: 38m of 3h 30m, 18%`), and in `mode=review` the tier that ran. Then the phase timing from `run_state.py phases RUN.md`, one line (for example `Phase timing: brief 30m, first-playable 2h, polish 1h; total 3h 30m`).
6. **Review packet.** Its absolute path, then the absolute path of `.verify/<app>/evolution.html` (every moment's stills across rounds, plus the trailer per round), and the trailer's `play.mp4` when a trailer was recorded.
7. **Next.** Numbered choices, the recommended one first; for a decision, the exact `answer` line to append to `RUN.md`.
