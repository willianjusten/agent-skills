---
name: game-feel
description: Adds game feel (juice) to a game, meaning hit-stop, screen shake, easing, particles, UI feedback and a sound for every gameplay event. Use when a game works but feels flat or silent, when asked to add juice, polish feel or add sound effects, when a gameplay event is added or changed, or when a playtest reports an event with no sound.
metadata:
  scope: personal
---

# Game Feel

A game with correct rules and no feedback reads as unfinished, and silence is the loudest tell. Give every gameplay event a sound and a visible reaction, and list them in one event map that a test can check.

## Steps

1. **List the events.** Read the simulation and write down every gameplay event the player causes or suffers (pickup, hit, death, win, score change, level start). Done when each event has a stable name and the simulation records it as plain data, so a script can read it.
2. **Write the event map.** One row per event: its sound, its feedback, and how strong it is. Keep it in the game's treatment document and mirror it in code as a record keyed by event name, so a new event without an entry fails the type checker. Done when no event is missing a row.
3. **Pick the feedback from the checklist** in [references/juice-checklist.md](references/juice-checklist.md). Start with the cheapest that reads at a glance; add layers only when the playtest still feels flat. Done when each row names at least one visual or motion reaction.
4. **Add the sounds.** Sound effects are generated with ZzFX: a parameter array per sound, kept as plain data in its own module so tests can read it without audio. Music and any recorded sound must be CC0 or credited. Record every audio asset in the app's manifest with its license, per the asset rules of the project. Done when each mapped sound has parameters and a manifest entry.
5. **Wire it once.** The renderer reads new events from the state and looks each up in the map; no per-event code in the render loop. Browsers keep audio locked until a gesture, so unlock it on the first key or pointer press. Time the reactions in simulation ticks, not frame time, so scripted captures stay repeatable. Done when playing the game fires every mapped sound and reaction.
6. **Test the map.** Add a unit test and a playtest check that fail when a mapped event has no sound parameters or an emitted event has no map entry. Done when removing one sound makes both fail.
7. **Check the feel and the budget.** Play it. Keep sound and reaction strong enough to notice and short enough not to hide the next event; keep the project's frame and size budgets. Update reference captures only after looking at the new frame.

## Rules

- Every event gets a sound. "No sound" is a decision recorded in the map with a reason, not an omission.
- Feedback scales with importance: frequent events get small reactions, rare events get big ones.
- Never block input or change simulation outcomes with a reaction; feel is presentation.
- Honour reduced-motion settings for shake and flashes.
