#!/usr/bin/env python3
"""Reads a conductor RUN.md: where a run resumes and whether a budget is spent.

  run_state.py next   <RUN.md>
  run_state.py budget <RUN.md> [--now <iso8601>]
  run_state.py limits <RUN.md>
  run_state.py lock   acquire|release|status <RUN.md> [--owner <name>] [--now <iso8601>]

Entries are lines shaped `- <UTC timestamp> | <kind> | <text>`; anything else
(headings, notes) is ignored. Defaults: 6 polish rounds, 6 hours of active run
time. `process=minimal|standard|full` (default standard) sets the round limit
(2, 6, 6) unless an explicit `rounds=N` is given; `limits` prints the result. Active time is summed across sittings: a sitting runs from a `start` or
`resume` entry to the next `stop` or `done`, so waiting for an answer is free.
A sitting that ends without a stop (a crash) counts to its last entry written
by the run; the user's `answer` and `budget` lines never extend it, and a
`budget` line, like a `note`, never changes where the run resumes.

The lock is the file `RUN.md.lock` next to RUN.md, holding `owner` and `since`
lines. One conductor holds it per run: acquire is refused (exit 4) while
another owner holds it, the holder acquiring again refreshes `since`, release
removes it, and a lock not refreshed for 2 hours is stale and taken over. The
conductor re-acquires at every phase end, so a live run never goes stale.
"""

import argparse
import os
import re
import sys
from datetime import datetime, timezone

DEFAULT_ROUNDS = 6
DEFAULT_HOURS = 6.0
DEFAULT_PROCESS = "standard"
# Polish rounds per process setting; minimal is a quick prototype, full adds judges rather than rounds.
PROCESS_ROUNDS = {"minimal": 2, "standard": 6, "full": 6}
# Written by the user or as asides: they never move the resume point or extend a sitting.
NOT_RUN_STATE = ("note", "budget")
NOT_RUN_TIME = ("note", "budget", "answer")
# Distinct from 1 (a usage error) so the conductor can tell a spent budget from a failed call.
BUDGET_SPENT_EXIT = 3
# Exit code for a lock held by another owner.
LOCK_HELD_EXIT = 4
# A conductor refreshes the lock at every phase end; two hours without one means it died.
LOCK_STALE_HOURS = 2.0
ENTRY = re.compile(r"^- (\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ) \| ([a-z-]+) \| ?(.*)$")


def parse_time(text):
    return datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def read_entries(path):
    entries = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            match = ENTRY.match(line.rstrip("\n"))
            if match:
                entries.append((parse_time(match.group(1)), match.group(2), match.group(3)))
    return entries


def next_action(entries):
    entries = [entry for entry in entries if entry[1] not in NOT_RUN_STATE]
    if not entries:
        return "start"
    _, last_kind, last_text = entries[-1]
    if last_kind == "done":
        return "done"
    if last_kind == "stop":
        return "waiting: " + last_text.split(" | ")[0].strip()
    if last_kind == "answer":
        for _, kind, text in reversed(entries):
            if kind == "stop":
                return "resume: " + text.split(" | ")[0].strip() + " | " + last_text
        return "continue: " + last_text
    return "continue: " + last_text


def configured_limit(entries, key, default, cast):
    value = default
    for _, kind, text in entries:
        if kind in ("start", "budget"):
            found = re.search(r"\b" + key + r"=(\d+(?:\.\d+)?)", text)
            if found:
                value = cast(found.group(1))
    return value


def configured_process(entries):
    value = DEFAULT_PROCESS
    for _, kind, text in entries:
        if kind in ("start", "budget"):
            found = re.search(r"\bprocess=(\S+)", text)
            if found:
                value = found.group(1).rstrip(",.;")
    if value not in PROCESS_ROUNDS:
        raise SystemExit("process=%s is not valid; use minimal, standard or full" % value)
    return value


def round_limit(entries):
    return configured_limit(entries, "rounds", PROCESS_ROUNDS[configured_process(entries)], int)


def active_hours(entries, now):
    total_seconds = 0.0
    sitting_start = None
    last_time = None
    for time, kind, _ in entries:
        if kind in ("start", "resume"):
            if sitting_start is not None:
                total_seconds += (last_time - sitting_start).total_seconds()
            sitting_start = time
        elif kind in ("stop", "done") and sitting_start is not None:
            total_seconds += (time - sitting_start).total_seconds()
            sitting_start = None
        if kind not in NOT_RUN_TIME:
            last_time = time
    if sitting_start is not None:
        total_seconds += (now - sitting_start).total_seconds()
    return total_seconds / 3600


