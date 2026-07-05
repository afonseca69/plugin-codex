---
name: taskmanager-lite
description: Decompose a PRD, feature, or roadmap item into dependency-ordered, verifiable tasks with acceptance criteria and regression checks. Use when planning implementation work in Codex without requiring the upstream SQLite taskmanager.
---

# Taskmanager Lite

This is a Codex-native planning workflow, not the full upstream SQLite taskmanager engine.

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
  dependency-ordered task plans without the upstream SQLite engine.
- `references/agent-taskmanager.md` for the fuller Codex-native planning persona.
- `references/agent-verifier.md` for acceptance-criteria verification guidance without
  the upstream SQLite engine.

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
