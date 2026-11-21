---
name: loop
description: Runs one lab game or experiment from a pitch or brief to a checked, recorded build in the user's own session, with a time or cycle budget, in review or overnight mode. Run by name as /loop.
disable-model-invocation: true
metadata:
  scope: personal
  uses: ideation brief three-build game-feel
---

# Loop

One run, one attempt, one branch. The inner loop is edit, shot, look, check, commit. The Stop hook is the outer loop: it hands you the next direction when you try to stop early. Format of the log and hook: `docs/loop-log.md` in the agent-skills repo.

## Arguments

`/loop <pitch, brief path or idea> [--budget 45m | 8h | 20cycles] [--mode review|overnight] [--lab <path>] [--app <name>]`

Defaults when an argument or an answer is missing (take them, never wait, log each under `## Notes` as `Default: ...`): mode `review`; budget 45 minutes (review) or 8 hours (overnight); lab is the current directory if its root `package.json` is named `lab`, else the `lab` checkout next to it; app name is a kebab-case name taken from the pitch.

## Steps

1. **Settle the input.** A `PITCH.md` or `BRIEF.md` path is used as given. A bare idea goes through `ideation`, then `brief`; unattended (overnight, or nobody answering), run them with every recommended answer, no approval stop, and log each as a default. Done when a `BRIEF.md` with a Next directions list exists.
2. **Make the run branch.** Never work on the default branch. `git worktree add -b loop/<app> <lab-parent>/<lab-dirname>-<app> HEAD` from the lab, then `pnpm install --frozen-lockfile --offline` there (without `--offline` if it fails). Done when `git branch --show-current` in the worktree prints `loop/<app>`.
3. **Scaffold.** `pnpm create-app game|experiment <app>` in the worktree (`three-build` has the rules), copy the brief to `apps/<app>/BRIEF.md`, commit the scaffold. Done when `pnpm check <app>` passes on the untouched template.
4. **Start the log.** Run `scripts/start-run.sh --app-dir <worktree>/apps/<app> --budget <budget> --mode <mode> --title <title>` from the folder your session started in. It fills `LOOP.md` (header, directions from the brief), writes `.loop-active` there (pass `--session-id` when you know the session id) and ignores `.loop-active*`. Commit `LOOP.md` and `.gitignore`. Done when the script prints the log path and `Status: running`.
5. **Run a direction.** Before each one: read the unchecked `## Notes` lines (the user steers there), re-read the brief's pillars and Not this list, and add a Notes line `On track`, `Drifted: ...` or `Brief is wrong: ...`. Then loop until the direction is met:
   - edit; `pnpm shot <app> <seconds...>`, then read the images (a change you have not looked at is not done);
   - `pnpm check <app>`; fix every FAIL;
   - when it is green, commit on the run branch and add one `## Cycles` line: `- <n> <UTC time> <what changed>; check <PASS|FAIL counts>; <minutes used>`.
   When a direction adds a gameplay event, give it a sound and feedback the `game-feel` way. Done when the direction is met and the commit is green; tick it `- [x]`.
6. **Cut and keep.** Two failed tries at one problem: stop, log it under `## Open items` with the symptom, cut the feature or direction and move on. If a later try scores worse than an earlier one (check lines, shot, frame time), `git revert` or restore the earlier version: keep the best, not the latest. Done when no direction is retried a third time.
7. **Let the hook drive.** Each time you stop, the hook may block with the next direction or, when the list is done, a review cycle: take fresh shots, name the three weakest things a player would notice, fix them. Every blocked stop must be followed by tool calls (Claude Code ends the session after 8 consecutive blocked stops with none); never answer a block with prose only. The hook drives only the session this skill runs in. Done when the hook lets you stop: the budget is spent or the log says `Status: done`.
8. **Hand off.** Follow [references/hand-off.md](references/hand-off.md): set `Status: done`, delete `.loop-active` and `.loop-active.state`, run `pnpm verify <app>` and `pnpm record <app>`, write the summary, send the files with SendUserFile and a PushNotification. Done when the notification is sent and the worktree is clean.

## Overnight rules

Overnight mode runs the same loop with a large budget and never decides alone about anything irreversible:

- Never merge, never push, never deploy, never delete a branch or a tag, never force anything.
- Never spend money: no paid API, paid asset or paid service; free, permissively licensed packages only.
- Never read or print `.env*` files or secrets.
- A blocker you cannot fix in two tries is an open item, not a night of retries.
- The result waits on the run branch for the user's review; say so in the summary.

Review mode follows the same no-merge, no-push, no-deploy and no-delete rules unless the user asks for them in this conversation.

## Unattended

No answer arrives. Choose the default, write it as a Notes line, continue. Never ask a question as the last message of a turn; that stop gets the next direction back, not an answer.
