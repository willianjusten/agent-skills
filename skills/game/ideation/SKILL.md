---
name: ideation
description: Interviews the user in numbered rounds, each with a recommended answer, to turn a vague game or creative-piece idea into a one-page pitch they approve, before any brief or code. Use when someone has only a spark of an idea, asks to brainstorm or ideate a game or piece, wants alternative concepts, a core loop or core verb tested, a comparison with similar games, a scope check, or a toy-first prototype of the core interaction.
metadata:
  scope: personal
---

# Ideation

Strengthen the idea before anyone specifies it. The output is one page, `PITCH.md`, engine-neutral, that a brief can be written from without asking again.

## Steps

1. **Pick the mode.** A game (has goals, failure, a loop) or a piece (a feeling and a response to input, no win state). Infer it when the idea says so (a win state or failure means game; "no win state" means piece) and state it in one line; if unclear, ask once with a recommendation. Done when the mode is stated.
2. **Run rounds.** Ask three to five numbered questions per round (a round may merge topics, or cover a short topic such as the directions with three questions), each with your recommended answer and a one-line reason; the user can reply "1 yes, 2 no". If a grilling skill is installed, use it for the questioning; otherwise follow this pattern yourself. Never ask what you can infer or read from the repo, and skip a round the idea already settles (say so in one line). If the user rejects a recommendation, record their answer, ask one short why as the first line of the same or next round (not a round of its own; skip it when they already gave the reason), revise any later recommendation that depended on it, and move on without re-arguing. Done when the round's topic is settled.
3. **Game mode, in order**, each method in its reference:
   - Two or three divergent concepts, one pick: [references/divergent-concepts.md](references/divergent-concepts.md)
   - Player fantasy, feeling back to mechanics: [references/mda.md](references/mda.md)
   - Core verb and verb test, then the loop at 30 seconds, 5 minutes and a session: [references/core-loop.md](references/core-loop.md)
   - Twist against the closest comparable games, and a scope check: [references/forcing-questions.md](references/forcing-questions.md)
   - Optional toy-first round, only if the verb is unproven: [references/toy-first.md](references/toy-first.md). If code is off limits or the user declines, record it as an open question.
   - A "Not this" round: five or more concrete defaults to avoid, each checkable by looking at a frame.

   Done when each method's output is noted for the pitch.
4. **Piece mode:** run the rounds in [references/piece-mode.md](references/piece-mode.md). Skip the game-only rounds and any round the idea already settles. If the user asked for alternative concepts, the directions round is where they go (two or three, one picked).
5. **Write the pitch.** Use [references/pitch-template.md](references/pitch-template.md) and save `PITCH.md` in the target folder. Sections that do not apply to the mode are written as `n/a`. Done when no placeholder text remains (except the empty "Approved by" line) and it fits one page.
6. **Hand over.** Show the pitch and ask for approval or changes. Do not write a GDD, treatment or code. State that the pitch is ready to be turned into a brief if a brief skill is installed. Done when the user has approved; then fill the `Approved by` line with their name and the date (only the user's own approval counts, never an assumed one). If they list changes, return to the step the change touches and rewrite the pitch.

## Rules

- Both modes need a "Not this" list of at least five items and at most three open questions.
- No engine, library or API names in the pitch.
- Offer divergence before depth: never deepen the first idea that was said.
- A toy-first prototype is throwaway and has no goal, score or UI.
- Record rejected concepts in one line each in the pitch, so they are not re-proposed.
