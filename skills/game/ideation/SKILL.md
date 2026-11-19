---
name: ideation
description: Interviews the user in numbered rounds, each with a recommended answer, to turn a vague game or creative-piece idea into a one-page pitch they approve, before any brief or code. Use when someone has only a spark of an idea, asks to brainstorm or ideate a game or piece, wants alternative concepts, a core loop or core verb tested, a comparison with similar games, a scope check, or a toy-first prototype of the core interaction.
metadata:
  scope: personal
---

# Ideation

Strengthen the idea before anyone specifies it. The output is one page, `PITCH.md`, engine-neutral, that a brief can be written from without asking again.

## Steps

1. **Pick the mode.** A game (has goals, failure, a loop) or a piece (a feeling and a response to input, no win state). If unclear, ask once. Done when the mode is stated.
2. **Run rounds.** Ask three to five numbered questions per round, each with your recommended answer and a one-line reason; the user can reply "1 yes, 2 no". If a grilling skill is installed, use it for the questioning; otherwise follow this pattern yourself. Never ask what you can infer or read from the repo, and skip a round the idea already settles (say so in one line). If the user rejects a recommendation, record their answer, ask one short why, and move on without re-arguing. Done when the round's topic is settled.
3. **Game mode, in order**, each method in its reference:
   - Two or three divergent concepts, one pick: [references/divergent-concepts.md](references/divergent-concepts.md)
   - Player fantasy, feeling back to mechanics: [references/mda.md](references/mda.md)
   - Core verb and verb test, then the loop at 30 seconds, 5 minutes and a session: [references/core-loop.md](references/core-loop.md)
   - Twist against the closest comparable games, and a scope check: [references/forcing-questions.md](references/forcing-questions.md)
   - Optional toy-first round, only if the verb is unproven: [references/toy-first.md](references/toy-first.md)
4. **Piece mode:** run the five rounds in [references/piece-mode.md](references/piece-mode.md) (feeling, where and how, input to motion, directions, scope, and a "Not this" list of at least five items). Skip the game-only rounds.
5. **Write the pitch.** Use [references/pitch-template.md](references/pitch-template.md) and save `PITCH.md` in the target folder. Sections that do not apply to the mode are written as `n/a`. Done when no placeholder text remains (except the empty "Approved by" line) and it fits one page.
6. **Hand over.** Show the pitch and ask for approval or changes. Do not write a GDD, treatment or code. State that the pitch is ready to be turned into a brief if a brief skill is installed. Done when the user has approved or listed changes.

## Rules

- Both modes need a "Not this" list of at least five items and at most three open questions.
- No engine, library or API names in the pitch.
- Offer divergence before depth: never deepen the first idea that was said.
- A toy-first prototype is throwaway and has no goal, score or UI.
- Record rejected concepts in one line each in the pitch, so they are not re-proposed.
