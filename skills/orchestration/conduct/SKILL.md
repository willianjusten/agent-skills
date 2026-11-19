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

1. **Resolve the target.** The argument is a pitch file (`PITCH.md`) or an app folder. If it is a folder with a `RUN.md`, run `python3 -I <skill dir>/scripts/run_state.py next <app>/RUN.md`: `done` means say so and stop; `waiting: <stop>` means the user has not answered, so show the stop line and ask them to append `- <UTC timestamp> | answer | <text>` to `RUN.md`, then stop. Otherwise it is a start or a resume. A pitch without an approval line (`Approved by`) is not ready: say so and stop. Done when the target is one of start, resume.
2. **Collect overrides.** Read any extra stop points or budgets in the request (`rounds=N`, `hours=H`, "also stop after ...") and pass them through. Defaults: 6 polish rounds, 4 hours of active run time (summed across sittings; waiting for an answer is not counted). Done when the overrides are listed.
3. **Start it in the background.** Run from the lab repo, with the Bash tool's background option:

   ```bash
   claude --agent conductor -p "<start or resume>: <path>. <overrides>"
   ```

   The conductor must run as the main-thread agent, because it and `polish-director` spawn subagents; it cannot be started with the Agent tool. Done when the process is running. If it exits within seconds, read its output, fix the cause and return to step 1; do not report a run that never started.
4. **Tell the user.** One line: the run's app folder, `RUN.md` path, the budgets, and that a push notification arrives at each stop. Do not wait for it.

## Rules

- Never do the conductor's work here; this skill only starts it.
- To answer a stop, the user appends an `answer` line to `RUN.md` and runs `/conduct <app>` again.
