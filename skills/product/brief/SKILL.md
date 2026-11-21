---
name: brief
description: Writes a one-page BRIEF.md for a game or animated experiment before any code, with promise, pillars, loop or treatment, screens, Not this list, done condition, cut list, a feature list with a check per feature, demo mode, look direction and an ordered next-directions list. Use when starting a game or creative experiment, when scope is unclear, when asked for a brief, GDD, treatment, pillars, cut list or feature list, or when agents keep drifting to default looks.
metadata:
  scope: personal
  uses: game-design
---

# Brief

One page that tells every agent what to build, what not to build and how to know it is done. Engine-neutral: no engine, library or API names.

## Steps

1. **Read the input.** Take the idea or an approved `PITCH.md` as given; read any existing `BRIEF.md` or `AGENTS.md` in the target folder and extend it. Infer the mode: game (has failure and a loop) or experiment (a feeling and a response to input). Ask only what you cannot infer: who plays or watches, on what device, for how long, with or without sound. Done when you can state the idea in two sentences.
2. **Write the brief.** Use [references/brief-template.md](references/brief-template.md) and save `BRIEF.md` in the app's folder. Every section gets content; a section you cannot fill becomes a question to the user, and a section that does not apply to the mode says `n/a`. Done when no placeholder text remains and it fits one page.
3. **Check the testable parts.**
   - Pillars: three at most, each checkable against a decision.
   - Loop (games): one line naming what the player does, what the game answers and why they do it again, plus a goal at each of three time scales (`game-design` `references/loop.md` rules 1 and 3).
   - Screens: every screen has exactly one primary action and asks one decision; what is shown at once is at most 5 named items, and the rest (settings, controls list, stats, help) sits behind a button or submenu. Locked items are hidden until available, and each row says where controls help lives. A screen with two decisions, two primary actions, a wall of text or no controls help location is rewritten.
   - Not this: five or more concrete items, each checkable by looking at a frame.
   - Done condition: a statement a script or a screenshot can confirm, not "feels good".
   - Cut list: ordered, first cut first.
   - Feature list: every promised feature has a check, written as a lab `pnpm check <app>` line or a sentence a scripted run can assert from a fresh start, and names the screen it is shown on and what it displaces there. A feature with no check is not a feature yet; one that only adds to a full screen is cut or moved.
   - Demo mode: what the app does with no input, so a recorder sees a full loop.
   - Next directions: a plain ordered markdown list (`1. ...`), one direction per line, most valuable first, no nested bullets. A loop reads this list line by line.
   Done when each item passes.
4. **Hand over.** Show the promise, Not this, cut list and feature list first and ask for approval or changes. Do not start building. Done when the user has approved or listed changes; then rewrite the sections they touch.

## Rules

- Follow the repo's file names if it already names them differently.
- A frame of an experiment is a function of time and input only; say so when it is to be recorded or compared.
- No marketing prose; keep to what an agent needs.
- Look direction names the look in words and hex roles (three to six colors); a named-looks list is optional and, when present, one line per look with the one to start from marked.
