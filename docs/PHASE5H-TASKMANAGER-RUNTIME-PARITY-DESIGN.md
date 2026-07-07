# Phase 5H TaskManager Runtime Parity Design

## Status

Phase 5H began as a design-only slice for future Codex-native TaskManager
runtime parity. Phase 5H-1 published the future manual `plan` command contract
without runtime behavior. Phase 5H-2 implements the narrow manual
`plan-validate`, `plan-preview`, and `plan-apply` wrapper command family for
reviewed JSON payloads.

The published baseline remains plugin version `0.1.13` with 29 skills. Default
hooks remain advisory-only. Optional extended advisory hooks and optional
enforcing hooks remain opt-in and outside the plugin hook entry point.

Phase 5H-1 extends this design with a future manual `plan` command contract.
It is still design-only. It does not implement the runtime `plan` surface or
any wrapper behavior.

Phase 5H-2 implements only the reviewed-payload manual plan wrapper surface. It
does not add a first-class plan skill, parse PRDs, ask follow-up questions,
execute tasks, write verification or regression rows, change current task state,
run research, implement done gates, enable hooks, change plugin version, or
claim full upstream `plan` parity.

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

- Define a Codex-native shape for `plan`, `run`, and `verify` without claiming
  full upstream parity.
- Implement only reviewed-payload manual `plan` validation, preview, and apply
  in Phase 5H-2.
- Keep TaskManager persistence explicit, manual, and bounded to
  `PROJECT_DIR/.taskmanager/`.
- Preserve the current hook posture: default advisory hooks only, with extended
  and enforcing hooks remaining opt-in.
- Separate passive visibility, manual operations, plan generation, run
  execution, verification/reporting, and possible future done gates.
- Provide implementation slices that can be taken later without claiming full
  upstream parity.

## Non-goals

- No PRD parsing, plan generation, `run`, `verify`, `research`, done gates,
  broad `update`, or autonomous execution.
- No runtime script, wrapper, hook, migration, manifest, or executable-code
  changes beyond the explicit Phase 5H-2 manual `plan-*` wrapper commands.
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
| Manual plan payload validation/preview/apply | Implemented in Phase 5H-2 for reviewed JSON payloads. | `plan-validate` and `plan-preview` are read-only; `plan-apply` inserts plan analyses, milestones, tasks, and optional memories only. It does not parse PRDs or execute tasks. |
| Future plan generation | Not implemented. | Codex or an operator should produce a reviewable structured payload before any database import. |
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

These names are design placeholders except for the Phase 5H-2 manual `plan-*`
wrapper commands explicitly called out below.

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

## Phase 5H-1 Manual `plan` Command Contract

Phase 5H-1 defines the smallest future command contract for manual planning. It
does not add the command. The future `plan` surface exists to persist a reviewed
Codex-generated plan into the TaskManager SQLite artifacts without starting
execution, verification, research, or done-gate behavior.

### Intended Purpose

The future manual `plan` command should take an operator-reviewed plan payload
and turn it into durable TaskManager planning artifacts. It should not parse a
PRD inside the wrapper, ask follow-up questions, edit repository files, execute
tasks, verify work, or start background activity.

Codex operator skills remain responsible for reading the PRD or user prompt,
resolving ambiguities with the user, and producing the structured payload. The
wrapper remains responsible only for deterministic validation, preview, and
transactional persistence inside `PROJECT_DIR/.taskmanager/`.

### Command Inputs

The future wrapper inputs should be explicit and file-based:

- `PROJECT_DIR`: required for every `plan-*` command. The wrapper must resolve
  it to one target `.taskmanager/taskmanager.db`.
- `PLAN_JSON`: required for validation, preview, and apply. It should be a path
  to a structured JSON file produced outside the wrapper and reviewed before
  apply.
- Optional output mode, if added later: human text by default, with JSON output
  only when explicitly requested.

The payload contract should include:

- payload format version;
- source description, such as PRD path, folder path, or prompt summary;
- source hash when a file or folder source is available;
- one `plan_analyses` record with assumptions, risks, ambiguities,
  non-functional requirements, scope in/out, decisions, cross-cutting concerns,
  and PRD-level acceptance criteria;
- zero or more `milestones` with stable client IDs, title, description, phase
  order, status, and acceptance criteria;
- one or more `tasks` with stable client IDs, optional parent client ID,
  milestone client ID, title, description, details, test strategy, type,
  priority, status, complexity fields, tags, dependencies, dependency types,
  and acceptance criteria;
- optional `memories` for durable decisions or constraints that should be
  persisted as active memories;
- payload metadata that records the generating skill or operator context without
  implying autonomous agent execution.

### Expected Outputs

`plan-validate PROJECT_DIR PLAN_JSON` should:

