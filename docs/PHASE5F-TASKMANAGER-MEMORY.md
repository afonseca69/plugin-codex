# Phase 5F TaskManager Manual Memory Operations

## Status

Phase 5F is implemented in plugin version `0.1.12` as a safe, explicit, manual
memory-operation slice for initialized copied TaskManager SQLite engine state.

It does not enable hooks, register Codex commands, start background jobs,
auto-run TaskManager, execute tasks, update task statuses, write verification
rows, run research, perform web access, or claim full upstream TaskManager
memory/runtime parity.

## Added Runtime Surface

The manual wrapper now supports read-only memory commands:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-list PROJECT_DIR [limit]
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-show PROJECT_DIR MEMORY_ID
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-search PROJECT_DIR QUERY [limit]
```

It also supports explicit mutating memory commands:

```bash
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-add PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh memory-deprecate PROJECT_DIR MEMORY_ID REASON
```

`memory-search` prefers `memories_fts` when available. If FTS is unavailable or
rejects query syntax, the wrapper falls back to `LIKE` over title, body, and
tags.

`memory-add` inserts one active memory row and prints the created id.
`memory-deprecate` sets `status = 'deprecated'` without deleting the memory. The
schema has no clean deprecation-reason field, so the wrapper validates the
reason for operator intent and reports that the reason is not stored.

## Added Skill

Phase 5F adds one first-class Codex operator skill:

- `taskmanager-engine-memory`

The skill guides manual use of the wrapper. It is not a Codex command
registration layer and does not add hidden runtime behavior.

## Safety Boundaries

- `memory-list`, `memory-show`, and `memory-search` are read-only.
- `memory-add` and `memory-deprecate` mutate only
  `PROJECT_DIR/.taskmanager/taskmanager.db`.
- No memory deletion.
- No hook changes.
- No `hooks/hooks.json` changes.
- No enforcing-hook behavior changes.
- No background jobs, schedulers, external integrations, web research, or
  auto-run behavior.
- No implementation of `plan`, `run`, `verify`, `update`, `research`, migration,
  reset, wipe, import, or other broad TaskManager commands.
- No upstream memory update, supersede, conflict reconciliation, or
  research-backed memory workflow.
- No full upstream `memory` parity claim.
- No full upstream TaskManager parity claim.

## Verification Coverage

`tests/test_wrapper_cli.sh` now covers:

- help text for memory commands;
- `memory-list` on an empty initialized database;
- `memory-add` creating a memory and returning `M-001`;
- `memory-show` reading the created memory;
- `memory-search` finding the created memory;
- `memory-search` falling back to `LIKE` when FTS rejects query syntax;
- checksum preservation for read-only memory commands;
- `memory-deprecate` marking a memory deprecated without deleting it;
- missing and invalid argument failures for memory commands;
- continued `init`, `status`, `next`, `show`, `export-json`, and `run-sql-tests`
  wrapper behavior.

Latest local Phase 5F wrapper result: `test_wrapper_cli.sh` passed `77/0` while
also delegating to the copied SQL suite (`285/0`) and lifecycle suite (`30/0`)
through `run-sql-tests`.

## Remaining Gaps

The upstream TaskManager command set is still not ported as a full Codex
runtime. Remaining memory gaps include update, supersede, conflict checks,
research capture, source-linked research freshness, and any automatic memory
selection during task execution. These require their own explicit wrapper
commands, operator skills, and before/after database tests before any parity
claim.
