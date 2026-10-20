#!/bin/bash
# PreToolUse hook for Bash. Based on mattpocock/skills git-guardrails-claude-code,
# extended with the per-project push policy in .claude/afk.json:
#   "manual" (default, also when the file is missing): block every git push.
#   "branch": allow pushing non-default branches and `gh pr create --draft`.
# Always blocked: default-branch pushes, force pushes, remote deletes, gh pr merge.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -n "$HOOK_CWD" ] && [ -d "$HOOK_CWD" ] && cd "$HOOK_CWD"

block() {
  echo "BLOCKED: '$COMMAND' $1" >&2
  exit 2
}

DANGEROUS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    block "matches dangerous pattern '$pattern'. The user has prevented you from doing this."
  fi
done

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
AFK_FILE="$REPO_ROOT/.claude/afk.json"
PUSH_POLICY=manual
if [ -n "$REPO_ROOT" ] && [ -f "$AFK_FILE" ]; then
  PUSH_POLICY=$(jq -r '.push // "manual"' "$AFK_FILE" 2>/dev/null || echo manual)
fi
[ "$PUSH_POLICY" = "branch" ] || PUSH_POLICY=manual

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
# main and master always count as default, plus whatever origin/HEAD points to.
DEFAULT_BRANCHES="main master $(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"

MANUAL_MESSAGE="is not allowed: this repo's push policy is 'manual' (.claude/afk.json is missing or sets \"push\": \"manual\"). Do not push or open PRs. Commit locally and report the branch name; the user pushes after reading the report."

is_default_branch() {
  local branch
  for branch in $DEFAULT_BRANCHES; do
    [ "$1" = "$branch" ] && return 0
  done
  return 1
}

check_push_target() {
  local target="${1#refs/heads/}"
  [ "$target" = "HEAD" ] && target="$CURRENT_BRANCH"
  if is_default_branch "$target"; then
    block "pushes to the default branch '$target', which is never allowed. Push the ticket or integration branch instead and leave the default branch to the user."
  fi
}

check_git_push() {
  local token remote="" refspecs=() refspec
  for token in "$@"; do
    case "$token" in
      --force | --force-with-lease* | --force-if-includes | --mirror)
        block "force-pushes, which is never allowed. Push without force, or stop and report the conflict to the user." ;;
      --delete | --prune)
        block "deletes remote branches, which is never allowed. Leave branch cleanup to the user." ;;
      --all)
        block "pushes every branch including the default one, which is never allowed. Push the ticket branch by name." ;;
      --*) ;;
      -*)
        case "$token" in
          *f*) block "force-pushes, which is never allowed. Push without force, or stop and report the conflict to the user." ;;
          *d*) block "deletes remote branches, which is never allowed. Leave branch cleanup to the user." ;;
        esac ;;
      *)
        if [ -z "$remote" ]; then remote="$token"; else refspecs+=("$token"); fi ;;
    esac
  done

  [ "$PUSH_POLICY" = "manual" ] && block "$MANUAL_MESSAGE"

  if [ ${#refspecs[@]} -eq 0 ]; then
    check_push_target "$CURRENT_BRANCH"
    return
  fi
  for refspec in "${refspecs[@]}"; do
    case "$refspec" in
      +*) block "force-pushes with a '+' refspec, which is never allowed. Push without force, or stop and report the conflict to the user." ;;
      :*) block "deletes a remote branch, which is never allowed. Leave branch cleanup to the user." ;;
      *:*) check_push_target "${refspec##*:}" ;;
      *) check_push_target "$refspec" ;;
    esac
  done
}

check_gh_pr() {
  case "$1" in
    merge)
      block "merges a PR, which is never allowed. Leave the PR open for the user to review and merge." ;;
    create)
      [ "$PUSH_POLICY" = "manual" ] && block "$MANUAL_MESSAGE"
      case " $* " in
        *" --draft "* | *" -d "*) ;;
        *) block "opens a non-draft PR. Under the 'branch' push policy, use 'gh pr create --draft'." ;;
      esac ;;
  esac
}

# Check each command in a chain (&&, ||, ;, |) on its own.
while IFS= read -r segment; do
  read -ra words <<<"$segment"
  index=0
  while [ $index -lt ${#words[@]} ]; do
    word="${words[$index]}"
    next="${words[$((index + 1))]}"
    if [ "$word" = "git" ]; then
      # Skip global options such as -C <path> or -c key=value before the subcommand.
      position=$((index + 1))
      while [[ "${words[$position]}" == -* ]]; do
        case "${words[$position]}" in -C | -c) position=$((position + 2)) ;; *) position=$((position + 1)) ;; esac
      done
      if [ "${words[$position]}" = "push" ]; then
        check_git_push "${words[@]:$((position + 1))}"
      fi
      break
    elif [ "$word" = "gh" ] && [ "$next" = "pr" ]; then
      check_gh_pr "${words[@]:$((index + 2))}"
      break
    fi
    index=$((index + 1))
  done
done < <(printf '%s\n' "$COMMAND" | perl -pe 's/&&|\|\||[;|]/\n/g')

exit 0
