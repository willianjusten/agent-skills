# Profile: game

Used when the adapter's `profile` is `game` (lab: an app under `apps/games/`). It adds the game rules to steps 5, 7 and 8 of the skill.

## Each direction

- When a direction adds a gameplay event, give it a sound and feedback the `game-feel` way.
- When it adds something the player sees, name in its cycle line the screen it lives on and what it moved behind a button to make room; a screen only grows when something else leaves it.

## Review cycle

Check the fresh shots in the order of `game-design` "Reviewing a build" (each finding names its rule), then name the three weakest things a player would notice and one thing to remove or simplify (a feature, option, screen element or HUD group that costs more attention than it gives). Run the UI pass ([ui-pass.md](ui-pass.md)) with its game rules: read `.verify/<app>/check/ui/screens.png` (every screen on one sheet) and the shots behind it, fix every `ui layout` FAIL, and hold each screen to `game-design` `references/ui-ux.md`.

## Hand-off

The summary's **Play it** links include the start, `?demo=1` and `?tune`, and it has a **Controls** section. The run-article frame is one demo second that shows play, not a menu.
