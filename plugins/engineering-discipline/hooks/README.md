# Hooks

## Default hook set

`hooks/hooks.json` is advisory-only:

- `read_docs_first.sh` adds docs-first guidance when a prompt arrives.
- `verify_before_commit.sh` reminds before `git commit`.
- `restart_reminder.sh` reminds after a commit if runtime reload may be needed.

These hooks provide context and reminders only.

They are the plugin entry-point hooks referenced by `.codex-plugin/plugin.json`. The Phase 3
extended hooks are not added to this default file.

## Optional extended advisory hook set

`hooks/extended-advisory-hooks.json` is an opt-in advisory preset. It includes the default
advisory hooks plus:

- `asset_inventory_gate.sh` reminds on build-new prompts to inventory existing code before
  adding another asset.
- `ls_real_preflight.sh` reminds on system-description prompts to inspect real files, callers,
  output, and recent history before explaining behavior.
- `self_challenge_gate.sh` reminds on deep tasks to verify claims and challenge the first
  framing before delivering an answer.
- `session_retro.sh` reminds on wrap-up prompts to capture durable lessons and follow-ups.
- `docs_update_gate.sh` reminds before `git commit` to pay docs debt when behavior, decisions,
  incidents, architecture, status, or open questions changed.
- `curate_on_stop.sh` reminds at Stop, when `docs/` exists, to curate decisions/errors into docs
  and verify changed claims.

These scripts return Codex hook JSON with `additionalContext` only. They never deny, block, write
files, run git write commands, or call external services.

## Optional strict hook set

`hooks/enforcing-hooks.json` contains stricter examples:

- `verify_commit_gate.sh` checks whether a pending commit has ledger evidence.
- `verify_stop_gate.sh` checks whether uncommitted tracked work has ledger evidence before stopping.

Use strict mode only after a live Codex smoke test in your own environment. Codex hooks are guardrails, not sandbox-grade security.

## Reviewing and trusting hooks in Codex

Review the script and JSON files in this directory before trusting any hook profile in Codex.
The default plugin entry point is `hooks/hooks.json`; the extended and strict JSON files are
manual alternatives for users who choose to configure them.

In Codex, use the hook review UI for the installed plugin, inspect the command paths, and trust
only the profile you intend to run. It is safe to keep hooks disabled or untrusted; the skills and
documentation still work without hook execution.

## Ledger commands

```bash
bash hooks/lib/ledger.sh hash --cached
bash hooks/lib/ledger.sh pass all "ran tests and review"
bash hooks/lib/ledger.sh mark tests pass <ref> "test evidence"
bash hooks/lib/ledger.sh mark adversarial pass <ref> "review evidence"
bash hooks/lib/ledger.sh waive <ref> "low-risk docs-only change"
bash hooks/lib/ledger.sh covered <ref>
```

The ledger defaults to `.codex/engineering-discipline-ledger.log` in the target git repository when possible.
