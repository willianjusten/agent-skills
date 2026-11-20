#!/bin/bash
# Shared helpers for tests/*.test.sh. Source it after REPO_ROOT is set:
#   . "$(dirname "$0")/lib.sh"
# `fail` counts into `failures`; end each test with `[ "$failures" -eq 0 ] || exit 1`.

failures=0

pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  [ -n "${2:-}" ] && echo "$2" | sed 's/^/       /'
  failures=$((failures + 1))
}

frontmatter() { awk 'NR == 1 { next } /^---$/ { exit } { print }' "$1"; }
field() { frontmatter "$1" | awk -v key="$2" -F': *' '$1 == key { print $2; exit }'; }
meta() { frontmatter "$1" | awk -v key="$2" '$1 == key ":" { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }'; }
scope_of() { frontmatter "$1" | awk '/^metadata:/ { in_meta = 1; next } in_meta && /scope:/ { sub(/.*scope:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); print; exit }'; }
