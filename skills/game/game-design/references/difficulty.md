# Difficulty

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [difficulty-deep.md](difficulty-deep.md).

1. **Shape a sawtooth, not a ramp.** Challenge rises over the run with a lighter stage after every hard one; the next hard stage tops the last. Judge it on a complete run. Why: constant pressure fatigues, constant calm bores. Check: log threat load per wave or room (enemies alive times damage, or moves needed); it must not rise monotonically. [1][2][7]

2. **Failure costs chance times replay.** Tune both: a hard segment with a 2 s retry feels gentler than a mild one that replays 90 s. Check: per segment, log deaths and seconds from death back to the point of failure. [4]

3. **Retry fast, from the failed attempt.** Control returns within about 1 s of death, without a confirm press, at the start of the attempt with the goal in view. Death never strips earned upgrades. Break when: a run-based game; then game over focuses Retry and control returns within 3 s, and runs last minutes. Check: timestamp death and first accepted input; list what resets on death, each with a reason. [4][house]

4. **Combine only known things.** Escalate by mixing elements already met; a stage shows one new element at most (teaching it: onboarding.md). Break when: the combination is itself the lesson. Check: tag each stage with elements it first shows; fail any with two. [7][house]

5. **Relax after every peak.** Keep full threat 3 to 5 s after the peak, wait for the last fight to end, then 30 to 45 s of minimal threat with pickups and no spawns; cue the next wave. Check: log last damaging enemy death to next threat; assert above the floor outside boss waves. [2][3][house]

6. **Randomise inside a band; bosses stand apart.** Spawn timing varies in a range, an event right after another is smaller, and no two peaks stack. A boss changes the tactic, is cued 2 to 3 s ahead, and ignores relax logic. Check: simulate 100 runs; the gap between peaks never drops below the floor. [2][3][house]

7. **Adjust frequency and supply, not rules.** The adjuster moves spawn timing, counts and pickup drops; never damage, enemy health or player stats. Use two or three signals, a hard floor and ceiling, and a log line per change. Why: fixed rules keep skill meaningful. Check: list every parameter the adjuster writes. [1][2][5]

8. **Offer help after repeated failure, optional.** After a set count of deaths on one segment (choose and record it), offer a skip or a slower pass; the player can decline. Mark assisted runs in scored modes. Check: simulate the deaths; the offer appears and play continues without taking it. [6][house]
