# Parity gap analysis

## Snapshot

- Original repository: `../mwguerra-plugins`
- Original commit/tag: `7bab128` / `v0.1.0`
- Codex repository baseline: `05d80f9`
- Goal: track what has been ported from the original Claude Code plugin suite to the Codex-native plugin.

## Current Codex coverage

The current Codex port provides one consolidated plugin:

- `engineering-discipline`

It currently includes:

- `.agents/plugins/marketplace.json`
- `plugins/engineering-discipline/.codex-plugin/plugin.json`
- advisory hooks enabled by default
- optional extended advisory hooks kept out of default config
- optional strict hooks kept out of default config
- 21 first-class Codex skills
- selected Codex-adapted references and templates under existing skill directories
- 8 Codex-native agent/persona reference guides under existing skill directories
- passive TaskManager SQLite engine artifacts under `taskmanager-lite/references/taskmanager-engine/`

Current Codex skills:

- `architect-design`
- `architect-refine`
- `architect-review`
- `filament-conventions`
- `laravel-conventions`
- `maestro-adversarial-verify`
- `maestro-deep-analysis`
- `maestro-deep-work`
- `maestro-implement`
- `maestro-journey`
- `maestro-regression`
- `maestro-route`
- `prd-builder-bugfix`
- `prd-builder-feature`
- `prd-builder-prd`
- `prd-builder-refine`
- `scribe-docs-discipline`
- `scribe-init`
- `scribe-sync`
- `scribe-verify`
- `taskmanager-lite`

Current Codex reference/template/persona coverage:

- `architect-design/references/`: design heuristics, seam catalog, and architect persona.
- `architect-review/references/`: design adversary persona.
- `filament-conventions/references/`: Filament v5 recipes with target-project version checks.
- `maestro-deep-analysis/references/`: audit plan and `docs/deep-analysis/` output structure.
- `maestro-implement/references/`: expanded implementation process and implementer persona.
- `prd-builder-prd/references/` and `templates/`: question bank, default stack profile,
  design-review lenses, PRD interviewer persona, and PRD template.
- `scribe-docs-discipline/references/` and `templates/`: canonical docs layout plus docs
  README, STATUS, ADR, incident, roadmap, open-question templates, and doc curator persona.
- `scribe-verify/references/`: doc verifier persona.
- `taskmanager-lite/references/`: planning question bank, PRD-to-task example,
  TaskManager-lite planning persona, acceptance verifier persona, and passive TaskManager
  SQLite engine artifacts.

## Original Claude plugins

The original suite has six Claude Code plugins:

- `architect`
- `laravel`
- `maestro`
- `prd-builder`
- `scribe`
- `taskmanager`

The Codex port currently consolidates them into one plugin. This is acceptable for the first Codex-native package, but parity tracking must still preserve the original plugin boundaries conceptually.

## Commands ported as first-class Codex skills

### Architect

- `architect/commands/design.md` -> `architect-design`
- `architect/commands/refine.md` -> `architect-refine`
- `architect/commands/review.md` -> `architect-review`

### Maestro

- `maestro/commands/adversarial-verify.md` -> `maestro-adversarial-verify`
- `maestro/commands/deep-analysis.md` -> `maestro-deep-analysis`
- `maestro/commands/deep-work.md` -> `maestro-deep-work`
- `maestro/commands/implement.md` -> `maestro-implement`
- `maestro/commands/journey.md` -> `maestro-journey`
- `maestro/commands/regression.md` -> `maestro-regression`
- `maestro/commands/route.md` -> `maestro-route`

### PRD Builder

- `prd-builder/commands/bugfix.md` -> `prd-builder-bugfix`
- `prd-builder/commands/feature.md` -> `prd-builder-feature`
- `prd-builder/commands/prd.md` -> `prd-builder-prd`
- `prd-builder/commands/refine.md` -> `prd-builder-refine`

### Scribe

- `scribe/commands/init.md` -> `scribe-init`
- `scribe/commands/sync.md` -> `scribe-sync`
- `scribe/commands/verify.md` -> `scribe-verify`

`scribe-docs-discipline` remains the general docs discipline skill.

## Commands not yet ported as first-class Codex skills

### TaskManager

The original TaskManager command set has not been ported as Codex runtime wrappers yet:

