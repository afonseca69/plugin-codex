# Porting notes

This repository adapts the engineering workflow ideas from `mwguerra/plugins` to Codex.

## Main changes

- Claude `.claude-plugin` metadata was replaced by Codex `.codex-plugin` metadata.
- Repository marketplace metadata lives in `.agents/plugins/marketplace.json`.
- Claude slash commands are represented as Codex skills.
- Claude agent personas are represented as process guidance inside skills.
- Default hooks are advisory.
- Stricter hooks are opt-in and require live Codex smoke testing.
- The full upstream SQLite task engine is not included in this first port; `taskmanager-lite` provides a planning workflow instead.

## Future work

- Port the full task engine as a separate tested slice.
- Add richer templates for PRDs, ADRs, incidents, and architecture docs.
- Add live Codex smoke-test evidence for strict hooks.
