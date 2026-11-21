# UI pass

Part of every review cycle, and run after any direction that adds or changes a menu, HUD, dialog or overlay. A player who meets cramped spacing or a wall of information at once will call the game clunky however well it plays.

1. **Check output.** `pnpm check <app>` prints `ui layout` lines for overlap, clipping, minimum font size, target size and gap, a words-per-screen budget, and the crowding rules: duplicate phrases, controls legend, choice groups per screen, words per tile, locked items and font-size count. Fix every `ui layout` FAIL at its cause, never by editing a threshold; fix a crowding failure by deleting or moving content, not by shrinking it. Alignment only informs: judge it on the screenshot. A screen near its words budget is a candidate for the next step.
2. **Look at every screen.** Open `.verify/<app>/check/ui/screens.png` first, every screen the check reached on one sheet, then each shot behind it (title, playing, pause, game over, settings, every overlay), and read them as a first-time player. The check reaches only the screens its bots pass through; open the others (a shop, a pick step, an overlay) yourself with `pnpm shot` or the app's URL parameters. Name what you see at once; if that is more than the screen's primary action plus the few things needed to take it, something is too early.
3. **Progressive disclosure.** One primary action per screen, visually the strongest. Detail (controls list, settings, credits, stats breakdown, help) sits behind a button, tab or submenu, and the screen offers a way back. Apply these rules:
   - **One decision per screen.** Name the decision each screen asks; a second one moves to its own step or to the moment it matters. Remember the last choices so repeat runs cost one click.
   - **Icons in the grid, detail on focus.** A grid shows icons and at most a short name; only the focused item shows detail, in one panel.
   - **Say each fact once.** A name, role, cost or key shown on a tile is not repeated in the detail panel.
   - **Hide what is locked.** Show no locked items, or one "?" tile for the next unlock.
   - **No controls legend.** Show a key as a transient prompt the first time it matters, and keep one Controls button on title and pause.
   - **HUD in two tiers.** At most 5 groups always on screen, what a decision needs every second; everything else appears on change and leaves.
4. **One spacing scale.** Pick a base step (for example 8 px) and use only its multiples for padding, gaps and margins; one scale for type sizes too. Controls get room to breathe and touch targets stay large enough with a gap between them.
5. **If `ui-polish` is installed**, run it on the DOM screens (menus, HUD, overlays) at desktop width, and at phone width only when the user asked for mobile (then also `pnpm check <app> --mobile`); it screenshots, checks the visual checklist and fixes styles. Its findings count as review findings. If it is missing, steps 1 to 4 stand alone.
6. **Remove one thing.** Name one element, option or screen that a player would not miss and remove it or move it behind a button. Nothing worth removing is a valid answer only when said with the screens checked.
7. **Log it.** A cycle that changes UI says so in its `## Cycles` line. A finding becomes a direction; a UI pass that finds nothing is part of a dry review, with the screens checked named in the entry.
