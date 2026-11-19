# Glossary

Terms used across the skills, agents and harness in this repo.

- **Leaf skill**: a skill that works alone and names no sibling skill in this repo. Most skills are leaves.
- **Orchestrator**: an agent in `agents/` or a skill in `skills/orchestration/` that runs other skills and agents. It may name them; `install.sh check` verifies each one is installed where the orchestrator can see it. See `docs/adr/0001-leaf-and-orchestrator-skills.md`.
- **Pitch**: the one-page concept that ends ideation and that Will approves. Everything after the pitch runs autonomously.
- **Run**: one conductor execution on one app, from pitch to delivery, logged append-only in the app's `RUN.md`. A run can stop and resume.
- **Conductor**: the orchestrator agent that drives a run through its phases.
- **Stop point**: a moment where a run stops, notifies Will and waits: target frames chosen, polish plateau, a split taste call, a gate still failing after two fixes, a budget spent, or any stop the brief adds.
- **Budget**: the limits on a run (polish rounds, wall-clock hours). Spending one is a stop point.
- **Component**: one item of a run's checklist, with a measurable target, the folder it owns and the judge lens that scores it (visual, feel or motion). Polish workers own components.
- **Area**: the fixed polish split (lighting, VFX, props, UI, audio), used only when no component checklist is given.
