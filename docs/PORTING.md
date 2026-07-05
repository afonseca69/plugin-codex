# Porting notes

This repository adapts the engineering workflow ideas from `mwguerra/plugins` to Codex.

## Main changes

- Claude `.claude-plugin` metadata was replaced by Codex `.codex-plugin` metadata.
- Repository marketplace metadata lives in `.agents/plugins/marketplace.json`.
- Claude slash commands are represented as Codex skills.
- Claude agent personas are represented as skill-local Codex reference/persona guides, not
  automatically executed agents.
- Default hooks are advisory.
- The remaining upstream advisory hooks are available as an optional extended advisory preset,
  not default-enabled.
- Stricter hooks are opt-in and require live Codex smoke testing.
- The full upstream SQLite task engine is not included in this first port; `taskmanager-lite` provides a planning workflow instead.
- Selected upstream references and templates now live under Codex skill-local
  `references/` and `templates/` directories, rewritten for `AGENTS.md`, Codex skills,
  `docs/`, evidence, and verification language.
- Original upstream agent prompts now live as Codex-native reference/persona guides under
  the relevant skill directories. See `docs/AGENT-STRATEGY.md`.

## Future work

- Port the full task engine as a separate tested slice.
- If Codex grows a stable automatic agent mechanism, design and verify that as a separate
  phase before making any runtime claim.
- Add live Codex smoke-test evidence for strict hooks.
