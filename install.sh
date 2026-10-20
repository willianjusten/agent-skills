#!/usr/bin/env bash
# Links skills and harness config from this repo into the machine. Idempotent.
# Written for the bash 3.2 that ships with macOS: no associative arrays, no mapfile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GLOBAL_SKILLS="$CLAUDE_HOME/skills"
SPOKE_DIR="${SPOKE_DIR:-$HOME/Developer/spoke}"
OWN_SKILLS="$ROOT/skills"
VENDOR_ROOT="$ROOT/vendor"
SCOPES_FILE="$ROOT/scopes.json"
DIST_SPOKE="$ROOT/dist/spoke"
SKILLS_CLI="skills@1.7.2"
VALIDATOR="$VENDOR_ROOT/robonuggets/skill-creator-plus/.agents/skills/skill-creator-plus/scripts/validate_skill.py"

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
  ./install.sh check                  validate own skills (skill-creator-plus validator + scope)
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
  link_path "$ROOT/harness/shared/CODING_STANDARDS.md" "$CLAUDE_HOME/CODING_STANDARDS.md"
  link_path "$ROOT/harness/claude/settings.json" "$CLAUDE_HOME/settings.json"
  link_path "$ROOT/harness/claude/statusline-command.sh" "$CLAUDE_HOME/statusline-command.sh"
  link_path "$ROOT/harness/claude/matt-skills" "$CLAUDE_HOME/matt-skills"
}

# Vendored sources are the top-level keys of scopes.json, e.g. "mattpocock/skills".
vendor_sources() {
  jq -r 'keys[]' "$SCOPES_FILE"
}

vendor_store() {
  echo "$VENDOR_ROOT/$1/.agents/skills"
}

vendored_scope() {
  jq -r --arg source "$1" --arg name "$2" '.[$source][$name] // "unlisted"' "$SCOPES_FILE"
}

# Runs the skills CLI inside one vendor directory, showing its output only on failure.
run_skills_cli() {
  local source="$1" output
  shift
  mkdir -p "$VENDOR_ROOT/$source"
  if ! output="$(cd "$VENDOR_ROOT/$source" && npx -y "$SKILLS_CLI" "$@" 2>&1)"; then
    echo "$output" >&2
    echo "skills CLI failed in vendor/$source: $*" >&2
    exit 1
  fi
}

update_vendor_source() {
  local source="$1" store installed_name upstream_name scope to_add="" to_remove=""
  store="$(vendor_store "$source")"
  echo "Updating vendored skills from $source..."
  [ -f "$VENDOR_ROOT/$source/skills-lock.json" ] && run_skills_cli "$source" update -y

  for installed_name in $(jq -r --arg source "$source" '.[$source] | to_entries[] | select(.value != "off") | .key' "$SCOPES_FILE"); do
    upstream_name="$(upstream_name_of "$installed_name")"
    [ -d "$store/$upstream_name" ] || to_add="$to_add $upstream_name"
  done
  if [ -d "$store" ]; then
    for upstream_name in $(ls "$store"); do
      scope="$(vendored_scope "$source" "$(installed_name_of "$upstream_name")")"
      case "$scope" in off | unlisted) to_remove="$to_remove $upstream_name" ;; esac
    done
  fi
  if [ -n "$to_add" ]; then
    # shellcheck disable=SC2086
    run_skills_cli "$source" add "$source" -s $to_add -y
    log_change "added from $source:$to_add"
  fi
  if [ -n "$to_remove" ]; then
    # shellcheck disable=SC2086
    run_skills_cli "$source" remove $to_remove -y
    log_change "removed from $source:$to_remove"
  fi

  local upstream_list
  upstream_list="$(cd "$VENDOR_ROOT/$source" && npx -y "$SKILLS_CLI" add "$source" -l 2>&1 |
    perl -pe 's/\e\[[0-9;]*m//g' | perl -ne 'print "$1\n" if /^\S+\s{4}([a-z0-9][a-z0-9-]*)\s*$/')"
  for upstream_name in $upstream_list; do
    [ "$(vendored_scope "$source" "$(installed_name_of "$upstream_name")")" = "unlisted" ] &&
      log_manual "new upstream skill in $source, add it to scopes.json to decide: $upstream_name"
  done
  return 0
}

