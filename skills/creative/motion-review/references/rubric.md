# Motion rubric

Score X and Y independently on the same anchors, 1 to 10, whole numbers. Never round up to reach a bar.

## What you are given

Each of `x/` and `y/` holds three sheets of the same piece over the same time window:

- `strip.png`: evenly spaced moments of the window, shrunk, read left to right, then top to bottom. Use it for rhythm and how the whole frame moves.
- `crops.png`: the same moments as a 1:1 crop of one region at full resolution, in the same order. Use it for fine detail: specks, grain, edges, how they are placed and how that placement changes over time.
- `burst.png`: 1:1 crops of consecutive frames (a fraction of a second), read left to right, then top to bottom. Use it for flicker: what changes from one frame to the next.

Compare every crop with its neighbours; motion is what changes between them.

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

## Motion lens

Judge on 0-2 points each, summed to 10:

- Fluidity: shapes travel and change smoothly between moments; no jumps, stalls or sudden resets.
- Rhythm: timing has variation and intent (ease, build, rest); not a constant mechanical beat, not random noise.
- Randomness of placement over time: particles, specks and texture are placed unevenly, with clumps, streaks and empty stretches that shift from moment to moment. An even, uniform layer, the same density everywhere, reads as mechanical and scores 0 here.
- Temporal stability: detail that should persist (a speck riding a wave, a surface texture) persists and moves coherently; groups do not pop in or die together; no crawling, swimming or column patterns.
- Flicker and fine detail: in the burst, frame-to-frame change is calm and deliberate, no shimmer or strobing. Fine layers (grain, dust, specks) must be findable in the crops: a layer you cannot see at 1:1 counts as absent and scores 0 here, and the note says so.

## Output format

```text
X: <score>  <one-line note>
Y: <score>  <one-line note>
```

Notes name what you see in motion (where, which sheet), never which image is newer or better made by whom.
