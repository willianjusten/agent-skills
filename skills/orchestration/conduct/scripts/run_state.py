#!/usr/bin/env python3
"""Reads a conductor RUN.md: where a run resumes and whether a budget is spent.

  run_state.py next   <RUN.md>
  run_state.py budget <RUN.md> [--now <iso8601>]

Entries are lines shaped `- <UTC timestamp> | <kind> | <text>`; anything else
(headings, notes) is ignored. Defaults: 6 polish rounds, 4 hours per sitting.
"""

import argparse
import re
import sys
from datetime import datetime, timezone

DEFAULT_ROUNDS = 6
DEFAULT_HOURS = 4.0
BUDGET_SPENT_EXIT = 3
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


def limit(entries, key, default, cast):
    value = default
    for _, kind, text in entries:
        if kind in ("start", "budget"):
            found = re.search(r"\b" + key + r"=(\d+(?:\.\d+)?)", text)
            if found:
                value = cast(found.group(1))
    return value


def check_budget(entries, now):
    max_rounds = limit(entries, "rounds", DEFAULT_ROUNDS, int)
    max_hours = limit(entries, "hours", DEFAULT_HOURS, float)
    rounds = sum(1 for _, kind, _ in entries if kind == "round")
    if rounds >= max_rounds:
        return "stop: rounds spent (%d of %d)" % (rounds, max_rounds)
    sitting_start = None
    for time, kind, _ in entries:
        if kind in ("start", "resume"):
            sitting_start = time
    if sitting_start is not None:
        hours = (now - sitting_start).total_seconds() / 3600
        if hours >= max_hours:
            return "stop: hours spent (%.1f of %g)" % (hours, max_hours)
    return "ok"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["next", "budget"])
    parser.add_argument("run_file")
    parser.add_argument("--now", help="UTC time as 2026-01-31T12:00:00Z; defaults to the clock")
    args = parser.parse_args()
    try:
        entries = read_entries(args.run_file)
    except FileNotFoundError:
        entries = []
    if args.command == "next":
        print(next_action(entries))
        return 0
    now = parse_time(args.now) if args.now else datetime.now(timezone.utc)
    verdict = check_budget(entries, now)
    print(verdict)
    return 0 if verdict == "ok" else BUDGET_SPENT_EXIT


if __name__ == "__main__":
    sys.exit(main())
