# Parity gap analysis

## Snapshot

- Original repository: `../mwguerra-plugins`
- Original commit/tag: `7bab128` / `v0.1.0`
- Codex repository baseline: `05d80f9`
- Goal: track what has been ported from the original Claude Code plugin suite to the Codex-native plugin.

## Current Codex coverage

The current Codex port provides one consolidated plugin:

- `engineering-discipline`

It currently includes:

- `.agents/plugins/marketplace.json`
- `plugins/engineering-discipline/.codex-plugin/plugin.json`
- advisory hooks enabled by default
- optional extended advisory hooks kept out of default config
- optional strict hooks kept out of default config
- 28 first-class Codex skills
- selected Codex-adapted references and templates under existing skill directories
- 8 Codex-native agent/persona reference guides under existing skill directories
- TaskManager SQLite engine artifacts and a manual opt-in wrapper under
  `taskmanager-lite/references/taskmanager-engine/`

Current Codex skills:

- `architect-design`
- `architect-refine`
- `architect-review`
- `filament-conventions`
- `laravel-conventions`
- `maestro-adversarial-verify`
- `maestro-deep-analysis`
- `maestro-deep-work`
- `maestro-implement`
- `maestro-journey`
- `maestro-regression`
- `maestro-route`
- `prd-builder-bugfix`
- `prd-builder-feature`
- `prd-builder-prd`
- `prd-builder-refine`
- `scribe-docs-discipline`
- `scribe-init`
- `scribe-sync`
- `scribe-verify`
- `taskmanager-engine-export`
- `taskmanager-engine-init`
- `taskmanager-engine-memory`
- `taskmanager-engine-next`
- `taskmanager-engine-show`
- `taskmanager-engine-status`
- `taskmanager-engine-test`
- `taskmanager-lite`

Current Codex reference/template/persona coverage:

- `architect-design/references/`: design heuristics, seam catalog, and architect persona.
- `architect-review/references/`: design adversary persona.
- `filament-conventions/references/`: Filament v5 recipes with target-project version checks.
- `maestro-deep-analysis/references/`: audit plan and `docs/deep-analysis/` output structure.
- `maestro-implement/references/`: expanded implementation process and implementer persona.
- `prd-builder-prd/references/` and `templates/`: question bank, default stack profile,
  design-review lenses, PRD interviewer persona, and PRD template.
- `scribe-docs-discipline/references/` and `templates/`: canonical docs layout plus docs
  README, STATUS, ADR, incident, roadmap, open-question templates, and doc curator persona.
- `scribe-verify/references/`: doc verifier persona.
- `taskmanager-lite/references/`: planning question bank, PRD-to-task example,
  TaskManager-lite planning persona, acceptance verifier persona, TaskManager SQLite engine
  artifacts, and a manual engine wrapper.
- `taskmanager-engine-*`: first-class Codex skills for explicit manual wrapper operation
  (`init`, `status`, `next`, read-only `show`, manual memory operations, `export-json`, and
  copied engine tests).

## Original Claude plugins

The original suite has six Claude Code plugins:

- `architect`
- `laravel`
- `maestro`
- `prd-builder`
- `scribe`
- `taskmanager`

The Codex port currently consolidates them into one plugin. This is acceptable for the first Codex-native package, but parity tracking must still preserve the original plugin boundaries conceptually.

## Commands ported as first-class Codex skills

### Architect

- `architect/commands/design.md` -> `architect-design`
- `architect/commands/refine.md` -> `architect-refine`
- `architect/commands/review.md` -> `architect-review`

### Maestro

- `maestro/commands/adversarial-verify.md` -> `maestro-adversarial-verify`
- `maestro/commands/deep-analysis.md` -> `maestro-deep-analysis`
- `maestro/commands/deep-work.md` -> `maestro-deep-work`
- `maestro/commands/implement.md` -> `maestro-implement`
- `maestro/commands/journey.md` -> `maestro-journey`
- `maestro/commands/regression.md` -> `maestro-regression`
- `maestro/commands/route.md` -> `maestro-route`

### PRD Builder

- `prd-builder/commands/bugfix.md` -> `prd-builder-bugfix`
- `prd-builder/commands/feature.md` -> `prd-builder-feature`
- `prd-builder/commands/prd.md` -> `prd-builder-prd`
- `prd-builder/commands/refine.md` -> `prd-builder-refine`

