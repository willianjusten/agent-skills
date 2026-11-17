---
name: asset-pipeline
description: Sources, generates and records game and piece assets with the lab's asset scripts, honouring the app's asset level. Use when an app needs textures, images, cutouts or models, when choosing between placeholder, free and premium assets, when a license or manifest question comes up, or when `verify` flags the asset manifest.
metadata:
  scope: personal
---

# Asset Pipeline

Every asset enters an app through a script that writes its manifest entry. Nothing is dropped into `public/assets/` by hand: a file with no entry has no recorded license, and `verify` fails it.

## Steps

1. **Read the level.** The app declares `assetLevel` in `app.json` (`placeholder`, `free`, `premium`; missing means `placeholder`), and the brief or art bible may set a level and a polish per asset type. Done when you can state level and polish for each asset type you were asked for.
2. **Apply the level.** `placeholder`: build primitives and grey boxes, run no script. `free`: CC0 libraries and local generation only. `premium`: refuse and say it is locked until the unlock bar is met; never work around the refusal. If the asked level is above the app's declaration, stop and ask the user to raise `assetLevel`. Done when every requested asset has an allowed route.
3. **Choose the source, library first.** Poly Haven or ambientCG for textures, HDRIs and models; local generation only for what no CC0 library has. Scripts and flags are in [references/scripts.md](references/scripts.md). Done when each asset names its script.
4. **Run the script from the lab root.** `pnpm asset <command> <id> --app <app directory> --level <level> --polish <rough|polished>`. Fetch from Poly Haven only through its API, never by scraping. Done when the script exits 0 and its manifest entry exists.
5. **Follow the polish.** `rough` generates once and records. `polished` makes a style test sheet first (`art/style-test/`), generates with more steps, optimizes models, and leaves the entry `pending`: show the user the sheet and the asset, and run `pnpm asset approve <id>` only after they say yes. Done when no polished entry is still `pending` without the user having seen it.
6. **Check licenses.** Use only Apache-2.0 or CC0 sources. Do not use FLUX dev or pro, bria or RMBG-2.0 (non-commercial). A source with other terms gets `commercialUse` of `attribution-required` with the credit text, or `no`; ask the user before shipping it. Done when every entry has a license and a commercial-use flag.
7. **Verify.** Run `pnpm verify <app>`; the `Asset manifest and licenses` gate must pass. The lab `README.md`, section "Assets", lists what it fails on. Fix the entry or remove the asset; never loosen the gate.

## Rules

- Output stays engine-neutral: glTF, PNG and OGG, with the manifest as plain JSON.
- Keep total assets under the 15 MB gate; pick the lowest texture resolution that looks right, and compress models.
- Tell the user plainly which tool actually ran. A missing tool (mflux, rembg, gltf-transform) is reported, not replaced by a different generator.
