# Onboarding

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [onboarding-deep.md](onboarding-deep.md).

1. **Teach by doing.** Each mechanic first appears where it is the only sensible move and a first try is safe. Text is the last resort. Why: doing sticks. Break when: the binding can't be discovered; show a hint (rule 4). Check: no paragraph of text in the first 60 s; a bot pressing only hinted inputs meets every verb. [1][2]

2. **The opening cannot lose the run.** Until each core verb has succeeded once, mistakes cost seconds, and the first hazard follows the first success. Why: early struggle makes players quit. Break when: the brief is permadeath; the death still explains itself (rule 6). Check: an input-less bot survives 30 s. [1][2][house]

3. **One new thing, used three times.** A mechanic arrives alone and repeats with variation about three times before the next; at most three new at once. Why: working memory. Break when: two mechanics are one idea (move and look). Check: a first-appearance table shows no shared firsts. [2][3][4][7]

4. **Hints die on use.** A hint serves one verb, appears after a playtested idle delay, stays until the verb succeeds once (never a timer), then never returns in that profile. Why: repeats annoy. Break when: the action is irreversible; keep it until confirmed. Check: act, assert the hint is gone; reload, still gone; clear storage, back. [2][5][6][7]

5. **Straight to play, fast.** Load to play takes one input: a title with Play focused, but no splash, picker or agreement before the first run; prompts wait; the forced audio click is the start click. Aim under 5 s to first input, 60 s to first success. Why: slow loads lose players. Break when: touch versus keyboard is undetectable. Check: a headless test logs inputs and ms to first input and first score. [4][5][10][11][12][13][house]

6. **Failure says what to change.** Early deaths show the cause and restart in place (timing: difficulty.md rule 3), with no tally or tips between. Why: players expect to die but resent slow loops. Break when: a roguelike recap is justified; keep retry one input. Check: log ms and inputs from death to control. [1][7][9][house]

7. **One goal in view.** The screen alone answers "what now?" with one objective or landmark. Break when: aimlessness is the premise; keep one distant landmark. Check: screenshots at 10, 30 and 60 s. [2][6][8][9]

8. **Returning players skip what they know.** Store a flag per hint; returners reach play in one input and the tutorial never replays. Keep a reachable "how to play" and skippable steps. Break when: skills fade; remind, don't replay. Check: set flags, reload, no hints; clear storage, hints return. [2][4][6][8][9][house]
