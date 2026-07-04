---
name: maestro-journey
description: "Render a read-only, evidence-backed view of one feature from PRD through design, tasks, verification, regression, and shipped status."
---

# Maestro Journey

Use this skill to answer: "Where is this feature in the engineering lifecycle?" It is a
read-only composer over existing artifacts. It creates no datastore, writes no gate, and
does not imply a link where the repository has not recorded one.

## Key

The de facto join key is the PRD slug, usually `docs/prd/prd-{slug}.md`. If the docs and
tasks do not share a traceable PRD path or slug, show both sides separately and mark them
`unlinked`.

## Process

1. **Resolve the feature.** Accept a slug, name, or PRD path. Normalize paths relative to
   the repo root.
2. **Read docs-side evidence.**
   - PRD: `docs/prd/prd-{slug}.md`
   - Design: `docs/architecture/` and related `docs/adr/`
   - Current truth: `docs/STATUS.md`
   - Roadmap: `docs/roadmap.md` and `docs/open-questions.md`
3. **Read task-side evidence.** Use local task artifacts if they exist. In this Codex
   port, prefer `taskmanager-lite` plans, checklists in docs, PR descriptions, or commit
   history over any raw TaskManager SQLite access. Do not require the upstream engine.
4. **Read verification evidence.** Look for test commands, `maestro-regression` verdicts,
   PR checks, review notes, or captured evidence in docs.
5. **Render one table.** Mark each stage as `present`, `partial`, `absent`, or
   `unlinked`, with a pointer to the evidence.

## Guardrails

- Read only. Do not create or update docs as part of a journey report.
- Never infer shipped status from task completion alone; check `STATUS.md`, release notes,
  git history, or runtime evidence.
- Treat missing regression evidence as `not run`, not `clean`.
- If the feature cannot be resolved, point to `prd-builder-prd` or `prd-builder-feature`.

## Output format

```text
Journey: <feature>
Join verdict: joined on <path> | unlinked | docs-only | tasks-only

| Stage | Status | Evidence | Notes |
|---|---|---|---|
| Idea / PRD | present | docs/prd/prd-...md | ... |
| Design | partial | docs/architecture/... | ... |
| Tasks | unlinked | ... | ... |
| Verified | absent | ... | ... |
| Regression clean | absent | ... | ... |
| Shipped | partial | docs/STATUS.md | ... |

Gaps:
Next evidence to collect:
```
