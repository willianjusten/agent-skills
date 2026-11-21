---
name: game-design
description: Game design handbook by topic, read on demand - core loop, difficulty and pacing, the first minute, play-field readability, menus and HUD, in-game copy, juice and feel, music and sound effects, and accessibility - each a short rules file with numbers and checks, plus a detail file with examples and sources. Use when designing, building or reviewing a game or a game screen, when a game feels flat, unfair, confusing, noisy or boring, when players quit early or a HUD or menu looks busy, when tuning a wave table or difficulty curve, when choosing telegraph times, wave pacing, HUD layout, button labels, captions, hit-stop, screen shake or music structure, when planning a tutorial or first minute, when listing accessibility options, or when a build review needs design checks.
metadata:
  scope: personal
---

# Game Design

A handbook, not a procedure: rules for what makes a game clear, fair and worth replaying, with the numbers and checks a build can be held to. The base model knows the principles; these files carry the defaults it skips when nobody asks.

## Rules for every use

1. **Read one rules file per question.** Pick it from the table. Open its `-deep` file only when a rule doesn't settle the case or you need the numbers table, examples or sources. A review that spans topics reads each topic it flags, one at a time.
2. **The brief's look wins over style.** No rule here sets colour, palette, bloom or art direction. Readability of the player and of danger is the one exception, and it is fixed with contrast, placement or timing, never by toning the look down.
3. **Rules are defaults.** Break one when its "Break when" applies and note it in the log. Checks report misses; only rules marked **blocks** stop a run.
4. **Tags.** `[n]` points to the detail file's sources; `[house]` is a rule or number of ours, set by playtest, not by a source.

## Pick the file

| Question | Rules | Detail |
|---|---|---|
| Why keep playing? Goals, choices, replay | [loop.md](references/loop.md) | [loop-deep.md](references/loop-deep.md) |
| Too hard, too easy, unfair, waves and bosses, retry | [difficulty.md](references/difficulty.md) | [difficulty-deep.md](references/difficulty-deep.md) |
| First minute, tutorial, title to play, hints | [onboarding.md](references/onboarding.md) | [onboarding-deep.md](references/onboarding-deep.md) |
| Can the player see themselves and the danger? Telegraphs, banners, effect noise | [play-field.md](references/play-field.md) | [play-field-deep.md](references/play-field-deep.md) |
| Menus, screens, focus, HUD layout | [ui-ux.md](references/ui-ux.md) | [ui-ux-deep.md](references/ui-ux-deep.md) |
| Words: labels, captions, game-over text | [copy.md](references/copy.md) | [copy-deep.md](references/copy-deep.md) |
| Hits feel weak, input feels slow: hit-stop, shake, easing, particles | [feel.md](references/feel.md) | [feel-deep.md](references/feel-deep.md) |
| Music, sound effects, mix | [sound.md](references/sound.md) | [sound-deep.md](references/sound-deep.md) |
| Options to ship: flashes, shake, colour, remapping, text size | [accessibility.md](references/accessibility.md) | [accessibility-deep.md](references/accessibility-deep.md) |

Also for experiments (animated pieces, not games): ui-ux, copy and sound.

## Reviewing a build

When asked to review a build or a cycle without a named topic, check in this order and stop reading a file once its rules are checked:

1. play-field (blocks first: player covered, danger unreadable)
2. onboarding, then difficulty (retry cost, telegraphs, pacing)
3. copy and ui-ux on every screen shown
4. feel and sound on every gameplay event
5. loop, when the session ends early or replay is in question
6. accessibility, before a release

Report each miss as: rule file and number, what you saw, the fix.
