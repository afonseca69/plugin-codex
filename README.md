# plugin-codex

Codex-native engineering discipline plugin inspired by [`mwguerra/plugins`](https://github.com/mwguerra/plugins), adapted for the current Codex plugin, skill, hook, and `AGENTS.md` model.

This repository is not a direct Claude Code plugin copy. It is a Codex-oriented port with:

- a repo marketplace at `.agents/plugins/marketplace.json`;
- one installable Codex plugin at `plugins/engineering-discipline`;
- `.codex-plugin/plugin.json` metadata;
- reusable Codex skills under `skills/*/SKILL.md`;
- selected Codex-adapted references and templates under skill-local `references/` and
  `templates/` directories;
- advisory hooks enabled by default;
- optional enforcing verification hooks documented but not enabled by default;
- `AGENTS.md` guidance for working on this repository.

## Why this port exists

The upstream project was built for Claude Code and uses `.claude-plugin`, slash commands, Claude-oriented hooks, and Claude-oriented agent files. Codex now has a compatible but different extension model: plugins are packaged with `.codex-plugin/plugin.json`, skills live as `SKILL.md` folders, repo marketplaces live under `.agents/plugins/marketplace.json`, and project instructions live in `AGENTS.md`.

This port keeps the useful workflow ideas — route work by risk, implement with verification, verify adversarially, keep docs current, design before irreversible changes, shape PRDs, and use Laravel conventions when relevant — while avoiding a false promise that Claude commands or Claude subagents run unchanged in Codex.

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
| `maestro-deep-work` | Orchestrate broad multi-place work through plan, refutation, execution, synthesis, and verification. |
| `maestro-regression` | Prove a change did not break existing behavior through suite evidence and blast-radius review. |
| `maestro-journey` | Show one feature's read-only path from PRD through design, verification, and shipped status. |
| `prd-builder-prd` | Turn a rough product idea into a full PRD under `docs/prd/`. |
| `prd-builder-feature` | Create a focused PRD for a feature inside an existing product. |
| `prd-builder-bugfix` | Document a bug fix with reproduction, root cause, rollback, and regression coverage. |
| `prd-builder-refine` | Improve an existing PRD by filling weak or missing requirements. |
| `scribe-docs-discipline` | Keep `docs/` and `AGENTS.md` accurate as living project truth. |
| `scribe-init` | Bootstrap a living `docs/` source of truth idempotently. |
| `scribe-sync` | Curate recent work into `docs/` and verify the result. |
| `scribe-verify` | Adversarially verify docs against code, decisions, incidents, and staleness. |
| `architect-design` | Produce right-sized architecture and ADRs before implementation. |
| `architect-refine` | Evolve existing architecture while preserving ADR history. |
| `architect-review` | Adversarially review architecture and ADRs with read-only findings. |
| `taskmanager-lite` | Decompose PRDs/features into verifiable tasks without requiring the upstream SQLite engine. |
| `laravel-conventions` | Apply Laravel/Filament/Pest conventions safely when the target project is Laravel. |
| `filament-conventions` | Apply Filament-specific panel, resource, auth, and verification conventions. |

Invoke skills explicitly with `$skill-name` or let Codex select them when your task matches the skill description.

## Reference and template material

The plugin also ships passive skill-local references and templates adapted from the upstream
suite:

| Area | Included material |
|---|---|
| Architecture | Design heuristics and seam catalog. |
| Maestro | Implementation process and deep-analysis audit/publish templates. |
| PRD Builder | Question bank, default stack profile, design-review lenses, PRD template. |
| Scribe | Canonical docs layout plus STATUS, ADR, incident, roadmap, open-question templates. |
| TaskManager-lite | Planning question bank and PRD-to-task example without the SQLite engine. |
| Filament | Filament v5 recipes, with version verification required in the target project. |

These files are content for skills to consult. They do not add new skills, enable hooks, or
install the upstream TaskManager engine.

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

This port has been checked for:

- valid JSON manifests;
- valid skill frontmatter presence;
- Bash syntax for hook scripts;
- Codex-native paths and environment names in the new files.

It has passed local Codex CLI installation checks, advisory hook smoke tests, and optional strict hook script smoke tests on WSL2. Before relying on enforcing hooks globally, still validate them inside your target live Codex workflow and review them in `/hooks`.

## Attribution and license

This is a Codex-oriented adaptation of `mwguerra/plugins`, originally MIT licensed by Marcelo Guerra. See [`NOTICE.md`](NOTICE.md) and [`LICENSE`](LICENSE).
