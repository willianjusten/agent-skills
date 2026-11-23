# Hand-off

Run in order after the hook lets you stop.

1. **Close the log.** The hook has let you stop (two dry reviews and `Status: done`, budget spent, or the user wrote `Status: stopped`); set `Status: done` if it is not already (leave `stopped` as is); delete `.loop-active` and `.loop-active.state` from the folder the session started in. Add anything left undecided under `## Open items`.
2. **Gates and proof.** From the run worktree: `pnpm check <app>`, `pnpm record <app>`, then `pnpm verify <app>` (record and check first, verify builds its packet from them). A failing gate is fixed or listed as an open item; never edit a threshold to pass. Commit.
3. **Summary.** Write `apps/<app>/.verify/<app>/summary.md` (not committed), at most 40 lines, in this order:
   - **Headline:** one or two sentences on what is ready to play, and whether `check` and `verify` pass.
   - **Play it:** the dev command with `--host` (`pnpm --dir <worktree>/apps/<app> dev --host`), so a phone on the same network can open it, then links on the machine's network address and the port it prints (`http://<address>:<port>/...`; the address is the `Network:` line the server prints, or `ipconfig getifaddr en0`), with the `localhost` form of the start link beside the first. Give the start, `?demo=1`, `?tune`, and one link per moment worth checking, built from the app's own URL parameters and debug controls (read them from its source, for example `?wave=10` for a boss). Mark which ones are test aids.
   - **Controls:** every key, pointer and gamepad action, from the action map (the game itself teaches them in play or on a Controls screen).
   - **Changes:** one line per direction met, from the log, grouped by area when there are many. Say how to reach each one the player can see or hear.
   - **Open items:** copied from `## Open items`, each with its reason. Add what nobody has seen or heard yet, such as audio that was never listened to.
   - **Checks:** the PASS, FAIL and INFO counts from `.verify/<app>/check/results.json`, and the `pnpm verify` verdict with the fps lines.
   - **Run:** the branch, the last commit, start and end time, the number of cycles and dry reviews, and why it ended.
   - **Files:** the absolute paths of `play.mp4`, `play-contact-sheet.png`, `check/ui/screens.png` (every screen on one sheet) and the verify packet, and the run article's URL.
   - **Defaults taken:** the `Default:` Notes lines.
   - **Next:** numbered choices, the recommended one first (for example merge the branch, reopen with new directions, or listen to the audio).
4. **Run article.** Build and publish the frame-per-cycle page with the run's time and cost: [run-article.md](run-article.md).
5. **Send files.** With SendUserFile, in this order: `screens.png` (under `.verify/<app>/check/ui/`), so the user judges every menu at a glance, then `play.mp4`, `play-contact-sheet.png` (both under `.verify/<app>/record/`), then `summary.md`. Start the dev server in the background with `--host` on a free port and print the summary in the chat with the real address and port filled in, the run article's link first.
6. **Notify.** One PushNotification with the one line that matters: the verdict and the first open item, for example `loop/<app> ready: verify PASSED, 2 open items`.
7. **Stop.** Do not merge, push, deploy or delete anything. The branch waits for the user.
