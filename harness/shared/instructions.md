## General

- Always use descriptive variable names
- NEVER use emojis in responses, commit messages, or pull request descriptions
- Keep responses short and direct — avoid excessive formatting and verbose explanations
- Only add comments for magic numbers, complex business logic, or non-self-explanatory functions
- When skills are available, always follow their guidelines and workflows instead of default behavior
- Never push to remote without explicit confirmation
- Never commit without explicit approval — propose a commit plan and wait for confirmation before running git commit
- Prefer atomic commits — split changes by logical step (refactor, new helper, wiring, changeset), not by feature completion
- Never add Co-Authored-By or any Claude attribution to commit messages or pull request descriptions
- When I ask a question during a conversation, treat it as a question -- just answer it
- Do NOT interpret questions as implicit requests to revert, undo code, modify, or make changes
- When the user asks a question or requests analysis, do NOT start editing files or implementing changes. Ask/plan first, act only when explicitly told to proceed

## Code design

- When a change edits the same control flow in two or more places, extract it into one function in that change instead of deferring it. Keep each caller's own answer (scope, flags) as an explicit argument; no defaults, shared constants or wrappers that hide it
- Trust inputs an earlier step already validated or narrowed. The receiving function uses that result and documents the precondition; it does not repeat the check
- Do not add a wrapper that only forwards an argument to a function that already exists
- Before moving or extracting a function, check what tests import and mock, and keep it reachable through the module the tests already mock
- Add a type, branch or error only for a state a caller can reach. Reuse the types callers already share
- Give each type or helper one import path. Import it from the module that owns it; do not re-export it from a second module
- In Spoke repos, place new or moved code per spoke-knowledge's code-organization doc: nearest shared boundary on real reuse, explicit named export from the module's public surface

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

Global defaults for Matt Pocock's skills. They apply to every repo, so `/setup-matt-pocock-skills` does not need to be run per-repo; run it only to override these for a specific project.

### Issue tracker

Local markdown under `.scratch/<feature>/` in the repo being worked on. See `~/.claude/matt-skills/issue-tracker.md`.

### Triage labels

The five canonical roles, unchanged. See `~/.claude/matt-skills/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `~/.claude/matt-skills/domain.md`.
