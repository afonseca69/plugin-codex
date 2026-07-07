# Phase 5D TaskManager Runtime Design

## Status

Phase 5D is a documentation and architecture phase only. It does not change plugin
runtime behavior, add scripts, add skills, change hooks, enable hooks, bump the
plugin version, or implement additional TaskManager commands.

Plugin version `0.1.10` remains a limited Codex-native port with passive
TaskManager SQLite artifacts, a small manual wrapper, and first-class skills for
the wrapper operations that already exist. Full upstream TaskManager runtime
parity is not claimed.

Post-design update: Phase 5E in plugin version `0.1.11` implements the first
read-only visibility slice from this design through
`taskmanager-engine.sh show PROJECT_DIR [view] [args...]` and the
`taskmanager-engine-show` skill. It remains limited to read-only overview, task,
milestone, memory, deferral, verification, and regression views and does not
claim full upstream `show` or TaskManager runtime parity.

Post-design update: Phase 5F in plugin version `0.1.12` implements a narrow
manual memory slice from this design through `memory-list`, `memory-show`,
`memory-search`, `memory-add`, and `memory-deprecate` wrapper commands and the
`taskmanager-engine-memory` skill. It remains limited to explicit memory list,
detail, search, single-row add, and status-only deprecation; it does not claim
full upstream `memory`, research, or TaskManager runtime parity.

Post-design update: Phase 5G in plugin version `0.1.13` implements a narrow
manual task-operation slice from this design through `task-add`,
`task-set-status`, `task-update-title`, and soft `task-archive` wrapper commands
and the `taskmanager-engine-task` skill. It remains limited to explicit
single-row task mutation, does not cascade parent statuses or write verification
rows, and does not claim full upstream `update` or TaskManager runtime parity.

## Context

The upstream TaskManager plugin in `../mwguerra-plugins/taskmanager` provides a
SQLite-backed command set for planning, running, verifying, showing, updating,
exporting, researching, and managing project memories. The upstream files are
Claude Code slash-command specifications and rely on Claude-specific affordances
such as command registration, `Task` subagents, `AskUserQuestion`, `WebSearch`,
and `CLAUDE_PLUGIN_ROOT`.

The Codex port must not copy those runtime assumptions blindly. A future runtime
parity implementation needs explicit Codex-native wrappers, precise storage
boundaries, and tests that prove what is supported before the README or release
notes say it is supported.

Evidence inspected for this design:

- `README.md`
- `docs/PARITY-GAP-ANALYSIS.md`
- `docs/VERIFY.md`
- `docs/RELEASE-READINESS-0.1.10.md`
- `plugins/engineering-discipline/.codex-plugin/plugin.json`
- `plugins/engineering-discipline/skills/taskmanager-lite/SKILL.md`
- `plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/`
- `plugins/engineering-discipline/skills/taskmanager-engine-*/SKILL.md`
- upstream `../mwguerra-plugins/taskmanager/commands/*.md`
- upstream `../mwguerra-plugins/taskmanager/skills/*.md`
- upstream `../mwguerra-plugins/taskmanager/agents/*.md`
- upstream `../mwguerra-plugins/taskmanager/schemas/*.sql` and tests

## Goals

- Record the current `0.1.10` TaskManager baseline honestly.
- Map the upstream command surface to current Codex support and future gaps.
- Define a Codex-native architecture for future explicit runtime wrappers.
- Preserve the safety posture: manual execution, no hooks, no auto-run, no hidden
  mutation, and writes bounded to a user-supplied project directory.
- Define a test strategy strong enough to support future incremental parity
  claims.
- Recommend small implementation slices after this design.

## Non-goals For Phase 5D

- No runtime implementation.
- No new wrapper subcommands.
- No new skills.
- No hook changes or hook enablement.
- No plugin version bump.
- No implementation of `plan`, `run`, `verify`, `show`, `update`, `memory`, or
  `research`.
- No full upstream TaskManager parity claim.

## Current Implemented Baseline In 0.1.10

Version `0.1.10` includes 26 first-class Codex skills. The TaskManager-related
baseline is:

- Phase 5A: passive SQLite engine artifacts under
  `plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/`.
- Phase 5B: a manual Bash wrapper at
  `plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh`.
- Phase 5C: first-class Codex skills for explicit manual wrapper operations:
  `taskmanager-engine-init`, `taskmanager-engine-status`,
  `taskmanager-engine-next`, `taskmanager-engine-export`, and
  `taskmanager-engine-test`.

