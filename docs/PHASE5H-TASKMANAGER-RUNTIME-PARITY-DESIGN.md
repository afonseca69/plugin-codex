# Phase 5H TaskManager Runtime Parity Design

## Status

Phase 5H is a design-only slice for future Codex-native TaskManager runtime
parity. It does not change plugin runtime behavior, edit wrapper scripts, add
skills, change hooks, enable hooks, bump the plugin version, or implement
additional TaskManager commands.

The published baseline remains plugin version `0.1.13` with 29 skills. Default
hooks remain advisory-only. Optional extended advisory hooks and optional
enforcing hooks remain opt-in and outside the plugin hook entry point.

## Relationship To Phase 5D

Phase 5D recorded the broad runtime architecture for moving from passive copied
TaskManager artifacts toward explicit Codex-native wrapper operations. Phase 5E,
Phase 5F, and Phase 5G implemented narrow slices from that design: read-only
visibility, manual memory operations, and manual task operations.

Phase 5H does not supersede Phase 5D. It narrows the next risky design area:
future `plan`, `run`, and `verify` behavior. The purpose is to separate what is
already safe and manual from what still needs deliberate command contracts,
artifact flow, tests, and safety gates before any implementation can begin.

## Goals

- Define a future Codex-native shape for `plan`, `run`, and `verify` without
  implementing those commands.
- Keep TaskManager persistence explicit, manual, and bounded to
  `PROJECT_DIR/.taskmanager/`.
- Preserve the current hook posture: default advisory hooks only, with extended
  and enforcing hooks remaining opt-in.
- Separate passive visibility, manual operations, plan generation, run
  execution, verification/reporting, and possible future done gates.
- Provide implementation slices that can be taken later without claiming full
  upstream parity.

## Non-goals

- No implementation of `plan`, `run`, `verify`, `research`, done gates, broad
  `update`, or autonomous execution.
- No runtime script, wrapper, hook, migration, manifest, or executable-code
  changes.
- No Codex command registration.
- No background jobs, schedulers, agents, subagents, or hidden services.
- No automatic TaskManager execution or hook-driven TaskManager behavior.
- No full parity claim with upstream `mwguerra/plugins`.

## Current Surface Separation

| Surface | Current status | Boundary |
|---|---|---|
| Passive visibility | Implemented by copied schema, query, migration, and test artifacts plus read-only `show` modes. | Reads initialized engine state; does not execute tasks or mutate source files. |
| Manual task operations | Implemented in Phase 5G for add, status, title, and soft archive. | Mutates only explicit task rows in `PROJECT_DIR/.taskmanager/taskmanager.db`. |
| Manual memory operations | Implemented in Phase 5F for list, show, search, add, and deprecate. | Mutates only explicit memory rows for add/deprecate; no research workflow. |
| Future plan generation | Not implemented. | Should produce a reviewable structured payload before any database import. |
| Future run execution | Not implemented. | Should keep repository edits as explicit Codex work, separate from deterministic DB updates. |
| Future verify/reporting | Not implemented. | Should record evidence and produce reports before any status gate relies on it. |
| Future done gates | Deferred and not implemented. | Any gate must be explicit, tested, override-aware, and not hook-enabled by default. |

## Why This Remains Manual And Codex-native

The upstream TaskManager behavior depends on Claude Code slash commands,
Claude-specific agent affordances, and Claude-specific environment assumptions.
The Codex port should not simulate those implicitly. Future runtime parity should
continue to use two explicit layers:

- deterministic wrapper commands for filesystem and SQLite operations;
- Codex operator skills for interpretation, user-facing choices, evidence
  review, and summaries.

The wrapper should never invoke Codex, spawn agents, run background work, perform
web research, or edit repository source files. Codex may edit repository files
only when the user explicitly asks to run or implement a task.

## Future Command Surfaces

These names are design placeholders, not implemented commands.

### Future `plan`

The safest future `plan` shape is preview-first:

- `plan-validate PROJECT_DIR PLAN_JSON`
- `plan-preview PROJECT_DIR PLAN_JSON`
- `plan-apply PROJECT_DIR PLAN_JSON`

Codex should own PRD interpretation and plan-payload generation. The wrapper
should own validation and transactional import into milestones, tasks,
dependencies, memories, and plan analyses. `plan-apply` should require an
explicit reviewed payload and should fail before partial writes on invalid JSON,
duplicate IDs, invalid dependencies, invalid enum values, or missing schema
state.

### Future `run`

The safest future `run` shape is context-first:

- `run-context PROJECT_DIR TASK_ID`
- `run-start PROJECT_DIR TASK_ID`
- `run-record PROJECT_DIR TASK_ID OUTCOME EVIDENCE_JSON`

The wrapper should expose task context, mark explicit lifecycle transitions, and
record structured outcomes. It should not perform repository edits. Actual code
or documentation work remains explicit Codex work in the target repository, with
the user aware of the task being executed.

