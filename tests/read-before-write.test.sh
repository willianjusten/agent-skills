#!/bin/bash
# Tests for harness/claude/hooks/read-before-write.py: builds fixture files and
# transcripts, feeds PreToolUse payloads and checks for a deny decision.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/read-before-write.py"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT
failures=0

# Every fixture file changed on disk at BASE_EPOCH; reads land before or after it.
BASE_EPOCH=$(($(date +%s) - 3600))

iso_at() {
  jq -rn --argjson epoch "$1" '$epoch | todate'
}

# write_file <name> <line count> [epoch]: a file of numbered lines, last changed at epoch.
write_file() {
  local name="$1" line_count="$2" epoch="${3:-$BASE_EPOCH}"
  mkdir -p "$(dirname "$FIXTURE_DIR/$name")"
  seq 1 "$line_count" | sed 's/^/line /' >"$FIXTURE_DIR/$name"
  touch -d "$(iso_at "$epoch")" "$FIXTURE_DIR/$name"
  echo "$FIXTURE_DIR/$name"
}

# tool_call <id> <tool name> <input json> <epoch> [result json]: one assistant
# tool_use entry and its tool_result entry, as the session transcript writes them.
tool_call() {
  local tool_id="$1" tool_name="$2" tool_input="$3" epoch="$4" tool_use_result="${5:-null}"
  jq -cn --arg id "$tool_id" --arg name "$tool_name" --argjson input "$tool_input" --arg at "$(iso_at "$epoch")" \
    '{type: "assistant", timestamp: $at, message: {role: "assistant", content: [{type: "tool_use", id: $id, name: $name, input: $input}]}}'
  jq -cn --arg id "$tool_id" --arg at "$(iso_at "$epoch")" --argjson result "$tool_use_result" \
    '{type: "user", timestamp: $at, message: {role: "user", content: [{type: "tool_result", tool_use_id: $id, content: "ok"}]}, toolUseResult: $result}'
}

# read_call <id> <path> <start line> <line count> <total lines> <epoch>
read_call() {
  local tool_id="$1" file_path="$2" start_line="$3" line_count="$4" total_lines="$5" epoch="$6"
  tool_call "$tool_id" Read "$(jq -cn --arg path "$file_path" '{file_path: $path}')" "$epoch" \
    "$(jq -cn --arg path "$file_path" --argjson start "$start_line" --argjson count "$line_count" --argjson total "$total_lines" \
      '{type: "text", file: {filePath: $path, content: "", startLine: $start, numLines: $count, totalLines: $total}}')"
}

# payload <tool name> <path> <transcript> [extra json merged into the payload]
payload() {
  local tool_name="$1" file_path="$2" transcript_path="$3" extra="${4:-}"
  [ -n "$extra" ] || extra='{}'
  jq -cn --arg name "$tool_name" --arg path "$file_path" --arg transcript "$transcript_path" --arg cwd "$FIXTURE_DIR" --argjson extra "$extra" \
    '{session_id: "fixture", transcript_path: $transcript, cwd: $cwd, scratchpad_dir: $cwd, hook_event_name: "PreToolUse",
      tool_name: $name, tool_input: {file_path: $path, old_string: "line 1\n", new_string: "changed\n"}} + $extra'
}

# expect <name> <allow|deny> <payload json> [substring...]: substrings must appear in the deny reason.
expect() {
  local name="$1" expected_decision="$2" hook_payload="$3"
  shift 3
  local output exit_code decision reason
  output=$(echo "$hook_payload" | PATH="${HOOK_PATH:-$PATH}" /usr/bin/python3 "$HOOK" 2>&1)
  exit_code=$?
  decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  reason=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty' 2>/dev/null)
  [ -n "$decision" ] || decision=allow
  if [ "$exit_code" != 0 ] || [ "$decision" != "$expected_decision" ] || { [ "$decision" = allow ] && [ -n "$output" ]; }; then
    echo "FAIL $name: exit $exit_code, decision $decision, expected $expected_decision. Output: $output"
    failures=$((failures + 1))
    return
  fi
  local expected_text
  for expected_text in "$@"; do
    if [[ "$reason" != *"$expected_text"* ]]; then
      echo "FAIL $name: reason missing '$expected_text'. Reason: $reason"
      failures=$((failures + 1))
      return
    fi
  done
  echo "ok   $name"
}

small_file=$(write_file small.txt 40)

read_call t1 "$small_file" 1 20 40 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/partial.jsonl"
expect "partial read denies" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/partial.jsonl")" "small.txt" "partial"

