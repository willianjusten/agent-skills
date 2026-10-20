# Discover an existing repo

Read before writing anything. The goal is the commands that actually work today, not the ones a template expects.

## Where to look

| Fact | Sources, in order of trust |
| ---- | -------------------------- |
| Package manager | Lockfile (`bun.lock`/`bun.lockb`, `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`), then `packageManager` in `package.json` |
| typecheck, lint, test, build | `package.json` scripts; then the CI config (`.github/workflows/`, `.gitlab-ci.yml`, `.circleci/`); then README or CONTRIBUTING. A CI step that runs `tsc --noEmit` directly is the typecheck even without a script |
| Non-standard commands | Scripts beyond the four above that an agent would need: database reset, seeding, codegen, e2e, local services (`docker compose`) |
| Port and database env vars | `.env.example`, `.env.sample`, the framework config, `docker-compose.yml`. Read names only, never the values of `.env` files |
| Existing agent files | `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `docs/`, `.husky/`, `.claude/afk.json` |

Run each discovered check command once. A command that fails today is a finding, not something to fix.

## Gaps

- A missing script among typecheck, lint, test, build: `verify` chains the ones that exist; list the missing one with the command that would fill it (for example `tsc --noEmit` when `tsconfig.json` exists). Add it only if the user asks.
- An existing `AGENTS.md` or `CLAUDE.md`: keep it. Suggest cuts (paths, rules a check could enforce, anything over 15 lines) in the report, but do not apply them.
- A `/init`-generated `CLAUDE.md`: treat it like any existing file; propose moving its useful lines into `AGENTS.md`.

## Findings table

Give this in the report, one row per fact:

| Fact | Found | Source | Command ran |
| ---- | ----- | ------ | ----------- |
| Package manager | pnpm | pnpm-lock.yaml | n/a |
| test | `pnpm test` (vitest) | package.json | passed |
| lint | missing | - | - |
