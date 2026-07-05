# Installation

Add this repository as a Codex plugin marketplace, then install the `engineering-discipline` plugin.

## Marketplace path

The repository marketplace file is:

```text
.agents/plugins/marketplace.json
```

The installable plugin is:

```text
plugins/engineering-discipline/.codex-plugin/plugin.json
```

## After installing

Restart Codex so skills and hooks are discovered.

Expected skills:

- `maestro-route`
- `maestro-implement`
- `maestro-adversarial-verify`
- `maestro-deep-analysis`
- `maestro-deep-work`
- `maestro-regression`
- `maestro-journey`
- `prd-builder-prd`
- `prd-builder-feature`
- `prd-builder-bugfix`
- `prd-builder-refine`
- `scribe-docs-discipline`
- `scribe-init`
- `scribe-sync`
- `scribe-verify`
- `architect-design`
- `architect-refine`
- `architect-review`
- `taskmanager-lite`
- `laravel-conventions`
- `filament-conventions`

The default hook set is advisory-only. The package also includes an optional extended advisory
preset at `plugins/engineering-discipline/hooks/extended-advisory-hooks.json`; it is not enabled
by default. Hooks can be left disabled or untrusted if you only want the skills and docs.

The installed plugin also includes passive references and templates under relevant skill
directories, including architecture heuristics, PRD templates, Scribe docs templates,
TaskManager-lite planning examples, deep-analysis output structure, and Filament v5 recipes.
They do not add skills, enable strict hooks, or install the upstream SQLite TaskManager engine.
