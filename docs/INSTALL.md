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
- `taskmanager-engine-init`
- `taskmanager-engine-status`
- `taskmanager-engine-next`
- `taskmanager-engine-show`
- `taskmanager-engine-memory`
- `taskmanager-engine-export`
- `taskmanager-engine-test`
- `laravel-conventions`
- `filament-conventions`

The default hook set is advisory-only. The package also includes an optional extended advisory
preset at `plugins/engineering-discipline/hooks/extended-advisory-hooks.json`; it is not enabled
by default. Hooks can be left disabled or untrusted if you only want the skills and docs.

The installed plugin also includes passive references, templates, and agent/persona guides
under relevant skill directories, including architecture heuristics, PRD templates, Scribe
docs templates, TaskManager-lite planning examples, deep-analysis output structure, and
Filament v5 recipes. It also includes TaskManager SQLite engine artifacts and a manual wrapper
under:

```text
plugins/engineering-discipline/skills/taskmanager-lite/references/taskmanager-engine
```

The wrapper is `bin/taskmanager-engine.sh` inside that directory. It is manual only and supports
safe `init`, `status`, `next`, `show`, memory list/show/search/add/deprecate, `export-json`, and
`run-sql-tests` commands. Only `init`, `memory-add`, and `memory-deprecate` mutate
`PROJECT_DIR/.taskmanager`; read-only commands open the initialized database read-only. The
`taskmanager-engine-*` skills are first-class Codex guides for those manual operations. These
materials do not enable strict hooks, run automatic agents, auto-run TaskManager, or register
Codex commands.
