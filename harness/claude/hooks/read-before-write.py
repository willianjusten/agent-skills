"""PreToolUse hook for Edit|Write|NotebookEdit.

Denies changing an existing file unless the session's Read calls covered every
line of it. Standard library only (runs on /usr/bin/python3, 3.9). Fails open:
any error, missing transcript or unknown format allows the call.
"""

import json
import os
import sys
import tempfile
import time
from datetime import datetime

WRITE_TOOLS = ("Edit", "Write", "NotebookEdit")

LOCKFILE_NAMES = ("package-lock.json", "pnpm-lock.yaml", "bun.lockb")
GENERATED_DIRS = ("node_modules", "dist", "build", ".next", "coverage")

WHOLE_FILE = (1, float("inf"))

# Slack between a write's recorded result and the file's mtime, so the session's
# own writes do not count as a change made outside it.
SESSION_WRITE_TOLERANCE_SECONDS = 5

# How long after this hook allows a write a change on disk still counts as that write.
# The transcript lags, so with parallel calls an earlier write may not be in it yet.
ALLOWED_WRITE_WINDOW_SECONDS = 120

# The Read tool returns at most 2000 lines when the call has no offset/limit.
READ_DEFAULT_LIMIT = 2000

# Past one Read's worth of lines, an Edit needs only its old_string plus this much context.
LARGE_FILE_CONTEXT_LINES = 50


def is_exempt(file_path, project_dir):
    """Lockfiles and generated output are rewritten by tools, never read line by line.

    Only the part of the path inside the project counts, so a project that itself
    lives under a folder named `build` is still checked.
    """
    file_name = os.path.basename(file_path)
    if file_name.endswith(".lock") or file_name in LOCKFILE_NAMES:
        return True
    relative_path = os.path.relpath(file_path, project_dir)
    checked_path = file_path if relative_path.startswith("..") else relative_path
    return any(part in GENERATED_DIRS for part in os.path.dirname(checked_path).split(os.sep))


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))


def target_path(tool_input):
    return tool_input.get("file_path") or tool_input.get("notebook_path")


def session_transcript(payload):
    """The transcript of whoever is calling: a subagent writes its own at
    <session>/subagents/agent-<agent_id>.jsonl and only knows what it read there."""
    transcript_path = payload.get("transcript_path")
    agent_id = payload.get("agent_id")
    if not transcript_path or not agent_id:
        return transcript_path
    agent_file_name = f"agent-{agent_id}.jsonl"
    if os.path.basename(transcript_path) == agent_file_name:
        return transcript_path
    session_dir = os.path.splitext(transcript_path)[0]
    return os.path.join(session_dir, "subagents", agent_file_name)


def allowed_writes_path(payload):
    """Where this hook records the writes it allowed, per session and agent."""
    state_dir = payload.get("scratchpad_dir") or tempfile.gettempdir()
    owner = "-".join(str(part) for part in (payload.get("session_id"), payload.get("agent_id")) if part)
    return os.path.join(state_dir, f"read-before-write-{owner or 'unknown'}.json")


def load_allowed_writes(state_path):
    try:
        with open(state_path, encoding="utf-8") as state_file:
            allowed_writes = json.load(state_file)
        return allowed_writes if isinstance(allowed_writes, dict) else {}
    except (OSError, ValueError):
        return {}


def record_allowed_write(state_path, allowed_writes, target_real_path):
    allowed_writes[target_real_path] = time.time()
    try:
        with open(state_path, "w", encoding="utf-8") as state_file:
            json.dump(allowed_writes, state_file)
    except OSError:
        pass


def conversation_turns(transcript_path):
    """Timestamped user and assistant entries. Other entries (request copies, titles,
    modes) repeat or annotate turns and carry no timestamp."""
    with open(transcript_path, encoding="utf-8") as transcript:
        for line in transcript:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if (
                isinstance(entry, dict)
                and entry.get("type") in ("user", "assistant")
                and isinstance(entry.get("message"), dict)
                and entry.get("timestamp")
            ):
                yield entry


def entry_epoch(entry):
    """Seconds since the epoch of a transcript entry's ISO 8601 timestamp."""
    return datetime.fromisoformat(str(entry["timestamp"]).replace("Z", "+00:00")).timestamp()


def content_blocks(entry, block_type):
    content = entry["message"].get("content")
    if not isinstance(content, list):
        return []
    return [block for block in content if isinstance(block, dict) and block.get("type") == block_type]


def read_range(tool_input, tool_use_result, is_notebook):
    """The (first, last) lines a Read returned, from its result when recorded, else its input.

    A notebook Read returns every cell, so it covers the whole file.
    """
    if is_notebook:
        return WHOLE_FILE
    returned_file = tool_use_result.get("file") if isinstance(tool_use_result, dict) else None
    if isinstance(returned_file, dict) and isinstance(returned_file.get("numLines"), int):
        first_line = max(int(returned_file.get("startLine") or 1), 1)
        return first_line, first_line + returned_file["numLines"] - 1
    first_line = max(int(tool_input.get("offset") or 1), 1)
    return first_line, first_line + int(tool_input.get("limit") or READ_DEFAULT_LIMIT) - 1