{
  read_call t1 "$small_file" 1 20 40 $((BASE_EPOCH + 60))
  read_call t2 "$small_file" 21 20 40 $((BASE_EPOCH + 70))
} >"$FIXTURE_DIR/full.jsonl"
expect "full read in two windows allows" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/full.jsonl")"

read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH - 60)) >"$FIXTURE_DIR/stale.jsonl"
expect "read before an external change denies" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/stale.jsonl")" "small.txt" "stale"

{
  read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH - 60))
  tool_call t2 Edit "$(jq -cn --arg path "$small_file" '{file_path: $path, old_string: "a", new_string: "b"}')" $((BASE_EPOCH - 2))
} >"$FIXTURE_DIR/own-edit.jsonl"
expect "the session's own edit keeps earlier reads" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/own-edit.jsonl")"

# The session's edit grew the file past the lines Read returned; a Read that reached
# the end of the file covers what the session appended.
grown_file=$(write_file grown.txt 42)
{
  read_call t1 "$grown_file" 1 40 40 $((BASE_EPOCH - 60))
  tool_call t2 Edit "$(jq -cn --arg path "$grown_file" '{file_path: $path, old_string: "a", new_string: "b"}')" $((BASE_EPOCH - 2))
} >"$FIXTURE_DIR/grown.jsonl"
expect "a full read still covers lines the session's edit added" allow "$(payload Edit "$grown_file" "$FIXTURE_DIR/grown.jsonl")"

tool_call t1 Write "$(jq -cn --arg path "$small_file" '{file_path: $path, content: "x"}')" $((BASE_EPOCH - 1)) >"$FIXTURE_DIR/own-write.jsonl"
expect "a file the session wrote whole allows" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/own-write.jsonl")"

: >"$FIXTURE_DIR/empty.jsonl"
expect "new file allows" allow "$(payload Write "$FIXTURE_DIR/brand-new.txt" "$FIXTURE_DIR/empty.jsonl")"

for exempt_name in yarn.lock package-lock.json pnpm-lock.yaml bun.lockb; do
  expect "lockfile $exempt_name allows" allow "$(payload Write "$(write_file "$exempt_name" 40)" "$FIXTURE_DIR/empty.jsonl")"
done

for exempt_dir in node_modules dist build .next coverage; do
  expect "path under $exempt_dir/ allows" allow "$(payload Edit "$(write_file "app/$exempt_dir/out.js" 40)" "$FIXTURE_DIR/empty.jsonl")"
done

large_file=$(write_file large.txt 5000)
large_edit=$(jq -cn --arg path "$large_file" '{tool_input: {file_path: $path, old_string: "line 3000\nline 3001\n", new_string: "changed\n"}}')
read_call t1 "$large_file" 2950 102 5000 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/large-window.jsonl"
expect "large file with a covering window allows" allow "$(payload Edit "$large_file" "$FIXTURE_DIR/large-window.jsonl" "$large_edit")"

read_call t1 "$large_file" 2960 100 5000 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/large-short.jsonl"
expect "large file with a window short of 50 lines denies" deny "$(payload Edit "$large_file" "$FIXTURE_DIR/large-short.jsonl" "$large_edit")" "large.txt" "2950-2959"

expect "large file Write needs every line" deny \
  "$(payload Write "$large_file" "$FIXTURE_DIR/large-window.jsonl" "$(jq -cn --arg path "$large_file" '{tool_input: {file_path: $path, content: "x"}}')")" "large.txt" "1-2949"

# A session that read nothing yet: one user prompt, no tool calls.
jq -cn --arg at "$(iso_at "$BASE_EPOCH")" '{type: "user", timestamp: $at, message: {role: "user", content: "fix it"}}' >"$FIXTURE_DIR/no-reads.jsonl"
expect "unread file denies" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/no-reads.jsonl")" "small.txt" "partial"

nested_repo_file=$(write_file build/repo/src/app.js 40)
expect "a project that lives under build/ is still checked" deny \
  "$(payload Edit "$nested_repo_file" "$FIXTURE_DIR/no-reads.jsonl" "$(jq -cn --arg cwd "$FIXTURE_DIR/build/repo" '{cwd: $cwd}')")" "app.js"

expect "relative path resolves against cwd" deny "$(payload Edit small.txt "$FIXTURE_DIR/no-reads.jsonl")" "small.txt"

