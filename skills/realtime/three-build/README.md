# Three Build

Builds games and creative pieces in the lab monorepo on three.js WebGPURenderer.

## What It Does

```mermaid
flowchart LR
  A[Find the lab repo] --> B[Pick a template]
  B --> C[pnpm create-app]
  C --> D[Read TREATMENT and ENGINE]
  D --> E[Build in slices on core]
  E --> F[pnpm verify]
```

## Usage

```text
Add a new example app to the lab with a water ripple effect
Start a new game in the lab from the game template
Why is this piece not publishing window.__lab?
```

## Requirements

- A checkout of the lab monorepo with pnpm and Node 24.
