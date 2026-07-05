---
name: taskmanager-engine-status
description: Read TaskManager engine status from PROJECT_DIR/.taskmanager/taskmanager.db through the manual wrapper.
---

# Taskmanager Engine Status

Use this skill to inspect an initialized copied TaskManager SQLite engine
database without mutating it.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a read-only manual wrapper operation. It does not enable hooks, register
Codex commands, start background jobs, schedule work, or provide full upstream
TaskManager runtime parity.

## Guardrails

- Run only against the user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Do not create, edit, migrate, or delete TaskManager files.
- Do not infer task health beyond the wrapper output.
- Do not enable or edit hooks.

## Usage

From the repository root:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" status "$PROJECT_DIR"
```

The wrapper prints the project path, database path, schema version, and core
table counts.

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` inspected;
- whether the command exited successfully;
- schema version and table counts shown by the wrapper;
- the exact error if the database is missing or `sqlite3` is unavailable;
- that the operation was read-only.
