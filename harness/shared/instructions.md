## Precedence

When rules conflict: safety rules > skill instructions > style. Matt Pocock's skills win over my own rules; mine only fill gaps they leave.

## Safety (always)

- Never merge into the default branch or merge PRs unless I explicitly ask in that conversation. Never force-push or delete remote branches.
- Never read or print `.env*` contents or secrets.

## General

- Questions are questions: when I ask a question or request analysis, answer it. Do not edit, revert or implement until I explicitly say to proceed. A skill I invoked counts as that go-ahead for its own steps.
- Always use descriptive variable names. Only add comments for magic numbers, complex business logic, or non-self-explanatory functions.
- NEVER use emojis in responses, commit messages, or pull request descriptions. Keep responses short and direct.
- Prefer atomic commits, split by logical step (refactor, new helper, wiring, changeset). Never add Co-Authored-By or any Claude attribution to commit messages or pull request descriptions.
- Search before reading; read files over ~20KB with offset/limit; run `git diff --stat` before diffing files; truncate noisy output. Delegate broad exploration to a subagent and keep only its conclusion.

## Environment

- Check for a project-level CLAUDE.md for project-specific conventions. Shell is always zsh.
- Cross-repo coding standards live in `~/.claude/CODING_STANDARDS.md`; a repo's own standards win where they conflict.
- Docker is OrbStack. When a tool cannot find Docker, check `orb status` and set `DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock`; do not ask me to start Docker.
- Before using a library API whose shape you are unsure of for the installed version, look it up with the context7 docs tool and quote the version.
- I have two Macs (Mac Studio and MacBook), each with Chrome connected to Claude in Chrome, and they may run different dev servers at once. Before the first browser action in a session, call `list_connected_browsers` and `select_browser` the one whose name matches `scutil --get ComputerName`, so `localhost` is this machine's; I pre-authorize that choice. If none matches, ask me.

## Agent skills

Global defaults for Matt Pocock's skills in every repo; run `/setup-matt-pocock-skills` only to override them per project.

- **Issue tracker**: local markdown under `.scratch/<feature>/` in the repo being worked on. See `~/.claude/skills/setup-matt-pocock-skills/issue-tracker-local.md`. Work closes by setting a ticket's Status to `done`, not through PRs.
- **Triage labels**: the five canonical roles, unchanged. See `~/.claude/skills/setup-matt-pocock-skills/triage-labels.md`.
- **Domain docs**: single-context, `GLOSSARY.md` and `docs/adr/` at the repo root. See `~/.claude/skills/setup-matt-pocock-skills/domain.md`.
- **Merger subagents**: when `implement-spec` spawns a merger subagent, run it on Haiku.
