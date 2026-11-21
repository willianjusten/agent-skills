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
- `Status:` is `running` or `done`. Setting `done` is how a run meets its done condition; the hook then allows the stop.
- `## Directions` holds ordered checkbox lines (`- [ ]` open, `- [x]` done). Only this section is read for directions.
- `## Cycles` holds one `- ` line per cycle. The cycle count is the number of those lines, which is what a `<N> cycles` budget spends.

## Active run

The run is active while a marker file `.loop-active` exists in the working folder or any parent of the Stop hook's cwd:

```json
{"log": "loop.md", "session_id": "optional"}
```

`log` is relative to the marker's folder or absolute. With `session_id`, only that session is looped. The loop skill writes the marker at the start and removes it at the end. No marker, no effect.

## What the hook does

Stop input (Claude Code hooks docs, Stop): common fields `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name`, plus `stop_hook_active`, `last_assistant_message`, `background_tasks`, `session_crons`. Block response: JSON on stdout with `{"decision": "block", "reason": "..."}` and exit 0 (exit 2 with the reason on stderr also blocks). Claude Code itself ends the turn after 8 consecutive blocked stops without a tool call (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` raises it).

| Situation | Result |
| --------- | ------ |
| No marker, other session, missing log, unparsable budget | allow |
| `Status: done` | allow |
| Budget spent (end time passed or cycle lines >= N) | allow |
| Log and working tree identical to the previous blocked stop | allow (loop breaker) |
| An unchecked direction exists | block with the first one |
| Every direction checked | block with the review-cycle instruction |

The loop breaker compares a checksum of the log plus `git status` and `git diff` (ignoring `.loop-active*`), kept in `.loop-active.state` next to the marker.

## Driving the hook in a test

Pipe Stop input JSON to the hook with the working folder as `cwd`, and set `LOOP_NOW` (epoch seconds) to fix the clock. See `tests/loop-stop-hook.test.sh`.

```bash
echo '{"session_id":"s1","cwd":"/path/to/run"}' | LOOP_NOW=1780315200 bash harness/claude/hooks/loop-stop.sh
```
