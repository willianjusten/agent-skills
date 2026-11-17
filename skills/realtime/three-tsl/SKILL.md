---
name: three-tsl
description: Writes shaders and materials with three.js TSL (Three Shading Language) node materials instead of GLSL. Use when authoring or editing a shader, material, post-processing effect or procedural visual in a three.js WebGPURenderer project, or when tempted to write GLSL, ShaderMaterial or onBeforeCompile.
metadata:
  scope: personal
---

# Three TSL

Training data skews to GLSL. TSL is a node graph built in JavaScript that compiles to WGSL or GLSL, so one effect runs on WebGPU and on the WebGL 2 fallback.

## Steps

1. **Read the sources.** Fetch the TSL wiki page (`https://github.com/mrdoob/three.js/wiki/Three.js-Shading-Language`), `https://threejs.org/llms.txt` and `https://threejs.org/docs/llms-full.txt`, plus the TSL examples linked from them. Return to them whenever you are unsure of a node name; do not guess from GLSL habit. To confirm a function exists in the installed three version, grep the installed `three` package in `node_modules` (its `src/nodes/` TSL exports) before the web docs. Done when each node and function you plan to use appears in the docs or in an existing lab effect.
2. **Read a working effect in the repo.** In the lab, an `experiment` template app has `src/effects/*.ts`, one TSL material per file. Copy its shape: imports from `three/webgpu` and `three/tsl`, a node material, uniforms updated from a `frame` function. `apps/examples/tsl-lava/src/effects/lava.ts` is the worked example. Done when you can say which uniform carries time. The effect returns an `ExperimentDefinition` (`frame`, optional `tune`) from `@lab/core`, defined in `packages/core/src/experiment.ts`; `tune` receives a `TuningPane`, a Tweakpane pane.
3. **Write the effect as a graph.**
   - Use `three/webgpu` node materials (`MeshBasicNodeMaterial`, `MeshStandardNodeMaterial`, ...) and assign nodes to `colorNode`, `positionNode`, `emissiveNode` and the other node slots.
   - Express maths with node functions and operators (`.mul`, `.add`, `mix`, `smoothstep`, `uv()`, `uniform()`), not string shaders.
   - Use `Fn` for reusable chunks and `uniform` for values the JS side changes. Type `Fn` and `Loop` params with `Node<'float'>` or `Node<'vec2'>` from `three/webgpu`, as `lava.ts` does, instead of casting.
   - Never use `ShaderMaterial`, `RawShaderMaterial`, `onBeforeCompile` or GLSL strings.
4. **Keep it deterministic.** Time comes from one time uniform, set by the app's frame function, so a seeked frame renders the same image. No `Math.random` or clock reads feeding uniforms.
5. **Name the magic numbers** as constants and expose tunables through the template's tuning pane, so a human can retune without a rewrite.
6. **Build it alone first** on the template's lab route, then port into the main app. Done when the effect renders with no console errors on WebGPU and with `navigator.gpu` hidden (`pnpm verify <app> --no-webgpu` runs the fallback).
7. **Prove it with captures.** For an experiment, list the seek times that show the effect in `captures.json`, so `verify` compares them with `references/<name>.png`. Changing a shader changes the pixels, which fails the reference gate until a human reviews the captures and `pnpm verify <app> --accept` is run; a subagent accept only when the task explicitly allows it and after viewing every capture, and record what was accepted in the report. Details: the lab `README.md`, section "Playtests, captures and the review packet". Open questions go in the app's `DECISIONS.md` (create it if missing); read `taste.md` first, it may be empty.

If installed, the `threejs-procedural-materials` and `threejs-visual-validation` skills cover advanced materials and fixed-view validation; without them, the steps above are enough.

## Pitfalls

- Node API names change between three.js releases; check the installed version before trusting a snippet from memory or a blog.
- Compute and storage-buffer features need WebGPU and do not run on the WebGL 2 fallback; keep a fallback path or leave them out.
- Type errors on node chains usually mean a missing conversion (`float()`, `vec3()`); fix the type, do not cast to `any`.
- Many extra texture samples or loop iterations show up first on the mobile profile; check the numbers with `pnpm verify <app>`.
