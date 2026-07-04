# Architecture Design Heuristics

These checklists adapt the upstream `architecture-design` reference material for
Codex-native skills. Use them when `architect-design`, `architect-refine`, or
`architect-review` needs more mechanical guidance than the skill summary.

## Context Elicitation

Ask only questions that change a design decision. Capture answers as the Context
section of the design or ADR.

### Scale

- Current users, tenants, request rate, read/write mix, and largest data entity.
- Realistic 6-18 month growth shape: flat, linear, campaign-driven, or viral.
- Data volume and growth rate.
- Latency expectations for the hero flow.
- Burst patterns, batch windows, and long-running jobs.

### Risk And Compliance

- Money, payments, financial records, or billing correctness.
- PII, health data, regulated data, residency, retention, or audit needs.
- Uptime expectations and the cost of an hour of downtime.
- Worst credible blast radius of a bug in the area.

### Team And Operations

- Current team size and expected team shape.
- Deployment and operations maturity.
- Budget or hosting constraints.
- Brownfield boundaries, existing stack, and current docs/ADRs.

## One-Way Door Test

Treat a decision as expensive to change when reversing it requires one or more of:

- data migration or data ownership change;
- public API, client, or cross-team contract change;
- auth, tenancy, money, compliance, or audit semantics;
- many downstream dependents before it can be revisited;
- recovery work if it is wrong, not just refactoring.

Spend design effort on these decisions now. Defer reversible choices when they can
sit behind an interface and be revisited with better information.

## Decide Now

- Data model and boundary ownership.
- Core module/service boundaries.
- Key public or internal contracts that other work will depend on.
- Security, tenancy, money, and lifecycle state decisions.
- Seams whose boundary is cheap now and expensive to retrofit later.
- Concrete extraction or revisit triggers for each seam.

## Defer

- Vendor/library choices behind an already-owned interface.
- Caches, queues, replicas, sharding, or services without a measured trigger.
- Optimizations that require production evidence.
- Decisions whose accuracy improves materially with later information and whose
  cost of change remains low.

Record deferrals in `docs/open-questions.md` when undecided, or in
`docs/roadmap.md` when planned with a trigger.

## Subtraction Test

Every component, layer, service, dependency, or abstraction must pass at least
one test:

1. A present PRD requirement needs it now.
2. It is a cheap boundary for an expensive future extraction with a concrete
   trigger.

If it passes neither, remove it from the design.

Common removal candidates:

- queues, caches, services, or message buses added "just in case";
- wrappers over a single implementation with no plausible second implementation;
- microservices chosen before team, scale, or blast-radius evidence exists;
- plugin/config engines for one current case;
- speculative scale work without a threshold.

## Adversarial Review Lenses

Before accepting the design, try to refute it:

- Boundary leaks: where two modules share tables, transactions, mutable state, or
  hidden assumptions.
- Scale break: the first plausible bottleneck under the elicited future.
- Irreversible mistake: a data, ownership, auth, money, or contract choice lacking
  an ADR or evidence.
- Over-engineering: any component that fails the subtraction test.
- PRD trace: anything that does not serve the hero flow, launch scope, or a
  documented seam.
- Trigger quality: triggers that are vague, ownerless, or impossible to observe.

Drop overturned design claims rather than patching around weak assumptions.

## Good Revisit Triggers

A good trigger is:

- concrete and observable: a metric, threshold, event, dependency, or date;
- owned by a role or person;
- tied to a planned path, such as the seam to extract;
- falsifiable, so it can say "not yet" as clearly as "now";
- written in the ADR and any architecture boundary/seam table.

Examples:

| Weak | Strong |
|---|---|
| Revisit if it gets slow. | Extract report generation to a worker queue when report requests push hero-flow p95 above 500 ms for two consecutive business days. Owner: backend lead. |
| Add replicas when we have more users. | Add a read replica when primary CPU sustains over 70 percent and read queries are over 80 percent of DB load. Owner: ops. |
| Split billing later. | Split billing when a dedicated billing team owns its release cadence or billing deploys must be isolated from core. Owner: engineering manager. |

## Output Checklist

- Read `AGENTS.md`, `README.md`, relevant `docs/`, PRDs, and accepted ADRs.
- Elicit scale, risk/compliance, team, ops, and brownfield constraints.
- Identify one-way decisions and write one ADR per significant decision.
- Apply the subtraction test.
- Place seams from `seam-catalog.md` only where a plausible trigger exists.
- Challenge the design with the adversarial lenses above.
- Write or update `docs/architecture/` and `docs/adr/` according to the Scribe
  docs layout.
