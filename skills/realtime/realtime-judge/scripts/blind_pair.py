#!/usr/bin/env python3
"""Blind before/after pairing and decision for polish-round judging.

prepare: copies the two captures into a judge directory as x.png and y.png in a
random order and records the mapping in a separate file. Given two folders (a
motion capture's sheets), it copies them to x/ and y/ instead. It never prints the mapping.

decide: reads the mapping and each judge's scores for X and Y, maps them back to
before and after, counts the lowest judge per capture, and keeps the change only
if it wins or ties. A still moment takes --visual and --feel; a motion window
takes --motion; all three together count the lowest of the three. With --visual-gap and --feel-gap (target-gap
scores against a benchmark), the lower gap score per capture must also win or tie.
"""

import argparse
import json
import random
import shutil
import sys
from pathlib import Path

STILL_LENSES = ("visual", "feel")
MOTION_LENS = "motion"
LENSES = (*STILL_LENSES, MOTION_LENS)
BEFORE, AFTER = "before", "after"
SIDES = (BEFORE, AFTER)
FIRST_LABEL, SECOND_LABEL = "X", "Y"
LABELS = (FIRST_LABEL, SECOND_LABEL)
MIN_SCORE, MAX_SCORE = 1, 10


def prepare(arguments):
    rng = random.Random(arguments.seed) if arguments.seed is not None else random.SystemRandom()
    sides = list(SIDES)
    rng.shuffle(sides)
    sources = {BEFORE: Path(arguments.before), AFTER: Path(arguments.after)}
    if sources[BEFORE].is_dir() != sources[AFTER].is_dir():
        raise SystemExit("Give two images or two folders, not one of each")
    if sources[BEFORE].is_dir() and sorted(p.name for p in sources[BEFORE].iterdir()) != sorted(p.name for p in sources[AFTER].iterdir()):
        raise SystemExit("The two folders must hold the same file names, or the names give the order away")
    judge_dir = Path(arguments.judge_dir)
    judge_dir.mkdir(parents=True, exist_ok=True)
    for label, side in zip((label.lower() for label in LABELS), sides):
        if sources[side].is_dir():
            shutil.copytree(sources[side], judge_dir / label, dirs_exist_ok=True)
        else:
            shutil.copyfile(sources[side], judge_dir / f"{label}.png")
    mapping_path = Path(arguments.mapping)
    mapping_path.parent.mkdir(parents=True, exist_ok=True)
    mapping = {FIRST_LABEL: sides[0], SECOND_LABEL: sides[1], "seed": arguments.seed}
    mapping_path.write_text(json.dumps(mapping, indent=2) + "\n")
    print(f"Prepared X and Y in {judge_dir}. Mapping saved for the packet only.")


def parse_scores(text):
    scores = {}
    for pair in text.split(","):
        label, _, value = pair.partition("=")
        label = label.strip().upper()
        if label not in LABELS:
            raise SystemExit(f"Unknown label '{label}' in '{text}'; use X=n,Y=n")
        try:
            score = float(value)
        except ValueError:
            raise SystemExit(f"Score '{value}' is not a number")
        if not MIN_SCORE <= score <= MAX_SCORE:
            raise SystemExit(f"Score {score:g} is outside {MIN_SCORE}-{MAX_SCORE}")
        scores[label] = score
    if set(scores) != set(LABELS):
        raise SystemExit(f"Need both X and Y scores, got '{text}'")
    return scores


def format_score(value):
    return int(value) if float(value).is_integer() else value


def unshuffle(mapping, text_by_lens):
    by_side = {}
    for lens, text in text_by_lens.items():
        scores = parse_scores(text)
        by_side[lens] = {mapping[label]: scores[label] for label in LABELS}
    counted = {side: min(scores[side] for scores in by_side.values()) for side in SIDES}
    shown = {lens: {side: format_score(scores[side]) for side in SIDES} for lens, scores in by_side.items()}
    return shown, counted


