#!/usr/bin/env python3
"""Reads a conductor RUN.md: where a run resumes and whether a budget is spent.

  run_state.py next   <RUN.md> [--allow-missing]
                      (one state line, then a `notes for the next round:` line per unread answer)
  run_state.py budget <RUN.md> [--now <iso8601>]
  run_state.py rows   <RUN.md>
  run_state.py limits <RUN.md>
  run_state.py accepts <RUN.md>
  run_state.py phases <RUN.md> [--now <iso8601>]
  run_state.py phase-names
  run_state.py look   <RUN.md>
  run_state.py lock   acquire|release|status <RUN.md> [--owner <name>] [--now <iso8601>]

A RUN.md that does not exist is an error (exit 2), so a mistyped path never reads
as a fresh run; only `next --allow-missing` prints `start` for it.

Entries are lines shaped `- <UTC timestamp> | <kind> | <text>`; headings and
prose are ignored. A line that starts with `- ` and holds ` | ` but does not
parse (capital kind, no trailing Z, impossible date) is skipped with a warning
on stderr. Defaults: 6 polish rounds, 6 hours of active run time, 3 autonomous
accepts. `process=minimal|standard|full` (default standard) sets the round
limit (2, 6, 6) unless an explicit whole-number `rounds=N` is given; `limits`
prints the result with `autoAccepts=N`. `accepts` prints `accepts-since-answer=K
of N`: the `accept` entries since the user's last `answer`, against the limit.

`mode=overnight|review` in a `start` or `budget` line (default `review`) says who
decides between rounds. `limits` prints it first. Overnight is fully autonomous:
`accepts` and `limits` print `unlimited` for the accept limit and the round limit
unless `autoAccepts=N` or `rounds=N` was given, and `look` defaults to `auto`;
the hours still bound the run. In review mode `next` prints `waiting: round-review`
when the last run entry is a `round` (the conductor normally writes `stop |
round-review` itself, and the answer to it reads like any stop's answer).

`budget` prints `reserve: <left> left of <hours>h, delivery reserve <N>m` (exit 0)
when the remaining hours are at or below the delivery reserve, the time kept for the
trailer round and delivery: the conductor then stops polishing and moves on. The
reserve is `reserve=<minutes>` in a `start` or `budget` line (default 40).

`rows` reads `row` entries, `row | <name> | turn <N> | score <V>/<F> of target <T> |
kept|reverted|pending | approach: <text>`: one per row per turn, with the row's
state after the turn (a reverted turn carries the score of the version it kept).
`turn 0 | score -/- | pending` declares a row before it is worked. It prints one
line per row (`turns`, `score` as V/F, `counted` as the lower of the two, `target`,
`at-target`, `last`, and `lost=K` after K losses in a row), then `next:` with the
rows to pick, never-worked first, then fewest turns, then lowest counted score,
then checklist order; a row whose last turn was reverted carries `(new approach)`,
and one lost twice in a row `(shrink scope)`. The last line is `all-at-target=yes|no`.

`next` prints `continue: phase=<name> | last=<kind>: <text>`, where the phase
is the last `phase` entry (`setup` before the first) and the last entry is the
last run entry (a `note` or `budget` line is not one).

Active time is summed across sittings: a sitting runs from a `start` or
`resume` entry to the next `stop` or `done`, so waiting for an answer is free.
A sitting that ends without a stop (a crash) counts to its last entry written
by the run; the user's `answer` and `budget` lines never extend it, and a
`budget` line, like a `note`, never changes where the run resumes.

`phase-names` prints the phase names in run order, one per line.

`phases` prints the active time per phase, one `<name> <duration>` line each and
a `total`. A `phase | <name>` entry starts a phase (time before the first is
`setup`); a resume carries on in the phase the sitting stopped in, and a phase
that comes back is summed. Waiting for an answer is not counted; `budget` spends
this same total.

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
finished, so read its result), and `redo: round N` if it has none. When the
entry lacks `branch=` or `base=`, or git cannot check the branch, the redo line
says so in parentheses: read the branch yourself before respawning a director.

The lock is the file `RUN.md.lock` next to RUN.md, holding `owner` and `since`
lines. One conductor holds it per run: acquire is refused (exit 4) while
another owner holds it, the holder acquiring again refreshes `since`, release
removes it, and a lock not refreshed for 2 hours is stale and taken over. The
conductor re-acquires at every phase end, so a live run never goes stale. The
file appears whole (written aside, then linked or renamed into place) and a
takeover is confirmed by reading it back. `lock status` exits 4 while the lock
is held (and not stale): the code is the answer, not a failure.
"""

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime, timezone

