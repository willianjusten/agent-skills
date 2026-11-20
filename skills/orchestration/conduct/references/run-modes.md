# Run modes

Read after setup, with `limits` and `profile`. `limits` prints `mode=overnight` or `mode=review`; the mode decides who makes the calls between rounds.

## Choosing the mode

`/conduct` copies the mode into the `start` or a `budget` line as `mode=overnight` or `mode=review`. With no mode named, it is `review`.

| The request says | Mode and settings |
| ---------------- | ----------------- |
| "overnight", "while I sleep", "on its own", "autonomously", "run unattended" | `mode=overnight`, plus `hours=N` when it names a duration |
| a duration alone ("work on this for 6h") | `mode=review` with `hours=N`: a duration says how long, not who decides |
| "call me each round", "ask me after each round", "check with me every round", "review each round" | `mode=review` |
| nothing about it | `mode=review` |

`autoAccepts=N` and `look=ask|auto` stay valid and win over what the mode implies.

## Overnight

Fully autonomous, bounded by the hours (default 6).

- `look=auto` is implied: no look-variants stop, and you log the pick as an `assumption`.
- No cap on autonomous reference accepts: `accepts` and `limits` print `unlimited` unless `autoAccepts=N` was given. Every accept still gets an `accept` line, after a reviewer subagent has read the old and new capture side by side, and the hand-off lists them all. An accept line without that reviewer's verdict in it is refused: the side-by-side read is the user's rule, and no overnight run skips it.
- No round limit unless `rounds=N` was given; the hours bound the run.
- It uses the whole budget: delivery comes early only when `run_state.py rows` prints `all-at-target=yes`; otherwise rounds go on until `budget` prints `reserve:`, then the trailer round and delivery. A flat round changes approach and a plateau is not a stop (`references/polish-rounds.md`, "Use the whole budget").
- A judge split on a taste call is yours to settle: the lower counted score decides (keep the change only on a win or tie); log an `assumption | judge split resolved: <moment>, <scores>, <decision>`. It is not a stop.
- The only stops are a gate failing after two fix attempts and delivery. Everything else is an `assumption`, and a spent budget moves on to delivery.

## Review

You and the user decide together; accepts are the user's.

- After every polish round, once `round`, `judge` and `revert` lines are written and the packet is current, `step` prints `stop: round-review`: append `stop | round-review | round N kept/reverted: <one line> | <packet path>`, then follow the stop procedure. If you end without that line, `next` still prints `waiting: round-review`.
- The hand-off for this stop links the packet and opens with its Evolution section when it exists (the per-moment stills across rounds), then offers numbered choices: keep and continue, revert the round, or notes for the next round; at the last round (the round limit, or every row at target) it also offers the trailer round (`references/trailer-round.md`). The answer is `keep`, `revert`, `deliver`, `trailer` or notes, as one `answer` line; `deliver` and `trailer` end polish (`trailer` runs the trailer round first). `revert` means you revert the round's merge before the next round; notes reach the next director through `next`.
- A round is light unless `run_state.py checkpoint` says `checkpoint-due`; the hand-off says which tier ran (`references/checkpoints.md`).
- Autonomous accepts stay at the limit `accepts` prints (default 3); an accept needs the user at the limit.
- A judge split on a taste call is a stop, as before.