def file_history(transcript_path, target_real_path, current_tool_use_id):
    """The session's successful Reads of the target as (epoch called, (first, last) line),
    and the epoch the session last changed it, or None.

    A Write counts as a read of the whole file, since the session wrote every line of it.
    A write with no result yet is still running (parallel calls), so it counts as the
    latest change. The call being judged is skipped: it cannot vouch for itself.
    Returns None when the transcript holds no conversation turn: an unknown format.
    """
    tool_uses = {}
    tool_results = {}
    format_recognized = False
    for entry in conversation_turns(transcript_path):
        format_recognized = True
        for block in content_blocks(entry, "tool_use"):
            tool_uses[block.get("id")] = (block, entry_epoch(entry))
        for block in content_blocks(entry, "tool_result"):
            tool_results[block.get("tool_use_id")] = (block, entry.get("toolUseResult"), entry_epoch(entry))
    if not format_recognized:
        return None

    is_notebook = target_real_path.endswith(".ipynb")
    reads = []
    last_session_write = None
    for tool_use_id, (tool_use, called_at) in tool_uses.items():
        tool_name = tool_use.get("name")
        tool_input = tool_use.get("input")
        if tool_use_id == current_tool_use_id or tool_name not in ("Read",) + WRITE_TOOLS:
            continue
        if not isinstance(tool_input, dict) or not target_path(tool_input):
            continue
        if os.path.realpath(str(target_path(tool_input))) != target_real_path:
            continue
        result_block, tool_use_result, finished_at = tool_results.get(tool_use_id, ({}, None, None))
        if result_block.get("is_error"):
            continue
        if tool_name == "Read":
            reads.append((called_at, read_range(tool_input, tool_use_result, is_notebook)))
            continue
        written_at = float("inf") if finished_at is None else finished_at
        last_session_write = written_at if last_session_write is None else max(last_session_write, written_at)
        if tool_name == "Write":
            reads.append((called_at if finished_at is None else finished_at, WHOLE_FILE))
    return reads, last_session_write


def first_gap(ranges, first_needed, last_needed):
    """The first (start, end) span of needed lines no range covers, or None when covered."""
    cursor = first_needed
    for range_start, range_end in sorted(ranges):
        if range_start > cursor:
            break
        cursor = max(cursor, range_end + 1)
        if cursor > last_needed:
            return None
    if cursor > last_needed:
        return None
    next_starts = [range_start for range_start, _ in ranges if range_start > cursor]
    return cursor, min(next_starts + [last_needed + 1]) - 1


def line_count(file_content):
    """Lines as the Read tool counts them: only \\n ends a line."""
    if not file_content:
        return 0
    return file_content.count("\n") + (0 if file_content.endswith("\n") else 1)


def needed_lines(tool_name, tool_input, file_content, total_lines):
    """The (first, last) lines the session must have read before this change, or None
    when the Edit cannot apply (its old_string is not in the file)."""
    old_string = tool_input.get("old_string")
    if total_lines <= READ_DEFAULT_LIMIT or tool_name != "Edit" or not old_string:
        return 1, total_lines
    match_index = file_content.find(old_string)
    if match_index < 0:
        return None
    if tool_input.get("replace_all"):
        return 1, total_lines
    first_line = file_content.count("\n", 0, match_index) + 1
    last_line = first_line + old_string.rstrip("\n").count("\n")
    return (
        max(first_line - LARGE_FILE_CONTEXT_LINES, 1),
        min(last_line + LARGE_FILE_CONTEXT_LINES, total_lines),
    )


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") not in WRITE_TOOLS:
        return
    tool_input = payload.get("tool_input") or {}
    file_path = target_path(tool_input)
    transcript_path = session_transcript(payload)
    if not file_path or not transcript_path or not os.path.isfile(transcript_path):
        return
    project_dir = payload.get("cwd") or os.getcwd()
    file_path = os.path.join(project_dir, file_path)
    if not os.path.isfile(file_path) or is_exempt(file_path, project_dir):
        return

    with open(file_path, encoding="utf-8", errors="replace", newline="") as target_file:
        file_content = target_file.read()
    total_lines = line_count(file_content)
    needed = needed_lines(payload["tool_name"], tool_input, file_content, total_lines)
    if total_lines == 0 or needed is None:
        return

    target_real_path = os.path.realpath(file_path)
    history = file_history(transcript_path, target_real_path, payload.get("tool_use_id"))
    if history is None:
        return
    reads, last_session_write = history
    state_path = allowed_writes_path(payload)
    allowed_writes = load_allowed_writes(state_path)
    last_allowed_write = allowed_writes.get(target_real_path)
    changed_at = os.path.getmtime(file_path)
    changed_by_session = (
        last_session_write is not None and changed_at <= last_session_write + SESSION_WRITE_TOLERANCE_SECONDS
    ) or (
        isinstance(last_allowed_write, (int, float))
        and last_allowed_write - SESSION_WRITE_TOLERANCE_SECONDS <= changed_at <= last_allowed_write + ALLOWED_WRITE_WINDOW_SECONDS
    )
    fresh_ranges = [line_range for read_at, line_range in reads if changed_by_session or read_at >= changed_at]
    gap = first_gap(fresh_ranges, *needed)
    if not gap:
        record_allowed_write(state_path, allowed_writes, target_real_path)
        return
    if len(fresh_ranges) < len(reads):
        deny(f"{file_path} changed on disk after it was read (stale read); Read it again before editing.")
    else:
        deny(f"{file_path} was only partially read (lines {gap[0]}-{gap[1]} unread); Read it in full before editing.")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
