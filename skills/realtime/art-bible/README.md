# Art Bible

Fixes the look and the asset level per asset type, and gets sign-off before assets are made.

## What It Does

```mermaid
flowchart LR
  A[Read treatment] --> B[Palette and references]
  B --> C[Asset level and polish]
  C --> D[Style test sheet]
  D --> E[Sign-off]
```

## Usage

```text
Write the art bible for this game
Our generated textures do not match; fix the look
Set the asset level for sprites to free and models to placeholder
```

## Output

`ART-BIBLE.md` in the app folder, and a style test sheet under `art/style-test/`.
