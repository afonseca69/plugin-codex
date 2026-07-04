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
- 8 first-class Codex skills

Current Codex skills:

- `architect-design`
- `laravel-conventions`
- `maestro-adversarial-verify`
- `maestro-deep-analysis`
- `maestro-implement`
- `maestro-route`
- `scribe-docs-discipline`
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

## Commands not yet ported as first-class Codex skills

### Architect

- `architect/commands/refine.md`
- `architect/commands/review.md`

`architect/commands/design.md` is partially represented by `architect-design`.

### Maestro

- `maestro/commands/deep-work.md`
- `maestro/commands/journey.md`
- `maestro/commands/regression.md`

These are not yet first-class Codex skills.

Already represented:

- `maestro/commands/adversarial-verify.md` -> `maestro-adversarial-verify`
- `maestro/commands/deep-analysis.md` -> `maestro-deep-analysis`
- `maestro/commands/implement.md` -> `maestro-implement`
- `maestro/commands/route.md` -> `maestro-route`

### PRD Builder

None of the original PRD Builder commands have been ported yet:

- `prd-builder/commands/bugfix.md`
- `prd-builder/commands/feature.md`
- `prd-builder/commands/prd.md`
- `prd-builder/commands/refine.md`

### Scribe

The original Scribe command set has not been ported as first-class skills yet:

- `scribe/commands/init.md`
- `scribe/commands/sync.md`
- `scribe/commands/verify.md`

`scribe-docs-discipline` currently covers only the general discipline.

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

## Skills not yet ported as first-class Codex skills

### Laravel

- `laravel/skills/filament-conventions/SKILL.md`

`laravel-conventions` exists, but Filament-specific guidance is not yet first-class.

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

Partially or not yet ported:

- `maestro/skills/deep-work/SKILL.md`
- `maestro/skills/regression/SKILL.md`

Already represented:

- `maestro/skills/adversarial-verify/SKILL.md`
- `maestro/skills/deep-analysis/SKILL.md`
- `maestro/skills/implementation/SKILL.md`
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

Add missing high-value skills without porting engines yet:

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

The next safe step is Phase 1: add the missing first-class Codex skills while keeping hooks disabled or advisory-only.
