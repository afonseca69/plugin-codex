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
- optional strict hooks kept out of default config
- 21 first-class Codex skills

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

The original TaskManager command set has not been ported as a real engine yet:

- `taskmanager/commands/export.md`
- `taskmanager/commands/init.md`
- `taskmanager/commands/memory.md`
- `taskmanager/commands/plan.md`
- `taskmanager/commands/research.md`
- `taskmanager/commands/run.md`
- `taskmanager/commands/show.md`
- `taskmanager/commands/update.md`
- `taskmanager/commands/verify.md`

`taskmanager-lite` is only a planning workflow, not parity with the SQLite-backed original.

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

Not yet ported.

`taskmanager/skills/taskmanager/SKILL.md` is only lightly represented by `taskmanager-lite`.

## Agents not yet ported

The original Claude agents are not yet converted to a Codex-native strategy:

- `architect/agents/architect.md`
- `architect/agents/design-adversary.md`
- `maestro/agents/implementer.md`
- `prd-builder/agents/prd-interviewer.md`
- `scribe/agents/doc-curator.md`
- `scribe/agents/doc-verifier.md`
- `taskmanager/agents/taskmanager.md`
- `taskmanager/agents/verifier.md`

Current approach: their roles are partially embedded in skills. This is not parity.

Future options:

1. Convert each agent into a referenced persona document under the relevant skill.
2. Create explicit Codex skills for each agent role.
3. If Codex subagent support is appropriate, create a dedicated subagent strategy later.

## Hooks not yet ported or not enabled by default

Current default Codex hooks:

- `read_docs_first.sh`
- `verify_before_commit.sh`
- `restart_reminder.sh`

Current optional strict hooks:

- `verify_commit_gate.sh`
- `verify_stop_gate.sh`

Original hooks not yet ported:

- `maestro/hooks/asset_inventory_gate.sh`
- `maestro/hooks/ls_real_preflight.sh`
- `maestro/hooks/self_challenge_gate.sh`
- `maestro/hooks/session_retro.sh`
- `scribe/hooks/curate_on_stop.sh`
- `scribe/hooks/docs_update_gate.sh`

Original hooks intentionally not default-enabled:

- strict verification gates remain opt-in.

## TaskManager engine not yet ported

The original SQLite-backed TaskManager engine is not yet included:

- `taskmanager/schemas/default-config.json`
- `taskmanager/schemas/migrate-v4.0-to-v4.1.sh`
- `taskmanager/schemas/migrate-v4.1-to-v4.2.sh`
- `taskmanager/schemas/queries.sql`
- `taskmanager/schemas/schema.sql`
- `taskmanager/tests/test_lifecycle_e2e.sh`
- `taskmanager/tests/test_sql_queries.sh`

This is the largest remaining feature gap.

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

Add references and templates from the original plugins under Codex skill directories.

### Phase 3 — Port advisory hooks

Add Codex-native advisory versions of:

- asset inventory
- look-before-describe
- self-challenge
- session retrospective
- docs update reminder
- doc curation reminder

Keep them reviewable and advisory.

### Phase 4 — Convert agents to a Codex strategy

Do not assume Claude agent files run as-is. Convert them deliberately.

### Phase 5 — Port TaskManager engine

Port SQLite schema, migrations, query catalog, tests, and command-like skills as a separate, heavily tested slice.

## Current verdict

The repository is now a functional Codex plugin, but not yet a full parity port of the original `mwguerra/plugins` suite.

The next safe step is Phase 2: add selected reference material and templates under the Codex skill directories while keeping hooks disabled or advisory-only and leaving the TaskManager engine for a separate tested phase.
