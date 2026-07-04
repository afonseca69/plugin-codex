---
name: architect-refine
description: "Evolve an existing architecture through scoped docs and ADR changes, preserving history and verifying the design delta adversarially."
---

# Architect Refine

Use this skill when an existing design must change because of a new requirement, a fired
extraction trigger, review findings, or documented drift. This is not initial design; use
`architect-design` when no design of record exists.

## Preconditions

- Read `AGENTS.md`, `README.md`, relevant `docs/`, and current code before editing.
- Confirm `docs/architecture/` or ADRs exist. If not, recommend `architect-design` or
  `scribe-init`.
- Load `scribe-docs-discipline` expectations: docs are product truth, stale docs are
  defects, and durable decisions belong in ADRs.

## Drivers

Frame exactly why the design is changing:

- New or changed PRD requirement under `docs/prd/`.
- A documented extraction trigger has fired, with evidence.
- Findings from `architect-review`, `scribe-verify`, `maestro-deep-analysis`, tests, or
  human review.
- Code and docs disagree, requiring a human-confirmed design update or regression fix.

## Process

1. **Load baseline.** Read `docs/STATUS.md`, architecture files, accepted ADRs, and code
   referenced by the area being changed.
2. **Scope the delta.** Name what must change and what must stay put. Separate one-way
   decisions from reversible implementation details.
3. **Design the evolution.** Update only the affected boundaries, ownership, data model,
   interfaces, and triggers. Build the simplest design that satisfies the driver.
4. **Preserve history.** Supersede old ADRs instead of deleting or rewriting them. Each
   replacement decision gets a new ADR with context, options, decision, consequences, owner,
   date, and trigger to revisit.
5. **Challenge the delta.** Use `maestro-adversarial-verify` or `architect-review` logic to
   attack the changed design: boundary leaks, scale break, irreversible mistake,
   over-engineering, missing trigger, and PRD trace.
6. **Write surviving docs.** Patch architecture docs and ADRs only for claims that survived
   the review. Keep `STATUS.md`, roadmap, and open questions aligned or flag them for
   `scribe-sync`.
7. **Verify.** Run doc checks or tests that prove the architecture still matches code.

## Guardrails

- Do not erase ADR history.
- Do not extract early when the trigger has not actually fired.
- Do not auto-resolve an ADR/code conflict without a human decision.
- Do not turn a focused refinement into a broad redesign.
- Do not claim architecture matches code without evidence.

## Output format

```text
Driver:
Baseline read:
Decisions evolved:
  Superseded:
  Added:
Architecture docs changed:
Adversarial findings:
Verification:
History preserved:
Owed follow-up:
```
