# Release readiness checkpoint: 0.1.13

## Summary

- Version: `0.1.13`
- Branch used for this checkpoint: `feat/phase5g-taskmanager-task-operations`
- Plugin entry point: `plugins/engineering-discipline/.codex-plugin/plugin.json`
- Default hook entry point: `plugins/engineering-discipline/hooks/hooks.json`
- Release posture: limited manual TaskManager task operations; no hook behavior change.

Version `0.1.13` is ready as a Codex-native plugin release checkpoint for Phase
5G. This is not a claim of full upstream parity with `mwguerra/plugins`.

## Added In 0.1.13

- Explicit mutating manual task commands:
  `task-add PROJECT_DIR TASK_ID TITLE [TYPE] [STATUS] [PARENT_ID]`,
  `task-set-status PROJECT_DIR TASK_ID STATUS`,
  `task-update-title PROJECT_DIR TASK_ID TITLE`, and
  `task-archive PROJECT_DIR TASK_ID`.
- First-class Codex skill: `taskmanager-engine-task`.
- Wrapper regression coverage for task creation, duplicate refusal, parent
  validation, status validation and timestamp behavior, title updates, soft
  archive, show/next visibility, and invalid/missing argument failures.
- Documentation for task command safety boundaries and remaining parity gaps.

## Current Supported Surface

The `0.1.13` plugin currently supports:

- one consolidated Codex plugin at `plugins/engineering-discipline`;
- default advisory-only hooks for documentation-first reminders, verification reminders before
  commit, and restart reminders;
- optional extended advisory hooks and optional enforcing hooks that remain out of
  `hooks/hooks.json`;
- Codex skills for Maestro, PRD Builder, Scribe, Architect, Laravel/Filament, TaskManager-lite,
  and manual TaskManager wrapper operation;
- passive TaskManager SQLite schema/config, migrations, query catalog, copied tests, and usage
  notes under `taskmanager-lite/references/taskmanager-engine/`;
- an explicit manual TaskManager wrapper at
  `taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh`;
- first-class wrapper operation skills:
  `taskmanager-engine-init`, `taskmanager-engine-status`, `taskmanager-engine-next`,
  `taskmanager-engine-show`, `taskmanager-engine-task`, `taskmanager-engine-memory`,
  `taskmanager-engine-export`, and `taskmanager-engine-test`.

## Non-claims

The `0.1.13` release does not claim:

- full upstream parity with the original Claude Code plugin suite;
- full SQLite-backed TaskManager runtime parity;
- Codex command registration for the original TaskManager command set;
- automatic TaskManager execution, schedulers, background jobs, or hidden runtime services;
- upstream TaskManager command parity for `plan`, `run`, `verify`, broad `update`, `research`,
  or full `memory`;
- full upstream `show` parity beyond the tested read-only visibility modes;
- full upstream `memory` parity beyond the tested manual list/show/search/add/deprecate modes;
- full upstream task/update parity beyond add/status/title/soft archive;
- parent status cascade, done gates, verification row writes, regression row writes, or task
  execution;
- default enablement of extended advisory hooks;
- default enablement of enforcing hooks;
- production reliability for enforcing hooks without live target-environment smoke testing;
- hook behavior changes.

## Validation Commands

Static validation for this checkpoint:

```bash
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/enforcing-hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/extended-advisory-hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/default-config.json >/dev/null
bash -n plugins/engineering-discipline/hooks/*.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/migrate-v4.0-to-v4.1.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/schemas/migrate-v4.1-to-v4.2.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_wrapper_cli.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_sql_queries.sh
bash -n plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_lifecycle_e2e.sh
python3 -c 'import ast; from pathlib import Path; ast.parse(Path("plugins/engineering-discipline/hooks/lib/json_value.py").read_text()); print("python syntax OK")'
git diff --check
find . -type d -name __pycache__ -print
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
```

TaskManager runtime validation for this checkpoint:

```bash
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_sql_queries.sh
bash tests/test_lifecycle_e2e.sh
bash tests/test_wrapper_cli.sh
```

Disposable task smoke:

```bash
ENGINE=plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
TMP=$(mktemp -d)
"$ENGINE" init "$TMP"
"$ENGINE" task-add "$TMP" 1 "Smoke parent task" feature planned
"$ENGINE" task-add "$TMP" 1.1 "Smoke child task" task planned 1
"$ENGINE" show "$TMP" tasks
"$ENGINE" show "$TMP" task 1.1
"$ENGINE" task-set-status "$TMP" 1.1 in-progress
"$ENGINE" task-update-title "$TMP" 1.1 "Smoke child task updated"
"$ENGINE" next "$TMP"
"$ENGINE" task-archive "$TMP" 1.1
rm -rf "$TMP"
```

## Local Result Summary

- JSON validation passed for marketplace, plugin manifest, default hooks, enforcing hooks,
  extended advisory hooks, and TaskManager default config.
- Bash syntax validation passed for hooks, migrations, wrapper, and copied tests.
- Python helper syntax validation passed.
- `git diff --check` passed.
- No `__pycache__` directories were present.
- Sorted skill discovery included 29 `SKILL.md` files, including `taskmanager-engine-task`.
- Standalone TaskManager SQL suite passed `285/0`.
- Standalone TaskManager lifecycle suite passed `30/0`.
- Wrapper CLI suite passed `118/0`, including delegated SQL/lifecycle tests through
  `run-sql-tests`.
- Disposable task smoke passed for `init`, `task-add`, `show tasks`, `show task`,
  `task-set-status`, `task-update-title`, `next`, and `task-archive`.

## Hook Status

Hook behavior is unchanged in `0.1.13`:

- default hooks remain advisory-only;
- optional extended advisory hooks remain opt-in;
- optional enforcing hooks remain opt-in;
- `hooks/hooks.json` remains the plugin hook entry point;
- enforcing hooks must not be described as reliable for a target installation until they pass a
  live Codex smoke test there.

This checkpoint does not edit hooks, enable hooks, or change hook policy.

## TaskManager Status

TaskManager parity status for `0.1.13`:

- Phase 5A passive SQLite artifacts are present.
- Phase 5B manual wrapper is present and validated for explicit `init`, `status`, `next`,
  `export-json`, and `run-sql-tests`.
- Phase 5C first-class wrapper operation skills are present.
- Phase 5E read-only `show` visibility is implemented and validated for initialized copied
  engine state.
- Phase 5F manual memory operations are implemented and validated for initialized copied engine
  state.
- Phase 5G manual task operations are implemented and validated for initialized copied engine
  state.

This is artifact parity plus limited explicit wrapper operation, read-only visibility, safe
manual memory operations, and safe manual task operations. It is not full upstream TaskManager
command parity and not a full TaskManager runtime.
