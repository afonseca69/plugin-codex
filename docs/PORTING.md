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
- The upstream TaskManager SQLite engine artifacts are included passively under
  `taskmanager-lite/references/taskmanager-engine/`; `taskmanager-lite` remains the active
  Codex planning workflow.
- TaskManager command wrappers and automatic runtime behavior are not ported yet.
- Selected upstream references and templates now live under Codex skill-local
  `references/` and `templates/` directories, rewritten for `AGENTS.md`, Codex skills,
  `docs/`, evidence, and verification language.
- Original upstream agent prompts now live as Codex-native reference/persona guides under
  the relevant skill directories. See `docs/AGENT-STRATEGY.md`.

## Future work

- Design Codex-native TaskManager command wrappers as a separate tested slice.
- Add runtime tests before claiming full TaskManager parity.
- If Codex grows a stable automatic agent mechanism, design and verify that as a separate
  phase before making any runtime claim.
- Add live Codex smoke-test evidence for strict hooks.