The copied engine artifacts include:

- `schemas/schema.sql` for SQLite schema version `4.2.0`.
- `schemas/default-config.json`.
- `schemas/queries.sql`.
- migrations for `v4.0 -> v4.1` and `v4.1 -> v4.2`.
- copied SQL and lifecycle tests.
- wrapper CLI tests.
- usage and notes documentation.

The current wrapper supports only these manual commands:

- `init [PROJECT_DIR]`
- `status [PROJECT_DIR]`
- `next [PROJECT_DIR]`
- `export-json [PROJECT_DIR]`
- `run-sql-tests`
- `help`

Current validation already recorded for `0.1.10`:

- `test_sql_queries.sh` passed `285/0`.
- `test_lifecycle_e2e.sh` passed `30/0`.
- `test_wrapper_cli.sh` passed `19/0`.
- wrapper smoke passed for `init`, `status`, `next`, `export-json`, and
  `run-sql-tests`.

Those results validate the copied SQLite artifacts and limited manual wrapper.
They do not validate full upstream TaskManager runtime parity.

## Upstream TaskManager Command Surface

The upstream TaskManager command set is:

| Upstream command | Upstream purpose | Mutation profile | Current Codex support |
|---|---|---|---|
| `init` | Initialize `.taskmanager/` with schema, config, logs, and PRD template; detect old schema versions. | Writes `.taskmanager/`. | Partially supported by manual `init`; current wrapper creates DB/config/logs and refuses existing DB, but does not implement the whole upstream init UX. |
| `plan` | Parse PRD file, folder, or prompt; analyze risks; create plan analyses, memories, milestones, tasks, dependencies, and optional expansions. | Writes many DB tables and logs. | Not implemented. `taskmanager-lite` is database-free planning guidance only. |
| `run` | Select or execute tasks, apply memories and deferrals, update statuses, perform work, verify before done, and propagate status. | Mutates DB and may mutate repository files when performing task work. | Not implemented. |
| `verify` | Verify tasks, milestones, or PRD criteria with captured evidence and adversarial review; record verification rows. | Mutates verification rows and task status. | Not implemented. |
| `show` | Read dashboard, task details, next tasks, stats, deferrals, milestones, verification, and plan analyses. | Read-only. | Phase 5E implements a limited read-only subset: overview, task list/detail, milestones, memories, deferrals, verifications, and regressions. Full upstream `show` is not implemented. |
| `update` | Modify task fields, status, tags, dependencies, milestones, deferrals, and scope. | Mutates DB. | Phase 5G implements a limited manual subset for add, status, title, and soft archive. Broad upstream `update` is not implemented. |
| `export` | Export JSON for tasks, memories, verifications, all data, or markdown task files. | Read-only for stdout JSON; writes when output file or task files requested. | Partially supported by `export-json` for core JSON to stdout. |
| `research` | Combine codebase analysis and web research, then store findings as memories. | Reads repo and network; mutates memories/state/logs. | Not implemented. |
| `memory` | Add, list, show, search, update, deprecate, supersede, and check memory conflicts. | Mixed read-only and DB mutation. | Phase 5F implements a limited manual subset: list, show, search, add, and status-only deprecate. Full upstream `memory` is not implemented. |

## Safely Supported By The Manual Wrapper

The current manual wrapper safely supports:

- initializing a user-specified project with `.taskmanager/taskmanager.db`,
  `.taskmanager/config.json`, and `.taskmanager/logs/`;
- refusing to overwrite an existing `.taskmanager/taskmanager.db`;
- reading schema version and core table counts;
- reading rows from `v_next_task`;
- explicit single-row task add, status update, title update, and soft archive;
- read-only memory list, detail, and search, with FTS preferred and LIKE fallback;
- explicit single-row memory add and status-only deprecation;
- exporting core JSON data to stdout without mutating the database;
- running copied SQL and lifecycle tests in disposable test state;
- no hook changes, no Codex command registration, no background jobs, no task
  execution, and no hidden runtime services.

The current wrapper does not safely support:

- planning from PRDs into the DB;
- executing or verifying tasks;
- broad task updates for tags, dependencies, milestones, deferrals, scope, or done gates;
- memory update, supersede, conflict reconciliation, or research-backed memory workflows;
- research;
- full dashboards or stats;
- output file generation except when a user redirects stdout themselves;
- schema migration orchestration;
- automatic subagent verification;
- any repository edits outside `.taskmanager/`.