DEFAULT_ROUNDS = 6
DEFAULT_HOURS = 6.0
DEFAULT_AUTO_ACCEPTS = 3
DEFAULT_PROCESS = "standard"
DEFAULT_MODE = "review"
# Minutes kept at the end of the budget for the trailer round and delivery.
DEFAULT_RESERVE_MINUTES = 40
MODES = ("overnight", "review")
# What an uncapped limit prints, so a reader never mistakes it for a number.
UNLIMITED = "unlimited"
PHASE_NAMES = ("brief", "art-bible", "first-playable", "look-variants", "checklist", "polish", "reference-judge", "deliver")
# Polish rounds per process setting; minimal is a quick prototype, full adds judges rather than rounds.
PROCESS_ROUNDS = {"minimal": 2, "standard": 6, "full": 6}
# Written by the user or as asides: they never move the resume point or extend a sitting.
NOT_RUN_STATE = ("note", "budget")
NOT_RUN_TIME = ("note", "budget", "answer")
# Distinct from 1 (a usage error) so the conductor can tell a spent budget from a failed call.
BUDGET_SPENT_EXIT = 3
# A usage error the conductor must see rather than read as a fresh run: a missing RUN.md.
MISSING_FILE_EXIT = 2
# Exit code for a lock held by another owner.
LOCK_HELD_EXIT = 4
# A conductor refreshes the lock at every phase end; two hours without one means it died.
LOCK_STALE_HOURS = 2.0
ENTRY = re.compile(r"^- (\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ) \| ([a-z-]+) \| ?(.*)$")
# A line that looks like an entry attempt: a bullet with at least two bars.
SCORE = r"(\d+(?:\.\d+)?)"
ROW = re.compile(
    r"^(.+?) \| turn (\d+) \| score (?:-/-|" + SCORE + "/" + SCORE + r") of target " + SCORE
    + r" \| (kept|reverted|pending)(?: \| approach: (.*))?$"
)
ENTRY_ATTEMPT = re.compile(r"^- .* \| .* \|")


def parse_time(text):
    return datetime.strptime(text, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)


def read_entries(path):
    entries = []
    with open(path, encoding="utf-8") as handle:
        for number, line in enumerate(handle, 1):
            line = line.rstrip("\n")
            match = ENTRY.match(line)
            try:
                if match:
                    entries.append((parse_time(match.group(1)), match.group(2), match.group(3)))
                    continue
            except ValueError:
                pass
            if ENTRY_ATTEMPT.match(line):
                print("%s:%d: skipped, not a valid entry: %s" % (path, number, line[:80]), file=sys.stderr)
    return entries


