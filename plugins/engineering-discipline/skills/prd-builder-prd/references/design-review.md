# PRD Design Review

After drafting a PRD in memory, run these two review lenses silently and rewrite
the final PRD so the surviving decisions are integrated. Do not write separate
review notes unless the user explicitly asks for them.

## Lens 1: Experience And Simplicity

Review the product from the user's experience.

Ask:

- What one story does the product tell?
- Does every feature serve the thesis and hero flow?
- Which options, settings, screens, or steps make the user think about internal
  machinery instead of their goal?
- What is the first-run moment where value becomes obvious?
- Which single improvement would make the hero flow feel much sharper?

Outputs to apply:

- Cut-list of features, options, and steps.
- Sharpened one-sentence product promise.
- Simplified hero flow.
- Craft notes for the few moments that matter.

## Lens 2: First-Principles Engineering

Review the product from cost, physics, and operational truth.

Apply this order:

1. Question every requirement. Name the owner.
2. Delete anything that is not needed.
3. Simplify what survives.
4. Accelerate the remaining critical path.
5. Automate only after the above.

Ask:

- What breaks if this requirement is removed?
- Which dependencies or services are unnecessary for v1?
- What is the real bottleneck?
- What would make the core mechanism 10x simpler or cheaper?
- What must be decided now because it is expensive to change?

Outputs to apply:

- Keep/delete/simplify decisions with owners.
- Leaner launch architecture.
- Compressed critical path.
- Deferred roadmap entries with triggers.

## Reconciliation

- If both lenses say to cut something, cut it.
- If the lenses conflict, record an explicit decision with owner and rationale.
- Rewrite the final PRD, not just one section. The thesis, hero flow, launch
  scope, requirements, technical approach, decisions, risks, and roadmap should
  all reflect the review.
