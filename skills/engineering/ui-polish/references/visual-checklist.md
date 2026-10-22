# Visual checklist

The last source in SKILL.md Step 4. Measure in the screenshot where you can; "looks a bit tight" is a taste call, "8px here, 24px on every sibling card" is a finding. If the repo already runs axe or a similar accessibility check, run it on the touched routes too.

## Contents
- Severity
- Spacing
- Alignment
- Hierarchy
- Contrast
- States
- Motion and copy
- Responsive
- Consistency with neighbouring screens

## Severity

| Severity | Meaning | Example |
|---|---|---|
| Blocker | Content or a control cannot be seen, read or reached | clipped content, horizontal scroll, no visible focus |
| High | Breaks the design direction or a written standard | off-scale spacing, a missing state, contrast under the threshold |
| Medium | Inconsistent with the neighbouring screens | a different heading size or page padding |
| Nit | A taste call | a slightly heavier weight would read better |

Fix in severity order. Nits go to the report when the two rounds run out.

## Spacing

- Content never touches a container or viewport edge.
- Gaps come from the repo's spacing scale; one-off values next to the scale are findings.
- Related items sit closer to each other than to unrelated ones, so groups read as groups.
- Vertical rhythm is even: the same kind of block gets the same space above and below it.
- Controls in a row have equal gaps; buttons that stack on a phone have space between them.

## Alignment

- Items share left edges (or centres) with the content around them; nothing is a few pixels off.
- Text baselines in a row line up, including icons next to text.
- Grids keep their columns; a long value does not push one cell wider than the rest.

## Hierarchy

- One element per screen is clearly the most important, usually the heading or the primary action.
- Heading sizes step down in order; no level is skipped or reversed.
- There is one primary button per group; secondary actions look secondary.
- Type sizes and weights come from the repo's type scale.

## Contrast

- Body text and placeholders are readable against their background (WCAG AA: 4.5:1 for body text, 3:1 for large text and control borders).
- Text on images or colour fills stays readable at both widths.
- Status is never shown by colour alone; an error has text or an icon too.
- Hover and active states are at least as visible as the rest state, not fainter.

## States

- Every interactive element shows hover, keyboard focus and disabled states, and each is visibly different from the rest state. The keyboard focus ring is visible and not hidden behind other elements.
- Disabled controls look inactive, not only refuse the click.
- Selected, correct, wrong and active states differ by more than a slight tint.
- Empty, loading and error states exist for every view that shows remote or computed data, and they look designed, not like a blank area.
- Changing state does not shift the layout under the pointer unless the change is the point; a loading placeholder takes the same space as the content it stands in for.

## Motion and copy

- Motion answers a user action or draws attention once; decorative motion on every element is a finding, and the page respects reduced-motion settings.
- On new UI, generic defaults that do not fit the product (identical rounded cards for everything, an all-caps label over every heading, gradient washes as decoration) are Nits.
- Button labels that do not say what happens, and errors that do not say what went wrong and how to fix it, go to the report: copy is outside rule 2.

## Responsive

- No horizontal scroll at 375px; nothing is cut off or overlapping.
- Widths are flexible; fixed pixel widths on content are findings.
- Tap targets on a phone are at least 44 by 44px.
- Text inputs use at least 16px text on a phone, so the browser does not zoom in on focus.
- Long words, names and numbers wrap or truncate on purpose instead of breaking the layout.
- At 1280px, content has a sensible maximum width and does not stretch lines past easy reading.

## Consistency with neighbouring screens

Skip what a recorded design direction deliberately changes.

- The changed screen uses the same components as its neighbours for the same job (buttons, cards, links, headings).
- Page padding, heading position and back or navigation links sit where they do on neighbouring screens.
- Colours, radii, shadows and icon styles come from what the neighbours already use.
