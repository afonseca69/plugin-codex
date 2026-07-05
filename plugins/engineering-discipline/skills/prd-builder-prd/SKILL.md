---
name: prd-builder-prd
description: "Turn a rough product idea into a full Codex-native PRD under docs/prd with thesis, hero flow, lean launch scope, decisions, risks, and verification."
---

# PRD Builder PRD

Use this skill to create a full product PRD from a rough idea. The PRD is the product
truth that downstream design, planning, implementation, and verification use.

## Principles

- Lead with a one-line product thesis and the single hero flow that proves value.
- Keep launch scope lean; move non-essential work to a sequenced deferred roadmap with
  reasons.
- Prefer decisions with owners over vague open questions.
- Put technology in service of the user flow, not ahead of it.
- Vet new dependencies for license, maintenance, and necessity before recommending them.

## Process

1. **Read context.** Read `AGENTS.md`, `README.md`, `docs/STATUS.md`, existing PRDs, and
   relevant roadmap/open-question files when they exist.
2. **Capture the idea.** If the user provided a prompt, use it. Otherwise ask for the
   product or major feature in their own words.
3. **Generate a slug.** Use kebab-case and write the final file as
   `docs/prd/prd-{slug}.md`.
4. **Interview by category.** Ask only decision-changing questions. Cover:
   problem/context, users, solution/features, technical implementation, business value,
   UX/design, risks, and testing/quality.
5. **Choose a stack deliberately.** If the stack is already present, follow it. If not,
   offer the repository's default conventions or a clearly marked recommended default and
   record the choice in Decisions.
6. **Draft in memory first.** Include Mermaid diagrams only when they clarify flow or
   architecture.
7. **Run a silent two-lens review.** First subtract for experience and simplicity. Then
   challenge the engineering plan from first principles: fewest moving parts, explicit
   owners, no unnecessary dependencies. Reconcile conflicts into Decisions.
8. **Write only the final PRD.** Save one final artifact under `docs/prd/`; do not save
   scratch review notes.
9. **Handoff.** Recommend `architect-design` for non-trivial or irreversible work, then
   `taskmanager-lite` to decompose implementation tasks.

Useful references:

- `references/question-bank.md` for interview categories and adaptive shortcuts.
- `references/default-stack.md` for a greenfield SaaS default profile that must be
  verified before adoption.
- `references/design-review.md` for the silent two-lens review.
- `references/agent-prd-interviewer.md` for the fuller Codex-native interview
  persona adapted from the upstream agent prompt.
- `templates/prd-template.md` for the final PRD structure.

## Recommended PRD shape

```text
Title
Last updated
Product thesis
Hero flow
Executive summary
Problem and context
Users and personas
Launch scope v1
Deferred roadmap
Features and acceptance criteria
Technical approach
Dependencies and decisions
UX notes
Risks and mitigations
Testing and quality plan
Open questions
```

## Guardrails

- Do not create migrations, integrations, jobs, or implementation files while writing the
  PRD.
- Do not invent user research; label assumptions.
- Do not leave placeholders such as TBD in the final PRD.
- If the user pauses, preserve state in the conversation or a small draft note only when
  necessary; no TaskManager engine is required.
