# Phase 5A/5B Notes

## Source Files

Copied from `../mwguerra-plugins/taskmanager`:

- `schemas/default-config.json`
- `schemas/schema.sql`
- `schemas/queries.sql`
- `schemas/migrate-v4.0-to-v4.1.sh`
- `schemas/migrate-v4.1-to-v4.2.sh`
- `tests/test_sql_queries.sh`
- `tests/test_lifecycle_e2e.sh`

Relevant upstream TaskManager README and skill files were inspected to document
the engine accurately, but their command/runtime behavior was not ported.

Phase 5B adds Codex-local wrapper files around the copied artifacts:

- `bin/taskmanager-engine.sh`
- `tests/test_wrapper_cli.sh`
- `USAGE.md`

## Adaptations

- `tests/test_sql_queries.sh` now reads the milestone and PRD verify guard SQL
  snippets from `tests/fixtures/verify-guard-sql.md` instead of
  `commands/verify.md`.
- `tests/fixtures/verify-guard-sql.md` contains only the upstream SQL snippets
  needed by the copied test. It is a test fixture, not a Codex command.
- `tests/test_lifecycle_e2e.sh` has one output label changed from an upstream
  Claude-specific environment variable reference to neutral plugin-root wording.

No schema, query catalog, migration logic, or default config content was changed.

The Phase 5B wrapper started deliberately small with manual `init`, `status`,
`next`, `export-json`, `run-sql-tests`, and `help` commands only. Later slices
extend the same manual wrapper without registering Codex commands or changing
hook behavior.

Phase 5E extends the same wrapper with a manual, read-only `show` command for
initialized projects. `show` requires an explicit project path and exposes
overview, task list, task detail, milestone, memory, deferral, verification,
and regression views through `sqlite3 -readonly`.
It does not execute tasks, update statuses, write logs, or change hook behavior.

Phase 5F adds manual memory list/show/search/add/deprecate commands. Phase 5G
adds manual task add/status/title/archive commands. Phase 5H-2 adds manual
plan-validate/plan-preview/plan-apply commands for reviewed JSON payloads.
These additions remain explicit wrapper operations; they do not parse PRDs,
execute tasks, write verification or regression rows, run research, enable
hooks, or claim full upstream TaskManager parity.

## Remaining Gaps

Phase 5B deliberately leaves these out:

- First-class Codex command registration.
- Upstream TaskManager command parity for full `plan`, `run`, `verify`,
  `update`, `research`, or full `memory`.
- Full upstream `show` parity beyond the read-only Phase 5E visibility modes.
- Automatic TaskManager execution.
- Hook integration or hook enablement.
- Background jobs or external integrations.
- Repository migrations beyond the copied TaskManager SQLite migration scripts.
- Full parity claims for the upstream TaskManager runtime.

Future work can decide whether to expose these artifacts through first-class
Codex-native commands or skills, and should add runtime tests before making any
broader parity claim.
