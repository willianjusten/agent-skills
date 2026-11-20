# Sound table for the feel judge

Read at step 3 when the game's `results.json` has a `sound` key. No judge can hear, so the feel judge scores the numbers.

1. Paste `sound.report.sounds` into the `feel-judge` prompt as a plain text table (event, sound, peak, loudness, duration, fired, flags), next to the image directory, with the sentence "also name any audio problem the table shows". The table says nothing about before or after.
2. The judge adds one `Sound: <score 1-10>  <note>` line, or `Sound: no audio problem`.
3. A `sound` row is at target only when the `sound` gate passes and the judge names no audio problem. Report the gate result next to the judge's line.

Done when the `Sound:` line is in the judge's reply.
