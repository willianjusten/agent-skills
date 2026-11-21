#!/bin/bash
# The game-design skill stays cheap to load: rules files under 500 words, detail
# files under 1500, every file listed in SKILL.md (one hop), and every [n] tag in a
# rules file or its detail file resolves to a source in the detail file's list.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$(dirname "$0")/lib.sh"

skill="$REPO_ROOT/skills/game/game-design"
refs="$skill/references"
rules_cap=500
detail_cap=1500

for file in "$refs"/*.md; do
  name=$(basename "$file")
  words=$(wc -w <"$file" | tr -d ' ')
  case "$name" in
    *-deep.md) cap=$detail_cap ;;
    *) cap=$rules_cap ;;
  esac
  [ "$words" -le "$cap" ] && pass "$name: $words words (cap $cap)" || fail "$name: $words words, over $cap"
  grep -qF "references/$name" "$skill/SKILL.md" && pass "$name: listed in SKILL.md" || fail "$name: not listed in SKILL.md"
done

for rules in "$refs"/*.md; do
  case "$rules" in *-deep.md) continue ;; esac
  topic=$(basename "$rules" .md)
  detail="$refs/$topic-deep.md"
  if [ ! -f "$detail" ]; then fail "$topic: no $topic-deep.md"; continue; fi
  grep -qF "($topic-deep.md)" "$rules" && pass "$topic: rules link their detail file" || fail "$topic: rules do not link $topic-deep.md"

  sources=$(awk '/^## Sources/ { on = 1; next } on && /^## / { exit } on && /^[0-9]+\. / { sub(/\..*/, ""); print }' "$detail")
  count=$(echo "$sources" | grep -c .)
  [ "$sources" = "$(seq 1 "$count")" ] && pass "$topic: sources numbered 1..$count" || fail "$topic: sources not numbered 1..N" "$sources"

  cited=$(cat "$rules" "$detail" | awk '/^## Sources/ { exit } { print }' | grep -oE '\[[0-9]+\]' | tr -d '[]' | sort -u)
  dangling=$(comm -23 <(echo "$cited") <(echo "$sources" | sort -u) | tr '\n' ' ')
  [ -z "${dangling// /}" ] && pass "$topic: every tag resolves" || fail "$topic: tags with no source: $dangling"
  uncited=$(comm -13 <(echo "$cited") <(echo "$sources" | sort -u) | tr '\n' ' ')
  [ -z "${uncited// /}" ] && pass "$topic: every source cited" || fail "$topic: sources never cited: $uncited"
done

for topic in loop difficulty onboarding play-field ui-ux copy feel sound accessibility; do
  [ -f "$refs/$topic.md" ] && pass "topic present: $topic" || fail "topic missing: $topic"
done

[ "$failures" -eq 0 ] || exit 1
