# Verification

For the `0.1.13` release readiness and parity status checkpoint, see
[`docs/RELEASE-READINESS-0.1.13.md`](RELEASE-READINESS-0.1.13.md).

## Static checks

Run from repository root:

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
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
find . -type d -name __pycache__ -print
```

For Phase 5G, confirm the sorted skill list includes:

```text
plugins/engineering-discipline/skills/taskmanager-engine-export/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-init/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-memory/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-next/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-show/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-status/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-task/SKILL.md
plugins/engineering-discipline/skills/taskmanager-engine-test/SKILL.md
```

## TaskManager engine artifacts

The TaskManager SQLite engine artifacts are passive files under:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
```

They include schema/config, migrations, query catalog, copied tests, and a manual wrapper at
`bin/taskmanager-engine.sh`. The wrapper does not install Codex commands, enable hooks, or
auto-run TaskManager.

If `sqlite3` is installed, run the copied SQL suites from the artifact directory:

```bash
cd plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
bash tests/test_sql_queries.sh
bash tests/test_lifecycle_e2e.sh
bash tests/test_wrapper_cli.sh
```

Manual wrapper smoke test in a disposable temp directory:

```bash
ENGINE=plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh
TMP=$(mktemp -d)
"$ENGINE" init "$TMP"
test -f "$TMP/.taskmanager/taskmanager.db"
"$ENGINE" task-add "$TMP" 1 "Smoke parent task" feature planned
"$ENGINE" task-add "$TMP" 1.1 "Smoke child task" task planned 1
"$ENGINE" show "$TMP" tasks
"$ENGINE" show "$TMP" task 1.1
"$ENGINE" task-set-status "$TMP" 1.1 in-progress
"$ENGINE" task-update-title "$TMP" 1.1 "Smoke child task updated"
"$ENGINE" next "$TMP"
"$ENGINE" task-archive "$TMP" 1.1
"$ENGINE" memory-list "$TMP"
MEMORY_ID=$("$ENGINE" memory-add "$TMP" decision "Test memory" "This is a test memory" 3 0.9 | sed 's/^Created memory: //')
"$ENGINE" memory-list "$TMP"
"$ENGINE" memory-show "$TMP" "$MEMORY_ID"
"$ENGINE" memory-search "$TMP" test
"$ENGINE" memory-deprecate "$TMP" "$MEMORY_ID" "smoke test"
cat > "$TMP/plan.json" <<'JSON'
{
  "payload_version": "1",
  "review_status": "reviewed",
  "plan_analyses": {
    "prd_source": "prompt:smoke",
    "scope_in": "manual plan smoke",
    "scope_out": "task execution",
    "acceptance_criteria": ["plan payload is stored"]
  },
  "milestones": [
    {
      "id": "MS-SMOKE-001",
      "title": "Smoke milestone",
      "status": "planned",
      "phase_order": 1,
      "acceptance_criteria": ["milestone stored"]
    }
  ],
  "tasks": [
    {
      "id": "T-SMOKE-PLAN-001",
      "title": "Smoke planned task",
      "type": "analysis",
      "status": "planned",
      "priority": "medium",
      "milestone_id": "MS-SMOKE-001",
      "acceptance_criteria": ["task stored"]
    }
  ]
}
JSON
"$ENGINE" plan-validate "$TMP" "$TMP/plan.json"
"$ENGINE" plan-preview "$TMP" "$TMP/plan.json"
"$ENGINE" plan-apply "$TMP" "$TMP/plan.json"
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
"$ENGINE" run-sql-tests
rm -rf "$TMP"
```

Latest local result after Phase 5H-2: `test_sql_queries.sh` passed 285/0,
`test_lifecycle_e2e.sh` passed 30/0, and `test_wrapper_cli.sh` passed 152/0.

Passing these suites validates the standalone copied SQLite artifacts and the limited manual
wrapper only. Phase 5G adds first-class Codex skill entry points and explicit manual
task-add/status/title/archive wrapper commands for initialized engine state. Phase 5H-2 adds
manual reviewed-payload plan validate/preview/apply wrapper commands without adding a skill. These
do not claim full TaskManager plan/task/runtime parity. Full parity still requires broader Codex
command/runtime implementation and tests.

## Extended advisory hooks

`plugins/engineering-discipline/hooks/extended-advisory-hooks.json` is an optional preset. It
includes the default advisory reminders plus the Phase 3 advisory ports:

- `asset_inventory_gate.sh`
- `ls_real_preflight.sh`
- `self_challenge_gate.sh`
- `session_retro.sh`
- `docs_update_gate.sh`
- `curate_on_stop.sh`

They only return `additionalContext` and are safe to leave disabled.

## Strict hooks

The default hooks are advisory. Before using the optional strict hook config, test it in a disposable repository and then in a live Codex session.

Confirm:

- plugin hooks are trusted;
- advisory hooks run;
- strict commit gate can stop an unverified commit;
- ledger evidence allows the same change;
- Stop hook does not loop.

Do not claim strict hooks are production-ready until these checks pass in the target environment.


## Live hook smoke-test status

Last live hook smoke test was verified on WSL2 with Codex CLI `0.142.5` using installed plugin cache `0.1.3`. The 0.1.4 skill-only update, 0.1.5 reference/template update, 0.1.7 agent/persona reference update, 0.1.8 passive TaskManager engine artifact update, 0.1.9 manual TaskManager wrapper update, 0.1.10 manual wrapper skill update, 0.1.11 read-only TaskManager visibility update, 0.1.12 manual TaskManager memory update, and 0.1.13 manual TaskManager task update did not change default hook behavior. Version 0.1.6 adds optional extended advisory hooks, but does not change `hooks/hooks.json`:

- marketplace added from local repository;
- `engineering-discipline@plugin-codex` installed and enabled;
- installed cache JSON/Bash/Python checks passed;
- advisory hooks returned the expected Codex hook JSON;
- optional commit gate denied an unverified staged commit and allowed it after ledger evidence;
- optional Stop gate denied unverified tracked work;
- Stop loop guard allowed stop when `stop_hook_active=true`;
- ledger hash behavior was corrected so `--cached` does not hash unstaged-only work;
- ledger coverage lookup was corrected so older records for other hashes do not prevent matching evidence from being recognized.
