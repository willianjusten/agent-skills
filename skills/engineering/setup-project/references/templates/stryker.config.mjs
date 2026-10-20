// Optional mutation testing, off by default: verify never runs it, because a full run
// takes minutes. It mutates only the source files changed since BASE_BRANCH.
// Run it with `npx stryker run` before review, when a ticket's tests feel thin.
import { execFileSync } from "node:child_process";

// Set these from the project's tools.
const BASE_BRANCH = "main";
const TEST_RUNNER = "vitest"; // the @stryker-mutator/<runner>-runner package you installed
const SOURCE_FILE = /^src\/.*\.tsx?$/;
const TEST_FILE = /\.(test|spec)\.tsx?$/;

const changedFiles = execFileSync("git", ["diff", "--name-only", "--diff-filter=AMR", `${BASE_BRANCH}...HEAD`], {
  encoding: "utf8",
})
  .split("\n")
  .filter((filePath) => SOURCE_FILE.test(filePath) && !TEST_FILE.test(filePath));

if (changedFiles.length === 0) {
  console.log(`stryker: no source files changed since ${BASE_BRANCH}, nothing to mutate`);
  process.exit(0);
}

export default {
  testRunner: TEST_RUNNER,
  mutate: changedFiles,
  reporters: ["clear-text", "progress"],
  coverageAnalysis: "perTest",
};
