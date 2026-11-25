# Profile: site

Used when the adapter's `profile` is `site`: a page or a set of pages in an existing web app, looked at by visitors. No game rules apply, and the repo's own conventions (its `CLAUDE.md` or `AGENTS.md`, design docs) win over taste.

## Each direction

- Shoot every page, state and width the direction touches, from the adapter's `shot`; the brief's done condition names the widths and states (times of day, open cards, phone and desktop).
- When a direction adds something a visitor sees, name in its cycle line the page or state it lives on and what it moved or removed to make room.
- Sound only when the brief asks for it, and it never plays before the visitor's first input.

## Review cycle

Check the fresh shots against the brief's pillars, Not this list and done condition, in that order, then name the three weakest things a first-time visitor would notice and one thing to remove or simplify (a section, label, effect or control that costs more attention than it gives). Run the UI pass ([ui-pass.md](ui-pass.md)) at every width the brief names, holding each screen to the repo's own UI rules. With `--slow-checks`, run `checkSlow` in every review cycle; without it, leave it to the user.

## Hand-off

The summary's **Play it** section becomes **Open it**: the start URL and one link per state worth checking, from the brief's demo mode and the app's URL parameters, each on the network address and on `localhost`. No **Controls** section unless the page takes keys beyond the browser's own. The run-article frame is one URL at one viewport, logged as `Frame: <url>, <width>x<height>`.
