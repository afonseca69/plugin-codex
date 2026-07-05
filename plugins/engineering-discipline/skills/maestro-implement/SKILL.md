---
name: maestro-implement
description: Implement a feature, fix, refactor, or code change in Codex with disciplined intake, investigation, planning, building, verification, docs, and honest delivery. Use for non-trivial repository mutations.
---

# Maestro Implement

Follow `references/process.md` for the full process. Compress it for trivial work; expand it for risky work.
For a focused one-task implementer stance, use `references/agent-implementer.md`.

## Operating rules

- Read before asking; ask only decision-changing questions.
- Build exactly the requested scope. Surface adjacent work; do not bundle it silently.
- Match the repository's existing idioms.
- Tests must be able to fail if the change is reverted.
- Do not weaken tests to pass.
- Update docs when behavior, commands, workflows, or constraints change.
- Report what changed, how it was verified, and what was deliberately left out.

## When to pause

Pause and ask or report if you encounter:

- hidden schema/data migration needs;
- auth/permission implications not in scope;
- external service calls or secret handling;
- destructive commands;
- unclear product behavior;
- a failing unrelated baseline that blocks honest verification.

## Delivery contract

A finished implementation must include:

- code or docs change aligned to the ask;
- relevant validation output or an explicit reason validation could not run;
- updated docs if behavior changed;
- a short risk note for migrations, deploy, runtime restart, or data effects.
