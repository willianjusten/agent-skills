---
name: game-feel
description: Adds game feel (juice) to a game, meaning hit-stop, screen shake, easing, particles, UI feedback and a sound for every gameplay event, with the lab's audio mixer, synth recipes and music sequencer. Use when a game works but feels flat or silent, when asked to add juice, polish feel or add sound effects or music, when a gameplay event is added or changed, or when a check reports an event with no sound.
metadata:
  scope: personal
---

# Game Feel

A game with correct rules and no feedback reads as unfinished, and silence is the loudest tell. Give every gameplay event a sound and a visible reaction, list them in one event map a test can check, and tune in the order the player experiences them.

## Steps

1. **Diagnose before tuning.** Name which of three things is wrong, and fix them in this order: response (input to visible reaction is fast and certain: same frame, no dropped input), then clarity (the player can tell what happened and what matters: events are distinct, the important one is loudest and biggest), then satisfaction (weight, juice, polish). Tuning satisfaction on top of a slow or unclear game hides the problem. Done when you can state the first failing layer.
2. **List the events.** Read the simulation and write down every gameplay event the player causes or suffers (pickup, hit, death, win, score change, level start). Done when each event has a stable name and the simulation appends it to its state as plain data.
3. **Write the event map.** One row per event: sound, feedback, strength. Mirror it in code as a record keyed by event name (`EVENT_MAP` with `EventFeel` from `@lab/game`), so a new event without an entry fails the type checker. Done when no event is missing a row; "no sound" is a row with a reason.
4. **Pick the feedback** from [references/juice-checklist.md](references/juice-checklist.md): the cheapest that reads at a glance first, more layers only if it still feels flat. Done when each row names a visual or motion reaction.
5. **Add the sounds** with `@lab/audio`, no samples. Start from `STARTER_SOUND_EVENTS` (20 recipes with bus, priority, cooldown, voice cap, duck, pitch variance and a target peak), copy the rows the game needs into `src/sounds.ts` with `defineSoundEvents`, and tune; the rows are untuned by ear. Write a new sound as a recipe of tone and noise layers. Levels, recipes and music rules are in [references/audio.md](references/audio.md). Done when each mapped sound has a row.
6. **Wire it once.** One mixer on a live `AudioContext` with `gestureTarget: window` (audio stays locked until the first key or pointer press). The renderer reads new events and looks each up in the map (`createEventFeed`, `applyFeedback`); no per-event code in the loop. Pass `gameTime` on every `mixer.play` so `check` can replay the run. Music is a sequencer on the mixer (`createSequencer`), its intensity set from game state. Time reactions in simulation ticks, not frame time. Done when playing the game fires every mapped sound and reaction.
7. **Check and listen.** `pnpm check <app>` fails an event that never fires, one that dominates, clipping, DC offset and a clicking loop, and reports loudness; fix each line by editing the row, not the threshold. Then `pnpm record <app>` and read the contact sheet for the reactions. Done when `check` exits 0 and each reaction is visible.

## Rules

- Every event gets a sound. "No sound" is a decision recorded in the map with a reason, not an omission.
- Frequency sets the mix: the most frequent sound is the quietest and shortest, rarer and more important events are louder and fuller.
- Feedback scales with importance: frequent events small, rare events big.
- Never block input or change simulation outcomes with a reaction; feel is presentation.
- Honour reduced-motion settings for shake and flashes.
- UI feedback (menus, HUD, buttons) stays calm: a press, hover and focus reaction per control, a count-up or pulse on a changed number, never a flash or shake on a static menu. Show only what the player needs this second; detail sits behind a button or submenu, so juice never piles onto a crowded screen.
