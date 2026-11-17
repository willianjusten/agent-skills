# Three TSL

Writes three.js shaders as TSL node graphs instead of GLSL.

## What It Does

| Phase | Output |
| ----- | ------ |
| Read official TSL docs and `llms.txt` | Known node names |
| Read an existing effect | The repo's effect shape |
| Write the node material | One effect file, one time uniform |
| Build alone, then port | Effect renders on WebGPU and WebGL 2 |

## Usage

```text
Write a TSL ripple shader for the plane
Port this GLSL fragment shader to TSL
Add a glow effect to the cube material
```

## FAQ

- Does it copy the TSL docs? No, it links to them.
