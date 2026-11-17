---
name: three-verify
description: Runs and reads the lab monorepo's `verify` gate check and fixes failing gates. Use when an app change needs checking, when asked if a game or piece is done, when a gate fails (fps, first frame, size, console errors, backend), or before reporting a lab app finished.
metadata:
  scope: personal
---

# Three Verify

`pnpm verify <app>` is the single end-to-end check for a lab app. It builds the app, serves the production build, runs headed Chromium on a desktop and a throttled mobile profile, and exits 1 when any gate fails.

## Steps

1. **Run it** from the lab root: `pnpm verify <app>` (the app's folder name; running it with no name lists apps). After a fresh clone run `pnpm exec playwright install chromium` once. Leave the browser window alone while it runs; covering it can skew fps. Done when you have the gate table and exit code.
2. **Read the result.** The table prints each gate with actual and threshold; failing gates print detail below it. The same data is in `.verify/<app>/results.json` (`gates`, `measurements`, `config`). Gates cover steady fps and p95 frame time per profile, first presented frame per profile, renderer backend, JS gzip size, asset size, and console or page errors. Done when you can list each failing gate with its actual number.
3. **Fix the cause, never the threshold.** Thresholds live in `packages/verify/gates.config.ts` only, and loosening one needs the user's approval. Fixes by gate:
   - **Console errors:** read the printed detail. A 404 counts, including the favicon (templates ship a data-URL icon link). A shader or material error shows here.
   - **First frame:** the app did not publish `window.__lab` through core, or startup does heavy work before the first frame; defer it.
   - **Backend:** fails when the app lands on WebGL 2. Check the shader uses no WebGPU-only path that breaks and the renderer comes from core.
   - **fps / p95:** profile first (the `optimize-threejs-games` skill), then cut overdraw, draw calls, per-frame allocation, shader cost.
   - **JS or asset size:** find the heavy import in the build output, load it on demand, compress assets.
4. **Re-run until every gate passes.** The work is done when `pnpm verify <app>` prints PASSED and exits 0.
5. **Also run the WebGL 2 path** with `pnpm verify <app> --no-webgpu` when you wrote shaders; it hides `navigator.gpu` and drops the backend requirement.

## Limits

- `verify` serves the production build, so `window.__game` is absent; bot playthroughs need a dev build (see the lab's `packages/verify/AGENTS.md`).
- A change to `packages/` or `templates/` is done when `pnpm test`, `pnpm typecheck` and `pnpm test:e2e` pass, not just `verify`.
- Fps numbers are hardware dependent. If only a gate on a different GPU fails, say so rather than loosening it.
