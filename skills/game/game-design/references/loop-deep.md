# Loop: detail

Read after [loop.md](loop.md) when a rule doesn't settle the case. Sections follow the rule numbers.

## Contents
- 1 Name the loop in one line
- 2 Every action shows what changed and why
- 3 Goals at three scales, each feeding the next
- 4 Choices cost something and depend on the situation
- 5 Risk buys a reward the player can size up
- 6 Growth meets a counter-force
- 7 Replay comes from depth, not volume
- Numbers
- Sources

## 1 Name the loop in one line

Cook defines a loop as model, action, system, feedback and updated model, and an arc as a loop you leave immediately [1]. Loops build lasting skill; arcs (a scripted mission, a one-off puzzle) lose value after one pass [1][2]. His test: remove a feature and see whether the core still stands [1].

- Good: arena shooter. Aim and shoot, the enemy reacts and more spawn, positioning changes the next shot.
- Bad: a scripted intro fight that plays identically every run and changes nothing in later fights.
- Check: list the verbs in code that change state because of input; mark each as repeating or one-shot. A one-shot that feeds no repeating verb is an arc.

## 2 Every action shows what changed and why

Koster lists what feedback must convey: what you can do, that you did it, how state changed, whether it helped [3]. Cook wants feedback that is functional, helping the player build a correct model [1][2]. Meier warns that the worst move after a decision is to just move on [4]. Per-event juice sits in the feel topic; this rule is only that cause and effect is shown.

- Good: a missed shot shows where it landed and whether cover absorbed it.
- Bad: damage with no visible source, so the player cannot tell what to avoid.
- Mechanical check: enumerate input handlers and state mutations; assert each emits a visual or audio event in the same or next frame. Report the count with none.

## 3 Goals at three scales, each feeding the next

Meier frames decisions as short-term against long-term, with the player turning short progress into reach on the long goal [4]. Cook calls loops fractal, running at many levels and frequencies [1]. Chen lists clear goals and direct feedback among the elements of flow [5]. The three named bands and the 10 s first goal are ours [house]; no source states them.

- Good: kill an enemy (seconds), clear a wave (about a minute), survive N waves or beat a best (session).
- Bad: only "survive as long as you can", nothing in between.
- Mechanical check: tag each goal in code with expected duration; fail if a band is empty. Assert a goal string renders in the first scene.

## 4 Choices cost something and depend on the situation

Meier's criteria: each option has a cost, the best pick depends on the situation, players can choose differently, the result persists and shows, and enough information is available to decide. Always taking the first of three, or a purely random pick, is not interesting [4]. He also says complex decisions should not pile up and trivial ones do not belong in slow moments [4]. Randomness that replaces the choice is out; uncertainty in the outcome is fine [3][4][house]. The 3-per-10 s cap is ours.

- Good: fast ship with weak armour against slow ship with strong armour.
- Bad: three upgrades where one is strictly more of everything.
- Mechanical check: for each pick-one set, simulate each state and report any option that wins in all of them; in a 2 minute recording count non-trivial decisions per 10 s window.

## 5 Risk buys a reward the player can size up

Meier lists risk against reward as one criterion of an interesting decision [4]. Koster ties fun to uncertainty and progress in prediction [3]. Proportion and readability before committing are ours [house].

- Good: grazing bullets raises a score multiplier that a hit resets.
- Bad: a pickup guarded by a hazard but worth the same as a free one.
- Mechanical check: table of risky options against the safe baseline; payoff differs by a visible amount, and each risk has a telegraph or cue before the point of no return.

## 6 Growth meets a counter-force

Adams: positive feedback makes a slightly ahead player win every time, and it creates a fair but very short game when it starts too early; negative feedback keeps outcomes open, but too much produces stalemate [6]. The MDA paper shows it with Monopoly, where the leader grows richer as the rest fall behind [7]. RPGs compensate by raising enemy toughness [6]. Catch-up help for a trailing player belongs to difficulty.md.

- Good: kills raise fire rate while enemy density rises with it.
- Bad: every kill buffs the player permanently and enemy strength never moves; by minute three nothing threatens them.
- Mechanical check: list every stat that grows with play and its counter. In a no-new-threat scripted run, compare clear time of minute one and minute two; the second must not be clearly faster.

## 7 Replay comes from depth, not volume

Cook warns that chains of arcs form a content treadmill that fails when content stops [1]. Koster: a solved situation stops being fun, so situations must vary enough for theories to be tested and dropped [3]. In Cook's mastery model a skill's reward fades but it keeps value when it reaches further challenges; a skill nothing demands has burned out [2].

- Good: a seeded generator varies enemy mix and layout; the dash taught in wave one is needed to cross a gap in wave four.
- Bad: the same wave order every run, optimum memorised in two tries; a dash with no obstacle needing it.
- Mechanical check: ten runs with a seeded bot, compare spawn logs and score spread (identical logs mean a fixed script); for each skill, grep challenge definitions for a requirement.

## Numbers

| Value | What | Source |
| --- | --- | --- |
| 1 line | the loop written as do, answer, change | [1][house] |
| 10 s | first micro-goal complete and goal phrase visible | house |
| 3 per 10 s | most non-trivial choices at once | house |
| 0 | inputs with no response | house |
| 10 runs | seeded-bot sample for replay | house |
| about one third | design ideas Meier says he cut, "if not more" | [4] |

## Sources

1. Cook, "Loops and Arcs", Lost Garden, 2012. http://lostgarden.com/2012/04/30/loops-and-arcs/
2. Cook, "The Chemistry of Game Design" (skill atoms, burnout), Game Developer, 2007. https://www.gamedeveloper.com/design/the-chemistry-of-game-design
3. Koster, "Game design is simple, actually", raphkoster.com. https://www.raphkoster.com/?p=48717
4. Meier, "Interesting Decisions", GDC 2012, read through a trade-press write-up (secondary). https://www.gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions
5. Chen, "Flow in Games", MFA thesis, USC, 2006. https://www.jenovachen.com/flowingames/Flow_in_games_final.pdf
6. Adams, "Designer's Notebook: Positive Feedback", Gamasutra. https://gamedeveloper.com/design/designer-s-notebook-positive-feedback
7. Hunicke, LeBlanc, Zubek, "MDA: A Formal Approach to Game Design and Game Research", 2004. https://users.cs.northwestern.edu/~hunicke/MDA.pdf
