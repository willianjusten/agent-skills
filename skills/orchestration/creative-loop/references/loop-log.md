# Loop log and the Stop hook

A long run keeps a loop log, a Markdown file the run owns. The Stop hook `harness/claude/hooks/loop-stop.sh` reads it so the run continues until its budget is spent.

## Format

```markdown
# Loop: <title>
Brief: <one line, or a path to the brief>
Started: 2026-06-01T11:00:00Z
Budget: 45 minutes, ends 2026-06-01T11:45:00Z
Mode: autonomous
Attempts: 1
Status: running

## Directions
- [x] first direction
- [ ] next direction

## Cycles
- 1 2026-06-01T11:10:00Z what this cycle did and its result

## Notes
User notes and steering, free text.

## Open items
- things left undecided or unresolved
```

- Header lines are `Key: value`, one per line, before the first `##` section. A tool can parse them with `^Key:`.
- `Started:` is a UTC ISO 8601 time ending in `Z`.
- `Budget:` is either `<N> minutes, ends <ISO time>Z` (also `hours`; only the `ends` time is read) or `<N> cycles`. The hook reads `ends <time>Z` or `<N> cycles`; any other value means no loop.
- `Status:` is `running`, `stopped` or `done`. `stopped` is the only early exit: the user writes it (or the skill does when the user asks to stop in the conversation) and the hook allows the stop. `done` is set only at hand-off, after the hook let the session stop; while budget remains the hook ignores it and blocks with a review cycle.
- `## Directions` holds ordered checkbox lines (`- [ ]` open, `- [x]` done). Only this section is read for directions.
- `## Cycles` holds one `- ` line per cycle. The cycle count is the number of those lines, which is what a `<N> cycles` budget spends.

## Active run

The run is active while a marker file `.loop-active` exists in the working folder or any parent of the Stop hook's cwd:

```json
{"log": "loop.md", "session_id": "optional"}
```

`log` is relative to the marker's folder or absolute. Only the session named by `session_id` is looped. `start-run.sh` takes it from `--session-id`, else from `$CLAUDE_SESSION_ID` when set. With neither, the hook binds the marker to the first session that stops under it by writing that session's `session_id` into the marker, so other sessions started in the same folder are never blocked. The marker is only searched for from the hook's cwd upward, never at or above `$HOME`. The loop skill writes the marker at the start and removes it at the end. No marker, no effect.

## What the hook does

Stop input (Claude Code hooks docs, Stop): common fields `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, plus `stop_hook_active`, `last_assistant_message`, `background_tasks`, `session_crons`. Block response: JSON on stdout with `{"decision": "block", "reason": "..."}` and exit 0 (exit 2 with the reason on stderr also blocks). Claude Code itself ends the turn after 8 consecutive blocked stops without a tool call (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` raises it).

| Situation | Result |
| --------- | ------ |
| No marker, other session, missing log, unparsable budget | allow |
| Stale marker: older than the budget plus an hour (7 days for a cycle budget) | allow |
| `Status: stopped` | allow |
| `Status: done` with budget remaining | block with the review-cycle instruction |
| Budget spent (end time passed or cycle lines >= N), whatever the status | allow |
| Log and working tree identical to the previous blocked stop | allow (loop breaker) |
| An unchecked direction exists | block with the first one |
| Every direction checked | block with the review-cycle instruction |

The loop breaker compares a checksum of the log plus `git status` and `git diff` of the repo that holds the log (the lab worktree, which is not the session folder), ignoring `.loop-active*`. It is kept in `.loop-active.state` next to the marker.

User interrupts: the Claude Code hooks reference says Stop "does not run if the stoppage occurred due to a user interrupt", and the Stop input has no interrupt field. So an interrupted turn never reaches the hook, and nothing needs implementing for "the user has not interrupted". The user can also end a run by deleting the marker.

## Driving the hook in a test

Pipe Stop input JSON to the hook with the working folder as `cwd`, and set `LOOP_NOW` (epoch seconds) to fix the clock. See `tests/loop-stop-hook.test.sh` in the agent-skills repo.

```bash
echo '{"session_id":"s1","cwd":"/path/to/run"}' | LOOP_NOW=1780315200 bash harness/claude/hooks/loop-stop.sh
```
