# Engineering Discipline plugin for Codex

Installable Codex plugin exposed by the root marketplace.

## Contents

- Codex skills in `skills/*/SKILL.md`.
- Selected reference and template material under skill-local `references/` and
  `templates/` directories.
- Passive TaskManager SQLite engine artifacts under
  `skills/taskmanager-lite/references/taskmanager-engine/`.
- Advisory lifecycle hooks in `hooks/hooks.json`.
- Optional strict hook examples in `hooks/enforcing-hooks.json`.
- Ledger helper in `hooks/lib/ledger.sh` for recording verification evidence.

## Default behavior

The default hook set is advisory. It gives reminders and context, but does not deny actions.

The reference/template material is passive skill content. It does not enable hooks, create
background services, run TaskManager, or install command wrappers. The TaskManager engine
artifacts are schema/config, migrations, query catalog, and copied test assets only.

## Optional strict mode

Read `hooks/README.md` before experimenting with strict hooks. Use strict mode only after a live Codex smoke test in your environment.
