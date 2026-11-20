---
name: conduct
description: Starts the conductor in the background on an approved pitch or on an app with a RUN.md. Run it by name as /conduct followed by a pitch file or an app folder.
disable-model-invocation: true
metadata:
  scope: personal
  uses: conductor
---

# Conduct

Starts one autonomous run and returns at once. The `conductor` agent does the work and writes `RUN.md` in the app folder.

## Steps

1. **Resolve the target.** Resolve the argument to an absolute path against the current directory. If the path does not exist, say so and stop. The argument is a pitch file (`PITCH.md`) or an app folder.
   - A pitch file needs an `Approved by` line with a name after it; a missing or empty line means it is not ready, so say so and stop. A pitch is always a start.
   - An app folder needs a `RUN.md`; one without it is not a run, so say so and stop (a new run starts from a pitch file). Run `python3 -I <skill dir>/scripts/run_state.py next <app>/RUN.md` (a mistyped path exits 2 with a message rather than reading as a new run). Output `done`: say so and stop. `waiting: <stop>`: the user has not answered, so show the stop's line from `RUN.md` and ask them to append `- <UTC timestamp> | answer | <text>` to it, then stop. `resume: ...` or `continue: ...`: it is a resume.

   Then check the run lock: for an app folder, `python3 -I <skill dir>/scripts/run_state.py lock status <app>/RUN.md`. Exit 4 means a conductor holds it (the output names the owner and start): say so and stop, because a second conductor on one app overwrites `RUN.md`. A lock older than 2 hours reads as stale and does not block. For a pitch file, the conductor takes the lock itself once the app folder exists.

   Done when the target is one of start, resume, and no live lock holds it.
2. **Collect overrides.** Read any extra stop points or budgets in the request (`rounds=N`, `hours=H`, `process=minimal|standard|full`, `look=auto`, `target=yes`, `mode=overnight|review`, `autoAccepts=N`, "also stop after ...") and pass them through as given, without explaining them: the conductor owns what each one means and applies its defaults (6 polish rounds, 6 hours of active run time), and `RUN.md` keeps earlier overrides, so pass only what the request names. Turn run-mode phrasing into the mode: "overnight for 6h" or "while I sleep" is `mode=overnight hours=6`; "call me each round" or "ask me after each round" is `mode=review`; name neither and the conductor uses `review`. Done when the overrides are listed, or none.
3. **Start it in the background.** Run from the lab repo (the git root of the target, `git -C <target dir> rev-parse --show-toplevel`; if the target is in no git repo, say a run needs the lab repo and stop). Spawn the `conductor` agent with the Agent tool and `run_in_background: true`, prompt:

   ```text
   <start|resume>: <absolute target path>. <overrides>
   ```

   The path is the pitch file for a start and the app folder for a resume; leave `<overrides>` out when there are none. The conductor reads the stop and answer from `RUN.md` itself. It runs as level 1 and spawns `polish-director` (level 2), which spawns workers and judges (level 3); nothing deeper. Done when the agent is running. If it ends within seconds, read its result, fix the cause and return to step 1; do not report a run that never started.
4. **Tell the user.** One line: the target path (the app folder for a resume; for a start the conductor creates it, so give the pitch path), the overrides you passed (or "defaults"), and that a push notification arrives at each stop and at delivery. Do not wait for it.
5. **Notify, then relay the hand-off.** When the conductor's result arrives (a stop or `done`):
   - Send a push notification yourself with the `PushNotification` tool (load it with ToolSearch if it is deferred): this runs in the main thread, which has the tool, and the background conductor never did. Send it at every stop and at delivery, with the stop line (or the `done` line) from the last entry of `RUN.md` as the message. If the tool is unavailable or fails, print the line first in your reply.
   - Start the app's dev server in the background (`pnpm --dir <app dir> dev --host 127.0.0.1`) and read the port it prints.
   - Give the user the conductor's hand-off with every link filled in with that port. Relay it as written; do not shorten it.

   Done when the notification is sent and the user has working links.

## Rules

- Never do the conductor's work here; this skill only starts it.
- Never start a conductor on an app whose lock is held; the conductor takes the lock with `run_state.py lock acquire` as its first step.
- To answer a stop, the user appends an `answer` line to `RUN.md` and runs `/conduct <app>` again.
- An `answer` line written while no stop is pending is notes: the running conductor reads it at the next round boundary.
