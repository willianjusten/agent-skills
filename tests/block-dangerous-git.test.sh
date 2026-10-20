#!/bin/bash
# Tests for the push policy in harness/claude/hooks/block-dangerous-git.sh: feeds
# PreToolUse payloads from throwaway repos and transcripts and checks block or allow.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$REPO_ROOT/harness/claude/hooks/block-dangerous-git.sh"
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
failures=0

# make_repo <name> [push policy]: a repo on branch feature. Prints the repo path.
make_repo() {
  local repo_dir="$WORK_DIR/$1" push_policy="$2"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -q -b feature
  if [ -n "$push_policy" ]; then
    mkdir -p "$repo_dir/.claude"
    echo "{\"push\": \"$push_policy\"}" >"$repo_dir/.claude/afk.json"
  fi
  echo "$repo_dir"
}

# make_transcript <name> <latest prompt>: an older push request, the latest prompt,
# then a tool result and an injected meta entry that must both be skipped.
make_transcript() {
  local transcript_path="$WORK_DIR/$1.jsonl"
  {
    jq -cn '{type: "user", message: {content: "push it and open the PR"}}'
    jq -cn '{type: "assistant", message: {content: [{type: "text", text: "Done."}]}}'
    jq -cn --arg prompt "$2" '{type: "user", message: {content: [{type: "text", text: $prompt}]}}'
    jq -cn '{type: "user", message: {content: [{type: "tool_result", content: "please push"}]}}'
    jq -cn '{type: "user", isMeta: true, message: {content: "Pushes follow afk.json"}}'
  } >"$transcript_path"
  echo "$transcript_path"
}

# expect <name> <repo> <transcript> <command> <block|allow>
expect() {
  local name="$1" repo_dir="$2" transcript_path="$3" command="$4" expected="$5" actual=allow
  jq -n --arg cwd "$repo_dir" --arg transcript "$transcript_path" --arg command "$command" \
    '{cwd: $cwd, transcript_path: $transcript, tool_input: {command: $command}}' |
    bash "$HOOK" 2>/dev/null
  [ $? = 2 ] && actual=block
  if [ "$actual" = "$expected" ]; then
    echo "ok   $name"
  else
    echo "FAIL $name: got $actual, expected $expected"
    failures=$((failures + 1))
  fi
}

manual_repo=$(make_repo manual)
branch_repo=$(make_repo branch branch)
asked=$(make_transcript asked "commit and push this, then open a PR")
asked_pr=$(make_transcript asked-pr "Open the pull request")
not_asked=$(make_transcript not-asked "work on ticket 05")
negated=$(make_transcript negated "commit it but don't push yet")
pr_word=$(make_transcript pr-word "fix the PRD typo")

expect "manual, asked: push current branch allows" "$manual_repo" "$asked" "git push -u origin feature" allow
expect "manual, asked: bare push allows" "$manual_repo" "$asked" "git push" allow
expect "manual, asked: gh pr create allows" "$manual_repo" "$asked_pr" "git push && gh pr create --title x" allow
expect "manual, asked: push main blocks" "$manual_repo" "$asked" "git push origin main" block
expect "manual, asked: force push blocks" "$manual_repo" "$asked" "git push --force origin feature" block
expect "manual, asked: delete remote branch blocks" "$manual_repo" "$asked" "git push origin :feature" block
expect "manual, asked: gh pr merge blocks" "$manual_repo" "$asked" "gh pr merge 1" block
expect "manual, not asked: push blocks" "$manual_repo" "$not_asked" "git push origin feature" block
expect "manual, not asked: gh pr create blocks" "$manual_repo" "$not_asked" "gh pr create --draft" block
expect "manual, told not to push: push blocks" "$manual_repo" "$negated" "git push origin feature" block
expect "manual, 'PRD' is not a PR request: push blocks" "$manual_repo" "$pr_word" "git push origin feature" block
expect "manual, no transcript: push blocks" "$manual_repo" "" "git push origin feature" block
expect "manual: unrelated command allows" "$manual_repo" "$not_asked" "git status" allow

expect "branch: push feature allows" "$branch_repo" "$not_asked" "git push origin feature" allow
expect "branch: draft PR allows" "$branch_repo" "$not_asked" "gh pr create --draft" allow
expect "branch: non-draft PR blocks" "$branch_repo" "$not_asked" "gh pr create" block
expect "branch: push main blocks" "$branch_repo" "$asked" "git push origin main" block

[ $failures -eq 0 ]
