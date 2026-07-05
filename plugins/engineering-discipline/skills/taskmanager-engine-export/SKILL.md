---
name: taskmanager-engine-export
description: Export JSON-style core TaskManager engine data through the read-only manual wrapper.
---

# Taskmanager Engine Export

Use this skill to print JSON-style core data from an initialized copied
TaskManager SQLite engine database.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a read-only manual wrapper operation unless the user explicitly asks to
redirect output to a file. It does not enable hooks, register Codex commands,
start background jobs, schedule work, or provide full upstream TaskManager
runtime parity.

## Guardrails

- Run only against the user-requested `PROJECT_DIR`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Do not write an export file unless the user requested an output path.
- If redirecting output, write only to the user-directed path and report it.
- Do not create, edit, migrate, or delete TaskManager data.
- Do not enable or edit hooks.

## Usage

Print to stdout from the repository root:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
"$ENGINE" export-json "$PROJECT_DIR"
```

Write to a user-requested file:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
OUTPUT="/path/requested-by-user/taskmanager-export.json"
"$ENGINE" export-json "$PROJECT_DIR" > "$OUTPUT"
```

Optional JSON validation for a redirected file:

```bash
python3 -m json.tool "$OUTPUT" >/dev/null
```

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` inspected;
- whether output was printed or redirected;
- the output file path if one was requested;
- whether JSON validation was run and its result;
- any wrapper error if JSON SQLite functions, the database, or `sqlite3` are
  unavailable;
- that TaskManager data was not mutated.
