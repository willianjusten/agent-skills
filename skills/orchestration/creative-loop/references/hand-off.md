# Hand-off

Run in order after the hook lets you stop.

1. **Close the log.** The hook has let you stop (two dry reviews and `Status: done`, budget spent, or the user wrote `Status: stopped`); set `Status: done` if it is not already (leave `stopped` as is); delete `.loop-active` and `.loop-active.state` from the folder the session started in. Add anything left undecided under `## Open items`.
2. **Gates and proof.** From the run worktree: `pnpm check <app>`, `pnpm record <app>`, then `pnpm verify <app>` (record and check first, verify builds its packet from them). A failing gate is fixed or listed as an open item; never edit a threshold to pass. Commit.
3. **Summary.** Write `apps/<app>/.verify/<app>/summary.md` (not committed), at most 40 lines, in this order:
   - **Headline:** one or two sentences on what is ready to play, and whether `check` and `verify` pass.
   - **Play it:** the dev command (`pnpm --dir <worktree>/apps/<app> dev`), then links relative to the port it prints (`http://localhost:<port>/...`). Give the start, `?demo=1`, `?tune`, and one link per moment worth checking, built from the app's own URL parameters and debug controls (read them from its source, for example `?wave=10` for a boss). Mark which ones are test aids.
   - **Controls:** the control lines the title shows.
   - **Changes:** one line per direction met, from the log, grouped by area when there are many. Say how to reach each one the player can see or hear.
   - **Open items:** copied from `## Open items`, each with its reason. Add what nobody has seen or heard yet, such as audio that was never listened to.
   - **Checks:** the PASS, FAIL and INFO counts from `.verify/<app>/check/results.json`, and the `pnpm verify` verdict with the fps lines.
   - **Run:** the branch, the last commit, start and end time, the number of cycles and dry reviews, and why it ended.
   - **Files:** the absolute paths of `play.mp4`, `play-contact-sheet.png` and the verify packet.
   - **Defaults taken:** the `Default:` Notes lines.
   - **Next:** numbered choices, the recommended one first (for example merge the branch, reopen with new directions, or listen to the audio).
4. **Send files.** With SendUserFile, in this order: `play.mp4`, `play-contact-sheet.png` (both under `.verify/<app>/record/`), then `summary.md`. Start the dev server in the background on a free port and print the summary in the chat with that real port filled in.
5. **Notify.** One PushNotification with the one line that matters: the verdict and the first open item, for example `loop/<app> ready: verify PASSED, 2 open items`.
6. **Stop.** Do not merge, push, deploy or delete anything. The branch waits for the user.
