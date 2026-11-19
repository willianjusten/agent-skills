# Testing

Two checks guard every commit; the `pre-commit` hook runs both (about 6 s).

| Command | Checks |
| ------- | ------ |
| `./install.sh check` | each own skill against the `skill-creator-plus` validator, scope and README rules; each agent's frontmatter; every skill or agent an orchestrator names exists and is visible to it |
| `tests/run.sh` | every `tests/*.test.sh` in parallel (about 3 s); prints each file's output in name order, ends `All tests passed.` or `FAILED: <files>` with exit 1 |

## One test file

```bash
bash tests/conduct.test.sh
```

Each file works in its own `mktemp` directory and prints `ok` or `FAIL` per assertion; it exits 1 when any assertion failed. Files by area: `conduct`, `orchestrators`, `polish-agents`, `realtime-judge`, `realtime-skills`, `motion-review`, `agents-install`, `settings-hooks`, `vendoring`, `write-scope-hook`.

## Adding a test

Copy the shape of a neighbour (`pass` and `fail` helpers, a `failures` counter, exit 1 when it is above zero) into `tests/<name>.test.sh`; `run.sh` picks it up by the `.test.sh` suffix. A new skill or agent usually needs only `./install.sh check`; add a test when it ships a script or a rule `check` cannot see.

## Commands in the lab repo

Skills point agents at the lab's tiers: `pnpm check` (typecheck and unit tests, about 9 s) for every change, `pnpm verify <app>` for an app, and `pnpm test:e2e:fast` then `pnpm test:e2e:slow` for `packages/` or `templates/`. They are documented in the lab README.