## Missing For Runtime Parity

Runtime parity is missing in these areas:

- Codex-native wrappers for upstream `plan`, `run`, `verify`, `show`, `update`,
  `memory`, and `research`.
- Full `export` modes, especially table-selective exports and markdown task file
  generation.
- Upstream-style `init` details such as PRD template creation, activity log
  initialization, version-aware migration guidance, and full install reporting.
- Explicit migration command wrappers and tests for user-owned databases.
- Session and activity log handling for every mutating command.
- SQL-safe insertion and update paths for all JSON fields.
- Plan import validation before writing milestones, tasks, memories, and analyses.
- A done gate that records both acceptance verification and regression evidence.
- A Codex-native substitute for upstream automatic verifier subagents.
- A clear interaction model for user questions that replaces upstream
  `AskUserQuestion` without hiding decisions.
- Safe research behavior that never performs network research or memory writes
  unless explicitly requested.
- Tests that prove command-level behavior and database before/after state.

## Proposed Codex-native Architecture

Future runtime parity should use explicit manual wrappers plus first-class Codex
operator skills. The term `taskmanager-engine-*` in this design refers to future
Codex skill/operator entry points backed by explicit wrapper subcommands where a
shell wrapper is appropriate. No such future entry points are added in Phase 5D.

### Layers

1. Engine artifact layer

   Owns copied schema, migrations, default config, query catalog, and artifact
   tests. This layer remains passive until a wrapper command is run.

2. Wrapper layer

   Owns deterministic filesystem and SQLite operations. It should use Bash plus
   `sqlite3`, keep SQL writes in transactions, validate enum values before
   mutation, and return non-zero on invalid input. It should not call Codex,
   invoke agents, perform web research, or edit repository source files.

3. Codex operator skill layer

   Owns LLM-dependent work: PRD interpretation, task decomposition, evidence
   assessment, user-facing summaries, and explicit user decisions. Skills call the
   wrapper only after the project directory and intended operation are clear.

4. Repository work layer

   Applies only to future `run`. Codex may edit repository files only when the
   user explicitly asks to run or implement a task. The TaskManager database may
   record task state and evidence, but the wrapper itself must not make source
   edits.

### Command Contract

Future mutating commands should require an explicit `PROJECT_DIR`. The current
wrapper accepts an omitted project directory and defaults to `PWD`; future skills
should still resolve and report the exact project path before any mutation.

Each future wrapper command should define:

- arguments and default behavior;
- read-only versus mutating mode;
- exact DB tables/views touched;
- whether output is human text, JSON, or both;
- transaction boundary;
- before/after assertions used by tests;
- error conditions and exit codes;
- whether an operation can write files and where.

### Data Flow

For LLM-dependent commands, use a two-stage flow:

1. Codex skill gathers context and produces a structured payload or evidence
   summary.
2. Wrapper validates and persists that payload in one SQLite transaction.

This keeps the shell wrapper deterministic and testable while preserving Codex as
the explicit reasoning layer.

### Failure Behavior

- Missing `sqlite3` returns dependency failure.
- Missing `.taskmanager/taskmanager.db` reports initialization guidance and does
  not create state unless the command is `init`.
- Read-only commands open the database in read-only mode.
- Mutating commands fail before partial writes when validation fails.
- Multi-row writes use transactions.
- No command deletes `.taskmanager/` or wipes a database.
- Migrations are explicit commands only, with backup and version checks.

## Safety Model

Future runtime wrappers must preserve these rules:

- Explicit/manual execution only.
- No auto-run.
- No hooks.
- No background jobs.
- No hidden mutation.
- User-supplied project directory for every meaningful operation.
- No destructive reset, wipe, or recreate behavior.
- No implicit repository-wide mutation.
- No network access unless the user explicitly asks for research.
- No claim that enforcing hooks or automatic runtime behavior are reliable.

Mutating commands may write only the state they explicitly own. A future `run`
skill may edit repository files only because the user asked Codex to execute a
task; that is separate from the wrapper's database mutation boundary.

## Data Model And Storage Boundaries

The TaskManager engine owns only `PROJECT_DIR/.taskmanager/`.

Expected files and directories:

```text
PROJECT_DIR/.taskmanager/
  config.json
  logs/
  taskmanager.db
  docs/              # only when explicitly created by init/export behavior
```

