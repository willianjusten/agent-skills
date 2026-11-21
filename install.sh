#!/usr/bin/env bash
# Links skills and harness config from this repo into the machine. Idempotent.
# Written for the bash 3.2 that ships with macOS: no associative arrays, no mapfile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
GLOBAL_SKILLS="$CLAUDE_HOME/skills"
GLOBAL_AGENTS="$CLAUDE_HOME/agents"
SPOKE_DIR="${SPOKE_DIR:-$HOME/Developer/spoke}"
OWN_SKILLS="$ROOT/skills"
OWN_AGENTS="$ROOT/agents"
VENDOR_ROOT="$ROOT/vendor"
SCOPES_FILE="$ROOT/scopes.json"
DIST_SPOKE="$ROOT/dist/spoke"
SKILLS_CLI="skills@1.9.0"
# Codex reads the universal .agents/skills store, so naming it as the only agent
# makes the skills CLI install there and nowhere else.
SKILLS_AGENT="codex"
VALIDATOR_SOURCE="robonuggets/skill-creator-plus"
VALIDATOR="$VENDOR_ROOT/$VALIDATOR_SOURCE/.agents/skills/skill-creator-plus/scripts/validate_skill.py"

# Upstream ships `code-review`, which collides with Claude Code's built-in skill.
# Format: "<upstream name>:<installed name>". tests/vendoring.test.sh reads this line.
RENAMES="code-review:matt-code-review"

force=false
update=false
update_sources=""
node_checked=false
changes=()
warnings=()
manual=()

usage() {
  cat <<EOF
Usage:
  ./install.sh [--update [<owner>/<repo>]] [--force]   install and link skills and harness config
  ./install.sh check                                 validate own skills (skill-creator-plus validator + scope)

  --update   move every vendored source (or only the one named) to its newest
             upstream commit, rewrite its lock and print what changed
  --force    replace real files that sit where a link should go
EOF
}

log_change() { changes+=("$1"); }
log_warning() { warnings+=("$1"); }
log_manual() { manual+=("$1"); }

# Progress goes to stderr as it happens; the summary at the end stays on stdout.
log_step() { echo "==> $1" >&2; }
log_detail() { echo "    $1" >&2; }

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
  command -v agentplan >/dev/null || log_warning "agentplan not found; Spoke cannot regenerate its skills"
  has_context7_mcp || log_warning "context7 MCP server not found; agents cannot look up library docs (see README, What install.sh Touches)"
}

has_context7_mcp() {
  jq -e '.mcpServers // {} | has("context7")' "$HOME/.claude.json" >/dev/null 2>&1 && return 0
  grep -qs '"context7@' "$CLAUDE_HOME/plugins/installed_plugins.json"
}

link_harness() {
  link_path "$ROOT/harness/shared/instructions.md" "$CLAUDE_HOME/CLAUDE.md"
  link_path "$ROOT/harness/shared/CODING_STANDARDS.md" "$CLAUDE_HOME/CODING_STANDARDS.md"
  link_path "$ROOT/harness/claude/settings.json" "$CLAUDE_HOME/settings.json"
  link_path "$ROOT/harness/claude/statusline-command.sh" "$CLAUDE_HOME/statusline-command.sh"
  link_path "$ROOT/harness/claude/hooks/write-scope.sh" "$CLAUDE_HOME/hooks/write-scope.sh"
  link_path "$ROOT/harness/claude/hooks/loop-stop.sh" "$CLAUDE_HOME/hooks/loop-stop.sh"
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

vendor_lock() {
  echo "$VENDOR_ROOT/$1/skills-lock.json"
}

# Records the lock a source was last installed from, so an unchanged lock skips the network.
last_installed_lock() {
  echo "$VENDOR_ROOT/$1/.installed-lock.json"
}

locked_names() {
  jq -r '.skills | keys[]' "$1"
}

# Succeeds when a lock lists the given upstream skill name.
is_locked() {
  local lock="$1" upstream_name="$2"
  locked_names "$lock" | grep -qx "$upstream_name"
}

# Upstream names of the skills scopes.json enables for one source.
enabled_upstream_names() {
  local installed_name
  for installed_name in $(jq -r --arg source "$1" '.[$source] | to_entries[] | select(.value != "off") | .key' "$SCOPES_FILE"); do
    upstream_name_of "$installed_name"
  done
}

require_node() {
  $node_checked && return 0
  if ! command -v node >/dev/null ||
    ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 20) ? 0 : 1)'; then
    echo "Installing vendored skills needs node >= 22.20 (found $(node -v 2>/dev/null || echo none))" >&2
    exit 1
  fi
  node_checked=true
}

