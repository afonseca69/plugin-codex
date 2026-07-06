---
name: taskmanager-engine-init
description: Initialize PROJECT_DIR/.taskmanager with the explicit manual TaskManager engine wrapper.
---

# Taskmanager Engine Init

Use this skill only when the user explicitly asks to initialize the copied
TaskManager SQLite engine for a project.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a manual wrapper. It does not enable hooks, register Codex commands,
start background jobs, schedule work, or provide full upstream TaskManager
runtime parity.

## Guardrails

- Warn before running `init`: it writes only under `PROJECT_DIR/.taskmanager`.
- Resolve the intended `PROJECT_DIR` before running the wrapper.
- If `PROJECT_DIR/.taskmanager` already exists, stop and ask the user before
  proceeding. Do not remove, rename, or overwrite existing files.
- The wrapper refuses an existing `PROJECT_DIR/.taskmanager/taskmanager.db`, but
  still preflight the path so the user sees the overwrite risk before command
  execution.
- Do not initialize outside the user-requested project directory.
- Do not enable or edit hooks as part of initialization.

## Usage

From the repository root:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" init "$PROJECT_DIR"
```

Expected successful output includes:

```text
Initialized TaskManager engine at /path/to/project/.taskmanager
Database: /path/to/project/.taskmanager/taskmanager.db
```

## Validation And Reporting

After a successful init, verify the database path if the user needs proof:

```bash
test -f "$PROJECT_DIR/.taskmanager/taskmanager.db"
```

Report:

- the exact `PROJECT_DIR` used;
- the wrapper command that ran;
- whether `PROJECT_DIR/.taskmanager/taskmanager.db` was created;
- any wrapper stderr/stdout if the command fails;
- that no hooks or automatic runtime behavior were enabled.
