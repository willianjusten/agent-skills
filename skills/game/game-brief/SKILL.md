---
name: game-brief
description: Turns a game concept into a GDD, a treatment and an art bible with asset levels, before any code. Use when starting a new game, when scope is unclear, when asked for a GDD, game design doc, pillars, core loop or cut list, or before breaking a game into tickets.
metadata:
  scope: personal
---

# Game Brief

Scope is decided here, in files, before building. The output is engine-neutral: no engine, library or API names, so the files carry over to another engine unchanged.

## Steps

1. **Read the concept.** Take the user's idea as given; read any existing `TREATMENT.md`, GDD or `AGENTS.md` in the target folder and extend them instead of overwriting. Ask only what you cannot infer: who plays, on what device, how long a session lasts. Done when you can state the concept in two sentences.
2. **Write the GDD.** Use [references/gdd-template.md](references/gdd-template.md). Every section gets content; a section you cannot fill becomes a question to the user. Pillars at most three. The cut list is ordered. Non-goals name tempting features. Done when a scripted playtest could assert win, lose and score from the text.
3. **Write the treatment.** Use [references/treatment-template.md](references/treatment-template.md). Palette entries are hex with a role. The "Not this" list has at least five concrete items. Done when no placeholder text remains.
4. **Write the art bible.** Use [references/art-bible-template.md](references/art-bible-template.md). Palette matches the treatment. Fill the asset-level table for every asset type the GDD needs: level (`placeholder`, `free`, `premium`) and polish (`rough`, `polished`). Default to `placeholder` and `rough`; set `premium` only if the user asks, and note it is locked until they unlock it. Leave sign-off empty. Done when every asset type in the GDD has a row.
5. **Stub the engine doc.** Write `ENGINE.md` from [references/engine-template.md](references/engine-template.md) with the perf budget filled and the file map empty. When a folder will have its own pitfalls, write a nested `AGENTS.md` from [references/agents-template.md](references/agents-template.md), plus a `CLAUDE.md` containing `@AGENTS.md`. Done when the budget is stated.
6. **Hand over.** Show the user the cut list, non-goals and asset levels first, then ask for approval and the art bible sign-off. Do not start building or generating assets. Done when the user has approved or listed changes.

## Rules

- Write files in the app's folder (`GDD.md`, `TREATMENT.md`, `ART-BIBLE.md`, `ENGINE.md`); if the repo already names them differently, follow it.
- No engine-specific content in the GDD, treatment or art bible: say "fixed-step simulation", not a class name.
- Keep each file to what an agent needs; no marketing prose.
- If a skill for slicing the GDD into tickets is installed, offer it as the next step; otherwise list the first three slices yourself.
