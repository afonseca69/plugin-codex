# Phase 5G TaskManager Manual Task Operations

## Status

Phase 5G is implemented in plugin version `0.1.13` as a safe, explicit, manual
task-operation slice for initialized copied TaskManager SQLite engine state.

It does not enable hooks, register Codex commands, start background jobs,
auto-run TaskManager, execute tasks, write verification rows, run research,
perform web access, or claim full upstream TaskManager task/update/runtime
parity.

## Added Runtime Surface

The manual wrapper now supports explicit mutating task commands:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-add PROJECT_DIR TASK_ID TITLE [TYPE] [STATUS] [PARENT_ID]
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-set-status PROJECT_DIR TASK_ID STATUS
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-update-title PROJECT_DIR TASK_ID TITLE
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh task-archive PROJECT_DIR TASK_ID
```

`task-add` inserts one row into `tasks`, requires an explicit id and title,
refuses duplicate ids, validates schema statuses, validates task types, and
requires a parent to exist when `PARENT_ID` is provided. The schema constrains
stored types to `feature`, `bug`, `chore`, `analysis`, and `spike`; the wrapper
accepts generic input type `task` as an alias for the schema default `feature`.

`task-set-status` updates one task row. Entering `in-progress` sets
`started_at` if empty. Entering `done` sets `completed_at` if empty. Moving away
from `done` preserves `completed_at`.

`task-update-title` updates only `title` and `updated_at`.

`task-archive` is soft archive only. It sets `archived_at` and `updated_at`
without deleting the task row.

## Added Skill

Phase 5G adds one first-class Codex operator skill:

- `taskmanager-engine-task`

The skill guides manual use of the wrapper. It is not a Codex command
registration layer and does not add hidden runtime behavior.

## Safety Boundaries

- All task commands in this phase are mutating and require explicit invocation.
- Task commands mutate only `PROJECT_DIR/.taskmanager/taskmanager.db`.
- No task deletion.
- No hook changes.
- No `hooks/hooks.json` changes.
- No enforcing-hook behavior changes.
- No background jobs, schedulers, external integrations, web research, or
  auto-run behavior.
- No implementation of `plan`, `run`, `verify`, broad `update`, `memory`,
  `research`, migration, reset, wipe, import, or other broad TaskManager
  commands.
- No parent status cascade beyond schema-defined behavior. The current schema
  provides rollup views, not task status triggers.
- No verification or regression row writes.
- No full upstream task/update parity claim.
- No full upstream TaskManager parity claim.

## Verification Coverage

`tests/test_wrapper_cli.sh` now covers:

- help text for task commands;
- `task-add` creating a task and returning the explicit id;
- duplicate task id refusal;
- missing parent refusal;
- valid parent creation;
- invalid task id, type, and status failures;
- `task-set-status` invalid status failure;
- `task-set-status` timestamp behavior for `started_at` and `completed_at`;
- preserving `completed_at` when moving away from `done`;
- `task-update-title` changing only title and `updated_at` as far as practical;
- `show tasks`, `show task`, and `next` reflecting created tasks;
- `task-archive` setting `archived_at`, keeping the row, and hiding the task
  from `show tasks` and `next`;
- continued `init`, `status`, `show`, memory operations, `export-json`, and
  `run-sql-tests` wrapper behavior.

Latest local Phase 5G wrapper result: `test_wrapper_cli.sh` passed `118/0` while
also delegating to the copied SQL suite (`285/0`) and lifecycle suite (`30/0`)
through `run-sql-tests`.

## Remaining Gaps

The upstream TaskManager command set is still not ported as a full Codex
runtime. Remaining task gaps include planning from PRDs, dependency/tag/milestone
updates, deferral updates, execution workflows, verification and regression
recording, done gates, parent status propagation, task deletion policy, and
automatic memory application. These require their own explicit wrapper commands,
operator skills, and before/after database tests before any parity claim.
