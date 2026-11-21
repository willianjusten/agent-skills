# Ideation

Interviews you in numbered rounds and ends with a one-page pitch you approve.

## What It Does

```mermaid
flowchart LR
  A[Spark] --> P[Pre-flight] --> B[Divergent concepts]
  B --> C[Fantasy and verb]
  C --> D[Loop and twist]
  D --> E[Scope check]
  E --> F[PITCH.md]
```

| Mode | Rounds | Output |
| ---- | ------ | ------ |
| Game | pre-flight, concepts, player fantasy (MDA), verb test, core loop, twist, scope, optional toy | `PITCH.md` |
| Experiment | pre-flight, feeling, input-to-motion mapping, directions, "Not this" | `PITCH.md` |

## Usage

```text
I have a vague idea for a game about tides, help me shape it
Brainstorm three directions for an interactive experiment about fog
Is the core loop of this game any good?
```

## Output

`PITCH.md` in the target folder.

## FAQ

- Does it write the GDD? No; it hands a pitch to a brief step.
- Is a grilling skill required? No; it follows the same pattern itself.
