---
name: three-build
description: Builds games and creative pieces in the lab monorepo on three.js WebGPURenderer. Use when adding or changing an app, example, game or piece in the lab repo, scaffolding from the game or experiment template, writing the renderer setup or loop, or sizing a perf budget.
metadata:
  scope: personal
---

# Three Build

Apps in the lab monorepo share one renderer bootstrap, loop and template set. Build on those; do not rebuild them per app.

## Steps

1. **Find the lab.** It is the checkout whose root `package.json` is named `lab`, with `packages/core`, `packages/verify` and `templates/`. Work from the current directory if it is one; otherwise ask the user where it is. Read its `README.md` and `AGENTS.md` before anything else; they win over this skill where they differ. Done when you can name the commands the README lists.
2. **Pick a template.** Run `pnpm create-app` with no arguments to list templates. A game with simulation and input uses `game`; a visual piece or a technique example uses `experiment`; `basic` is the bare minimum. Done when the template choice matches the brief's kind of work.
3. **Scaffold, never copy.** Run `pnpm create-app <template> <name> [games|pieces|examples]`. A hand-copied folder skips token replacement and the gallery manifest. Done when `apps/<category>/<name>` exists and is not yet edited.
4. **Read the app's docs.** `TREATMENT.md` states creative intent and a "Not this" list; `ENGINE.md` holds the file map, rules and perf budget. Fill the stubs for a new app; keep `ENGINE.md` current when the file map or rules change.
5. **Build in vertical slices.** Rules in "Renderer and loop" below. Write shaders and materials as TSL node materials, never GLSL, using the TSL docs linked below. Done when `pnpm typecheck` passes for the app.
6. **Verify.** Run `pnpm verify <app>` from the lab root and fix every failing gate. The work is not done until it prints PASSED.

## Renderer and loop

- Import from `three/webgpu` (and `three/tsl`), never bare `three`. Renderer is `WebGPURenderer`, which falls back to WebGL 2 by itself.
- Use the core package (`@lab/core`): `startApp` for a plain app, `startExperiment` for a seekable piece. Read `packages/core/src` for the current exports; do not write your own renderer, resize handling or `requestAnimationFrame` loop. An app that bypasses core never publishes `window.__lab`, and the first-frame gate fails.
- Games: simulation is a pure, seeded, fixed-timestep module with no three or DOM imports and a Vitest test; rendering only reads its state. `window.__game` stays behind `import.meta.env.DEV`.
- Experiments: a frame is a pure function of the seekable time. No clock reads, `Math.random` or frame deltas inside it.
- Build a hard effect alone on the template's lab route first, then port it into the main app.
- Honour `prefers-reduced-motion`.

## Perf habits

- Budgets are hard gates (fps, first frame, JS and asset size); read `packages/verify/gates.config.ts` for the live numbers. Never edit a threshold to pass; that needs the user's approval.
- Reuse geometries and materials, instance repeated meshes, allocate nothing per frame, load heavy modules on demand (the tuning panel is already behind `?tune`).
- Measure through `window.__lab.frameStats`, not a second frame counter.

## Upstream skills

Reach for installed upstream skills by role instead of restating them here:

- General three.js performance and review rules: the `three-best-practices` skill.
- Profiling a slow scene or game: the `optimize-threejs-games` skill.
- Post-processing, bloom, exposure and grading: the `threejs-bloom` and `threejs-exposure-color-grading` skills.
- Procedural materials: the `threejs-procedural-materials` skill.
- Current three.js API and TSL: `https://threejs.org/docs/`, `https://threejs.org/llms.txt` and the TSL wiki page linked from the docs. Check the installed three version in the lab's lockfile first, since APIs move between releases.

If an upstream skill assumes GLSL or bare `three`, translate it to TSL and `three/webgpu`.
