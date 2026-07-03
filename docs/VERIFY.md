# Verification

## Static checks

Run from repository root:

```bash
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/enforcing-hooks.json >/dev/null
bash -n plugins/engineering-discipline/hooks/*.sh
python3 -m py_compile plugins/engineering-discipline/hooks/lib/json_value.py
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
```

## Strict hooks

The default hooks are advisory. Before using the optional strict hook config, test it in a disposable repository and then in a live Codex session.

Confirm:

- plugin hooks are trusted;
- advisory hooks run;
- strict commit gate can stop an unverified commit;
- ledger evidence allows the same change;
- Stop hook does not loop.

Do not claim strict hooks are production-ready until these checks pass in the target environment.
