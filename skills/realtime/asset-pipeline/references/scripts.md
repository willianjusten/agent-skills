# Asset scripts

Run from the lab root. Every command needs `--app <app directory>`; `--level` defaults to `free`, `--polish` to `rough`. Run `pnpm asset` with no arguments for the current options.

| Command | Does | Notes |
| ------- | ---- | ----- |
| `polyhaven <id> [--resolution 1k]` | Downloads a texture's diffuse, normal and roughness maps through the official API | CC0 |
| `ambientcg <id> [--resolution 1K]` | Downloads an ambientCG material zip and unpacks the same three maps | CC0 |
| `generate-image <id> --prompt <text> [--seed n] [--model schnell\|flux2-klein-4b]` | Local mflux generation | Apache-2.0 models only. `--tool-version` and `--runner "uvx --from mflux"` when mflux is not a `uv tool` install |
| `remove-background <asset id> [--model isnet-general-use\|birefnet-general]` | rembg cutout of a recorded image, saved as `<id>-cutout` | Inherits the source's license and prompt. `--runner "uvx --from rembg[cpu,cli]"` for an ephemeral run |
| `optimize-gltf <asset id>` | gltf-transform optimize of a recorded model, saved as `<id>-optimized` | `rough` dedups and prunes; `polished` adds meshopt and webp compression |
| `img-to-3d <model id> --from <image asset id> [--backend sf3d\|trellis\|tripo]` | Image to optimized GLB through local Stable Fast 3D (default, `LAB_SF3D_DIR`), local TRELLIS.2 (trellis-mac, `LAB_TRELLIS_DIR`) or the Tripo API (`TRIPO_API_KEY`), recorded as `<model id>`. Selection order is sf3d, trellis, tripo | SF3D is `attribution-required` under the Stability AI Community License (commercial use under US $1M annual revenue, registration and a "Powered by Stability AI" credit); TRELLIS and Tripo free tier are `commercialUse: no`, so `verify` flags them (a warning in an experiment-only app). SF3D needs the gated `stabilityai/stable-fast-3d` weights; its MPS path can crash on the GPU watchdog, so retry with `SF3D_USE_CPU=1`. Prints time, peak memory and GLB size before and after. Add `--runner "npx --package @gltf-transform/cli"` when gltf-transform is not installed |
| `approve <asset id>` | Marks a polished asset approved | Only after the user has seen it |

Headless Blender cleanup (`blender -b -P script.py`) is a manual step for models gltf-transform cannot fix; re-import the result as a recorded source before running `optimize-gltf`.

## Manifest entry

`assets.manifest.json` in the app folder holds `{ "assets": [...] }`; the fields are listed in the lab `README.md`, section "Assets", and typed in `packages/tools/src/manifest.ts`. The scripts write it; read it, do not hand-edit it.
