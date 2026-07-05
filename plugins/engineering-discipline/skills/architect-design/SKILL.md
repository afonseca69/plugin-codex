---
name: architect-design
description: Design a right-sized architecture before implementing a feature, boundary, data model, integration, or irreversible decision. Use between PRD and tasks, especially for schema, API, auth, or cross-module changes.
---

# Architect Design

Architecture is tradeoffs under constraints, not generic best practices.

## Process

1. Read PRD/requirements and current docs/code.
2. Identify irreversible or expensive-to-change decisions.
3. Define the simplest design that serves the present requirement.
4. Place seams only where there is a concrete future trigger.
5. Specify data ownership, interfaces, lifecycle states, and failure behavior.
6. Challenge the design with `maestro-adversarial-verify` for high-risk changes.
7. Record durable choices as ADRs.

For detailed checklists, use:

- `references/design-heuristics.md` for elicitation, one-way decisions, subtraction,
  adversarial design review, and trigger quality.
- `references/seam-catalog.md` for common cheap-now seams and extraction triggers.
- `references/agent-architect.md` for the fuller Codex-native architect persona
  adapted from the upstream agent prompt.

## Output

Use this structure:

```text
Context
Goals / non-goals
Current constraints
Proposed design
Data model and ownership
Interfaces / contracts
Security and failure behavior
Alternatives considered
Revisit triggers
Implementation slices
Verification plan
```

Avoid speculative platforms, premature abstractions, and hidden migrations.
