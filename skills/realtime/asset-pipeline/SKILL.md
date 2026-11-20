---
name: asset-pipeline
description: Sources, generates and records game and experiment assets with the lab's asset scripts, honouring the app's asset level. Use when an app needs textures, images, cutouts or models, when choosing between placeholder, free and premium assets, when a license or manifest question comes up, or when `verify` flags the asset manifest.
metadata:
  scope: personal
---

# Asset Pipeline

Every asset enters an app through a script that writes its manifest entry. Nothing is dropped into `public/assets/` by hand: a file with no entry has no recorded source, and `verify` fails it.

## Steps

1. **Read the level.** The app declares `assetLevel` in `app.json` (`placeholder`, `free`, `premium`; missing means `placeholder`), and the brief or art bible may set a level and a polish per asset type. Done when you can state level and polish for each asset type you were asked for.
2. **Apply the level.** `placeholder`: build primitives and grey boxes, run no script. `free`: free libraries and local generation only. `premium`: refuse and say it is locked until the unlock bar is met; never work around the refusal. If the asked level is above the app's declaration, stop and ask the user to raise `assetLevel`. Done when every requested asset has an allowed route.
3. **Choose the source, library first.** Models: a pack first (`pnpm asset pack`, Kenney and Quaternius as GLB), one family per game where it covers the roles; run `pack sheet` and pick from the thumbnails, not the names. Poly Haven or ambientCG for textures, HDRIs and realistic props. Image-to-3D only for a hero prop no pack has, and 2D cutouts never stand in for a 3D model. Scripts and flags are in [references/scripts.md](references/scripts.md). Done when each asset names its script.
4. **Run the script from the lab root.** `pnpm asset <command> <id> --app <app directory> --level <level> --polish <rough|polished>`. Fetch from Poly Haven only through its API, never by scraping. Done when the script exits 0 and its manifest entry exists.
5. **Follow the polish.** `rough` generates once and records. `polished` makes a style test sheet first (`art/style-test/`), generates with more steps, optimizes models, and leaves the entry `pending`: show the user the sheet and the asset, and run `pnpm asset approve <id>` only after they say yes. Done when no polished entry is still `pending` without the user having seen it.
6. **Record licenses, never filter by them.** Every lab app is experimental, so any source or model may be used whatever its terms, including non-commercial ones (FLUX.1 dev, bria, RMBG-2.0, TRELLIS, Tripo). Prefer the asset that looks best; never pick a worse one or a flat stand-in for license reasons. The scripts record the license, commercial-use flag and credit in the entry so the user can decide before a release. Done when every entry carries its terms.
7. **Check every model.** `pack fetch` already normalises and checks; run `pnpm asset check-glb <id> --role <role> --fix` on any other model (Poly Haven, image-to-3D). Done when each model passes its role: pivot at bottom-centre, lit materials, inside the triangle budget.
8. **Verify.** Run `pnpm verify <app>`; the `Asset manifest` gate must pass; it never judges license terms. The lab `README.md`, section "Assets", lists what it fails on. Fix the entry or remove the asset; never loosen the gate.

## Rules

- Output stays engine-neutral: glTF, PNG and OGG, with the manifest as plain JSON.
- Keep total assets under the 15 MB gate; pick the lowest texture resolution that looks right, and compress models.
- Local generation needs `mflux` and `rembg[cpu,cli]` installed with `uv tool install`, plus a Hugging Face login with the FLUX model terms accepted (the repos are gated, and the first run downloads tens of GB). On a `GatedRepoError`, 401 or 403, send the user to the lab `README.md`, section "Assets", Prerequisites; do not copy the steps.
- Tell the user plainly which tool actually ran. A missing tool (mflux, rembg, gltf-transform) is reported, not replaced by a different generator.
