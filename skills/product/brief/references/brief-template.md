# Brief template

Save as `BRIEF.md`. One page, engine-neutral.

```markdown
# <Working title>

**Mode:** game | experiment
**Promise:** <one sentence: what the player or viewer gets and feels>

## Pillars
<three or fewer, each a sentence a decision can be checked against>

## Core loop (game) / Treatment (experiment)
<game: the 10-second loop (action, feedback, reward), then how a run starts and ends>
<experiment: what it is, camera, motion character, and what each input moves>

## Controls
<input to action for keyboard, pointer and touch; for an experiment also no input and reduced motion>

## Screens
| Screen | Decision it asks | Shown at once | Behind a button | Hidden until available | Controls help |
| ------ | ---------------- | ------------- | --------------- | ---------------------- | ------------- |
| <title, play, pause, game over, ...> | <exactly one decision; its primary action> | <at most 5 named items> | <settings, controls, records> | <locked or unmet items> | <taught in play at first use, or the Controls button> |

## Not this
<five or more concrete defaults to avoid, each checkable in a frame>

## Done condition
<win, lose and score for a game, or the end state or loop length for an experiment, stated so a script can confirm it>

## Cut list
1. <first cut>
2.
3.

## Features
| Feature | Check | Shown on |
| ------- | ----- | -------- |
| <feature> | `pnpm check <app> --<assertion>` or a scripted-run sentence | <screen or HUD it appears on, and what it pushes behind a button there; "none" when it is felt, not shown> |

## Demo mode
<what runs with no input, and how long one full loop takes>

## Look direction
<the look in words; palette as hex with a role each; camera and lighting feel>
Optional named looks, one line each, starting one marked:
- <look name>: <one line> (start here)

## Next directions
1. <most valuable direction>
2. <next>
3. <next>
```
