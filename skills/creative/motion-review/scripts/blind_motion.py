#!/usr/bin/env python3
"""Blind before/after shuffle and decision for motion judging.

prepare: copies two folders of motion sheets (the same file names in each) into a
judge directory as x/ and y/ in a random order, and records the mapping in a
separate file. It never prints the mapping.

decide: reads the mapping and the motion judge's scores for X and Y, maps them
back to before and after, and keeps the change only if after wins or ties.
"""

import argparse
import json
import random
import shutil
import sys
from pathlib import Path

BEFORE, AFTER = "before", "after"
SIDES = (BEFORE, AFTER)
LABELS = ("X", "Y")
MIN_SCORE, MAX_SCORE = 1, 10


def sheet_names(folder):
    if not folder.is_dir():
        raise SystemExit(f"{folder} is not a folder of motion sheets")
    return sorted(path.name for path in folder.iterdir())


def prepare(arguments):
    sources = {BEFORE: Path(arguments.before), AFTER: Path(arguments.after)}
    if sheet_names(sources[BEFORE]) != sheet_names(sources[AFTER]):
        raise SystemExit("The two folders must hold the same file names, or the names give the order away")
    rng = random.Random(arguments.seed) if arguments.seed is not None else random.SystemRandom()
    sides = list(SIDES)
    rng.shuffle(sides)
    judge_dir = Path(arguments.judge_dir)
    for label, side in zip(LABELS, sides):
        shutil.copytree(sources[side], judge_dir / label.lower(), dirs_exist_ok=True)
    mapping_path = Path(arguments.mapping)
    mapping_path.parent.mkdir(parents=True, exist_ok=True)
    mapping = {LABELS[0]: sides[0], LABELS[1]: sides[1], "seed": arguments.seed}
    mapping_path.write_text(json.dumps(mapping, indent=2) + "\n")
    print(f"Prepared x/ and y/ in {judge_dir}. Mapping saved for the packet only.")


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
        scores[label] = int(score) if score.is_integer() else score
    if set(scores) != set(LABELS):
        raise SystemExit(f"Need both X and Y scores, got '{text}'")
    return scores


def decide(arguments):
    mapping = json.loads(Path(arguments.mapping).read_text())
    scores = parse_scores(arguments.motion)
    by_side = {mapping[label]: scores[label] for label in LABELS}
    result = {
        "mapping": {label: mapping[label] for label in LABELS} | {"seed": mapping.get("seed")},
        BEFORE: by_side[BEFORE],
        AFTER: by_side[AFTER],
        "decision": "keep" if by_side[AFTER] >= by_side[BEFORE] else "reject",
    }
    print(markdown(result) if arguments.markdown else json.dumps(result, indent=2))


def markdown(result):
    return (
        "### Blind motion judging\n\n"
        f"Shown to the judge as X = {result['mapping']['X']}, Y = {result['mapping']['Y']} "
        f"(seed {result['mapping']['seed']}).\n\n"
        "| Judge | Before | After |\n| --- | --- | --- |\n"
        f"| Motion judge | {result[BEFORE]} | {result[AFTER]} |\n\n"
        f"Decision: **{result['decision']}**. Advisory; a judge never gates a merge alone."
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    prepare_parser = commands.add_parser("prepare")
    prepare_parser.add_argument("--before", required=True, help="folder of motion sheets")
    prepare_parser.add_argument("--after", required=True, help="folder with the same sheet names")
    prepare_parser.add_argument("--judge-dir", required=True)
    prepare_parser.add_argument("--mapping", required=True)
    prepare_parser.add_argument("--seed", type=int)
    prepare_parser.set_defaults(run=prepare)

    decide_parser = commands.add_parser("decide")
    decide_parser.add_argument("--mapping", required=True)
    decide_parser.add_argument("--motion", required=True, help="motion judge scores, e.g. X=5,Y=7")
    decide_parser.add_argument("--markdown", action="store_true")
    decide_parser.set_defaults(run=decide)

    arguments = parser.parse_args()
    arguments.run(arguments)


if __name__ == "__main__":
    sys.exit(main())
