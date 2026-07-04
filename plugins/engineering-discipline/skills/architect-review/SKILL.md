---
name: architect-review
description: "Adversarially review an existing architecture and ADR set, producing read-only findings with evidence and recommended refinements."
---

# Architect Review

Use this skill to pressure-test an existing design before implementation or after drift is
suspected. It is read-only and advisory: report findings; use `architect-refine` to apply
them.

## Preconditions

- Read `AGENTS.md`, `README.md`, and relevant `docs/`.
- Confirm `docs/architecture/` or ADRs exist. If not, recommend `architect-design`.
- Read enough PRD/product context to know what the architecture must serve.

## Review lenses

Apply these lenses independently where possible:

1. **Boundary leaks.** Do modules share tables, state, transactions, or assumptions that
   contradict the documented boundary?
2. **Scale break.** What is the first plausible bottleneck or rewrite point, and is there
   a documented trigger or mitigation?
3. **Irreversible mistakes.** Are data ownership, public contracts, tenancy, auth, money,
   or migration decisions treated casually or missing ADRs?
4. **Over-engineering.** Which component, layer, service, or abstraction lacks a present
   requirement or explicit future trigger?
5. **PRD trace.** Does the design serve the hero flow and launch scope without building
   unrelated machinery?
6. **Trigger quality.** Are extraction/revisit triggers observable, dated or measurable,
   and owned?

## Process

1. **Load the design.** Read architecture docs, accepted ADRs, `STATUS.md`, PRDs, and the
   code paths those docs cite.
2. **Extract atomic claims.** Turn broad design prose into checkable claims.
3. **Refute claims.** Use real evidence: docs locations, `path:line`, call-site searches,
   tests, configs, or runtime behavior. Avoid taste-based findings.
4. **Aggregate findings.** Deduplicate, assign severity by future cost, and record which
   claims survived.
5. **Report only.** Do not edit architecture docs or ADRs in this skill.

## Severity

- `critical`: likely rewrite, data loss, security/auth break, or public contract failure.
- `high`: boundary cannot hold, scale wall is inside the planning horizon, or irreversible
  decision lacks a record.
- `medium`: over-engineering, missing trigger, ADR inconsistency, or important ambiguity.
- `low`: clarity or stale-reference issue with limited implementation risk.

## Output format

```text
Design review: <scope>
Verdict:

| # | Concern | Severity | Evidence | Recommended change |
|---|---|---|---|---|
| 1 | ... | high | docs/... and path:line | ... |

Survived the challenge:
Recommended next step:
```

## Guardrails

- Stay read-only.
- Do not fabricate architecture to critique when no design of record exists.
- Do not mark a finding without evidence.
- Do not collapse an ADR/code conflict into a doc edit; flag it for human resolution.
