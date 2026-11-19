---
name: motion-review
description: Judges a change to a creative piece or game in motion, blind, from before and after frame strips, 1:1 detail crops and a burst of consecutive frames shuffled as X and Y, scored by a fresh motion judge on fluidity, rhythm, randomness of placement over time, temporal stability and flicker. Use when a polish round changes something that moves or shimmers (particles, dust, grain, noise, waves, timing), when still-frame judges cannot see the problem, when asked to judge motion, flicker or animation quality, or to compare before and after recordings of a piece.
metadata:
  scope: personal
---

# Motion Review

Still-frame judges cannot see motion or fine texture: an even layer of dust, specks popping in together, grain too fine to show at full frame. This skill adds a blind motion lens. Its score is advice, like any judge's; the app's hard gates stay the hard checks.

## Steps

1. **Pick the window and the crop.** Choose a time window that shows the change moving (several seconds; a full cycle for a looping piece) and a crop centre over the detail the change is about (the band where the dust lives, not empty backdrop). In the lab, set them in the `motion` object of the app's `captures.json` (fields in the lab README, "Motion capture"). For a game, script a playthrough in the `game` block of `captures.json` (a seed plus actions held from second to second): the lab replays it through `__game.advance`, so before and after play the same run and the window can be as long as the script. Done when before and after will be captured with the same window, crop and script.
2. **Capture before and after.** With the after side checked out (committed or not), capture the commit before the change and the working tree in one run; in the lab, `pnpm verify <app> --motion --against <before commit>` writes `.verify/<app>/motion-before/` and `motion-after/`. Without such a command, capture each commit in turn and copy its sheets out before the next run. Each `judge/` holds `strip.png`, `crops.png` and `burst.png`; each side also has a `motion.mp4` for people. If the capture says the sheets are identical, move the window or the crop to where the change shows before judging. Done when you have a before and an after folder with the same three file names that differ.
3. **Shuffle.** Use a fresh judge directory and keep the mapping file outside it:

   ```bash
   python3 -I <skill dir>/scripts/blind_motion.py prepare \
     --before <before judge folder> --after <after judge folder> \
     --judge-dir <dir>/judge-motion --mapping <dir>/mapping-motion.json
   ```

   Never print the mapping or put it in a prompt. Done when the judge directory holds `x/` and `y/` only.
4. **Run the judge.** Start a fresh `motion-judge` subagent with only the judge directory path and [references/rubric.md](references/rubric.md). Never give it the diff, the change's intent, earlier scores, the commit names or the words before and after. If it names before or after, discard the reply and run a new one. Done when it returns a score and a note for X and for Y.
5. **Decide.**

   ```bash
   python3 -I <skill dir>/scripts/blind_motion.py decide --mapping <dir>/mapping-motion.json --motion X=5,Y=7 --markdown
   ```

   The change is kept only if the after score equals or beats the before score. If the round also judges still moments, the motion window counts as one more moment: a loss here rejects the change, whatever the stills say. Done when you have the decision.
6. **Record and act.** Paste the markdown block, the judge's notes and the path of both `motion.mp4` files into the round's review notes (in the lab, next to `.verify/<app>/review-packet.html`). On a reject, revert or rework and judge again with a new shuffle; report the reject to the user and never re-run a judge until it agrees. Done when the decision is recorded and acted on.

## Rules

- Same window, crop, rubric and judge setup for before and after, and for every round, so scores stay comparable.
- The user watches the MP4s; the judge reads the sheets. A user's note about motion outranks the judge.
- Scores are judgements, not tests. Report them as such.
