---
name: setup-project
description: Set up a new or existing TypeScript and React repo for agent work - AGENTS.md, verify, quality checks and ratchet, worktree setup, architecture docs, CI, pre-commit and push policy.
disable-model-invocation: true
metadata:
  scope: personal
  role: orchestrator
---

# setup-project

`/setup-project` gives a repo what unattended agents need: one `verify` command that proves work is done, checks that keep quality from slipping, worktrees that do not share a database or port, short instructions, and a push policy. Mode **new** grills the stack and scaffolds an empty folder; mode **existing** fits an existing repo without changing what already works.

## Rules for every run

1. **Fill gaps, never overwrite.** If a target file exists, keep it and note it in the report. In an existing repo, a script or config that already works is the source of truth, even when it differs from a template. Edit shared files like `package.json` in place with the smallest change, so the diff shows only what was added.
2. **Commands come from the repo.** Every command written anywhere (AGENTS.md, `verify`, CI, `worktree-setup.sh`) must exist in `package.json` or the repo's docs, and must have run once in this session. Nothing assumes a framework, ORM, package manager or test runner beyond what the repo shows.
3. **Checks over prose.** AGENTS.md holds only what an agent cannot discover: pointers into `docs/` and `scripts/` are fine, source paths and rules a linter or test could enforce are not. Keep it under 15 lines, because every agent turn pays for it.
4. **Ask only these:** the stack (mode new) and the push policy. Everything else is discovered or defaulted.

Template paths are relative to this skill's folder.

## Workflow

```text
setup-project progress:
- [ ] 1 Mode picked and the repo's facts collected
- [ ] 2 Stack recorded and scaffolded (new only)
- [ ] 3 verify script runs green
- [ ] 4 AGENTS.md, CLAUDE.md, docs/ written
- [ ] 5 Strict tsconfig, lint rules and ratchet in verify
- [ ] 6 worktree-setup.sh written and run once
- [ ] 7 CI workflow and pre-commit in place
- [ ] 8 Push policy in .claude/afk.json; issue tracker switched if branch
- [ ] 9 .scratch/ ignored, report given
```

**Step 1. Pick the mode.** An empty folder, or one with no `package.json`, is **new**: `git init` it if needed. Anything else is **existing**: follow references/discover.md and keep its findings table for the report. Done when you know the package manager and the real typecheck, lint, test and build commands (or that one is missing).

**Step 2. Stack (new only).** Follow references/new-stack.md: grill the five choices, write `docs/adr/0001-stack.md` from references/templates/adr-0001-stack.md, scaffold with the framework's own generator, then add a smoke test. Done when the scaffold installs and the ADR names every choice.

**Step 3. verify.** Add a `verify` script to `package.json` that runs typecheck, lint, test and build in that order and stops at the first failure, using only scripts that exist (in mode new, add any missing one; in mode existing, list a missing one in the report instead of inventing it). Run it. If it fails on the fresh scaffold, fix the scaffold and run it again; in an existing repo, report the failure and leave the code alone, even when a stop hook blocks finishing because `verify` fails: answer the hook with the report and stop again, since fixing the app is the user's call. Done when `verify` exits 0, or the failure is in the report.

**Step 4. Instructions and docs.** Fill references/templates/AGENTS.md; write `CLAUDE.md` as the single line `@AGENTS.md` (when `CLAUDE.md` exists without that line, add it at the top). Fill references/templates/architecture.md into `docs/architecture.md`, copy references/templates/GOTCHAS.md to `docs/GOTCHAS.md`, and create `docs/patterns/.gitkeep`. Done when AGENTS.md is under 15 lines, has no placeholder left and names no source path.

**Step 5. Quality.** Follow references/quality.md: strict tsconfig flags, lint rules with boundaries filled from `docs/architecture.md`, and `scripts/ratchet.mjs` chained into `verify` after lint. In mode existing it adds only what cannot fail today and reports the rest with error counts. Done when `verify` exits 0 (or its failure is in the report) and `.ratchet.json` exists.

**Step 6. Worktrees.** Copy references/templates/worktree-setup.sh to `scripts/worktree-setup.sh`, make it executable, and set the variables at its top from what Step 1 found (the env var that holds the port, the one that holds the database URL or name). Run it once in the main checkout: it must exit 0 and change nothing there. Done when that run is clean.

**Step 7. CI and pre-commit.** With no CI config, fill references/templates/ci.yml into `.github/workflows/verify.yml`. With one, add nothing: two workflows running the same checks drift apart, so report which `verify` steps it skips and the one-line change that would make it run `verify`. Then, unless a pre-commit hook already exists, invoke the `setup-pre-commit` skill, skipping its final commit step, since this skill reports before anything is committed. Done when a pre-commit hook exists and its staged-file check passes.

**Step 8. Push policy.** Check `git remote -v`. Without a remote, write `.claude/afk.json` as `{ "push": "manual" }` without asking. With one, ask: `manual` (AFK runs push nothing, the default) or `branch` (AFK runs push ticket and integration branches and open a draft PR). Write the answer from references/templates/afk.json. On `branch`, read and follow `~/.claude/skills/setup-matt-pocock-skills/SKILL.md` (it is not model-invocable, so the Skill tool refuses it) and choose GitHub Issues; put its `## Agent skills` block in `AGENTS.md`, not `CLAUDE.md`, so every harness reads it. Done when `afk.json` is valid JSON.

**Step 9. Finish.** Add `.scratch/` to `.gitignore` if missing. Re-run `verify`; if it now fails, go back to the step that broke it. Then reply with the report: a table of every target from the checklist with `added`, `kept` (already there) or `missing` and why, plus the Step 1 findings in mode existing. Commit nothing unless asked.

## Resources

- [references/discover.md](references/discover.md) - where the real commands, env vars and CI live in an existing repo, and the findings table. Open in Step 1, mode existing.
- [references/new-stack.md](references/new-stack.md) - the stack questions, defaults and scaffold rules. Open in Step 2.
- [references/quality.md](references/quality.md) - tsconfig, lint and boundary rules, the ratchet, optional Stryker, per mode. Open in Step 5.
- `references/templates/` - `AGENTS.md`, `architecture.md`, `GOTCHAS.md`, `adr-0001-stack.md`, `tsconfig-strict.json`, `oxlintrc.json`, `eslint.config.mjs`, `knip.json`, `ratchet.mjs`, `stryker.config.mjs`, `worktree-setup.sh`, `ci.yml`, `afk.json`. Each step names the one it fills.