- read the database schema and payload;
- return success only when the payload can be safely previewed or applied;
- report row counts, referenced IDs, resolved target IDs, and validation
  warnings;
- perform no database or filesystem writes.

`plan-preview PROJECT_DIR PLAN_JSON` should:

- show the plan analysis, milestones, task tree, dependency graph, optional
  memories, and target tables;
- highlight collisions with existing task, milestone, memory, or plan-analysis
  IDs;
- report whether apply would be a clean insert or rejected;
- perform no database or filesystem writes.

`plan-apply PROJECT_DIR PLAN_JSON` should:

- require a payload that passes validation;
- write all accepted plan artifacts in one SQLite transaction;
- report inserted row counts and the final IDs written;
- leave repository source files untouched;
- fail without partial writes if any planned artifact cannot be persisted.

### TaskManager Artifact Flow

1. `init` creates the `.taskmanager/` directory, database, config, and logs.
2. Codex reads a PRD, folder, or prompt only after explicit user intent.
3. Codex produces a `PLAN_JSON` payload and presents the planning outcome for
   operator review.
4. `plan-validate` checks JSON shape, schema version, enum values, ID format,
   parent references, milestone references, dependency references, acceptance
   criteria shape, and memory fields without writing.
5. `plan-preview` reads current TaskManager state and reports the exact
   artifacts that would be inserted.
6. `plan-apply` writes `plan_analyses`, `milestones`, `tasks`, and optional
   `memories` in a single transaction.
7. Dependencies are stored in the existing task JSON fields
   `tasks.dependencies` and `tasks.dependency_types`; the copied schema does not
   have a separate task-dependency table.
8. `state.current_task_id`, `verifications`, and `regression_checks` remain
   untouched by planning.
9. Later `run` and `verify` surfaces may read the planned artifacts, but they
   remain separate future slices.

### SQLite, Task, And Memory Boundaries

- Validation and preview may read `schema_version`, `plan_analyses`,
  `milestones`, `tasks`, `memories`, `state`, and config files only to validate
  compatibility and collisions.
- Validation and preview must not mutate the database, config, logs, repository
  files, or hook files.
- Apply may insert new `plan_analyses`, `milestones`, `tasks`, and optional
  `memories` only.
- Apply must not update existing task status, archive existing tasks, rewrite
  existing memories, deprecate memories, write verification rows, write
  regression rows, or set current task state.
- Apply must keep all writes inside `PROJECT_DIR/.taskmanager/`.
- Apply must not edit source files, launch Codex work, invoke agents, perform
  research, or enable hooks.

### Safety Model

- Require an explicit `PROJECT_DIR` and `PLAN_JSON` path for every future
  mutating plan operation.
- Treat payload generation and payload persistence as separate steps.
- Require preview before apply at the skill/operator layer, even if the wrapper
  later exposes direct `plan-apply`.
- Validate all JSON fields with a structured parser before SQLite writes.
- Validate task and milestone IDs before resolving client IDs to persisted IDs.
- Validate dependency references against the payload and existing database state.
- Validate status, type, priority, complexity, milestone status, memory kind,
  memory source type, and memory confidence/importance ranges before writing.
- Use one SQLite transaction for apply and prove rollback on every failure mode.
- Keep hooks advisory-only and never use hooks to trigger planning.
- Keep extended and enforcing hooks opt-in and outside the default hook entry
  point.
- Keep all execution manual: no auto-run, no background work, no schedulers, no
  autonomous agents, and no subagents.

### Failure Modes

The future implementation should fail closed, with non-zero exit status and no
partial writes, for:

- missing `PROJECT_DIR`, missing database, or missing `PLAN_JSON`;
- unreadable or invalid JSON;
- unsupported payload format version;
- unsupported TaskManager schema version;
- duplicate IDs inside the payload;
- collisions with existing persisted IDs when overwrite behavior is not
  explicitly supported;
- invalid enum values or malformed JSON subfields;
- missing parent, milestone, or dependency references;
- cyclic parent relationships;
- dependencies that point to archived, canceled, duplicate, or missing tasks;
- empty task lists;
- optional memories that violate memory kind, source, confidence, importance, or
  required body/title constraints;
- SQLite constraint failures;
- interrupted apply transactions.

### Later Validation Strategy

A later implementation slice must add tests before any runtime claim is made:

- payload validator tests for each failure mode above;
- preview tests that assert no database file timestamp, checksum, or row count
  changes;
- apply tests that assert exact before/after rows for `plan_analyses`,
  `milestones`, `tasks`, and optional `memories`;
