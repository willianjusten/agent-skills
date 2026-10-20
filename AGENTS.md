# AGENTS.md

Conventions for working in this repository. This file is for agents editing the repo itself; it is never installed and never reaches a project that uses the skills.

## What lives where

| Path | Owner | Edit it? |
| ---- | ----- | -------- |
| `skills/<category>/<name>/` | this repo | yes: own skills |
| `vendor/<owner>/<repo>/` | `npx skills` (via `./install.sh --update`) | no: changes are lost on update. The only local patch is the `code-review` rename in `apply_renames`; policy goes in `harness/` files the skills already read |
| `scopes.json` | this repo | yes: one line per vendored skill |
| `harness/` | this repo | yes: linked into `~/.claude`, so edits apply immediately |
| `dist/` | `install.sh` | no: generated, gitignored |
| `.scratch/` | anyone | free-form notes, gitignored |

## Creating or changing a skill

1. Use the `skill-creator-plus` skill: NEW mode for a new skill, AUDIT then REFINE for an existing one. It writes test prompts first and follows Anthropic's authoring rules.
2. Put the folder at `skills/<category>/<name>/`. Categories: `engineering`, `productivity`, `product`. The folder name equals the frontmatter `name`.
3. Add the scope under `metadata` (the only place extra fields are portable across harnesses):

   ```yaml
   metadata:
     scope: personal # personal | both | spoke | off
   ```

4. Add a `README.md` next to `SKILL.md` (shape below).
5. Run `./install.sh check`, fix every error, then `./install.sh`.
6. Add the skill to the catalog table in the root `README.md`.

## Skill conventions

- `SKILL.md` is a table of contents: what to do, in order. Detail goes in `references/` and is loaded only by the step that needs it, one level deep.
- Model-invoked skills get a trigger-rich `description` ("Use when ..."). Skills only run by name set `disable-model-invocation: true` and get a short, human-facing description.
- Use only open-standard frontmatter: `name`, `description`, `disable-model-invocation`, `paths`, `license`, `metadata`. Anything else is ignored by some harness.
- A skill never names or depends on a sibling skill; each one must work alone.
- No secrets, no machine paths (`/Users/<name>`), no dates or version pins in skill text.

## Skill README shape

Sections in this order, nothing else:

1. `# <Title>` and a one-line tagline.
2. `## What It Does`: a short mermaid flowchart or a table of phases and outputs.
3. `## Usage`: example requests in a `text` block, phrased the way a user would say them.
4. Optional: `## Output` (files it writes), `## Requirements` (tools, MCP servers), `## FAQ` (one line per entry).

## Scopes

| Scope | Linked to | Visible in |
| ----- | --------- | ---------- |
| `personal` | `~/.claude/skills` | every repo except Spoke (off via `skillOverrides`; Cursor still shows it) |
| `both` | `~/.claude/skills` | every repo, Spoke included |
| `spoke` | `dist/spoke/` | Spoke only, through agentplan |
| `off` | nowhere | nowhere |

## Harness files

- `harness/shared/instructions.md` is `~/.claude/CLAUDE.md` and the Cursor User Rules. After editing it, paste it into Cursor again.
- Claude Code writes `/config` changes through the `settings.json` symlink. Review those diffs and strip machine-specific values before committing.

## Commits

Atomic, one logical step each: vendor update, scope change, new skill, harness change, installer change. Never commit or push without the user's approval.
