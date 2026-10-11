<p align="center">
  <img src="assets/banner.png" alt="skill-creator-plus" width="100%">
</p>

# skill-creator-plus

A free Claude skill that audits, builds and improves other skills against Anthropic's own skill-writing rules, including what changed for the newest Claude models.

Point it at a skill (or a whole folder of skills) and it gives you a findings report first: every rule marked pass, fail or not applicable, with the file and line as evidence and a proposed fix. It changes nothing until you say which fixes to apply.

## Why this matters now

A skill is a folder with a `SKILL.md` file that teaches Claude how to do a job the same way each time. Anthropic publishes clear rules for writing them, and it is easy to break several without noticing: descriptions that never trigger, reference files Claude only half reads, rules buried where compaction cuts them.

The core rules on Anthropic's skill authoring page have been stable for about a year. What changed is the models:

- The prompting guide for **Claude Fable 5** says skills written for older models are often **too prescriptive** and can make output worse. Review them and remove what the model now does better on its own, but test before you delete.
- The guides for **Fable 5, Opus 5.5 and Sonnet 5.5** all list a `reasoning_extraction` refusal: asking Claude to **write out its reasoning** in the reply can be declined. A short explanation of the answer is fine.
- The Fable 5 guide also says to **give the reason**, not only the request, to steer with brief instructions instead of long lists, and to **make checking explicit**, preferring a fresh Claude as the checker over self-review.

Claude Code adds its own: put the most important instructions at the top of `SKILL.md` (compaction keeps only the first 5,000 tokens), and move any rule that has to hold on every run into a hook.

This skill checks all of that, and the validator script checks the mechanical parts in a second.

## Install

**Claude Code.** Put the folder in your skills folder and name it `skill-creator-plus`:

```bash
# for all your projects
git clone https://github.com/robonuggets/skill-creator-plus ~/.claude/skills/skill-creator-plus

# or for one project only, from the project folder
git clone https://github.com/robonuggets/skill-creator-plus .claude/skills/skill-creator-plus
```

On Windows, `~/.claude` is the `.claude` folder inside your user folder. Downloading the ZIP from GitHub and copying the folder there works too.

**claude.ai.** Zip the folder (`SKILL.md`, `references/`, `scripts/` and `LICENSE`; you can leave out `examples/`) and upload it under Skills in claude.ai settings. The frontmatter uses only the fields claude.ai accepts. The validator needs code execution turned on.

## Use it

Just ask in plain words. Three modes:

| Mode | Say something like | You get |
|---|---|---|
| AUDIT | "Audit my deploy skill against Anthropic's rules." / "Check every skill in ~/.claude/skills and tell me what to fix first." | A report: one row per rule, fails first, ranked fixes. Nothing is edited until you pick. |
| NEW | "Make this a skill, we write release notes like this every Friday." | Test prompts first, then a new skill folder that passes the validator. |
| REFINE | "The report skill keeps forgetting the date filter. Fix the skill." | The rule rewritten around its reason, usually shorter than before. |

"Improve my skill for Opus 5.5" runs AUDIT, then REFINE with the fixes you approve.

See [examples/pdf-helper-report.md](examples/pdf-helper-report.md) for a full audit of a deliberately broken sample skill.

## The validator

`scripts/validate_skill.py` checks the rules a script can check. Python 3.8 or newer, standard library only, works on Windows, Mac and Linux.

```bash
python3 scripts/validate_skill.py path/to/my-skill              # one skill
python3 scripts/validate_skill.py --all ~/.claude/skills         # every skill in a folder, one table
python3 scripts/validate_skill.py path/to/my-skill --json       # machine-readable
python3 scripts/validate_skill.py path/to/my-skill --ban-em-dash # also flag em dashes
python3 scripts/init_skill.py my-new-skill --path ~/.claude/skills --refs --scripts
```

Exit codes: `0` no errors (warnings and notes are fine), `1` errors found, `2` could not run. Each finding carries a rule ID from the table below.

Part of the real output for the sample skill in `examples/pdf-helper/`:

```text
Skill: examples/pdf-helper (name: Claude_PDF_Helper)

ERROR  FM1    SKILL.md:4  'description' has an unquoted ': ' (or ends with ':'), which YAML reads as a new key, so the frontmatter will not parse. Wrap the value in double quotes.
ERROR  ST4    reference/advanced.md:3  reference/details.md is reached only through other reference files (reference/advanced.md:3), never from SKILL.md. Claude may only preview files it reaches that way (for example with head -100). Link it from SKILL.md, or fold its content into the file that needs it.
ERROR  ST5    reference/api.md  reference/api.md is 124 lines with no contents list in its first 50 lines. Add a '## Contents' list at the top so a partial read still shows everything the file covers.
WARN   DS2    SKILL.md:4  description is not in third person (found "I can"). It is injected into the system prompt; write "Processes Excel files", not "I can help" or "You can use this".
WARN   NM2    SKILL.md:20  asks Claude to write out its reasoning ("Think step by step and write"). Newer models (Claude Fable 5, Opus 5.5, Sonnet 5.5) may decline this with the reasoning_extraction refusal. Ask for the answer, or a short explanation of it, instead.
NOTE   HK1    SKILL.md:11,31  words like "must always" mark a rule that must hold every time, and the frontmatter has no hooks. Prose can be skipped or cut by compaction; if the rule truly must hold, enforce it with a hook (frontmatter hooks:).
...
Result: 8 errors, 11 warnings, 6 notes - fix the errors first.
```

