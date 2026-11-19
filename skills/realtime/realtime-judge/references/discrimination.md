# Reference discrimination

Measures whether a fresh judge can tell a render from its reference. Use it when the goal is "a critic cannot tell which is the original", not "after beats before".

## Steps

1. **Cut 12 crop pairs.** From the app's captures, take 12 reference crops and 12 render crops of the same regions at the same scale and size. Name each pair the same (`01.png` to `12.png`) in a reference folder and a render folder. Done when both folders hold the same 12 names.
2. **Shuffle.**

   ```bash
   python3 -I <skill dir>/scripts/blind_pair.py discriminate-prepare \
     --reference-dir <dir>/refs --render-dir <dir>/renders \
     --judge-dir <dir>/judge-discrimination --key <dir>/discrimination-key.json
   ```

   The judge directory holds `trial-01` to `trial-12`, each with only `x.png` and `y.png`; which trial holds which crop and which side is real are random. The key file stays out of it and out of every judge prompt.
3. **Run one fresh judge** (a read-only subagent, no shared context). Give it the judge directory and this task, word for word: "Each trial folder holds two crops, X and Y. Exactly one is a real reference; the other is a render. Look at both at full size and pick the real one in every trial. Reply with one line, `01=X,02=Y,...`, one pick for each of the 12 trials, and one short note per trial on what gave it away. Do not skip a trial; guess when unsure." Give it no rubric scores, no prior results and no hint of the render's flaws. Done when all 12 picks are back.
4. **Score.**

   ```bash
   python3 -I <skill dir>/scripts/blind_pair.py discriminate-score \
     --key <key.json> --answers 01=X,02=Y,... --markdown
   ```

   The look passes when the judge picks the real reference in 7 or fewer of the 12 trials; 8 or more fails. Done when you have the count and the result.
5. **Record.** Paste the markdown block, with the judge's per-trial notes, into the review packet. The notes of a failed run say what to fix next. Rerun with fresh crops after a fix; do not rerun the same trials until they pass.

## Rules

- The 7-of-12 bar is fixed. Tighten it only with the user's approval, never on your own and never to make a run pass.
- Same crop regions and scale for both sides; a size or compression difference makes the answer trivial and measures nothing.
- Scores here are judgements, not tests; the result is advisory and never gates a merge alone.
