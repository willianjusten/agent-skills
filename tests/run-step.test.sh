#!/bin/bash
# Tests for run_state.py step and profile: the one next action a conductor takes,
# and what an app's kind (game or experiment) changes in the run.

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SCRIPT="$REPO_ROOT/skills/orchestration/conduct/scripts/run_state.py"
. "$(dirname "$0")/lib.sh"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
state() { python3 -I "$SCRIPT" "$@"; }
first_line() { "$@" 2>&1 | head -1; }
expect() {
  local description="$1" expected="$2" actual
  shift 2
  actual=$(first_line "$@")
  [ "$actual" = "$expected" ] && pass "$description" || fail "$description" "expected '$expected', got '$actual'"
}
new_app() {
  # new_app <category> <name> [app.json extra]: an app folder with an app.json and an empty RUN.md
  local dir="$work/apps/$1/$2"
  mkdir -p "$dir/src"
  echo "{\"title\": \"$2\", \"category\": \"$1\"${3:+, $3}}" >"$dir/app.json"
  : >"$dir/RUN.md"
  echo "$dir"
}
log() { echo "- $1 | $2 | $3" >>"$app/RUN.md"; }

# profile: the kind comes from app.json, then a kind= override
app=$(new_app games glide '"trailer": {"seconds": 30}')
log 2026-11-19T01:00:00Z start "pitch=PITCH.md"
expect "a game's profile" "kind=game process=standard brief=GDD.md art-bible=yes motion-every-round=no game-rows=yes sound-row=no trailer=yes" state profile "$app/RUN.md"
touch "$app/src/sounds.ts"
expect "a game with src/sounds.ts gets a sound row" "kind=game process=standard brief=GDD.md art-bible=yes motion-every-round=no game-rows=yes sound-row=yes trailer=yes" state profile "$app/RUN.md"
viz=$(new_app experiments particles)
app=$viz
log 2026-11-19T01:00:00Z start "pitch=PITCH.md"
expect "an experiment's profile judges motion every round and has no game rows" "kind=experiment process=standard brief=TREATMENT.md art-bible=yes motion-every-round=yes game-rows=no sound-row=no trailer=no" state profile "$app/RUN.md"
log 2026-11-19T01:00:01Z budget "kind=game process=minimal"
expect "kind= and process= override" "kind=game process=minimal brief=GDD.md art-bible=no motion-every-round=no game-rows=yes sound-row=no trailer=no" state profile "$app/RUN.md"
odd="$work/loose/RUN.md"; mkdir -p "$work/loose"; echo "- 2026-11-19T01:00:00Z | start | pitch=P" >"$odd"
case "$(first_line state profile "$odd")" in kind=game*) pass "no app.json means a game";; *) fail "no app.json means a game" "$(state profile "$odd")";; esac

# step walks the phases in order and checks each one's artifact
app=$(new_app experiments drift)
expect "an empty RUN.md is a start" "start" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T01:00:00Z start "pitch=PITCH.md"
expect "after start the brief begins" "phase: brief | done when TREATMENT.md exists" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T01:01:00Z phase brief
expect "inside a phase it keeps working" "work: brief | done when TREATMENT.md exists" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
touch "$app/TREATMENT.md"
expect "the brief file moves it to the art bible" "phase: art-bible | done when ART-BIBLE.md exists" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
touch "$app/ART-BIBLE.md"
expect "then the first look" "phase: first-playable | done when a checkpoint | baseline line is logged" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T01:30:00Z checkpoint "baseline | verify"
expect "then the look variants" "phase: look-variants | done when the look is chosen (run_state.py look)" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T01:31:00Z phase look-variants
log 2026-11-19T01:32:00Z stop "look-variants | pick one of variants=dusk,neon,noon | p"
expect "a pending stop waits" "wait: look-variants" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:00:00Z answer "neon, less bloom"
expect "an answer resumes" "resume: look-variants | neon, less bloom" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:01:00Z resume "from look-variants"
expect "a chosen look moves on to the checklist" "phase: checklist | done when COMPONENTS.md exists and rows are declared" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:02:00Z phase checklist
touch "$app/COMPONENTS.md"
expect "COMPONENTS.md alone is not enough" "work: checklist | done when COMPONENTS.md exists and rows are declared" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:03:00Z row "particles | turn 0 | score -/- of target 8 | pending | approach: none"
log 2026-11-19T02:03:00Z row "bloom | turn 0 | score -/- of target 8 | pending | approach: none"
expect "rows declared: polish begins" "phase: polish | done when every row is at target, the budget is spent or reserved, or the user answers deliver or trailer" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:04:00Z phase polish
expect "the first round after the baseline is light, with accepts allowed and the never-worked rows" "round: 1 | tier=light | accepts=yes | motion-every-round=yes | rows: particles, bloom" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:05:00Z round-start "1 | branch=r1 base=abc"
log 2026-11-19T02:40:00Z round "1 | particles"
log 2026-11-19T02:40:00Z row "particles | turn 1 | score 6/6 of target 8 | kept | approach: curl noise"
expect "review mode stops after a round" "stop: round-review | round 1" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T02:41:00Z stop "round-review | round 1 kept | p"
expect "then waits" "wait: round-review" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T03:00:00Z answer "keep"
log 2026-11-19T03:01:00Z resume "from round-review"
expect "a kept round goes on to the next round" "round: 2 | tier=light | accepts=yes | motion-every-round=yes | rows: bloom, particles" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z
log 2026-11-19T03:02:00Z round "2 | bloom"
log 2026-11-19T03:03:00Z stop "round-review | round 2 kept | p"
log 2026-11-19T03:10:00Z answer "deliver"
log 2026-11-19T03:11:00Z resume "from round-review"
expect "answering deliver ends polish; no trailer declared, so deliver" "phase: deliver | done when done is logged" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z

