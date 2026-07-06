# Phase 5E TaskManager Read-only Runtime Visibility

## Status

Phase 5E is implemented in plugin version `0.1.11` as a safe, explicit,
read-only visibility slice for initialized copied TaskManager SQLite engine
state.

It does not enable hooks, register Codex commands, start background jobs,
auto-run TaskManager, execute tasks, update statuses, write verification rows,
or claim full upstream TaskManager runtime parity.

## Added Runtime Surface

The manual wrapper now supports:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh show PROJECT_DIR [view] [args...]
```

Supported views:

- `overview`
- `tasks [limit]`
- `task TASK_ID`
- `milestones [limit]`
- `memories [limit]`
- `deferrals [limit]`
- `verifications [TASK_ID]`
- `regressions [TARGET_ID]`

`PROJECT_DIR` is required for `show`. The wrapper opens
`PROJECT_DIR/.taskmanager/taskmanager.db` through `sqlite3 -readonly`.

## Added Skill

Phase 5E adds one first-class Codex operator skill:

- `taskmanager-engine-show`

The skill guides manual read-only use of the wrapper. It is not a Codex command
registration layer and does not add hidden runtime behavior.

## Safety Boundaries

- Read-only visibility only.
- No writes to `taskmanager.db`, logs, config, docs, or repository source files.
- No hook changes.
- No `hooks/hooks.json` changes.
- No enforcing-hook behavior changes.
- No background jobs, schedulers, external integrations, or auto-run behavior.
- No implementation of `plan`, `run`, `verify`, `update`, `memory`, `research`,
  migration, reset, wipe, import, or other mutating TaskManager commands.
- No full upstream `show` parity claim.
- No full upstream TaskManager parity claim.

## Verification Coverage

`tests/test_wrapper_cli.sh` now covers:

- help text for `show`;
- explicit `PROJECT_DIR` requirement;
- empty initialized database behavior;
- unknown view failure;
- missing task id failure for `task`;
- human `overview`, `tasks`, `task`, `milestones`, `memories`, `deferrals`,
  `verifications`, and `regressions` output;
- optional task/target filters for `verifications` and `regressions`;
- a database checksum assertion proving the tested `show` modes do not mutate
  `taskmanager.db`;
- continued `init`, `status`, `next`, `export-json`, and `run-sql-tests`
  wrapper behavior.

Latest local Phase 5E wrapper result: `test_wrapper_cli.sh` passed `50/0` while
also delegating to the copied SQL suite (`285/0`) and lifecycle suite (`30/0`)
through `run-sql-tests`.

## Remaining Gaps

The upstream TaskManager command set is still not ported as a full Codex
runtime. Mutating runtime workflows remain future work and require their own
explicit wrapper commands, operator skills, and before/after database tests.
