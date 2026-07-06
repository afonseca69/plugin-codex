---
name: taskmanager-lite
description: Decompose a PRD, feature, or roadmap item into dependency-ordered, verifiable tasks with acceptance criteria and regression checks. Use when planning implementation work in Codex without requiring an active SQLite TaskManager runtime.
---

# Taskmanager Lite

This is a Codex-native planning workflow, not the full upstream SQLite
TaskManager runtime.

Upstream TaskManager SQLite engine artifacts are included under
`references/taskmanager-engine/` for schema/query/migration/test reference,
standalone validation, and an explicit manual wrapper. The wrapper lives at
`references/taskmanager-engine/bin/taskmanager-engine.sh` and supports only safe
manual commands: `init`, `status`, `next`, `export-json`, `run-sql-tests`, and
`help`.

The wrapper is not registered as a Codex command, does not enable hooks, does
not auto-run TaskManager, and does not implement the full upstream command set.
Use the database-free planning format below unless the user explicitly asks to
initialize, inspect, export, or test the copied SQLite engine.

For explicit manual wrapper operations, use these first-class Codex skills:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

## Task shape

Each task should have:

- ID;
- title;
- outcome;
- dependencies;
- files/subsystems likely touched;
- acceptance criteria;
- verification command or manual proof;
- regression risk;
- explicit out-of-scope items.

## Planning rules

- Prefer small tasks that can be reviewed and reverted independently.
- Make dependencies explicit.
- Put foundation and safety checks before UI polish.
- Do not mark a task done without evidence.
- For risky tasks, require `maestro-adversarial-verify` before closure.

Useful references:

- `references/planning-question-bank.md` for architecture, stack, API, auth, database,
  frontend, and verification questions.
- `references/prd-to-tasks-example.md` for converting PRD sections and folder docs into
  dependency-ordered task plans without relying on an active SQLite runtime.
- `references/agent-taskmanager.md` for the fuller Codex-native planning persona.
- `references/agent-verifier.md` for acceptance-criteria verification guidance without
  an active SQLite runtime.
- `references/taskmanager-engine/README.md` and `references/taskmanager-engine/USAGE.md`
  for the SQLite schema, migrations, query catalog, copied tests, manual wrapper,
  validation commands, and remaining runtime gaps.

## Output format

```text
Milestone:
Tasks:
  T1 — title
    Outcome:
    Depends on:
    Acceptance criteria:
    Verification:
    Regression risk:
    Out of scope:
Done gate:
```
