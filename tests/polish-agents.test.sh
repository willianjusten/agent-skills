#!/bin/bash
# Tests for the polish orchestration agents: the director coordinates on fable,
# the parameterized worker builds on opus, the model lives in each frontmatter,
# neither reaches Spoke, and the worker is bound by the write-scope hook with no
# tool that could write around it.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
AGENTS="$REPO_ROOT/agents/realtime"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

frontmatter() { awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1"; }
field() { frontmatter "$1" | awk -v key="$2" -F': *' '$1 == key { print $2; exit }'; }
scope_of() { frontmatter "$1" | awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }'; }

expected_model() {
  case "$1" in
    polish-director) echo fable ;;
    polish-worker) echo opus ;;
  esac
}

for agent in polish-director polish-worker; do
  file="$AGENTS/$agent.md"
  if [ ! -f "$file" ]; then
    fail "$agent exists under agents/realtime"
    continue
  fi
  pass "$agent exists under agents/realtime"

  [ "$(field "$file" name)" = "$agent" ] && pass "$agent name equals its file name" || fail "$agent name equals its file name"
  [ "$(field "$file" model)" = "$(expected_model "$agent")" ] && pass "$agent runs on $(expected_model "$agent")" || fail "$agent runs on $(expected_model "$agent")" "found '$(field "$file" model)'"
  [ "$(scope_of "$file")" = "personal" ] && pass "$agent is scoped personal, so Spoke never gets it" || fail "$agent is scoped personal" "found '$(scope_of "$file")'"
  field "$file" description | grep -q "^Use when\|Use when" && pass "$agent description says when to use it" || fail "$agent description says when to use it"

  tools=$(field "$file" tools)
  if [ -n "$tools" ] && ! echo "$tools" | grep -qi "spoke"; then
    pass "$agent has an explicit tool list with no Spoke tool"
  else
    fail "$agent has an explicit tool list with no Spoke tool" "tools: '$tools'"
  fi
  if grep -rEn '/Users/[a-z]|/home/[a-z]' "$file" >/dev/null; then
    fail "$agent has no machine paths"
  else
    pass "$agent has no machine paths"
  fi
done

director="$AGENTS/polish-director.md"
worker="$AGENTS/polish-worker.md"

field "$director" tools | grep -qw Agent && pass "the director can spawn workers and judges" || fail "the director can spawn workers and judges"

worker_tools=$(field "$worker" tools)
if echo "$worker_tools" | grep -qwE 'Bash|Agent'; then
  fail "the worker has no Bash or Agent tool, so it cannot write around the hook" "tools: $worker_tools"
else
  pass "the worker has no Bash or Agent tool, so it cannot write around the hook"
fi

if frontmatter "$worker" | grep -q 'hooks/write-scope.sh' && frontmatter "$worker" | grep -q 'PreToolUse'; then
  pass "the worker declares the write-scope hook as PreToolUse"
else
  fail "the worker declares the write-scope hook as PreToolUse"
fi
if frontmatter "$worker" | grep -F 'write-scope.sh' | grep -qF '|| exit 2'; then
  pass "the hook command turns any failure, such as a missing script, into a block"
else
  fail "the hook command turns any failure, such as a missing script, into a block"
fi
for write_tool in Write Edit MultiEdit; do
  frontmatter "$worker" | grep -E 'matcher:' | grep -qw "$write_tool" && pass "the hook matcher covers $write_tool" || fail "the hook matcher covers $write_tool"
done

grep -q "polish-scope.json" "$director" && pass "the director writes the scope file" || fail "the director writes the scope file"
grep -q "visual-judge" "$director" && grep -q "feel-judge" "$director" && pass "the director calls both judges" || fail "the director calls both judges"
grep -qi "review packet" "$director" && pass "the director ends the round with a review packet" || fail "the director ends the round with a review packet"

grep -q "component checklist" "$director" && grep -q "COMPONENTS.md" "$director" && pass "the director accepts a component checklist" || fail "the director accepts a component checklist"
grep -q "measurable target" "$director" && grep -q "judge lens" "$director" && grep -qF 'folder it owns' "$director" && pass "a checklist row carries a target, a folder and a judge lens" || fail "a checklist row carries a target, a folder and a judge lens"
grep -q "only when no checklist is given" "$director" && pass "the fixed areas are the fallback without a checklist" || fail "the fixed areas are the fallback without a checklist"
grep -q "motion-judge" "$director" && grep -q "lens its row names" "$director" && pass "the judge follows the component's lens" || fail "the judge follows the component's lens"
grep -q "component" "$worker" && pass "the worker accepts a component" || fail "the worker accepts a component"
grep -q "process setting" "$director" && grep -q '`minimal`: one judge lens per moment' "$director" && grep -q '`full`: as standard, plus `motion-judge`' "$director" && pass "the director describes what each process setting changes" || fail "the director describes what each process setting changes"

[ "$failures" -eq 0 ] || exit 1