# Runs the skills CLI inside a directory, showing its output only on failure.
run_skills_cli() {
  local directory="$1" output
  shift
  require_node
  mkdir -p "$directory"
  if ! output="$(cd "$directory" && npx -y "$SKILLS_CLI" "$@" 2>&1)"; then
    echo "$output" >&2
    echo "skills CLI failed in $directory: $*" >&2
    exit 1
  fi
}

# Installs one source at the commits its lock records, then drops skills the lock
# no longer lists.
restore_vendor_source() {
  local source="$1" lock store installed_lock upstream_name needs_install=false
  lock="$(vendor_lock "$source")"
  store="$(vendor_store "$source")"
  installed_lock="$(last_installed_lock "$source")"
  if [ ! -f "$lock" ]; then
    log_manual "no lock for $source yet, run ./install.sh --update $source"
    return 0
  fi

  cmp -s "$lock" "$installed_lock" || needs_install=true
  for upstream_name in $(locked_names "$lock"); do
    [ -f "$store/$upstream_name/SKILL.md" ] || needs_install=true
  done
  if $needs_install; then
    if [ -n "$(locked_names "$lock")" ]; then
      local started_at=$SECONDS
      log_detail "fetching $source at $(locked_commits "$lock" | cut -c1-7) with the skills CLI..."
      run_skills_cli "$VENDOR_ROOT/$source" experimental_install --frozen-lockfile -a "$SKILLS_AGENT" -y
      log_detail "fetched $source in $((SECONDS - started_at))s"
      log_change "installed $source at its locked commit"
    fi
    cp "$lock" "$installed_lock"
  fi

  if [ -d "$store" ]; then
    for upstream_name in $(ls "$store"); do
      is_locked "$lock" "$upstream_name" && continue
      rm -rf "${store:?}/$upstream_name"
      log_change "removed directory $store/$upstream_name ($source skill not in its skills-lock.json)"
    done
  fi
  for upstream_name in $(enabled_upstream_names "$source"); do
    is_locked "$lock" "$upstream_name" ||
      log_manual "enabled in scopes.json but not locked, run ./install.sh --update $source: $(installed_name_of "$upstream_name")"
  done
  return 0
}

restore_vendored() {
  local source
  for source in $(vendor_sources); do
    restore_vendor_source "$source"
  done
}

# Prints the upstream commits a lock pins, comma-separated.
locked_commits() {
  [ -f "$1" ] || return 0
  jq -r '[.skills[].commit] | unique | join(",")' "$1"
}

# Prints the commit move of one source, a GitHub compare URL when both sides pin
# a single commit, and the diff between the old/ and new/ copies in a directory.
print_update_report() {
  local source="$1" old_commits="$2" new_commits="$3" snapshot_dir="$4"
  echo "== $source: ${old_commits:-none} -> ${new_commits:-none}"
  if [ -n "$old_commits" ] && [ -n "$new_commits" ] && [ "$old_commits" != "$new_commits" ] &&
    [ "${old_commits#*,}" = "$old_commits" ] && [ "${new_commits#*,}" = "$new_commits" ]; then
    echo "   https://github.com/$source/compare/$old_commits...$new_commits"
  fi
  if (cd "$snapshot_dir" && diff -ruN old new >"$snapshot_dir/changes.diff"); then
    echo "   no changes in the enabled skills"
  else
    cat "$snapshot_dir/changes.diff"
  fi
}