SQLite schema `4.2.0` includes:

- `milestones`
- `plan_analyses`
- `tasks`
- `memories`
- `memories_fts`
- `deferrals`
- `verifications`
- `state`
- `regression_checks`
- `schema_version`

Important views include:

- `v_next_task`
- `v_next_task_sequential`
- `v_task_verification`
- `v_milestone_verification`
- `v_prd_verification`
- `v_milestone_status`
- `v_task_regression`

Storage rules:

- Writes are limited to `PROJECT_DIR/.taskmanager/`.
- Schema migrations are explicit only.
- Migration scripts must check source version, write backups under
  `.taskmanager/`, and never delete user data as a shortcut.
- Read-only commands must not alter `taskmanager.db`, logs, config, or docs.
- Export to stdout is read-only.
- Export to files writes only to a user-requested path or to
  `.taskmanager/docs/tasks/` when that mode is explicitly invoked.
- No repository-wide mutation occurs unless the user asks Codex to execute a task
  through future `run` behavior.

## Future Command Design

### `taskmanager-engine-plan`

Purpose:

- Convert a PRD file, folder, or user prompt into validated SQLite state:
  `plan_analyses`, `milestones`, `tasks`, and selected `memories`.

Codex-native design:

- Codex reads PRD inputs and existing docs explicitly.
- Codex produces a structured plan payload with tasks, dependencies, acceptance
  criteria, test strategy, milestones, risks, assumptions, and decisions.
- Wrapper validates enum values, task IDs, dependency references, milestone IDs,
  JSON columns, and required fields.
- Wrapper inserts the plan in a single transaction.
- The first implementation should support a preview/dry-run path before an
  apply path, so users can inspect the generated plan before DB mutation.

Safety:

- No task execution.
- No repository source edits.
- No automatic research unless the user explicitly asks for it.
- No auto-expansion loop until basic plan import is tested.

Parity gaps remaining after a first safe implementation:

- Upstream macro questions and milestone generation may need staged support.
- Automatic expansion should be a later slice.
- LLM-generated plan quality is a Codex skill responsibility, not a shell script
  responsibility.

### `taskmanager-engine-run`

Purpose:

- Execute a selected task or explicit batch using DB state, memories, deferrals,
  and verification gates.

Codex-native design:

- Wrapper can select the next task, mark it `in-progress`, record session state,
  and record completion metadata.
- Codex performs repository edits only after the user explicitly invokes the run
  workflow.
- Before marking `done`, Codex must gather verification evidence and the wrapper
  must confirm required verification/regression rows exist.
- Batch mode requires an explicit batch count and should stop on the first
  failed verification or ambiguous user decision.

Safety:

- No autonomous background execution.
- No hidden selection of large batches.
- No status `done` without explicit evidence or explicit human override.
- Deferrals must be recorded rather than silently dropped.

Parity gaps:

- Upstream relies on automatic verifier subagents. Codex parity needs an explicit,
  tested verification mechanism before claiming equivalence.

### `taskmanager-engine-verify`

Purpose:

- Verify task, milestone, or PRD acceptance criteria and record verification
  history.

Codex-native design:

- Wrapper loads target criteria and records verification rows.
- Codex runs or inspects the relevant evidence using existing verification
  discipline.
- The command records `self` evidence separately from adversarial results.
- Overrides require an explicit reason and are stored as `overridden`.
- Milestone and PRD verification should be added after task verification is
  proven.

Safety:

- Verification does not implement fixes.
- Failed criteria move the task to `needs-review`.
- Empty acceptance criteria fail closed for milestone/PRD value gates.
- No automatic subagent claim unless a Codex multi-agent workflow is implemented
  and tested separately.

### `taskmanager-engine-show`

Purpose:

- Provide read-only dashboard, task detail, next-task, stats, deferral,
  milestone, verification, regression, and analysis views.

Codex-native design:

- Implement first because it is read-only and broadens observability.
- Use `sqlite3 -readonly`.
- Support human tables and JSON output where practical.
- Reuse canonical views from `schema.sql` for next-task and verification status.

Safety:

- Must not write logs, state, config, or DB rows.
- Tests should compare DB checksums before and after every show mode.

### `taskmanager-engine-update`

Purpose:

- Modify task fields, status, tags, dependencies, milestones, and deferrals.

Codex-native design:

- Start with small DB-only updates: title, description, priority, type,
  complexity, tags, dependencies, milestone assignment, and acceptance criteria.
