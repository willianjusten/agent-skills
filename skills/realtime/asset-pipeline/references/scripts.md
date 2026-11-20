# Asset scripts

Run from the lab root. Every command needs `--app <app directory>`; `--level` defaults to `free`, `--polish` to `rough`. Run `pnpm asset` with no arguments for the current options.

| Command | Does | Notes |
| ------- | ---- | ----- |
| `polyhaven <id> [--resolution 1k]` | Downloads a texture's diffuse, normal and roughness maps through the official API | CC0 |
| `pack search <pack> [--query "words"] [--kit <slug>] [--animated] [--max-triangles n]` | Lists models in a codepawl GLB pack (`kenney`, `quaternius`, or `owner/dataset`) with kit, triangles, size, license and clips | No `--app` needed. Index pinned to the dataset revision and cached |
| `pack sheet <pack> --out <png> [search options]` | Contact sheet of up to 24 thumbnails, legend in reading order | Needs ffmpeg. Read the PNG to pick |
| `pack fetch <pack>:<model id> --id <asset id> --role <role>` | Web-tier GLB into `public/assets/models/<id>.glb`, pivot and materials fixed, checked, recorded | Records the row's own license and credit; deletes a model that fails its role. Prints the clips (name and seconds) or "no clips". An id already in the manifest is refused without `--replace` |
| `check-glb <asset id> --role <role> [--fix]` | Pivot, unlit materials, triangle budget and height of a recorded model | Roles: character, enemy, weapon, prop, tile, environment. Prints the clips or "no clips". Exits 1 on an error |
| `ambientcg <id> [--resolution 1K]` | Downloads an ambientCG material zip and unpacks the same three maps | CC0 |
| `optimize-gltf <asset id>` | gltf-transform optimize of a recorded model, saved as `<id>-optimized` | `rough` dedups and prunes; `polished` adds meshopt and webp compression |
| `approve <asset id>` | Marks a polished asset approved | Only after the user has seen it |

In a `code-only` app (`"assetMode": "code-only"` in `app.json`) no asset command runs and `verify` fails any asset file.

Headless Blender cleanup (`blender -b -P script.py`) is a manual step for models gltf-transform cannot fix; re-import the result as a recorded source before running `optimize-gltf`.

## Manifest entry

`assets.manifest.json` in the app folder holds `{ "assets": [...] }`; the fields are listed in the lab `README.md`, section "Assets", and typed in `packages/tools/src/manifest.ts`. The scripts write it; read it, do not hand-edit it.
