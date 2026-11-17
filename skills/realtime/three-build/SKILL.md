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
3. **Scaffold, never copy.** Run `pnpm create-app <template> <name> [games|pieces|examples]`. A technique or knowledge-base example uses `examples`. A hand-copied folder skips token replacement and the gallery manifest. Commit the `pnpm-lock.yaml` change `create-app` makes. Done when `apps/<category>/<name>` exists and is not yet edited.
4. **Read the app's docs.** `TREATMENT.md` states creative intent and a "Not this" list; `ENGINE.md` holds the file map, rules and perf budget. Fill the stubs for a new app; keep `ENGINE.md` current when the file map or rules change.
5. **Build in vertical slices.** Rules in "Renderer and loop" below. Write shaders and materials as TSL node materials, never GLSL, using the TSL docs linked below. Done when `pnpm typecheck` passes for the app.
6. **Add checks.** A game gets `src/playtest.ts`, a scripted playtest that calls `capture(name)`; an experiment gets `captures.json` with the seek times to capture. Format: the lab `README.md`, section "Playtests, captures and the review packet". Done when `verify` has captures to compare.
7. **Verify.** Run `pnpm verify <app>` from the lab root and fix every failing gate. A visual change fails the reference gate until the captures are reviewed and `pnpm verify <app> --accept` is run; a subagent accept only when the task explicitly allows it and after viewing every capture, and record what was accepted in the report. Read `taste.md` before building (it may be empty). Create the app's `DECISIONS.md` when there are open questions; the template does not ship one. The work is not done until it prints PASSED.

## Renderer and loop

- Import from `three/webgpu` (and `three/tsl`), never bare `three`. Renderer is `WebGPURenderer`, which falls back to WebGL 2 by itself.
- Use the core package (`@lab/core`): `startApp` for a plain app, `startExperiment` for a seekable piece. Read `packages/core/src` for the current exports; do not write your own renderer, resize handling or `requestAnimationFrame` loop. An app that bypasses core never publishes `window.__lab`, and the first-frame gate fails.
- Games: simulation is a pure, seeded, fixed-timestep module with no three or DOM imports and a Vitest test; rendering only reads its state. `window.__game` stays behind `import.meta.env.DEV`.
- Experiments: a frame is a pure function of the seekable time. No clock reads, `Math.random` or frame deltas inside it.
- Build a hard effect alone on the template's lab route first, then port it into the main app.
- Honour `prefers-reduced-motion`.
- A full-screen effect: core's `startApp` (`packages/core/src/app.ts`) sets up the default camera; size the plane from that camera and its distance, not from numbers copied here.

## Perf habits

- Budgets are hard gates (fps, first frame, JS and asset size); read `packages/verify/gates.config.ts` for the live numbers. Never edit a threshold to pass; that needs the user's approval.
- Reuse geometries and materials, instance repeated meshes, allocate nothing per frame, load heavy modules on demand (the tuning panel is already behind `?tune`).
- Measure through `window.__lab.frameStats`, not a second frame counter.

## Upstream skills

If installed, reach for these upstream skills by role instead of restating them here. Each is optional; the fallback is in brackets.

- General three.js performance and review rules: `three-best-practices` [fallback: the perf habits above and `https://threejs.org/docs/`].
- Profiling a slow scene or game: `optimize-threejs-games` [fallback: browser performance panel and `window.__lab.frameStats`].
- Post-processing, bloom, exposure and grading: `threejs-bloom` and `threejs-exposure-color-grading` [fallback: three.js post-processing examples].
- Procedural materials: `threejs-procedural-materials` [fallback: the `three-tsl` skill and the TSL wiki].
- Current three.js API and TSL: `https://threejs.org/llms.txt`, `https://threejs.org/docs/llms-full.txt` and `https://github.com/mrdoob/three.js/wiki/Three.js-Shading-Language`. Check the installed three version in the lab's lockfile first, since APIs move between releases.

If an upstream skill assumes GLSL or bare `three`, translate it to TSL and `three/webgpu`.
