# Release readiness checkpoint: 0.1.11

## Release snapshot

- Plugin: `engineering-discipline`
- Version: `0.1.11`
- Branch used for this checkpoint: `feat/phase5e-taskmanager-readonly-runtime`
- Marketplace entry point: `.agents/plugins/marketplace.json`
- Plugin entry point: `plugins/engineering-discipline/.codex-plugin/plugin.json`
- Default hook entry point: `plugins/engineering-discipline/hooks/hooks.json`
- Skill count: 27 first-class Codex skills
- Release posture: limited read-only TaskManager runtime visibility; no hook behavior change.

Version `0.1.11` is ready as a Codex-native plugin release checkpoint for Phase
5E. This is not a claim of full upstream parity with `mwguerra/plugins`.

## Added In 0.1.11

- Manual wrapper command:
  `taskmanager-engine.sh show PROJECT_DIR [view] [args...]`.
- First-class Codex skill: `taskmanager-engine-show`.
- Read-only visibility views for overview, task list, task detail, milestones,
  memories, deferrals, verifications, and regressions.
- Wrapper regression coverage proving tested `show` modes do not mutate
  `taskmanager.db`.
- Documentation for Phase 5E behavior and safety limits.

## Supported now

The `0.1.11` plugin currently supports:

- one installable Codex plugin named `engineering-discipline`;
- 27 first-class Codex skills for routing, implementation, adversarial verification,
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
  `taskmanager-engine-show`, `taskmanager-engine-export`, and `taskmanager-engine-test`.

## Intentionally not claimed

The `0.1.11` release does not claim:

- full upstream parity with the original Claude Code plugin suite;
- full SQLite-backed TaskManager runtime parity;
- Codex command registration for the original TaskManager command set;
- automatic TaskManager execution, schedulers, background jobs, or hidden runtime services;
- upstream TaskManager command parity for `plan`, `run`, `verify`, `update`, `memory`,
  `research`, or related workflows;
- full upstream `show` parity beyond the tested read-only visibility modes;
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
python3 - <<'PY'
import ast
from pathlib import Path
ast.parse(Path("plugins/engineering-discipline/hooks/lib/json_value.py").read_text())
print("python syntax OK")
PY
git diff --check
find . -type d -name __pycache__ -print
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
```

TaskManager runtime validation for this checkpoint:

```bash
bash plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/tests/test_wrapper_cli.sh
```

Disposable smoke validation:

```bash
ENGINE=plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
TMP=$(mktemp -d)
"$ENGINE" init "$TMP"
"$ENGINE" show "$TMP" overview
"$ENGINE" show "$TMP" tasks
"$ENGINE" show "$TMP" milestones
"$ENGINE" show "$TMP" memories
"$ENGINE" show "$TMP" deferrals
"$ENGINE" show "$TMP" verifications
"$ENGINE" show "$TMP" regressions
"$ENGINE" status "$TMP"
"$ENGINE" next "$TMP"
"$ENGINE" export-json "$TMP"
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
- Sorted skill discovery included 27 `SKILL.md` files, including `taskmanager-engine-show`.
- `test_wrapper_cli.sh` passed `50/0` and delegated to copied SQL/lifecycle suites:
  `test_sql_queries.sh` passed `285/0`; `test_lifecycle_e2e.sh` passed `30/0`.
- Standalone TaskManager SQL suite passed `285/0`.
- Standalone TaskManager lifecycle suite passed `30/0`.
- Disposable wrapper smoke passed for `init`, `show overview`, `show tasks`, `show milestones`,
  `show memories`, `show deferrals`, `show verifications`, `show regressions`, `status`, `next`,
  and `export-json`.

## Hook safety status

Hook behavior is unchanged in `0.1.11`:

- default hooks remain advisory-only;
- optional extended advisory hooks remain opt-in;
- optional enforcing hooks remain opt-in;
- `hooks/hooks.json` remains the plugin hook entry point;
- enforcing hooks must not be described as reliable for a target installation until they pass a
  live Codex smoke test in that installation.

This checkpoint does not edit hooks, enable hooks, or change hook policy.

## TaskManager status

TaskManager parity status for `0.1.11`:

- Phase 5A artifacts are present and validated as passive SQLite engine reference material.
- Phase 5B manual wrapper is present and validated for explicit `init`, `status`, `next`,
  `export-json`, and `run-sql-tests` usage.
- Phase 5C wrapper operation skills are present and validated as first-class Codex operator
  guides around the manual wrapper.
- Phase 5D runtime design is recorded in `docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md`.
- Phase 5E read-only `show` visibility is implemented and validated for initialized copied
  engine state.

This is artifact parity plus limited explicit wrapper operation and read-only visibility. It is
not full upstream TaskManager command parity and not a full TaskManager runtime.