def check_budget(entries, now):
    max_rounds = round_limit(entries)
    max_hours = configured_limit(entries, "hours", DEFAULT_HOURS, float)
    rounds = sum(1 for _, kind, _ in entries if kind == "round")
    if rounds >= max_rounds:
        return "stop: rounds spent (%d of %d)" % (rounds, max_rounds)
    hours = active_hours(entries, now)
    if hours >= max_hours:
        return "stop: hours spent (%.1f of %g)" % (hours, max_hours)
    return "ok"


def lock_path(run_file):
    return run_file + ".lock"


def read_lock(path):
    try:
        with open(path, encoding="utf-8") as handle:
            fields = dict(line.rstrip("\n").split("=", 1) for line in handle if "=" in line)
        return fields["owner"], parse_time(fields["since"])
    except FileNotFoundError:
        return None
    except (KeyError, ValueError):
        # An unreadable lock cannot name a holder; treat it as long expired.
        return "unknown", datetime.fromtimestamp(0, timezone.utc)


def write_lock(path, owner, now, exclusive):
    text = "owner=%s\nsince=%s\n" % (owner, now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    flags = os.O_WRONLY | os.O_CREAT | (os.O_EXCL if exclusive else os.O_TRUNC)
    descriptor = os.open(path, flags, 0o644)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        handle.write(text)


def run_lock(action, run_file, owner, now):
    path = lock_path(run_file)
    held = read_lock(path)
    if action == "status":
        if held is None:
            print("free")
            return 0
        stale = (now - held[1]).total_seconds() / 3600 >= LOCK_STALE_HOURS
        print("held by %s since %s%s" % (held[0], held[1].strftime("%Y-%m-%dT%H:%M:%SZ"), " (stale)" if stale else ""))
        return 0 if stale else LOCK_HELD_EXIT
    if not owner:
        raise SystemExit("--owner is required for lock " + action)
    if action == "release":
        if held is None:
            print("free")
            return 0
        if held[0] != owner:
            print("not released: held by %s" % held[0])
            return LOCK_HELD_EXIT
        os.remove(path)
        print("released")
        return 0
    if held is None:
        try:
            write_lock(path, owner, now, exclusive=True)
        except FileExistsError:
            print("refused: another conductor just took the lock")
            return LOCK_HELD_EXIT
        print("acquired")
        return 0
    held_owner, held_since = held
    if held_owner == owner:
        write_lock(path, owner, now, exclusive=False)
        print("refreshed")
        return 0
    if (now - held_since).total_seconds() / 3600 >= LOCK_STALE_HOURS:
        write_lock(path, owner, now, exclusive=False)
        print("acquired: took over a stale lock from %s (since %s)" % (held_owner, held_since.strftime("%Y-%m-%dT%H:%M:%SZ")))
        return 0
    print("refused: held by %s since %s" % (held_owner, held_since.strftime("%Y-%m-%dT%H:%M:%SZ")))
    return LOCK_HELD_EXIT


def resolve_now(text):
    try:
        return parse_time(text) if text else datetime.now(timezone.utc)
    except ValueError:
        raise SystemExit(f"--now '{text}' is not a UTC time; use 2026-01-31T12:00:00Z")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["next", "budget", "limits", "lock"])
    parser.add_argument("rest", nargs="+", help="RUN.md, or for lock: acquire|release|status then RUN.md")
    parser.add_argument("--owner", help="lock owner name, for example the conductor's run id")
    parser.add_argument("--now", help="UTC time as 2026-01-31T12:00:00Z; defaults to the clock")
    args = parser.parse_args()
    if args.command == "lock":
        if len(args.rest) != 2 or args.rest[0] not in ("acquire", "release", "status"):
            raise SystemExit("usage: run_state.py lock acquire|release|status <RUN.md> [--owner <name>]")
        return run_lock(args.rest[0], args.rest[1], args.owner, resolve_now(args.now))
    run_file = args.rest[0]
    try:
        entries = read_entries(run_file)
    except FileNotFoundError:
        entries = []
    if args.command == "next":
        print(next_action(entries))
        return 0
    if args.command == "limits":
        print("process=%s rounds=%d hours=%g" % (configured_process(entries), round_limit(entries), configured_limit(entries, "hours", DEFAULT_HOURS, float)))
        return 0
    verdict = check_budget(entries, resolve_now(args.now))
    print(verdict)
    return 0 if verdict == "ok" else BUDGET_SPENT_EXIT


if __name__ == "__main__":
    sys.exit(main())
