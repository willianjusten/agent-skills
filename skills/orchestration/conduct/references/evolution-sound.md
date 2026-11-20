# Evolution and sound

Read at step 4 (baseline), step 6 (every round) and step 8 of the conductor. The review packet's Evolution section and `.verify/<app>/evolution.html` show every moment as a row of stills in round order, with scores and a kept or reverted chip under each. They are only complete when every round was recorded, reverted tries included.

## Recording a round

`pnpm verify <app> --round <label> [--round-notes <file>]` is a normal verify run (add `--record-seconds 45` at a checkpoint or when the round judges motion of real play; `references/checkpoints.md`) that also snapshots the captures, and the trailer sheet and mp4 when `.verify/<app>/trailer/` exists, into `.verify/<app>/evolution/<NN>-<label>/`. Not with `--motion`, `--variants`, `--url` or `--preset`.

- **When.** Once after the first playable, labelled `baseline` (no notes). Then after every polish round, labelled `r<N>`, and once more for every reverted try, labelled `r<N>-try<K>-reverted`, run before the revert so the captures are the tried state. The trailer round uses `trailer-baseline`, `trailer-t<K>` and `trailer-t<K>-reverted`; pass `--trailer` in the same run, so the sheet is in the round (the sheet of an earlier `--trailer` run is picked up too).
- **Labels.** Letters, digits, `-` and `_`. Reusing a label replaces that round in place; folders are numbered by creation order and earlier rounds persist.
- **Notes file.** Write it under the round's scratch folder, never in the app, from the judges' counted scores after the round:

  ```json
  {
    "summary": "one line about the round",
    "moments": {
      "<capture name without .png>": { "visual": 7, "feel": 6, "motion": 7, "target": 8, "kept": true, "note": "short reason" }
    }
  }
  ```

  `visual` and `feel` are the counted (lower) judge scores, required for a listed moment; `motion` and `target` are optional; `kept` says whether the round's change to that moment stayed. Every name must match a capture the run produced (exit 2 otherwise), and a moment not listed shows its still without scores. A label containing `reverted`, or every noted moment `kept: false`, dims the round. Never write a score a judge did not return.
- Each recorded round gets a `step | evolution round <label> recorded` line.

## Hand-off

Link `.verify/<app>/evolution.html` (absolute path) next to the packet in every hand-off, and open a `round-review` hand-off with the Evolution section. The `accept` lines of an overnight run are listed there with the capture they changed.

## Sound

Games with `src/balance.ts` and an event map in `src/sounds.ts` get a `sound` key in `results.json` and a "Sound" packet section: one row per mapped event with `peakDbfs`, `loudnessDbfs`, `durationMs`, `fired` (the bot run dispatched an event the map wires to that sound) and `flags` (`silent`, `loud`, `never-fired`; `three-verify` defines them). The `sound` gate fails on a silent sound or one that never fired; `loud` is a finding.

- The feel judge scores sound, since no judge can hear: give it `sound.report.sounds` as `realtime-judge` describes (`references/sound.md`). The table says nothing about before or after.
- A `sound` row (lens `feel`, target: gate passes and no audio problem named) is at target only when both hold, and `rows` enforces the gate half: the `row` line carries `gate=pass` (or `gate=fail`) from the `sound` gate, and without `gate=pass` the row stays below target whatever the score. The line takes the feel judge's score for the table as F and `-` as V (`score -/<F>`).
- A sound that never fired usually means the bot policy in `src/balance.ts` never reaches it (a reroll, a refused buy, game over): fix the policy so the bot exercises it, rather than dropping the sound from the map.
- Without `src/sounds.ts` there is no sound row and no gate.
