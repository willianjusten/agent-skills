# Hand-off

Run in order after the hook lets you stop.

1. **Close the log.** The hook has let you stop (two dry reviews and `Status: done`, budget spent, or the user wrote `Status: stopped`); set `Status: done` if it is not already (leave `stopped` as is); delete `.loop-active` and `.loop-active.state` from the folder the session started in. Add anything left undecided under `## Open items`.
2. **Gates and proof.** From the run folder, the adapter's `check` and `checkSlow`, `record`, then `verify` (lab: `pnpm check <app>`, `pnpm record <app>`, then `pnpm verify <app>`; record and check first, verify builds its packet from them). A failing gate is fixed or listed as an open item; never edit a threshold to pass. Commit.
3. **Summary.** Write `<out>/summary.md` (lab: `.verify/<app>/summary.md` at the worktree root; not committed), at most 40 lines, in this order:
   - **Headline:** one or two sentences on what is ready to play, and whether `check` and `verify` pass.
   - **Play it:** the adapter's `dev` command with `--host` or its equivalent (lab: `pnpm --dir <worktree>/apps/<category>/<app> dev --host`), so a phone on the same network can open it, then links on the machine's network address and the port it prints (`http://<address>:<port>/...`; the address is the `Network:` line the server prints, or `ipconfig getifaddr en0`), with the `localhost` form of the start link beside the first. Give the start, `?demo=1`, `?tune` (when the piece has them), and one link per moment worth checking, built from the app's own URL parameters and debug controls (read them from its source, for example `?wave=10` for a boss). Mark which ones are test aids.
   - **Controls** (game and experiment profiles): every key, pointer and gamepad action, from the action map (the game itself teaches them in play or on a Controls screen).
   - **Changes:** one line per direction met, from the log, grouped by area when there are many. Say how to reach each one the player can see or hear.
   - **Open items:** copied from `## Open items`, each with its reason. Add what nobody has seen or heard yet, such as audio that was never listened to.
   - **Checks:** the PASS, FAIL and INFO counts from the check output (lab: `.verify/<app>/check/results.json`), and the `verify` verdict with its frame-time lines.
   - **Run:** the branch, the last commit, start and end time, the number of cycles and dry reviews, and why it ended.
   - **Files:** the absolute paths of the video and contact sheet `record` printed (lab: `play.mp4`, `play-contact-sheet.png`), the screens sheet (lab: `check/ui/screens.png`, every screen on one sheet), the verify output, and the run article's URL.
   - **Defaults taken:** the `Default:` Notes lines.
   - **Next:** numbered choices, the recommended one first (for example merge the branch, reopen with new directions, or listen to the audio).
4. **Run article.** Build and publish the frame-per-cycle page with the run's time and cost: [run-article.md](run-article.md).
5. **Send files.** With SendUserFile, in this order: the screens sheet (lab: `screens.png` under `.verify/<app>/check/ui/`), so the user judges every screen at a glance, then the video and contact sheet (lab: `play.mp4`, `play-contact-sheet.png` under `.verify/<app>/record/`), then `summary.md`. Start the dev server in the background with `--host` on a free port, or reuse the one running, and print the summary in the chat with the real address and port filled in, the run article's link first.
6. **Notify.** One PushNotification with the one line that matters: the verdict and the first open item, for example `loop/<app> ready: verify PASSED, 2 open items` (the run branch's name).
7. **Stop.** Do not merge, push, deploy or delete anything. The branch waits for the user.
