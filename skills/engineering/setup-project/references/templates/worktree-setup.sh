#!/bin/bash
# Prepares a git worktree for an agent: installs dependencies, copies the env files
# from the main checkout, and gives this worktree its own port and database so that
# parallel worktrees never share a dev server or a dev database.
# In the main checkout it only installs dependencies.
set -euo pipefail

# Set these from the project's env files. Leave DATABASE_VARIABLE empty when there is no database.
PORT_VARIABLE="PORT"
DATABASE_VARIABLE="DATABASE_URL"
BASE_PORT=3000

worktree_root=$(git rev-parse --show-toplevel)
main_root=$(git worktree list --porcelain | awk 'NR == 1 { sub(/^worktree /, ""); print }')
cd "$worktree_root"

# Each worktree keeps its index in its own git dir, which `git worktree remove` deletes,
# so an index stays stable while the worktree lives and is reused after it is gone.
# The main checkout is 0.
allocate_worktree_index() {
  local index_file used_indices candidate=1
  index_file="$(git rev-parse --git-dir)/worktree-index"
  if [ -f "$index_file" ]; then
    cat "$index_file"
    return
  fi
  used_indices=$(cat "$(git rev-parse --git-common-dir)"/worktrees/*/worktree-index 2>/dev/null || true)
  while echo "$used_indices" | grep -qx "$candidate"; do
    candidate=$((candidate + 1))
  done
  echo "$candidate" >"$index_file"
  echo "$candidate"
}

if [ -f bun.lock ] || [ -f bun.lockb ]; then package_manager=bun
elif [ -f pnpm-lock.yaml ]; then package_manager=pnpm
elif [ -f yarn.lock ]; then package_manager=yarn
else package_manager=npm
fi

install_dependencies() {
  case "$package_manager" in
    bun | pnpm) "$package_manager" install --frozen-lockfile ;;
    yarn) yarn install --immutable 2>/dev/null || yarn install --frozen-lockfile ;;
    npm) if [ -f package-lock.json ]; then npm ci; else npm install; fi ;;
  esac
}

# set_env_value <file> <name> <value>: replaces the line for <name>, or appends it.
set_env_value() {
  local env_file="$1" name="$2" value="$3" temporary_file
  temporary_file=$(mktemp)
  grep -v "^${name}=" "$env_file" >"$temporary_file" 2>/dev/null || true
  echo "${name}=${value}" >>"$temporary_file"
  mv "$temporary_file" "$env_file"
}

# A URL keeps its scheme, host and query; only the database name gets the suffix.
# An earlier suffix is dropped first, so running the script twice is safe.
worktree_database_value() {
  local value="$1" suffix="_wt${worktree_index}" query=""
  value="${value%\"}"
  value="${value#\"}"
  if [[ "$value" == *"?"* ]]; then
    query="?${value#*\?}"
    value="${value%%\?*}"
  fi
  value=$(echo "$value" | sed -E 's/_wt[0-9]+$//')
  echo "${value}${suffix}${query}"
}

package_script_exists() {
  [ -f package.json ] && node -e "process.exit(require('./package.json').scripts?.['$1'] ? 0 : 1)"
}

install_dependencies

if [ "$worktree_root" = "$main_root" ]; then
  echo "Main checkout: dependencies installed, env left as it is."
  exit 0
fi
worktree_index=$(allocate_worktree_index)

for env_file in "$main_root"/.env "$main_root"/.env.local; do
  [ -f "$env_file" ] && [ ! -f "$worktree_root/$(basename "$env_file")" ] && cp "$env_file" "$worktree_root/"
done
touch .env

set_env_value .env "$PORT_VARIABLE" "$((BASE_PORT + worktree_index))"
if [ -n "$DATABASE_VARIABLE" ]; then
  current_database=$(grep "^${DATABASE_VARIABLE}=" .env | tail -1 | cut -d= -f2- || true)
  if [ -n "$current_database" ]; then
    set_env_value .env "$DATABASE_VARIABLE" "$(worktree_database_value "$current_database")"
    package_script_exists db:reset && "$package_manager" run db:reset
  fi
fi

echo "Worktree $worktree_index: $PORT_VARIABLE=$((BASE_PORT + worktree_index))${DATABASE_VARIABLE:+, own $DATABASE_VARIABLE}."
