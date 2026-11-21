# Hand-off

Run in order after the hook lets you stop.

1. **Close the log.** Set `Status: done`; delete `.loop-active` and `.loop-active.state` from the folder the session started in. Add anything left undecided under `## Open items`.
2. **Gates and proof.** From the run worktree: `pnpm check <app>`, `pnpm record <app>`, then `pnpm verify <app>` (record and check first, verify builds its packet from them). A failing gate is fixed or listed as an open item; never edit a threshold to pass. Commit.
3. **Summary.** Write `apps/<app>/.verify/<app>/summary.md` (not committed), at most 25 lines:
   - the branch and the last commit;
   - Changes: one line per direction met, from the log;
   - Open items: copied from `## Open items`, each with the reason;
   - Check results: counts of PASS, FAIL and INFO from `.verify/<app>/check/results.json`, and the `pnpm verify` verdict;
   - Defaults taken: the `Default:` Notes lines.
4. **Send files.** With SendUserFile, in this order: `play.mp4`, `play-contact-sheet.png` (both under `.verify/<app>/record/`), then `summary.md`.
5. **Notify.** One PushNotification with the one line that matters: the verdict and the first open item, for example `loop/<app> ready: verify PASSED, 2 open items`.
6. **Stop.** Do not merge, push, deploy or delete anything. The branch waits for the user.
