# Directions sources

The run's directions come from one of three places. Ask the user which one at the start, with the adapter's `directions` as the recommended answer (lab: the brief); unattended, take it and log `Default: directions from <source>`. The brief stays the source of pillars, Not this and the done condition whatever the list comes from.

## Building the list

Write one direction per line to a scratch file and pass it as `start-run.sh --directions-from <file>`. A line is `- [ ] <title> (<pointer>)`, or `- [x] ...` for one already met. The brief needs no file: `start-run.sh` reads its Next directions list.

| Source | Pointer | Order | Already met |
| ------ | ------- | ----- | ----------- |
| `brief` | none | the brief's numbered list | none |
| `github` | `#<number>` | the parent's sub-issues in order (`gh api repos/{owner}/{repo}/issues/<parent>/sub_issues`), closed ones left out | open, but `git log --grep '#<number>'` on the run branch shows it built: tick it and log `Default: #<number> already built` |
| `scratch` | `.scratch/<feature>/issues/<NN>-<slug>.md` | ticket number | `Status: done` left out; built but not marked: tick it, as for GitHub |

A ticket blocked by an open one (`Blocked by:` line, or GitHub's blocked-by) goes after its blocker. Done when every open ticket is a line.

## Running one

Before a direction with a pointer, read its ticket: the acceptance criteria are what "met" means for it, beside the brief's pillars. A ticket asking for something the brief's Not this forbids is logged as `Brief is wrong: ...` and skipped, not built.

## Writing back

Only to the ticket a direction points at, only when it is met and committed on the run branch:

- `scratch`: set its `Status:` to `done` and append under `## Comments` the commits and the cycle lines that met it, at once.
- `github`: at hand-off, once per met ticket, `gh issue comment <number>` with the run branch and its commits, then `gh issue close <number>`. Not mid-run: a later cycle can still revert it, and only the hand-off gates say the branch holds.

A cut direction (two failed tries) gets a comment with the symptom and stays open. Never assign, label, reopen or create tickets; a new idea from a review is a new line in `LOOP.md`, not a ticket.