### Scribe

- `scribe/commands/init.md` -> `scribe-init`
- `scribe/commands/sync.md` -> `scribe-sync`
- `scribe/commands/verify.md` -> `scribe-verify`

`scribe-docs-discipline` remains the general docs discipline skill.

## Commands not yet ported as full Codex runtime wrappers

### TaskManager

The original TaskManager command set has not been ported as full Codex runtime wrappers yet:

- `taskmanager/commands/export.md`
- `taskmanager/commands/init.md`
- `taskmanager/commands/memory.md`
- `taskmanager/commands/plan.md`
- `taskmanager/commands/research.md`
- `taskmanager/commands/run.md`
- `taskmanager/commands/show.md`
- `taskmanager/commands/update.md`
- `taskmanager/commands/verify.md`

`taskmanager-lite` remains the active planning workflow. Phase 5A adds SQLite engine artifacts,
Phase 5B adds a small manual shell wrapper for `init`, `status`, `next`, `export-json`, and
`run-sql-tests`, Phase 5C adds first-class Codex skills that operate that wrapper explicitly,
Phase 5E adds read-only `show` runtime visibility, and Phase 5F adds safe manual memory
operations:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-show`
- `taskmanager-engine-memory`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

Those skills are operator guides around the manual wrapper. They are not hidden runtime services,
are not registered Codex commands, and do not make this parity with the SQLite-backed original.
The Phase 5E `show` support is limited to read-only overview/detail/list views over initialized
engine state; it does not execute tasks, update statuses, write verification rows, or implement
the full upstream `show` UX.
The Phase 5F memory support is limited to manual `memory-list`, `memory-show`,
`memory-search`, `memory-add`, and `memory-deprecate`; it does not implement upstream memory
update/supersede/conflict workflows or research-backed memory behavior.
Phase 5D records a future runtime design in
[`docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md`](PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md);
Phase 5E implements the first read-only visibility slice from that design, and Phase 5F
implements a narrow manual memory slice.

## Skill coverage and remaining gaps

### Laravel

Already represented:

- `laravel/skills/filament-conventions/SKILL.md` -> `filament-conventions`
- `laravel/skills/laravel-conventions/SKILL.md` -> `laravel-conventions`

### Maestro discipline skills

The original always-on discipline skills are not yet first-class Codex skills:

- `maestro/skills/context-thrift/SKILL.md`
- `maestro/skills/cross-project/SKILL.md`
- `maestro/skills/finish-your-turn/SKILL.md`
- `maestro/skills/native-code/SKILL.md`
- `maestro/skills/outcome-first/SKILL.md`
- `maestro/skills/prove-it/SKILL.md`
- `maestro/skills/retrospective/SKILL.md`
- `maestro/skills/scope-discipline/SKILL.md`
- `maestro/skills/thoughts/SKILL.md`

### Maestro process skills

Already represented:

- `maestro/skills/adversarial-verify/SKILL.md`
- `maestro/skills/deep-analysis/SKILL.md`
- `maestro/skills/deep-work/SKILL.md`
- `maestro/skills/implementation/SKILL.md`
- `maestro/skills/regression/SKILL.md`
- `maestro/skills/route/SKILL.md`

### PRD Builder

- `prd-builder/skills/prd-interview/SKILL.md`

Not yet ported.

### TaskManager

- `taskmanager/skills/taskmanager-memory/SKILL.md`

Partially represented by `taskmanager-engine-memory` for explicit manual wrapper
operations. Full upstream memory skill parity is still not claimed.

`taskmanager/skills/taskmanager/SKILL.md` is only lightly represented by `taskmanager-lite`.
The underlying SQLite schema, migrations, query catalog, copied SQL tests, and a small manual
wrapper are now present under `taskmanager-lite/references/taskmanager-engine/`, with
first-class Codex skills for the supported manual wrapper operations.
Phase 5E adds limited read-only `show` visibility, and Phase 5F adds safe manual
memory list/show/search/add/deprecate operations, but this is still not full
TaskManager command parity.

## Original agents converted to Codex references

The original Claude-oriented agent files have been converted to a Codex-native
reference/persona strategy. They are passive skill-local guides, not automatically executed
subagents:

| Original agent file | Codex reference/persona guide |
|---|---|
| `architect/agents/architect.md` | `architect-design/references/agent-architect.md` |
| `architect/agents/design-adversary.md` | `architect-review/references/agent-design-adversary.md` |
| `maestro/agents/implementer.md` | `maestro-implement/references/agent-implementer.md` |
| `prd-builder/agents/prd-interviewer.md` | `prd-builder-prd/references/agent-prd-interviewer.md` |
| `scribe/agents/doc-curator.md` | `scribe-docs-discipline/references/agent-doc-curator.md` |
| `scribe/agents/doc-verifier.md` | `scribe-verify/references/agent-doc-verifier.md` |
| `taskmanager/agents/taskmanager.md` | `taskmanager-lite/references/agent-taskmanager.md` |
| `taskmanager/agents/verifier.md` | `taskmanager-lite/references/agent-verifier.md` |

See `docs/AGENT-STRATEGY.md` for the strategy and explicit non-claims.

## Hooks ported or not enabled by default

Current default Codex hooks:

- `read_docs_first.sh`
- `verify_before_commit.sh`
- `restart_reminder.sh`

Current optional extended advisory hooks:

- `asset_inventory_gate.sh`
- `ls_real_preflight.sh`
- `self_challenge_gate.sh`
- `session_retro.sh`
- `docs_update_gate.sh`
- `curate_on_stop.sh`

Current optional strict hooks:

- `verify_commit_gate.sh`
- `verify_stop_gate.sh`

Original hooks intentionally not default-enabled:

- extended advisory reminders remain opt-in;
- strict verification gates remain opt-in.

## TaskManager engine artifacts, manual wrapper, and wrapper skills

Phase 5A, Phase 5B, Phase 5C, Phase 5E, and Phase 5F include the SQLite-backed TaskManager engine
artifacts, manual wrapper, read-only visibility, manual memory operations, and manual wrapper
operation skills under
`plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/`:

- `schemas/default-config.json`
- `schemas/migrate-v4.0-to-v4.1.sh`
- `schemas/migrate-v4.1-to-v4.2.sh`
- `schemas/queries.sql`
- `schemas/schema.sql`
- `bin/taskmanager-engine.sh`
- `tests/fixtures/verify-guard-sql.md`
- `tests/test_wrapper_cli.sh`
- `tests/test_lifecycle_e2e.sh`
- `tests/test_sql_queries.sh`
- `USAGE.md`

Phase 5C also adds these skill entry points under `plugins/engineering-discipline/skills/`:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

Phase 5E adds:

- `taskmanager-engine-show`

Phase 5F adds:

- `taskmanager-engine-memory`

This is artifact/reference parity plus a limited manual wrapper and skill-level operator guides,
not full runtime parity. The copied tests are adapted only to read the upstream verify guard SQL
from a local passive test fixture because Phase 5A does not port
`taskmanager/commands/verify.md` as a command. The Phase 5B wrapper initializes and inspects the
copied SQLite engine, Phase 5C documents that wrapper as first-class skills, Phase 5E adds
read-only `show` visibility for initialized engine state, and Phase 5F adds explicit memory
list/show/search/add/deprecate operations. These phases do not implement the original
TaskManager command set.

## Recommended conversion phases

### Phase 1 — Finish first-class Codex skill coverage

Status: completed in Codex plugin `0.1.4`.

Added high-value skills without porting engines:

- `maestro-deep-work`
- `maestro-regression`
- `maestro-journey`
- `prd-builder-prd`
- `prd-builder-feature`
- `prd-builder-bugfix`
- `prd-builder-refine`
- `scribe-init`
- `scribe-sync`
- `scribe-verify`
- `filament-conventions`
- `architect-refine`
- `architect-review`

### Phase 2 — Port docs/templates and reference material

Status: completed in Codex plugin `0.1.5`.

Added selected reference/template material from the original plugins under existing Codex skill
directories:

- architecture design heuristics and seam catalog;
- Filament v5 recipes, with explicit target-project version verification;
- Maestro deep-analysis audit plan and publish structure;
- expanded Maestro implementation process;
- PRD Builder question bank, default stack profile, design review, and PRD template;
- Scribe docs layout and templates for README, STATUS, ADR, incident, roadmap, and open
  questions;
- TaskManager-lite planning question bank and PRD-to-task example.

Deliberate exclusions in this phase:

- no hook behavior changes;
- no enforcing-hook enablement;
- no full TaskManager SQLite engine, schemas, migrations, query catalog, tests, or command
  engine;
- no external integrations, background jobs, or unrelated tooling;
- no new skills beyond the existing 21.

### Phase 3 — Port advisory hooks

Status: completed in Codex plugin `0.1.6` as optional extended advisory hooks.

Added Codex-native advisory versions of:

- asset inventory
- look-before-describe
- self-challenge
- session retrospective
- docs update reminder
- doc curation reminder

They are packaged in `plugins/engineering-discipline/hooks/extended-advisory-hooks.json`, which
also includes the existing default advisory reminders. The plugin entry-point
`hooks/hooks.json` was not changed, so Phase 3 is not default-enabled.

### Phase 4 — Convert agents to a Codex strategy

Status: completed in Codex plugin `0.1.7` as passive Codex reference/persona guides.

Added skill-local guides for the original agent roles:

- architect persona;
- design adversary persona;
- implementer persona;
- PRD interviewer persona;
- doc curator persona;
- doc verifier persona;
- TaskManager-lite planning persona;
- acceptance verifier persona.

This phase deliberately does not claim automatic subagent execution, does not enable hooks,
does not change `hooks/hooks.json`, and does not port the full TaskManager SQLite engine.

### Phase 5A — Port TaskManager engine artifacts

Status: completed in Codex plugin `0.1.8` as passive artifacts. After installing `sqlite3` on WSL2, the copied artifact tests passed: `test_sql_queries.sh` 285/0 and `test_lifecycle_e2e.sh` 30/0.

Added under `taskmanager-lite/references/taskmanager-engine/`:

- SQLite schema `v4.2.0`;
- default config;
- query catalog;
- v4.0 -> v4.1 and v4.1 -> v4.2 migrations;
- copied SQL query and lifecycle test scripts;
- a passive verify-guard SQL fixture used by the copied query test.

Deliberate exclusions in this phase:

- no hook behavior changes;
- no changes to `hooks/hooks.json`;
- no strict hook enablement;
- no Codex command wrappers;
- no automatic TaskManager execution;
- no background jobs, external integrations, or repository migrations;
- no full TaskManager runtime parity claim.

### Phase 5B — Add safe manual TaskManager engine wrappers

Status: completed in Codex plugin `0.1.9` as explicit/manual wrappers only.

Added under `taskmanager-lite/references/taskmanager-engine/`:

- `bin/taskmanager-engine.sh`;
- `tests/test_wrapper_cli.sh`;
- `USAGE.md`.

The wrapper supports:

- `init [PROJECT_DIR]`;
- `status [PROJECT_DIR]`;
- `next [PROJECT_DIR]`;
- `export-json [PROJECT_DIR]`;
- `run-sql-tests`;
- `help`.

Deliberate exclusions in this phase:

- no hook behavior changes;
- no changes to `hooks/hooks.json`;
- no strict hook enablement;
- no first-class Codex command registration;
- no automatic TaskManager execution;
- no background jobs, external integrations, or schedulers;
- no upstream TaskManager `plan`, `run`, `verify`, `show`, `update`, `memory`, or `research`
  command parity;
- no full TaskManager runtime parity claim.

### Phase 5C — Add first-class manual wrapper operation skills

Status: completed in Codex plugin `0.1.10` as first-class Codex skills for explicit manual
wrapper operations.

Added under `plugins/engineering-discipline/skills/`:

- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-export`
- `taskmanager-engine-test`

