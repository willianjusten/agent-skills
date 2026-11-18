# Rubric

One lens per judge. Score X and Y independently on the same anchors, 1 to 10, whole numbers. Never round up to reach a bar.

## Anchors

| Score | Means |
| ----- | ----- |
| 10 | Best-in-class, something you would study |
| 9 | Excellent: a trained eye finds almost nothing |
| 8 | Polished and intentional, only minor nits |
| 7 | Good, but a noticeable flaw |
| 6 | Acceptable: works and reads clearly, with visible rough edges |
| 5 | Mediocre: the idea is there, the execution distracts |
| 3-4 | Clearly broken or wrong in places |
| 1-2 | Barely works, or reads as something else |

## Visual lens: visuals and composition

Judge on 0-2 points each, summed to 10:

- Composition and framing: where the eye goes, balance, depth.
- Colour and light: palette cohesion, contrast, value structure, glow and bloom.
- Material and detail: surfaces, texture, edges, no artifacts.
- Atmosphere and depth: fog, haze, volume and layering between foreground and background; a flat empty backdrop scores 0 here.
- Polish of the whole frame: one coherent style, nothing placeholder, cropped or unfinished.

## Feel lens: feel and readability

The captures are still frames, so judge what a frame shows about feel:

- Readability: the player, threats, goals and interactive things are identifiable at a glance.
- Hierarchy: what matters most is the most visible; UI does not fight the scene.
- Feedback cues: impact, motion, state and effect cues visible in the frame.
- Clarity at play size: still readable at the size and speed it is played.
- Mood and intent: the frame conveys the experience the piece aims for.

## Target gap (only with a benchmark image)

When a benchmark is given, score each image a second time on closeness to it, 1 to 10: 10 is indistinguishable in look, 5 has the right idea with major layers missing, 1 shares only the layout. This is separate from the lens score; do not let one image's distance from the other soften it.

Then compare each image to the benchmark under every heading below and list what differs. Write `matches` only when it truly does.

You may be given a list of accepted differences: ways the user prefers to depart from the benchmark. Still list them under their heading, marked `(accepted)`, but do not count them against the gap score.


- Light and glow: brightness, bloom, halo size, falloff.
- Atmosphere and fog: haze, volume, drifting density, depth between layers.
- Material and texture: internal detail, wisps, grain, edge quality.
- Colour: hue, saturation, value range.
- Composition: framing, edge clearance, balance.

## Output format (both judges)

Without a benchmark:

```text
X: <score>  <one-line note>
Y: <score>  <one-line note>
```

With a benchmark:

```text
X: <score>  gap <score>  <one-line note>
Y: <score>  gap <score>  <one-line note>
X gaps:
- light and glow: <difference or matches>
- atmosphere and fog: ...
- material and texture: ...
- colour: ...
- composition: ...
Y gaps:
- (same five headings)
```

Notes name what you see, never which image is newer or better made by whom.
