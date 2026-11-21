# Loop

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [loop-deep.md](loop-deep.md).

1. **Name the loop in one line.** The player does X, the game answers Y, and Y changes what the player does next. No third part means an arc (one pass), not a loop. Break when: played once by design. Check: per feature, ask what repeats; remove the ones that neither repeat nor feed the loop and see if the core stands. [1][2]

2. **Every action shows what changed and why.** Each input and state change gets a visible or audible response in the same or next frame; damage shows its source. Why: without it the player cannot update their model. Break when: hidden information is the point. Check: press each input once and name the response. [1][2][3][4]

3. **Goals at three scales, each feeding the next.** One goal ends in seconds, one in minutes, one spans the session; the first completes within 10 s. Why: a lone long goal gives nothing to do now. Break when: the minute scale is the same loop repeated (wave after wave). Check: list each goal with its duration, one per band; freeze the 10 s screenshot and say what to do. [1][4][5][house]

4. **Choices cost something and depend on the situation.** Each option gives something up, the best pick changes with state, and the result shows. At most 3 non-trivial choices per 10 s. Why: a dominant option is not a decision. Break when: execution is the skill (rhythm, twitch aim). Check: for each pick-one set, find a state where each option wins. [4][house]

5. **Risk buys a reward the player can size up.** An optional risk pays visibly more than the safe route and is readable before committing. Break when: relaxed exploration. Check: table each risky option against its safe baseline; a guarded pickup must be worth more than a free one. [3][4]

6. **Growth meets a counter-force.** Every source of player strength (fire rate, speed, multiplier) gets a counter: density rises, drops thin out or the multiplier decays. Why: unchecked positive feedback snowballs until nothing threatens the player. Break when: a power fantasy is the point. Check: list each growth source and its counter; without new threats minute two must not be easier. [6][7][house]

7. **Replay comes from depth, not volume.** Vary situations (seeded spawn mix, layout) and make each skill needed by a later challenge. Why: content only delays a solved loop. Break when: a deliberate one-shot. Check: ten seeded bot runs must differ in situations and scores; every skill is demanded by some later challenge. [1][2][3]

Difficulty curve, retry cost, catch-up help: difficulty.md.
