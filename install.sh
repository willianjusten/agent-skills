#!/usr/bin/env bash
# Links skills and harness config from this repo into the machine. Idempotent.
# Written for the bash 3.2 that ships with macOS: no associative arrays, no mapfile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GLOBAL_SKILLS="$CLAUDE_HOME/skills"
SPOKE_DIR="${SPOKE_DIR:-$HOME/Developer/spoke}"
OWN_SKILLS="$ROOT/skills"
VENDOR_DIR="$ROOT/vendor/mattpocock"
VENDOR_STORE="$VENDOR_DIR/.agents/skills"
VENDOR_SOURCE="mattpocock/skills"
SCOPES_FILE="$ROOT/scopes.json"
DIST_SPOKE="$ROOT/dist/spoke"
SKILLS_CLI="skills@1.7.2"

# Upstream ships `code-review`, which collides with Claude Code's built-in skill.
# Format: "<upstream name>:<installed name>".
RENAMES="code-review:matt-code-review"

force=false
update=false
changes=()
warnings=()
manual=()

usage() {
  cat <<EOF
Usage:
  ./install.sh [--update] [--force]   link skills and harness config
  ./install.sh init-project [dir]     add AGENTS.md and a CLAUDE.md importing it

  --update   refresh vendored skills from upstream before linking
  --force    replace real files that sit where a link should go
EOF
}

log_change() { changes+=("$1"); }
log_warning() { warnings+=("$1"); }
log_manual() { manual+=("$1"); }

print_list() {
  local title="$1"
  shift
  [ "$#" -eq 0 ] && return 0
  echo
  echo "$title"
  local item
  for item in "$@"; do echo "  - $item"; done
}

installed_name_of() {
  local upstream_name="$1" pair
  for pair in $RENAMES; do
    if [ "${pair%%:*}" = "$upstream_name" ]; then
      echo "${pair#*:}"
      return
    fi
  done
  echo "$upstream_name"
}

upstream_name_of() {
  local installed_name="$1" pair
  for pair in $RENAMES; do
    if [ "${pair#*:}" = "$installed_name" ]; then
      echo "${pair%%:*}"
      return
    fi
  done
  echo "$installed_name"
}

# Creates or fixes a symlink. A real file or directory in the way is only
# replaced with --force.
link_path() {
  local source_path="$1" link="$2"
  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$source_path" ] && return 0
    ln -sfn "$source_path" "$link"
    log_change "relinked $link"
  elif [ -e "$link" ]; then
    if $force; then
      rm -rf "$link"
      ln -s "$source_path" "$link"
      log_change "replaced real file with link: $link"
    else
      log_warning "real file in the way, not linked (use --force): $link"
    fi
  else
    mkdir -p "$(dirname "$link")"
    ln -s "$source_path" "$link"
    log_change "linked $link"
  fi
}

check_prerequisites() {
  local missing=""
  command -v git >/dev/null || missing="$missing git"
  command -v jq >/dev/null || missing="$missing jq"
  if [ -n "$missing" ]; then
    echo "Missing required tools:$missing" >&2
    exit 1
  fi
  if $update; then
    if ! command -v node >/dev/null; then
      echo "--update needs node >= 22.20" >&2
      exit 1
    fi
    if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 20) ? 0 : 1)'; then
      echo "--update needs node >= 22.20 (found $(node -v))" >&2
      exit 1
    fi
  fi
  command -v agentplan >/dev/null || log_warning "agentplan not found; Spoke cannot regenerate its skills"
}

link_harness() {
  link_path "$ROOT/harness/shared/instructions.md" "$CLAUDE_HOME/CLAUDE.md"
  link_path "$ROOT/harness/claude/settings.json" "$CLAUDE_HOME/settings.json"
  link_path "$ROOT/harness/claude/statusline-command.sh" "$CLAUDE_HOME/statusline-command.sh"
  link_path "$ROOT/harness/claude/matt-skills" "$CLAUDE_HOME/matt-skills"
}

# Runs the skills CLI inside the vendor store, showing its output only on failure.
run_skills_cli() {
  local output
  if ! output="$(cd "$VENDOR_DIR" && npx -y "$SKILLS_CLI" "$@" 2>&1)"; then
    echo "$output" >&2
    echo "skills CLI failed: $*" >&2
    exit 1
  fi
}

vendored_scope() {
  jq -r --arg name "$1" '.[$name] // "unlisted"' "$SCOPES_FILE"
}

