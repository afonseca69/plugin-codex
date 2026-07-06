# Release readiness checkpoint: 0.1.10

## Release snapshot

- Plugin: `engineering-discipline`
- Version: `0.1.10`
- Branch used for this checkpoint: `docs/release-readiness-0.1.10`
- Marketplace entry point: `.agents/plugins/marketplace.json`
- Plugin entry point: `plugins/engineering-discipline/.codex-plugin/plugin.json`
- Default hook entry point: `plugins/engineering-discipline/hooks/hooks.json`
- Skill count: 26 first-class Codex skills
- Release posture: documentation/status checkpoint only; no runtime behavior change and no
  version bump.

Version `0.1.10` is ready as a Codex-native plugin release checkpoint for the completed parity
phases listed below. This is not a claim of full upstream parity with `mwguerra/plugins`.

## Installed cache validation status

The installed cache for plugin version `0.1.10` was validated successfully before this checkpoint.
Validation covered plugin metadata, hook syntax, skill discovery, passive TaskManager SQLite
artifacts, the manual TaskManager wrapper, and first-class manual wrapper operation skills.

Cache-level status recorded for this checkpoint:

- installed cache `0.1.10` validated successfully;
- skill count observed as 26;
- SQL query suite passed;
- lifecycle suite passed;
- wrapper CLI regression suite passed;
- manual wrapper smoke passed.

This document records that validation state. It does not alter the installed cache, plugin
manifest, hooks, skills, wrapper scripts, or TaskManager artifacts.

## Completed phases

- Phase 1: first-class parity skills.
- Phase 2: references and templates.
- Phase 3: optional extended advisory hooks.
- Phase 4: Codex agent/persona strategy.
- Phase 5A: passive TaskManager SQLite artifacts.
- Phase 5B: manual TaskManager engine wrapper.
- Phase 5C: first-class skills for wrapper operations.

## Supported now

The `0.1.10` plugin currently supports:

- one installable Codex plugin named `engineering-discipline`;
- 26 first-class Codex skills for routing, implementation, adversarial verification,
  regression review, architecture, PRDs, Scribe docs, Laravel/Filament conventions, and manual
  TaskManager wrapper operation;
- selected Codex-adapted references, templates, and passive persona guides under skill-local
  `references/` and `templates/` directories;
- default advisory-only hooks for documentation-first reminders, verification reminders before
  commit, and runtime restart/recheck reminders;
- optional extended advisory hook preset kept outside the default hook entry point;
- optional enforcing hook preset kept outside the default hook entry point;
- passive TaskManager SQLite schema/config, migrations, query catalog, copied tests, and usage
  notes under `taskmanager-lite/references/taskmanager-engine/`;
- an explicit manual TaskManager wrapper at
  `taskmanager-lite/references/taskmanager-engine/bin/taskmanager-engine.sh`;
- first-class Codex skills for the supported manual wrapper operations:
  `taskmanager-engine-init`, `taskmanager-engine-status`, `taskmanager-engine-next`,
  `taskmanager-engine-export`, and `taskmanager-engine-test`.

## Intentionally not claimed

The `0.1.10` release does not claim:

- full upstream parity with the original Claude Code plugin suite;
- full SQLite-backed TaskManager runtime parity;
- Codex command registration for the original TaskManager command set;
- automatic TaskManager execution, schedulers, background jobs, or hidden runtime services;
- upstream TaskManager command parity for `plan`, `run`, `verify`, `show`, `update`, `memory`,
  `research`, or related workflows;
- default enablement of extended advisory hooks;
- default enablement of enforcing hooks;
- production reliability for enforcing hooks without live target-environment smoke testing;
- Claude-specific runtime behavior or dependencies.

## Validation commands and results

Required repository validation for this checkpoint:

```bash
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/enforcing-hooks.json >/dev/null
python3 -m json.tool plugins/engineering-discipline/hooks/extended-advisory-hooks.json >/dev/null
bash -n plugins/engineering-discipline/hooks/*.sh
git diff --check
find . -type d -name __pycache__ -print
```

Additional scope checks for this readiness change:

```bash
python3 - <<'PY'
import json
from pathlib import Path
print(json.loads(Path("plugins/engineering-discipline/.codex-plugin/plugin.json").read_text())["version"])
PY
git diff --name-only -- plugins/engineering-discipline/hooks
git diff --name-status -- 'plugins/engineering-discipline/skills/**/SKILL.md'
find plugins/engineering-discipline/skills -name SKILL.md -print | sort
```

Expected and recorded results:

- JSON validation passed for marketplace, plugin manifest, default hooks, enforcing hooks, and
  extended advisory hooks.
- Hook shell syntax validation passed.
- `git diff --check` passed.
- `find . -type d -name __pycache__ -print` returned no output.
- Plugin version remained `0.1.10`.
- No files under `plugins/engineering-discipline/hooks/` changed.
- No new `SKILL.md` files were added; the skill count remained 26.
- Installed-cache TaskManager SQL, lifecycle, wrapper regression, and wrapper smoke checks were
  already validated successfully for `0.1.10`.

## Hook safety status

Hook behavior is unchanged in `0.1.10`:

- default hooks remain advisory-only;
- optional extended advisory hooks remain opt-in;
- optional enforcing hooks remain opt-in;
- `hooks/hooks.json` remains the plugin hook entry point;
- enforcing hooks must not be described as reliable for a target installation until they pass a
  live Codex smoke test in that installation.

This checkpoint does not edit hooks, enable hooks, or change hook policy.

## TaskManager status

TaskManager parity status for `0.1.10`:

- Phase 5A artifacts are present and validated as passive SQLite engine reference material.
- Phase 5B manual wrapper is present and validated for explicit `init`, `status`, `next`,
  `export-json`, and `run-sql-tests` usage.
- Phase 5C wrapper operation skills are present and validated as first-class Codex operator
  guides around the manual wrapper.
- The copied SQL tests, lifecycle tests, wrapper CLI tests, and wrapper smoke test passed.

This is artifact parity plus limited explicit wrapper operation. It is not full upstream
TaskManager command parity and not a full TaskManager runtime.

## Recommended next phases

Recommended future work after `0.1.10`:

- Phase 5D: design broader Codex-native TaskManager command/runtime parity before implementation,
  including command boundaries, state model, safety rules, and verification strategy.
- Live hook verification: if strict hooks are promoted in the future, run and document live Codex
  smoke tests in the target installation before changing defaults or reliability claims.
- Parity review: keep `docs/PARITY-GAP-ANALYSIS.md` current as any remaining upstream skills,
  commands, or runtime behavior are intentionally ported or explicitly deferred.
- Release hygiene: keep release notes precise about supported wrapper operations and avoid
  implying automatic TaskManager behavior.
