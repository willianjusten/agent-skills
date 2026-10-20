## Precedence

When rules conflict: safety rules > AFK mode > skill instructions > style.

## Safety (always)

- Never push to or merge into the default branch, force-push, delete remote branches, or merge PRs.
- Other pushes follow the project's `.claude/afk.json` (missing file = `manual`: push only when my latest prompt asks for it).
- Never read or print `.env*` contents or secrets.

## Interactive mode (default)

- On the default branch, propose a commit plan and wait for approval.
- Questions are questions: answer, don't edit.

## AFK mode

Applies when working a ticket whose Status is `ready-for-agent` or `in-progress`, on a non-default branch or worktree.

- Create the ticket branch or worktree first if you are on the default branch.
- Commit atomically without asking. Do not push; I push after reading the report. Exception: with `"push": "branch"`, push the ticket and integration branches and end with a draft PR.
- Seams in the spec's Testing Decisions are pre-agreed; do not ask to confirm them.
- Do not ask questions. If blocked after two attempts, follow the tracker's escalate operation and move on.
- Done means `verify` passes. For tickets with `Tests: e2e` that touch UI, also attach browser evidence: page loads, no console errors, the interaction works.

## General

- Always use descriptive variable names
- NEVER use emojis in responses, commit messages, or pull request descriptions
- Keep responses short and direct — avoid excessive formatting and verbose explanations
- Only add comments for magic numbers, complex business logic, or non-self-explanatory functions
- Prefer atomic commits — split changes by logical step (refactor, new helper, wiring, changeset), not by feature completion
- Never add Co-Authored-By or any Claude attribution to commit messages or pull request descriptions
- Questions are questions: when I ask a question or request analysis, answer it. Do not edit, revert or implement until I explicitly say to proceed

## Context budget

- Search before reading: grep/glob for the symbol, then read only the relevant range
- Read files over ~20KB with offset/limit; never read the same large file twice in a session
- Never `cat` whole directories of references; open only the file the current step needs
- For diffs, run `git diff --stat` first, then diff specific files
- Truncate noisy command output (`| tail -50`, `| head`, `--quiet`) instead of dumping it
- Delegate broad exploration to a subagent and keep only its conclusion

## Environment

- Shell is always zsh
- Docker is OrbStack. When a tool cannot find Docker (testcontainers, Firebase emulator tests), check `orb status` and set `DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock`; do not ask me to start Docker
- Check for project-level CLAUDE.md for project-specific conventions (package manager, framework, linter, etc.)

## Agent skills

Global defaults for Matt Pocock's skills in every repo; run `/setup-matt-pocock-skills` only to override them per project.

- **Issue tracker**: local markdown under `.scratch/<feature>/` in the repo being worked on. See `~/.claude/matt-skills/issue-tracker.md`.
- **Triage labels**: the five canonical roles, unchanged. See `~/.claude/matt-skills/triage-labels.md`.
- **Domain docs**: single-context, `GLOSSARY.md` and `docs/adr/` at the repo root. See `~/.claude/matt-skills/domain.md`.
