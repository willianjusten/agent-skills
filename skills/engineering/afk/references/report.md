# report.md template

Every ticket file under `issues/` goes in exactly one section. Write "None." under an empty section.

```markdown
# <feature>: afk report

Integration branch: `<branch>`
Stopped by: frontier empty | budget hold at <percent>% | budget stop at <percent>%
Budget: 5-hour window <start>% -> <end>%, from `budget.sh` ("unknown" when it printed unknown)

## Done

| Ticket | SHAs |
| --- | --- |
| 01 <title> | abc1234, def5678 |

## Blocked

| Ticket | Blocker |
| --- | --- |
| 03 <title> | <one line from its ## Blocker, or the merge conflict files> |

## Needs you

- 04 <title>: ready-for-human
- 05 <title>: needs-info, <one line from its ## Blocker>
- 06 <title>: not started, budget hold | budget stop
- advisory: `path:line` - <finding>
- blocking, after two fix rounds: `path:line` - <finding>
```

- Blocked holds tickets that failed during this run. Needs you holds tickets a human must act on before an agent can start them, tickets the budget stop left untouched, and every review finding still open.
- Take a ticket's SHAs from its merge commit, not from the implementer's report: `git log --format=%h <merge>^1..<merge>^2`.