def branch_has_new_commits(run_file, branch, base):
    """True when the round branch holds commits past the base recorded at round start; None when git cannot tell."""
    run_dir = os.path.dirname(os.path.abspath(run_file))
    result = subprocess.run(
        ["git", "-C", run_dir, "rev-list", "--count", base + ".." + branch],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    return int(result.stdout.strip() or 0) > 0


def pending_round(entries, run_file):
    """The resume verdict for a round started but never logged as finished, or None."""
    for _, kind, text in reversed(entries):
        if kind == "round":
            return None
        if kind == "round-start":
            number = text.split(" | ")[0].strip()
            fields = dict(re.findall(r"(\w+)=(\S+)", text))
            if "branch" not in fields or "base" not in fields:
                return "redo: round %s (no branch and base recorded)" % number
            has_commits = branch_has_new_commits(run_file, fields["branch"], fields["base"])
            if has_commits is None:
                return "redo: round %s (branch check failed, read the branch before respawning)" % number
            if has_commits:
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
    run_entries = [entry for entry in entries if entry[1] != "answer"]
    if configured_mode(entries) == "review" and run_entries and run_entries[-1][1] == "round":
        # A round ended and the user has not reviewed it; a missing `stop` line must not let the run carry on.
        if last_kind == "answer":
            return "resume: round-review | " + last_text
        return "waiting: round-review"
    if last_kind == "answer":
        # The answer answers a stop only when the stop is the last run entry before it.
        if run_entries and run_entries[-1][1] == "stop":
            return "resume: " + run_entries[-1][2].split(" | ")[0].strip() + " | " + last_text
        if run_entries:
            _, last_kind, last_text = run_entries[-1]
    pending = pending_round(entries, run_file) if run_file else None
    return pending or "continue: phase=%s | last=%s: %s" % (current_phase(entries), last_kind, last_text)


def current_phase(entries):
    """The name in the last `phase` entry, or `setup` before the first."""
    name = "setup"
    for _, kind, text in entries:
        if kind == "phase":
            name = text.split(" | ")[0].strip() or "setup"
    return name


def round_notes(entries):
    """Answers that arrived with no stop pending and no round begun since: notes for the next round."""
    notes = []
    previous_run_kind = None
    review_mode = configured_mode(entries) == "review"
    for _, kind, text in entries:
        if kind in NOT_RUN_STATE:
            continue
        if kind == "answer":
            answers_round_review = review_mode and previous_run_kind == "round"
            if previous_run_kind != "stop" and not answers_round_review:
                notes.append(text)
            continue
        if kind == "round-start":
            notes = []
        previous_run_kind = kind
    return notes


def last_setting(entries, key, value_pattern):
    """The latest `key=value` in a start or budget line, or None; value_pattern is the regex for the value."""
    value = None
    for _, kind, text in entries:
        if kind in ("start", "budget"):
            found = re.search(r"\b" + key + "=(" + value_pattern + ")", text)
            if found:
                value = found.group(1)
    return value


def configured_limit(entries, key, default, cast):
    value = last_setting(entries, key, r"\d+(?:\.\d+)?")
    if value is None:
        return default
    if cast is int and not value.isdigit():
        raise SystemExit("%s=%s is not valid; use a whole number" % (key, value))
    return cast(value)


def configured_mode(entries):
    value = last_setting(entries, "mode", r"[a-z]+") or DEFAULT_MODE
    if value not in MODES:
        raise SystemExit("mode=%s is not valid; use overnight or review" % value)
    return value


def accept_limit(entries):
    """The autonomous-accept limit: the explicit autoAccepts=N, else unlimited overnight, else the default; None means unlimited."""
    explicit = last_setting(entries, "autoAccepts", r"\d+(?:\.\d+)?")
    if explicit is None and configured_mode(entries) == "overnight":
        return None
    return configured_limit(entries, "autoAccepts", DEFAULT_AUTO_ACCEPTS, int)


def accepts_report(entries):
    """`accepts-since-answer=K of N`: accept entries after the user's last answer, against the limit."""
    since_answer = 0
    for _, kind, _ in entries:
        if kind == "answer":
            since_answer = 0
        elif kind == "accept":
            since_answer += 1
    limit = accept_limit(entries)
    return "accepts-since-answer=%d of %s" % (since_answer, UNLIMITED if limit is None else limit)


def configured_process(entries):
    value = last_setting(entries, "process", r"[a-z]+") or DEFAULT_PROCESS
    if value not in PROCESS_ROUNDS:
        raise SystemExit("process=%s is not valid; use minimal, standard or full" % value)
    return value


def round_limit(entries):
    """The polish round limit; None (unlimited) overnight unless rounds=N was given, since the hours bound that run."""
    if last_setting(entries, "rounds", r"\d+(?:\.\d+)?") is None and configured_mode(entries) == "overnight":
        return None
    return configured_limit(entries, "rounds", PROCESS_ROUNDS[configured_process(entries)], int)


def active_hours(entries, now):
    return sum(phase_seconds(entries, now).values()) / 3600


def phase_seconds(entries, now):
    """Active seconds per phase, in order of first appearance. A sitting that ended without a stop counts to its last run entry."""
    seconds = {"setup": 0.0}
    current_phase = "setup"
    sitting_open = False
    cursor = None
    for time, kind, text in entries:
        if kind in NOT_RUN_TIME:
            continue
        if kind in ("start", "resume"):
            cursor = time
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
    return last_setting(entries, key, r"[a-z]+") or default


def configured_look(entries):
    """look=ask|auto; overnight implies auto unless look= was given."""
    return configured_flag(entries, "look", "auto" if configured_mode(entries) == "overnight" else "ask")


def parse_variant_answer(answer, variants):
    """The preset an answer names and its note: a variant name or its 1-based number, then an optional note."""
    exact = re.match(r"([A-Za-z0-9_-]+)[\s,.:;-]*(.*)$", answer.strip(), flags=re.S)
    for name in variants:
        if exact and exact.group(1).lower() == name.lower():
            return name, exact.group(2).strip()
    words = re.sub(r"^(?:i |let's |lets )?(?:pick|choose|take|go with|variant|look|use)\b[:= ]*", "", answer.strip(), flags=re.I)
    first = re.match(r"([A-Za-z0-9_-]+)[\s,.:;-]*(.*)$", words, flags=re.S)
    if not first:
        return None, ""
    token, note = first.group(1), first.group(2).strip()
    if not variants:
        return token, note
    for name in variants:
        if token.lower() == name.lower():
            return name, note
    if token.isdigit() and 1 <= int(token) <= len(variants):
        return variants[int(token) - 1], note
    return None, ""


def look_state(entries):
    """The look decision: the latest of an auto pick and the user's answer to the look-variants stop, else pending or none."""
    variants = []
    stop_index = None
    for index, (_, kind, text) in enumerate(entries):
        if kind == "stop" and text.split(" | ")[0].strip() == "look-variants":
            stop_index = index
            found = re.search(r"\bvariants=([\w,-]+)", text)
            variants = found.group(1).split(",") if found else []
    auto_index, auto_state = None, None
    for index, (_, kind, text) in enumerate(entries):
        auto = re.match(r"look=auto\b[:, ]*(?:picked |pick |chose |chosen )?([\w-]+)", text) if kind == "assumption" else None
        if auto:
            auto_index, auto_state = index, "auto " + auto.group(1)
    answer_index, answer_state = None, None
    if stop_index is not None:
        for index in range(stop_index + 1, len(entries)):
            _, kind, text = entries[index]
            if kind == "answer":
                preset, note = parse_variant_answer(text, variants)
                answer_index = index
                answer_state = "unclear | " + text if preset is None else "chosen " + preset + (" | " + note if note else "")
                break
    if auto_index is not None and (answer_index is None or auto_index > answer_index or answer_state.startswith("unclear")):
        return auto_state
    if answer_state:
        return answer_state
    return "none" if stop_index is None else "pending"


def check_budget(entries, now):
    max_rounds = round_limit(entries)
    max_hours = configured_limit(entries, "hours", DEFAULT_HOURS, float)
    rounds = sum(1 for _, kind, _ in entries if kind == "round")
    if max_rounds is not None and rounds >= max_rounds:
        return "stop: rounds spent (%d of %d)" % (rounds, max_rounds)
    hours = active_hours(entries, now)
    if hours >= max_hours:
        return "stop: hours spent (%.1f of %g)" % (hours, max_hours)
    reserve_minutes = configured_limit(entries, "reserve", DEFAULT_RESERVE_MINUTES, int)
    minutes_left = round((max_hours - hours) * 60, 3)
    if minutes_left <= reserve_minutes:
        return "reserve: %s left of %gh, delivery reserve %dm" % (format_duration(minutes_left * 60), max_hours, reserve_minutes)
    return "ok"


def row_report(entries):
    """One line per row, then the rows to pick next and whether every row is at target."""
    rows = {}
    for _, kind, text in entries:
        if kind != "row":
            continue
        match = ROW.match(text.strip())
        if not match:
            print("not a valid row entry: %s" % text[:80], file=sys.stderr)
            continue
        name, turn, visual, feel, target, outcome, _ = match.groups()
        row = rows.setdefault(name, {"target": float(target), "turns": [], "score": None})
        row["target"] = float(target)
        if int(turn) == 0:
            continue
        row["turns"].append((outcome, text.split("approach:", 1)[1].strip() if "approach:" in text else ""))
        row["score"] = (visual, feel) if visual is not None else None
    if not rows:
        return "no rows logged"
    lines, candidates = [], []
    for order, (name, row) in enumerate(rows.items()):
        counted = min(float(value) for value in row["score"]) if row["score"] else None
        at_target = counted is not None and counted >= row["target"]
        lost = 0
        for outcome, _ in reversed(row["turns"]):
            if outcome != "reverted":
                break
            lost += 1
        last = row["turns"][-1][0] if row["turns"] else "none"
        lines.append("%s turns=%d score=%s counted=%s target=%s at-target=%s last=%s%s" % (
            name, len(row["turns"]), "/".join(row["score"]) if row["score"] else "-",
            "%g" % counted if counted is not None else "-", "%g" % row["target"],
            "yes" if at_target else "no", last, " lost=%d" % lost if lost else ""))
        if not at_target:
            note = " (shrink scope)" if lost >= 2 else " (new approach)" if lost else ""
            candidates.append((len(row["turns"]), counted if counted is not None else -1, order, name + note))
    lines.append("next: " + ", ".join(name for _, _, _, name in sorted(candidates)))
    lines.append("all-at-target=" + ("no" if candidates else "yes"))
    return "\n".join(lines)


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
    """Write the lock whole: aside first, then linked into place (exclusive) or renamed over the old one."""
    text = "owner=%s\nsince=%s\n" % (owner, now.strftime("%Y-%m-%dT%H:%M:%SZ"))
    aside = "%s.%d.tmp" % (path, os.getpid())
    with open(aside, "w", encoding="utf-8") as handle:
        handle.write(text)
    try:
        if exclusive:
            os.link(aside, path)
        else:
            os.replace(aside, path)
    finally:
        if os.path.exists(aside):
            os.remove(aside)


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
        confirmed = read_lock(path)
        if confirmed is None or confirmed[0] != owner:
            print("refused: another conductor took over the stale lock first")
            return LOCK_HELD_EXIT
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
    parser.add_argument("command", choices=["next", "budget", "rows", "limits", "accepts", "phases", "phase-names", "look", "lock"])
    parser.add_argument("rest", nargs="*", help="RUN.md, or for lock: acquire|release|status then RUN.md")
    parser.add_argument("--allow-missing", action="store_true", help="next only: a missing RUN.md reads as a new run")
    parser.add_argument("--owner", help="lock owner name, for example the conductor's run id")
    parser.add_argument("--now", help="UTC time as 2026-01-31T12:00:00Z; defaults to the clock")
    args = parser.parse_args()
    if args.command == "lock":
        if len(args.rest) != 2 or args.rest[0] not in ("acquire", "release", "status"):
            raise SystemExit("usage: run_state.py lock acquire|release|status <RUN.md> [--owner <name>]")
        return run_lock(args.rest[0], args.rest[1], args.owner, resolve_now(args.now))
    if args.command == "phase-names":
        print("\n".join(PHASE_NAMES))
        return 0
    if len(args.rest) != 1:
        raise SystemExit("usage: run_state.py %s <RUN.md>" % args.command)
    run_file = args.rest[0]
    try:
        entries = read_entries(run_file)
    except FileNotFoundError:
        if not (args.command == "next" and args.allow_missing):
            print("%s does not exist; check the path" % run_file, file=sys.stderr)
            return MISSING_FILE_EXIT
        entries = []
    if args.command == "next":
        print(next_action(entries, run_file))
        for note in round_notes(entries):
            print("notes for the next round: " + note)
        return 0
    if args.command == "limits":
        rounds, accepts = round_limit(entries), accept_limit(entries)
        print("mode=%s process=%s rounds=%s hours=%g autoAccepts=%s" % (
            configured_mode(entries), configured_process(entries), UNLIMITED if rounds is None else rounds,
            configured_limit(entries, "hours", DEFAULT_HOURS, float), UNLIMITED if accepts is None else accepts))
        return 0
    if args.command == "accepts":
        print(accepts_report(entries))
        return 0
    if args.command == "look":
        print("look=%s target=%s" % (configured_look(entries), configured_flag(entries, "target", "no")))
        print("state=" + look_state(entries))
        return 0
    if args.command == "phases":
        print(report_phases(entries, resolve_now(args.now)))
        return 0
    if args.command == "rows":
        print(row_report(entries))
        return 0
    verdict = check_budget(entries, resolve_now(args.now))
    print(verdict)
    return BUDGET_SPENT_EXIT if verdict.startswith("stop") else 0


if __name__ == "__main__":
    sys.exit(main())
