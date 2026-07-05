# Verification

## Static checks

Run from repository root:

```bash
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/enforcing-hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/extended-advisory-hooks.json >/dev/null
bash -n plugins/engineering-discipline/hooks/*.sh
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

Last live hook smoke test was verified on WSL2 with Codex CLI `0.142.5` using installed plugin cache `0.1.3`. The 0.1.4 skill-only update, 0.1.5 reference/template update, and 0.1.7 agent/persona reference update did not change hook behavior. Version 0.1.6 adds optional extended advisory hooks, but does not change `hooks/hooks.json`:

- marketplace added from local repository;
- `engineering-discipline@plugin-codex` installed and enabled;
- installed cache JSON/Bash/Python checks passed;
- advisory hooks returned the expected Codex hook JSON;
- optional commit gate denied an unverified staged commit and allowed it after ledger evidence;
- optional Stop gate denied unverified tracked work;
- Stop loop guard allowed stop when `stop_hook_active=true`;
- ledger hash behavior was corrected so `--cached` does not hash unstaged-only work;
- ledger coverage lookup was corrected so older records for other hashes do not prevent matching evidence from being recognized.