- `taskmanager/commands/export.md`
- `taskmanager/commands/init.md`
- `taskmanager/commands/memory.md`
- `taskmanager/commands/plan.md`
- `taskmanager/commands/research.md`
- `taskmanager/commands/run.md`
- `taskmanager/commands/show.md`
- `taskmanager/commands/update.md`
- `taskmanager/commands/verify.md`

`taskmanager-lite` remains the active planning workflow. Phase 5A adds passive SQLite engine
artifacts, but not the command runtime that would make this parity with the SQLite-backed
original.

## Skill coverage and remaining gaps

### Laravel

Already represented:

- `laravel/skills/filament-conventions/SKILL.md` -> `filament-conventions`
- `laravel/skills/laravel-conventions/SKILL.md` -> `laravel-conventions`

### Maestro discipline skills

The original always-on discipline skills are not yet first-class Codex skills:

- `maestro/skills/context-thrift/SKILL.md`
- `maestro/skills/cross-project/SKILL.md`
- `maestro/skills/finish-your-turn/SKILL.md`
- `maestro/skills/native-code/SKILL.md`
- `maestro/skills/outcome-first/SKILL.md`
- `maestro/skills/prove-it/SKILL.md`
- `maestro/skills/retrospective/SKILL.md`
- `maestro/skills/scope-discipline/SKILL.md`
- `maestro/skills/thoughts/SKILL.md`

### Maestro process skills

Already represented:

- `maestro/skills/adversarial-verify/SKILL.md`
- `maestro/skills/deep-analysis/SKILL.md`
- `maestro/skills/deep-work/SKILL.md`
- `maestro/skills/implementation/SKILL.md`
- `maestro/skills/regression/SKILL.md`
- `maestro/skills/route/SKILL.md`

### PRD Builder

- `prd-builder/skills/prd-interview/SKILL.md`

Not yet ported.

### TaskManager

- `taskmanager/skills/taskmanager-memory/SKILL.md`

Not yet ported as a first-class Codex skill.

`taskmanager/skills/taskmanager/SKILL.md` is only lightly represented by `taskmanager-lite`.
The underlying SQLite schema, migrations, query catalog, and copied SQL tests are now present as
passive artifacts under `taskmanager-lite/references/taskmanager-engine/`.

## Original agents converted to Codex references

The original Claude-oriented agent files have been converted to a Codex-native
reference/persona strategy. They are passive skill-local guides, not automatically executed
subagents:

| Original agent file | Codex reference/persona guide |
|---|---|
| `architect/agents/architect.md` | `architect-design/references/agent-architect.md` |
| `architect/agents/design-adversary.md` | `architect-review/references/agent-design-adversary.md` |
| `maestro/agents/implementer.md` | `maestro-implement/references/agent-implementer.md` |
| `prd-builder/agents/prd-interviewer.md` | `prd-builder-prd/references/agent-prd-interviewer.md` |
| `scribe/agents/doc-curator.md` | `scribe-docs-discipline/references/agent-doc-curator.md` |
| `scribe/agents/doc-verifier.md` | `scribe-verify/references/agent-doc-verifier.md` |
| `taskmanager/agents/taskmanager.md` | `taskmanager-lite/references/agent-taskmanager.md` |
| `taskmanager/agents/verifier.md` | `taskmanager-lite/references/agent-verifier.md` |

See `docs/AGENT-STRATEGY.md` for the strategy and explicit non-claims.

## Hooks ported or not enabled by default

Current default Codex hooks:

- `read_docs_first.sh`
- `verify_before_commit.sh`
- `restart_reminder.sh`

Current optional extended advisory hooks:

- `asset_inventory_gate.sh`
- `ls_real_preflight.sh`
- `self_challenge_gate.sh`
- `session_retro.sh`
- `docs_update_gate.sh`
- `curate_on_stop.sh`

Current optional strict hooks:

- `verify_commit_gate.sh`
- `verify_stop_gate.sh`

Original hooks intentionally not default-enabled:

- extended advisory reminders remain opt-in;
- strict verification gates remain opt-in.

## TaskManager engine artifacts ported passively

Phase 5A includes the original SQLite-backed TaskManager engine artifacts under
`plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine/`:

