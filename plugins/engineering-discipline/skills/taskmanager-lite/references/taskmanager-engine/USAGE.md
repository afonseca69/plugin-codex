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
- `taskmanager-engine-task`
- `taskmanager-engine-memory`
- `taskmanager-engine-plan`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

Those skills are operator guides for this wrapper. They do not add hidden
runtime behavior or full upstream TaskManager command parity.

## Requirements

- `sqlite3` on `PATH`.
- Bash.
- `python3` on `PATH` for the manual `plan-*` payload commands.

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

Add or update one task through explicit database mutation:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-add /path/to/project 1 "Parent task" feature planned
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-add /path/to/project 1.1 "Child task" task planned 1
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-set-status /path/to/project 1.1 in-progress
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-update-title /path/to/project 1.1 "Child task updated"
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-archive /path/to/project 1.1
```

`task-add` requires an explicit `TASK_ID` and `TITLE`, refuses duplicate ids,
validates parent existence when `PARENT_ID` is provided, and stores schema-safe
defaults for omitted optional fields. Schema task types are `feature`, `bug`,
`chore`, `analysis`, and `spike`; generic input type `task` is accepted as an
alias for the schema default `feature`.

`task-set-status` validates the task and status. Entering `in-progress` sets
`started_at` if empty. Entering `done` sets `completed_at` if empty. Moving away
from `done` does not erase `completed_at`. It does not cascade parent statuses or
write verification rows.

`task-update-title` updates only `title` and `updated_at`. `task-archive` is a
soft archive only: it sets `archived_at` and never deletes the task row.

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

Validate, preview, and apply a reviewed plan payload:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-validate /path/to/project /path/to/plan.json
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-preview /path/to/project /path/to/plan.json
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-apply /path/to/project /path/to/plan.json
```

`PLAN_JSON` is an explicit reviewed JSON file produced outside the wrapper. The
wrapper does not read PRDs, ask questions, synthesize tasks, execute work, or
start background activity.

The plan payload must use `payload_version: 1` and
`review_status: "reviewed"`. It may provide one `plan_analyses` object, zero or
more `milestones`, one or more `tasks`, and optional `memories`.
`plan_analyses.id` and memory ids are generated when omitted. Task and milestone
ids are explicit stable payload ids. Task dependencies are stored in the
existing `tasks.dependencies` and `tasks.dependency_types` JSON fields.

`plan-validate` and `plan-preview` open the initialized database read-only and
perform no writes. `plan-apply` writes all accepted plan artifacts in one SQLite
transaction and fails before writing on invalid JSON, missing task list,
unsupported schema version, duplicate payload IDs, invalid enum values, missing
references, cyclic parent relationships, inactive dependencies, or collisions
with existing persisted IDs.

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
  `plan-validate`, `plan-preview`, and `export-json` are read-only.
- `task-add`, `task-set-status`, `task-update-title`, and `task-archive` write
  only to `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `memory-add` and `memory-deprecate` write only to
  `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `plan-apply` writes only new `plan_analyses`, `milestones`, `tasks`, and
  optional `memories` rows to `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `run-sql-tests` delegates to the copied test scripts, which use disposable
  `mktemp` directories.
- The wrapper does not implement upstream TaskManager PRD parsing, `run`,
  `verify`, broad `update`, full `memory`, or `research` command behavior.
- The `show` command is visibility only; it does not execute tasks, update
  status, write verification rows, write logs, or claim upstream `show` parity.
- The task commands do not plan tasks from PRDs, execute tasks, verify tasks,
  cascade parent status, manage dependencies/tags/milestones, or implement full
  upstream `update` parity.
- The memory commands do not run research, auto-classify, update, supersede, or
  reconcile memory conflicts.
- The plan commands do not execute tasks, write verification or regression rows,
  change `state.current_task_id`, enable hooks, run research, or claim full
  upstream `plan` parity.
- Full upstream TaskManager runtime parity is not claimed.
