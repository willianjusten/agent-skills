# Brief

Writes a one-page brief for a game or experiment before any code.

## What It Does

| Phase | Output |
| ----- | ------ |
| Read | Mode and the idea in two sentences |
| Write | `BRIEF.md`: promise, pillars, loop or treatment, controls, Not this, done condition, cut list, features with checks, demo mode, look, next directions |
| Check | Testable pillars, Not this, done condition, a check per feature, an ordered next-directions list |
| Hand over | User approval before building |

## Usage

```text
Write a brief for a one-button arcade game about a lighthouse keeper
Make a brief for an experiment about fog reacting to the pointer
What should I cut from this game idea?
```

## Output

`BRIEF.md` in the app folder.

## FAQ

- Does it write an art bible or engine doc? No; the brief holds only the look direction.
- What reads the next-directions list? A loop can take it as its direction queue.
