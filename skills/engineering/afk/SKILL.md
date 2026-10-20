---
name: afk
description: Run a spec's whole ticket graph unattended on an integration branch, inside the usage budget, and end with a report.
disable-model-invocation: true
metadata:
  scope: personal
  role: orchestrator
---

# afk

`/afk <feature folder>` builds every ticket an agent can take, with nobody watching, and leaves a `report.md` that says what is done, what is blocked and what needs a human. It is `implement-spec`'s flow with three guards: a ticket filter, a concurrency limit and a budget check.

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
- [ ] 2 Integration branch ready, notes explored
- [ ] 3 Frontier loop run until empty or stopped
- [ ] 4 Review and up to two fix rounds
- [ ] 5 report.md written
- [ ] 6 Pushed and draft PR opened, or left local
```

**Step 1. Read.** Read `<feature folder>/spec.md` and every `issues/*.md`. Read the repo's `.claude/afk.json`; a missing file means `"push": "manual"`. Confirm `git check-ignore -q <feature folder>` succeeds; if it fails, write only the report with that under Needs you, and stop. Run `bash scripts/budget.sh` and note the reading as the starting budget. Done when you know the push policy and the starting budget.

**Step 2. Branch and explore.** If the main checkout is on the default branch, create and check out `afk/<feature>` from it; otherwise the current branch is the integration branch. The checkout must be clean. Run one `explorer` subagent with a notes directory outside the repo. Done when the integration branch is checked out and the notes index exists.

**Step 3. Frontier loop.** Keep a list of running tickets: started, not yet merged or escalated.

1. Run `bash scripts/budget.sh`. On `go`, continue to 2. On `hold`, start nothing: skip to 3, or with nothing running go to Step 5. On `stop`, start nothing, let the running tickets finish through 3, then go to Step 5.
2. Run `bash scripts/frontier.sh <feature folder> <running...>`. Start an `implementer` subagent in the background for each number it prints, in its own worktree and branch (references/subagents.md). Add each to the running list. If it prints nothing and nothing is running, the loop is done.
3. Wait for the next implementer to report, then run a `merger` subagent for its branch. On a merge, remove the ticket from the running list. On a conflict or a failed `verify`, escalate the ticket with the merger's report as the blocker, then remove it.
4. Go back to 1.

Done when the loop ends at 2, or at a `hold` or `stop` with nothing running.

**Step 4. Review.** Run one `reviewer` subagent over the integration branch against its merge-base with the default branch. For `blocking` findings, run one fix round (references/subagents.md), merge it, and review again; stop after two fix rounds. Skip this step after a `stop`. Done when no `blocking` finding is left or two rounds are spent.

**Step 5. Report.** Write `<feature folder>/report.md` from references/report.md. Check it: every ticket file appears exactly once, and every Done row's SHAs exist on the integration branch (`git branch --contains <sha>`). If the check fails, fix the report and return to the start of Step 5.

**Step 6. Push or not.** Under `"push": "branch"`, push the integration branch and each merged ticket branch, then open one draft PR: `gh pr create --draft --base <default branch> --head <integration> --body-file <feature folder>/report.md`. If `gh pr list --head <integration>` already shows a PR, update its body (`gh pr edit --body-file`) instead of opening a second. Under `manual`, push nothing. Remove the worktrees of merged tickets (`git worktree remove`), keep the rest. End your reply with the report's path and the PR link, if any.

## Resources

- [references/subagents.md](references/subagents.md) - what each subagent is given, the worktree layout and the fix-round ticket. Open in Steps 2 to 4.
- [references/report.md](references/report.md) - the `report.md` template. Open in Step 5.
- `scripts/frontier.sh <feature folder> [running...]` - ticket numbers that may start now: `ready-for-agent`, blockers `done` and not running, at most 2 running, no shared Areas.
- `scripts/budget.sh [cache]` (or `AFK_USAGE_CACHE`) - `go`, `hold` (80% of the 5-hour window), `stop` (90%), or `go unknown` when the statusline cache is missing or stale.
