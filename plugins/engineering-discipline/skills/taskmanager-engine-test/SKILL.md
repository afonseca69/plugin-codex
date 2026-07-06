---
name: taskmanager-engine-test
description: Run the copied TaskManager engine SQL, lifecycle, and wrapper tests for the manual engine artifacts.
---

# Taskmanager Engine Test

Use this skill to run validation for the copied TaskManager SQLite engine
artifacts and the manual wrapper.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

These tests validate the copied artifacts and limited manual wrapper only. They
do not enable hooks, register Codex commands, start background jobs, schedule
work, or prove full upstream TaskManager runtime parity.

## Guardrails

- Run tests from
  `plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine`.
- The copied tests and wrapper use disposable temp directories; do not point
  tests at user project state.
- Do not delete files outside disposable temp directories.
- Do not hide failures or summarize them as passing when any command exits
  non-zero.
- Do not enable or edit hooks.

## Usage

Run the copied SQL, lifecycle, and wrapper tests from the engine artifact
directory:

```bash
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_sql_queries.sh
bash tests/test_lifecycle_e2e.sh
bash tests/test_wrapper_cli.sh
```

Run the wrapper's delegated SQL test command from the repository root:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh run-sql-tests
```

## Validation And Reporting

Report:

- every command that ran;
- each command exit status;
- pass/fail counts printed by the copied tests;
- any dependency failure, especially missing `sqlite3`;
- that test state was disposable temp state;
- that passing tests validate only the copied artifacts and limited manual
  wrapper, not full upstream TaskManager parity.