These skills describe safe use of
`plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh`.
They cover initializing `PROJECT_DIR/.taskmanager`, read-only status/next/export inspection, and
copied engine test execution. They do not enable hooks, add background jobs, register Codex
commands, auto-run TaskManager, or claim full upstream TaskManager parity.

### Phase 5D — Consider broader TaskManager runtime parity

Status: documented as a design-only architecture phase after plugin `0.1.10`.

Phase 5D adds
[`docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md`](PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md),
which maps the upstream TaskManager command surface, current manual wrapper baseline, missing
runtime parity, safety model, storage boundaries, future command-by-command design, testing
strategy, risks, non-goals, and recommended implementation slices.

Deliberate exclusions in this phase:

- no plugin runtime behavior changes;
- no new wrapper subcommands;
- no new skills;
- no hook changes or hook enablement;
- no plugin version bump;
- no implementation of `plan`, `run`, `verify`, `show`, `update`, `memory`, or `research`;
- no full TaskManager runtime parity claim.

### Phase 5E — Safe read-only TaskManager runtime visibility

Status: completed in Codex plugin `0.1.11` as a limited read-only visibility slice.
Detailed behavior and safety notes are recorded in
[`docs/PHASE5E-TASKMANAGER-READONLY-RUNTIME.md`](PHASE5E-TASKMANAGER-READONLY-RUNTIME.md).

