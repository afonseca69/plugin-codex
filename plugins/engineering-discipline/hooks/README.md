# Hooks

## Default hook set

`hooks/hooks.json` is advisory-only:

- `read_docs_first.sh` adds docs-first guidance when a prompt arrives.
- `verify_before_commit.sh` reminds before `git commit`.
- `restart_reminder.sh` reminds after a commit if runtime reload may be needed.

These hooks provide context and reminders only.

## Optional strict hook set

`hooks/enforcing-hooks.json` contains stricter examples:

- `verify_commit_gate.sh` checks whether a pending commit has ledger evidence.
- `verify_stop_gate.sh` checks whether uncommitted tracked work has ledger evidence before stopping.

Use strict mode only after a live Codex smoke test in your own environment. Codex hooks are guardrails, not sandbox-grade security.

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
