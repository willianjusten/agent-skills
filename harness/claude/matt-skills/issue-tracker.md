# Issue tracker: Local Markdown

Issues and specs live as markdown files in `.scratch/`, relative to the root of whichever repo is in scope. This is the global default for every repo; no per-repo setup is needed.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.

## Status lifecycle

One plain line near the top of every file: `Status: <value>`. Never bold; this overrides the bold `**Status:**` in `to-tickets`' local template.

- Spec files: `spec`. Orchestrators never pick these up.
- Tickets: `ready-for-agent` | `ready-for-human` -> `in-progress` -> `done`, or `needs-info` when blocked.

## Required ticket fields

Plain `Field: value` lines under the title, never bold:

- `Blocked by: NN, NN` or `None`
- `Areas:` module or domain names the ticket touches (no paths). Tickets with overlapping Areas never run in parallel. A schema or migration change is always its own ticket and blocks its dependents.
- `Tests: tdd | e2e | verify-only`
- `Reuses: <path:line>[, <path:line>...]` the existing code the ticket follows, or `Reuses: no-precedent`. Search the codebase for the nearest example before writing the ticket.
- `Verify:` optional; the command that proves it is done

## Implementation frontier

A ticket is ready to start when it is `ready-for-agent`, every `Blocked by` ticket is `done`, it is not already running, and its `Areas` do not overlap with a running ticket. At most two tickets run at once.

## Worktrees

`.scratch/` is gitignored and absent from worktrees. A subagent working in a worktree gets the ticket and spec paths as absolute paths in the main checkout and updates ticket status there.

## Operations

- Claim: set `Status: in-progress` and save before any work.
- Done: set `Status: done`, append the commit SHAs under `## Done`. Record a small departure from the ticket there as `Deviation: <one line>`; a contradiction with the spec is an Escalate.
- Escalate: append `## Blocker` (what was tried, what is needed), set `Status: needs-info`, continue the frontier.
- Log: append one line per attempt to `.scratch/<feature>/progress.md`: ticket, result, commit or blocker.

## Closing work

With `"push": "branch"` in `.claude/afk.json`, work closes through a PR: `implement-spec` opens it as a draft and marks it ready for review at the end. An agent never merges it. Otherwise work closes by ticket status (Done above) and nothing is pushed.
