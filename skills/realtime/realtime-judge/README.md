# Realtime Judge

Blind before/after judging for polish rounds, with two lenses and the lower score counting.

## What It Does

```mermaid
flowchart LR
  A[Before and after captures] --> B[prepare: shuffle as X and Y]
  B --> C[visual-judge and feel-judge]
  C --> D[decide: lower score counts]
  D --> E{After wins or ties?}
  E -- yes --> F[Keep]
  E -- no --> G[Reject]
  D --> H[Scores and mapping into the packet]
```

## Usage

```text
Judge this polish round blind
Did the new lighting actually improve the arena? Score before and after
Put the judge scores in the review packet
```

## Output

- A judge directory per moment with `x.png` and `y.png` only.
- A mapping file per moment (kept out of the judges' reach) and a markdown block for the packet with both scores, the counted score and the decision.

## Requirements

- Python 3, and before and after PNG captures taken at the same moments.
- The `visual-judge` and `feel-judge` agents.

## FAQ

- Does a reject block a merge? No, judges advise; `verify` gates are the hard checks.
- Why the lower score? One judge spotting a flaw should be enough to doubt the change.
