# agent-skills

One repo for agent skills, global instructions and Claude Code config, shared by every machine. Works in Claude Code and Cursor through the open Agent Skills format.

## New machine

1. Dotfiles (`~/Developer/dotfiles/install.sh`), which clones this repo to `~/Developer/agent-skills` and runs `./install.sh`.
2. Log in to Claude Code (`claude`).
3. Paste `harness/shared/instructions.md` into Cursor: Settings > Rules > User Rules.
4. Spoke: clone the workspace and its web repos, run its setup, then `./install.sh` again (see [Spoke](#spoke)).

## Layout

```
skills/<name>/SKILL.md        own skills; scope in frontmatter metadata.scope
skills/.template/SKILL.md     copy this to start a new skill
vendor/mattpocock/            Matt Pocock's skills, managed by `npx skills` (store + skills-lock.json)
scopes.json                   scope for each vendored skill
harness/shared/instructions.md  global rules; linked to ~/.claude/CLAUDE.md, pasted into Cursor
harness/claude/               settings.json, statusline-command.sh, matt-skills/ (linked into ~/.claude)
install.sh                    the only command
dist/                         generated, gitignored
```

## Scopes

| Scope      | Where it shows up                                    |
| ---------- | ---------------------------------------------------- |
| `personal` | everywhere except Spoke                              |
| `both`     | everywhere, including Spoke                          |
| `spoke`    | only in Spoke                                        |
| `off`      | nowhere (vendored skill kept on record, not installed) |

Own skills declare it in frontmatter:

```yaml
metadata:
  scope: both
```

Vendored skills are listed in `scopes.json`. A vendored skill missing from it is not linked.

## Common tasks

| Task                         | Do                                                               |
| ---------------------------- | ---------------------------------------------------------------- |
| Add a skill                  | `cp -R skills/.template skills/<name>`, edit it, `./install.sh`  |
| Remove a skill               | delete `skills/<name>`, `./install.sh`                           |
| Change a scope               | edit the frontmatter or `scopes.json`, `./install.sh`            |
| Update vendored skills       | `./install.sh --update`, review `git diff`, commit               |
| Enable a vendored skill      | set it to `personal`/`both` in `scopes.json`, `./install.sh --update` |
| Share project instructions   | `./install.sh init-project <dir>` (AGENTS.md + CLAUDE.md with `@AGENTS.md`) |

## What install.sh touches

- `~/.claude/CLAUDE.md`, `settings.json`, `statusline-command.sh`, `matt-skills/`: symlinks into `harness/`. A real file in the way is reported and left alone unless `--force`.
- `~/.claude/skills/<name>`: one symlink per `personal` or `both` skill. Links into this repo that are no longer wanted are removed. Nothing else in `~/.claude/skills/` (such as `synced/`) is touched.
- `vendor/mattpocock/` (only with `--update`): runs `npx skills update`, adds enabled skills that are missing, removes skills set to `off`, lists new upstream skills as candidates.
- Vendored files, on every run: renames upstream `code-review` to `matt-code-review` (it collides with Claude Code's built-in `/code-review`).
- If `~/Developer/spoke` exists: `spoke/.claude/settings.local.json` (`skillOverrides`) and `dist/spoke/`.

It is idempotent: a second run prints `No changes.`

Requirements: `git`, `jq`; `--update` also needs node >= 22.20 (asdf, `~/.tool-versions`).

## Spoke

Spoke's skills come from its own workspace and `agentplan`. This repo adds two things:

- Personal-only skills are switched off in Spoke through `skillOverrides: off` in `spoke/.claude/settings.local.json` (Claude Code only).
- Spoke-only skills are linked into `dist/spoke/`, which agentplan reads as a global skill source. Add it once to `spoke/agentplan.jsonc`; `install.sh` prints the line when it is missing:

```jsonc
"sources": { "skills": { "global": ["../agent-skills/dist/spoke"] } }
```

Then `agentplan generate` in Spoke.

## Manual cases

| Symptom                                           | Fix                                                                                       |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `Rename patch no longer matches`                  | Upstream changed the text. Update the pattern in `apply_renames` in `install.sh`.          |
| `Unpatched code-review references`                | Upstream added a new reference. Add a `patch_file` line for it.                            |
| `real file in the way`                            | Something replaced a symlink (for example Claude Code rewrote `settings.json`). Diff it against `harness/`, keep what you want, then `./install.sh --force`. |
| A skill appears twice in Cursor                   | Cursor also reads `~/.agents/skills` and `~/.cursor/skills`; keep them empty.              |
| Personal skills visible in Spoke in Cursor        | Expected: Cursor ignores `skillOverrides`.                                                 |
| `new upstream skill, add it to scopes.json`       | Decide a scope for it in `scopes.json`, then `./install.sh --update`.                      |
| `skills CLI failed`                               | The output above it is from `npx skills`; usually network or a skill name that no longer exists upstream. |
