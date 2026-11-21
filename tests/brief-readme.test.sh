#!/bin/bash
# The brief skill's README follows the "Skill README shape" in AGENTS.md: a title, then
# What It Does, Usage, and only the optional Output, Requirements and FAQ, in that order.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

readme="$REPO_ROOT/skills/product/brief/README.md"
headings=$(grep -E '^#{1,2} ' "$readme" | sed -E 's/^#+ //')
[ "$(echo "$headings" | sed -n 1p | grep -c .)" -eq 1 ] && [ "$(grep -m1 -E '^#{1,2} ' "$readme" | cut -c1-2)" = "# " ] && pass "starts with a title" || fail "starts with a title"

sections=$(echo "$headings" | sed 1d)
[ "$(echo "$sections" | sed -n 1p)" = "What It Does" ] && [ "$(echo "$sections" | sed -n 2p)" = "Usage" ] && pass "What It Does then Usage" || fail "What It Does then Usage" "$sections"

previous_rank=0
order_ok=1
while IFS= read -r section; do
  rank=0 index=0
  for name in "What It Does" "Usage" "Output" "Requirements" "FAQ"; do
    index=$((index + 1))
    [ "$section" = "$name" ] && rank=$index
  done
  if [ "$rank" -eq 0 ] || [ "$rank" -le "$previous_rank" ]; then order_ok=0; fi
  previous_rank=$rank
done <<<"$sections"
[ "$order_ok" -eq 1 ] && pass "only allowed sections, in the AGENTS.md order" || fail "only allowed sections, in the AGENTS.md order" "$sections"

[ "$failures" -eq 0 ] || exit 1
