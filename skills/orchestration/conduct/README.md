# Conduct

Starts the conductor on an approved pitch and walks away; it stops only when your judgement is needed.

## What It Does

```mermaid
flowchart LR
  A[Pitch] --> B[Brief]
  B --> C[Art bible]
  C --> D[Scaffold and first playable]
  D --> E{{Stop 1: target frames}}
  E --> F[Component checklist]
  F --> G[Polish rounds]
  G --> H[Reference judge]
  H --> I[Delivery]
```

| Phase | Output |
| ----- | ------ |
| Brief, art bible | `GDD.md` or `TREATMENT.md`, `ART-BIBLE.md` (signed on your behalf, logged) |
| Target frames | stop 1: you approve a target |
| Checklist | `COMPONENTS.md`: target, folder and lens per component |
| Polish, judge, delivery | review packet, `DECISIONS.md`, `RUN.md` |

## Usage

```text
/conduct apps/games/tide-runner/PITCH.md
/conduct apps/games/tide-runner
/conduct apps/experiments/fog/PITCH.md rounds=3 hours=2, also stop before delivery
```

## Output

`RUN.md` in the app folder, append-only and committed. To answer a stop, append `- <UTC timestamp> | answer | <your answer>` and run `/conduct <app>` again. One conductor runs per app: it holds `RUN.md.lock` (owner and start time, uncommitted) and a second start is refused while the lock is held; a lock not refreshed for 2 hours counts as stale.

## Requirements

- The lab repo with `pnpm verify` and `pnpm asset target`.
- Subagents nest three levels (conductor, director, worker or judge); no extra launch or permission mode is needed.
- Stops are announced with a push notification; without the tool, the line is in `RUN.md`.

## FAQ

- Default stops? Target frames, polish plateau, split taste call, a gate failing twice, a spent budget.
- Default budget? 6 polish rounds and 6 hours of active run time per run, summed across stops and resumes, overridable in the request or the brief.
