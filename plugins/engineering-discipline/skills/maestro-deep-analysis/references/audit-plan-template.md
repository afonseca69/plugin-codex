# Deep Analysis Audit Plan Template

Use this template to structure a Codex-native deep analysis. It adapts the
upstream multi-agent workflow reference without depending on a specific runtime.

## Scope

```text
Repository:
Date:
Git ref:
Working tree caveat:
User goal:
Non-goals:
High-risk domains:
```

## Scout

Read first:

- `AGENTS.md`, `README.md`, and relevant `docs/`.
- Repository tree and package manifests.
- Recent git history.
- Entry points for the requested subsystem.
- Tests, configs, jobs, commands, routes, and public APIs near the area.

Write down area candidates with file anchors before launching deep reading.

## Area Plan

| Key | Label | Scope | File anchors | Flow map? |
|---|---|---|---|---|
| auth | Authentication and authorization | ... | `app/...` | yes/no |
| tests | Test coverage and false positives | ... | `tests/...` | no |

Choose enough areas to cover the risk, but keep each area narrow enough that the
reader can be exhaustive.

Always consider these cross-cutting areas when relevant:

- architecture and module boundaries;
- data model, ownership, and migrations;
- authorization and permissions;
- lifecycle/state behavior;
- tests and missing regression checks;
- external integrations, queues, schedulers, and runtime config;
- deployment and restart assumptions;
- documentation drift.

## Reader Output Schema

Each area reader should produce:

```text
Area:
Summary:
Implemented:
  - claim with evidence
Gaps:
  - title:
    severity:
    detail:
    files:
Flaws:
  - title:
    severity:
    detail:
    evidence:
    files:
Questions:
  - decidable owner question
Coverage caveats:
```

Severity:

- `critical`: money loss, data loss, security hole, tenant/auth leak.
- `high`: broken or wrong behavior in a common path.
- `medium`: edge-case bug, missing safeguard, serious DX/UX issue.
- `low`: polish or clarity.

## Refute Pass

For every critical/high flaw, run an independent refute-first check:

```text
Claim:
Evidence cited:
Related callers/guards/tests checked:
Refutation attempts:
Verdict: confirmed | refuted | downgraded | unverified
Corrected severity:
Reasoning:
```

Default to refuted until the evidence survives direct reading. Check for guards
elsewhere in the call chain, intentional behavior, configuration gates, and test
coverage that contradicts the claim.

## Synthesis

Produce:

- production-readiness or release-readiness assessment;
- deduplicated roadmap buckets P0/P1/P2/quick wins;
- merged source links for duplicate findings;
- questions requiring owner decisions;
- explicit coverage gaps.

## Publish

Write the tree described in `references/output-structure.md` when the user asked
for a persisted audit or when the result should inform future work. Otherwise,
return the same structure in the conversation and state that no files were
written.
