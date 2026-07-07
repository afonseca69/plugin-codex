# Engineering Discipline plugin for Codex

Installable Codex plugin exposed by the root marketplace.

## Contents

- Codex skills in `skills/*/SKILL.md`.
- Selected reference and template material under skill-local `references/` and
  `templates/` directories.
- Passive TaskManager SQLite engine artifacts under
  `skills/taskmanager-lite/references/taskmanager-engine/`.
- First-class `taskmanager-engine-*` skills that operate the manual wrapper
  explicitly, including read-only runtime visibility and manual task/memory
  operations.
- Advisory lifecycle hooks in `hooks/hooks.json`.
- Optional strict hook examples in `hooks/enforcing-hooks.json`.
- Ledger helper in `hooks/lib/ledger.sh` for recording verification evidence.

## Default behavior

The default hook set is advisory. It gives reminders and context, but does not deny actions.

The reference/template material is passive skill content. It does not enable hooks, create
background services, auto-run TaskManager, or install command wrappers. The TaskManager engine
artifacts include schema/config, migrations, query catalog, copied test assets, and a manual
wrapper that is operated only through explicit user direction or the `taskmanager-engine-*`
skills. The manual task operations mutate only
`PROJECT_DIR/.taskmanager/taskmanager.db`; they do not cascade parent statuses,
write verification rows, execute tasks, or claim full upstream TaskManager parity.

## Optional strict mode

Read `hooks/README.md` before experimenting with strict hooks. Use strict mode only after a live Codex smoke test in your environment.