The full output is in [examples/pdf-helper-validator-output.txt](examples/pdf-helper-validator-output.txt). With `--all` you get one table:

```text
Skill       Errors  Warnings  Notes  Rules with errors or warnings
----------  ------  --------  -----  -----------------------------
pdf-helper       8        11      6  FM1 FM2 ST4 ST5
```

## The rules

46 rules. **Script** means the validator decides. **Script + read** means the validator flags candidates and Claude confirms in context. **Read** means Claude judges it during an audit and cites the evidence. "Advice" marks rules from practice rather than from Anthropic's docs.

| ID | Rule | Checked by | Source |
|---|---|---|---|
| FM1 | Frontmatter starts on line 1 and parses as YAML | Script | [Claude Code: Frontmatter reference][cc-fm] |
| FM2 | Name: lowercase, numbers, hyphens, max 64, no "anthropic" or "claude", matches the folder | Script | [Best practices: YAML frontmatter requirements][p-yaml] |
| FM3 | Name says the activity (`processing-pdfs`), not vague (`helper`) | Script + read | [Best practices: Naming conventions][p-naming] |
| FM4 | Only recognised fields; only six for claude.ai and the Skills API | Script | [Claude Code: Frontmatter outside Claude Code][cc-portable] |
| FM5 | Invocation set on purpose (manual-only, background, `paths`) | Read | [Claude Code: Control who invokes a skill][cc-invoke] |
| DS1 | Description present, at most 1,024 characters, no XML tags | Script | [Best practices: YAML frontmatter requirements][p-yaml] |
| DS2 | Description in third person | Script + read | [Best practices: Writing effective descriptions][p-desc] |
| DS3 | Says what it does and when to use it, in the user's words | Script + read | [Best practices: Writing effective descriptions][p-desc] |
| DS4 | Key use case first; description plus `when_to_use` under 1,536 characters | Script + read | [Claude Code: Descriptions are cut short][cc-cut] |
| ST1 | SKILL.md body under 500 lines | Script | [Best practices: Progressive disclosure][p-pd] |
| ST2 | Most important instructions near the top | Script + read | [Claude Code: Claude stops following a skill][cc-stops] |
| ST3 | Split by area, details on demand | Read | [Best practices: Progressive disclosure][p-pd] |
| ST4 | References one level deep from SKILL.md | Script | [Best practices: Avoid deeply nested references][p-nested] |
| ST5 | Contents list on reference files over 100 lines | Script | [Best practices: Table of contents][p-toc] |
| ST6 | Every file reachable and well named; no dead links or backups | Script + read | [Best practices: Runtime environment][p-runtime] |
| ST7 | Forward slashes in every path | Script | [Best practices: Avoid Windows-style paths][p-paths] |
| CT1 | Concise: only what Claude does not already know | Read | [Best practices: Concise is key][p-concise] |
| CT2 | Degrees of freedom match the risk; mix levels; "what if Claude does this differently?" | Read | [Best practices: Degrees of freedom][p-freedom] + advice |
| CT3 | Nothing time-sensitive; old ways under "Old patterns" | Script + read | [Best practices: Time-sensitive information][p-time] |
| CT4 | One term per concept | Read | [Best practices: Consistent terminology][p-terms] |
| CT5 | Templates say how strict they are | Read | [Best practices: Template pattern][p-template] |
| CT6 | Input and output examples where style matters | Read | [Best practices: Examples pattern][p-examples] |
| CT7 | A default plus one escape hatch, not a menu | Read | [Best practices: Too many options][p-options] |
| CT8 | MCP tools named in full, `ServerName:tool_name` | Read | [Best practices: MCP tool references][p-mcp] |
| CT9 | No `TODO`, `FIXME` or unfilled placeholders | Script | Advice |
| CT10 | One rule, one place | Read | Advice |
| WF1 | Checklist with "done when" lines and a go-back line | Script + read | [Best practices: Workflows for complex tasks][p-workflows] |
| WF2 | Feedback loop: check, fix, repeat (a style guide counts as a check) | Read | [Best practices: Feedback loops][p-loops] |
| WF3 | Plan, validate, execute for batch or destructive jobs | Read | [Best practices: Verifiable intermediate outputs][p-plan] |
| WF4 | Standing instructions, not one-time steps | Read | [Claude Code: Skill content lifecycle][cc-lifecycle] |
| SC1 | Scripts solve errors instead of deferring them | Read | [Best practices: Solve, don't defer][p-solve] |
| SC2 | No unexplained ("voodoo") constants | Read | [Best practices: Solve, don't defer][p-solve] |
| SC3 | Says whether to run or read each script | Read | [Best practices: Utility scripts][p-scripts] |
| SC4 | Error messages name the problem and the fix | Read | [Best practices: Verifiable intermediate outputs][p-plan] |
| SC5 | Packages listed with install lines; the Claude API cannot install | Script + read | [Best practices: Package dependencies][p-packages] |
| NM1 | Not too prescriptive for newer models; test before deleting | Read + test | [Fable 5: Scaffolding changes][f5-scaffold] |
| NM2 | No instruction to write out the model's reasoning | Script + read | [Fable 5: Scaffolding changes][f5-scaffold], [Opus 5.5][o55-thinking] |
| NM3 | Rules carry their reason | Read | [Fable 5: Give the reason][f5-reason] |
| NM4 | Brief steering; capitals only for real hard lines | Script + read | [Fable 5: Instruction following][f5-steer] + advice |
| NM5 | Verification explicit; fresh-context verifier preferred | Read | [Fable 5: Scaffolding changes][f5-scaffold] |
| HK1 | A rule that has to hold on every run lives in a hook | Script + read | [Claude Code: Stops following][cc-stops], [Hooks in skills][hooks] |
| TS1 | At least three evaluations, built first, with a baseline | Read | [Best practices: Build evaluations first][p-evals] |
| TS2 | Fresh Claude tests on real work, skill on and off | Read | [Best practices: Iterate with Claude][p-ab], [Claude Code: Evaluate][cc-evals] |
| TS3 | Tested on the models it runs on; full sweep only where it matters | Read | [Best practices: Test with all models][p-models] + advice |
| LB1 | No two skills claim the same triggers | Read | Advice |
| LB2 | Unused skills found with `/skill-doctor` and turned off | Read | [Claude Code: Find unused skills][cc-unused] |

Rules were checked against Anthropic's pages on 2026-10-05.

## What is in the box

```text
SKILL.md                      the skill: rules, the three modes, links to the rest
references/audit-checklist.md every rule with why, how to check, and the report format
references/authoring-guide.md how to write each part of a skill
references/testing.md         evaluations, baselines, model sweeps, test before you delete
scripts/validate_skill.py     the validator
scripts/init_skill.py         scaffolds a new skill that passes the validator
examples/                     a broken sample skill, its validator output and its audit report
```

## Credits and license

The failure-mode names used in audits (no-op, duplication, sediment, sprawl, premature completion) come from Matt Pocock's "writing-great-skills". Not affiliated with Anthropic. MIT license, see [LICENSE](LICENSE).

Made by [RoboNuggets](https://www.skool.com/robonuggets)

[p-concise]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#concise-is-key
[p-freedom]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#set-appropriate-degrees-of-freedom
[p-models]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#test-with-all-models-you-plan-to-use
[p-naming]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions
[p-desc]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#writing-effective-descriptions
[p-pd]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#progressive-disclosure-patterns
[p-nested]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-deeply-nested-references
[p-toc]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#structure-longer-reference-files-with-table-of-contents
[p-workflows]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#use-workflows-for-complex-tasks
[p-loops]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#implement-feedback-loops
[p-time]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-time-sensitive-information
[p-terms]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#use-consistent-terminology
[p-template]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#template-pattern
[p-examples]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#examples-pattern
[p-evals]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#build-evaluations-first
[p-ab]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#develop-skills-iteratively-with-claude
[p-paths]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-windows-style-paths
[p-options]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-offering-too-many-options
[p-solve]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#solve-dont-defer
[p-scripts]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#provide-utility-scripts
[p-plan]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#create-verifiable-intermediate-outputs
[p-packages]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#package-dependencies
[p-runtime]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#runtime-environment
[p-mcp]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#mcp-tool-references
[p-yaml]: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#yaml-frontmatter-requirements
[cc-fm]: https://code.claude.com/docs/en/skills#frontmatter-reference
[cc-portable]: https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code
[cc-invoke]: https://code.claude.com/docs/en/skills#control-who-invokes-a-skill
[cc-lifecycle]: https://code.claude.com/docs/en/skills#skill-content-lifecycle
[cc-stops]: https://code.claude.com/docs/en/skills#claude-stops-following-a-skill
[cc-cut]: https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short
[cc-evals]: https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill
[cc-unused]: https://code.claude.com/docs/en/skills#find-unused-skills
[hooks]: https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents
[f5-scaffold]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5#recommended-scaffolding-changes
[f5-steer]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5#strong-instruction-following
[f5-reason]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5#give-the-reason-not-only-the-request
[o55-thinking]: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5#prompts-written-for-thinking-disabled
