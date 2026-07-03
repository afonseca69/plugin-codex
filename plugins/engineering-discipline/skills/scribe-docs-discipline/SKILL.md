---
name: scribe-docs-discipline
description: Keep repository documentation accurate as living project truth. Use when initializing docs, changing behavior, closing phases, recording decisions, or checking docs against code.
---

# Scribe Docs Discipline

Documentation is part of the product. Stale docs are defects.

## Rules

- Read existing `AGENTS.md`, `README.md`, and relevant `docs/` before editing code.
- Update docs in the same change when behavior, commands, architecture, deployment, or constraints change.
- Remove obsolete operational guidance rather than layering contradictions.
- Use ADRs for durable decisions and tradeoffs.
- Use incident notes for failures, regressions, and production surprises.
- Link artifacts instead of copying large content between docs.

## Suggested layout

```text
docs/
  STATUS.md
  roadmap.md
  architecture/
  adr/
  incidents/
  deep-analysis/
```

## Verification

When asked to verify docs:

- enumerate claims in the doc;
- check each claim against code/config/tests;
- mark claim as true, stale, unsupported, or ambiguous;
- patch stale claims or produce a fix list.
