# Install and scopes

`./install.sh` links this repo into `~/.claude`, so editing a file here changes it on the machine at once. A second run prints `No changes.`

## Commands

| Command | Use it to |
| ------- | --------- |
| `./install.sh check` | validate own skills, agents and orchestrator dependencies; changes nothing |
| `./install.sh` | install vendored skills at their locked commit and link everything |
| `./install.sh --update [<owner>/<repo>]` | move vendored sources to their newest upstream commit; review the printed diff, then commit the locks |
| `./install.sh --force` | replace a real file sitting where a link should go |

Run `check` first and fix every error before a plain `./install.sh`. Requirements: `git`, `jq`, `python3` (for `check`), node >= 22.20 when vendored skills are fetched.

## What it links

- Own skills (`skills/<category>/<name>/`) and `personal` or `both` vendored skills into `~/.claude/skills/<name>`.
- Agents (`agents/<category>/<name>.md`) into `~/.claude/agents/`.
- `harness/shared/instructions.md` as `~/.claude/CLAUDE.md`, plus `CODING_STANDARDS.md`, `settings.json`, the statusline and the `loop-stop` hook.
- Git hooks: it sets `core.hooksPath` to `.githooks/`, whose `pre-commit` runs `tests/run.sh` and `./install.sh check`.

`vendor/<owner>/<repo>/skills-lock.json` pins each source to an upstream commit; the fetched `.agents/` folder is gitignored. The only local patch is renaming Matt's `code-review` to `matt-code-review`.

## Scopes

| Scope | Linked to | Visible in |
| ----- | --------- | ---------- |
| `personal` | `~/.claude/skills` | every repo except Spoke |
| `both` | `~/.claude/skills` | every repo, Spoke included |
| `spoke` | `dist/spoke/` | Spoke only |
| `off` | nowhere | nowhere |

- Own skill or agent: set `metadata.scope` in its frontmatter. Agents take only `personal`, `both` or `off`.
- Vendored skill: one line in `scopes.json` under its source. A skill missing there is not installed.
- An orchestrator must be scoped where everything it names is visible; `check` enforces it.

## Tasks

| Task | Do |
| ---- | -- |
| Change a scope | edit the frontmatter or `scopes.json`, `./install.sh check`, `./install.sh` |
| Enable a vendored skill | set it in `scopes.json`, then `./install.sh --update <owner>/<repo>` |
| Add a vendor source | add `"<owner>/<repo>": { "<skill>": "personal" }` to `scopes.json`, then `--update` that source and commit the lock |
| Remove an own skill | delete its folder, `./install.sh` |

Troubleshooting messages are in the root [README](../README.md#reference).
