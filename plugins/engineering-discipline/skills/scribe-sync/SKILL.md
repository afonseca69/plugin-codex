---
name: scribe-sync
description: "Curate recent work into docs/ and optionally verify the result, keeping documentation current without enforcing hooks or adding storage."
---

# Scribe Sync

Use this skill to consolidate recent work into `docs/` and then verify the result. It is an
advisory workflow: surface drift and missing docs loudly, but do not block work.

## Options to support

- `--since <ref>`: curate changes since a specific commit/ref/date.
- `--verify-only`: skip curation and run `scribe-verify` against current docs.
- `--no-verify`: curate only; warn that the docs remain unverified.

## Process

1. **Confirm docs exist.** If `docs/` is missing, stop and recommend `scribe-init`.
2. **Determine the window.** Prefer the explicit `--since` ref. Otherwise use
   `docs/.scribe/last-sync` when valid, then the last commit touching `docs/`, then a
   clearly stated fallback window.
3. **Gather evidence.** Read:
   - git diff/stat/log for the window plus uncommitted changes;
   - `docs/.scribe/capture.log` if present;
   - `docs/STATUS.md`, `roadmap.md`, `open-questions.md`, recent ADRs/incidents, and
     architecture index files likely affected.
4. **Curate docs.** Update docs according to `scribe-docs-discipline`:
   - decisions become ADRs;
   - non-trivial fixed defects become incidents;
   - shipped behavior updates `STATUS.md`;
   - planned or deferred work goes to `roadmap.md`;
   - unresolved decisions go to `open-questions.md`;
   - architecture changes are recorded as ADRs and flagged for architect-owned docs.
   Use `../scribe-docs-discipline/references/docs-layout.md` when deciding where a claim
   belongs.
5. **Record watermark.** When appropriate, update `docs/.scribe/last-sync` with the current
   commit SHA after curation.
6. **Verify unless skipped.** Run `scribe-verify` and report any drift, stale items, or
   human-resolution conflicts.

## Guardrails

- Link to large artifacts instead of copying them into multiple docs.
- Keep docs lean and atomic: one decision per ADR, one incident per incident note.
- Do not auto-resolve an accepted ADR that code contradicts; flag it for human decision.
- Do not enable strict hooks or add a background curation service.
- If no recent work exists, still allow verification because older docs can drift.

## Output format

```text
Window:
Curated:
  Decisions:
  Incidents:
  System facts:
  Intent / roadmap:
Verification:
Drift / conflicts:
Unverified because:
Next step:
```
