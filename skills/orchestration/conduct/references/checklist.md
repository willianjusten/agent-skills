# Component checklist

Read in the checklist phase.

`COMPONENTS.md` in the app folder is a table with one row per component: its measurable target (a number or a named gap to the target frame), the folder it owns and its lens (`visual`, `feel` or `motion`). Components own disjoint folders. `run_state.py profile` says which row sets below apply.

## Rows by kind

- **Game** (`game-rows=yes`): components for movement, hit feedback, enemies, UI and audio, mostly `feel` and `motion` lenses; then the Baseline, Features and balance rows below.
- **Experiment** (`game-rows=no`): components for the piece's layers (particles, fields, post, palette, camera), mostly `visual` and `motion` lenses; no Baseline, feature or balance rows. Every experiment also gets:
  - a `motion` row for the piece over time: target "the motion judge scores fluidity, rhythm and flicker at or above <T> across the motion window", folder the simulation or effect folder;
  - an `input` row when the treatment maps input (pointer, keys, audio or MIDI): lens `motion`, target "the response the treatment's input mapping names is visible within the motion window", folder the input module. An audio-reactive piece names its test signal (a fixture file or a generated tone sweep) in the target, so the judges see the same input each round.

Rows still score `visual` and `feel` as V/F, for both kinds: for an experiment the feel judge reads the frame's readability and its response to input, and the motion judge's score goes in the round notes as `motion`.

With a target, run `pnpm asset target path <id> --app <app dir>` after the answer: it must print an approved target; if it fails, stop again. Without one, an art-bible reference image is the benchmark when the bible names one; otherwise the gap score is not reported.

## Baseline (games)

Run `pnpm verify <app>` and read `baseline` in `.verify/<app>/results.json` (the packet's "Game baseline" table). Items are title, pause, sound, banner, restart and loading, each `present`, `missing` or `skipped`. Add one "Baseline" component for the missing items, without asking: one row per missing item (target: the item present and its UI check green; lens `visual`; it owns the files the shared factory is wired in). A pitch that rules an item out (no pause in a speedrun timer) is not added: append `- No <item>: <reason>` to `DECISIONS.md` (the check then reports `skipped`) and log `assumption | baseline: no <item> | <reason>`. Baseline rows come first, so round 1 fixes them before taste work.

## Features and balance (games)

From the brief's feature list, add a row per feature whose check in the game's `src/features.ts` fails (the packet's "N of M features pass" and its failing rows), with the check's `why` as the target. From the brief's balance band, run the balance report (`balance` in `results.json`, the packet's "Balance report") and add a row per measure outside its band (for example "win rate 0%, band 20-60%" or "idle survives round 1 on 4 of 24 seeds, band: yes"); lens `feel`. Without a `src/balance.ts` or a band, add no balance rows. Features and balance are reports, never gates: they become rows so polish rounds fix them like any other gap, and a row back in band or passing counts as met.

## Sound

With `sound-row=yes`: when the packet has a "Sound" section (a game with `src/sounds.ts` and a bot run), add one `sound` row: lens `feel`, target "the `sound` gate passes and the feel judge names no audio problem", folder `src/sounds.ts` and any audio folder (`references/evolution-sound.md`). The `trailer` row is not part of the checklist: the trailer round declares it when it starts (`references/trailer-round.md`), so `rows` is not held open by it.
