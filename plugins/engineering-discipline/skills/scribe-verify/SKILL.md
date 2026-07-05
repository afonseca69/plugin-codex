---
name: scribe-verify
description: "Adversarially verify docs/ against code, decisions, incidents, and cross-document staleness, then report advisory drift."
---

# Scribe Verify

Use this skill to prove `docs/` is still true. The verifier does not trust the writer. It
tries to refute each claim using code, config, tests, history, and other docs.

## Truth types

| Type | Lives in | True means | Check |
|---|---|---|---|
| System facts | `STATUS.md`, `architecture/` | Matches current code and behavior | Compare doc claims to code, config, tests, and commands |
| Decisions | `adr/` | Current decision of record | Check status, supersession links, and consistency with code |
| Incidents | `incidents/` | Accurate postmortem | Verify symptom, root cause, fix, and prevention are evidenced |
| Intent | `roadmap.md`, `open-questions.md` | Current and owned | Find shipped items still on roadmap and answered questions still open |

## Process

1. **Confirm scope.** Verify all docs by default, or a narrowed type/path when requested.
2. **Resolve referent.** Use the current working tree unless the user names a git ref.
3. **Enumerate claims.** Read the in-scope docs and split claims into atomic statements.
4. **Refute by type.** For each claim, identify what would prove it stale or false, then
   inspect direct evidence.
5. **Use multiple lenses for risky docs.** For broad or high-risk verification, run
   separate passes for system facts, ADR currency, incidents, and intent staleness. Use
   `maestro-adversarial-verify` when a claim is consequential.
6. **Aggregate findings.** Keep minority findings when they have evidence. A claim is
   accurate only when no pass could overturn it with evidence.
7. **Report only.** Verification is advisory and read-only; use `scribe-sync` to curate
   fixes.

Use `../scribe-docs-discipline/references/docs-layout.md` for the canonical truth types
and stale-doc checks.
Use `references/agent-doc-verifier.md` for the fuller Codex-native read-only verifier
persona adapted from the upstream agent prompt.

## Verdicts

- `accurate`: evidence supports the claim.
- `drift`: a system fact no longer matches code or behavior.
- `stale`: an intent or decision artifact should have moved or been superseded.
- `conflict`: an accepted ADR and the code disagree; flag for human resolution.
- `unsupported`: the claim might be true, but the verifier found no evidence.

## Output format

```text
scribe-verify - advisory
Referent:
Scope:
Claims checked:
Summary:
  accurate:
  drift:
  stale:
  conflict:
  unsupported:

Findings:
  - Doc:
    Claim:
    Type:
    Verdict:
    Evidence:
    Recommended fix:
```

## Guardrails

- Do not fix docs while verifying.
- Do not treat missing evidence as proof.
- Do not auto-resolve ADR/code conflicts.
- Do not claim docs are accurate unless the check actually ran.