update_vendored() {
  local source
  for source in $(vendor_sources); do
    update_vendor_source "$source"
  done
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
  local matt_store
  matt_store="$(vendor_store mattpocock/skills)"
  [ -d "$matt_store" ] || return 0
  patch_file "$matt_store/code-review/SKILL.md" "name: code-review" "name: matt-code-review"
  patch_file "$matt_store/ask-matt/SKILL.md" '`/code-review`' '`/matt-code-review`'
  patch_file "$matt_store/implement/SKILL.md" '"code-review"' '"matt-code-review"'
  patch_file "$matt_store/implement-spec/SKILL.md" '`code-review`' '`matt-code-review`'
  patch_file "$matt_store/tdd/SKILL.md" 'the `code-review` skill' 'the `matt-code-review` skill'

  local leftovers
  leftovers="$(grep -rnE '(^|[^-])code-review' "$matt_store" || true)"
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
      sub(/[ \t]*#.*$/, "")
      gsub(/["'\'' \t]/, "")
      print
      exit
    }
  ' "$1"
}

# Own skills live one category deep: skills/<category>/<name>/SKILL.md.
own_skill_dirs() {
  local skill_file
  for skill_file in "$OWN_SKILLS"/*/*/SKILL.md; do
    [ -f "$skill_file" ] && dirname "$skill_file"
  done
  return 0
}

# Prints "<name> <scope> <path>" for every skill in the repo.
resolve_skills() {
  local skill_dir name scope source
  for skill_dir in $(own_skill_dirs); do
    name="$(basename "$skill_dir")"
    scope="$(frontmatter_scope "$skill_dir/SKILL.md")"
    echo "$name ${scope:-missing} $skill_dir"
  done
  for source in $(vendor_sources); do
    for skill_dir in "$(vendor_store "$source")"/*/; do
      [ -f "$skill_dir/SKILL.md" ] || continue
      name="$(installed_name_of "$(basename "$skill_dir")")"
      echo "$name $(vendored_scope "$source" "$name") ${skill_dir%/}"
    done
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

  # Created even when empty, since agentplan.jsonc lists it as a skill source.
  mkdir -p "$DIST_SPOKE"
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

# Validates own skills: skill-creator-plus validator, a valid scope, and a README.
check_own_skills() {
  command -v python3 >/dev/null || { echo "check needs python3" >&2; exit 1; }
  [ -f "$VALIDATOR" ] || { echo "Validator missing: run ./install.sh --update" >&2; exit 1; }
  local skill_dir scope failed=0 checked=0
  for skill_dir in $(own_skill_dirs); do
    checked=$((checked + 1))
    echo "== ${skill_dir#"$ROOT"/}"
    python3 "$VALIDATOR" "$skill_dir" || failed=1
    scope="$(frontmatter_scope "$skill_dir/SKILL.md")"
    case "$scope" in
      personal | both | spoke | off) ;;
      *) echo "ERROR scope: metadata.scope must be personal, both, spoke or off (found '${scope:-nothing}')"; failed=1 ;;
    esac
    [ -f "$skill_dir/README.md" ] || { echo "ERROR readme: missing README.md (see AGENTS.md)"; failed=1; }
  done
  [ "$checked" -eq 0 ] && echo "No own skills under skills/<category>/<name>/ yet."
  return "$failed"
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
  case "${1:-}" in
    init-project)
      init_project "${2:-.}"
      exit 0
      ;;
    check)
      check_own_skills
      exit $?
      ;;
  esac
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
