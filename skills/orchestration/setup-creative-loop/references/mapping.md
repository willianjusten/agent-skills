# Mapping a repo to the adapter

One section per field. "Script" means an entry the repo already has (package scripts, Makefile targets, a task runner); run it through the repo's package manager (`pnpm`, `npm run`, `yarn`, `bun`), read from its lockfile.

## check

The fast gate the loop runs before every commit, so it must finish in about a minute and need no build. Chain with `&&`, in this order, the ones that exist: typecheck, lint, format check, unit tests. Leave out anything that writes files (a formatter without `--check`, a snapshot update). With none of them, use the test script; with no tests, say so in the report and use `true`, never invent a test.

## checkSlow and verify

`checkSlow` is the slow gate run in review cycles when a run passes `--slow-checks` (off by default): an e2e suite, a visual or performance check, a build plus a smoke run. Prefer a form that targets the running server (`--url {url}`, `BASE_URL={url}`) over one that needs a fresh build. `verify` is the hand-off gate, also only with `--slow-checks`: the slowest honest one the repo has, usually the same as `checkSlow`, or the build (`build`) when there is nothing else. Never `null`: the hand-off needs a verdict.

## dev and url

`dev.command` is the repo's dev script. `dev.url` is the page the piece lives on, with the port the dev server uses in this checkout (read the script, its config or the running process; `lsof -iTCP -sTCP:LISTEN -P` shows a running one). Some servers refuse a second copy in the same folder (Next.js does), so the loop reuses one already answering on that URL; say so in the report when one was running.

## install

The repo's frozen install, for example `pnpm install --frozen-lockfile`. Used only when the loop makes a new worktree.

## shot

A repo screenshot or visual tool that writes images and prints their paths is used as is. Otherwise the bundled script, copied to `scripts/creative-loop/shot.mjs`:

```text
node scripts/creative-loop/shot.mjs --url {url} --pages "<page>,<page>" --sizes <WxH>,<WxH> --ready "<selector>" --out <out>/shots
```

- Pages: the states the brief's done condition and demo mode name, as URL parameters or paths (`?stop=wide`, `?time=night`, `/about`). Empty first page means the start URL.
- Sizes: the widths the brief names; else `1440x900,390x844`.
- Ready: the selector the page sets once it has drawn (`[data-world-ready=true]`); without one, raise `--wait`.

## record

A repo recorder is used as is. Otherwise the bundled script, next to `shot.mjs`:

```text
node scripts/creative-loop/record.mjs --url {url} --pages "<page>,<page>" --size 1440x900 --ready "<selector>" --dwell 4000 --out <out>/record
```

Pages in the order a visitor or player would meet them: the tour is the video the user watches at hand-off.

## profile

`game` when the piece is won or lost (a score, lives, levels), `experiment` when it is watched or played with, `site` when it is pages a visitor reads in an existing web app. When a repo holds more than one kind, ask which the next run is for.

## directions

The tracker the repo's agent docs name: GitHub (`{"source": "github", "parent": <issue>}`, the parent whose sub-issues are the brief's directions) or local `.scratch/` (`{"source": "scratch", "feature": "<folder>"}`). With neither, or when the brief's Next directions list is the only list, `{"source": "brief"}`.

## out

A gitignored folder at the repo root, `.loop` by default. Shots, records, `history/` frames and `summary.md` go under it.
