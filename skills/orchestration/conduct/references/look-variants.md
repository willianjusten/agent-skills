# Look variants and the target frame

Read at step 4b of the conductor.

The pitch or caller may say `look=auto` and `target=yes`; copy them into the `start` or a `budget` line.

## Variants

Write three presets in the app's `src/presets/<name>.json` (format: the lab's look module, standard tuning preset), from the art bible (the brief when `process=minimal` skipped it) and the pitch. Each sets the palette hues, light, fog, grade and camera values it changes and leaves the rest at the app default. They differ in palette, light and atmosphere as far as the pitch allows (a warm dusk, a cold neon night, a bright noon are the shape; follow the pitch's mood and its "Not this" list). A preset that changes nothing visible makes near-copies: redo it.

Pick a moment where the game is mid-action (a game's `game.capture` name such as `after-pickup` or `mid-wave`, an experiment's `t-<seconds>s`). Run `pnpm verify <app> --variants <a>,<b>,<c> --moment <name>` (it runs alone, no gates), then `pnpm verify <app>` so the packet's "Look variants" section is current.

- `look=ask` (default): append `stop | look-variants | pick one of variants=<a>,<b>,<c> with one answer line, optionally with a note | <packet path>`. The user answers `answer | <variant name>` or `answer | <variant name>, <note>`; read it with `run_state.py look`. This is stop point 1 and costs the user one line. An `unclear` state means the answer names no variant: stop again with the same stop line.
- `look=auto`: choose the variant that best fits the pitch and its "Not this" list and append `assumption | look=auto <preset> | <why it fits the pitch>`; there is no stop.

## Writing the chosen look

Copy the chosen preset's values (and the note's change on top) into the app's `src/look.ts` spec, keep the other presets in `src/presets/`, run `pnpm verify <app>` green and append `step | look chosen: <preset> | <note, if any>`.

The chosen look's capture is the judges' benchmark whenever no target frame exists: copy `.verify/<app>/variants/<preset>.png` to `looks/chosen.png` in the app folder, commit it, and give its absolute path to the director as the look benchmark.

## Target frame (only when `target=yes`)

Follow `target-loop` steps 2 and 3 from the chosen look (capture, `pnpm asset target prepare <id> --app <app dir> --capture <png>`, then the stop) and append `stop | target-frames | ... | <packet path>`. You never approve, generate or swap a target. Without `target=yes` there is no target stop and no target: the chosen look is the benchmark.