# Real transcripts also hold api-request-blob entries: request copies with tool_use
# blocks and no timestamp. They are not conversation turns and must not break the hook.
{
  cat "$FIXTURE_DIR/no-reads.jsonl"
  jq -cn --arg path "$small_file" \
    '{type: "api-request-blob", hash: "h", sessionId: "s", message: {role: "assistant", content: [{type: "tool_use", id: "t9", name: "Read", input: {file_path: $path}}]}}'
} >"$FIXTURE_DIR/with-blob.jsonl"
expect "request blobs neither break the hook nor count as reads" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/with-blob.jsonl")" "small.txt"

printf 'not json {{\n\x00\x01garbage\n' >"$FIXTURE_DIR/corrupt.jsonl"
expect "corrupt transcript allows" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/corrupt.jsonl")"
echo '{"some": "other format"}' >"$FIXTURE_DIR/unknown.jsonl"
expect "unknown transcript format allows" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/unknown.jsonl")"
expect "missing transcript allows" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/missing.jsonl")"

tool_call t1 Read "$(jq -cn --arg path "$small_file" '{file_path: $path}')" $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/input-only.jsonl"
expect "a Read without a recorded range counts its input" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/input-only.jsonl")"

read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH + 60)) | jq -c 'if .type == "user" then .message.content[0].is_error = true else . end' >"$FIXTURE_DIR/failed-read.jsonl"
expect "a failed Read does not count" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/failed-read.jsonl")" "small.txt"

# A subagent writes its own transcript at <session>/subagents/agent-<agent_id>.jsonl,
# and only knows what it read there.
mkdir -p "$FIXTURE_DIR/session/subagents"
cp "$FIXTURE_DIR/no-reads.jsonl" "$FIXTURE_DIR/session.jsonl"
read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/session/subagents/agent-reader.jsonl"
cp "$FIXTURE_DIR/no-reads.jsonl" "$FIXTURE_DIR/session/subagents/agent-skimmer.jsonl"
expect "subagent that read the file allows" allow \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/session.jsonl" '{"agent_id": "reader", "agent_type": "implementer"}')"
expect "subagent that did not read the file denies" deny \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/session.jsonl" '{"agent_id": "skimmer", "agent_type": "implementer"}')" "small.txt"
expect "subagent payload already pointing at its own transcript works" allow \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/session/subagents/agent-reader.jsonl" '{"agent_id": "reader"}')"
expect "main session does not borrow a subagent's reads" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/session.jsonl")" "small.txt"
expect "subagent without a transcript allows" allow \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/session.jsonl" '{"agent_id": "ghost"}')"

notebook_file=$(write_file analysis.ipynb 3000)
notebook_edit=$(jq -cn --arg path "$notebook_file" '{tool_input: {notebook_path: $path, new_source: "x"}}')
tool_call t1 Read "$(jq -cn --arg path "$notebook_file" '{file_path: $path}')" $((BASE_EPOCH + 60)) \
  "$(jq -cn --arg path "$notebook_file" '{type: "notebook", file: {filePath: $path, cells: []}}')" >"$FIXTURE_DIR/notebook.jsonl"
expect "notebook read whole allows NotebookEdit" allow "$(payload NotebookEdit "$notebook_file" "$FIXTURE_DIR/notebook.jsonl" "$notebook_edit")"
expect "unread notebook denies NotebookEdit" deny "$(payload NotebookEdit "$notebook_file" "$FIXTURE_DIR/no-reads.jsonl" "$notebook_edit")" "analysis.ipynb"

tool_call t1 Read "$(jq -cn --arg path "$notebook_file" '{file_path: $path}')" $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/notebook-untyped.jsonl"
expect "notebook Read without a recorded type still covers it" allow \
  "$(payload NotebookEdit "$notebook_file" "$FIXTURE_DIR/notebook-untyped.jsonl" "$notebook_edit")"

{
  cat "$FIXTURE_DIR/no-reads.jsonl"
  jq -cn --arg path "$small_file" '{type: "assistant", message: {role: "assistant", content: [{type: "tool_use", id: "t9", name: "Read", input: {file_path: $path}}]}}'
} >"$FIXTURE_DIR/untimed-turn.jsonl"
expect "a turn without a timestamp is skipped, not fatal" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/untimed-turn.jsonl")" "small.txt"

