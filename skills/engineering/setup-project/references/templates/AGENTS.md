# <project name>

<One sentence: what this project is and who uses it.>

- Package manager: <npm | pnpm | yarn | bun>. Do not use another one.
- `<pm> run verify` proves a change is done: typecheck, lint, test, build.
- New worktree: `scripts/worktree-setup.sh` before anything else.
<- One line per non-standard command, for example `<pm> run db:reset` recreates the dev database.>

Architecture and module boundaries: `docs/architecture.md`. Patterns to copy: `docs/patterns/`. Decisions: `docs/adr/`.
Known traps: docs/GOTCHAS.md
