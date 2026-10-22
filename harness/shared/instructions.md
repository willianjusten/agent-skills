## Precedence

When rules conflict: safety rules > skill instructions > AFK mode > style. Matt Pocock's skills win over my own rules; mine only fill gaps they leave.

## Safety (always)

- Never merge into the default branch, force-push, delete remote branches, or merge PRs.
- Push to the default branch only when my latest prompt directly asks for that push. Other pushes follow the project's `.claude/afk.json` (missing file = `manual`: push only when my latest prompt asks for it).
- Never read or print `.env*` contents or secrets.

## Interactive mode (default)

- On the default branch, propose a commit plan and wait for approval.
- Questions are questions: when I ask a question or request analysis, answer it. Do not edit, revert or implement until I explicitly say to proceed.

## AFK mode

Applies when working a ticket whose Status is `ready-for-agent` or `in-progress`, on a non-default branch or worktree.

- Create the ticket branch or worktree first if you are on the default branch.
- Commit atomically without asking, staging files by name. Do not push; I push after reading the report. Exception: with `"push": "branch"`, push the ticket and integration branches; the PR follows the tracker's closing work.
- Run at most two implementer subagents at once, never two whose tickets have overlapping `Areas`. This cap overrides a skill's "maximum concurrency".
- Never delete, skip or loosen a test the ticket did not ask to change.
- Do not ask questions; seams in the spec's Testing Decisions are pre-agreed. If blocked after two attempts, follow the tracker's escalate operation and move on.
- Done means the repo's own checks pass when you run them in your shell: typecheck, lint, test, build, whichever exist (the `verify` script when there is one). Use only commands the repo has (package scripts, `Makefile`, CI workflow, pre-commit config, `AGENTS.md`) and never install a tool.
- End the report with one line per check: `<command> - pass | fail | gap: <why>`. A missing or unrunnable check is a gap, never a pass.

## General and environment

- Always use descriptive variable names. Only add comments for magic numbers, complex business logic, or non-self-explanatory functions.
- NEVER use emojis in responses, commit messages, or pull request descriptions. Keep responses short and direct.
- Prefer atomic commits, split by logical step (refactor, new helper, wiring, changeset). Never add Co-Authored-By or any Claude attribution to commit messages or pull request descriptions.
- Search before reading; read files over ~20KB with offset/limit; run `git diff --stat` before diffing files; truncate noisy output. Delegate broad exploration to a subagent and keep only its conclusion.
- When running `matt-code-review`, include `~/.claude/CODING_STANDARDS.md` among the standards sources; a repo standard wins on conflict.
- When a skill starts subagents, pass `model` on the Agent call: implementer and exploration subagents `sonnet`, merger `haiku`; everything else inherits the session.
- Check for a project-level CLAUDE.md for project-specific conventions. Shell is always zsh. Docker is OrbStack. When a tool cannot find Docker, check `orb status` and set `DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock`; do not ask me to start Docker.
- Before using a library API whose shape you are unsure of for the installed version, look it up with the context7 docs tool and quote the version.

## Agent skills

Global defaults for Matt Pocock's skills in every repo; run `/setup-matt-pocock-skills` only to override them per project.

- **Issue tracker**: local markdown under `.scratch/<feature>/` in the repo being worked on. See `~/.claude/matt-skills/issue-tracker.md`.
- **Triage labels**: the five canonical roles, unchanged. See `~/.claude/matt-skills/triage-labels.md`.
- **Domain docs**: single-context, `GLOSSARY.md` and `docs/adr/` at the repo root. See `~/.claude/matt-skills/domain.md`.
