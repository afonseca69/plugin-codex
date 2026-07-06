---
name: taskmanager-engine-memory
description: Run safe manual TaskManager memory list, show, search, add, and deprecate operations through the explicit wrapper.
---

# Taskmanager Engine Memory

Use this skill only when the user explicitly asks to inspect or manually mutate
memories in an initialized copied TaskManager SQLite engine database.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a manual wrapper around copied SQLite artifacts. It does not enable
hooks, register Codex commands, start background jobs, run tasks, perform web
research, auto-classify memories, reconcile conflicts, or provide full upstream
TaskManager memory/runtime parity.

## Read-only Commands

These commands open `PROJECT_DIR/.taskmanager/taskmanager.db` read-only and must
not mutate TaskManager state:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" memory-list "$PROJECT_DIR"
"$ENGINE" memory-list "$PROJECT_DIR" 50
"$ENGINE" memory-show "$PROJECT_DIR" M-001
"$ENGINE" memory-search "$PROJECT_DIR" "database convention"
"$ENGINE" memory-search "$PROJECT_DIR" "database convention" 50
```

`memory-search` prefers the copied `memories_fts` table when available. If FTS is
unavailable or rejects the query syntax, the wrapper falls back to `LIKE` over
memory title, body, and tags.

## Mutating Commands

These commands write only to `PROJECT_DIR/.taskmanager/taskmanager.db` and only
when explicitly invoked:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" memory-add "$PROJECT_DIR" decision "Prefer small PRs" "Keep changes focused and verified." 4 0.9
"$ENGINE" memory-deprecate "$PROJECT_DIR" M-001 "Superseded by current project guidance"
```

`memory-add` validates the memory type, title, body, importance, and confidence,
then inserts one active memory row. It generates the next `M-NNN` id and relies
on the existing schema triggers to update FTS.

`memory-deprecate` validates the memory id and reason, then sets
`status = 'deprecated'` without deleting the row. The current schema has a
status field but no clean deprecation-reason field, so the wrapper reports that
the reason is not stored instead of overloading unrelated fields.

## Guardrails

- Require an explicit user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Treat `memory-list`, `memory-show`, and `memory-search` as visibility only.
- Warn that `memory-add` and `memory-deprecate` mutate the database before using
  them on user-owned state.
- Do not delete memories.
- Do not fake supersession or deprecation metadata when the schema lacks a clean
  field for it.
- Do not run research, web searches, automatic classification, or conflict
  resolution as part of these commands.
- Do not enable or edit hooks.

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` used;
- whether the operation was read-only or mutating;
- the command that ran;
- for `memory-add`, the created memory id;
- for `memory-deprecate`, the deprecated memory id and the schema limitation for
  reason storage;
- any wrapper validation failure, missing database, missing `sqlite3`, or
  missing memory id;
- that full upstream TaskManager memory/research/runtime parity is not claimed.
