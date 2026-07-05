# TaskManager Engine Artifacts

This directory is a Codex reference/runtime artifact port of the upstream
TaskManager SQLite engine files from `mwguerra/plugins`.

It is not a full Codex TaskManager runtime. It does not register Codex commands,
enable hooks, start background work, create repository migrations, or auto-run
tasks. Phase 5B adds a small manual wrapper for safe local initialization,
read-only inspection, JSON export, and copied SQL test execution. Phase 5C adds
first-class Codex skills that guide explicit use of that manual wrapper.

## Contents

```text
taskmanager-engine/
  bin/
    taskmanager-engine.sh
  schemas/
    default-config.json
    schema.sql
    queries.sql
    migrate-v4.0-to-v4.1.sh
    migrate-v4.1-to-v4.2.sh
  tests/
    fixtures/verify-guard-sql.md
    test_wrapper_cli.sh
    test_sql_queries.sh
    test_lifecycle_e2e.sh
  NOTES.md
  USAGE.md
```

The schema is upstream TaskManager SQLite schema `v4.2.0`. It includes tables
for tasks, milestones, plan analyses, memories, deferrals, verification history,
regression checks, singleton state, and schema version tracking. It also ships
the canonical scheduling and verification views:

- `v_next_task`
- `v_next_task_sequential`
- `v_task_verification`
- `v_milestone_verification`
- `v_prd_verification`
- `v_milestone_status`
- `v_task_regression`

The query catalog documents common SQLite queries for scheduling, task status,
memory lookup, deferrals, milestones, plan analyses, verification, and archival.

## Manual Wrapper

`bin/taskmanager-engine.sh` is explicit and manual only:

```bash
bin/taskmanager-engine.sh help
bin/taskmanager-engine.sh init /path/to/project
bin/taskmanager-engine.sh status /path/to/project
bin/taskmanager-engine.sh next /path/to/project
bin/taskmanager-engine.sh export-json /path/to/project
bin/taskmanager-engine.sh run-sql-tests
```

`init` creates `/path/to/project/.taskmanager/`, initializes
`taskmanager.db` from `schemas/schema.sql`, copies `default-config.json` to
`config.json` if missing, and creates `logs/`. It refuses to overwrite an
existing `.taskmanager/taskmanager.db`.

`status`, `next`, and `export-json` require an initialized project and do not
mutate the database. `run-sql-tests` delegates to the copied test scripts and
uses their disposable temp state.

See `USAGE.md` for command examples and safety limits.

## Codex Skill Entry Points

The plugin includes first-class skills for the supported manual wrapper
operations:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

These skills describe when and how to run the wrapper. They do not add a hidden
runtime, enable hooks, or claim upstream TaskManager command parity.

## Attribution

These artifacts are copied or minimally adapted from the upstream
`mwguerra/plugins` TaskManager plugin, originally MIT licensed by Marcelo
Guerra. See the repository-level `NOTICE.md` and `LICENSE`.

## Test Safety

The copied test scripts create temporary directories with `mktemp -d` and clean
them with `trap`. Test databases, `.taskmanager/` folders, logs, and migration
backup directories are created under those temporary directories.

The migration scripts operate on the `TASKMANAGER_DIR` argument they are given.
When used by the copied tests, that directory is inside the temporary test
workspace.

## Validation

From the repository root:

```bash
python3 -m json.tool plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/default-config.json >/dev/null
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/migrate-v4.0-to-v4.1.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/migrate-v4.1-to-v4.2.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_wrapper_cli.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_sql_queries.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_lifecycle_e2e.sh
```

If `sqlite3` is installed, run the copied SQL suites and wrapper test from this directory:

```bash
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_sql_queries.sh
bash tests/test_lifecycle_e2e.sh
bash tests/test_wrapper_cli.sh
```

Passing these tests validates the copied SQLite artifacts as standalone files and the limited
manual wrapper.
Latest local artifact result for Phase 5C: `test_sql_queries.sh` passed 285/0,
`test_lifecycle_e2e.sh` passed 30/0, and `test_wrapper_cli.sh` passed 19/0
while also running the copied SQL suites through `run-sql-tests`.

This does not prove full Codex TaskManager runtime parity. The port still does
not provide Codex command registration, automatic agents, hook-driven execution,
or the full upstream command set. Phase 5C adds only first-class Codex skill
entry points for the manual wrapper documented above.