### Future `verify`

The safest future `verify` shape is evidence-first:

- `verify-record PROJECT_DIR TARGET_TYPE TARGET_ID CRITERION_INDEX STATUS EVIDENCE_JSON`
- `verify-report PROJECT_DIR TARGET_TYPE TARGET_ID`
- `verify-gate-preview PROJECT_DIR TASK_ID`

Verification should record evidence rows and produce a report before any gate
uses the result. `verify-gate-preview` should remain read-only until a later
slice deliberately implements a guarded status transition.

## Expected Artifact Flow

1. `init` creates the passive engine state as it does today.
2. A future Codex skill reads a PRD or user-provided plan request and produces a
   structured plan payload for review.
3. Future plan validation checks the payload without mutating the database.
4. Future plan apply writes milestones, tasks, memories, dependencies, and plan
   analyses in one transaction after explicit operator review.
5. Future run context reads the selected task, relevant memories, deferrals,
   dependencies, and acceptance criteria.
6. Codex performs repository work only after explicit user intent for that task.
7. Future verification records evidence and reports task, milestone, or PRD
   status.
8. Future done-gate behavior, if ever implemented, uses recorded verification
   and regression evidence and remains separate from default hooks.

## Safety Model

- Require an explicit `PROJECT_DIR` for all future mutating commands.
- Keep read-only commands provably read-only with database checksum or timestamp
  assertions in tests.
- Use SQLite transactions for every future multi-row mutation.
- Validate JSON, enums, dependency references, target IDs, and schema version
  before writing.
- Fail closed on invalid input and prove rollback behavior with tests.
- Keep wrapper mutations inside `PROJECT_DIR/.taskmanager/`.
- Keep repository edits outside the wrapper and under explicit Codex/user
  control.
- Treat web research as out of scope for Phase 5H and future explicit opt-in
  work only.
- Do not use hooks as runtime triggers for TaskManager behavior.

## Hook Posture

Default hooks remain advisory-only and continue to point at
`plugins/engineering-discipline/hooks/hooks.json`.

The optional extended advisory preset remains opt-in. The optional enforcing
hook preset remains opt-in and must not be described as reliable for a target
installation until it has live Codex smoke-test evidence in that installation.

Future TaskManager runtime work must not enable hooks automatically, move
enforcing hooks into the default hook entry point, or depend on hooks for command
correctness.

## Future Implementation Slices

Each later slice should update documentation and verification notes only for
behavior actually implemented and tested.

1. Phase 5I: plan payload contract.

   Define a structured JSON payload and validation rules. Add tests for invalid
   JSON, duplicate task IDs, invalid dependencies, invalid enum values, and
   schema-version mismatch. No PRD parsing or DB mutation is required in this
   slice.

2. Phase 5J: plan preview and transactional apply.

   Add preview output and explicit apply for a reviewed payload. Prove atomic
   rollback and before/after database state for milestones, tasks, dependencies,
   memories, and plan analyses.

3. Phase 5K: verification recording and reporting.

   Add evidence recording and reports for task, milestone, and PRD targets.
   Prove validation, latest-attempt semantics, override handling, and read-only
   reporting.

4. Phase 5L: run context and explicit lifecycle transitions.

   Add context display and explicit task lifecycle updates around user-directed
   Codex work. Repository edits remain outside the wrapper.

5. Phase 5M: deferred done gates.

   Consider a guarded transition only after verification and regression evidence
   are implemented and tested. Done gates must be explicit wrapper behavior, not
   default hook behavior.

6. Phase 5N: research, if still needed.

   Start with codebase-only research. Add web research only as an explicit,
   source-linked, timestamped, opt-in workflow.

## Deferred / Not Promised

- Full parity with upstream `mwguerra/plugins`.
- Auto-run.
- Background jobs or schedulers.
- Hooks enabled by default beyond the current advisory hook entry point.
- Autonomous agents or subagents.
- Complete `plan`, `run`, `verify`, or `research` runtime behavior.
- Broad upstream `update` parity.
- Enforcing done gates.
- Web research without explicit user intent.
- Codex command registration for the upstream TaskManager command set.

## Acceptance Criteria For This Design-only Slice

- Changes are docs-only.
- No runtime behavior changes.
- No hook behavior changes.
- No plugin version bump.
- No skill count change.
- No wrapper, migration, manifest, hook, or executable-code edits.
- No implementation of `plan`, `run`, `verify`, `research`, done gates, auto-run,
  background work, schedulers, agents, or subagents.
- No push, tag, or release is created as part of this slice.

## Verification For This Slice

Design-only verification is limited to repository hygiene:

```bash
git diff --check
git status --short
git diff --stat
```

Future implementation slices need command-specific tests before any new runtime
parity claim.
