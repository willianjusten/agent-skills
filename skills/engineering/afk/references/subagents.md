# Subagents

Brief every subagent with pointers, not copies: absolute paths to the spec, the ticket, the notes index and the commits that matter. Each agent's own definition carries its rules.

## explorer

Give it the spec, the `issues/` folder and a notes directory outside the repo: `<repo parent>/<repo>-afk/<feature>/notes`. Its index maps each ticket number to the notes it needs.

## implementer

Create the worktree before starting the subagent:

```bash
git worktree add <repo parent>/<repo>-afk/<feature>/<NN> -b afk/<feature>-<NN> <integration branch>
```

Give it:

- the ticket and spec paths in the main checkout (the worktree has no `.scratch/`);
- the integration branch, its worktree path and branch;
- the notes index.

Run it in the background. Its report names the branch, the commits and evidence for every acceptance criterion. If it reports a `## Blocker`, the ticket is escalated already: remove it from the running list and do not merge.

## merger

Give it the ticket branch, the integration branch and the main checkout path. It merges with `--no-ff`, runs `verify`, and stops on a conflict instead of resolving it.

## reviewer

Give it the fixed point (`git merge-base <default branch> <integration branch>`), the spec and the `issues/` folder. Collect its `blocking` and `advisory` lines.

## Fix round

The implementer's stop hook needs a ticket with acceptance criteria, so write one at `<feature folder>/review/fix-<round>.md` (outside `issues/`, so `frontier.sh` never schedules it):

```markdown
# Review fix <round>

Status: in-progress
Blocked by: None
Areas: review
Tests: verify-only

## Acceptance criteria

- [ ] <blocking finding, verbatim: path:line - what is wrong - the fix>
```

Run one implementer on it in worktree `<repo parent>/<repo>-afk/<feature>/fix-<round>`, branch `afk/<feature>-fix-<round>`, then the merger, then the reviewer again.