update_vendored() {
  echo "Updating vendored skills from $VENDOR_SOURCE..."
  run_skills_cli update -y

  local installed_name upstream_name scope to_add="" to_remove=""
  for installed_name in $(jq -r 'to_entries[] | select(.value != "off") | .key' "$SCOPES_FILE"); do
    upstream_name="$(upstream_name_of "$installed_name")"
    [ -d "$VENDOR_STORE/$upstream_name" ] || to_add="$to_add $upstream_name"
  done
  for upstream_name in $(ls "$VENDOR_STORE"); do
    scope="$(vendored_scope "$(installed_name_of "$upstream_name")")"
    case "$scope" in off | unlisted) to_remove="$to_remove $upstream_name" ;; esac
  done
  if [ -n "$to_add" ]; then
    # shellcheck disable=SC2086
    run_skills_cli add "$VENDOR_SOURCE" -s $to_add -y
    log_change "added vendored skills:$to_add"
  fi
  if [ -n "$to_remove" ]; then
    # shellcheck disable=SC2086
    run_skills_cli remove $to_remove -y
    log_change "removed vendored skills:$to_remove"
  fi

  local upstream_list
  upstream_list="$(cd "$VENDOR_DIR" && npx -y "$SKILLS_CLI" add "$VENDOR_SOURCE" -l 2>&1 |
    perl -pe 's/\e\[[0-9;]*m//g' | perl -ne 'print "$1\n" if /^\S+\s{4}([a-z0-9][a-z0-9-]*)\s*$/')"
  for upstream_name in $upstream_list; do
    [ "$(vendored_scope "$(installed_name_of "$upstream_name")")" = "unlisted" ] &&
      log_manual "new upstream skill, add it to scopes.json to decide: $upstream_name"
  done
  return 0
}

# Replaces one literal string in a vendored file. Fails loudly when neither the
# original nor the patched text is found, which means upstream changed.
patch_file() {
  local file="$1" original="$2" patched="$3"
  [ -f "$file" ] || return 0
  if grep -qF -- "$original" "$file"; then
    ORIGINAL="$original" PATCHED="$patched" perl -0pi -e 's/\Q$ENV{ORIGINAL}\E/$ENV{PATCHED}/g' "$file"
    log_change "patched $(basename "$(dirname "$file")")/$(basename "$file")"
  elif ! grep -qF -- "$patched" "$file"; then
    echo "Rename patch no longer matches in $file: expected '$original'" >&2
    exit 1
  fi
}

apply_renames() {
  patch_file "$VENDOR_STORE/code-review/SKILL.md" "name: code-review" "name: matt-code-review"
  patch_file "$VENDOR_STORE/ask-matt/SKILL.md" '`/code-review`' '`/matt-code-review`'
  patch_file "$VENDOR_STORE/implement/SKILL.md" '"code-review"' '"matt-code-review"'
  patch_file "$VENDOR_STORE/implement-spec/SKILL.md" '`code-review`' '`matt-code-review`'
  patch_file "$VENDOR_STORE/tdd/SKILL.md" 'the `code-review` skill' 'the `matt-code-review` skill'

  local leftovers
  leftovers="$(grep -rnE '(^|[^-])code-review' "$VENDOR_STORE" || true)"
  if [ -n "$leftovers" ]; then
    echo "Unpatched code-review references in vendored skills:" >&2
    echo "$leftovers" >&2
    exit 1
  fi
}

