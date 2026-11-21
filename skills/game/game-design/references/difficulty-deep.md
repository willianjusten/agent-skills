# Difficulty: detail

Read after [difficulty.md](difficulty.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Shape a sawtooth, not a ramp
- 2 Failure costs chance times replay
- 3 Retry fast, from the failed attempt
- 4 Combine only known things
- 5 Relax after every peak
- 6 Randomise inside a band; bosses stand apart
- 7 Adjust frequency and supply, not rules
- 8 Offer help after repeated failure, optional
- Numbers
- Sources

## 1 Shape a sawtooth, not a ramp

Chen's flow model: too hard gives anxiety, too easy gives boredom, and players differ in skill, so one fixed line fits some and loses others [1]. Valve found constant combat tiring and long quiet dull; alternating peaks and valleys held interest [2]. Valve also lists pacing and difficulty curve among things that cannot be judged until the whole game exists [7].

- Good: wave 4 spikes, wave 5 is a breather that adds a pickup, wave 6 beats wave 4.
- Bad: enemy count and speed grow by a fixed step each wave, so the player is bored early and drowned late.
- Mechanical check: replay a recorded or bot run through every stage; plot threat load and deaths per stage; rework a stage with about 4x the average deaths [house].

## 2 Failure costs chance times replay

McMillen frames difficulty as likelihood of dying times the penalty, and says the penalty has shrunk to restart time plus the length replayed [4].

- Good: a hard jump sequence that costs 2 s to retry.
- Bad: a medium boss behind a 90 s walk.
- Mechanical check: report deaths and seconds-to-return per segment.

## 3 Retry fast, from the failed attempt

McMillen calls Super Meat Boy's respawn almost instantaneous and ties the game's hardness staying fun to it; levels stay short so the goal is visible and little is re-crossed [4]. The 1 s figure is our reading of that direction [house].

- Good: a short hit reaction, then control at the attempt start, no confirm.
- Bad: death, 2 s fade, "Game Over", button, reload, 3 s intro; or a death that removes collected power-ups.
- Mechanical check: delta between the death event and the first accepted input at the start; dump the reset list.

## 4 Combine only known things

Valve's design process reused existing elements in new ways to gain depth without new learning cost [7]. The one-new-element-per-stage count is ours [house].

- Good: wave 6 mixes the shielded enemy from wave 3 with the dash enemy from wave 2.
- Bad: wave 3 adds two enemy types and a hazard together.
- Mechanical check: stage data has a `firstShows` list; assert length at most 1.

## 5 Relax after every peak

Valve's cycle: full threat until intensity crosses a peak, hold it 3 to 5 s, drop to minimal threat but wait for a natural break, then 30 to 45 s of minimal threat or until the team nears the next safe room [2][3]. Intensity rises with damage taken and nearby kills, decays toward zero, and does not decay while an enemy is engaging [2]. These come from a 4-player campaign; a 3-minute arena may need a shorter valley, which is a tuning call [house].

- Good: wave clears, 30 s with pickups and no spawns, a visible countdown.
- Bad: the next wave spawns while the last enemies still fight, with no recovery for ten waves.
- Mechanical check: log last damaging death to next threat; expose the intensity number in debug and confirm it falls during relax.

## 6 Randomise inside a band; bosses stand apart

Valve's mobs came at random 90 to 180 s intervals on Normal, and mob size grew from a minimum after a spawn to a maximum over time, so back-to-back mobs stay survivable; unpredictability was a mix of frequent, medium and rare events [2][3]. The Tank halts momentum, forces defence over assault, is announced by music, yells and footsteps, and is exempt from adaptive pacing [2][3]. The cue lead is ours [house].

- Good: a base plan with a bounded random offset; a second event soon after the first is smaller.
- Bad: uniform random spawn times with no floor, stacking two peaks; a boss that is a larger health bar.
- Mechanical check: 100 simulated runs, assert minimum peak gap; assert a cue event precedes the boss spawn by 2 s or more.

## 7 Adjust frequency and supply, not rules

Valve's Director changes how often threats come, not their strength, and its crude intensity estimate still works [2]. Hunicke's Hamlet adjusts the supply of health and ammunition, treating balance as an economy [5]. Chen warns that deaths and scores are poor proxies for flow and that a game barely sees the player's state [1]. Hunicke notes DDA moves control from designer to code [5].

- Good: after heavy damage, spawn less for a stretch and drop a repair item.
- Bad: silently halving enemy health after 3 deaths; skill stops meaning anything.
- Mechanical check: list the adjuster's writes (timing, counts, pickups only); assert floor and ceiling; read the change log.

## 8 Offer help after repeated failure, optional

Nintendo's Super Guide in New Super Mario Bros. Wii offers to demonstrate a section after repeated failure; its designers pitched it at players who want to move on, while those who want mastery ignore it [6]. The count is a design choice.

- Good: after N deaths on one segment, offer "skip" or "slow this section".
- Bad: quietly easing the game, or never helping a player who died 20 times at one spot.
- Mechanical check: script N deaths; assert the offer shows, declining it changes nothing, and the run is flagged assisted.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 3 to 5 s | full threat held after a peak | 2, 3 |
| 30 to 45 s | minimal threat relax period | 2, 3 |
| 90 to 180 s | random mob interval, Normal | 2, 3 |
| about 1 s | death to control | house (direction from 4) |
| 2 to 3 s | boss cue lead | house |
| 4x average | deaths per stage that trigger rework | house |
| 1 | new elements first shown per stage | house |

## Sources

1. Chen, J. "Flow in Games", USC MFA thesis (2006), and "Flow in Games (and Everything Else)", Communications of the ACM 50(4) (2007).
2. Booth, M. (Valve). "The AI Systems of Left 4 Dead", AIIDE 2009 keynote slides.
3. Valve. "Replayable Cooperative Game Design: Left 4 Dead", GDC 2009 slides.
4. McMillen, E. on Super Meat Boy, "Why So Hard?", designer talk reported by Game Developer.
5. Hunicke, R. and Chapman, V. "AI for Dynamic Difficulty Adjustment in Games" (Hamlet).
6. Iwata Asks: New Super Mario Bros. Wii, Nintendo, Super Guide interview.
7. Valve. "Half-Life 2 Design Process", GDC slides (2006).
