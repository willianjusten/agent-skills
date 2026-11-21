---
name: asset-pipeline
description: Sources and records game and experiment assets from packs and libraries with the lab's `pnpm asset` scripts, or makes them in code. Use when an app needs textures, images, models or animation clips, when a license or manifest question comes up, or when `verify` flags the asset manifest.
metadata:
  scope: personal
---

# Asset Pipeline

Every asset enters an app through a script that writes its manifest entry. Nothing is dropped into `public/assets/` by hand: a file with no entry has no recorded source, and `verify` fails it.

## Steps

1. **List what is needed.** Name each asset and its role (character, enemy, weapon, prop, tile, environment, texture). If the brief or the app's `app.json` says `"assetMode": "code-only"`, run no asset script (see [references/sources.md](references/sources.md)). Done when every asset has a role or the app is code-only.
2. **Choose the source in this order: packs, then libraries, then code-made.** Selection rules are in [references/sources.md](references/sources.md); script flags are in [references/scripts.md](references/scripts.md). Done when each asset names its source.
3. **Run the script from the lab root.** `pnpm asset <command> <id> --app <app directory>`; run `pnpm asset` with no arguments for the current commands. Fetch from Poly Haven only through its API, never by scraping. `pack fetch` refuses an id already in the manifest unless you pass `--replace`. Done when the script exits 0 and its manifest entry exists.
4. **Record licenses, never filter by them.** Every lab app is experimental, so any source may be used whatever its terms; never pick a worse asset for license reasons. The scripts record license, commercial-use flag and credit in each entry. Done when every entry carries its terms.
5. **Check every model, and play its clips.** Run `pnpm asset check-glb <id> --role <role> --fix` on any model `pack fetch` did not already check. Done when each model passes its role and each clip that fits a state is played in the app's animation code or noted as unused ([references/sources.md](references/sources.md)).
6. **Look at it in the app.** Run `pnpm shot <app> <seconds>` and read the image: the asset should match its neighbours in scale, style and lighting. Done when you have seen it in the scene.
7. **Verify.** Run `pnpm verify <app>`; the asset manifest gate must pass (in code-only mode, the code-only gate). The gate does not judge license terms. Fix the entry or remove the asset; never loosen the gate.

## Rules

- Output stays engine-neutral: glTF, PNG and OGG, with the manifest as plain JSON.
- Keep total assets under the size gate; pick the lowest texture resolution that looks right, and compress models (`optimize-gltf`).
- Tell the user plainly which tool actually ran. A missing tool (ffmpeg for `pack sheet`, gltf-transform) is reported, not replaced by a different source.
- A request to generate an image or model from a prompt is declined: generation is not part of the pipeline; offer a pack, a library or a code-made asset.
- Paid assets are out of scope.
