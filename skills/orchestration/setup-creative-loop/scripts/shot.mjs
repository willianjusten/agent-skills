// Screenshots every page at every size for /creative-loop, and prints one image path per line.
// Usage: node shot.mjs --url <base> [--pages "<p1>,<p2>"] [--sizes 1440x900,390x844]
//        [--ready "<css selector>"] [--wait <ms>] [--out <folder>]
// A page starting with "?" or "#" is appended to --url; any other is resolved against it.
// Exits 1 when a page throws, logs a console error, or never shows the --ready selector.
// Playwright is loaded from the repo the command runs in.
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const PHONE_MAX_WIDTH = 600; // below this a viewport is shot as a touch phone
const READY_TIMEOUT_MS = 30000;

function readOptions(argv) {
  const options = { pages: "", sizes: "1440x900,390x844", ready: "", wait: "1500", out: ".loop/shots" };
  for (let index = 0; index < argv.length; index += 2) {
    const name = argv[index].replace(/^--/, "");
    if (!(name in options) && name !== "url") throw new Error(`unknown option ${argv[index]}`);
    options[name] = argv[index + 1] ?? "";
  }
  if (!options.url) throw new Error("--url is required");
  return options;
}

export function pageUrl(base, page) {
  if (!page) return base;
  if (page.startsWith("?") || page.startsWith("#")) return base + page;
  return new URL(page, base).toString();
}

export function fileSlug(page) {
  return (page || "start").replace(/[^a-zA-Z0-9]+/g, "-").replace(/^-|-$/g, "") || "start";
}

async function main() {
  const { chromium } = createRequire(join(process.cwd(), "package.json"))("playwright");
  const options = readOptions(process.argv.slice(2));
  const pages = options.pages.split(",").map((page) => page.trim());
  const sizes = options.sizes.split(",").map((size) => size.split("x").map(Number));
  mkdirSync(options.out, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const failures = [];
  for (const page of pages) {
    for (const [width, height] of sizes) {
      const isPhone = width < PHONE_MAX_WIDTH;
      const context = await browser.newContext({ viewport: { width, height }, deviceScaleFactor: 1, isMobile: isPhone, hasTouch: isPhone });
      const tab = await context.newPage();
      const problems = [];
      tab.on("pageerror", (error) => problems.push(String(error)));
      tab.on("console", (message) => message.type() === "error" && problems.push(message.text()));
      await tab.goto(pageUrl(options.url, page));
      if (options.ready) {
        await tab.waitForSelector(options.ready, { timeout: READY_TIMEOUT_MS }).catch(() => problems.push(`never ready: ${options.ready}`));
      }
      await tab.waitForTimeout(Number(options.wait));
      const file = join(options.out, `${fileSlug(page)}-${width}x${height}.png`);
      await tab.screenshot({ path: file });
      console.log(file);
      for (const problem of problems.slice(0, 5)) failures.push(`${file}: ${problem}`);
      await context.close();
    }
  }
  await browser.close();
  for (const failure of failures) console.log(`FAIL ${failure}`);
  process.exit(failures.length ? 1 : 0);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(String(error));
    process.exit(1);
  });
}