Added under `taskmanager-lite/references/taskmanager-engine/`:

- a manual `show PROJECT_DIR [view] [args...]` wrapper command;
- wrapper regression coverage proving `show` modes preserve the database checksum;
- usage documentation for read-only overview, task list, task detail, milestone,
  memory, deferral, verification, and regression views.

Added under `plugins/engineering-discipline/skills/`:

- `taskmanager-engine-show`

Supported `show` views:

- `overview`
- `tasks [limit]`
- `task TASK_ID`
- `milestones [limit]`
- `memories [limit]`
- `deferrals [limit]`
- `verifications [TASK_ID]`
- `regressions [TARGET_ID]`

Deliberate exclusions in this phase:

- no hook behavior changes;
- no changes to `hooks/hooks.json`;
- no strict hook enablement;
- no first-class Codex command registration;
- no automatic TaskManager execution;
- no background jobs, external integrations, or schedulers;
- no upstream TaskManager `plan`, `run`, `verify`, `update`, `memory`, or `research`
  command behavior;
- no mutation through `show`;
- no full upstream `show` parity claim;
- no full TaskManager runtime parity claim.

### Phase 5F — Safe manual TaskManager memory operations

Status: completed in Codex plugin `0.1.12` as a limited manual memory slice.
Detailed behavior and safety notes are recorded in
[`docs/PHASE5F-TASKMANAGER-MEMORY.md`](PHASE5F-TASKMANAGER-MEMORY.md).

