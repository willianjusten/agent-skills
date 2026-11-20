# RUN.md and run_state.py

Read at the start of the conductor. `RUN.md` is in the app folder, committed and append-only.

## Entry kinds

One entry per line, `- <UTC timestamp> | <kind> | <text>`. Kinds:

- `start`: text carries `pitch=<path>`, `kind=game|experiment` and optional `mode=overnight|review process=minimal|standard|full rounds=N hours=H reserve=M autoAccepts=N look=auto target=yes`.
- `step`, `assumption`, `judge`, `revert`.
- `phase`: text is the phase name, logged when a phase begins: `brief`, `art-bible`, `first-playable`, `look-variants`, `checklist`, `polish`, `reference-judge`, `trailer`, `deliver`.
- `round-start`: `<N> | branch=<round branch> base=<sha>`, written before the director spawns.
- `round`: text starts with the round number.
- `stop`: `<stop name> | <one-line reason> | <packet path>`.
- `answer`: written by the user. One with no stop pending is notes for the next round. The answer to `look-variants` names a variant, such as `dusk` or `neon, less bloom`.
- `resume`, `done`.
- `reopen`: `after done | focus: <text>`, written by the conductor when the user asks for more work on a `done` run. It starts a new leg back in `polish`.
- `wip`: the first finished slice is playable: play links.
- `budget`: a limit the user raised.
- `row`: `<name> | turn <N> | score <V>/<F> of target <T> | kept|reverted|pending | approach: <text>`, one per row per turn: V and F are the visual and feel scores of the row's moment as it stands after the turn (a reverted turn carries the kept version's scores). The checklist phase declares each row once as `<name> | turn 0 | score -/- of target <T> | pending | approach: none`.
- `checks`: `<round label> | <minutes>`, the wall minutes the round spent in checks.
- `checkpoint`: `<round label> | <what ran>`, written after a checkpoint (`references/checkpoints.md`).
- `accept`: references accepted without the user: round, capture names and why.
- `note`: ignored when resuming.

A line that starts with `- ` and has two ` | ` but does not parse is skipped and named on stderr: check the kind is lowercase and the timestamp ends in `Z`.

## run_state.py

`python3 -I <conduct skill dir>/scripts/run_state.py <command> RUN.md`. A missing RUN.md exits 2; only `next --allow-missing` reads it as a new run.

| Command | Prints |
| ------- | ------ |
| `step` | the one next action: `start`, `done`, `wait: <stop>`, `resume: <stop> \| <answer>`, `read result: ...`, `redo: round N`, `stop: round-review \| round N`, `phase: <name> \| done when <check>`, `work: <name> \| done when <check>` or `round: N \| tier=light\|checkpoint \| accepts=yes\|no \| motion-every-round=yes\|no \| rows: <pick order>`; then the `notes for the next round` lines. It walks the phases in run order and names the first whose check fails, so a skipped phase comes back |
| `profile` | `kind=game\|experiment process=<p> brief=GDD.md\|TREATMENT.md art-bible=yes\|no motion-every-round=yes\|no game-rows=yes\|no sound-row=yes\|no trailer=yes\|no`: the kind is `kind=` in a `start` or `budget` line, else `category` in `app.json` |
| `next` | `start`, `done`, `waiting: <stop>` (also `waiting: round-review` in review mode right after a round), `resume: <stop> \| <answer>`, `read result: round N branch <b>`, `redo: round N` (with a reason in parentheses when the branch could not be checked: read the branch first) or `continue: phase=<phase> \| last=<kind>: <text>`; then a `notes for the next round: <text>` line per `answer` that arrived with no stop pending |
| `budget` | `ok`; `reserve: <left> left of <H>h, delivery reserve <N>m` (exit 0) once the time left is at or below the delivery reserve (`reserve=<minutes>`; `run_state.py` holds the default); or `stop: ...` with exit 3 |
| `rows` | one line per row: `<name> turns=N score=V/F counted=C target=T at-target=yes\|no last=kept\|reverted\|none [lost=K]` (a side of the score is `-` for the trailer and sound rows; the sound line adds `gate=pass\|fail\|none`); then `next: <rows to pick, in order>` (a lost row carries `(new approach)`, one lost twice `(shrink scope)`, or `(same approach, write a new one)` when both losses used the same approach) and `all-at-target=yes\|no` |
| `limits` | `mode=<m> process=<p> rounds=N hours=H autoAccepts=N` (`unlimited` for rounds and autoAccepts in overnight mode unless given) |
| `accepts` | `accepts-since-answer=K of N` (`of unlimited` overnight) |
| `phases` | active time per phase, then a total |
| `checks` | `checks=<M>m run=<R>m share=<P>%`; a `lighter: <label> spent <M>m of <R>m in checks` line follows when the newest round spent more than half of its time in checks |
| `checkpoint` | `checkpoint-due` or `light` for the next polish round: due with no checkpoint yet, two rounds after the last one, at the delivery reserve, or on the last round the limit allows |
| `phase-names` | the phase names in run order |
| `look` | `look=ask\|auto target=yes\|no` (`auto` by default overnight), then `state=none\|pending\|chosen <preset> [\| note]\|auto <preset>\|unclear \| <answer>` |
| `lock acquire\|release\|status --owner <id>` | exit 4 when another owner holds it |

Hours are active run time summed across sittings (a sitting runs from `start`, `resume` or `reopen` to the next `stop` or `done`), so time spent waiting for an answer is free. A `reopen` starts a new leg: `budget`, `checkpoint` and `accepts` count only the rounds, hours and accepts after the last `reopen`, against the limits in force; `phases` and `checks` still cover the whole run.

Read the `notes for the next round` lines before each round, pass them to the director as notes for that round, and log a `step` line saying so.

## Process setting

`process=` is `minimal`, `standard` (default) or `full`. An explicit `rounds=N` beats the process default; `budget` enforces whichever applies.

| Process | What runs | Polish rounds |
| ------- | --------- | ------------- |
| `minimal` | the brief only, no art bible document, one judge lens per moment (tell the director) | 2 |
| `standard` | every phase but the reference judge | 6 |
| `full` | the standard flow plus the reference discrimination judge (the reference-judge phase) and `motion-review` on every round (tell the director) | 6 |

With `minimal` there is no bible: the brief phase also fixes what the art bible would have (`code-only` or one pack family for models: the pitch's choice, else the pack default), logged as an `assumption`, and the look-variants phase writes its presets from the brief and the pitch. Under every setting, tell the director to judge combat motion from the play recording.
