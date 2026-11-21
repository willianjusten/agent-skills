# UI pass

Part of every review cycle, and run after any direction that adds or changes a menu, HUD, dialog or overlay. A player who meets cramped spacing or a wall of information at once will call the game clunky however well it plays.

1. **Check output.** `pnpm check <app>` prints `ui layout` lines for overlap, clipping, minimum font size, target size and gap, and a words-per-screen budget. Fix every `ui layout` FAIL at its cause (move, shrink or hide the element), never by editing a threshold. Read the INFO lines too, including the `ui layout` lines for duplicate phrases, controls legend, choice groups per screen, words per tile, locked items and font-size count: act on each like a failure and fix it by deleting content, not by shrinking it. A screen near its words budget is a candidate for the next step.
2. **Look at every screen.** Open each shot under `.verify/<app>/check/ui/` (title, playing, pause, game over, settings, every overlay) and read it as a first-time player. Name what you see at once; if that is more than the screen's primary action plus the few things needed to take it, something is too early.
3. **Progressive disclosure.** One primary action per screen, visually the strongest. Detail (controls list, settings, credits, stats breakdown, help) sits behind a button, tab or submenu, and the screen offers a way back. Apply these rules:
   - **One decision per screen.** Name the decision each screen asks; a second one moves to its own step or to the moment it matters. Remember the last choices so repeat runs cost one click.
   - **Icons in the grid, detail on focus.** A grid shows icons and at most a short name; only the focused item shows detail, in one panel.
   - **Say each fact once.** A name, role, cost or key shown on a tile is not repeated in the detail panel.
   - **Hide what is locked.** Show no locked items, or one "?" tile for the next unlock.
   - **No controls legend.** Show a key as a transient prompt the first time it matters, and keep one Controls button on title and pause.
   - **HUD in two tiers.** At most 5 groups always on screen, what a decision needs every second; everything else appears on change and leaves.
4. **One spacing scale.** Pick a base step (for example 8 px) and use only its multiples for padding, gaps and margins; one scale for type sizes too. Controls get room to breathe and touch targets stay large enough with a gap between them.
5. **If `ui-polish` is installed**, run it on the DOM screens (menus, HUD, overlays) at phone and desktop width; it screenshots, checks the visual checklist and fixes styles. Its findings count as review findings. If it is missing, steps 1 to 4 stand alone.
6. **Log it.** A cycle that changes UI says so in its `## Cycles` line. A finding becomes a direction; a UI pass that finds nothing is part of a dry review, with the screens checked named in the entry.
