# plugin-codex

Codex-native engineering discipline plugin inspired by [`mwguerra/plugins`](https://github.com/mwguerra/plugins), adapted for the current Codex plugin, skill, hook, and `AGENTS.md` model.

This repository is not a direct Claude Code plugin copy. It is a Codex-oriented port with:

- a repo marketplace at `.agents/plugins/marketplace.json`;
- one installable Codex plugin at `plugins/engineering-discipline`;
- `.codex-plugin/plugin.json` metadata;
- reusable Codex skills under `skills/*/SKILL.md`;
- selected Codex-adapted references and templates under skill-local `references/` and
  `templates/` directories;
- passive agent/persona reference guides adapted for Codex skill workflows;
- TaskManager SQLite engine artifacts under `taskmanager-lite` for schema,
  migration, query, copied-test reference, a small manual wrapper, and
  first-class manual wrapper operation skills;
- a small advisory hook set enabled by default;
- optional extended advisory hooks documented but not enabled by default;
- optional enforcing verification hooks documented but not enabled by default;
- `AGENTS.md` guidance for working on this repository.

## Why this port exists

The upstream project was built for Claude Code and uses `.claude-plugin`, slash commands, Claude-oriented hooks, and Claude-oriented agent files. Codex now has a compatible but different extension model: plugins are packaged with `.codex-plugin/plugin.json`, skills live as `SKILL.md` folders, repo marketplaces live under `.agents/plugins/marketplace.json`, and project instructions live in `AGENTS.md`.

This port keeps the useful workflow ideas — route work by risk, implement with verification, verify adversarially, keep docs current, design before irreversible changes, shape PRDs, and use Laravel conventions when relevant — while avoiding a false promise that upstream commands or agent prompts run unchanged in Codex.

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
| `taskmanager-lite` | Decompose PRDs/features into verifiable tasks without requiring an active SQLite TaskManager runtime. |
| `taskmanager-engine-init` | Initialize `PROJECT_DIR/.taskmanager` through the explicit manual TaskManager engine wrapper. |
| `taskmanager-engine-status` | Read status from `PROJECT_DIR/.taskmanager/taskmanager.db` through the manual wrapper. |
| `taskmanager-engine-next` | Show next available tasks through the read-only manual wrapper. |
| `taskmanager-engine-show` | Inspect read-only TaskManager overview, task, milestone, memory, deferral, verification, and regression views. |
| `taskmanager-engine-task` | Run safe manual task add, status, title, and soft archive operations through the explicit wrapper. |
| `taskmanager-engine-memory` | Run safe manual memory list, show, search, add, and deprecate operations through the manual wrapper. |
| `taskmanager-engine-export` | Export JSON-style core TaskManager data through the read-only manual wrapper. |
| `taskmanager-engine-test` | Run copied TaskManager SQL, lifecycle, and wrapper tests. |
| `laravel-conventions` | Apply Laravel/Filament/Pest conventions safely when the target project is Laravel. |
| `filament-conventions` | Apply Filament-specific panel, resource, auth, and verification conventions. |

Invoke skills explicitly with `$skill-name` or let Codex select them when your task matches the skill description.

## Reference and template material

The plugin also ships passive skill-local references and templates adapted from the upstream
suite:

| Area | Included material |
|---|---|
| Architecture | Design heuristics, seam catalog, architect persona, and design-adversary persona. |
| Maestro | Implementation process, implementer persona, and deep-analysis audit/publish templates. |
| PRD Builder | Question bank, default stack profile, design-review lenses, PRD interviewer persona, PRD template. |
| Scribe | Canonical docs layout plus STATUS, ADR, incident, roadmap, open-question templates, doc curator persona, and doc verifier persona. |
| TaskManager-lite | Planning question bank, PRD-to-task example, planning persona, verifier persona, TaskManager SQLite engine artifacts, manual engine wrapper, and manual wrapper skill entry points. |
| Filament | Filament v5 recipes, with version verification required in the target project. |

These files are content for skills to consult. They do not enable hooks, run
automatic agents, or auto-run TaskManager. See
[`docs/AGENT-STRATEGY.md`](docs/AGENT-STRATEGY.md) for how upstream agent prompts are represented
as Codex reference/persona guides.

The TaskManager engine artifacts live at
`plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/`. They
include upstream schema/config, migrations, query catalog, copied SQL test assets, and a manual
wrapper at `bin/taskmanager-engine.sh`. The wrapper supports explicit `init`, `status`, `next`,
`show`, `task-add`, `task-set-status`, `task-update-title`, `task-archive`, `memory-list`,
`memory-show`, `memory-search`, `memory-add`, `memory-deprecate`, `export-json`, and
`run-sql-tests` commands, but it is not registered as a Codex command and is not a full
TaskManager runtime. The `show` command is read-only visibility for initialized engine state; it
does not execute tasks or update TaskManager data. The task commands are manual and bounded to the
initialized SQLite database; `task-add`, `task-set-status`, `task-update-title`, and
`task-archive` mutate only `PROJECT_DIR/.taskmanager/taskmanager.db` and do not cascade parent
statuses or write verification rows. The memory commands are manual and bounded to the initialized
SQLite database; only `memory-add` and `memory-deprecate` mutate
`PROJECT_DIR/.taskmanager/taskmanager.db`. The `taskmanager-engine-*` skills are first-class Codex
operator guides for that wrapper; they do not add hidden runtime behavior or full upstream command
parity.
Future TaskManager runtime parity is scoped in
[`docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md`](docs/PHASE5D-TASKMANAGER-RUNTIME-DESIGN.md).
The implemented read-only Phase 5E slice is recorded in
[`docs/PHASE5E-TASKMANAGER-READONLY-RUNTIME.md`](docs/PHASE5E-TASKMANAGER-READONLY-RUNTIME.md).
The implemented manual memory Phase 5F slice is recorded in
[`docs/PHASE5F-TASKMANAGER-MEMORY.md`](docs/PHASE5F-TASKMANAGER-MEMORY.md).
The implemented manual task Phase 5G slice is recorded in
[`docs/PHASE5G-TASKMANAGER-TASK-OPERATIONS.md`](docs/PHASE5G-TASKMANAGER-TASK-OPERATIONS.md).

## Hooks policy

The default bundled hooks are **advisory-only**:

- remind Codex to read docs first on user prompts;
- warn before `git commit` if verification was not recorded;
- remind after commits to restart/recheck runtime behavior when appropriate.

An optional extended advisory preset ports the remaining upstream reminder hooks for asset
inventory, look-before-describe, self-challenge, session retro, docs update, and docs curation.
It is packaged as `plugins/engineering-discipline/hooks/extended-advisory-hooks.json` and is not
the plugin entry-point hook config.

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

See [`docs/RELEASE-READINESS-0.1.13.md`](docs/RELEASE-READINESS-0.1.13.md) for the `0.1.13`
release readiness and parity status checkpoint.

Version `0.1.13` adds safe manual TaskManager task operations through explicit
`task-add`, `task-set-status`, `task-update-title`, and `task-archive` wrapper commands and the
`taskmanager-engine-task` skill. It has been checked for:

- valid JSON manifests;
- valid skill frontmatter presence;
- Bash syntax for hook scripts;
- Bash syntax for the manual TaskManager wrapper and wrapper test;
- Bash syntax for copied TaskManager migration and test scripts;
- JSON validity for the copied TaskManager default config;
- Python helper syntax;
- no generated `__pycache__` directories;
- standalone copied TaskManager SQL tests passed locally with `sqlite3`: `test_sql_queries.sh` 285/0 and `test_lifecycle_e2e.sh` 30/0.
- wrapper smoke/regression tests passed locally with `sqlite3`: `test_wrapper_cli.sh` 118/0,
  including `init`, `status`, `next`, `show`, task operations, memory operations, `export-json`, and
  wrapper-driven `run-sql-tests`.

Hook behavior is unchanged from `0.1.9`: default hooks remain advisory-only, optional extended
advisory hooks remain opt-in, and strict hooks remain opt-in. The TaskManager wrapper is manual
only. The `taskmanager-engine-*` skills describe manual wrapper usage and do not claim full
upstream TaskManager runtime parity. `task-add`, `task-set-status`, `task-update-title`,
`task-archive`, `memory-add`, and `memory-deprecate` are explicit database mutations only; they
do not implement plan/run/verify/update/research or full upstream task/memory parity. Before
relying on enforcing hooks globally, still validate
them inside your target live Codex workflow and review them in `/hooks`.

## Attribution and license

This is a Codex-oriented adaptation of `mwguerra/plugins`, originally MIT licensed by Marcelo Guerra. See [`NOTICE.md`](NOTICE.md) and [`LICENSE`](LICENSE).
