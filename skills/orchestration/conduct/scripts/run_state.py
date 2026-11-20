#!/usr/bin/env python3
"""Reads a conductor RUN.md: where a run resumes and whether a budget is spent.

  run_state.py next   <RUN.md>   (one state line, then a `notes for the next round:` line per unread answer)
  run_state.py budget <RUN.md> [--now <iso8601>]
  run_state.py limits <RUN.md>
  run_state.py phases <RUN.md> [--now <iso8601>]
  run_state.py look   <RUN.md>
  run_state.py lock   acquire|release|status <RUN.md> [--owner <name>] [--now <iso8601>]

Entries are lines shaped `- <UTC timestamp> | <kind> | <text>`; anything else
(headings, notes) is ignored. Defaults: 6 polish rounds, 6 hours of active run
time. `process=minimal|standard|full` (default standard) sets the round limit
(2, 6, 6) unless an explicit `rounds=N` is given; `limits` prints the result. Active time is summed across sittings: a sitting runs from a `start` or
`resume` entry to the next `stop` or `done`, so waiting for an answer is free.
A sitting that ends without a stop (a crash) counts to its last entry written
by the run; the user's `answer` and `budget` lines never extend it, and a
`budget` line, like a `note`, never changes where the run resumes.

`phases` prints the active time per phase, one `<name> <duration>` line each and
a `total`. A `phase | <name>` entry starts a phase (time before the first is
`setup`); a resume carries on in the phase the sitting stopped in, and a phase
that comes back is summed. Waiting for an answer is not counted, so the total
equals the hours `budget` spends.

`look` prints the look settings and the look decision. `look=auto` and
`target=yes` in a `start` or `budget` line set the mode (default `look=ask
target=no`). The first stop is `stop | look-variants | ... variants=a,b,c`; an
`answer` after it names a variant (its name, or its 1-based number) with an
optional note, and prints `state=chosen <preset> | <note>`. An `assumption`
starting `look=auto <preset>` prints `state=auto <preset>`; a stop with no
answer prints `state=pending`, otherwise `state=none`.

A `round-start | N | branch=<name> base=<sha>` entry, written before the
polish director spawns, makes a cut-off round recoverable: when the run ends
with that entry unanswered by a `round` entry, `next` prints `read result:
round N branch <name>` if the branch has commits after `base` (the director
finished, so read its result), and `redo: round N` if it has none.

The lock is the file `RUN.md.lock` next to RUN.md, holding `owner` and `since`
lines. One conductor holds it per run: acquire is refused (exit 4) while
another owner holds it, the holder acquiring again refreshes `since`, release
removes it, and a lock not refreshed for 2 hours is stale and taken over. The
conductor re-acquires at every phase end, so a live run never goes stale.
"""

import argparse
import os
import re
import subprocess
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


def branch_has_new_commits(run_file, branch, base):
    """True when the round branch holds commits past the base recorded at round start."""
    run_dir = os.path.dirname(os.path.abspath(run_file))
    result = subprocess.run(
        ["git", "-C", run_dir, "rev-list", "--count", base + ".." + branch],
        capture_output=True, text=True,
    )
    return result.returncode == 0 and int(result.stdout.strip() or 0) > 0


def pending_round(entries, run_file):
    """The resume verdict for a round started but never logged as finished, or None."""
    for _, kind, text in reversed(entries):
        if kind == "round":
            return None
        if kind == "round-start":
            number = text.split(" | ")[0].strip()
            fields = dict(re.findall(r"(\w+)=(\S+)", text))
            if "branch" in fields and "base" in fields and branch_has_new_commits(run_file, fields["branch"], fields["base"]):
                return "read result: round %s branch %s" % (number, fields["branch"])
            return "redo: round " + number
    return None


def next_action(entries, run_file=None):
    entries = [entry for entry in entries if entry[1] not in NOT_RUN_STATE]
    if not entries:
        return "start"
    _, last_kind, last_text = entries[-1]
    if last_kind == "done":
        return "done"
    if last_kind == "stop":
        return "waiting: " + last_text.split(" | ")[0].strip()
    if last_kind == "answer":
        # The answer answers a stop only when the stop is the last run entry before it.
        run_entries = [entry for entry in entries if entry[1] != "answer"]
        if run_entries and run_entries[-1][1] == "stop":
            return "resume: " + run_entries[-1][2].split(" | ")[0].strip() + " | " + last_text
        last_text = run_entries[-1][2] if run_entries else last_text
    pending = pending_round(entries, run_file) if run_file else None
    return pending or "continue: " + last_text


def round_notes(entries):
    """Answers that arrived with no stop pending and no round begun since: notes for the next round."""
    notes = []
    previous_run_kind = None
    for _, kind, text in entries:
        if kind in NOT_RUN_STATE:
            continue
        if kind == "answer":
            if previous_run_kind != "stop":
                notes.append(text)
            continue
        if kind in ("round-start", "resume"):
            notes = []
        previous_run_kind = kind
    return notes


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


