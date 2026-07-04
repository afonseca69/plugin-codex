---
name: prd-builder-bugfix
description: "Document a bug fix with reproduction, impact, root cause, fix approach, rollback, and permanent regression coverage."
---

# PRD Builder Bugfix

Use this skill when a bug needs a written fix brief before implementation or when the fix
needs traceability after the fact. The document should explain how to reproduce the bug,
why it happens, how it will be fixed, and how it will never silently return.

## Process

1. **Read context.** Check `AGENTS.md`, issue links, recent commits, logs provided by the
   user, relevant docs, and nearby tests/code.
2. **Capture symptoms.** Record exact behavior, error messages, affected users, severity,
   first-known date, frequency, and environment.
3. **Pin reproduction.** Write precise reproduction steps and expected vs actual behavior.
   If reproduction is intermittent, record known triggers and unknowns.
4. **Analyze root cause.** Identify the suspected component, code path, data state, or
   dependency. Separate confirmed facts from hypotheses.
5. **Define fix approach.** Compare alternatives when useful. Name risk, rollback, and
   impacted areas.
6. **Plan verification.** Require a fix-verification test and a regression test. For risky
   untested behavior, recommend characterization coverage before changing it.
7. **Write the bugfix PRD.** Save to `docs/prd/prd-{slug}.md`.
8. **Handoff.** Use `maestro-implement` for the fix and `maestro-regression` before
   closure.

## Output shape

```text
# Bug Fix: <title>

Summary
- Severity:
- Reported:
- Affected versions / environments:

Problem description
Reproduction steps
Expected vs actual behavior
Impact
Root cause analysis
Fix approach
Files / components likely touched
Testing strategy
Regression coverage
Rollback plan
Related issues / evidence
Open questions
```

## Guardrails

- Do not call a root cause confirmed without evidence.
- Do not skip reproduction unless the bug is truly unreproducible; record that as risk.
- Do not implement the fix while writing the PRD unless the user explicitly switches scope.
- Do not close the bug without a regression check or an explicit residual-risk note.
