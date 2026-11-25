---
name: setup-creative-loop
description: Prepares a repo for /creative-loop once. It writes the adapter .claude/creative-loop.json with the repo's shot, check, verify and record commands, its profile and its directions source, adds the shot and record scripts it lacks, and dry-runs every command. Run by name as /setup-creative-loop.
disable-model-invocation: true
metadata:
  scope: personal
  uses: creative-loop
---

# Setup Creative Loop

Makes `creative-loop` runnable in a repo that is not the lab. The adapter format is the loop's own: read `creative-loop` `references/adapter.md` first; it wins over anything here.

## Rules for every run

1. **The repo's own commands first.** A script the repo already has (tests, lint, a visual check, a screenshot tool) beats a bundled one, because the repo's maintainers keep it working.
2. **Nothing that edits outside the repo, nothing committed.** Leave every change in the working tree and list it; the user commits. Adding a dependency changes the lockfile, so ask first.
3. **Every command runs once before you finish.** An adapter whose commands were never run is a guess, and the loop would find out mid-run.

## Workflow

```text
Progress:
- [ ] 1 Lab or existing adapter
- [ ] 2 Repo read
- [ ] 3 Answers from the user
- [ ] 4 Commands mapped, scripts added
- [ ] 5 Adapter written
- [ ] 6 Dry run green
- [ ] 7 Report
```

**1. Lab or existing adapter.** If the root `package.json` is named `lab`, say the loop uses its built-in lab adapter and stop. If `.claude/creative-loop.json` exists, show it, ask what to change, and continue from step 4 with only those fields. Done when you know whether to write a new adapter.

**2. Read the repo.** Collect what step 3 and 4 need, from files, not guesses: the package scripts (or Makefile or task runner), `CLAUDE.md` or `AGENTS.md` conventions, the issue tracker the repo uses (its agent docs, for example `docs/agents/issue-tracker.md`), every `BRIEF.md` (`git ls-files '*BRIEF.md'`), the dev command, its port and whether a server already answers there, a ready signal the page sets (a `data-*` attribute or element that appears when it has loaded), any screenshot, e2e or visual-check script, and whether `playwright` is a dependency. Details per field: [references/mapping.md](references/mapping.md). Done when each adapter field has a candidate or is marked missing.

**3. Ask once.** One message, numbered questions, each with your recommended answer from step 2: profile (`game`, `experiment` or `site`), brief path, default directions source (brief, GitHub parent issue number, or `.scratch/` feature folder), the pages and states to shoot and the widths (from the brief's done condition and demo mode), and, if missing, consent to add `playwright` as a dev dependency. Wait for the answers. Done when every question is answered.

**4. Map commands and add scripts.** Fill `check`, `checkSlow`, `verify`, `install` and `dev` from the repo's scripts as [references/mapping.md](references/mapping.md) says. For `shot` and `record`, use the repo's own tool if it has one; else copy `scripts/shot.mjs` and `scripts/record.mjs` from this skill into the repo's `scripts/creative-loop/` and build the commands from the answers (flags are in each script's header). Done when every required field has a command.

**5. Write the adapter.** `.claude/creative-loop.json`, fields as `creative-loop` `references/adapter.md` lists them, `scaffold` `null` unless the repo creates pieces from a template. Add the `out` folder to `.gitignore`. Done when `jq . .claude/creative-loop.json` parses.

**6. Dry run.** Reuse the running dev server or start `dev` in the background. Fill the placeholders as the loop would and run, in order: `check`, `shot` (open two of the images and look at them), `checkSlow`, `record` (open the contact sheet), `verify`. A command that errors because of the adapter is fixed in it, and you go back to step 5. A command that runs but reports the repo's own failures stays as it is: report them. Done when each command ran and you have its result.

**7. Report.** The adapter path, one line per command with its dry-run result, the files added or changed, the red checks the repo already had, and the line to start a run: `/creative-loop <brief path> --mode review --budget 45m`.

## Resources

- [references/mapping.md](references/mapping.md) - how to fill each adapter field from what a repo has. Open in steps 2 and 4.
- `scripts/shot.mjs` - copy into the repo, never run from here: screenshots each page at each size, prints the paths, exits 1 on a page error or a missing ready signal. Needs `playwright` in the repo (`pnpm add -D playwright`, then `pnpm exec playwright install chromium`).
- `scripts/record.mjs` - copy next to `shot.mjs` (it imports it): records a tour of the pages, writes `play.mp4` (ffmpeg) or `play.webm`, and `play-contact-sheet.png` (ImageMagick `montage`) or a frames folder.