# Read counts only \n as a line break; a form feed or \r inside a line is not one.
printf 'one\fstill one\ntwo\rstill two\n' >"$FIXTURE_DIR/control-chars.txt"
touch -d "$(iso_at "$BASE_EPOCH")" "$FIXTURE_DIR/control-chars.txt"
read_call t1 "$FIXTURE_DIR/control-chars.txt" 1 2 2 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/control-chars.jsonl"
expect "lines count only newlines, like Read" allow "$(payload Edit "$FIXTURE_DIR/control-chars.txt" "$FIXTURE_DIR/control-chars.jsonl")"

expect "large file Edit whose old_string is not found allows" allow \
  "$(payload Edit "$large_file" "$FIXTURE_DIR/large-window.jsonl" "$(jq -cn --arg path "$large_file" '{tool_input: {file_path: $path, old_string: "no such text", new_string: "x"}}')")"

expect "large file replace_all needs every line" deny \
  "$(payload Edit "$large_file" "$FIXTURE_DIR/large-window.jsonl" "$(jq -cn --arg path "$large_file" '{tool_input: {file_path: $path, old_string: "line 3000\n", new_string: "x", replace_all: true}}')")" "large.txt"

{
  read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH - 60))
  read_call t2 "$small_file" 1 10 40 $((BASE_EPOCH + 60))
} >"$FIXTURE_DIR/stale-and-partial.jsonl"
expect "a stale full read plus a fresh partial one says stale" deny "$(payload Edit "$small_file" "$FIXTURE_DIR/stale-and-partial.jsonl")" "small.txt" "stale"

# Parallel calls: an earlier Edit of the same file may have run with its result not yet
# in the transcript. It is the session's change, so earlier reads still count.
{
  read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH - 60))
  tool_call t2 Edit "$(jq -cn --arg path "$small_file" '{file_path: $path, old_string: "a", new_string: "b"}')" $((BASE_EPOCH - 30)) | head -1
} >"$FIXTURE_DIR/in-flight-edit.jsonl"
expect "an in-flight session edit keeps earlier reads" allow "$(payload Edit "$small_file" "$FIXTURE_DIR/in-flight-edit.jsonl")"

# Parallel calls where the transcript lags: the first Edit's tool_use is not written yet
# when the second Edit is judged. The hook's own record of allowing the first one covers it.
lagging_file=$(write_file lagging.txt 40)
read_call t1 "$lagging_file" 1 40 40 $((BASE_EPOCH + 60)) >"$FIXTURE_DIR/lagging.jsonl"
expect "first of two parallel edits allows" allow "$(payload Edit "$lagging_file" "$FIXTURE_DIR/lagging.jsonl")"
touch "$lagging_file"
expect "second parallel edit allows while the transcript lags" allow "$(payload Edit "$lagging_file" "$FIXTURE_DIR/lagging.jsonl")"
expect "another session gets no credit for that record" deny \
  "$(payload Edit "$lagging_file" "$FIXTURE_DIR/lagging.jsonl" '{"session_id": "other"}')" "lagging.txt" "stale"

# The call being judged is in the transcript too; it must not vouch for itself.
{
  read_call t1 "$small_file" 1 40 40 $((BASE_EPOCH - 60))
  tool_call current Edit "$(jq -cn --arg path "$small_file" '{file_path: $path, old_string: "a", new_string: "b"}')" $((BASE_EPOCH + 30)) | head -1
} >"$FIXTURE_DIR/self.jsonl"
expect "the call being judged does not count as a session write" deny \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/self.jsonl" '{"tool_use_id": "current"}')" "small.txt" "stale"

# The hook must not reach for node or a PATH python: both fail here.
fake_bin="$FIXTURE_DIR/fake-bin"
mkdir -p "$fake_bin"
for fake_tool in node python3; do
  printf '#!/bin/sh\nexit 1\n' >"$fake_bin/$fake_tool"
  chmod +x "$fake_bin/$fake_tool"
done
HOOK_PATH="$fake_bin" expect "runs with a broken node and python3 on PATH" deny \
  "$(payload Edit "$small_file" "$FIXTURE_DIR/partial.jsonl")" "small.txt" "partial"

output=$(echo 'not json' | /usr/bin/python3 "$HOOK" 2>&1)
exit_code=$?
if [ "$exit_code" = 0 ] && [ -z "$output" ]; then
  echo "ok   junk payload allows silently"
else
  echo "FAIL junk payload allows silently: exit $exit_code, output: $output"
  failures=$((failures + 1))
fi

expect "other tools pass through" allow "$(payload Read "$small_file" "$FIXTURE_DIR/no-reads.jsonl")"

[ "$failures" -eq 0 ] || exit 1
