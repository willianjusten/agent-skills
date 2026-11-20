# Component checklist

Read at step 5 of the conductor.

`COMPONENTS.md` in the app folder is a table with one row per component: its measurable target (a number or a named gap to the target frame), the folder it owns and its lens (`visual`, `feel` or `motion`). Games usually need feel and motion rows (movement, hit feedback, audio), experiments visual and motion rows. Components own disjoint folders.

With a target, run `pnpm asset target path <id> --app <app dir>` after the answer: it must print an approved target; if it fails, stop again. Without one, an art-bible reference image is the benchmark when the bible names one; otherwise the gap score is not reported.

## Baseline

Run `pnpm verify <app>` and read `baseline` in `.verify/<app>/results.json` (the packet's "Game baseline" table). Items are title, pause, sound, banner, restart and loading, each `present`, `missing` or `skipped`. Add one "Baseline" component for the missing items, without asking: one row per missing item (target: the item present and its UI check green; lens `visual`; it owns the files the shared factory is wired in). A pitch that rules an item out (no pause in a speedrun timer) is not added: append `- No <item>: <reason>` to `DECISIONS.md` (the check then reports `skipped`) and log `assumption | baseline: no <item> | <reason>`. Baseline rows come first, so round 1 fixes them before taste work.

## Features and balance

From the brief's feature list, add a row per feature whose check in the game's `src/features.ts` fails (the packet's "N of M features pass" and its failing rows), with the check's `why` as the target. From the brief's balance band, run the balance report (`balance` in `results.json`, the packet's "Balance report") and add a row per measure outside its band (for example "win rate 0%, band 20-60%" or "idle survives round 1 on 4 of 24 seeds, band: yes"); lens `feel`. Without a `src/balance.ts` or a band, add no balance rows. Features and balance are reports, never gates: they become rows so polish rounds fix them like any other gap, and a row back in band or passing counts as met.

## Sound

When the packet has a "Sound" section (a game with `src/sounds.ts` and a bot run), add one `sound` row: lens `feel`, target "the `sound` gate passes and the feel judge names no audio problem", folder `src/sounds.ts` and any audio folder (`references/evolution-sound.md`). The `trailer` row is not part of the checklist: the trailer round declares it when it starts (`references/trailer-round.md`), so `rows` is not held open by it.
