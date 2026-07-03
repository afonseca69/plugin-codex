# Notice

This repository is a Codex-oriented adaptation of [`mwguerra/plugins`](https://github.com/mwguerra/plugins).

Original project:

- Repository: `https://github.com/mwguerra/plugins`
- Original author: Marcelo Guerra
- Original license: MIT License
- Original copyright notice: `Copyright (c) 2026 Marcelo Guerra`

This port changes the packaging and runtime assumptions from Claude Code to Codex:

- `.claude-plugin` marketplace and manifests are replaced with Codex `.agents/plugins` marketplace metadata and `.codex-plugin/plugin.json`.
- Claude slash commands are represented as Codex skills.
- Claude-specific environment variables in hooks are replaced with Codex-native `PLUGIN_ROOT`, `PLUGIN_DATA`, and hook JSON fields, while allowing Codex's compatibility variables where safe.
- Hard gates are present as optional scripts/config, but advisory-only hooks are the default until live Codex smoke tests prove the enforcing mode in the target environment.

The adaptation intentionally does not represent itself as the upstream Claude Code suite.