- Validate every enum and foreign key before mutation.
- Use JSON-aware updates for JSON columns.
- Add milestone and deferral operations in later slices.
- AI-assisted rewrites should stay in the Codex skill layer and persist only
  after preview and explicit confirmation.

Safety:

- Direct `done` status updates should either be blocked until verification gates
  pass or require an explicit override reason recorded in the DB.
- No task deletion or destructive reparenting without a narrow, tested command.
- No source file edits.

### `taskmanager-engine-memory`

Purpose:

- Manage long-lived project memories in `memories` and `memories_fts`.

Phase 5F implemented subset:

- `memory-list PROJECT_DIR [limit]` opens the DB read-only and lists memory id,
  type, importance, confidence, status, and title.
- `memory-show PROJECT_DIR MEMORY_ID` opens the DB read-only and shows one
  memory's useful fields.
- `memory-search PROJECT_DIR QUERY [limit]` opens the DB read-only, tries
  `memories_fts` first, and falls back to `LIKE` over title/body/tags when FTS
  is unavailable or rejects the query syntax.
- `memory-add PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]` validates
  enum/range/text inputs and inserts one active row with the next `M-NNN` id.
- `memory-deprecate PROJECT_DIR MEMORY_ID REASON` validates the id/reason and
  sets `status = 'deprecated'` without deleting data. The schema has no clean
  deprecation-reason field, so the reason is not stored.

Codex-native design:

- Implement read modes first: list, show, search, stats.
- Add mutating modes after read modes are tested: add, update, deprecate,
  supersede.
- Conflict detection should be advisory first and never rewrite memory history
  automatically.
- Codex asks or infers missing fields visibly before persistence.

Safety:

- User-created memories are not auto-updated.
- Supersession preserves history.
- FTS search uses safe escaping or parameterized helper behavior where possible.
- No deletion, web research, auto-classification, or hidden conflict
  reconciliation occurs in Phase 5F.

### `taskmanager-engine-research`

Purpose:

- Research a topic through explicit codebase inspection and optional web research,
  then store findings as memories.

Codex-native design:

- Start with codebase-only research.
- Web research is opt-in per invocation and must cite sources.
- The skill synthesizes findings; the wrapper persists selected memories only
  after explicit apply.
- Task-scoped research must populate `scope.tasks` so future run workflows can
  load it deliberately.

Safety:

- No hidden network access.
- No automatic memory writes from casual research.
- No claim that research is current unless it was freshly checked.
- Sources and timestamps should be stored in memory links/body when web research
  is used.

### Current And Future `init` / `export`

`init` and `export-json` already exist in limited form. Future hardening should:

- keep `init` refusing existing DB overwrite;
- add upstream-compatible PRD template and activity log behavior only when tested;
- add version-aware migration guidance without auto-migration;
- keep JSON export read-only by default;
- add table-selective export modes before markdown file generation;
- require explicit output path for exports outside stdout.

## Testing Strategy

Existing evidence remains useful but limited:

- SQL query suite: `test_sql_queries.sh`.
- Lifecycle suite: `test_lifecycle_e2e.sh`.
- Wrapper CLI suite: `test_wrapper_cli.sh`.
- Manual wrapper smoke for `init`, `status`, `next`, `export-json`, and
  `run-sql-tests`.

Future command wrappers need new tests:

- one wrapper CLI test file per command or one clearly partitioned runtime wrapper
  test suite;
- disposable temp repositories only;
- no test points at a real user project;
- before/after database assertions for every mutating command;
- checksum or timestamp assertions proving read-only commands did not mutate DB
  files;
- transaction rollback tests for invalid enum, invalid dependency, invalid JSON,
  missing DB, missing view, missing `sqlite3`, and duplicate IDs;
- migration tests using copied fixture databases for every supported source
  version;
- output contract tests for human and JSON modes;
- evidence-row tests for verification and regression gates;
- explicit negative tests that `done` cannot be reached without required evidence;
- export tests that write only to temp output paths;
- research tests that stub or skip network and prove no web call is made unless
  explicitly requested.

Testing must not rely on hooks, background jobs, or live Codex installation
behavior unless a future phase explicitly changes hook policy and records live
smoke-test evidence.

## Risk Analysis

