# Architecture

<Two or three sentences: what the system does and how a request or user action flows through it.>

## Modules

Describe each module by the capability it owns, not by where it lives. An agent finds the files; it cannot find the intent.

| Module | Owns | May import |
| ------ | ---- | ---------- |
| <ui> | <screens and components; no data access> | <domain> |
| <domain> | <business rules; pure, no framework code> | <nothing> |
| <data> | <persistence and external APIs> | <domain> |

## Boundaries

<Each rule above that a lint rule enforces, named once. A boundary nobody checks belongs in a ticket to add the check, not here.>
