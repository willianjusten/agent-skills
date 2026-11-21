# Accessibility

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [accessibility-deep.md](accessibility-deep.md).

Ranked cheapest first; each rule carries its tier. Contrast numbers: play-field.md rule 3. Caption length: copy.md.

1. **One saved settings screen.** Basic. Reachable from the menu and pause; holds master, music and effects volume (0 to 100, mute on a key), plus every option below. Persist to `localStorage` in try/catch and apply before the first frame. Why: players set up once. Break when: storage fails; fall back to defaults. Check: change, reload, values match. [7][9]

2. **Pause works anywhere.** Basic. Esc or P, gamepad Start and a visible button pause in every state, and on `visibilitychange` or blur. Time and audio stop. Break when: real-time multiplayer. Check: send the key in each state; dt is zero. [8][14][house]

3. **Colour never carries meaning alone.** Basic. Pair every colour code with shape, pattern, icon or label. Why: about 8 to 10% of males have red or green difficulty. Break when: purely decorative. Check: run a colour-blindness simulation on a screenshot; hazards still differ by shape (danger itself: play-field.md rule 2). [3][13]

4. **Cap flashes.** Basic. At most 3 flashes per second, general and red counted separately; a flash is a 10% luminance swing. Keep a cooldown on hit flashes, no full-screen strobes, no tight stripe patterns or full-screen scanlines. Break when: never. Check: log mean canvas luminance for the worst effect; count swings per 1000 ms. [2][10][house]

5. **Shake and motion are adjustable.** Basic. A 0 to 100% slider scales shake, blur and flash; read `prefers-reduced-motion` once for the first-run default (shake low, parallax and decoration off). Why: motion sickness. Break when: motion is the mechanic; reduce decoration only. Check: slider at 0 gives zero camera offset; emulate reduce. [5][11][15][16][house]

6. **Text has a floor.** Basic default, advanced scaling. Required text at least 18 px at 1080p (28 px for living-room screens); never baked into images. Offer 100 to 200% scaling. Break when: copyright or debug lines. Check: measure rendered ascender-to-descender height. [4][12]

7. **Input is remappable and forgiving.** Intermediate. Bind actions, not keys, and show the live label. Keyboard-only path for menus and play. Hold actions get a toggle option; holds stay under 3 s; no essential gestures or two-button chords; target sizes: ui-ux.md rule 5. Break when: press-down is the mechanic. Check: finish a run on keyboard only; remap one key and no old binding remains. [1][6][14][house]

8. **Assists change during play.** Intermediate. Offer one or two: speed multiplier, extra health or lives, wider timing windows. Reachable from pause, effective without a restart. Break when: a puzzle with no fail state; offer undo or skip. Check: toggle mid-run; behaviour changes next frame. [1][8][house]
