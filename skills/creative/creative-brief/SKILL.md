---
name: creative-brief
description: Turns an idea for an animated experiment, visual scene or interactive visual into a treatment with a "Not this" list, before any code. Use when starting a creative experiment, a technique demo or a landing-page visual, when asked for a treatment, palette, camera or input mapping, or when agents keep drifting to default looks.
metadata:
  scope: personal
---

# Creative Brief

One treatment gives every agent the same creative intent. The output is engine-neutral: no engine, library or API names.

## Steps

1. **Read the idea.** Take it as given; read any existing `TREATMENT.md` or `AGENTS.md` in the target folder and extend them. Ask only what you cannot infer: where it is shown, on what device, how long it runs, whether sound is involved. Done when you can state the experiment in two sentences.
2. **Write the treatment.** Use [references/treatment-template.md](references/treatment-template.md). Sections: idea, palette (hex with a role each, three to six colors), camera, input mapping (including what happens with no input, and the reduced-motion behavior), and "Not this". Done when no placeholder text remains.
3. **Write the "Not this" list with care.** At least five concrete items, each a look or behavior an agent would otherwise default to (a generic gradient, a bouncy ease, a vignette on everything). Done when each item could be checked by looking at a frame.
4. **Stub the engine doc.** Write `ENGINE.md` from [references/engine-template.md](references/engine-template.md) with the perf budget filled and the file map empty. For a folder with its own pitfalls, add a nested `AGENTS.md` from [references/agents-template.md](references/agents-template.md) and a `CLAUDE.md` containing `@AGENTS.md`. Done when the budget is stated.
5. **Hand over.** Show the palette and the "Not this" list first, then ask for approval. Do not start building. Done when the user has approved or listed changes.

## Rules

- Write `TREATMENT.md` and `ENGINE.md` in the experiment's folder; follow the repo if it names them differently.
- A frame of the experiment must be a function of time and input only; say so in the treatment when the experiment is to be recorded or compared.
- No engine-specific content; keep each file to one screen.
