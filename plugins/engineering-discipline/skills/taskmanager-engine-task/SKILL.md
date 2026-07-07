---
name: taskmanager-engine-task
description: Run safe manual TaskManager task add, status, title, and soft archive operations through the explicit wrapper.
---

# Taskmanager Engine Task

Use this skill only when the user explicitly asks to manually mutate tasks in an
initialized copied TaskManager SQLite engine database.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a manual wrapper around copied SQLite artifacts. It does not enable
hooks, register Codex commands, start background jobs, run tasks, verify tasks,
perform research, or provide full upstream TaskManager runtime parity.

## Mutating Commands

These commands write only to `PROJECT_DIR/.taskmanager/taskmanager.db` and only
when explicitly invoked:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" task-add "$PROJECT_DIR" 1 "Parent task" feature planned
"$ENGINE" task-add "$PROJECT_DIR" 1.1 "Child task" task planned 1
"$ENGINE" task-set-status "$PROJECT_DIR" 1.1 in-progress
"$ENGINE" task-update-title "$PROJECT_DIR" 1.1 "Child task updated"
"$ENGINE" task-archive "$PROJECT_DIR" 1.1
```

`task-add` requires an explicit task id and title. Optional `TYPE`, `STATUS`,
and `PARENT_ID` default to `feature`, `planned`, and no parent. Stored task
types remain constrained by the schema: `feature`, `bug`, `chore`, `analysis`,
or `spike`. The wrapper accepts generic input type `task` as an alias for the
schema default `feature`.

`task-set-status` validates the task exists and the status is one of `draft`,
`planned`, `in-progress`, `blocked`, `paused`, `done`, `canceled`, `duplicate`,
or `needs-review`. Entering `in-progress` sets `started_at` if it is empty.
Entering `done` sets `completed_at` if it is empty. Moving away from `done`
preserves `completed_at`; the wrapper does not silently erase completion
history.

`task-update-title` validates the task exists, then updates only `title` and
`updated_at`.

`task-archive` is a soft archive only. It sets `archived_at` and `updated_at`
without deleting the row.

## Guardrails

- Require an explicit user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Treat every command in this skill as mutating.
- Validate task ids conservatively before writes.
- Refuse duplicate task ids.
- Require a parent task to exist when `PARENT_ID` is provided.
- Do not delete tasks.
- Do not cascade parent statuses. The current schema has views, not triggers,
  for task rollups.
- Do not write verification rows, regression rows, memories, logs, repository
  source files, or hook files as part of these commands.
- Do not implement upstream `plan`, `run`, `verify`, `update`, `research`, or
  full `memory` workflows through this skill.

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` used;
- that the operation was mutating;
- the command that ran;
- for `task-add`, the created task id;
- for `task-set-status`, the task id and new status;
- for `task-update-title`, the task id;
- for `task-archive`, the archived task id and that it was a soft archive;
- any wrapper validation failure, missing database, missing `sqlite3`, duplicate
  task id, invalid status/type, or missing parent;
- that full upstream TaskManager runtime parity is not claimed.
