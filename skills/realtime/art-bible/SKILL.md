---
name: art-bible
description: "Writes or revises the art bible for a game or experiment: theme and setting, pack family, palette, references, style test sheet, and the asset level and polish per asset type, then gets the user's sign-off. Use when a game or experiment needs a consistent look, before sourcing assets, when choosing placeholder, free or premium assets, whether a game is code-only, or when assets do not match each other."
metadata:
  scope: personal
---

# Art Bible

One look for every asset. No asset is sourced until the user signs this off. The output is engine-neutral.

## Steps

1. **Read the brief.** Read `TREATMENT.md` and the GDD if present; the palette must match the treatment. Done when you can list the asset types the work needs.
2. **Write the bible.** Use [references/art-bible-template.md](references/art-bible-template.md). Name the game's theme and setting first (for example "pirate cove, night"): packs are picked against it. Name one pack family (for example Kenney or Quaternius) where models are needed, or choose code-only: every asset made by code, no model, image, font or audio file, declared as `"assetMode": "code-only"` in the app. References are three to six, each with the one thing to take from it. Style rules cover shape language, texture detail, lighting mood and what to avoid. Done when no placeholder text remains.
3. **Set levels and polish.** One row per asset type: level (`placeholder`, `free`, `premium`) and polish (`rough`, `polished`). Default to `placeholder` and `rough`. `premium` is locked until the user unlocks it; record the request and keep the row at `free`. Done when every needed asset type has a row.
4. **Make the style test sheet.** For any level above `placeholder`, produce one subject in the target style from the chosen pack, library or code, and record its path and status `pending`. If the asset tools are not available, say so and leave the status `pending` with a note. Done when the sheet exists or the gap is stated.
5. **Get sign-off.** Show the palette, references, sheet and level table. Record name and date only after the user says yes, plus their changes. Done when the sign-off line is filled or the user's objections are listed.

## Rules

- No sign-off, no asset beyond a placeholder.
- No engine, library or API names in the bible; a pack family, for example Kenney, is a source, not an API, and may be named; the bible stays engine-neutral.
- A change to the palette after sign-off needs a new sign-off.