# Moves one source to its newest upstream commit: installs its enabled skills
# fresh, replaces its store and lock, and prints the diff of the enabled skills.
update_vendor_source() {
  local source="$1" lock store scratch_dir enabled_names old_commits upstream_name
  lock="$(vendor_lock "$source")"
  store="$(vendor_store "$source")"
  scratch_dir="$(mktemp -d)"
  enabled_names="$(enabled_upstream_names "$source")"
  old_commits="$(locked_commits "$lock")"
  echo "Updating vendored skills from $source..."

  mkdir -p "$scratch_dir/install" "$scratch_dir/old" "$scratch_dir/new"
  [ -d "$store" ] && cp -R "$store/." "$scratch_dir/old/"
  if [ -n "$enabled_names" ]; then
    # shellcheck disable=SC2086
    run_skills_cli "$scratch_dir/install" add "$source" -s $enabled_names -a "$SKILLS_AGENT" -y
  else
    jq -n '{ version: 2, skills: {} }' >"$scratch_dir/install/skills-lock.json"
  fi

  rm -rf "$store"
  mkdir -p "$(dirname "$store")"
  [ -d "$scratch_dir/install/.agents/skills" ] && cp -R "$scratch_dir/install/.agents/skills" "$store"
  cmp -s "$scratch_dir/install/skills-lock.json" "$lock" || log_change "updated lock for $source"
  cp "$scratch_dir/install/skills-lock.json" "$lock"
  cp "$lock" "$(last_installed_lock "$source")"
  apply_renames
  [ -d "$store" ] && cp -R "$store/." "$scratch_dir/new/"

  print_update_report "$source" "$old_commits" "$(locked_commits "$lock")" "$scratch_dir"
  rm -rf "$scratch_dir"

  local upstream_list
  upstream_list="$(npx -y "$SKILLS_CLI" add "$source" -l 2>&1 |
    perl -pe 's/\e\[[0-9;]*m//g' | perl -ne 'print "$1\n" if /^\S+\s{4}([a-z0-9][a-z0-9-]*)\s*$/')"
  for upstream_name in $upstream_list; do
    [ "$(vendored_scope "$source" "$(installed_name_of "$upstream_name")")" = "unlisted" ] &&
      log_manual "new upstream skill in $source, add it to scopes.json to decide: $upstream_name"
  done
  return 0
}

update_vendored() {
  local source
  for source in ${update_sources:-$(vendor_sources)}; do
    if ! vendor_sources | grep -qx "$source"; then
      echo "Not a vendored source in scopes.json: $source" >&2
      exit 1
    fi
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
  echo "$global_names" | grep -qx setup-matt-pocock-skills ||
    log_warning "setup-matt-pocock-skills is not linked; the tracker docs CLAUDE.md points at are missing"
}

# Own subagents live one category deep: agents/<category>/<name>.md.
own_agent_files() {
  local agent_file
  for agent_file in "$OWN_AGENTS"/*/*.md; do
    [ -f "$agent_file" ] && echo "$agent_file"
  done
  return 0
}

# Spoke has no agent source, so agents take every skill scope except spoke.
agent_scope_valid() {
  case "$1" in personal | both | off) return 0 ;; *) return 1 ;; esac
}

agent_scope_error() {
  echo "metadata.scope must be personal, both or off (found '${1:-nothing}')"
}

# Links subagents by the same scopes as skills. `check` rejects any other scope;
# here such an agent is skipped with the same message, so Spoke never changes.
link_agents() {
  local agent_file name scope duplicates
  duplicates="$(own_agent_files | xargs -n1 basename 2>/dev/null | sort | uniq -d)"
  if [ -n "$duplicates" ]; then
    echo "Agent names defined twice: $duplicates" >&2
    exit 1
  fi

  agent_names=""
  for agent_file in $(own_agent_files); do
    name="$(basename "$agent_file")"
    scope="$(frontmatter_scope "$agent_file")"
    if ! agent_scope_valid "$scope"; then
      log_warning "$(agent_scope_error "$scope"), not linked: ${name%.md}"
      continue
    fi
    [ "$scope" = "off" ] && continue
    link_path "$agent_file" "$GLOBAL_AGENTS/$name"
    agent_names="$agent_names$name"$'\n'
  done
  remove_stale_links "$GLOBAL_AGENTS" "$agent_names"
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

# Validates own skills: skill-creator-plus validator, a valid scope, and a README.
check_own_skills() {
  command -v python3 >/dev/null || { echo "check needs python3" >&2; exit 1; }
  [ -f "$VALIDATOR" ] || restore_vendor_source "$VALIDATOR_SOURCE"
  [ -f "$VALIDATOR" ] || { echo "Validator missing: run ./install.sh" >&2; exit 1; }
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

# Reads a top-level field from a frontmatter block, without surrounding quotes.
frontmatter_field() {
  awk -v field="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    index($0, field ":") == 1 {
      sub("^" field ":[ \t]*", "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' "$1"
}

# Validates own subagents: name, description and model, a name matching the
# file name, and a valid scope.
check_own_agents() {
  local agent_file field scope failed=0
  for agent_file in $(own_agent_files); do
    echo "== ${agent_file#"$ROOT"/}"
    for field in name description model; do
      [ -n "$(frontmatter_field "$agent_file" "$field")" ] ||
        { echo "ERROR $field: agent frontmatter needs $field"; failed=1; }
    done
    [ "$(frontmatter_field "$agent_file" name)" = "$(basename "$agent_file" .md)" ] ||
      { echo "ERROR name: frontmatter name must equal the file name"; failed=1; }
    scope="$(frontmatter_scope "$agent_file")"
    agent_scope_valid "$scope" || { echo "ERROR scope: $(agent_scope_error "$scope")"; failed=1; }
  done
  return "$failed"
}

# Reads a field nested under metadata: in a frontmatter block.
frontmatter_metadata_field() {
  awk -v field="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    /^metadata:/ { in_metadata = 1; next }
    in_metadata && /^[^ \t]/ { in_metadata = 0 }
    in_metadata && $0 ~ "^[ \t]+" field ":" {
      sub("^[ \t]+" field ":[ \t]*", "")
      gsub(/,/, " ")
      print
      exit
    }
  ' "$1"
}

# Orchestrators (agents, and skills under skills/orchestration/) may run siblings,
# listed in metadata.uses. Every one must exist and be visible at the
# orchestrator's scope: personal sees personal and both, both sees only both.
check_orchestrators() {
  local failed=0 resolved_skills file kind scope uses dependency found dependency_scope
  resolved_skills="$(resolve_skills)"
  for file in $(own_skill_dirs | sed 's|$|/SKILL.md|') $(own_agent_files); do
    uses="$(frontmatter_metadata_field "$file" uses)"
    [ -n "$uses" ] || continue
    case "$file" in
      */SKILL.md)
        kind=skill
        if [ "$(basename "$(dirname "$(dirname "$file")")")" != orchestration ]; then
          echo "ERROR uses: ${file#"$ROOT"/}: only orchestrators (agents, skills/orchestration/) may declare metadata.uses"
          failed=1
          continue
        fi
        ;;
      *) kind=agent ;;
    esac
    scope="$(frontmatter_scope "$file")"
    for dependency in $uses; do
      found="$(echo "$resolved_skills" | awk -v name="$dependency" '$1 == name { print $2; exit }')"
      [ -n "$found" ] || found="$(own_agent_files | while read -r agent_file; do
        [ "$(basename "$agent_file" .md)" = "$dependency" ] && frontmatter_scope "$agent_file" && break
      done)"
      dependency_scope="$found"
      if [ -z "$dependency_scope" ]; then
        echo "ERROR uses: ${file#"$ROOT"/} ($kind) names $dependency: not found as a skill or agent"
        failed=1
      elif [ "$dependency_scope" = off ]; then
        echo "ERROR uses: ${file#"$ROOT"/} names $dependency: scoped off, installed nowhere"
        failed=1
      elif [ "$scope" = both ] && [ "$dependency_scope" != both ]; then
        echo "ERROR uses: ${file#"$ROOT"/} names $dependency: scoped $dependency_scope, not visible to a both orchestrator"
        failed=1
      elif [ "$scope" = personal ] && [ "$dependency_scope" = spoke ]; then
        echo "ERROR uses: ${file#"$ROOT"/} names $dependency: scoped spoke, not visible to a personal orchestrator"
        failed=1
      fi
    done
  done
  return "$failed"
}