| Risk | Impact | Mitigation |
|---|---|---|
| Accidental mutation | A wrapper could alter a real project or DB unexpectedly. | Require explicit project path, keep read-only commands read-only, use temp repos in tests, and document every write path. |
| Overclaiming parity | Users may rely on unsupported runtime behavior. | Keep docs and release notes precise; claim only command slices with passing tests. |
| Migration safety | A faulty migration could corrupt `.taskmanager/taskmanager.db`. | Make migrations explicit, version-gated, backed up, and tested on fixtures. |
| Planning skill vs SQLite engine ambiguity | Users may confuse `taskmanager-lite` plans with DB-backed TaskManager state. | Keep naming explicit: `taskmanager-lite` is database-free; `taskmanager-engine-*` requires initialized engine state. |
| Lack of automatic subagents | Upstream verification assumes a verifier subagent. | Do not claim automatic verifier parity. Use explicit Codex verification until multi-agent behavior is implemented and tested. |
| SQL/JSON escaping bugs | Generated plans and updates could corrupt JSON columns or fail constraints. | Validate payloads before SQL, use transactions, and add tests for quotes, newlines, dotted IDs, and JSON arrays/objects. |
| Network research freshness | Research could become stale or run without consent. | Make web research opt-in, source-linked, and timestamped. |
| Direct `done` bypass | Manual status update could skip verification gates. | Block or require explicit override with recorded reason. |

## Alternatives Considered

1. Directly port upstream slash-command markdown.

   Rejected for runtime parity because upstream commands assume Claude Code
   command registration, `Task` subagents, and Claude-specific environment
   variables.

2. Keep only `taskmanager-lite`.

   Safe, but it does not address future SQLite runtime parity and leaves the
   copied engine artifacts underused.

3. Put all behavior in one large shell wrapper.

   Too hard to test and too likely to mix LLM reasoning with deterministic DB
   mutation. The preferred design keeps reasoning in Codex skills and persistence
   in wrapper subcommands.

## Recommended Implementation Slices

1. Phase 5E: runtime foundation and read-only `show`.

   Add shared wrapper helpers only if needed, require explicit project paths for
   new commands, and implement `show` modes that are provably read-only.

2. Phase 5F: safe manual memory operations. Completed in `0.1.12`.

   Implemented list/show/search, explicit add, and status-only deprecate with
   before/after DB assertions and no hook changes.

3. Phase 5G: safe manual task operations. Completed in `0.1.13`.

   Implemented explicit task add, status update, title update, and soft archive
   with before/after DB assertions and no hook changes.

4. Future slice: export hardening.

   Add table-selective JSON export and explicit output-file behavior before
   markdown task file generation.

5. Future slice: broader DB-only `update` workflows.

   Implement simple field updates, tag/dependency edits, and guarded status
   changes before AI-assisted rewrites or scope cascades.

5. Phase 5I: `plan` payload import.

   Implement preview plus explicit apply for a structured plan payload. Add
   milestone/task/analysis insertion in one transaction.

6. Phase 5J: `verify` recording and gates.

   Record verification rows from explicit evidence and enforce `needs-review`
   routing before integrating with `run`.

7. Phase 5K: explicit `run` orchestration.

   Add task selection, status transitions, memory/deferral display, and a done
   gate. Repository edits remain explicit Codex work, not wrapper-side behavior.

8. Phase 5L: explicit `research`.

   Start codebase-only, then add opt-in web research with source-linked memory
   persistence.

Each slice should update `docs/PARITY-GAP-ANALYSIS.md`, `docs/VERIFY.md`, and
release readiness notes only for behavior actually implemented and tested.

## Revisit Triggers

Revisit this design when any of these become true:

- Codex exposes a stable command registration model that is preferable to skills
  plus manual wrappers.
- Codex multi-agent verification is implemented and tested in this plugin.
- A live install proves stricter hooks are reliable and a separate phase chooses
  to change hook defaults.
- The TaskManager schema changes upstream beyond `4.2.0`.
- Wrapper tests show the single-script approach is becoming too hard to maintain,
  making a small command library worth the added complexity.

## Explicit Non-goals For Future Runtime Parity

- No Claude-specific runtime dependencies.
- No automatic TaskManager execution.
- No hook-driven TaskManager behavior.
- No background scheduler or daemon.
- No destructive reset, wipe, or recreate command.
- No hidden migrations.
- No repository-wide mutation unless the user explicitly asks Codex to execute a
  task.
- No silent memory capture from unrelated work.
- No web research without explicit user intent.
- No full parity claim until every claimed command path has direct test evidence.
