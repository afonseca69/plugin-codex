---
name: scribe-init
description: "Bootstrap a living docs/ single source of truth idempotently, using skeleton docs for greenfield projects and evidence-backed analysis for brownfield projects."
---

# Scribe Init

Use this skill to initialize `docs/` as the repository's living source of truth. It is
idempotent: create missing files, keep existing content, and never clobber real docs.

## Modes

- **Already bootstrapped:** `docs/STATUS.md` or equivalent real docs already exist. Report
  what exists and recommend `scribe-verify` or `scribe-sync`.
- **Greenfield:** no substantial code exists. Create the skeleton only; do not invent
  system facts.
- **Brownfield:** code exists but docs are missing, stubbed, or stale. Scaffold first, then
  use `maestro-deep-analysis` evidence before writing system facts.

Honor an explicit user mode when safe, but never overwrite existing content.

## Skeleton

Create missing paths under `docs/`:

```text
docs/
  README.md
  STATUS.md
  architecture/
    README.md
  adr/
    0000-template.md
  incidents/
    .gitkeep
  roadmap.md
  open-questions.md
  .scribe/
    capture.log
```

Use repository templates if they exist. If no templates exist, create lean placeholders
that clearly say what belongs in each file and avoid false claims.

When this plugin's templates are available, use the matching files from
`../scribe-docs-discipline/templates/` and the layout rules in
`../scribe-docs-discipline/references/docs-layout.md`.

## Brownfield baseline

For existing codebases, do not write architecture or status from a quick skim. First run or
reuse `maestro-deep-analysis` so claims are anchored to code, config, tests, and docs. Then
populate only what the evidence supports:

- `STATUS.md`: what the system is and does now, with code/test anchors.
- `docs/architecture/`: baseline boundaries, data ownership, and interfaces if supported
  by evidence. Mark it as architect-owned and ready for `architect-refine`.
- `docs/adr/`: implicit decisions already embodied in code, one decision per ADR.
- `docs/incidents/`: only real, evidenced incidents.
- `roadmap.md` and `open-questions.md`: planned work and unresolved decisions with owners.

Run `scribe-verify` after the baseline and report drift honestly.

## Guardrails

- Never overwrite non-empty docs.
- Never fabricate system facts for greenfield projects.
- Never claim brownfield docs are accurate until verification has checked them.
- Keep default hooks advisory-only; this skill does not enable enforcing hooks.
- Do not port or require the upstream TaskManager SQLite engine.

## Output format

```text
Mode:
Reason:
Created:
Kept:
Brownfield evidence source:
Verification:
Next steps:
```
