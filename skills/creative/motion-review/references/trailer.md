# Judging a trailer

Read at step 2 when the thing to judge is the app's directed trailer, not a stretch of real play.

1. Record it with `pnpm verify <app> --trailer`: `.verify/<app>/trailer/play.mp4` (60 fps) and `play-contact-sheet.png`, one tile per second.
2. Cut the strip, the 1:1 crops and the burst from the mp4 yourself, since `--from-recording` reads only the play recording. The frame at time t is ffmpeg `-ss t`. Take a burst across every cut and the final reveal.
3. Between edits to the shot list, take shots at the shot times with `pnpm shot <app> <t1> [t2 ...] --query <the trailer's query>` (about 3 s) rather than a full recording.

Done when the strip, crops and burst exist; continue at step 3 of the skill.
