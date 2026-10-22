# Coding Standards

Rules for every repo. A repo's own standards win where they conflict.

## Code design

- Give each domain type one definition, owned by the module that owns its data; import it from there, never copy or re-export it
- Use the glossary's term for a concept in code and UI copy; one name never carries two meanings
- Translate foreign shapes (API payloads, vendor types, storage rows) at the boundary; inner code never sees their field names
- Pass time, randomness and I/O in as arguments; do not call them inline in logic. A parameter is enough, not an interface for one implementation
- Start remote I/O once, at the entry point that owns the result, not inside the unit that displays it
- Give each piece of state one owner, at the narrowest scope serving all its readers; do not copy fetched data into local state
- Do not store a value that can be computed from values already present
- Apply a consequence where its event happens, not in a later step that syncs one state to another
- Shape types so an impossible state cannot be represented: one status field, not several booleans
- Put a rule in the unit that owns the data it governs
- When a change edits the same control flow in two or more places, extract it in that change; keep each caller's own answer as an explicit argument
- Trust inputs an earlier step already validated; document the precondition instead of repeating the check
- Add a type, branch or error only for a state a caller can reach
- Before moving or extracting a function, keep it reachable through the module tests already import and mock

## Conformance

- New code follows the nearest existing code that does the same job; a departure needs a reason in the ticket or commit message

## UI

- Reuse the repo's existing tokens, theme values and components before adding a colour, size or font; a new value goes into the shared theme, not into a component
- Take spacing from one scale; no one-off values
- Leave space around and between content blocks: content never touches a container or viewport edge
- Give every interactive element visible hover, focus and disabled states
- Lay out with flexible widths; a changed screen works at 375px and 1280px with no horizontal scroll
- Cover empty, loading and error states for every view that shows remote or computed data
- Match the hierarchy of the screens next to it: headings, type sizes and alignment

## Agent slop

- Comments that narrate what the next line does
- Swallowed errors: a catch that drops the error or returns a default silently
- Casts or ignore comments that silence the type checker
- Tests that assert on mocks instead of behaviour
- Leftover debug output
- Edits outside the ticket's scope
- Deleted, skipped or loosened tests the ticket did not ask to change
- Hard-coded colours or sizes next to an existing theme
- Fixed pixel widths on content

## Not a finding

- A shape fix that needs new scope (a port, layer, flag or second implementation): report it as a design gap instead of asking for it