Added under `taskmanager-lite/references/taskmanager-engine/`:

- manual read-only `memory-list PROJECT_DIR [limit]`;
- manual read-only `memory-show PROJECT_DIR MEMORY_ID`;
- manual read-only `memory-search PROJECT_DIR QUERY [limit]` with FTS-first and LIKE fallback;
- explicit mutating `memory-add PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]`;
- explicit mutating `memory-deprecate PROJECT_DIR MEMORY_ID REASON`;
- wrapper tests for empty memory listing, add/show/search/deprecate, FTS fallback, validation
  failures, and read-only checksum preservation.

Added under `plugins/engineering-discipline/skills/`:

- `taskmanager-engine-memory`

Deliberate exclusions in this phase:

- no hook behavior changes;
- no changes to `hooks/hooks.json`;
- no strict hook enablement;
- no first-class Codex command registration;
- no automatic TaskManager execution;
- no background jobs, external integrations, schedulers, or web research;
- no upstream TaskManager `plan`, `run`, `verify`, `update`, or `research` behavior;
- no memory update, supersede, conflict reconciliation, or research-backed memory workflow;
- no deletion of memories;
- no full upstream `memory` parity claim;
- no full TaskManager runtime parity claim.

## Current verdict

The repository is now a functional Codex plugin with Phase 1 skill coverage, Phase 2
reference/template coverage, Phase 3 optional extended advisory hook coverage, Phase 4
agent/persona reference coverage, Phase 5A TaskManager SQLite engine artifacts, Phase 5B manual
TaskManager engine wrappers, Phase 5C first-class manual wrapper operation skills, Phase 5D
runtime parity design, Phase 5E read-only TaskManager runtime visibility, and Phase 5F safe manual
TaskManager memory operations. It is still not a full parity port of the original
`mwguerra/plugins` suite. The `0.1.12` release readiness and
parity status checkpoint is recorded in
[`docs/RELEASE-READINESS-0.1.12.md`](RELEASE-READINESS-0.1.12.md).

The next safe TaskManager step is another incremental implementation slice from the Phase 5D
design, such as export hardening or small guarded update workflows. Do not claim full
SQLite-backed TaskManager runtime parity until the original command behavior exists and passes
direct validation.
