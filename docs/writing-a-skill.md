# Writing a skill

Use the `skill-creator-plus` skill: it writes test prompts first and follows Anthropic's authoring rules. Say "make this a skill" for a new one, or "audit my <name> skill" for an existing one (audit reports, you approve, then it refines). Use `writing-for-agents` for the prose.

## Checklist

1. Folder `skills/<category>/<name>/`, equal to the frontmatter `name`. Categories: `engineering`, `productivity`, `product`, `realtime`, `game`, `creative`, `orchestration`.
2. Frontmatter: only `name`, `description`, `disable-model-invocation`, `paths`, `license`, `metadata`. Put the scope under `metadata`:

   ```yaml
   metadata:
     scope: personal # personal | both | spoke | off
   ```

3. Model-invoked skill: a trigger-rich `description` starting with what it does, then "Use when ...". Skill run only by name: `disable-model-invocation: true` and a short description.
4. `SKILL.md` is a table of contents of ordered steps, each ending on a checkable "Done when". Detail goes in `references/`, one level deep, loaded by the step that needs it.
5. A leaf skill names no sibling from this repo. An upstream skill may be named as "if installed", with a one-line fallback. An orchestrator lives in `skills/orchestration/` or `agents/` and declares `metadata.uses`.
6. `README.md` beside `SKILL.md`: title and tagline, `## What It Does` (mermaid or table), `## Usage` (requests as a user would say them), then optionally `## Output`, `## Requirements`, `## FAQ`.
7. No secrets, no machine paths (`/Users/<name>`), no dates or version pins.
8. `./install.sh check`, fix every error, then `./install.sh`.
9. If the skill joins the flow, add it to "Skills at a Glance" in the root README, and to `docs/images/flow.svg` or `routes.svg` if it changes the path.

An agent is `agents/<category>/<name>.md` with `name` (equal to the file name), `description`, `model` and `metadata.scope`.

Full rules: [AGENTS.md](../AGENTS.md). Tests for the change: [testing.md](testing.md).
