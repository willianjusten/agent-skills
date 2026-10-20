# Quality checks

Checks catch what prose cannot: strict types, lint rules, module boundaries, and a ratchet that keeps unused code, duplication and complexity from growing. Template paths are relative to this skill's folder.

## Mode new or existing

- **new**: apply everything below, then fix the scaffold until `verify` passes. The fixes belong to the scaffold, not to the rules: never loosen a rule to get green.
- **existing**: a stricter flag or rule can turn a green repo red, so change nothing that would. Add only the parts that cannot fail today: the warn-level complexity rules and the ratchet, which baselines whatever it finds. For each stricter tsconfig flag, lint preset and boundary rule, count the errors it would add (enable it, run, revert) and list it in the report with that count.

## 1. tsconfig

Merge references/templates/tsconfig-strict.json into every tsconfig whose `compilerOptions` cover source or config files (for Vite, `tsconfig.app.json` and `tsconfig.node.json`, not the root file that only lists references). Done when `typecheck` passes.

## 2. Lint

Use the linter the repo already has; never add a second one.

| Linter found | Template | How |
| ------------ | -------- | --- |
| oxlint (`.oxlintrc.json`) | references/templates/oxlintrc.json | Merge into the existing file, keeping its plugins and rules. |
| ESLint (`eslint.config.*`) | references/templates/eslint.config.mjs | Append its blocks after the framework's config in the existing file. |

Install with the repo's package manager; the npm forms are:

```bash
npm install -D eslint-plugin-sonarjs eslint-plugin-boundaries
npm install -D oxlint-tsgolint    # oxlint
npm install -D typescript-eslint  # ESLint
```

Fill the placeholders from `docs/architecture.md`:

- `boundaries/elements`: one entry per row of the Modules table, with the folder that module lives in. Files outside every folder are not checked; keep root entry files there.
- `boundaries/dependencies`: one policy per row, allowing exactly its "May import" column. A row that may import nothing gets no policy. Name each enforced rule once under Boundaries in `docs/architecture.md`.
- `no-restricted-imports` and its override: the database client package from `package.json` or the stack ADR, allowed only in the data module's folder. With no data layer, delete both.

Complexity and `max-params` stay at `warn`: the ratchet counts them, so a new one fails `verify` while legacy ones can wait. Done when `lint` exits 0.

## 3. Ratchet

1. Copy references/templates/ratchet.mjs to `scripts/ratchet.mjs` and set `SOURCE_DIRS` and `LINTER` at its top.
2. Install `knip` and `jscpd` (`npm install -D knip jscpd`). Fill references/templates/knip.json into `knip.json` (with an existing knip config, add `jscpd` to its `ignoreDependencies`, since only the ratchet runs it).
3. Add `"ratchet": "node scripts/ratchet.mjs"` and chain it into `verify` right after lint.
4. Run it once. In mode new, `unused` must be 0: a config file or entry knip calls unused is a knip config gap (add it to `entry`), not debt. The run writes `.ratchet.json`; it is committed with the setup.

Done when a second `ratchet` run passes and leaves `.ratchet.json` unchanged.

## 4. Mutation testing (optional, off by default)

Add only when the user asks for it. Copy references/templates/stryker.config.mjs to the repo root, set `BASE_BRANCH` and `TEST_RUNNER`, install it (`npm install -D @stryker-mutator/core @stryker-mutator/vitest-runner` for Vitest), and add `.stryker-tmp/` and `reports/mutation/` to `.gitignore`. It mutates only the source files changed since the base branch and is never part of `verify`. Otherwise mention in the report that it is available.