# a skipped phase is caught: no rows means back to the checklist, whatever phase was logged
app=$(new_app games skip)
touch "$app/GDD.md" "$app/ART-BIBLE.md" "$app/COMPONENTS.md"
log 2026-11-19T01:00:00Z start "pitch=P"
log 2026-11-19T01:10:00Z phase first-playable
log 2026-11-19T01:20:00Z phase look-variants
log 2026-11-19T01:30:00Z phase polish
expect "a run that entered polish without rows goes back to the checklist" "phase: checklist | done when COMPONENTS.md exists and rows are declared" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z

# overnight: no round-review stop, reserve ends polish, a declared trailer runs before delivery
app=$(new_app games night '"trailer": {"seconds": 30}')
touch "$app/GDD.md" "$app/ART-BIBLE.md" "$app/COMPONENTS.md"
log 2026-11-19T01:00:00Z start "pitch=P mode=overnight hours=2"
log 2026-11-19T01:01:00Z checkpoint "baseline | verify"
log 2026-11-19T01:02:00Z assumption "look=auto dusk | fits"
log 2026-11-19T01:03:00Z row "glide | turn 0 | score -/- of target 8 | pending | approach: none"
log 2026-11-19T01:04:00Z phase polish
log 2026-11-19T01:30:00Z round "1 | glide"
expect "overnight goes straight on, uncapped accepts" "round: 2 | tier=light | accepts=yes | motion-every-round=no | rows: glide" state step "$app/RUN.md" --now 2026-11-19T01:31:00Z
expect "at the reserve a declared trailer runs" "phase: trailer | done when a trailer row turn is logged or step | trailer round skipped" state step "$app/RUN.md" --now 2026-11-19T02:30:00Z
log 2026-11-19T02:30:00Z phase trailer
log 2026-11-19T02:40:00Z step "trailer round skipped: under 15 minutes left"
expect "then delivery" "phase: deliver | done when done is logged" state step "$app/RUN.md" --now 2026-11-19T02:41:00Z
log 2026-11-19T02:50:00Z phase deliver
log 2026-11-19T02:55:00Z done "delivered"
expect "a done run" "done" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z

# reopen: the leg runs polish again, then the trailer and delivery again
log 2026-11-20T09:00:00Z budget "rounds=2"
log 2026-11-20T09:00:01Z reopen "after done | focus: glide"
expect "a reopened run polishes again, round numbers carry on" "round: 2 | tier=light | accepts=yes | motion-every-round=no | rows: glide" state step "$app/RUN.md" --now 2026-11-20T09:01:00Z
log 2026-11-20T09:30:00Z round "2 | glide"
log 2026-11-20T09:40:00Z round "3 | glide"
expect "the reopened leg's spent rounds lead to its own trailer" "phase: trailer | done when a trailer row turn is logged or step | trailer round skipped" state step "$app/RUN.md" --now 2026-11-20T09:41:00Z

# full process adds the reference judge; minimal skips the art bible
app=$(new_app games full)
touch "$app/GDD.md" "$app/ART-BIBLE.md" "$app/COMPONENTS.md"
log 2026-11-19T01:00:00Z start "pitch=P process=full mode=overnight"
log 2026-11-19T01:01:00Z checkpoint "baseline | verify"
log 2026-11-19T01:02:00Z assumption "look=auto dusk | fits"
log 2026-11-19T01:03:00Z row "glide | turn 1 | score 9/9 of target 8 | kept | approach: x"
log 2026-11-19T01:04:00Z phase polish
expect "every row at target goes to the reference judge with process=full" "phase: reference-judge | done when a step | reference judge line is logged" state step "$app/RUN.md" --now 2026-11-19T01:05:00Z
app=$(new_app experiments quick)
touch "$app/TREATMENT.md"
log 2026-11-19T01:00:00Z start "pitch=P process=minimal"
expect "minimal skips the art bible" "phase: first-playable | done when a checkpoint | baseline line is logged" state step "$app/RUN.md" --now 2026-11-19T03:30:00Z

[ "$failures" -eq 0 ] || exit 1
