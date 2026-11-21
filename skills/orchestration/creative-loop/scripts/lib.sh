#!/bin/bash
# Shared helpers for plan-attempts.sh and start-run.sh. Source it; it runs nothing.

SECONDS_PER_MINUTE=60
SECONDS_PER_HOUR=3600
MAX_ATTEMPTS=3

# format_utc <epoch seconds> <date format>: BSD date (-r) first, GNU date (-d) as the fallback.
format_utc() {
  date -u -r "$1" "+$2" 2>/dev/null || date -u -d "@$1" "+$2"
}

# attempt_letter <1..MAX_ATTEMPTS>: 1 -> a, 2 -> b, 3 -> c
attempt_letter() {
  local alphabet=abcdefghijklmnopqrstuvwxyz
  echo "${alphabet:$(($1 - 1)):1}"
}

# option_value <option> <argument count left>: stops with exit 2 when an option has no value.
option_value() {
  if [ "$2" -lt 2 ]; then echo "$1 needs a value" >&2; exit 2; fi
}
