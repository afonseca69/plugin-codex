---
name: maestro-deep-analysis
description: Perform a deep, evidence-backed audit of a repository, subsystem, or architecture before risky implementation. Use for brownfield unknowns, repeated regressions, unclear foundations, or broad modernization planning.
---

# Maestro Deep Analysis

Use this skill for read-heavy investigation before implementation. The goal is a truthful, evidence-backed map of the system and a roadmap of small, safe follow-up slices.

## Rules

- Read real code, config, tests, and docs before describing behavior.
- Separate confirmed facts from inferences.
- Prefer direct artifacts over summaries.
- Do not mutate production code unless the user explicitly asks for implementation.
- Record uncertainty instead of filling gaps with confident guesses.
- Prioritize findings by impact, reversibility, and verification confidence.

## Review areas

Cover the relevant subset:

- architecture and module boundaries;
- data model, ownership, and migrations;
- authorization and permissions;
- lifecycle/state-machine behavior;
- test coverage and missing regression checks;
- external integrations, queues, schedulers, and runtime configuration;
- deployment and restart assumptions;
- documentation drift;
- high-risk areas such as auth, billing, data deletion, tenant isolation, and public APIs.

## Process

1. Define the audit scope and non-goals.
2. Read `AGENTS.md`, `README.md`, and relevant `docs/`.
3. Inspect the repository tree and recent git history.
4. Identify subsystem entry points, callers, tests, and configuration.
5. Build an evidence table: claim, file/line or command evidence, confidence, risk.
6. Challenge the findings with a refute-first pass.
7. Produce a prioritized roadmap.

Useful references:

- `references/audit-plan-template.md` for area planning, reader schema, refute pass,
  synthesis, and publish flow.
- `references/output-structure.md` for the `docs/deep-analysis/` publishing contract.

## Output

Use this structure:

```text
Scope:
Executive summary:
Confirmed facts:
Findings:
  F1 — title
    Evidence:
    Impact:
    Confidence:
    Recommended fix:
    Verification:
Roadmap:
  P0/P1/P2 slices:
Open questions:
What not to change yet:
```

Do not call a finding “verified” unless it is backed by a concrete artifact or command output.
