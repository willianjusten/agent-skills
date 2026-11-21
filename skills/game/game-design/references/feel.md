# Feel

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [feel-deep.md](feel-deep.md).

1. **Respond on the same frame.** The first visible or audible change from an input lands on the frame it is read, or the next. Precise, short-deadline actions (dodge, parry, jump) get the tightest budget; menus may take about 6 frames. Break when: a charged or heavy action; the wind-up itself still reacts at once. Check: frames from input read to first change is 0 or 1. [3][4][5][house]

2. **Scale feedback by importance, in layers.** Frequent events get small feedback, rare ones big, with a ceiling on the biggest. Important events get motion, a mark and a sound, cheapest first (flash, count-up, particles, squash, nudge, shake, hit-stop). Break when: a rare event is meant to be quiet. Check: order events by frequency; reaction size runs the opposite way, and one channel alone still reads. [1][2][4]

3. **Hit-stop freezes both sides, capped.** Freeze attacker and target for the same short time, longer for stronger hits: 1-2 ticks light, 2-6 heavy, a hard cap above. Hit and hurt boxes keep their positions. Break when: hits land many times a second; freeze kills only, or skip. Check: count frozen frames per hit class; stacked freezes never pass the cap. [2][house]

4. **Shake is trauma, not an offset.** Keep trauma in 0 to 1; events add 0.2 to 0.5, it decays linearly, shake is trauma squared or cubed, driven by smooth noise over time. 2D: rotate and translate; 3D: rotate only. Break when: close first-person or VR. Check: zero shake at zero trauma, trauma clamped, a graze and a kill clearly differ. [1][house]

5. **Follow the player with a weighted camera.** Move a fraction of the remaining distance per frame, scaled by time scale: 0.1 is fast, 0.01 slow at 60 fps. The player never leaves the screen. Break when: precision play; use a dead zone. Check: time scale 0 freezes the camera; no overshoot on a stop. [1]

6. **Ease it, deform only the look.** Reactions and arrivals ease out; no wind-up delays a response the player has pressed. Squash and stretch the drawing, never the collider. Check: a frame strip shows fast start and slow end; the collider is not scaled. [3][4][house]

7. **Juice never hides play.** Particles are short and local, with a live cap and a lifetime. Static menus get calm presses, never flash or shake. Break when: the effect is the information; shrink it and add a second cue. Check: in the busiest 5 s, find the player and nearest threat in under a second. Flash limits and reduced-motion: accessibility.md; noise budget: play-field.md rule 6. [1][7][house]
