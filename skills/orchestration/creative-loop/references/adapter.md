# Adapter

The adapter names a repo's commands, so the loop runs the same way in the lab, a site or any app with a page to look at. It is JSON at `.claude/creative-loop.json` in the repo root. `setup-creative-loop` writes it; the lab needs none, it uses [adapter-lab.json](adapter-lab.json).

## Finding it

In order, first match wins:

1. `.claude/creative-loop.json` in the current repo's root.
2. The current repo's root `package.json` is named `lab`, or `--lab <path>` was given: [adapter-lab.json](adapter-lab.json) for that lab.
3. The input is a bare idea or a pitch (a new piece) and a `lab` checkout sits next to the current repo: [adapter-lab.json](adapter-lab.json) for that lab.
4. None: stop and tell the user to run `/setup-creative-loop` in this repo first. This is the one start-up question that is not defaulted, because a run without commands cannot check anything.

Log which one was used as `Default: adapter <path>`.

## Fields

| Field | Meaning | Required |
| ----- | ------- | -------- |
| `profile` | `game`, `experiment` or `site`: which `references/profile-<name>.md` the run follows | yes |
| `brief` | path of `BRIEF.md` from the repo root; `LOOP.md` goes next to it | yes |
| `directions` | default source: `{"source": "brief"}`, `{"source": "github", "parent": <issue>}` or `{"source": "scratch", "feature": "<folder>"}` | yes |
| `install` | run once in a new worktree, before anything else | no |
| `scaffold` | creates a new piece; `null` when the piece already exists | no |
| `dev` | `command` starts the dev server; `url` is the page to open, `null` when the server prints it. Reuse a server already answering on that URL before starting one (some servers refuse a second copy in one folder) | yes |
| `shot` | writes the cycle's images and prints their paths, exits non-zero on failure | yes |
| `check` | the per-cycle gate, run before every commit; exit 0 is green, and every `FAIL` line it prints is a failure | yes |
| `checkSlow` | the gate that needs a build or minutes; run in review cycles and at hand-off | no |
| `verify` | the hand-off gate; exit 0 passes | yes |
| `record` | writes a video and a contact sheet of the piece and prints their paths | yes |
| `out` | folder (from the repo root, gitignored) for shots, `history/` frames and `summary.md` | yes |

Placeholders the loop fills: `{app}` (the piece's kebab-case name), `{kind}` (`game` or `experiment`), `{category}` (`games` or `experiments`), `{seconds}` (demo seconds to shoot, space-separated), `{url}` (the running page). A command may chain with `&&`. Unknown fields are ignored.

## Example

A site working on an existing page, directions from a GitHub parent issue:

```json
{
  "profile": "site",
  "brief": "docs/world/BRIEF.md",
  "directions": { "source": "github", "parent": 317 },
  "install": "pnpm install --frozen-lockfile",
  "scaffold": null,
  "dev": { "command": "pnpm dev", "url": "http://localhost:3000/next" },
  "shot": "node scripts/world-loop/shot.mjs --url {url} --out .loop/shots",
  "check": "pnpm typecheck && pnpm lint && pnpm format:check && pnpm test",
  "checkSlow": "pnpm world:check --url {url}",
  "verify": "pnpm world:check --url {url}",
  "record": "node scripts/world-loop/record.mjs --url {url} --out .loop/record",
  "out": ".loop"
}
```
