# Canonical `docs/` Layout

This reference describes the default living-docs structure used by the Scribe
skills. Treat it as a contract for where truth belongs, not as a requirement to
invent facts.

## Tree

```text
docs/
  README.md
  STATUS.md
  architecture/
    README.md
    boundaries.md
    data-model.md
    interfaces.md
  adr/
    NNNN-title.md
  incidents/
    NNNN-title.md
  roadmap.md
  open-questions.md
  prd/
  deep-analysis/
```

`NNNN` is a zero-padded sequence per directory. Do not reuse numbers.
Superseded ADRs remain in place and link to the superseding ADR.

## Truth Types

| Path | Purpose | Truth type |
|---|---|---|
| `docs/README.md` | Front door and index | Index |
| `docs/STATUS.md` | What the system is and does now | System fact |
| `docs/architecture/` | Boundaries, ownership, interfaces, seams | System fact |
| `docs/adr/NNNN-*.md` | One decision of record | Decision |
| `docs/incidents/NNNN-*.md` | One postmortem | Incident |
| `docs/roadmap.md` | Planned/future work with triggers | Intent |
| `docs/open-questions.md` | Undecided questions with owners | Intent |
| `docs/prd/` | Requirements owned by PRD Builder | Ingested |
| `docs/deep-analysis/` | Audit findings owned by Maestro | Ingested |

## Obligation Contract

| When work does this | Update this |
|---|---|
| Changes what the system is or does | `docs/STATUS.md` |
| Changes a boundary, data model, or interface | `docs/architecture/` and an ADR |
| Makes or changes a durable decision | ADR with owner, date, consequences, and trigger to revisit |
| Supersedes a decision | Mark old ADR superseded and add a new ADR |
| Fixes a non-trivial error | Incident note, plus STATUS/architecture if behavior changed |
| Defers an undecided item | `docs/open-questions.md` with owner |
| Plans future work | `docs/roadmap.md` with trigger |
| Ships a roadmap item | Move it from roadmap intent to STATUS/system fact |
| Answers an open question | Move it to an ADR |

## Ingestion Rule

Link to PRDs, deep analyses, design specs, and large reports. Do not copy them
into STATUS, ADRs, or architecture docs. If an ingested artifact becomes system
truth, restate only the checkable one-line fact and link to the source.

## Template Map

| Template | Target |
|---|---|
| `templates/docs-README.md` | `docs/README.md` |
| `templates/STATUS.md` | `docs/STATUS.md` |
| `templates/adr.md` | `docs/adr/NNNN-*.md` |
| `templates/incident.md` | `docs/incidents/NNNN-*.md` |
| `templates/roadmap.md` | `docs/roadmap.md` |
| `templates/open-questions.md` | `docs/open-questions.md` |

## Style Rules

- Absolute dates: `YYYY-MM-DD`.
- Lean docs: snapshots and links over duplication.
- Atomic docs: one decision per ADR, one incident per postmortem.
- Anchored claims: system facts cite code, config, tests, commands, or docs.
- Tables for structured data.
- Stale docs are defects.
