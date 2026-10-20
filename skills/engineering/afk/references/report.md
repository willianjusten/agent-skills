# report.md template

Every ticket file under `issues/` goes in exactly one of Done, Blocked and Needs you. Write "None." under an empty section.

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

## Learnings

- 02: <learning, verbatim from learnings.sh>

## Proposed promotions

- 02: <learning> -> <target>: <the exact rule, test, hook or line to add>
- stale: `docs/GOTCHAS.md:<line>` names `<name>`, which no longer exists: delete or update the line
- long: `docs/GOTCHAS.md` has <count> lines, limit 30: promote or delete lines
```

- Blocked holds tickets that failed during this run. Needs you holds tickets a human must act on before an agent can start them, tickets the budget stop left untouched, and every review finding still open.
- Take a ticket's SHAs from its merge commit, not from the implementer's report: `git log --format=%h <merge>^1..<merge>^2`.

## Learnings and promotions

Run `bash scripts/learnings.sh <feature folder> <Done ticket numbers...>` for Learnings, and `bash scripts/gotchas.sh <main checkout>` for the stale and long lines. Neither section is a place to act: write nothing to `docs/GOTCHAS.md`, `CODING_STANDARDS.md` or `docs/patterns/`. The user approves each promotion and applies it, or asks for it.

Give each learning one target, the first of these that fits:

1. **A check**: a lint rule, test or hook, when a tool can detect the mistake. Name the file and the rule or test.
2. **`CODING_STANDARDS.md`**: a rule for writing code anywhere in the repo. Use the repo's file, or `~/.claude/CODING_STANDARDS.md` when the lesson holds in every repo.
3. **`docs/patterns/<name>.md`**: how to make a kind of change that recurs; name the entry to add or extend.
4. **`docs/GOTCHAS.md`**: a trap no check or rule can carry. Write the line as `` - `<name>` <trap>: <what to do instead>. `` with the function, file or command in backticks, so `gotchas.sh` can tell when it goes stale.

A learning already covered by an existing check, standard, pattern or gotcha gets `-> covered by <where>` and no new text.
