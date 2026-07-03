# AGENTS.md

## Repository purpose

This repository packages a Codex-native engineering discipline plugin. Treat the plugin files as product code: changes to Markdown skills, manifests, hooks, or docs change runtime behavior for Codex users.

## Non-negotiable rules

- Do not add Claude-specific runtime dependencies to this Codex port.
- Keep `.codex-plugin/plugin.json` as the plugin entry point.
- Keep the repo marketplace at `.agents/plugins/marketplace.json`.
- Keep default hooks advisory-only unless a separate change explicitly opts in to enforcing hooks and documents live smoke-test evidence.
- Do not claim enforcing hooks are reliable until they have been tested in a live Codex installation.
- Preserve upstream attribution and MIT license notices.
- Prefer small, reviewable changes with clear verification notes.

## Validation before committing

Run these checks after editing plugin files:

```bash
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/enforcing-hooks.json >/dev/null
bash -n plugins/engineering-discipline/hooks/*.sh
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
```

If you edit hook behavior, also run a manual Codex smoke test following `docs/VERIFY.md`.

## Documentation discipline

When behavior changes, update the README and relevant files under `docs/`. Remove obsolete statements rather than leaving contradictory historical text in operational docs. Preserve historical rationale in `docs/PORTING.md` when useful.