- `schemas/default-config.json`
- `schemas/migrate-v4.0-to-v4.1.sh`
- `schemas/migrate-v4.1-to-v4.2.sh`
- `schemas/queries.sql`
- `schemas/schema.sql`
- `tests/fixtures/verify-guard-sql.md`
- `tests/test_lifecycle_e2e.sh`
- `tests/test_sql_queries.sh`

This is artifact/reference parity, not runtime parity. The copied tests are adapted only to read
the upstream verify guard SQL from a local passive test fixture because Phase 5A does not port
`taskmanager/commands/verify.md` as a command.

## Recommended conversion phases

### Phase 1 — Finish first-class Codex skill coverage

Status: completed in Codex plugin `0.1.4`.

Added high-value skills without porting engines:

- `maestro-deep-work`
- `maestro-regression`
- `maestro-journey`
- `prd-builder-prd`
- `prd-builder-feature`
- `prd-builder-bugfix`
- `prd-builder-refine`
- `scribe-init`
- `scribe-sync`
- `scribe-verify`
- `filament-conventions`
- `architect-refine`
- `architect-review`

### Phase 2 — Port docs/templates and reference material

Status: completed in Codex plugin `0.1.5`.

Added selected reference/template material from the original plugins under existing Codex skill
directories:

- architecture design heuristics and seam catalog;
- Filament v5 recipes, with explicit target-project version verification;
- Maestro deep-analysis audit plan and publish structure;
- expanded Maestro implementation process;
- PRD Builder question bank, default stack profile, design review, and PRD template;
- Scribe docs layout and templates for README, STATUS, ADR, incident, roadmap, and open
  questions;
- TaskManager-lite planning question bank and PRD-to-task example.

Deliberate exclusions in this phase:

- no hook behavior changes;
- no enforcing-hook enablement;
- no full TaskManager SQLite engine, schemas, migrations, query catalog, tests, or command
  engine;
- no external integrations, background jobs, or unrelated tooling;
- no new skills beyond the existing 21.

### Phase 3 — Port advisory hooks

Status: completed in Codex plugin `0.1.6` as optional extended advisory hooks.

Added Codex-native advisory versions of:

- asset inventory
- look-before-describe
- self-challenge
- session retrospective
- docs update reminder
- doc curation reminder

They are packaged in `plugins/engineering-discipline/hooks/extended-advisory-hooks.json`, which
also includes the existing default advisory reminders. The plugin entry-point
`hooks/hooks.json` was not changed, so Phase 3 is not default-enabled.

### Phase 4 — Convert agents to a Codex strategy

Status: completed in Codex plugin `0.1.7` as passive Codex reference/persona guides.

Added skill-local guides for the original agent roles:

- architect persona;
- design adversary persona;
- implementer persona;
- PRD interviewer persona;
- doc curator persona;
- doc verifier persona;
- TaskManager-lite planning persona;
- acceptance verifier persona.

This phase deliberately does not claim automatic subagent execution, does not enable hooks,
does not change `hooks/hooks.json`, and does not port the full TaskManager SQLite engine.

### Phase 5A — Port TaskManager engine artifacts

Status: completed in Codex plugin `0.1.8` as passive artifacts.

Added under `taskmanager-lite/references/taskmanager-engine/`:

- SQLite schema `v4.2.0`;
- default config;
- query catalog;
- v4.0 -> v4.1 and v4.1 -> v4.2 migrations;
- copied SQL query and lifecycle test scripts;
- a passive verify-guard SQL fixture used by the copied query test.

Deliberate exclusions in this phase:

- no hook behavior changes;
- no changes to `hooks/hooks.json`;
- no strict hook enablement;
- no Codex command wrappers;
- no automatic TaskManager execution;
- no background jobs, external integrations, or repository migrations;
- no full TaskManager runtime parity claim.

### Phase 5B/5C — Design and test TaskManager runtime wrappers

Future work should design Codex-native wrappers for the original TaskManager command set and
prove them with runtime tests before claiming parity.

## Current verdict

The repository is now a functional Codex plugin with Phase 1 skill coverage, Phase 2
reference/template coverage, Phase 3 optional extended advisory hook coverage, Phase 4
agent/persona reference coverage, and Phase 5A passive TaskManager SQLite engine artifacts. It is
still not a full parity port of the original `mwguerra/plugins` suite.

The next safe TaskManager step is Codex-native runtime wrapper design and testing. Do not claim
full SQLite-backed TaskManager runtime parity until those wrappers exist and pass live validation.
