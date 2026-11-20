---
name: target-loop
description: Gives a polish round a visual target, a real screenshot repainted by an image model and approved by the user before anyone chases it. Use when a game or experiment needs a concrete visual goal, when asked for a target frame, dream loop or repaint prompt, when agents keep polishing without a clear look to reach, or when a round should be scored against a target.
metadata:
  scope: personal
---

# Target Loop

A target frame is a real capture of the app, repainted by an image model with the same camera, framing, layout and pose, and approved by the user. Rounds chase it and judges score against it. The user runs the repaint by hand in an image app, so no paid API is involved.

## Hard rule

Never create, generate, approve or choose a target yourself. If the user has not approved it, stop at step 3 and hand over; do not run a round, do not judge against a draft, do not substitute one of your own images. Approval is the user typing it in a terminal; there is no other path. Editing `assets.manifest.json` or `targets/` by hand to approve or swap a target is out of bounds; the lab refuses every other route.

## Steps

1. **Capture a real frame.** Run the app's `verify` gate and pick a capture of the moment that matters most (fixed tick or time, desktop size). Done when you have a PNG written by `verify`, not a hand-made screenshot.
2. **Prepare the repaint.** Store the capture and the repaint prompt with the app. In the lab: `pnpm asset target prepare <id> --app <dir> --capture <png>`; the lab code owns the prompt text, and [references/repaint-prompt.md](references/repaint-prompt.md) explains what it asks and how to judge the result. Done when the app's `targets/` folder holds `<id>.source.png` and `<id>.prompt.txt`.
3. **Hand over to the user.** Tell the user to attach the screenshot and paste the prompt in the image app, save the result, then run `target submit <id> --image <png>` and decide with `target approve <id>` or `target reject <id>`. Offer a step-by-step script for it. Then stop. Done when the user has the instructions and nothing else runs.
4. **Check approval before every round.** `pnpm asset target path <id> --app <dir>` prints the target image only when it is approved and exits non-zero otherwise. If it fails, stop and say so. Done when it prints a path.
5. **Run one round that chases it.** Give the area subagents the approved target and the current capture; the brief names what differs (light, material, colour, depth) and forbids changing camera, layout or gameplay. Write the brief from the last round's after-image gap lists, then check every item against the app's `taste.md`, the repo root `taste.md`, the app's `## Accepted differences`, the user's settled notes in the app's `DECISIONS.md` and any notes the user gave for this round: the user's taste outranks the judges, so drop each contradicting item and list it with the line that ruled it out. User notes are an optional override; the round goes ahead from the gap lists and taste files whenever there are none. When the user accepts a difference from the target, record it word for word under `## Accepted differences` in the app's `DECISIONS.md`. A change that makes the capture look less like the target is not progress. Done when the round has before and after captures of the same moment as the target.
6. **Judge against the target.** Use blind judges: shuffle before and after as X and Y, pass each judge the absolute target path from step 4 as the benchmark and the app's `## Accepted differences` word for word, anchored 10-point rubric, lower score counts, keep only a win or tie, and reject a change whose counted target-gap score drops even when it wins on the lens. If `workflow-score-to-target` is installed, use it for the multi-round climb; without it, repeat steps 5 and 6 until the target score is met or progress plateaus. Done when each moment has a decision and both scores.
7. **Re-target or stop.** If rounds plateau because the target is unreachable in real time (photographic detail, impossible geometry), report that to the user and offer a new capture and repaint (back to step 1); never edit the target.

## Without a target

A target frame is optional. When the pitch asks for none, the benchmark is an art-bible reference image when the bible names one: judges get its absolute path as they would a target's, and rounds chase it the same way (steps 5 and 6, with no `target path` check). With neither there is no benchmark and no gap score; judges score the lens only. A capture of the app itself (the chosen look, an earlier round) is never a benchmark, since it rewards sameness. The hard rule above still holds for any real target.

## Rules

- One approved target per moment; every round and judge uses the same file.
- The manifest records the target as an image asset: pending until approved, never shipped.
- Targets are reference only. Do not copy the target image into the app as an asset.
- Judges are advisory; `verify` gates stay the hard checks.
