---
name: taskmanager-engine-next
description: Show next available TaskManager engine tasks through the read-only manual wrapper.
---

# Taskmanager Engine Next

Use this skill to show rows from `v_next_task` for an initialized copied
TaskManager SQLite engine database.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a read-only manual wrapper operation. It does not run tasks, update
statuses, enable hooks, register Codex commands, start background jobs, or
provide full upstream TaskManager runtime parity.

## Guardrails

- Run only against the user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Treat the output as scheduling information only.
- Do not mark tasks started, done, verified, or skipped.
- Do not enable or edit hooks.

## Usage

From the repository root:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" next "$PROJECT_DIR"
```

If no tasks are available, the wrapper prints:

```text
No next tasks available.
```

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` inspected;
- whether tasks were listed or no next tasks were available;
- the exact wrapper output when useful;
- any wrapper error if `v_next_task`, the database, or `sqlite3` is unavailable;
- that the operation was read-only and did not execute tasks.
