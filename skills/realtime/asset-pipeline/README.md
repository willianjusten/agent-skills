# Asset Pipeline

Sources game assets from packs and libraries, or makes them in code, and records each one with its license.

## What It Does

```mermaid
flowchart LR
  A[List assets and roles] --> B[Packs, then libraries, then code-made]
  B --> C[pnpm asset command]
  C --> D[Manifest entry]
  D --> E[Check models and clips]
  E --> F[pnpm verify]
```

## Usage

```text
Get me a rock wall texture for the arena floor
Find a crate model that fits the pirate theme
Can we use this model in a commercial release?
verify says the asset manifest fails, fix it
```

## Output

- `assets.manifest.json` and `public/assets/` in the app.

## Requirements

- The lab monorepo. Pack contact sheets need ffmpeg; models need gltf-transform. Poly Haven and ambientCG need network.

## FAQ

- Can it use paid providers? No.
- Can I drop a file in by hand? No; without a manifest entry `verify` fails it.
