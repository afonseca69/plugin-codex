# Deep Analysis Output Structure

Every deep analysis should publish a stable tree under the analyzed repository.
Stable names make follow-up audits and implementation planning easy to diff.

```text
docs/deep-analysis/
  README.md
  00-executive-summary.md
  01-methodology.md
  roadmap.md
  flows.md              # only when end-to-end flows were mapped
  questions.md
  areas/
    01-<area-key>.md
    02-<area-key>.md
```

## File Contracts

### `README.md`

- Date of the run, absolute `YYYY-MM-DD`.
- Scope and non-goals.
- Index of generated files with one-line descriptions.
- How to rerun or refresh the analysis.

### `00-executive-summary.md`

- Verdict in one paragraph.
- Headline counts: areas checked, findings, confirmed/refuted/unverified flaws,
  gaps, and questions.
- Top risks with links into `roadmap.md` or area docs.
- What is solid, not only what is broken.
- Coverage caveats.

### `01-methodology.md`

- Area table: key, label, one-line scope, files sampled.
- Phase descriptions: scout, map, refute, synthesize, publish.
- Verification stats and any skipped/sampled/truncated areas.
- Date, repository ref, and working-tree caveats.

### `roadmap.md`

Use four buckets:

| # | Title | Area | Effort | Why |
|---|---|---|---|---|
| P0-1 | ... | ... | S/M/L/XL | Consequence if not fixed |

Buckets:

- P0: before production or before the next risky release.
- P1: soon, because a common path or important operation is wrong.
- P2: polish, parity, or future hardening.
- Quick wins: under one hour with disproportionate value.

Exclude refuted findings. Merge duplicates and cite the source area docs.

### `flows.md`

Only write this when a flow-mapping area ran.

| Flow | Status | Trigger | Outbound calls | Callbacks | State changes | Events | Notes |
|---|---|---|---|---|---|---|---|

Status values: `complete`, `partial`, `missing`, `flawed`.

For every non-complete flow, add a short subsection explaining what is missing or
wrong and where the evidence lives.

### `questions.md`

Group owner decisions by area.

| # | Area | Question | Options | Recommendation | Owner |
|---|---|---|---|---|---|

Questions must be decidable. Avoid vague prompts like "what should we do?"

### `areas/NN-<area-key>.md`

Use this order:

1. Summary.
2. Implemented inventory.
3. Gaps table.
4. Flaws, each with verdict, severity, evidence, and refutation result.
5. Questions for the owner.

For flaws:

- Keep refuted flaws in the area doc as refuted, so future audits do not
  rediscover the same non-issue.
- Do not put refuted flaws in the roadmap.
- Use direct `path:line`, config, test, or command evidence.

## Style Rules

- Separate confirmed facts from inference.
- Keep every meaningful claim anchored to code, config, docs, history, or command
  output.
- Use absolute dates.
- Prefer tables for structured data.
- No silent caps: if coverage was sampled or skipped, say exactly what was skipped.
