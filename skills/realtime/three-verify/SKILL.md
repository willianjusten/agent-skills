---
name: three-verify
description: Runs and reads the lab monorepo's `verify` gate check and fixes failing gates. Use when an app change needs checking, when asked if a game or experiment is done, when a gate fails (fps, first frame, size, console errors, backend), or before reporting a lab app finished.
metadata:
  scope: personal
---

# Three Verify

`pnpm verify <app>` is the single end-to-end check for a lab app. It builds the app, serves the production build for the gates, runs headed Chromium on a desktop and a throttled mobile profile, runs a scripted playtest or captures where the app has them, and exits 1 when any gate fails.

## Steps

1. **Run it** from the lab root: `pnpm verify <app>` (the app's folder name; running it with no name lists apps). After a fresh clone run `pnpm exec playwright install chromium` once. Leave the browser window alone while it runs; covering it can skew fps. Done when you have the gate table and exit code.
2. **Read the result.** The table prints each gate with actual and threshold; failing gates print detail below it. The same data is in `.verify/<app>/results.json` (`gates`, `measurements`, `config`). Gates cover steady fps and p95 frame time per profile, first presented frame per profile, renderer backend, JS gzip size, asset size, and console or page errors. Done when you can list each failing gate with its actual number.
3. **Fix the cause, never the threshold.** Thresholds live in `packages/verify/gates.config.ts` only, and loosening one needs the user's approval. Fixes by gate:
   - **Console errors:** read the printed detail. A 404 counts, including the favicon (templates ship a data-URL icon link). A shader or material error shows here.
   - **First frame:** the app did not publish `window.__lab` through core, or startup does heavy work before the first frame; defer it.
   - **Backend:** fails when the app lands on WebGL 2. Check the shader uses no WebGPU-only path that breaks and the renderer comes from core.
   - **fps / p95:** profile first (the `optimize-threejs-games` skill if installed, otherwise the browser performance panel), then cut overdraw, draw calls, per-frame allocation, shader cost.
   - **Full-screen coverage (`edge-bands`):** an experiment left an edge empty at a wide or tall window. Draw it with `createFullscreenEffect` from `@lab/engine` instead of a sized plane.
   - **JS or asset size:** find the heavy import in the build output, load it on demand, compress assets.
4. **Handle visual changes.** Captures (a game's `capture(name)` calls in `src/playtest.ts`, an experiment's `captures.json`) are compared with `<app>/references/<name>.png`. A missing reference or a visual change fails the reference gate. A new app has no references, so its first run fails that gate until they are accepted. Never run `--accept` just to get to green. Review means viewing the captures yourself. A subagent may run `--accept` only when its task explicitly allows it and only after viewing every capture; otherwise show the user the captures first. Record what was accepted in your report.
5. **Hand over the review packet.** `.verify/<app>/review-packet.html` collects gate numbers, playtest result, captures beside references and recordings. Bullet lines in the app's `DECISIONS.md` become its "Decisions to settle" section; put open questions there, creating the file if the app has none. Read `taste.md` in the lab root before building or polishing (it may be empty) and add review notes to it.
6. **Re-run until every gate passes.** The work is done when `pnpm verify <app>` prints PASSED and exits 0.
7. **Also run the WebGL 2 path** with `pnpm verify <app> --no-webgpu` when you wrote shaders; it hides `navigator.gpu` and drops the backend requirement.

## Flags

All optional; none is a gate.

- `--layer-cost`: prices each layer of an app that declares layers and adds the table to the review packet. Off by default and the slow part of `verify` (about a minute for ripple-toy); pass it when the packet needs layer prices. Not with `--motion` or `--url`.
- `--uncapped`: also runs the desktop profile once with Chromium's frame cap off and reports average fps, p95 and headroom at 60 fps in the packet and `results.json`. The gate fps stays capped. Read p95 as a floor for a GPU-bound app. Not with `--motion` or `--url`.
- `--preset <name>`: captures with `<app>/presets/<name>.json` loaded, to judge a tuned look; references are not compared. Not with `--accept` or `--motion`.
- `--accept`: rewrites the reference images from this run. Only for a change that altered the look on purpose, after viewing every capture against its reference. Not with `--motion`, `--variants` or `--preset`.
- `--variants <a>,<b>,<c> --moment <capture name>`: captures that one moment once per preset in `<app>/src/presets/`, into `.verify/<app>/variants/<preset>.png`. It runs alone: no gates and no results, so it takes none of the other flags; run a plain `pnpm verify <app>` afterwards to refresh the packet.
- `--motion --from-recording <from>-<to>`: cuts a range of seconds from the last play recording into `motion-play/judge/`. Needs `--motion`, not `--against` or `--url`. `--record-seconds <n>` sets how long a play recording runs.

## Game captures

A game can describe a scripted playthrough in the `game` block of its `captures.json`: a seed plus actions held from second to second. `pnpm verify <game> --motion` replays it deterministically through `__game.advance` and writes the frame strip, crops, burst and MP4, so the same script gives the same frames every run. It needs the dev build that `verify` makes itself, so it cannot run against `--url`. Details are in the lab `README.md`, "Motion capture".

## Limits

- The gates run on the production build, where `window.__game` is absent. A game's `src/playtest.ts` runs against a separate development build that `verify` makes itself; no manual dev build is needed for it.
- Playtest scripts, captures, references and the review packet are specified in the lab `README.md` (section "Playtests, captures and the review packet") and `packages/verify/AGENTS.md`; read them rather than relying on this summary.
- Done is tiered in the lab: `pnpm check` (typecheck and unit tests, about 9 s) for every change; `pnpm verify <app>` for an app you touched; for `packages/` or `templates/`, also `pnpm test:e2e:fast` then `pnpm test:e2e:slow` (about 8 minutes together) and `verify` of each affected app.
- Fps numbers are hardware dependent. If only a gate on a different GPU fails, say so rather than loosening it.
