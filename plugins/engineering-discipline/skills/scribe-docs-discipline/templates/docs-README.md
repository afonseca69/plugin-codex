# Project Documentation

This `docs/` directory is the project source of truth. System facts must match
the code. Decisions must reflect the current decision of record. Incidents must
describe real failures and fixes. Intent docs must stay current and owned.

## Start Here

| Path | Use it for |
|---|---|
| [`STATUS.md`](./STATUS.md) | Current behavior, components, focus, and health |
| [`architecture/`](./architecture/) | Boundaries, data model, interfaces, and seams |
| [`adr/`](./adr/) | Why durable decisions were made |
| [`incidents/`](./incidents/) | What broke, why, how it was fixed, and prevention |
| [`roadmap.md`](./roadmap.md) | Planned work and triggers |
| [`open-questions.md`](./open-questions.md) | Undecided questions with owners |
| [`prd/`](./prd/) | Requirements |
| [`deep-analysis/`](./deep-analysis/) | Audit findings |

## Update Rule

After work changes behavior, decisions, architecture, incidents, roadmap, or
open questions, update the matching doc in the same change.
