---
name: three-verify
description: Runs and reads the lab monorepo's `verify` gate check and fixes failing gates. Use when an app change needs checking, when asked if a game or experiment is done, when a gate fails (fps, first frame, size, console errors, backend), or before reporting a lab app finished.
metadata:
  scope: personal
---

# Three Verify

`pnpm verify <app>` is the single end-to-end check for a lab app. It builds the app, serves the production build for the gates, runs headed Chromium on a desktop and a throttled mobile profile, runs a scripted playtest or captures where the app has them, and exits 1 when any gate fails. The desktop fps profile measures at 1920x1080 (gate id `fps-desktop`).

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
6. **Between edits, take shots, not a full verify.** `pnpm shot <app> <t1> [t2 ...]` opens the production build on a virtual clock and writes `.verify/<app>/shots/t-<seconds>s.png` for each time, about 2 s for a few shots. Add `--play --keys KeyW,Space` to hold keys from time zero (the two go together), `--query autopilot=1` to add a query string, `--full` for 1920x1080 instead of 960x540. It prints console errors and the median frame time and runs no gates. Done when the shots show the change.
7. **Re-run until every gate passes.** The work is done when `pnpm verify <app>` prints PASSED and exits 0.
8. **Also run the WebGL 2 path** with `pnpm verify <app> --no-webgpu` when you wrote shaders; it hides `navigator.gpu` and drops the backend requirement.

## Flags

All optional; none is a gate.

- `--layer-cost`: prices each layer of an app that declares layers and adds the table to the review packet. Off by default and the slow part of `verify` (about a minute for ripple-toy); pass it when the packet needs layer prices. Not with `--motion` or `--url`.
- `--uncapped`: also runs the desktop profile once with Chromium's frame cap off and reports average fps, p95 and headroom at 60 fps in the packet and `results.json`. The gate fps stays capped. Read p95 as a floor for a GPU-bound app. Not with `--motion` or `--url`.
- `--preset <name>`: captures with `<app>/presets/<name>.json` loaded, to judge a tuned look; references are not compared. Not with `--accept` or `--motion`.
- `--accept`: rewrites the reference images from this run. Only for a change that altered the look on purpose, after viewing every capture against its reference. Not with `--motion`, `--variants` or `--preset`.
- `--variants <a>,<b>,<c> --moment <capture name>`: captures that one moment once per preset in `<app>/src/presets/`, into `.verify/<app>/variants/<preset>.png`. It runs alone: no gates and no results, so it takes none of the other flags; run a plain `pnpm verify <app>` afterwards to refresh the packet.
- `--record-seconds <n>`: records n seconds of play to `.verify/<app>/play/play.mp4` and `play-contact-sheet.png` (one tile per second). Off by default, because every frame is stepped and captured and the run gets much longer. The bot plays from the game's `src/balance.ts` policy, or nobody when there is none. The recording runs on a virtual clock at 60 fps, is silent, and closely repeats across runs of the same seed (not byte-identical, so never a test). Not with `--url` or `--preset`. Without it the packet lists the recording under "Checks that did not run".
- `--record <query>`: with `--record-seconds`, records the production build opened with that query string (for example `--record autopilot=1`; `--record ''` for none) with nobody pressing keys, instead of the bot. Use it for an experiment or a game with an autopilot. Seconds default to 45 here.
- `--motion --from-recording <from>-<to>`: cuts a range of seconds from the last play recording (either kind) into `motion-play/judge/`. Needs `--motion` and an earlier `--record-seconds` or `--record` run, not `--against` or `--url`. It reads only the play recording, never the trailer.
- `--trailer`: records the trailer declared in `app.json` into `.verify/<app>/trailer/` (`play.mp4`, `play-contact-sheet.png`), apart from `play/`, and adds a "Trailer" packet section. For presenting only: not frame-identical across runs, so never a test, gate or reference. Direct the trailer by editing the shot list in the app's `src/trailer.ts`; between edits take shots (step 6) with the trailer's query. Not with `--motion` or `--variants`.
- `--round <label> [--round-notes <file.json>]`: also snapshots the captures (and the trailer sheet and mp4 when present) into `.verify/<app>/evolution/<NN>-<label>/` with the judges' scores, for the packet's "Evolution" section and `.verify/<app>/evolution.html`. Run it after the baseline and after every round, reverted tries included. Notes file shape and labels: the lab `docs/testing-and-verify.md`. Not with `--motion`, `--variants`, `--url` or `--preset`.

Animation driven by `setTimeout` or `setInterval` does not record correctly, because the virtual clock does not move those timers; the packet warns when the app's `src` uses them. Drive animation from the frame loop.

## Game captures

A game can describe a scripted playthrough in the `game` block of its `captures.json`: a seed plus actions held from second to second. `pnpm verify <game> --motion` replays it deterministically through `__game.advance` and writes the frame strip, crops, burst and MP4, so the same script gives the same frames every run. It needs the dev build that `verify` makes itself, so it cannot run against `--url`. Details are in the lab `README.md`, "Motion capture".

## Limits

- The gates run on the production build, where `window.__game` is absent. A game's `src/playtest.ts` runs against a separate development build that `verify` makes itself; no manual dev build is needed for it.
- Playtest scripts, captures, references and the review packet are specified in the lab `README.md` (section "Playtests, captures and the review packet") and `packages/verify/AGENTS.md`; read them rather than relying on this summary.
- Done is tiered in the lab: `pnpm check` (typecheck and unit tests, about 9 s) for every change; `pnpm verify <app>` for an app you touched; for `packages/` or `templates/`, also `pnpm test:e2e:fast` then `pnpm test:e2e:slow` (about 8 minutes together) and `verify` of each affected app.
- Games with `src/balance.ts` and an event map in `src/sounds.ts` get a sound report (`sound` in `results.json`, packet section "Sound": per event peak, loudness, duration and whether the bot run fired it) and a `sound` gate that fails on a silent sound or one that never fired. A never-fired sound usually means the bot policy in `src/balance.ts` never reaches it: fix the policy, not the gate. A `loud` flag (more than 9 dB over the mix median) is a finding, not a failure.
- The `?tune` panel scrolls and folds.
- Fps numbers are hardware dependent. If only a gate on a different GPU fails, say so rather than loosening it.
