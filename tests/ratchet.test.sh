#!/bin/bash
# Tests for setup-project's ratchet.mjs template: it fails when a metric gets worse,
# names the metric, and rewrites .ratchet.json only when nothing got worse.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
RATCHET_SCRIPT="$REPO_ROOT/skills/engineering/setup-project/references/templates/ratchet.mjs"
FIXTURE_DIR=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$FIXTURE_DIR"' EXIT
failures=0

# expect <name> <expected> <actual>
expect() {
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected '$2', got '$3'"
    failures=$((failures + 1))
  fi
}

# expect_contains <name> <needle> <haystack>
expect_contains() {
  case "$3" in
    *"$2"*) echo "ok   $1" ;;
    *)
      echo "FAIL $1: expected output to contain '$2', got '$3'"
      failures=$((failures + 1))
      ;;
  esac
}

# The tools are stubbed in node_modules/.bin so the test needs no network; each stub
# prints the canned report the current case wrote into tool-output/.
project_dir="$FIXTURE_DIR/app"
tool_output="$FIXTURE_DIR/tool-output"
mkdir -p "$project_dir/scripts" "$project_dir/node_modules/.bin" "$tool_output"
cp "$RATCHET_SCRIPT" "$project_dir/scripts/ratchet.mjs"

printf '#!/bin/bash\ncat "%s/knip.json"\nexit 1\n' "$tool_output" >"$project_dir/node_modules/.bin/knip"
printf '#!/bin/bash\ncat "%s/oxlint.json"\n' "$tool_output" >"$project_dir/node_modules/.bin/oxlint"
printf '#!/bin/bash\ncat "%s/eslint.json"\nexit 1\n' "$tool_output" >"$project_dir/node_modules/.bin/eslint"
cat >"$project_dir/node_modules/.bin/jscpd" <<EOF
#!/bin/bash
while [ \$# -gt 0 ]; do
  if [ "\$1" = "--output" ]; then report_dir="\$2"; fi
  shift
done
cp "$tool_output/jscpd.json" "\$report_dir/jscpd-report.json"
EOF
chmod +x "$project_dir"/node_modules/.bin/*

# set_tools <unused exports> <duplication percentage> <complexity warnings>
set_tools() {
  local unused_exports="" index
  local complexity_diagnostics='{"code":"eslint(max-params)","filename":"src/b.ts","labels":[]}'
  for ((index = 1; index <= $1; index++)); do
    unused_exports+="${unused_exports:+,}{\"name\":\"unused$index\",\"line\":$index,\"col\":1,\"pos\":0}"
  done
  printf '{"issues":[{"file":"src/a.ts","dependencies":[],"exports":[%s],"files":[],"types":[]}]}' \
    "$unused_exports" >"$tool_output/knip.json"
  printf '{"duplicates":[],"statistics":{"total":{"clones":0,"percentage":%s}}}' "$2" >"$tool_output/jscpd.json"
  for ((index = 1; index <= $3; index++)); do
    complexity_diagnostics+=",{\"code\":\"sonarjs(cognitive-complexity)\",\"filename\":\"src/a.ts\",\"labels\":[{\"span\":{\"line\":$index}}]}"
  done
  printf '{"diagnostics":[%s,{"code":"eslint(no-unused-vars)","filename":"src/a.ts","labels":[]}]}' \
    "$complexity_diagnostics" >"$tool_output/oxlint.json"
}

run_ratchet() {
  ratchet_output=$(cd "$project_dir" && node scripts/ratchet.mjs 2>&1)
  ratchet_status=$?
}

baseline() {
  node -e 'const b = require(process.argv[1]); console.log(`${b.unused} ${b.duplication} ${b.complexity}`)' \
    "$project_dir/.ratchet.json"
}

# One max-params warning is always present, so complexity counts start at 1.
set_tools 2 1.5 0
run_ratchet
expect "first run passes" "0" "$ratchet_status"
expect "first run writes the baseline" "2 1.5 1" "$(baseline)"

run_ratchet
expect "an unchanged run passes" "0" "$ratchet_status"
expect "an unchanged run keeps the baseline" "2 1.5 1" "$(baseline)"

set_tools 3 1.5 0
run_ratchet
expect "a new unused export fails" "1" "$ratchet_status"
expect_contains "the failure names the unused metric" "unused" "$ratchet_output"
expect_contains "the failure lists the new finding" "unused3" "$ratchet_output"
expect "a failing run keeps the baseline" "2 1.5 1" "$(baseline)"

set_tools 2 2.25 0
run_ratchet
expect "more duplication fails" "1" "$ratchet_status"
expect_contains "the failure names the duplication metric" "duplication" "$ratchet_output"

set_tools 2 1.5 2
run_ratchet
expect "more complexity warnings fail" "1" "$ratchet_status"
expect_contains "the failure names the complexity metric" "complexity" "$ratchet_output"

set_tools 1 1.5 2
run_ratchet
expect "one better and one worse still fails" "1" "$ratchet_status"
expect "a mixed run keeps the baseline" "2 1.5 1" "$(baseline)"

set_tools 1 0.75 0
run_ratchet
expect "an improvement passes" "0" "$ratchet_status"
expect "an improvement lowers the baseline" "1 0.75 1" "$(baseline)"

set_tools 1 0.754 0
run_ratchet
expect "duplication noise below 0.01 points passes" "0" "$ratchet_status"

# ESLint reports complexity as ruleId per message instead of oxlint's code.
sed -i.bak 's/^const LINTER = "oxlint"/const LINTER = "eslint"/' "$project_dir/scripts/ratchet.mjs"
printf '[{"filePath":"src/a.ts","messages":[{"ruleId":"max-params","line":1},{"ruleId":"sonarjs/cognitive-complexity","line":9},{"ruleId":"no-console","line":3}]}]' \
  >"$tool_output/eslint.json"
run_ratchet
expect "eslint complexity warnings are counted" "1" "$ratchet_status"
expect_contains "eslint failure names the complexity metric" "complexity" "$ratchet_output"

printf 'not json' >"$tool_output/knip.json"
run_ratchet
expect "an unreadable tool report fails" "1" "$ratchet_status"
expect_contains "the failure names the tool" "knip" "$ratchet_output"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
