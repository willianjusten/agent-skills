---
name: afk
description: Run a spec's whole ticket graph unattended on an integration branch, inside the usage budget, and end with a report.
disable-model-invocation: true
metadata:
  scope: personal
  role: orchestrator
---

# afk

`/afk <feature folder>` builds every ticket an agent can take, with nobody watching, and leaves a `report.md` that says what is done, what is blocked and what needs a human. It runs the `implement-spec` skill with three guards on top: a ticket filter, a concurrency limit and a budget check.

## Rules for every run

1. **Never ask.** Nobody is watching. A ticket that cannot proceed is escalated (`## Blocker`, `Status: needs-info`) and the run moves on.
2. **Scripts decide scheduling.** Only `scripts/frontier.sh` picks what starts, and only `scripts/budget.sh` decides whether anything may start. Judgment drifts over a long run; the scripts do not.
3. **The main checkout owns ticket files.** `.scratch/` is gitignored, so worktrees do not see it. Every subagent gets the absolute paths of the spec and ticket in the main checkout.
4. **Push only under `"push": "branch"`.** Otherwise every branch and the report stay local.

Script paths are relative to this skill's folder.

## Workflow

```text
afk progress:
- [ ] 1 Spec, tickets and push policy read
- [ ] 2 Integration branch ready
- [ ] 3 implement-spec run with the overrides until the frontier is empty or the budget stops it
- [ ] 4 Security review run on the integration branch
- [ ] 5 report.md written
- [ ] 6 Pushed and draft PR opened, or left local
```

**Step 1. Read.** Read `<feature folder>/spec.md` and every `issues/*.md`. Read the repo's `.claude/afk.json`; a missing file means `"push": "manual"`. Confirm `git check-ignore -q <feature folder>` succeeds; if it fails, write only the report with that under Needs you, and stop. Run `bash scripts/budget.sh` and note the reading as the starting budget. Done when you know the push policy and the starting budget.

**Step 2. Branch.** If the main checkout is on the default branch, create and check out `afk/<feature>` from it; otherwise the current branch is the integration branch. The checkout must be clean. Done when the integration branch is checked out.

**Step 3. Run `implement-spec`.** It sets `disable-model-invocation`, so the Skill tool refuses it: read its `SKILL.md` instead (in Claude Code, `~/.claude/skills/implement-spec/SKILL.md`). If it is missing, put that under Needs you and go to Step 5. Follow its steps for the feature folder and the integration branch from Step 2, with the overrides below; where it says otherwise, the override wins. Done when the frontier is empty with nothing running, or at a `hold` or `stop` with nothing running.

| `implement-spec` step | Override |
| --- | --- |
| Exploration (optional) | Always run one `explorer` subagent (references/subagents.md). |
| Create the integration branch, draft PR after the first merge | The branch already exists. Open no PR here; Step 6 does that. |
| Pick the frontier, start implementers | Keep a running list: started, not yet merged or escalated. Before each start, run `bash scripts/budget.sh`: on `go`, run `bash scripts/frontier.sh <feature folder> <running...>` and start an `implementer` subagent for each number it prints, nothing else; on `hold`, start nothing; on `stop`, start nothing and end the run once the running tickets are merged. Worktrees and branches follow references/subagents.md. |
| Merge each finished ticket | Use a `merger` subagent. On a conflict or a failed `verify`, escalate the ticket with the merger's report as the blocker and drop it from the running list. |
| Code review with `matt-code-review`, one fix implementer | Use one `reviewer` subagent instead. For `blocking` findings, run a fix round (references/subagents.md), merge it, and review again; stop after two rounds. Skip review after a `stop`. Keep `advisory` findings for the report. |
| Mark the PR ready, resolve tickets | Skip: implementers already marked their tickets done, and any PR stays a draft. |
| Clean up worktrees | Remove only the worktrees of merged tickets; keep the rest for inspection. |

**Step 4. Security review.** Run it even after a `stop`, in the main checkout on the integration branch. It diffs against `origin/HEAD`: if `git rev-parse -q --verify origin/HEAD` fails and an `origin` remote exists, run `git remote set-head origin --auto`; with no `origin`, write "Skipped: no origin remote" under Security and go to Step 5. Call the Skill tool with `security-review` (Claude Code's built-in `/security-review`). Each finding is a `# Vuln N: <title>: <file:line>` heading with a `Severity:` line. High findings are `blocking`: run no fix round, since the code is already in the branch history and only a human can decide to rewrite it. Done when every finding is noted for the Security section.

**Step 5. Report.** Write `<feature folder>/report.md` from references/report.md, including Security from Step 4 and Learnings and Proposed promotions from `scripts/learnings.sh` and `scripts/gotchas.sh`. Apply no promotion. Check it: every ticket file appears exactly once in Done, Blocked and Needs you, and every Done row's SHAs exist on the integration branch (`git branch --contains <sha>`). If the check fails, fix the report and return to the start of Step 5.

**Step 6. Push or not.** With any `blocking` security finding, push nothing and open no PR, whatever the policy; say so under Needs you. Otherwise, under `"push": "branch"`, push the integration branch and each merged ticket branch, then open one draft PR: `gh pr create --draft --base <default branch> --head <integration> --body-file <feature folder>/report.md`. If `gh pr list --head <integration>` already shows a PR, update its body (`gh pr edit --body-file`) instead of opening a second. Under `manual`, push nothing. End your reply with the report's path and the PR link, if any.

## Resources

- [references/subagents.md](references/subagents.md) - what each subagent is given, the worktree layout and the fix-round ticket. Open in Step 3.
- [references/report.md](references/report.md) - the `report.md` template and the promotion order. Open in Step 5.
- `scripts/frontier.sh <feature folder> [running...]` - ticket numbers that may start now: `ready-for-agent`, blockers `done` and not running, at most 2 running, no shared Areas.
- `scripts/learnings.sh <feature folder> [ticket...]` - `NN: <learning>` for each `Learning:` line under a ticket's `## Done`.
- `scripts/gotchas.sh [repo root]` - `docs/GOTCHAS.md` lines whose backticked names no longer exist, and the file when it passes 30 lines.
- `scripts/budget.sh [cache]` (or `AFK_USAGE_CACHE`) - `go`, `hold` (80% of the 5-hour window), `stop` (90%), or `go unknown` when the statusline cache is missing or stale.
