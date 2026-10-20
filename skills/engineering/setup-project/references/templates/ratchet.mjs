// Quality ratchet: collects unused code (knip), the duplication percentage (jscpd) and
// complexity warnings (the linter), and compares them with the committed .ratchet.json.
// It fails when any number got worse and rewrites the baseline when one improved, so
// legacy debt can only shrink. Commit the rewritten .ratchet.json with the change.
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

// Set these from the project's tools.
const SOURCE_DIRS = ["src"];
const LINTER = "oxlint"; // "oxlint" | "eslint"

const BASELINE_FILE = ".ratchet.json";
const COMPLEXITY_RULES = new Set(["sonarjs/cognitive-complexity", "max-params"]);
// jscpd percentages wobble in the third decimal when unrelated lines move.
const DUPLICATION_PRECISION = 100;

function runTool(toolName, toolArguments) {
  const toolResult = spawnSync(join("node_modules", ".bin", toolName), toolArguments, {
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
  if (toolResult.error) {
    throw new Error(`${toolName} did not run: ${toolResult.error.message}`);
  }
  return toolResult;
}

function parseReport(toolName, reportText) {
  try {
    return JSON.parse(reportText);
  } catch {
    throw new Error(`${toolName} did not print a JSON report:\n${reportText.slice(0, 500)}`);
  }
}

function collectUnused() {
  const knipResult = runTool("knip", ["--reporter", "json", "--no-progress"]);
  const knipReport = parseReport("knip", knipResult.stdout || knipResult.stderr);
  const findings = [];
  for (const fileIssues of knipReport.issues) {
    for (const [category, categoryFindings] of Object.entries(fileIssues)) {
      if (!Array.isArray(categoryFindings)) continue;
      for (const finding of categoryFindings) {
        findings.push(`${fileIssues.file}: ${category} ${finding.name}`);
      }
    }
  }
  return { value: findings.length, details: findings };
}

function collectDuplication() {
  const reportDir = mkdtempSync(join(tmpdir(), "ratchet-jscpd-"));
  try {
    const jscpdResult = runTool("jscpd", ["--silent", "--reporters", "json", "--output", reportDir, ...SOURCE_DIRS]);
    const reportPath = join(reportDir, "jscpd-report.json");
    if (!existsSync(reportPath)) {
      throw new Error(`jscpd wrote no report:\n${jscpdResult.stderr.slice(0, 500)}`);
    }
    const jscpdReport = parseReport("jscpd", readFileSync(reportPath, "utf8"));
    const clones = jscpdReport.duplicates.map(
      (clone) => `${clone.firstFile.name}:${clone.firstFile.start} ~ ${clone.secondFile.name}:${clone.secondFile.start}`,
    );
    const percentage = Math.round(jscpdReport.statistics.total.percentage * DUPLICATION_PRECISION) / DUPLICATION_PRECISION;
    return { value: percentage, details: clones };
  } finally {
    rmSync(reportDir, { recursive: true, force: true });
  }
}

// oxlint names rules "sonarjs(cognitive-complexity)" and core rules "eslint(max-params)";
// ESLint names them "sonarjs/cognitive-complexity" and "max-params".
function readLintWarnings() {
  if (LINTER === "oxlint") {
    const oxlintReport = parseReport("oxlint", runTool("oxlint", ["--format", "json", ...SOURCE_DIRS]).stdout);
    return oxlintReport.diagnostics.map((diagnostic) => ({
      rule: diagnostic.code.replace(/^eslint\((.*)\)$/, "$1").replace(/^(.*)\((.*)\)$/, "$1/$2"),
      location: `${diagnostic.filename}:${diagnostic.labels[0]?.span.line ?? 0}`,
    }));
  }
  const eslintReport = parseReport("eslint", runTool("eslint", ["--format", "json", ...SOURCE_DIRS]).stdout);
  return eslintReport.flatMap((fileReport) =>
    fileReport.messages.map((message) => ({ rule: message.ruleId, location: `${fileReport.filePath}:${message.line}` })),
  );
}

function collectComplexity() {
  const violations = readLintWarnings()
    .filter((warning) => COMPLEXITY_RULES.has(warning.rule))
    .map((warning) => `${warning.location} ${warning.rule}`);
  return { value: violations.length, details: violations };
}

function main() {
  const metrics = {
    unused: collectUnused(),
    duplication: collectDuplication(),
    complexity: collectComplexity(),
  };
  const baseline = existsSync(BASELINE_FILE) ? JSON.parse(readFileSync(BASELINE_FILE, "utf8")) : {};
  const nextBaseline = {};
  const regressions = [];
  const improvements = [];

  for (const [metricName, metric] of Object.entries(metrics)) {
    const baselineValue = baseline[metricName] ?? metric.value;
    nextBaseline[metricName] = Math.min(metric.value, baselineValue);
    if (metric.value > baselineValue) regressions.push(metricName);
    if (metric.value < baselineValue) improvements.push(metricName);
    console.log(`ratchet: ${metricName} ${metric.value} (baseline ${baselineValue})`);
  }

  if (regressions.length > 0) {
    for (const metricName of regressions) {
      console.error(`ratchet: ${metricName} got worse: ${baseline[metricName]} -> ${metrics[metricName].value}`);
      for (const detail of metrics[metricName].details) console.error(`  ${detail}`);
    }
    console.error(`ratchet: fix the findings above; ${BASELINE_FILE} was not changed`);
    process.exit(1);
  }

  const baselineChanged = Object.keys(metrics).some((metricName) => baseline[metricName] !== nextBaseline[metricName]);
  if (baselineChanged) {
    writeFileSync(BASELINE_FILE, `${JSON.stringify(nextBaseline, null, 2)}\n`);
    console.log(`ratchet: ${BASELINE_FILE} updated${improvements.length ? `, improved: ${improvements.join(", ")}` : ""}`);
  }
}

try {
  main();
} catch (error) {
  console.error(`ratchet: ${error.message}`);
  process.exit(1);
}
