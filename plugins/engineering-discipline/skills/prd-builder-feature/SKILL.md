---
name: prd-builder-feature
description: "Create a focused PRD for a feature inside an existing product, emphasizing integration, lean scope, acceptance criteria, and verification."
---

# PRD Builder Feature

Use this skill for a new feature in an existing product. It is lighter than a full product
PRD but keeps the same discipline around scope, decisions, integration, and verification.

## Process

1. **Read current product context.** Inspect `AGENTS.md`, `README.md`, `docs/STATUS.md`,
   current PRDs, roadmap, architecture docs, and nearby code when relevant.
2. **Capture the feature.** State the one-line feature thesis and the key user flow that
   proves the feature works.
3. **Keep v1 narrow.** Include only the work needed for that flow. Move extras to a
   deferred list with a reason.
4. **Interview selectively.** Cover:
   - user need and current workaround;
   - target users and frequency;
   - core behavior, edge cases, and out-of-scope items;
   - integration points and affected components;
   - UX placement for UI-facing work;
   - risks, rollout, acceptance criteria, and regression checks.
5. **Review the draft.** Subtract unnecessary feature surface first, then challenge the
   implementation shape for dependencies, ownership, and testability.
6. **Write the final PRD.** Save to `docs/prd/prd-{slug}.md`.
7. **Handoff.** Recommend `architect-design` only when the feature changes architecture,
   data ownership, public contracts, auth, billing, or other expensive-to-change behavior.
   Otherwise move to `taskmanager-lite`.

## Output shape

```text
Feature thesis:
Key flow:
Problem / user need:
Launch scope:
Out of scope:
Requirements:
Acceptance criteria:
Integration points:
UX notes:
Risks:
Testing and regression plan:
Decisions:
Open questions:
```

## Guardrails

- Prefer the host product's existing stack and patterns.
- Do not add third-party packages without a dependency decision.
- Do not expand the feature into a product rewrite.
- Do not save intermediate critique notes; write the final PRD only.
