---
name: taskmanager-engine-plan
description: Use when manually validating, previewing, or applying reviewed TaskManager plan JSON payloads through the explicit wrapper.
---

# Taskmanager Engine Plan

Use this skill only when the user explicitly asks to manually validate, preview, or
apply reviewed plan payloads in an initialized copied TaskManager SQLite engine
database.

Wrapper path from the repository root:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
```

This is a manual wrapper around copied SQLite artifacts. It does not enable
hooks, register Codex commands, start jobs, schedule work, execute tasks,
run research, verify tasks, or provide full upstream TaskManager parity.

Reviewed plan payloads must satisfy:

- `payload_version` is `1`
- `review_status` is `reviewed`
- `tasks` is present and non-empty
- `milestones` and `memories` are optional arrays

The wrapper does not parse PRDs, generate plans, infer requirements, or perform
plan synthesis.

## Read-only Commands

These commands open `PROJECT_DIR/.taskmanager/taskmanager.db` and only read data:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
PLAN_JSON="/path/to/reviewed-plan.json"
"$ENGINE" plan-validate "$PROJECT_DIR" "$PLAN_JSON"
"$ENGINE" plan-preview "$PROJECT_DIR" "$PLAN_JSON"
```

`plan-validate` checks payload shape and constraints only.
`plan-preview` shows projected inserts only.

## Mutating Commands

This command writes to `PROJECT_DIR/.taskmanager/taskmanager.db` and must be used
explicitly:

```bash
ENGINE="plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh"
PROJECT_DIR="/path/to/project"
PLAN_JSON="/path/to/reviewed-plan.json"
"$ENGINE" plan-apply "$PROJECT_DIR" "$PLAN_JSON"
```

`plan-apply` is transactional and writes only to:

- `plan_analyses`
- `milestones`
- `tasks`
- optional `memories`

It does not touch other task manager tables beyond those writes.

## Guardrails

- Require an explicit user-requested `PROJECT_DIR` and `PLAN_JSON`.
- Require an existing `PROJECT_DIR/.taskmanager/taskmanager.db`.
- Require that review payload constraints above are met before any apply.
- Require validation or preview before applying; do not apply blindly.
- Do not execute planned tasks or call any run/verify/research/done
  command flow.
- Do not add done gates, background jobs, schedulers, agents, or subagents.
- Do not write verification rows, regression rows, or change `state.current_task_id`.
- Do not enable, create, or edit hooks.
- Do not implement runtime autonomy or full upstream flow control.
- Respect explicit user intent and return safely on parse, payload, or schema
  validation errors.

## Validation And Reporting

Report:

- the exact `PROJECT_DIR` and `PLAN_JSON` used;
- whether the command is read-only or mutating;
- the command executed (`plan-validate`, `plan-preview`, `plan-apply`);
- for `plan-validate`/`plan-preview`, any payload validation failures and warnings;
- for `plan-apply`, inserted counts for `plan_analyses`, `milestones`, `tasks`,
  and `memories`;
- any wrapper validation failure, DB missing errors, invalid payload boundary
  mismatches, or transaction aborts;
- that full upstream TaskManager runtime parity is not claimed.