- rollback tests for mid-transaction failure;
- idempotency or collision tests that define repeated apply behavior;
- output tests for human text and any explicit JSON output mode;
- wrapper help and argument validation tests;
- skill documentation tests or review that prove the operator guide does not
  promise execution, verification, research, done gates, hook enforcement, or
  full upstream parity.

### Acceptance Criteria For Future Implementation

A future implementation of this contract is acceptable only when:

- `plan-validate`, `plan-preview`, and `plan-apply` are implemented explicitly
  and documented;
- validation and preview are proven read-only;
- apply is proven transactional and bounded to `PROJECT_DIR/.taskmanager/`;
- task dependencies are persisted according to the current schema fields;
- optional memory writes are explicit and bounded to new rows;
- no repository source files are edited by the wrapper;
- no `run`, `verify`, `research`, done-gate, auto-run, background, scheduler,
  agent, or subagent behavior is added;
- hooks remain advisory-only by default, and extended/enforcing hooks remain
  opt-in;
- README, parity docs, skills, wrapper tests, and release notes are updated only
  for behavior actually implemented and tested;
- the plugin version and skill count are changed only in a deliberate release
  slice, not as a side effect of this design.

### Phase 5H-1 Does Not Implement

Phase 5H-1 does not implement runtime `plan`, `run`, `verify`, `research`, done
gates, auto-run, background jobs, schedulers, default enforcing hooks,
autonomous agents, subagents, or full parity with upstream `mwguerra/plugins`.

## Phase 5H-2 Manual `plan` Implementation

Phase 5H-2 implements the manual command family defined by the Phase 5H-1
contract:

```bash
taskmanager-engine.sh plan-validate PROJECT_DIR PLAN_JSON
taskmanager-engine.sh plan-preview PROJECT_DIR PLAN_JSON
taskmanager-engine.sh plan-apply PROJECT_DIR PLAN_JSON
```

The implementation is intentionally limited:

- `PLAN_JSON` must use `payload_version: 1` and `review_status: "reviewed"`;
- the payload may contain one `plan_analyses` object, zero or more milestones,
  one or more tasks, and optional memories;
- `plan-validate` and `plan-preview` open the initialized database read-only and
  perform no writes;
- `plan-apply` inserts accepted rows in a single SQLite transaction;
- collisions with existing persisted IDs fail before writes;
- task dependencies are stored in `tasks.dependencies` and
  `tasks.dependency_types`;
- `state.current_task_id`, `verifications`, and `regression_checks` are not
  changed.

See [`docs/PHASE5H-2-TASKMANAGER-PLAN.md`](PHASE5H-2-TASKMANAGER-PLAN.md) for
the implemented command details and verification evidence.

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

1. Phase 5I: first-class plan operator skill and broader payload fixtures.

   Add a `taskmanager-engine-plan` skill or equivalent operator guide for the
   Phase 5H-2 wrapper commands, plus focused fixture coverage for invalid
   dependencies, enum values, schema-version mismatch, and collision reporting.
   No PRD parsing or task execution is required in this slice.

2. Phase 5J: plan payload generation guidance.

   Document how Codex operator skills should produce reviewed `PLAN_JSON`
   payloads from PRDs or prompts before invoking the wrapper. Keep payload
   generation outside the wrapper.

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
- Complete upstream `plan`, `run`, `verify`, or `research` runtime behavior.
- PRD parsing or plan generation inside the wrapper.
- Broad upstream `update` parity.
- Enforcing done gates.
- Web research without explicit user intent.
- Codex command registration for the upstream TaskManager command set.

## Acceptance Criteria For Phase 5H-2

- `plan-validate`, `plan-preview`, and `plan-apply` are explicit manual wrapper
  commands.
- `plan-validate` and `plan-preview` are proven read-only.
- `plan-apply` is transactional and bounded to
  `PROJECT_DIR/.taskmanager/taskmanager.db`.
- `plan-apply` writes only `plan_analyses`, `milestones`, `tasks`, and optional
  `memories`.
- Invalid payloads and duplicate/colliding IDs fail before partial writes.
- No hook behavior changes.
- No plugin version bump.
- No skill count change.
- No migration, manifest, hook, or skill edits.
- No `run`, `verify`, `research`, done gates, auto-run, background work,
  schedulers, agents, or subagents.
- No full upstream `plan` or TaskManager runtime parity claim.

## Verification For Phase 5H-2

Implementation verification includes repository hygiene and command-specific
tests:

```bash
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_wrapper_cli.sh
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_wrapper_cli.sh
```

Latest local Phase 5H-2 result: `test_wrapper_cli.sh` passed `152/0` while also
delegating to `test_sql_queries.sh` (`285/0`) and `test_lifecycle_e2e.sh`
(`30/0`) through `run-sql-tests`.

Future implementation slices need their own command-specific tests before any
new runtime parity claim.
