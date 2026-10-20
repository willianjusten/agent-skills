# Stack for a new project

TypeScript and React are fixed; do not ask about them.

## Grill the five choices

Ask one choice at a time, leading with a recommendation and a one-line reason so it can be accepted in a word. Ask what the project is first, since each recommendation depends on it. Stop asking when all five have an answer; accept "you pick" as the recommendation.

| Choice | Ask about | Default when the answer is "you pick" |
| ------ | --------- | ------------------------------------- |
| Framework | Server rendering, routing, where it is hosted | Vite with React for a client app; Next.js when it needs server rendering or API routes |
| Data layer | Is there a database, which one, which ORM or client | None until a ticket needs one |
| Styling | Design system, component library | Tailwind CSS |
| Test runner | Unit and component tests; e2e separately | Vitest with Testing Library |
| Package manager | Team habit, monorepo plans | pnpm |

Record the answers in `docs/adr/0001-stack.md` before scaffolding, with the reason given for each.

## Scaffold

1. Use the framework's own generator with its TypeScript template (for example `pnpm create vite . --template react-ts`), run non-interactively in the current folder. Never hand-write what a generator produces.
2. Add the chosen styling, data client and test runner with their documented setup.
3. Make sure `package.json` has `typecheck` (`tsc --noEmit`, or `tsc -b` for project references), `lint`, `test` (single run, not watch mode) and `build`. Turn on `strict` in `tsconfig.json` if the generator did not.
4. Add one smoke test that renders the root component, so `test` proves something on day one.
5. Install, then run each of the four scripts. Fix the scaffold until all pass.