# Points git at .githooks/ so the pre-commit check runs here and in every worktree.
install_git_hook() {
  [ "$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$ROOT" && pwd -P)" ] || return 0
  [ "$(git -C "$ROOT" config --get core.hooksPath)" = ".githooks" ] && return 0
  git -C "$ROOT" config core.hooksPath .githooks
  log_change "set core.hooksPath to .githooks"
}

main() {
  case "${1:-}" in
    check)
      local status=0
      check_own_skills || status=1
      check_own_agents || status=1
      check_orchestrators || status=1
      exit "$status"
      ;;
  esac
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --update)
        update=true
        case "${2:-}" in
          */*) update_sources="$update_sources $2"; shift ;;
        esac
        ;;
      --force) force=true ;;
      -h | --help) usage; exit 0 ;;
      *) usage >&2; exit 1 ;;
    esac
    shift
  done

  log_step "Checking prerequisites"
  check_prerequisites
  log_step "Installing the git hook"
  install_git_hook
  log_step "Linking harness files"
  link_harness
  log_step "Restoring vendored skills"
  restore_vendored
  if $update; then
    log_step "Updating vendored sources"
    update_vendored
  fi
  log_step "Applying renames"
  apply_renames
  log_step "Linking skills"
  link_skills
  log_step "Linking agents"
  link_agents
  if [ -d "$SPOKE_DIR" ]; then
    log_step "Updating Spoke"
  fi
  setup_spoke
  echo >&2

  echo "Skills linked into $GLOBAL_SKILLS: $(printf '%s' "$global_names" | grep -c . || true)"
  echo "Agents linked into $GLOBAL_AGENTS: $(printf '%s' "$agent_names" | grep -c . || true)"
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
