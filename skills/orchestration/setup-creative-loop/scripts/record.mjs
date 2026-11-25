// Records a tour of the pages for /creative-loop hand-off: one video and one contact sheet.
// Usage: node record.mjs --url <base> [--pages "<p1>,<p2>"] [--size 1440x900]
//        [--ready "<css selector>"] [--dwell <ms per page>] [--out <folder>]
// Prints the video path (play.mp4 when ffmpeg is on PATH, else play.webm) and the contact sheet
// path (play-contact-sheet.png when ImageMagick montage is on PATH, else the frame folder).
// Playwright is loaded from the repo the command runs in.
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { mkdirSync, readdirSync, renameSync, rmSync } from "node:fs";
import { join } from "node:path";
import { fileSlug, pageUrl } from "./shot.mjs";

const READY_TIMEOUT_MS = 30000;
const CONTACT_SHEET_COLUMNS = 4;

function readOptions(argv) {
  const options = { pages: "", size: "1440x900", ready: "", dwell: "4000", out: ".loop/record" };
  for (let index = 0; index < argv.length; index += 2) {
    const name = argv[index].replace(/^--/, "");
    if (!(name in options) && name !== "url") throw new Error(`unknown option ${argv[index]}`);
    options[name] = argv[index + 1] ?? "";
  }
  if (!options.url) throw new Error("--url is required");
  return options;
}

function onPath(command) {
  try {
    execFileSync("which", [command], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

async function main() {
  const { chromium } = createRequire(join(process.cwd(), "package.json"))("playwright");
  const options = readOptions(process.argv.slice(2));
  const [width, height] = options.size.split("x").map(Number);
  const framesFolder = join(options.out, "frames");
  const rawFolder = join(options.out, "raw");
  rmSync(options.out, { recursive: true, force: true });
  mkdirSync(framesFolder, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width, height }, recordVideo: { dir: rawFolder, size: { width, height } } });
  const tab = await context.newPage();
  const pages = options.pages.split(",").map((page) => page.trim());
  for (const [index, page] of pages.entries()) {
    await tab.goto(pageUrl(options.url, page));
    if (options.ready) await tab.waitForSelector(options.ready, { timeout: READY_TIMEOUT_MS }).catch(() => {});
    await tab.waitForTimeout(Number(options.dwell));
    await tab.screenshot({ path: join(framesFolder, `${String(index + 1).padStart(2, "0")}-${fileSlug(page)}.png`) });
  }
  await context.close();
  await browser.close();

  const rawVideo = join(rawFolder, readdirSync(rawFolder).find((name) => name.endsWith(".webm")));
  let video = join(options.out, "play.webm");
  if (onPath("ffmpeg")) {
    video = join(options.out, "play.mp4");
    execFileSync("ffmpeg", ["-y", "-loglevel", "error", "-i", rawVideo, "-pix_fmt", "yuv420p", video]);
  } else {
    renameSync(rawVideo, video);
  }
  rmSync(rawFolder, { recursive: true, force: true });
  console.log(video);

  if (onPath("montage")) {
    const sheet = join(options.out, "play-contact-sheet.png");
    const frames = readdirSync(framesFolder).sort().map((name) => join(framesFolder, name));
    execFileSync("montage", [...frames, "-tile", `${Math.min(CONTACT_SHEET_COLUMNS, frames.length)}x`, "-geometry", "480x+4+4", sheet]);
    console.log(sheet);
  } else {
    console.log(framesFolder);
  }
}

main().catch((error) => {
  console.error(String(error));
  process.exit(1);
});