def phase_seconds(entries, now):
    """Active seconds per phase, in order of first appearance, using the sitting rules of active_hours."""
    seconds = {"setup": 0.0}
    current_phase = "setup"
    sitting_open = False
    cursor = None
    for time, kind, text in entries:
        if kind in NOT_RUN_TIME:
            continue
        if kind in ("start", "resume"):
            if sitting_open:
                seconds[current_phase] += (cursor - sitting_start).total_seconds()
            sitting_start = cursor = time
            sitting_open = True
            continue
        if not sitting_open:
            continue
        seconds[current_phase] += (time - cursor).total_seconds()
        cursor = time
        if kind == "phase":
            current_phase = text.split(" | ")[0].strip() or "setup"
            seconds.setdefault(current_phase, 0.0)
        elif kind in ("stop", "done"):
            sitting_open = False
    if sitting_open:
        seconds[current_phase] += (now - cursor).total_seconds()
    return seconds


def format_duration(total_seconds):
    minutes = int(round(total_seconds / 60))
    hours, minutes = divmod(minutes, 60)
    if hours and minutes:
        return "%dh %dm" % (hours, minutes)
    return "%dh" % hours if hours else "%dm" % minutes


def report_phases(entries, now):
    seconds = phase_seconds(entries, now)
    lines = ["%s %s" % (name, format_duration(value)) for name, value in seconds.items() if value > 0 or name != "setup"]
    lines.append("total " + format_duration(sum(seconds.values())))
    return "\n".join(lines)


def configured_flag(entries, key, default):
    value = default
    for _, kind, text in entries:
        if kind in ("start", "budget"):
            found = re.search(r"\b" + key + r"=([a-z]+)", text)
            if found:
                value = found.group(1)
    return value


def parse_variant_answer(answer, variants):
    """The preset an answer names and its note: `dusk`, `variant dusk, warmer`, `2`, `the second`."""
    words = re.sub(r"^(?:i |let's |lets )?(?:pick|choose|take|go with|variant|look|use)\b[:= ]*", "", answer.strip(), flags=re.I)
    words = re.sub(r"^(?:the |option |variant )", "", words, flags=re.I)
    first = re.match(r"([A-Za-z0-9_-]+)[\s,.:;-]*(.*)$", words, flags=re.S)
    if not first:
        return None, ""
    token, note = first.group(1), first.group(2).strip()
    ordinals = {"first": 1, "second": 2, "third": 3, "1st": 1, "2nd": 2, "3rd": 3}
    if variants:
        for name in variants:
            if token.lower() == name.lower():
                return name, note
        index = int(token) if token.isdigit() else ordinals.get(token.lower())
        if index and 1 <= index <= len(variants):
            return variants[index - 1], note
        return None, ""
    return token, note


def look_state(entries):
    """The look decision: auto pick, the user's answer to the look-variants stop, pending, or none."""
    variants = []
    stop_index = None
    for index, (_, kind, text) in enumerate(entries):
        if kind == "stop" and text.split(" | ")[0].strip() == "look-variants":
            stop_index = index
            found = re.search(r"\bvariants=([\w,-]+)", text)
            variants = found.group(1).split(",") if found else []
    for _, kind, text in reversed(entries):
        auto = re.match(r"look=auto\b[:, ]*(?:picked |pick |chose |chosen )?([\w-]+)", text) if kind == "assumption" else None
        if auto:
            return "auto " + auto.group(1)
    if stop_index is None:
        return "none"
    for _, kind, text in entries[stop_index + 1:]:
        if kind == "answer":
            preset, note = parse_variant_answer(text, variants)
            if preset is None:
                return "unclear | " + text
            return "chosen " + preset + (" | " + note if note else "")
    return "pending"


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
    parser.add_argument("command", choices=["next", "budget", "limits", "phases", "look", "lock"])
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
        print(next_action(entries, run_file))
        for note in round_notes(entries):
            print("notes for the next round: " + note)
        return 0
    if args.command == "limits":
        print("process=%s rounds=%d hours=%g" % (configured_process(entries), round_limit(entries), configured_limit(entries, "hours", DEFAULT_HOURS, float)))
        return 0
    if args.command == "look":
        print("look=%s target=%s" % (configured_flag(entries, "look", "ask"), configured_flag(entries, "target", "no")))
        print("state=" + look_state(entries))
        return 0
    if args.command == "phases":
        print(report_phases(entries, resolve_now(args.now)))
        return 0
    verdict = check_budget(entries, resolve_now(args.now))
    print(verdict)
    return 0 if verdict == "ok" else BUDGET_SPENT_EXIT


if __name__ == "__main__":
    sys.exit(main())
