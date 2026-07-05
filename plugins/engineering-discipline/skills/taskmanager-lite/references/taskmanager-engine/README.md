# TaskManager Engine Artifacts

This directory is a passive Codex reference/runtime artifact port of the
upstream TaskManager SQLite engine files from `mwguerra/plugins`.

It is not a Codex TaskManager runtime. It does not register commands, enable
hooks, start background work, create repository migrations, or auto-run tasks.
Codex wrappers and first-class runtime integration are future work.

## Contents

```text
taskmanager-engine/
  schemas/
    default-config.json
    schema.sql
    queries.sql
    migrate-v4.0-to-v4.1.sh
    migrate-v4.1-to-v4.2.sh
  tests/
    fixtures/verify-guard-sql.md
    test_sql_queries.sh
    test_lifecycle_e2e.sh
  NOTES.md
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
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_sql_queries.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_lifecycle_e2e.sh
```

If `sqlite3` is installed, run the copied SQL suites from this directory:

```bash
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_sql_queries.sh
bash tests/test_lifecycle_e2e.sh
```

Passing these tests validates the copied SQLite artifacts as standalone files.
Latest WSL2 artifact result: `test_sql_queries.sh` passed 285/0 and `test_lifecycle_e2e.sh` passed 30/0.

It does not prove full Codex TaskManager runtime parity, because Phase 5A does
not port Codex commands, wrappers, automatic agents, or hook-driven execution.
