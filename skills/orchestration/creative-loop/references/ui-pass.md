# UI pass

Part of every review cycle, and run after any direction that adds or changes a menu, HUD, dialog or overlay. A player who meets cramped spacing or a wall of information at once will call the game clunky however well it plays.

1. **Check output.** `pnpm check <app>` prints `ui layout` lines for overlap, clipping, minimum font size, target size and gap, and a words-per-screen budget. Fix every `ui layout` FAIL at its cause (move, shrink or hide the element), never by editing a threshold. Read the INFO lines too: a screen near its words budget is a candidate for the next step.
2. **Look at every screen.** Open each shot under `.verify/<app>/check/ui/` (title, playing, pause, game over, settings, every overlay) and read it as a first-time player. Name what you see at once; if that is more than the screen's primary action plus the few things needed to take it, something is too early.
3. **Progressive disclosure.** One primary action per screen, visually the strongest. Detail (controls list, settings, credits, stats breakdown, help) sits behind a button, tab or submenu, and the screen offers a way back. The HUD during play shows only what a decision needs right now; the rest opens on demand or on pause.
4. **One spacing scale.** Pick a base step (for example 8 px) and use only its multiples for padding, gaps and margins; one scale for type sizes too. Controls get room to breathe and touch targets stay large enough with a gap between them.
5. **If `ui-polish` is installed**, run it on the DOM screens (menus, HUD, overlays) at phone and desktop width; it screenshots, checks the visual checklist and fixes styles. Its findings count as review findings. If it is missing, steps 1 to 4 stand alone.
6. **Log it.** A cycle that changes UI says so in its `## Cycles` line. A finding becomes a direction; a UI pass that finds nothing is part of a dry review, with the screens checked named in the entry.
