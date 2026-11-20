# RUN.md and run_state.py

Read at step 1 of the conductor. `RUN.md` is in the app folder, committed and append-only.

## Entry kinds

One entry per line, `- <UTC timestamp> | <kind> | <text>`. Kinds:

- `start`: text carries `pitch=<path>` and optional `mode=overnight|review process=minimal|standard|full rounds=N hours=H autoAccepts=N look=auto target=yes`.
- `step`, `assumption`, `judge`, `revert`.
- `phase`: text is the phase name, logged when a phase begins: `brief`, `art-bible`, `first-playable`, `look-variants`, `checklist`, `polish`, `reference-judge`, `deliver`.
- `round-start`: `<N> | branch=<round branch> base=<sha>`, written before the director spawns.
- `round`: text starts with the round number.
- `stop`: `<stop name> | <one-line reason> | <packet path>`.
- `answer`: written by the user. One with no stop pending is notes for the next round. The answer to `look-variants` names a variant, such as `dusk` or `neon, less bloom`.
- `resume`, `done`.
- `wip`: the first finished slice is playable: play links.
- `budget`: a limit the user raised.
- `accept`: references accepted without the user: round, capture names and why.
- `note`: ignored when resuming.

A line that starts with `- ` and has two ` | ` but does not parse is skipped and named on stderr: check the kind is lowercase and the timestamp ends in `Z`.

## run_state.py

`python3 -I <conduct skill dir>/scripts/run_state.py <command> RUN.md`. A missing RUN.md exits 2; only `next --allow-missing` reads it as a new run.

| Command | Prints |
| ------- | ------ |
| `next` | `start`, `done`, `waiting: <stop>` (also `waiting: round-review` in review mode right after a round), `resume: <stop> \| <answer>`, `read result: round N branch <b>`, `redo: round N` (with a reason in parentheses when the branch could not be checked: read the branch first) or `continue: phase=<phase> \| last=<kind>: <text>`; then a `notes for the next round: <text>` line per `answer` that arrived with no stop pending |
| `budget` | `ok`, or `stop: ...` with exit 3 |
| `limits` | `mode=<m> process=<p> rounds=N hours=H autoAccepts=N` (`unlimited` for rounds and autoAccepts in overnight mode unless given) |
| `accepts` | `accepts-since-answer=K of N` (`of unlimited` overnight) |
| `phases` | active time per phase, then a total |
| `phase-names` | the phase names in run order |
| `look` | `look=ask\|auto target=yes\|no` (`auto` by default overnight), then `state=none\|pending\|chosen <preset> [\| note]\|auto <preset>\|unclear \| <answer>` |
| `lock acquire\|release\|status --owner <id>` | exit 4 when another owner holds it |

Hours are active run time summed across sittings (a sitting runs from `start` or `resume` to the next `stop` or `done`), so time spent waiting for an answer is free.

Read the `notes for the next round` lines before each round, pass them to the director as notes for that round, and log a `step` line saying so.

## Process setting

`process=` is `minimal`, `standard` (default) or `full`. An explicit `rounds=N` beats the process default; `budget` enforces whichever applies.

| Process | What runs | Polish rounds |
| ------- | --------- | ------------- |
| `minimal` | the brief only, no art bible document, one judge lens per moment (tell the director) | 2 |
| `standard` | steps 1 to 6 and 8, no reference judge | 6 |
| `full` | the standard flow plus the reference discrimination judge (step 7) and `motion-review` on every round (tell the director) | 6 |

With `minimal` there is no bible: step 2 also fixes what step 3 would have (`code-only` or one pack family for models: the pitch's choice, else the pack default), logged as an `assumption`, and step 4b writes its presets from the brief and the pitch. Under every setting, tell the director to judge combat motion from the play recording.
