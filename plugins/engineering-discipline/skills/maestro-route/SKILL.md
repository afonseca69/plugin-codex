---
name: maestro-route
description: Classify a coding or engineering request by risk and size, then recommend the smallest safe Codex workflow before edits begin. Use for vague asks, bug fixes, features, audits, refactors, or when the user asks where to start.
---

# Maestro Route

Use this skill before acting on a non-trivial engineering request.

## Goal

Choose the smallest safe workflow. Do not over-process trivial work, and do not let risky work start without investigation.

## Lanes

1. **Lookup / answer only** — no repository mutation. Read enough to answer with evidence.
2. **Trivial change** — one or two files, low risk, obvious verification.
3. **Standard implementation** — bounded feature/fix requiring investigation, tests, and docs updates.
4. **High-risk / architecture-affecting** — auth, money, security, data loss, migrations, public APIs, cross-module behavior, or unclear blast radius. Use design/adversarial verification first.
5. **Deep analysis** — broad audit, unknown subsystem, repeated regressions, or unclear foundation. Use `maestro-deep-analysis`.

## Routing checklist

- Restate the outcome in one sentence.
- Identify files/subsystems likely involved.
- Identify irreversible risks: schema, data deletion, auth, payments, external calls, deployment, concurrency, security.
- Read `AGENTS.md` and relevant `docs/` before asking questions.
- Ask only questions whose answers change what gets built.
- Recommend one lane and one next skill.

## Output format

Return:

- **Lane:** one of the five lanes above.
- **Why:** concise evidence-based reason.
- **Next:** skill/workflow to use.
- **Guardrails:** what must not be touched without explicit approval.
- **Verification:** tests/checks expected before delivery.
