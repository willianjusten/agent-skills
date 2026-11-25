# Run article

A private artifact page that shows the piece growing, one frame per cycle, with what the run cost. It is the page the user shares; the summary is the page they act on.

## Frames

One frame per cycle, all taken the same way, so the only thing that changes between two frames is the build.

- At cycle 1 choose the frame the profile names (game: one demo second that shows play, not a menu) and the window the brief names (a phone-first piece is shot upright). Log it under `## Notes` as `Frame: <seconds>s, <width>x<height>`.
- After each cycle's commit, save that frame as `<out>/history/<cycle, two digits>.jpg` (lab: `.verify/<app>/history/`).
- A cycle with no frame at hand-off is rebuilt from its commit: `git worktree add` a scratch checkout at that commit, build, shoot the same frame, remove the scratch worktree.

Done when every `## Cycles` line has a frame.

## Numbers

- **Time:** from the first to the last `## Cycles` timestamp per run, plus ideation and brief when they ran in this session; give each part and the total.
- **Cost:** sum the token usage in the session transcript (`~/.claude/projects/<project>/<session-id>.jsonl`, each message id counted once) by model and by kind (input, output, cache read, cache write), priced at the list prices in the `claude-api` skill. Give the total, the split, and each assumption (cache-write rate, subagent sessions left out). Say that on a subscription this is usage against the plan, and list money spent on assets or services separately, `$0` included.

## Page

Read the `claude-artifacts` guide topics `pages` and `design` first. In this order:

1. Title, one sentence on what the piece is, and the headline numbers: cycles, loop time, total time, cost.
2. The first frame beside the last.
3. Every frame in cycle order, each captioned with its cycle number and the cycle line's change in a few words. Mark the frames after a user's feedback with what they asked for.
4. Time and cost tables, with the assumptions under them.
5. How the frames were taken, and what they do not show (sound, feel, anything off-frame).

Publish it private with `publish_files` (frames as files, never inlined). Done when the page URL is in `summary.md` under **Files** and in the chat.

A later pass on the same piece (user polish after the run) adds its frames and numbers to the same artifact as a new version.
