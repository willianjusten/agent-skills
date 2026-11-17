#!/usr/bin/env python3
"""Blind before/after pairing and decision for polish-round judging.

prepare: copies the two captures into a judge directory as x.png and y.png in a
random order and records the mapping in a separate file. It never prints the mapping.

decide: reads the mapping and each judge's scores for X and Y, maps them back to
before and after, counts the lower of the two judges per capture, and keeps the
change only if it wins or ties.
"""

import argparse
import json
import random
import shutil
import sys
from pathlib import Path

LENSES = ("visual", "feel")
MIN_SCORE, MAX_SCORE = 1, 10


def prepare(arguments):
    rng = random.Random(arguments.seed) if arguments.seed is not None else random.SystemRandom()
    sides = ["before", "after"]
    rng.shuffle(sides)
    sources = {"before": Path(arguments.before), "after": Path(arguments.after)}
    judge_dir = Path(arguments.judge_dir)
    judge_dir.mkdir(parents=True, exist_ok=True)
    for label, side in zip(("x", "y"), sides):
        shutil.copyfile(sources[side], judge_dir / f"{label}.png")
    mapping_path = Path(arguments.mapping)
    mapping_path.parent.mkdir(parents=True, exist_ok=True)
    mapping = {"X": sides[0], "Y": sides[1], "seed": arguments.seed}
    mapping_path.write_text(json.dumps(mapping, indent=2) + "\n")
    print(f"Prepared {judge_dir}/x.png and {judge_dir}/y.png. Mapping saved for the packet only.")


def parse_scores(text):
    scores = {}
    for pair in text.split(","):
        label, _, value = pair.partition("=")
        label = label.strip().upper()
        if label not in ("X", "Y"):
            raise SystemExit(f"Unknown label '{label}' in '{text}'; use X=n,Y=n")
        try:
            score = float(value)
        except ValueError:
            raise SystemExit(f"Score '{value}' is not a number")
        if not MIN_SCORE <= score <= MAX_SCORE:
            raise SystemExit(f"Score {score:g} is outside {MIN_SCORE}-{MAX_SCORE}")
        scores[label] = score
    if set(scores) != {"X", "Y"}:
        raise SystemExit(f"Need both X and Y scores, got '{text}'")
    return scores


def number(value):
    return int(value) if float(value).is_integer() else value


def decide(arguments):
    mapping = json.loads(Path(arguments.mapping).read_text())
    judge_scores = {"visual": parse_scores(arguments.visual), "feel": parse_scores(arguments.feel)}
    by_side = {lens: {mapping[label]: scores[label] for label in ("X", "Y")} for lens, scores in judge_scores.items()}
    counted = {side: min(by_side[lens][side] for lens in LENSES) for side in ("before", "after")}
    result = {
        "mapping": {"X": mapping["X"], "Y": mapping["Y"], "seed": mapping.get("seed")},
        "scores": {lens: {side: number(by_side[lens][side]) for side in ("before", "after")} for lens in LENSES},
        "before_counted": number(counted["before"]),
        "after_counted": number(counted["after"]),
        "decision": "keep" if counted["after"] >= counted["before"] else "reject",
    }
    if arguments.markdown:
        print(markdown(result))
    else:
        print(json.dumps(result, indent=2))


def markdown(result):
    rows = "\n".join(
        f"| {lens.capitalize()} judge | {result['scores'][lens]['before']} | {result['scores'][lens]['after']} |"
        for lens in LENSES
    )
    return (
        "### Blind judging\n\n"
        f"Shown to judges as X = {result['mapping']['X']}, Y = {result['mapping']['Y']} "
        f"(seed {result['mapping']['seed']}).\n\n"
        "| Judge | Before | After |\n| --- | --- | --- |\n"
        f"{rows}\n"
        f"| Counted (lower of the two) | {result['before_counted']} | {result['after_counted']} |\n\n"
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
    decide_parser.add_argument("--visual", required=True, help="visual judge scores, e.g. X=6,Y=8")
    decide_parser.add_argument("--feel", required=True, help="feel judge scores, e.g. X=6,Y=9")
    decide_parser.add_argument("--markdown", action="store_true")
    decide_parser.set_defaults(run=decide)

    arguments = parser.parse_args()
    arguments.run(arguments)


if __name__ == "__main__":
    sys.exit(main())
