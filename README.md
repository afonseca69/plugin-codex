# plugin-codex

Codex-native engineering discipline plugin inspired by [`mwguerra/plugins`](https://github.com/mwguerra/plugins), adapted for the current Codex plugin, skill, hook, and `AGENTS.md` model.

This repository is not a direct Claude Code plugin copy. It is a Codex-oriented port with:

- a repo marketplace at `.agents/plugins/marketplace.json`;
- one installable Codex plugin at `plugins/engineering-discipline`;
- `.codex-plugin/plugin.json` metadata;
- reusable Codex skills under `skills/*/SKILL.md`;
- advisory hooks enabled by default;
- optional enforcing verification hooks documented but not enabled by default;
- `AGENTS.md` guidance for working on this repository.

## Why this port exists

The upstream project was built for Claude Code and uses `.claude-plugin`, slash commands, Claude-oriented hooks, and Claude-oriented agent files. Codex now has a compatible but different extension model: plugins are packaged with `.codex-plugin/plugin.json`, skills live as `SKILL.md` folders, repo marketplaces live under `.agents/plugins/marketplace.json`, and project instructions live in `AGENTS.md`.

This port keeps the useful workflow ideas — route work by risk, implement with verification, verify adversarially, keep docs current, design before irreversible changes, and use Laravel conventions when relevant — while avoiding a false promise that Claude commands or Claude subagents run unchanged in Codex.

## Install from Codex CLI

```bash
codex plugin marketplace add afonseca69/plugin-codex --ref main
codex plugin marketplace list
```

Then open the Codex plugin directory, choose the `plugin-codex` marketplace, and install/enable `engineering-discipline`.

After installation, restart Codex so newly installed skills and plugin hooks are discovered.

## Local development install

Clone this repository and point Codex at the local marketplace root:

```bash
git clone https://github.com/afonseca69/plugin-codex.git
cd plugin-codex
codex plugin marketplace add ./
```

The marketplace points to `./plugins/engineering-discipline`.

## Skills included

| Skill | Purpose |
|---|---|
| `maestro-route` | Classify a request by risk/size and choose the right workflow. |
| `maestro-implement` | Deliver a code change through intake, investigation, plan, build, verify, and honest delivery. |
| `maestro-adversarial-verify` | Run a refute-first verification pass before accepting a conclusion or change. |
| `maestro-deep-analysis` | Audit a codebase or subsystem and produce an evidence-backed roadmap. |
| `scribe-docs-discipline` | Keep `docs/` and `AGENTS.md` accurate as living project truth. |
| `architect-design` | Produce right-sized architecture and ADRs before implementation. |
| `taskmanager-lite` | Decompose PRDs/features into verifiable tasks without requiring the upstream SQLite engine. |
| `laravel-conventions` | Apply Laravel/Filament/Pest conventions safely when the target project is Laravel. |

Invoke skills explicitly with `$skill-name` or let Codex select them when your task matches the skill description.

## Hooks policy

The default bundled hooks are **advisory-only**:

- remind Codex to read docs first on user prompts;
- warn before `git commit` if verification was not recorded;
- remind after commits to restart/recheck runtime behavior when appropriate.

The upstream Claude plugin had hard verification gates. This repository includes Codex-adapted enforcing hooks, but keeps them out of the default hook file until you explicitly opt in and test them in your environment. See [`docs/VERIFY.md`](docs/VERIFY.md) and [`plugins/engineering-discipline/hooks/README.md`](plugins/engineering-discipline/hooks/README.md).

## Repository layout

```text
.agents/plugins/marketplace.json
plugins/engineering-discipline/
  .codex-plugin/plugin.json
  hooks/
  skills/
docs/
AGENTS.md
README.md
LICENSE
NOTICE.md
```

## Verification status

This initial port has been checked for:

- valid JSON manifests;
- valid skill frontmatter presence;
- Bash syntax for hook scripts;
- Codex-native paths and environment names in the new files.

It has **not** been smoke-tested inside a live Codex installation from this environment. Before relying on enforcing hooks, run the smoke checks in [`docs/VERIFY.md`](docs/VERIFY.md).

## Attribution and license

This is a Codex-oriented adaptation of `mwguerra/plugins`, originally MIT licensed by Marcelo Guerra. See [`NOTICE.md`](NOTICE.md) and [`LICENSE`](LICENSE).
