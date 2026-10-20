# Coding Standards

## Code design

- When a change edits the same control flow in two or more places, extract it into one function in that change instead of deferring it. Keep each caller's own answer (scope, flags) as an explicit argument; no defaults, shared constants or wrappers that hide it
- Trust inputs an earlier step already validated or narrowed. The receiving function uses that result and documents the precondition; it does not repeat the check
- Do not add a wrapper that only forwards an argument to a function that already exists
- Before moving or extracting a function, check what tests import and mock, and keep it reachable through the module the tests already mock
- Add a type, branch or error only for a state a caller can reach. Reuse the types callers already share
- Give each type or helper one import path. Import it from the module that owns it; do not re-export it from a second module

## Review

- **Duplicated Code**: when the diff itself edits every copy of the same logic shape, report the extraction as a fix for this change, not a follow-up.
- **Repeated Check**: a function re-validates or re-narrows an input its caller already resolved, so two places encode the same rule. → keep the check in the earlier step; the later function uses the result and documents the precondition.
