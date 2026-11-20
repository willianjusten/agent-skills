---
name: realtime-judge
description: Judges a polish-round change blind, with before and after captures shuffled as X and Y, two fresh judges on an anchored 10-point rubric, the lower score counting and the change kept only on a win or tie. Use when a polish round needs to know if a visual or feel change is an improvement, when asked to score or compare before and after captures of a game or experiment, when writing judge scores into a review packet, or when asked whether a judge can tell a render from its reference.
metadata:
  scope: personal
---

# Realtime Judge

Blind A/B judging for polish rounds only, not for every change. Judges advise; they never gate a merge alone, and `verify` gates stay the hard checks.

## Steps

1. **Get matching captures.** Take before and after PNGs of the same moments (same tick or time, same size) from the app's `verify` captures. Done when every moment has a before and an after image.
2. **Shuffle one moment at a time.** Run the script, once per moment, with a fresh judge directory each time:

   ```bash
   python3 -I <skill dir>/scripts/blind_pair.py prepare \
     --before <before.png> --after <after.png> \
     --judge-dir <dir>/judge-<moment> --mapping <dir>/mapping-<moment>.json
   ```

   The judge directory holds only `x.png` and `y.png`. The mapping file stays out of it, and you never print it or put it in a judge prompt. Done when each moment has a judge directory and a mapping file.
3. **Run two fresh judges per moment** as parallel subagents, `visual-judge` and `feel-judge` (Opus, no shared context, read-only). Give each only the judge directory, the lens rubric from [references/rubric.md](references/rubric.md) (paste its text into the prompt) and, when there is one, the absolute path of the benchmark image the user named (for a round chasing a target, the path `target path` prints; with no target, an art-bible reference image; never a capture of the app itself, and with neither there is no benchmark and no gap score), and the user's accepted differences from that target, word for word, from the `## Accepted differences` heading of the app's `DECISIONS.md` when it has one. Accepted differences describe the look, never which image is newer. Never give them the diff, the intent of the change, prior scores or the words before and after. Each returns a score from 1 to 10 for X and for Y with a one-line note per image, and for a still moment five yes or no answers per image, each with one line of evidence: player visible against the floor, threats readable, light direction matches the look, nothing clipped or cropped, HUD readable at play size (the rubric's concrete questions); with a benchmark, each also returns a target-gap score per image and a gap list under the rubric's five headings. Done when both return both scores, the five answers per image for a still moment, and the gap lists when there is a benchmark.
4. **Decide.** Per moment:

   ```bash
   python3 -I <skill dir>/scripts/blind_pair.py decide --mapping <mapping.json> \
     --visual X=6,Y=8 --feel X=6,Y=7 \
     --questions player_visible=yes:yes,threats_readable=yes:yes,light_direction=yes:yes,nothing_clipped=yes:yes,hud_readable=yes:no \
     --questions player_visible=yes:yes,threats_readable=yes:yes,light_direction=yes:yes,nothing_clipped=yes:yes,hud_readable=yes:yes \
     [--visual-gap X=4,Y=5 --feel-gap X=5,Y=5] --markdown
   ```

   `--questions` is given once per judge, with all five questions, each answer `X:Y` as `yes`, `no` or `na` (`python3 -I <skill dir>/scripts/blind_pair.py questions` lists the names). A side's answer is `yes` only when every judge said yes. A still moment without `--questions`, or a judge that leaves a question out, is an error; `--no-questions` is for a moment that has none on purpose.

   Pass the gap flags whenever the judges had a benchmark; the script then rejects a change whose counted gap score drops.

   A motion window scored by a motion judge is one more moment: prepare it with the before and after folders of motion sheets as `--before` and `--after` (the judge directory then holds `x/` and `y/`), and decide it with `--motion X=5,Y=7`, alone or beside `--visual` and `--feel`; the lowest given lens counts.

   The lowest judge's score counts for each capture, and the change is kept only if the after score equals or beats the before score, no question turns newly `no` (a `no` after a `yes` or `na`, even when the score rises) and, with a benchmark, the counted after gap score equals or beats the before gap score. With several moments, the change is kept only if it wins or ties at every moment; a loss at any one moment rejects it. A tie where the judges' notes say the two images look the same means the change had no visible effect at this scale: report "kept, no visible effect", not an improvement. Done when you have a decision per moment.
5. **Record it in the packet.** Paste the markdown block from `decide`, with the judges' notes, their gap scores (after-image gap, lower of the two counts) and their after-image gap lists verbatim, into the app's review packet notes (e.g. in the lab, the round's entry beside `.verify/<app>/review-packet.html`). The mapping and seed live only there. Add each judge's one line of evidence for every answer that changed. Done when the packet shows both scores, the answers beside them, the counted score and the decision.
6. **Act on the decision.** Keep: carry on to step 7. Reject: revert the change or fix the lowest-scoring criterion and judge again with a new shuffle. Report a rejected change to the user; do not argue with a judge by re-running until it passes. Done when the change is kept, or reverted or reworked and rejudged.
7. **Write the next brief.** Start from the after image's gap lists, so a win over the before image never hides what the target still has. Then check every item against the user's taste: the app's `taste.md`, the repo root `taste.md`, the app's `## Accepted differences`, the user's settled notes in the app's `DECISIONS.md` and any notes the user gave for this round. The user's taste outranks the judges: drop each item that contradicts it, and list every dropped item with the line that ruled it out. User notes are an optional override; the brief goes ahead from the gap lists and taste files whenever there are none. Done when every gap list item is either in the brief or listed as dropped with its reason.

## Reference discrimination mode

When the question is whether a render passes for its reference, not whether a change improved it, follow [references/discrimination.md](references/discrimination.md); it holds the trial setup, the pass bar and when the bar may change. Record the result and per-trial answers in the review packet.

## Rules

- Only the person running the round sees the mapping. If a judge's reply names before or after, discard it and rerun that judge.
- Use the same rubric and judge setup for every round so scores stay comparable.
- If `workflow-score-to-target` is installed, use it for the multi-round climb to a target score and its scorecard; this skill supplies the blind step inside each round. Without it, repeat steps 2 to 7 until every moment scores the target.
- With a benchmark, a change that wins on the lens but drops the gap score is rejected: it looks better but moves away from the target. The gap lists also drive the next brief and the multi-round target score.
- Scores are judgements, not tests. Report them as such.
