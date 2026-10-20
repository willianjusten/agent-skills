#!/bin/bash
# Tests for setup-project's worktree-setup.sh template: the main checkout keeps its
# env, and each worktree gets its own port and database name.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SETUP_SCRIPT="$REPO_ROOT/skills/engineering/setup-project/references/templates/worktree-setup.sh"
FIXTURE_DIR=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$FIXTURE_DIR"' EXIT
failures=0

# Package managers are stubbed so the test needs no network and records what ran.
mkdir -p "$FIXTURE_DIR/bin"
for stub in npm pnpm yarn bun; do
  printf '#!/bin/bash\necho "%s $*" >>"%s/calls.log"\n' "$stub" "$FIXTURE_DIR" >"$FIXTURE_DIR/bin/$stub"
  chmod +x "$FIXTURE_DIR/bin/$stub"
done
export PATH="$FIXTURE_DIR/bin:$PATH"

# expect <name> <expected> <actual>
expect() {
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected '$2', got '$3'"
    failures=$((failures + 1))
  fi
}

main_checkout="$FIXTURE_DIR/app"
mkdir -p "$main_checkout/scripts"
cd "$main_checkout" || exit 1
git init -q -b main
cp "$SETUP_SCRIPT" scripts/worktree-setup.sh
printf '{"scripts":{"db:reset":"echo reset"}}\n' >package.json
touch pnpm-lock.yaml
printf '.env\n' >.gitignore
printf 'PORT=3000\nDATABASE_URL="postgres://user@localhost:5432/app?schema=public"\nOTHER=kept\n' >.env
git add -A && git -c user.name=t -c user.email=t@t commit -qm init

bash scripts/worktree-setup.sh >/dev/null
expect "main checkout keeps its env" "$(printf 'PORT=3000\nDATABASE_URL="postgres://user@localhost:5432/app?schema=public"\nOTHER=kept')" "$(cat .env)"
expect "main checkout installs with the lockfile's manager" "pnpm install --frozen-lockfile" "$(tail -1 "$FIXTURE_DIR/calls.log")"

git worktree add -q "$FIXTURE_DIR/app-one" -b one
git worktree add -q "$FIXTURE_DIR/app two" -b two
(cd "$FIXTURE_DIR/app-one" && bash scripts/worktree-setup.sh >/dev/null)
(cd "$FIXTURE_DIR/app two" && bash scripts/worktree-setup.sh >/dev/null)

expect "first worktree gets port 3001" "PORT=3001" "$(grep '^PORT=' "$FIXTURE_DIR/app-one/.env")"
expect "second worktree, path with a space, gets port 3002" "PORT=3002" "$(grep '^PORT=' "$FIXTURE_DIR/app two/.env")"
expect "database URL gets a suffix before the query" "DATABASE_URL=postgres://user@localhost:5432/app_wt1?schema=public" "$(grep '^DATABASE_URL=' "$FIXTURE_DIR/app-one/.env")"
expect "other env values are copied" "OTHER=kept" "$(grep '^OTHER=' "$FIXTURE_DIR/app-one/.env")"
expect "db:reset runs once per worktree, never in main" "2" "$(grep -c 'pnpm run db:reset' "$FIXTURE_DIR/calls.log")"

(cd "$FIXTURE_DIR/app-one" && bash scripts/worktree-setup.sh >/dev/null)
expect "a second run does not stack suffixes" "DATABASE_URL=postgres://user@localhost:5432/app_wt1?schema=public" "$(grep '^DATABASE_URL=' "$FIXTURE_DIR/app-one/.env")"

git worktree remove --force "$FIXTURE_DIR/app-one"
git worktree add -q "$FIXTURE_DIR/app-three" -b three
(cd "$FIXTURE_DIR/app-three" && bash scripts/worktree-setup.sh >/dev/null)
expect "a removed worktree's port is reused" "PORT=3001" "$(grep '^PORT=' "$FIXTURE_DIR/app-three/.env")"
expect "existing worktrees keep their port" "PORT=3002" "$(grep '^PORT=' "$FIXTURE_DIR/app two/.env")"

if [ "$failures" -gt 0 ]; then
  echo "$failures failure(s)"
  exit 1
fi
