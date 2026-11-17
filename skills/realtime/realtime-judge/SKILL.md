---
name: realtime-judge
description: Judges a polish-round change blind, with before and after captures shuffled as X and Y, two fresh judges on an anchored 10-point rubric, the lower score counting and the change kept only on a win or tie. Use when a polish round needs to know if a visual or feel change is an improvement, when asked to score or compare before and after captures of a game or piece, or when writing judge scores into a review packet.
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
3. **Run two fresh judges per moment** as parallel subagents, `visual-judge` and `feel-judge` (Opus, no shared context, read-only). Give each only the judge directory, the lens rubric from [references/rubric.md](references/rubric.md) and the benchmark the user named. Never give them the diff, the intent of the change, prior scores or the words before and after. Each returns a score from 1 to 10 for X and for Y with a one-line note per image. Done when both return both scores.
4. **Decide.** Per moment:

   ```bash
   python3 -I <skill dir>/scripts/blind_pair.py decide --mapping <mapping.json> \
     --visual X=6,Y=8 --feel X=6,Y=7 --markdown
   ```

   The lower of the two judges' scores counts for each capture, and the change is kept only if the after score equals or beats the before score. With several moments, keep the change only if every moment is kept. Done when you have a decision per moment.
5. **Record it in the packet.** Paste the markdown block from `decide`, with the judges' notes, into the app's review packet notes (for the lab, the round's entry beside `.verify/<app>/review-packet.html`). The mapping and seed live only there. Done when the packet shows both scores, the counted score and the decision.
6. **Act on the decision.** Keep: carry on. Reject: revert the change or fix the lowest-scoring criterion and judge again with a new shuffle. Report a rejected change to the user; do not argue with a judge by re-running until it passes.

## Rules

- Only the person running the round sees the mapping. If a judge's reply names before or after, discard it and rerun that judge.
- Use the same rubric and judge setup for every round so scores stay comparable.
- If `workflow-score-to-target` is installed, use it for the multi-round climb to a target score and its scorecard; this skill supplies the blind step inside each round. Without it, repeat steps 2 to 6 until every moment scores the target.
- Scores are judgements, not tests. Report them as such.
