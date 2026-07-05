---
name: prd-builder-refine
description: "Improve an existing PRD by finding weak or missing requirements, asking targeted questions, and patching the document without changing its intent."
---

# PRD Builder Refine

Use this skill to strengthen an existing PRD. The job is not to rewrite the product from
scratch; it is to find gaps, ask targeted questions, and make the PRD more actionable
while preserving the original decisions and voice.

## Process

1. **Locate the PRD.** Use the provided path or list `docs/prd/*.md`. If none exists,
   recommend `prd-builder-prd` or `prd-builder-feature`.
2. **Read it fully.** Also read `AGENTS.md`, `docs/STATUS.md`, architecture docs, and
   roadmap/open questions when relevant.
3. **Run a gap analysis.** Check for:
   - product thesis and hero flow;
   - problem and affected users;
   - lean launch scope and deferred roadmap;
   - requirements with acceptance criteria;
   - technical approach and integration points;
   - dependency decisions;
   - risks and mitigations;
   - testing and regression plan;
   - Decisions with owners;
   - real open questions.
4. **Prioritize gaps.** Ask targeted questions only for missing or weak sections. Do not
   re-ask what the PRD already answers.
5. **Patch the PRD.** Make focused edits. Preserve adequate existing content, add sections
   only when missing, and update diagrams only when the underlying flow changed.
6. **Review the result.** Confirm there are no placeholders, contradictions, expanded
   scope, or ownerless decisions.
7. **Handoff.** If the refined PRD materially changes implementation work, recommend
   refreshing `architect-design` output or `taskmanager-lite` tasks.

Useful references from `prd-builder-prd`:

- `../prd-builder-prd/references/question-bank.md` for gap-specific questions.
- `../prd-builder-prd/references/design-review.md` when the PRD needs a scope and
  simplicity pass.
- `../prd-builder-prd/templates/prd-template.md` for missing section structure.

## Gap report format

```text
PRD:
Strong sections:
Needs improvement:
Missing sections:
Decision-changing questions:
Planned edits:
```

## Final report format

```text
Updated PRD:
Sections changed:
Sections added:
Decisions added or changed:
Open questions remaining:
Recommended next step:
```

## Guardrails

- Do not broaden the PRD beyond the user's product intent.
- Do not overwrite the whole file when focused edits are enough.
- Do not leave stale roadmap/open-question contradictions.
- Do not generate tasks automatically; offer the next planning step instead.
