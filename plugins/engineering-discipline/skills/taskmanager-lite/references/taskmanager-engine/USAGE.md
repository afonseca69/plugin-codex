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
- `taskmanager-engine-show`
- `taskmanager-engine-memory`
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

Show read-only runtime visibility from overview/detail/list views:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project overview
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project tasks 50
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project task T-001
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project milestones
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project memories
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project deferrals
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project verifications
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project verifications T-001
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show /path/to/project regressions T-001
```

Supported views are `overview`, `tasks [limit]`, `task TASK_ID`,
`milestones [limit]`, `memories [limit]`, `deferrals [limit]`,
`verifications [TASK_ID]`, and `regressions [TARGET_ID]`. The command requires
an explicit project path and opens the database with `sqlite3 -readonly`.

List, show, and search memories without mutating data:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-list /path/to/project
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-list /path/to/project 50
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-show /path/to/project M-001
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-search /path/to/project "database convention"
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-search /path/to/project "database convention" 50
```

`memory-search` prefers the `memories_fts` table when available. If FTS is
unavailable or rejects the query syntax, it falls back to `LIKE` over title,
body, and tags.

Add or deprecate one memory through explicit database mutation:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-add /path/to/project decision "Prefer small PRs" "Keep changes focused and verified." 4 0.9
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-deprecate /path/to/project M-001 "Superseded by current project guidance"
```

`memory-add` validates the memory type, title, body, importance, and confidence,
then inserts one active row with the next `M-NNN` id. `memory-deprecate` sets
`status = 'deprecated'` and never deletes the memory. The current schema has no
clean deprecation-reason field, so the reason argument is validated for operator
intent but not stored.

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
- `status`, `next`, `show`, `memory-list`, `memory-show`, `memory-search`, and
  `export-json` are read-only.
- `memory-add` and `memory-deprecate` write only to
  `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `run-sql-tests` delegates to the copied test scripts, which use disposable
  `mktemp` directories.
- The wrapper does not implement upstream TaskManager `plan`, `run`, `verify`,
  `update`, full `memory`, or `research` command behavior.
- The `show` command is visibility only; it does not execute tasks, update
  status, write verification rows, write logs, or claim upstream `show` parity.
- The memory commands do not run research, auto-classify, update, supersede, or
  reconcile memory conflicts.
- Full upstream TaskManager runtime parity is not claimed.
