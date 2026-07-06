---
name: taskmanager-engine-show
description: Inspect read-only TaskManager engine overview, task, milestone, memory, deferral, verification, and regression views through the manual wrapper.
---

# Taskmanager Engine Show

Use this skill to inspect an initialized copied TaskManager SQLite engine
database through the manual wrapper's read-only `show` command.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a read-only manual wrapper operation. It does not run tasks, update
statuses, write logs, enable hooks, register Codex commands, start background
jobs, schedule work, or provide full upstream TaskManager runtime parity.

## Guardrails

- Run only against the user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Treat all output as visibility only; do not infer permission to mutate state.
- Do not mark tasks started, done, verified, skipped, or blocked.
- Do not create, edit, migrate, or delete TaskManager files.
- Do not enable or edit hooks.

## Usage

From the repository root:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" show "$PROJECT_DIR"
```

Supported views:

```bash
"$ENGINE" show "$PROJECT_DIR" overview
"$ENGINE" show "$PROJECT_DIR" tasks
"$ENGINE" show "$PROJECT_DIR" tasks 50
"$ENGINE" show "$PROJECT_DIR" task T-001
"$ENGINE" show "$PROJECT_DIR" milestones
"$ENGINE" show "$PROJECT_DIR" memories
"$ENGINE" show "$PROJECT_DIR" deferrals
"$ENGINE" show "$PROJECT_DIR" verifications
"$ENGINE" show "$PROJECT_DIR" verifications T-001
"$ENGINE" show "$PROJECT_DIR" regressions
"$ENGINE" show "$PROJECT_DIR" regressions T-001
```

`tasks`, `milestones`, `memories`, and `deferrals` accept an optional numeric
limit. The default is `20`; the wrapper rejects limits over `100`.

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` inspected;
- which `show` view ran;
- whether the wrapper exited successfully;
- the relevant overview counts, task, memory, verification, regression, or
  deferral rows shown by the wrapper;
- any wrapper error if the database, `sqlite3`, requested task, or requested
  view is unavailable;
- that the operation was read-only and did not execute or update tasks.
