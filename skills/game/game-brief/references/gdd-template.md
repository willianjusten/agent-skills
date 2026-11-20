# <Title> GDD

## Pillars

Three or fewer. Each is a sentence a design decision can be checked against.

## Core loop

The 10-second loop: action, feedback, reward, repeat. Then the session loop (how a run starts and ends).

## Controls

Table of input to action, for keyboard, pointer and touch. Mark which are held and which are taps.

## Scope

What ships: modes, levels or arenas, enemies or hazards, session length. Give a number for each.

## Cut list

Ordered list of what goes first if time runs out, with the first item cut first.

## Non-goals

What this game deliberately is not. Each entry names a tempting feature and why it is out.

## Win, lose and score

The end conditions and how a run is measured, so a scripted playtest can assert on them.

## Feature list

One row per feature the pitch promises: feature, the pitch line it comes from, and its check (a sentence a scripted playtest can run from a fresh run, for example "after collecting 3 pickups the score reads 3"). A feature with no check is not a feature yet.

| Feature | Pitch line | Check |
| ------- | ---------- | ----- |

## Balance band

The numbers a seeded bot should land on over many runs, so "too easy" and "dies standing still" are numbers. Give each as a range, or write "n/a" with the reason when the game has no such thing.

| Measure | Band |
| ------- | ---- |
| Win rate of a simple bot policy (percent) | |
| Round or wave a typical run ends on | |
| Does a player who does nothing survive the first round (yes or no) | |

## Audio event map

One row per gameplay event with the sound that plays: event, sound, source.
