---
name: ui-polish
description: Runs the app, screenshots every screen a change touched at phone and desktop width in each state it can reach, checks the screenshots against the repo's standards and a visual checklist, and fixes styles and markup until the change matches its design direction or the screens around it. Use when a UI change works but looks unfinished, when the user asks to polish, tidy or check the look of a page or component, to check a change on mobile, or to fix spacing, alignment, hierarchy, contrast or hover, focus and disabled states before review. Not for throwaway prototypes, which skip polish on purpose.
metadata:
  scope: both
---

# UI Polish

Tests, lint and code review can all pass on a screen nobody has looked at. This skill looks at the rendered UI, fixes what looks unfinished, and reports what still needs a human eye.

## Rules for every run

1. **Judge only what you saw.** Every finding and every fix comes from a screenshot. If no tool can capture one, stop and tell the user which tools you tried and what failed. Never review the code as if it were a screenshot: code that reads fine can render broken, and a code-only pass is the gap this skill exists to close.
2. **Styles and markup only.** Change CSS, style objects, class names, theme usage and the element structure that holds them. Never change behaviour, data, copy that carries meaning, or tests. A fix that needs one of those goes in the report instead.
3. **Two fix rounds at most.** After the second re-capture, stop and report. Polish has no natural end, and a third round tends to churn what the first two settled.
4. **Match the direction, else what is there.** When a design direction is recorded for this change (a design plan, tokens, a chosen prototype variant), the changed screen follows it even where it departs from its neighbours: a deliberate redesign is not a defect. Without one, the screens the change did not touch set the look. Either way, use the repo's theme values, spacing scale and components before adding a value.

## Workflow

Copy this checklist and tick it off:

```text
UI polish progress:
- [ ] 1 Scope: touched screens listed
- [ ] 2 Run: app answering on a local URL
- [ ] 3 Capture: every screen, state and width captured
- [ ] 4 Review: findings listed, each tied to a screenshot
- [ ] 5 Fix: style and markup changes made (round 1 or 2)
- [ ] 6 Re-capture and compare, then report
```

**Step 1. Scope.** Read the ticket or spec for this work, and look in it and in `.scratch/<feature>/` for a recorded design direction (rule 4). If the change is a throwaway prototype (a prototype route or branch, a variant switcher), stop and say so. Diff against the base the user names, or by default `git merge-base HEAD <default branch>`, and include uncommitted changes. Map each changed file to the routes that render it: a page or route file maps to itself, and a component or style file maps to the pages that import it. Pick one or two neighbouring screens the change did not touch to compare against; if every screen is new or changed, use the closest one that existed before the change, and say so in the report. Done when you have a list of routes, each with the states it can reach (start, filled, empty, loading, error, and hover, focus and disabled on its controls).

**Step 2. Run.** Start the app with the project's own dev command, found in the repo's agent docs, README, `package.json` scripts or task runner. If you cannot tell which command or port, ask the user once. Run it in the background; if its port is taken by a process you did not start, use another port and leave that process alone. Done when the first touched route renders and responds to a click: a page that answers but ignores input has not hydrated.

**Step 3. Capture.** Open [references/capture.md](references/capture.md) and use the first recipe that works with the tools in this session. Capture each route at 375px and 1280px wide, and at 768px when the styles have a breakpoint between those, in every state from Step 1, plus the neighbouring screens. Read the browser console on each route and note new errors and warnings. If `.scratch/<feature>/` exists for this work, save the files under `.scratch/<feature>/ui-polish/before/`. If no recipe works, stop under rule 1. Done when every route, state and width has a screenshot or a note saying why that state could not be reached.

**Step 4. Review.** Check the screenshots in this order, and let an earlier source win where they disagree:

1. The design direction from Step 1, if any, for how the screen should look.
2. The repo's own standards and design docs, if present (agent docs, a coding standards file, a design system or component library docs).
3. The UI section of the user's global coding standards, if the session loaded or links one.
4. [references/visual-checklist.md](references/visual-checklist.md), which also defines the severities.

Without a direction, compare each changed screen with its neighbours for type sizes, spacing, alignment and component use. Console errors are behaviour, so they go to the report, not to Step 5. Done when each finding names its severity, the route, state and width, what is wrong and the source that says so.

**Step 5. Fix.** Fix the findings under rules 2 and 4, highest severity first. A fix may land in a shared style file outside the diff when the defect shows on a touched route; the neighbouring screens must then look unchanged in Step 6. Done when every finding is fixed or moved to the report with the reason.

**Step 6. Re-capture and compare.** Capture the same set again, saving under `ui-polish/after/` when Step 3 saved files. Compare before and after for each finding, and check that nothing else moved; undo any fix that made another screen, state or width worse, and mark it undone. If a finding is still open and this was round 1, return to Step 5. Before reporting, if the session can start a subagent, give a fresh one only the after screenshots, the design direction and the checklist, and ask it to flag real gaps only, so the agent that made the fixes does not grade them; treat what it flags as round 2 findings if a round is left, otherwise report them. Then stop the dev server if you started it, run the repo's lint and tests if you touched files they cover, and report:

```text
Fixed (verified | undone): <severity> <finding> on <route, state, width>, by <change>
Needs a human eye: <severity> <finding>, because <it needs behaviour or copy changes, or is a taste call>
Console: <new errors or warnings per route, or "clean">
Not captured: <route or state>, because <reason>
Screenshots: <folder, or "not saved">
```

## Resources

- [references/capture.md](references/capture.md) - capture recipes per browser tool, from the in-session browser to a Playwright CLI fallback, how to reach each state and read the console. Open in Step 3 and Step 6.
- [references/visual-checklist.md](references/visual-checklist.md) - severities, and what to check in each screenshot: spacing, alignment, hierarchy, contrast, states, motion and copy, responsive. Open in Step 4.
