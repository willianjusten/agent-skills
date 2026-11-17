#!/bin/bash
# Tests for install-only vendoring: git tracks one skills-lock.json per source in
# scopes.json, each lock pins every skill to an upstream commit, and the locked
# skills are exactly the ones scopes.json enables.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCOPES="$REPO_ROOT/scopes.json"
failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

# Upstream mattpocock/skills ships `code-review`; install.sh installs it as `matt-code-review`.
installed_name() {
  if [ "$1" = "code-review" ]; then echo "matt-code-review"; else echo "$1"; fi
}

expected_files=$(jq -r 'keys[] | "vendor/\(.)/skills-lock.json"' "$SCOPES" | sort)
tracked_files=$(git -C "$REPO_ROOT" ls-files vendor | sort)
if [ "$tracked_files" = "$expected_files" ]; then
  pass "git tracks only one skills-lock.json per vendored source"
else
  fail "git tracks only one skills-lock.json per vendored source" "$(diff <(echo "$expected_files") <(echo "$tracked_files") | grep '^[<>]' | head -10)"
fi

for source in $(jq -r 'keys[]' "$SCOPES"); do
  lock="$REPO_ROOT/vendor/$source/skills-lock.json"
  if [ ! -f "$lock" ]; then
    fail "$source has a lock file"
    continue
  fi

  if [ "$(jq -r '.version' "$lock")" = "2" ]; then
    pass "$source lock uses the v2 format"
  else
    fail "$source lock uses the v2 format" "found version $(jq -r '.version' "$lock")"
  fi

  unpinned=$(jq -r '.skills | to_entries[] | select((.value.commit // "") | test("^[0-9a-f]{40}$") | not) | .key' "$lock")
  if [ -z "$unpinned" ]; then
    pass "$source lock pins every skill to a commit"
  else
    fail "$source lock pins every skill to a commit" "$unpinned"
  fi

  enabled=$(jq -r --arg source "$source" '.[$source] | to_entries[] | select(.value != "off") | .key' "$SCOPES" | sort)
  locked=$(for name in $(jq -r '.skills | keys[]' "$lock"); do installed_name "$name"; done | sort)
  if [ "$enabled" = "$locked" ]; then
    pass "$source lock holds exactly the skills scopes.json enables"
  else
    fail "$source lock holds exactly the skills scopes.json enables" "$(diff <(echo "$enabled") <(echo "$locked") | grep '^[<>]' | sed 's/^</missing from lock:/; s/^>/not enabled:/')"
  fi
done

# Realtime sources are personal tools; none of their skills may reach Spoke.
for source in bizarro/skills MengTo/Skills greensock/gsap-skills emalorenzo/three-agent-skills scottstts/Threejs-Awesome-Graphics-Agent-Skills; do
  shared=$(jq -r --arg source "$source" '.[$source] // {"(source missing)": "missing"} | to_entries[] | select(.value != "personal" and .value != "off") | "\(.key): \(.value)"' "$SCOPES")
  if [ -z "$shared" ]; then
    pass "$source enables personal skills only"
  else
    fail "$source enables personal skills only" "$shared"
  fi
done

[ "$failures" -eq 0 ] || exit 1
