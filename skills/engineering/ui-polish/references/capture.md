# Capture recipes

Use the first recipe whose tools this session has. Try each recipe once before moving to the next; if none works, go to "When nothing works".

## Contents
- Widths and file names
- Reaching each state
- Recipe 1: a browser extension in the session (Claude in Chrome)
- Recipe 2: a Playwright MCP server
- Recipe 3: Playwright CLI
- When nothing works

## Widths and file names

Capture at a 375px and a 1280px viewport, plus 768px when SKILL.md Step 3 calls for it. Window width is not viewport width: after resizing, check `window.innerWidth` and adjust until it matches, or the phone capture may be a tablet one.

Capture the full page, not only the first screen, when the content scrolls; a broken footer or last row is still part of the change.

Name saved files `<route>-<state>-<width>.png`, for example `quiz-error-375.png`, with `/` in the route replaced by `-` and `home` for `/`. The same names in `before/` and `after/` make the comparison one-to-one; on a re-run, overwrite files of the same name.

## Reaching each state

| State | How to reach it |
|---|---|
| start | Load the route fresh |
| filled | Type realistic values, including one long value that could wrap or overflow |
| empty | Use a route, query or seed that returns no items; if none exists, note it as not reachable |
| loading | Throttle the network or block the data request in the browser tool; if it is too quick to see, note it as not reachable |
| error | Submit invalid input, or block or fail the data request |
| hover | Move the pointer over the control |
| focus | Press Tab until the control is focused, so the keyboard focus style shows, not the click one |
| disabled | Reach the condition that disables the control through the UI |

When a state needs something the page hides, such as a correct answer or a valid code, read it from the app's data, fixtures or seed files. Reach states through the UI and the browser tool, never by editing the app's code: a temporary code change is a behaviour change, and it can leak into the fix.

## Recipe 1: a browser extension in the session (Claude in Chrome)

1. Call `claude-in-chrome:tabs_context_mcp`, then `claude-in-chrome:tabs_create_mcp` to open a tab for this run.
2. Call `claude-in-chrome:resize_window`, then read `window.innerWidth` with `claude-in-chrome:javascript_tool` and adjust the width until it reads 375 (then 1280).
3. `claude-in-chrome:navigate` to the route, wait for it to settle, and take a `screenshot` with `claude-in-chrome:computer`. Check that the page is this app: the extension's browser can run on another machine, where `localhost` is a different host. If it is not this app, or the viewport width cannot be matched, move to the next recipe. Scroll and take more when the page is longer than the viewport.
4. Reach each state with `claude-in-chrome:computer` actions: `left_click`, `type`, `hover`, and `key` with `Tab`. Locate controls with `claude-in-chrome:find` or `claude-in-chrome:read_page` instead of guessing coordinates.
5. To save a file, take the screenshot with `save_to_disk` on and copy the returned path into the `before/` or `after/` folder under the name above.
6. Read the console with `claude-in-chrome:read_console_messages` on each route, filtered to errors and warnings.
7. Close the tab with `claude-in-chrome:tabs_close_mcp` when done.

## Recipe 2: a Playwright MCP server

1. `playwright:browser_resize` to 375 by 812 (then 1280 by 800).
2. `playwright:browser_navigate` to the route and wait for it to settle.
3. Reach each state with `playwright:browser_hover`, `playwright:browser_click`, `playwright:browser_type` and `playwright:browser_press_key` (`Tab` for focus).
4. `playwright:browser_take_screenshot` with `fullPage` on and a `filename` in the `before/` or `after/` folder.
5. `playwright:browser_console_messages` on each route for errors and warnings.

## Recipe 3: Playwright CLI

Works for any state reachable by URL alone. Needs Node. If Playwright or its browser is missing, ask the user before installing it (in a temporary folder outside the repo) and running `npx playwright install chromium`, because both download code; if they decline, go to "When nothing works".

```bash
npx playwright screenshot --viewport-size=375,812 --full-page <url> <folder>/<route>-start-375.png
npx playwright screenshot --viewport-size=1280,800 --full-page <url> <folder>/<route>-start-1280.png
```

For hover, focus, filled and error states, write a short script outside the repo (in a temporary folder) that uses `page.hover`, `page.keyboard.press('Tab')`, `page.fill` and `page.screenshot({ fullPage: true })`, logs `page.on('console')` errors and warnings, and run it with Node. Then read each saved file to look at it.

## When nothing works

Stop and tell the user:

```text
Could not capture the UI, so nothing was reviewed or changed.
Tried: <recipe>: <error or missing tool>, for each one
To unblock: <connect the browser extension, add a Playwright MCP server, or install Playwright>
```
