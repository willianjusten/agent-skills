# UI and UX

The brief's look direction wins over every rule here except readability of the player and of danger. Fix readability with contrast, placement or timing, never by toning the style down.

Rules are defaults: break one when its "Break when" applies and say so in the log. A check reports a miss; only **blocks** rules stop a run. Numbers, examples, sources: [ui-ux-deep.md](ui-ux-deep.md).

1. **Play in two activations.** From the title, a first-time player reaches play in 1 activation (onboarding.md rule 5), a returning player in at most 2. Play has focus; the last setup is the default. Break when: the loadout is the game. Check: script title to first gameplay frame, count activations. [1][2][3][4][house]

2. **One decision per screen.** Name the question; give one strongest action. A second decision gets its own screen. Grids show icons and a short name; only the focused item shows detail, once. Hide locked items. Settings, controls and stats sit behind a button. Break when: one coupled choice (hero plus weapon). Check: more than one selection group outside a shop is a miss. [2][4][house]

3. **Back is everywhere, the same.** Every submenu offers back on one input (Esc, B), its prompt in the same corner. Break when: a forced modal. Check: Esc from each screen goes up one level. [5][6]

4. **Focus is always visible.** Exactly one control has focus, never clipped or covered; a screen opens focused on its primary action. Directions land on the visual neighbour. Lists wrap; grids stop at edges. Break when: pointer-only touch. Check: direction-walk every screen; zero or two focused is a miss. [5][7][8][9][10]

5. **Single presses reach everything.** Keyboard and pad reach every control, sliders included, one press at a time. Targets 44 by 44 CSS px, never under 24, with a gap. Break when: an analog mechanic; add a digital path. Check: title to settings by keyboard only. [1][6][11][12][house]

6. **Prompts: few, contextual, fixed.** One to three per screen, fixed corner, the device's symbols. Teach a key near its target on first use. No permanent legend; one Controls entry. Check: over 3 hints on a menu, or a permanent legend in play, is a miss. [2][5][6][13][house]

7. **HUD in two tiers.** Always on: at most 5 groups, only what changes a decision each second; the rest appears on change, then leaves. Persistent items sit at the edges inside the safe area; urgent timed items near the eye-line, as glyph or bar. Exact numbers only when acted on. Check: cover the HUD with a hand; name what you would miss. [1][6][14][15][16][17][house]

8. **Pause, settings, game over.** One input opens and closes pause, focus on Resume, four entries (five with Restart). Settings save without a step, two levels deep at most. Game over shows the result and one or two numbers, focuses Retry, Menu second, auto-advances nothing. Check: reload keeps settings; count activations from game over. [3][6][11][18][19][house]

Wording: copy. Banners in play: play-field.md rule 5. Text size: accessibility.
