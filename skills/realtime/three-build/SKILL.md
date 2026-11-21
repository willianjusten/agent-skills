---
name: three-build
description: Builds games and creative experiments in the lab monorepo on three.js WebGPURenderer. Use when adding or changing a game or experiment in the lab repo, scaffolding from the game or experiment template, wiring the lab packages, looking at a build with shot, check or record, running the verify delivery step, or sizing a perf budget.
metadata:
  scope: personal
---

# Three Build

Apps in the lab monorepo are slim: a template that starts green, plus packages used as a library. Build on those; do not rebuild them per app.

## Steps

1. **Find the lab.** It is the checkout whose root `package.json` is named `lab`, with `packages/engine`, `packages/verify` and `templates/`. Work from the current directory if it is one; otherwise ask the user where it is. Read its `README.md`, `AGENTS.md` and `templates/AGENTS.md` first; they win over this skill where they differ. Done when you can name the root commands.
2. **Pick a template.** `pnpm create-app` with no arguments lists them. A game with simulation and input uses `game`; a visual experiment or technique demo uses `experiment`. Done when the choice matches the brief.
3. **Scaffold, never copy.** `pnpm create-app <template> <name>`. A hand-copied folder skips token replacement and the gallery manifest. Commit the `pnpm-lock.yaml` change. Done when the app folder exists and is not yet edited.
4. **Read the app's files.** `BRIEF.md` is the brief (a placeholder until written), `LOOP.md` the log of a long run (leave `Budget:` blank when no loop runs), `ENGINE.md` the file map, rules and perf budget. Keep `ENGINE.md` current when the file map or rules change. Done when you know which `src/` file each concern lives in.
5. **Build in vertical slices.** Rules in "Renderer and packages" below. Shaders and materials are TSL node materials, never GLSL. Done when `pnpm typecheck` passes for the app.
6. **Look at it as you go.** `pnpm shot <app> <t1> [t2 ...]` writes screenshots at those seconds of the demo (`?demo=1`; `--play --keys KeyW,Space` plays with input, `--query` overrides, `--full` is 1920x1080) and prints frame time and any console error. `pnpm record <app|path> [--seconds 30]` writes a silent 60 fps `play.mp4` and a contact sheet under `.verify/<app>/record/`. Both run on a virtual clock, so two runs of a deterministic app match. Read the images; a change you have not looked at is not done.
7. **Check.** `pnpm check <app>` plays the production build through its handle with an idle and a wandering bot and prints PASS, FAIL and INFO lines (phases reached, stuck, determinism, console errors, frame time, baseline title, pause, volume, restart and demo, sound levels), writing `.verify/<app>/check/results.json`. Fix every FAIL. Done when it exits 0.
8. **Deliver with verify.** `pnpm verify <app>` runs the hard gates (fps, first frame, JS and asset size, console errors, backend) and builds the review packet from the record and check output, so run `record` and `check` first. A gate with nothing to judge (no reference images, no assets) is skipped, not failed. Fix every failing gate; never edit a threshold in `packages/verify/gates.config.ts` to pass, that needs the user's approval. Done when it prints PASSED.

## Renderer and packages

- Import from `three/webgpu` and `three/tsl`, never bare `three`. `WebGPURenderer` falls back to WebGL 2 by itself.
- The packages are a library: `@lab/engine` (`startApp`, parameters, tuning), `@lab/experiment` (`startExperiment`, seekable clock), `@lab/game` (fixed-step loop, `createFlow`, `installHandle`, game feel), `@lab/look` (`declareLook`, `createLook`: lights, fog, tone, emissive, finishing layers), `@lab/effects` (post layers, each its own subpath), `@lab/input` (action map, `describeControls`), `@lab/ui` (headless menu, away guard, volume model), `@lab/audio` (mixer, recipes, sequencer), `@lab/debug` (`?tune` panel, `window.__lab`). Read each package's `AGENTS.md` for its rules and `src/index.ts` for the exports; never write your own renderer, resize handling or `requestAnimationFrame` loop. Respect the import boundaries between packages.
- Games: the simulation is a pure, seeded, fixed-timestep module with no three or DOM imports; it appends gameplay events to its state and rendering only reads it. Wire the flow (title, playing, paused, game-over), screens, input, audio and `?demo=1` the way the template's `main.ts` does, and keep its baseline working.
- Install the game handle (`installHandle` from `@lab/game/handle`) in every build, production included, never behind `import.meta.env.DEV`, and only after the app has started: `check` reads `window.__handle` and treats it as ready.
- Menus and HUD: one primary action per screen, detail behind a button, tab or submenu, and one spacing scale for padding, gaps and type. Keep the always-visible HUD to what the player needs this second. `pnpm check <app>` prints `ui layout` lines (overlap, clipping, minimum font, target size and gap, words per screen) and saves shots under `.verify/<app>/check/ui/`: read the shots and fix every FAIL.
- Experiments: a frame is a pure function of the seekable time. No clock reads, `Math.random` or frame deltas inside it.
- A look value (light, fog, tone, emissive, palette colour) is declared in the app's `look.ts` and applied with `createLook`; do not add a light, fog or hard-coded colour in `main.ts`. A tunable number is a parameter declared with the engine's parameter API.
- A full-screen effect uses `createFullscreenEffect` from `@lab/engine`, which covers the canvas at any camera and aspect.
- Build a hard effect alone first, then port it into the app. Honour `prefers-reduced-motion`.
- Code-only: `"assetMode": "code-only"` in `app.json` makes `verify` fail any asset file or outside request.

## Perf habits

- Budgets are hard gates; read `packages/verify/gates.config.ts` for the live numbers.
- Reuse geometries and materials, instance repeated meshes, allocate nothing per frame, load heavy modules on demand (the tuning panel already loads only on `?tune`).
- Measure through `window.__lab.frameStats` or the frame time `shot` prints, not a second frame counter.

## Upstream skills

If installed, reach for these by role instead of restating them. Each is optional; the fallback is in brackets.

- General three.js performance and review rules: `three-best-practices` [fallback: the perf habits above and `https://threejs.org/docs/`].
- Profiling a slow scene or game: `optimize-threejs-games` [fallback: browser performance panel and `window.__lab.frameStats`].
- Post-processing, bloom, exposure and grading: `threejs-bloom` and `threejs-exposure-color-grading` [fallback: three.js post-processing examples].
- Procedural materials: `threejs-procedural-materials` [fallback: the TSL wiki].
- Current three.js API and TSL: `https://threejs.org/llms.txt` and `https://github.com/mrdoob/three.js/wiki/Three.js-Shading-Language`. Check the installed three version in the lab's lockfile first.

If an upstream skill assumes GLSL or bare `three`, translate it to TSL and `three/webgpu`.
