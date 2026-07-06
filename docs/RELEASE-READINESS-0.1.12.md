# Release readiness checkpoint: 0.1.12

## Release snapshot

- Plugin: `engineering-discipline`
- Version: `0.1.12`
- Branch used for this checkpoint: `feat/phase5f-taskmanager-memory`
- Marketplace entry point: `.agents/plugins/marketplace.json`
- Plugin entry point: `plugins/engineering-discipline/.codex-plugin/plugin.json`
- Default hook entry point: `plugins/engineering-discipline/hooks/hooks.json`
- Skill count: 28 first-class Codex skills
- Release posture: limited manual TaskManager memory operations; no hook behavior change.

Version `0.1.12` is ready as a Codex-native plugin release checkpoint for Phase
5F. This is not a claim of full upstream parity with `mwguerra/plugins`.

## Added In 0.1.12

- Manual read-only wrapper commands:
  `memory-list PROJECT_DIR [limit]`, `memory-show PROJECT_DIR MEMORY_ID`, and
  `memory-search PROJECT_DIR QUERY [limit]`.
- Manual mutating wrapper commands:
  `memory-add PROJECT_DIR TYPE TITLE BODY [IMPORTANCE] [CONFIDENCE]` and
  `memory-deprecate PROJECT_DIR MEMORY_ID REASON`.
- First-class Codex skill: `taskmanager-engine-memory`.
- FTS-first memory search with safe LIKE fallback when FTS is unavailable or
  rejects query syntax.
- Wrapper regression coverage for empty memory lists, add/show/search/deprecate,
  FTS fallback, invalid arguments, and read-only checksum preservation.
- Documentation for Phase 5F behavior and safety limits.

## Supported now

The `0.1.12` plugin currently supports:

- one installable Codex plugin named `engineering-discipline`;
- 28 first-class Codex skills for routing, implementation, adversarial verification,
  regression review, architecture, PRDs, Scribe docs, Laravel/Filament conventions, and manual
  TaskManager wrapper operation;
- selected Codex-adapted references, templates, and passive persona guides under skill-local
  `references/` and `templates/` directories;
- default advisory-only hooks for documentation-first reminders, verification reminders before
  commit, and runtime restart/recheck reminders;
- optional extended advisory hook preset kept outside the default hook entry point;
- optional enforcing hook preset kept outside the default hook entry point;
- passive TaskManager SQLite schema/config, migrations, query catalog, copied tests, and usage
  notes under `taskmanager-lite/references/taskmanager-engine/`;
- an explicit manual TaskManager wrapper at
  `taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh`;
- first-class Codex skills for the supported manual wrapper operations:
  `taskmanager-engine-init`, `taskmanager-engine-status`, `taskmanager-engine-next`,
  `taskmanager-engine-show`, `taskmanager-engine-memory`, `taskmanager-engine-export`, and
  `taskmanager-engine-test`.

## Intentionally not claimed

The `0.1.12` release does not claim:

- full upstream parity with the original Claude Code plugin suite;
- full SQLite-backed TaskManager runtime parity;
- Codex command registration for the original TaskManager command set;
- automatic TaskManager execution, schedulers, background jobs, or hidden runtime services;
- upstream TaskManager command parity for `plan`, `run`, `verify`, `update`, `research`, or
  related workflows;
- full upstream `show` parity beyond the tested read-only visibility modes;
- full upstream `memory` parity beyond the tested manual list/show/search/add/deprecate modes;
- memory update, supersede, conflict reconciliation, or research-backed memory capture;
- default enablement of extended advisory hooks;
- default enablement of enforcing hooks;
- production reliability for enforcing hooks without live target-environment smoke testing;
- Claude-specific runtime behavior or dependencies.

## Validation commands and results

Required repository validation for this checkpoint:

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

Disposable smoke validation:

```bash
ENGINE=plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
TMP=$(mktemp -d)
"$ENGINE" init "$TMP"
"$ENGINE" memory-list "$TMP"
MEMORY_ID=$("$ENGINE" memory-add "$TMP" decision "Test memory" "This is a test memory" 3 0.9 | sed 's/^Created memory: //')
"$ENGINE" memory-list "$TMP"
"$ENGINE" memory-show "$TMP" "$MEMORY_ID"
"$ENGINE" memory-search "$TMP" test
"$ENGINE" memory-deprecate "$TMP" "$MEMORY_ID" "smoke test"
"$ENGINE" show "$TMP" memories
rm -rf "$TMP"
```

Recorded results:

- JSON validation passed for marketplace, plugin manifest, default hooks, enforcing hooks,
  extended advisory hooks, and TaskManager default config.
- Hook shell syntax validation passed.
- Hook Python helper syntax validation passed.
- TaskManager wrapper, migration, and copied test shell syntax validation passed.
- `git diff --check` passed.
- `find . -type d -name __pycache__ -print` returned no output.
- Sorted skill discovery included 28 `SKILL.md` files, including `taskmanager-engine-memory`.
- `test_sql_queries.sh` passed `285/0`.
- `test_lifecycle_e2e.sh` passed `30/0`.
- `test_wrapper_cli.sh` passed `77/0` and delegated to copied SQL/lifecycle suites.
- Disposable wrapper smoke passed for `init`, `memory-list`, `memory-add`, `memory-show`,
  `memory-search`, `memory-deprecate`, and `show memories`.

## Hook safety status

Hook behavior is unchanged in `0.1.12`:

- default hooks remain advisory-only;
- optional extended advisory hooks remain opt-in;
- optional enforcing hooks remain opt-in;
- `hooks/hooks.json` remains the plugin hook entry point;
- enforcing hooks must not be described as reliable for a target installation until they pass a
  live Codex smoke test in that installation.

This checkpoint does not edit hooks, enable hooks, or change hook policy.

## TaskManager status

TaskManager parity status for `0.1.12`:

- Phase 5A artifacts are present and validated as passive SQLite engine reference material.
- Phase 5B manual wrapper is present and validated for explicit `init`, `status`, `next`,
  `export-json`, and `run-sql-tests` usage.
- Phase 5C wrapper operation skills are present and validated as first-class Codex operator
  guides around the manual wrapper.
- Phase 5D runtime design is recorded in `docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md`.
- Phase 5E read-only `show` visibility is implemented and validated for initialized copied
  engine state.
- Phase 5F manual memory operations are implemented and validated for initialized copied engine
  state.

This is artifact parity plus limited explicit wrapper operation, read-only visibility, and safe
manual memory operations. It is not full upstream TaskManager command parity and not a full
TaskManager runtime.
