---
name: asset-pipeline
description: Sources and records game and experiment assets from packs and libraries with the lab's asset scripts, or makes them in code, honouring the app's asset level. Use when an app needs textures, images, models or animation clips, when choosing between placeholder, free and premium assets, when a license or manifest question comes up, or when `verify` flags the asset manifest.
metadata:
  scope: personal
---

# Asset Pipeline

Every asset enters an app through a script that writes its manifest entry. Nothing is dropped into `public/assets/` by hand: a file with no entry has no recorded source, and `verify` fails it.

## Steps

1. **Read the level and mode.** The app declares `assetLevel` in `app.json` (`placeholder`, `free`, `premium`; missing means `placeholder`) and may declare `"assetMode": "code-only"`; the brief or art bible may set a level and a polish per asset type. Done when you can state level, mode and polish for each asset type you were asked for.
2. **Apply the level.** `placeholder`: primitives and grey boxes, no script. `free`: free packs and libraries only. `premium`: refuse; it is locked until the unlock bar is met. An asked level above the app's declaration stops the work until the user raises `assetLevel`. In `code-only` mode run no asset script (see [references/sources.md](references/sources.md)). Done when every requested asset has an allowed route.
3. **Choose the source in this order: packs, then libraries, then code-made.** Selection rules and pack picking are in [references/sources.md](references/sources.md); script flags are in [references/scripts.md](references/scripts.md). Done when each asset names its source.
4. **Run the script from the lab root.** `pnpm asset <command> <id> --app <app directory> --level <level> --polish <rough|polished>`. Fetch from Poly Haven only through its API, never by scraping. `pack fetch` refuses an id already in the manifest unless you pass `--replace`. Done when the script exits 0 and its manifest entry exists.
5. **Follow the polish.** `rough` fetches once and records. `polished` also makes a style test sheet first (`art/style-test/`), optimizes models, and leaves the entry `pending`: show the user the sheet and the asset, and run `pnpm asset approve <id>` only after they say yes. Done when no polished entry is still `pending` without the user having seen it.
6. **Record licenses, never filter by them.** Every lab app is experimental, so any source may be used whatever its terms, including non-commercial ones. Prefer the asset that looks best; never pick a worse one or a flat stand-in for license reasons. The scripts record the license, commercial-use flag and credit in the entry so the user can decide before a release. Done when every entry carries its terms.
7. **Check every model, and play its clips.** Run `pnpm asset check-glb <id> --role <role> --fix` on any model `pack fetch` did not already check. Done when each model passes its role and each clip that fits a state is played in the app's animation code or noted as unused ([references/sources.md](references/sources.md)).
8. **Verify.** Run `pnpm verify <app>`; the `Asset manifest` gate must pass (in code-only mode, the `Code-only assets` gate); neither judges license terms. The lab `README.md`, section "Assets", lists what it fails on. Fix the entry or remove the asset; never loosen the gate.

## Rules

- Output stays engine-neutral: glTF, PNG and OGG, with the manifest as plain JSON.
- Keep total assets under the 15 MB gate; pick the lowest texture resolution that looks right, and compress models.
- Tell the user plainly which tool actually ran. A missing tool (ffmpeg for `pack sheet`, gltf-transform) is reported, not replaced by a different source.
- A request to generate an image or model from a prompt is declined: say that generation is not part of the pipeline and offer a pack, a library or a code-made asset.
