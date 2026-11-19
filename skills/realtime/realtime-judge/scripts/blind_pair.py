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

discriminate-prepare: builds 12 trials from matching reference and render crops,
each trial a judge subfolder holding x.png and y.png in a random order, and
records which side is the real reference in a key file kept outside the judge
directory. discriminate-score: reads the judge's picks of the real image per
trial and counts the correct ones; the look passes at 7 or fewer correct.
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
TRIAL_COUNT = 12
MAX_CORRECT_TO_PASS = 7


def require_fresh_judge_dir(judge_dir, leaked_thing):
    if judge_dir.exists() and any(judge_dir.iterdir()):
        raise SystemExit(f"{judge_dir} is not empty; use a fresh judge directory so no earlier {leaked_thing} reaches the judge")


def parse_pairs(text, read_pair, expected_keys, wrong_count_message):
    """Reads `key=value,key=value`: read_pair(key, value) validates one pair and returns (key, parsed value)."""
    parsed = {}
    for pair in text.split(","):
        raw_key, _, raw_value = pair.partition("=")
        key, value = read_pair(raw_key.strip(), raw_value)
        parsed[key] = value
    if set(parsed) != set(expected_keys):
        raise SystemExit(wrong_count_message(parsed))
    return parsed


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
    require_fresh_judge_dir(judge_dir, "sheet")
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


def trial_name(number):
    return f"{number:02d}"


def discriminate_prepare(arguments):
    rng = random.Random(arguments.seed) if arguments.seed is not None else random.SystemRandom()
    reference_dir, render_dir = Path(arguments.reference_dir), Path(arguments.render_dir)
    references = sorted(p.name for p in reference_dir.glob("*.png"))
    renders = sorted(p.name for p in render_dir.glob("*.png"))
    if references != renders:
        raise SystemExit("The reference and render folders must hold the same PNG file names, one pair per trial")
    if len(references) != TRIAL_COUNT:
        raise SystemExit(f"Need exactly {TRIAL_COUNT} crop pairs, found {len(references)}")
    judge_dir = Path(arguments.judge_dir)
    require_fresh_judge_dir(judge_dir, "crop")
    trial_order = list(range(1, TRIAL_COUNT + 1))
    rng.shuffle(trial_order)
    real_side = {}
    for number, crop_name in zip(trial_order, references):
        reference_first = rng.random() < 0.5
        first_source, second_source = (reference_dir, render_dir) if reference_first else (render_dir, reference_dir)
        trial_dir = judge_dir / f"trial-{trial_name(number)}"
        trial_dir.mkdir(parents=True)
        shutil.copyfile(first_source / crop_name, trial_dir / "x.png")
        shutil.copyfile(second_source / crop_name, trial_dir / "y.png")
        real_side[trial_name(number)] = FIRST_LABEL if reference_first else SECOND_LABEL
    key_path = Path(arguments.key)
    key_path.parent.mkdir(parents=True, exist_ok=True)
    key_path.write_text(json.dumps({"real": real_side, "seed": arguments.seed}, indent=2) + "\n")
    print(f"Prepared {TRIAL_COUNT} trials in {judge_dir}. Answer key saved for the packet only.")


def parse_answers(text, trial_names):
    def read_answer(trial, label):
        label = label.strip().upper()
        if trial not in trial_names:
            raise SystemExit(f"Unknown trial '{trial}' in '{text}'; use 01=X,02=Y,...")
        if label not in LABELS:
            raise SystemExit(f"Answer '{label}' for trial {trial} must be X or Y")
        return trial, label

    return parse_pairs(
        text, read_answer, trial_names, lambda answers: f"Need one answer for each of the {len(trial_names)} trials, got {len(answers)}"
    )


def discriminate_score(arguments):
    key = json.loads(Path(arguments.key).read_text())
    answers = parse_answers(arguments.answers, set(key["real"]))
    per_trial = {trial: answers[trial] == key["real"][trial] for trial in sorted(key["real"])}
    correct = sum(per_trial.values())
    result = {
        "trials": len(per_trial),
        "correct": correct,
        "result": "pass" if correct <= MAX_CORRECT_TO_PASS else "fail",
        "seed": key.get("seed"),
        "per_trial": {trial: {"real": key["real"][trial], "picked": answers[trial], "correct": per_trial[trial]} for trial in per_trial},
    }
    if arguments.markdown:
        print(discriminate_markdown(result))
    else:
        print(json.dumps(result, indent=2))


def discriminate_markdown(result):
    rows = "\n".join(
        f"| {trial} | {entry['real']} | {entry['picked']} | {'yes' if entry['correct'] else 'no'} |"
        for trial, entry in result["per_trial"].items()
    )
    return (
        "### Reference discrimination\n\n"
        f"Judge picked the real reference in {result['correct']} of {result['trials']} trials "
        f"(seed {result['seed']}). The look passes at {MAX_CORRECT_TO_PASS} or fewer correct.\n\n"
        "| Trial | Real was | Judge picked | Correct |\n| --- | --- | --- | --- |\n"
        f"{rows}\n\n"
        f"Result: **{result['result']}**. Advisory; a judge never gates a merge alone."
    )


def parse_scores(text):
    def read_score(label, value):
        label = label.upper()
        if label not in LABELS:
            raise SystemExit(f"Unknown label '{label}' in '{text}'; use X=n,Y=n")
        try:
            score = float(value)
        except ValueError:
            raise SystemExit(f"Score '{value}' is not a number")
        if not MIN_SCORE <= score <= MAX_SCORE:
            raise SystemExit(f"Score {score:g} is outside {MIN_SCORE}-{MAX_SCORE}")
        return label, score

    return parse_pairs(text, read_score, LABELS, lambda scores: f"Need both X and Y scores, got '{text}'")


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
        ) + f"| Counted target gap (lowest judge) | {result['gap_before_counted']} | {result['gap_after_counted']} |\n"
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

    discriminate_prepare_parser = commands.add_parser("discriminate-prepare")
    discriminate_prepare_parser.add_argument("--reference-dir", required=True)
    discriminate_prepare_parser.add_argument("--render-dir", required=True)
    discriminate_prepare_parser.add_argument("--judge-dir", required=True)
    discriminate_prepare_parser.add_argument("--key", required=True)
    discriminate_prepare_parser.add_argument("--seed", type=int)
    discriminate_prepare_parser.set_defaults(run=discriminate_prepare)

    discriminate_score_parser = commands.add_parser("discriminate-score")
    discriminate_score_parser.add_argument("--key", required=True)
    discriminate_score_parser.add_argument("--answers", required=True, help="the side picked as real per trial, e.g. 01=X,02=Y,...")
    discriminate_score_parser.add_argument("--markdown", action="store_true")
    discriminate_score_parser.set_defaults(run=discriminate_score)

    arguments = parser.parse_args()
    arguments.run(arguments)


if __name__ == "__main__":
    sys.exit(main())
