# TaskManager Engine Wrapper Usage

`bin/taskmanager-engine.sh` is a manual, opt-in Bash wrapper around the copied
TaskManager SQLite artifacts in this directory.

It is not registered as a Codex command, does not run automatically, does not
enable hooks, and does not start background work.

The plugin also includes first-class Codex skills for these manual wrapper
operations:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

Those skills are operator guides for this wrapper. They do not add hidden
runtime behavior or full upstream TaskManager command parity.

## Requirements

- `sqlite3` on `PATH`.
- Bash.

## Commands

Run from any directory:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh help
```

Initialize a project-local SQLite state directory:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh init /path/to/project
```

This creates:

```text
/path/to/project/.taskmanager/
  config.json
  logs/
  taskmanager.db
```

`init` refuses to overwrite an existing `.taskmanager/taskmanager.db`.

Read status:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh status /path/to/project
```

Show the next available tasks from `v_next_task` without mutating data:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh next /path/to/project
```

Print a JSON export of core tables without mutating data:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh export-json /path/to/project
```

Run the copied SQL validation suites from this artifact directory:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh run-sql-tests
```

## Safety Limits

- Writes are limited to `PROJECT_DIR/.taskmanager/` for `init`.
- `status`, `next`, and `export-json` are read-only.
- `run-sql-tests` delegates to the copied test scripts, which use disposable
  `mktemp` directories.
- The wrapper does not implement upstream TaskManager `plan`, `run`, `verify`,
  `show`, `update`, `memory`, or `research` command behavior.
- Full upstream TaskManager runtime parity is not claimed.
