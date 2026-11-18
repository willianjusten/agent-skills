# Repaint prompt

The lab owns the prompt text (`REPAINT_PROMPT` in `packages/tools/src/target-frame.ts`) and writes it to `targets/<id>.prompt.txt` on `target prepare`. Hand the user that file; do not retype or reword it here, so there is one source of truth.

What the prompt asks of the image model, line by line:

- Same camera, framing, layout and pose, nothing added, removed, moved or resized: stops the model redesigning the scene, so a round can compare like with like.
- Improve only the rendering (lighting, materials, texture detail, colour, atmosphere, depth): scopes the work.
- Stay reachable in real time on WebGPU: an unreachable target wastes rounds.
- One image at the screenshot's aspect ratio: keeps the framing diffable.

Reject a result when the layout moved, objects appeared or vanished, the aspect ratio changed, or it looks like another piece's style. When the app has an art bible, the user may add its palette and "Not this" list to the prompt before running it.