def decide(arguments):
    mapping = json.loads(Path(arguments.mapping).read_text())
    if (arguments.visual is None) != (arguments.feel is None):
        raise SystemExit("Give both --visual and --feel, or neither")
    lens_scores = {lens: getattr(arguments, lens) for lens in LENSES if getattr(arguments, lens) is not None}
    if not lens_scores:
        raise SystemExit("Give --visual and --feel for a still moment, --motion for a motion window, or all three")
    shown_scores, counted = unshuffle(mapping, lens_scores)
    keep = counted[AFTER] >= counted[BEFORE]
    has_gap = arguments.visual_gap is not None or arguments.feel_gap is not None
    if has_gap and (arguments.visual_gap is None or arguments.feel_gap is None):
        raise SystemExit("Give both --visual-gap and --feel-gap, or neither")
    result = {
        "mapping": {FIRST_LABEL: mapping[FIRST_LABEL], SECOND_LABEL: mapping[SECOND_LABEL], "seed": mapping.get("seed")},
        "scores": shown_scores,
        "before_counted": format_score(counted[BEFORE]),
        "after_counted": format_score(counted[AFTER]),
    }
    if has_gap:
        gap_scores, gap_counted = unshuffle(mapping, {"visual": arguments.visual_gap, "feel": arguments.feel_gap})
        keep = keep and gap_counted[AFTER] >= gap_counted[BEFORE]
        result["gap_scores"] = gap_scores
        result["gap_before_counted"] = format_score(gap_counted[BEFORE])
        result["gap_after_counted"] = format_score(gap_counted[AFTER])
    result["decision"] = "keep" if keep else "reject"
    if arguments.markdown:
        print(markdown(result))
    else:
        print(json.dumps(result, indent=2))


def markdown(result):
    rows = "\n".join(
        f"| {lens.capitalize()} judge | {result['scores'][lens]['before']} | {result['scores'][lens]['after']} |"
        for lens in result["scores"]
    )
    gap_rows = ""
    if "gap_scores" in result:
        gap_rows = "".join(
            f"| {lens.capitalize()} judge, target gap | {result['gap_scores'][lens]['before']} | {result['gap_scores'][lens]['after']} |\n"
            for lens in STILL_LENSES
        ) + f"| Counted target gap (lower of the two) | {result['gap_before_counted']} | {result['gap_after_counted']} |\n"
    return (
        "### Blind judging\n\n"
        f"Shown to judges as X = {result['mapping']['X']}, Y = {result['mapping']['Y']} "
        f"(seed {result['mapping']['seed']}).\n\n"
        "| Judge | Before | After |\n| --- | --- | --- |\n"
        f"{rows}\n"
        f"| Counted (lowest judge) | {result['before_counted']} | {result['after_counted']} |\n"
        f"{gap_rows}\n"
        f"Decision: **{result['decision']}**. Advisory; a judge never gates a merge alone."
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    prepare_parser = commands.add_parser("prepare")
    prepare_parser.add_argument("--before", required=True)
    prepare_parser.add_argument("--after", required=True)
    prepare_parser.add_argument("--judge-dir", required=True)
    prepare_parser.add_argument("--mapping", required=True)
    prepare_parser.add_argument("--seed", type=int)
    prepare_parser.set_defaults(run=prepare)

    decide_parser = commands.add_parser("decide")
    decide_parser.add_argument("--mapping", required=True)
    decide_parser.add_argument("--visual", help="visual judge scores, e.g. X=6,Y=8")
    decide_parser.add_argument("--feel", help="feel judge scores, e.g. X=6,Y=9")
    decide_parser.add_argument("--motion", help="motion judge scores, e.g. X=5,Y=7")
    decide_parser.add_argument("--visual-gap", help="visual judge target-gap scores, e.g. X=4,Y=5")
    decide_parser.add_argument("--feel-gap", help="feel judge target-gap scores, e.g. X=4,Y=5")
    decide_parser.add_argument("--markdown", action="store_true")
    decide_parser.set_defaults(run=decide)

    arguments = parser.parse_args()
    arguments.run(arguments)


if __name__ == "__main__":
    sys.exit(main())
