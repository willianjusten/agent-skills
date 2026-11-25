---
name: creative-loop
description: Runs one lab game or experiment from a pitch or brief to a checked, recorded build in the user's own session, with a time or cycle budget, in review or overnight mode. Run by name as /creative-loop.
disable-model-invocation: true
metadata:
  scope: personal
  uses: ideation brief three-build game-feel game-design ui-polish
---

# Creative Loop

One run, one attempt, one branch. The inner loop is edit, shot, look, check, commit. The Stop hook is the outer loop: it hands you the next direction when you try to stop early. Format of the log and hook: [references/loop-log.md](references/loop-log.md).

## Arguments

`/creative-loop <pitch, brief path or idea> [--budget 45m | 8h | 20cycles] [--mode review|overnight] [--attempts 1..3] [--lab <path>] [--app <name>]`

Defaults when an argument or an answer is missing (take them, never wait, log each under `## Notes` as `Default: ...`): mode `review`; budget 45 minutes (review) or 8 hours (overnight); lab is the current directory if its root `package.json` is named `lab`, else the `lab` checkout next to it; app name is a kebab-case name taken from the pitch.

## Steps

1. **Settle the input.** A `PITCH.md` or `BRIEF.md` path is used as given. A bare idea goes through `ideation`, then `brief`; unattended (overnight, or nobody answering), run them with every recommended answer, no approval stop, and log each as a default. Done when a `BRIEF.md` with a Next directions list exists.
2. **Make the run branch.** Never work on the default branch. `git worktree add -b loop/<app> <lab-parent>/<lab-dirname>-<app> HEAD` from the lab, then `pnpm install --frozen-lockfile --offline` there (without `--offline` if it fails). Done when `git branch --show-current` in the worktree prints `loop/<app>`.
3. **Scaffold.** `pnpm create-app game|experiment <app>` in the worktree (`three-build` has the rules), copy the brief to `apps/<category>/<app>/BRIEF.md` (`games` or `experiments`), commit the scaffold. Done when `pnpm check <app>` passes on the untouched template.
4. **Start the log.** Run `scripts/start-run.sh --app-dir <worktree>/apps/<category>/<app> --budget <budget> --mode <mode> --title <title>` from the folder your session started in. It fills `LOOP.md` (header, directions from the brief), writes `.loop-active` there (it takes the session id from `--session-id` or `$CLAUDE_SESSION_ID`; with neither, the hook binds the marker to your session at the first stop) and ignores `.loop-active*`. Commit `LOOP.md` and `.gitignore`. Done when the script prints the log path and `Status: running`.
5. **Run a direction.** Before each one: read the unchecked `## Notes` lines (the user steers there), re-read the brief's pillars and Not this list, and add a Notes line `On track`, `Drifted: ...` or `Brief is wrong: ...`. Then loop until the direction is met:
   - edit; `pnpm shot <app> <seconds...>`, then read the images (a change you have not looked at is not done);
   - `pnpm check <app>`; fix every FAIL;
   - when it is green, commit on the run branch and add one `## Cycles` line: `- <n> <UTC time> <what changed>; check <PASS|FAIL counts>; <minutes used>`.
   - save the cycle's frame for the run article ([references/run-article.md](references/run-article.md), Frames).
   When a direction adds a gameplay event, give it a sound and feedback the `game-feel` way. When it adds something the player sees, name in its cycle line the screen it lives on and what it moved behind a button to make room; a screen only grows when something else leaves it. Done when the direction is met and the commit is green; tick it `- [x]`.
6. **Cut and keep.** Two failed tries at one problem: stop, log it under `## Open items` with the symptom, cut the feature or direction and move on. If a later try scores worse than an earlier one (check lines, shot, frame time), `git revert` or restore the earlier version: keep the best, not the latest. Done when no direction is retried a third time.
7. **Let the hook drive.** Each time you stop, the hook may block with the next direction or, when the list is done, a review cycle: take fresh shots, check them in the order of `game-design` "Reviewing a build" (each finding names its rule), name the three weakest things a player would notice and one thing to remove or simplify (a feature, option, screen element or HUD group that costs more attention than it gives), fix them, and run the UI pass ([references/ui-pass.md](references/ui-pass.md)): read `.verify/<app>/check/ui/screens.png` (every screen on one sheet) and the shots behind it, fix every `ui layout` FAIL, and hold each screen to `game-design` `references/ui-ux.md`. Every blocked stop must be followed by tool calls (Claude Code ends the session after 8 consecutive blocked stops with none); never answer a block with prose only. The hook drives only the session this skill runs in. The list, not the clock, decides the end: when it is finished, run review cycles against the brief and every direction so far, and list new ideas for the piece, removals and simplifications among them, not only additions; each finding or idea worth doing becomes a new unchecked direction. A review that finds nothing and no idea worth doing is logged as a dry review (`review: dry`, with what was checked and the ideas rejected; format in the loop log reference). After two dry reviews in a row with every direction checked, set `Status: done`; the hook then lets you stop (set earlier, it is ignored while budget remains). The budget is a ceiling, and `Status: stopped` is the user's early exit (they write it, or you do when they ask in the conversation). Done when the hook lets you stop: two dry reviews and `Status: done`, the budget is spent, or the user wrote `Status: stopped`.
8. **Hand off.** Follow [references/hand-off.md](references/hand-off.md): set `Status: done` if it is not already (it is after two dry reviews, and you set it now when the budget ran out; leave `stopped` as is), delete `.loop-active` and `.loop-active.state`, run `pnpm verify <app>` and `pnpm record <app>`, write the summary, publish the run article, send the files with SendUserFile and a PushNotification. Done when the notification is sent and the worktree is clean.

## Attempts mode

`--attempts 2` or `--attempts 3` runs that many parallel attempts of the same brief and lets the user pick one; the default and `--attempts 1` is the single run above. Any other value is refused. Steps 1 and 3 run once (one `BRIEF.md`); everything else is per attempt. Follow [references/attempts.md](references/attempts.md) for the procedure. In short:

- `scripts/plan-attempts.sh --lab <lab> --app <app> --attempts <n>` prints one line per attempt with its branch `loop/<app>-<run-id>-<letter>` and worktree `<lab-dir>-<app>-<run-id>-<letter>`. The run id and the letter keep names unique across attempts and across runs; the script refuses a name that exists. Create worktrees only from its output.
- One background subagent per attempt, same brief, own worktree. This session is the outer loop for each attempt: the Stop hook does not drive subagents, so no `.loop-active` marker is written (`start-run.sh --attempts <n> --no-marker`), and when an attempt reports early you send it the next direction from its own `LOOP.md` until its budget is spent.
- One status line per report: `attempt <letter>: <direction or cycle>, check <PASS|FAIL counts>, <minutes used> of <budget>`.
- When every attempt is done, `pnpm record <path-a> <path-b> [<path-c>]` writes the stacked video; send it and wait for the pick.
- Review mode: the user picks in the conversation. Overnight mode: every attempt runs to its full budget and the pick waits for morning; send the stacked video and the summaries, then stop. Never pick for the user, never merge, never delete the other attempts' worktrees or branches.
- After the pick, continue from the picked attempt alone: steps 5 to 8 in its worktree with the Stop hook driving as in a single run (step 4 again, with the marker). The other attempts stay as they are.

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
