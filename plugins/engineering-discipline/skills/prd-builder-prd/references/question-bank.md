# PRD Question Bank

Use this bank for `prd-builder-prd`, `prd-builder-feature`, `prd-builder-bugfix`,
and `prd-builder-refine`. Ask only decision-changing questions. Batch related
questions when the interface supports it; otherwise ask concise direct questions.

## Launch Framing

Use for products and features. Skip for pure bug fixes.

- Product thesis: in one line, what is this and why does it win?
- Hero flow: what single demo proves the value?
- v1 scope stance:
  - hero flow only;
  - hero flow plus 1-2 support features;
  - fuller supporting set;
  - unsure, needs scope cutting.
- Deferral stance:
  - defer anything beyond the hero flow with a reason;
  - decide cheap items now and defer heavy ones;
  - include low-effort extras;
  - keep everything in v1.

## Problem And Context

- What problem is being solved?
- Who experiences it most acutely?
- What is the current workaround?
- Why solve it now?
- How often does it occur?
- What is the impact when it occurs?
- What surrounding constraints shape the problem?

## Users

- Primary user type and role.
- Technical proficiency.
- Main goal during the hero flow.
- Secondary users: admins, managers, support, auditors, external clients.
- Devices and session length.
- Current frustrations with alternatives.

## Solution And Scope

- Core feature that solves the problem.
- Minimum vertical slice.
- Acceptance criteria for each major feature.
- Explicit out-of-scope items.
- Deferred roadmap items, with trigger to revisit.
- Edge cases and errors for each feature.
- Differentiator: speed, simplicity, integration, cost, quality, trust, or other.

## Technical Implementation

- Host product stack, or recommended default when greenfield.
- Architecture shape: monolith, modular monolith, services, serverless, hybrid.
- Data model and ownership decisions.
- Auth, authorization, tenancy, money, and audit requirements.
- External integrations.
- Data volume, concurrency, latency, and availability expectations.
- Deployment target and environment strategy.
- Dependency policy and maintenance verification.

When no stack is specified, consult `references/default-stack.md` as a possible
default profile, not as an unverified fact.

## Business And Value

Skip pricing/revenue questions for internal tools unless the user asks.

- Primary value proposition.
- Success metrics and measurement source.
- Revenue model, if any.
- Pricing or packaging strategy, if relevant.
- Stakeholder or customer acquisition constraints.

## UX And Design

- Primary interaction model: form, dashboard, monitoring, workflow, chat,
  visual tool, API-only.
- Visual style direction and existing design system.
- Key screens in the hero flow.
- Accessibility target.
- Responsive requirements.
- First-run experience and emotional payoff.

## Risks

- Technical risks.
- Business risks.
- Dependencies and blockers.
- Assumptions.
- Mitigation for top risks.
- Fallback if the primary approach fails.

## Testing And Quality

- Acceptance criteria per feature.
- Unit, integration, end-to-end, browser, performance, and manual checks.
- Security and authorization checks.
- Regression risks.
- Rollback strategy.
- Evidence required before calling the work complete.

## Adaptive Shortcuts

- Feature PRD: lighter business section, heavier integration and regression plan.
- Bugfix PRD: reproduction, root cause, fix strategy, rollback, regression
  coverage; skip thesis/hero-flow unless product context changed.
- Internal tool: skip pricing, keep workflow efficiency and operational risk.
- Backend/API only: minimize visual design, keep contract and verification detail.
- Existing product: follow current stack and conventions before proposing defaults.
