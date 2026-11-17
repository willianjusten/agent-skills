# <Folder name>

Nested `AGENTS.md` for a folder with its own pitfalls. Ship a `CLAUDE.md` next to it containing only `@AGENTS.md` so Claude Code loads it.

Shape: a title, then a flat list of rules, one per bullet. Each bullet is a pitfall that bit once or a boundary that must hold, with the reason in the same line.

- Boundary: what this folder must not import or touch, and why.
- Collision point: shared files where parallel work collides, and the rule for adding to them.
- Gotcha: a tool or test quirk, with the fix.

Rules for writing it: only things an agent cannot learn by reading the code; no general advice; under 15 lines; update it when a pitfall is fixed at the source.
