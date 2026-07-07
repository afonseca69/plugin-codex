# Phase 5H-2 TaskManager Manual Plan Commands

## Status

Phase 5H-2 implements the smallest manual `plan` wrapper command family for
initialized copied TaskManager SQLite engine state.

It did not add a first-class Codex skill, change plugin version, change skill
count, enable hooks, register Codex commands, start background jobs, auto-run
TaskManager, execute planned tasks, write verification rows, write regression
rows, run research, implement done gates, or claim full upstream TaskManager
plan/runtime parity. Phase 5H-3 later adds the `taskmanager-engine-plan`
operator skill for these existing manual commands without changing wrapper
runtime behavior.

## Added Runtime Surface

The manual wrapper now supports explicit plan payload commands:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-validate PROJECT_DIR PLAN_JSON
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-preview PROJECT_DIR PLAN_JSON
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh plan-apply PROJECT_DIR PLAN_JSON
```

`PLAN_JSON` must be a reviewed, file-based payload produced outside the wrapper.
Codex or the operator remains responsible for reading a PRD, resolving
ambiguity, and creating the payload.

## Command Behavior

`plan-validate` opens the initialized database read-only, validates the payload
shape, schema version, IDs, enum values, task list, parent references, milestone
references, dependency references, memory fields, duplicate payload IDs, and
collisions with existing persisted IDs. It performs no writes.

`plan-preview` performs the same validation and prints the plan analysis,
milestones, tasks, optional memories, and whether apply would be a clean insert.
It performs no writes.

`plan-apply` performs the same validation, then inserts one `plan_analyses` row,
zero or more `milestones`, one or more `tasks`, and optional `memories` in a
single SQLite transaction. It fails before writing when the payload is invalid
or collides with existing persisted IDs.

## Payload Boundary

The supported payload is intentionally narrow:

- `payload_version` must be `1`;
- `review_status` must be `reviewed`;
- `plan_analyses` is one object, with generated `PA-NNN` id when omitted;
- `milestones` is optional, but any referenced milestone must exist in the
  payload or database;
- `tasks` must be a non-empty list with stable IDs and schema-valid fields;
- task dependencies are stored in the existing `tasks.dependencies` and
  `tasks.dependency_types` JSON fields;
- optional `memories` insert active memory rows with generated `M-NNN` IDs when
  omitted.

The wrapper does not parse PRDs, ask follow-up questions, synthesize tasks,
execute tasks, update current task state, write logs, or edit repository source
files.

## Safety Boundaries

- `plan-validate` and `plan-preview` are read-only.
- `plan-apply` writes only to `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `plan-apply` inserts only `plan_analyses`, `milestones`, `tasks`, and optional
  `memories`.
- `state.current_task_id`, `verifications`, and `regression_checks` are not
  changed.
- Hooks remain advisory-only by default.
- Optional extended advisory hooks and optional enforcing hooks remain opt-in.
- No `run`, `verify`, `research`, done-gate, auto-run, background, scheduler,
  autonomous agent, or subagent behavior is added.

## Verification Coverage

`tests/test_wrapper_cli.sh` covers:

- help text for `plan-validate`, `plan-preview`, and `plan-apply`;
- missing argument failures;
- invalid JSON rejection;
- missing or empty task list rejection;
- `plan-validate` accepting a reviewed payload without DB writes;
- `plan-preview` printing plan, milestone, and task details without DB writes;
- `plan-apply` inserting exact plan, milestone, task, and optional memory row
  counts;
- `plan-apply` preserving `state.current_task_id`;
- `plan-apply` not writing verification or regression rows;
- duplicate/collision rejection without partial writes.

Latest local Phase 5H-2 wrapper result: `test_wrapper_cli.sh` passed `152/0`
while also delegating to the copied SQL suite (`285/0`) and lifecycle suite
(`30/0`) through `run-sql-tests`.

## Remaining Gaps

Remaining TaskManager runtime gaps include broader payload fixture coverage,
PRD-to-payload guidance, `run`, `verify`, `research`, done gates, broad
`update`, full upstream `plan` UX, and full upstream TaskManager parity. Each
requires its own explicit slice and verification before any parity claim.
