# Repaint prompt

Paste this with the screenshot attached. The lab writes the same text to `targets/<id>.prompt.txt`.

```text
Repaint the attached screenshot as a finished, best-in-class frame of the same game or piece.
Keep EXACTLY the same camera, framing, layout and pose. Do not add, remove, move or resize anything.
Only improve the rendering: lighting, materials, texture detail, colour, atmosphere and depth.
Keep it reachable in real time on WebGPU: no photographic detail that a shader could not plausibly produce.
Output one image at the same aspect ratio as the screenshot.
```

Why each line: the first two stop the model redesigning the scene, so a round can compare like with like; the third scopes the work to rendering; the fourth keeps the target reachable, since an unreachable target wastes rounds; the last keeps the framing diffable.

Reject a result when the layout moved, objects appeared or vanished, the aspect ratio changed, or it looks like another piece's style. Adapt the prompt to name the art bible's palette and "Not this" list when the app has them.