# Reads `scope` from the `metadata:` block of a SKILL.md frontmatter.
frontmatter_scope() {
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    /^metadata:/ { in_metadata = 1; next }
    in_metadata && /^[^ \t]/ { in_metadata = 0 }
    in_metadata && /^[ \t]+scope:/ {
      sub(/^[ \t]+scope:[ \t]*/, "")
      gsub(/["'\'' \t]/, "")
      print
      exit
    }
  ' "$1"
}

# Prints "<name> <scope> <path>" for every skill in the repo.
resolve_skills() {
  local skill_dir name scope
  for skill_dir in "$OWN_SKILLS"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    name="$(basename "$skill_dir")"
    scope="$(frontmatter_scope "$skill_dir/SKILL.md")"
    echo "$name ${scope:-missing} ${skill_dir%/}"
  done
  for skill_dir in "$VENDOR_STORE"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    name="$(installed_name_of "$(basename "$skill_dir")")"
    echo "$name $(vendored_scope "$name") ${skill_dir%/}"
  done
}

# Removes links in a directory that point into this repo but are not wanted.
remove_stale_links() {
  local directory="$1" wanted_names="$2" link
  [ -d "$directory" ] || return 0
  for link in "$directory"/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in "$ROOT"/*) ;; *) continue ;; esac
    if ! echo "$wanted_names" | grep -qx "$(basename "$link")"; then
      rm "$link"
      log_change "removed stale link $link"
    fi
  done
}

link_skills() {
  local resolved duplicates name scope skill_path
  resolved="$(resolve_skills)"
  duplicates="$(echo "$resolved" | awk 'NF { print $1 }' | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    echo "Skill names defined twice: $duplicates" >&2
    exit 1
  fi

  global_names=""
  spoke_names=""
  personal_names=""
  managed_names=""
  while read -r name scope skill_path; do
    [ -n "$name" ] || continue
    managed_names="$managed_names$name"$'\n'
    case "$scope" in
      personal | both)
        link_path "$skill_path" "$GLOBAL_SKILLS/$name"
        global_names="$global_names$name"$'\n'
        [ "$scope" = "personal" ] && personal_names="$personal_names$name"$'\n'
        ;;
      spoke)
        spoke_names="$spoke_names$name"$'\n'
        ;;
      off) ;;
      unlisted) log_warning "vendored skill missing from scopes.json, not linked: $name" ;;
      *) log_warning "skill has invalid scope '$scope', not linked: $name" ;;
    esac
  done <<<"$resolved"
  remove_stale_links "$GLOBAL_SKILLS" "$global_names"
}

spoke_source_entry() {
  if [ "$(dirname "$ROOT")" = "$(dirname "$SPOKE_DIR")" ]; then
    echo "../$(basename "$ROOT")/dist/spoke"
  else
    echo "$DIST_SPOKE"
  fi
}

setup_spoke() {
  [ -d "$SPOKE_DIR" ] || return 0

  local settings_file="$SPOKE_DIR/.claude/settings.local.json"
  local current_settings="{}" updated_settings personal_json managed_json
  [ -f "$settings_file" ] && current_settings="$(cat "$settings_file")"
  personal_json="$(printf '%s' "$personal_names" | jq -R . | jq -s .)"
  managed_json="$(printf '%s' "$managed_names" | jq -R . | jq -s .)"
  # Drops "off" overrides for skills this repo manages, then re-adds one per personal-only skill.
  updated_settings="$(echo "$current_settings" | jq --argjson personal "$personal_json" --argjson managed "$managed_json" '
    .skillOverrides = (
      ((.skillOverrides // {}) | with_entries(select((.key as $key | $managed | index($key)) == null or .value != "off")))
      + ($personal | map({ (.): "off" }) | add // {})
    )
    | if .skillOverrides == {} then del(.skillOverrides) else . end
  ')"
  if [ "$(echo "$current_settings" | jq -S .)" != "$(echo "$updated_settings" | jq -S .)" ]; then
    mkdir -p "$(dirname "$settings_file")"
    echo "$updated_settings" >"$settings_file"
    log_change "updated skillOverrides in $settings_file"
  fi

  local name
  for name in $spoke_names; do
    link_path "$(resolve_skills | awk -v name="$name" '$1 == name { print $3 }')" "$DIST_SPOKE/$name"
  done
  remove_stale_links "$DIST_SPOKE" "$spoke_names"

  local source_entry
  source_entry="$(spoke_source_entry)"
  if ! grep -qF "\"$source_entry\"" "$SPOKE_DIR/agentplan.jsonc" 2>/dev/null; then
    log_manual "add \"$source_entry\" to sources.skills.global in $SPOKE_DIR/agentplan.jsonc, then run agentplan generate"
  fi
}

check_cursor_duplicates() {
  local directory
  for directory in "$HOME/.agents/skills" "$HOME/.cursor/skills"; do
    if [ -d "$directory" ] && [ -n "$(ls -A "$directory")" ]; then
      log_warning "$directory is not empty; Cursor may show skills twice"
    fi
  done
}

init_project() {
  local project_dir="${1:-.}"
  [ -d "$project_dir" ] || { echo "No such directory: $project_dir" >&2; exit 1; }
  if [ ! -f "$project_dir/AGENTS.md" ]; then
    printf '# Agent instructions\n\n' >"$project_dir/AGENTS.md"
    echo "created $project_dir/AGENTS.md"
  fi
  if [ ! -e "$project_dir/CLAUDE.md" ]; then
    echo "@AGENTS.md" >"$project_dir/CLAUDE.md"
    echo "created $project_dir/CLAUDE.md"
  elif ! grep -qx "@AGENTS.md" "$project_dir/CLAUDE.md"; then
    echo "CLAUDE.md exists without @AGENTS.md; add that line to share instructions with Cursor"
  fi
}

main() {
  if [ "${1:-}" = "init-project" ]; then
    init_project "${2:-.}"
    exit 0
  fi
  local argument
  for argument in "$@"; do
    case "$argument" in
      --update) update=true ;;
      --force) force=true ;;
      -h | --help) usage; exit 0 ;;
      *) usage >&2; exit 1 ;;
    esac
  done

  check_prerequisites
  link_harness
  $update && update_vendored
  apply_renames
  link_skills
  setup_spoke
  check_cursor_duplicates

  echo "Skills linked into $GLOBAL_SKILLS: $(printf '%s' "$global_names" | grep -c . || true)"
  [ -d "$SPOKE_DIR" ] && echo "Spoke-only skills in $DIST_SPOKE: $(printf '%s' "$spoke_names" | grep -c . || true)"
  if [ "${#changes[@]}" -eq 0 ]; then
    echo "No changes."
  else
    print_list "Changes:" "${changes[@]}"
  fi
  print_list "Warnings:" ${warnings[@]+"${warnings[@]}"}
  print_list "Manual steps:" ${manual[@]+"${manual[@]}"}
}

main "$@"
