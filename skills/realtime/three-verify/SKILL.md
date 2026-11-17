---
name: three-verify
description: Runs and reads the lab monorepo's `verify` gate check and fixes failing gates. Use when an app change needs checking, when asked if a game or piece is done, when a gate fails (fps, first frame, size, console errors, backend), or before reporting a lab app finished.
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
   - **JS or asset size:** find the heavy import in the build output, load it on demand, compress assets.
4. **Handle visual changes.** Captures (a game's `capture(name)` calls in `src/playtest.ts`, an experiment's `captures.json`) are compared with `<app>/references/<name>.png`. A missing reference or a visual change fails the reference gate until a human has reviewed the new captures and you run `pnpm verify <app> --accept`. Never run `--accept` to get to green on your own: show the user the captures first.
5. **Hand over the review packet.** `.verify/<app>/review-packet.html` collects gate numbers, playtest result, captures beside references and recordings. Bullet lines in the app's `DECISIONS.md` become its "Decisions to settle" section; put open questions there. Read `taste.md` in the lab root before building or polishing and add review notes to it.
6. **Re-run until every gate passes.** The work is done when `pnpm verify <app>` prints PASSED and exits 0.
7. **Also run the WebGL 2 path** with `pnpm verify <app> --no-webgpu` when you wrote shaders; it hides `navigator.gpu` and drops the backend requirement.

## Limits

- The gates run on the production build, where `window.__game` is absent. A game's `src/playtest.ts` runs against a separate development build that `verify` makes itself; no manual dev build is needed for it.
- Playtest scripts, captures, references and the review packet are specified in the lab `README.md` (section "Playtests, captures and the review packet") and `packages/verify/AGENTS.md`; read them rather than relying on this summary.
- A change to `packages/` or `templates/` is done when `pnpm test`, `pnpm typecheck` and `pnpm test:e2e` pass, not just `verify`.
- Fps numbers are hardware dependent. If only a gate on a different GPU fails, say so rather than loosening it.
