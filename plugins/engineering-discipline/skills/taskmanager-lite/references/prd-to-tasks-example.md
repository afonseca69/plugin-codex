# PRD To Task Plan Example

This reference adapts the upstream TaskManager PRD-ingestion examples for the
Codex-native `taskmanager-lite` skill. It is a planning example only. It does
not require or create `.taskmanager`, SQLite, migrations, memory tables, or an
execution engine.

## Example PRD

```markdown
# Bandwidth Widget

## Objective
Show real-time bandwidth usage so operators can monitor current traffic and
recent history.

## Requirements
- Show current bandwidth usage updating at least every 5 seconds.
- Show a small chart of the last 5 minutes.
- Warn when usage exceeds 80 percent of configured capacity.
- Persist history for later reports.
- Expose a JSON API endpoint for the widget.

## Non-goals
- No auth changes.
- No UI theme changes.

## Constraints
- Existing Laravel application.
- Existing Redis instance.
- Frontend charting already uses Chart.js.
```

## TaskManager-lite Output

```text
Milestone: MVP - realtime bandwidth widget

Tasks:
  T1 - Confirm telemetry source and capacity threshold
    Outcome: The data source, units, and 80 percent threshold are documented.
    Depends on: none
    Acceptance criteria:
      - Source of current Mbps is named.
      - Capacity value and units are defined.
      - Missing telemetry behavior is specified.
    Verification: Owner confirms the documented source and threshold.
    Regression risk: Later tasks may encode the wrong units.
    Out of scope: Building telemetry collection.

  T2 - Define bandwidth API contract
    Outcome: JSON response shape is explicit before implementation.
    Depends on: T1
    Acceptance criteria:
      - Endpoint path and method are named.
      - Response includes current Mbps, 5-minute points, timestamp, and warning flag.
      - Error shape for missing telemetry is defined.
    Verification: Contract reviewed against PRD requirements.
    Regression risk: Frontend/backend mismatch.
    Out of scope: Implementing the endpoint.

  T3 - Implement bandwidth API endpoint
    Outcome: Backend returns current and 5-minute bandwidth data.
    Depends on: T2
    Acceptance criteria:
      - Successful response matches the contract.
      - Missing telemetry returns the defined error.
      - Response time target is documented or tested if required.
    Verification: Focused backend tests for happy path and missing telemetry.
    Regression risk: Incorrect time-window calculation.
    Out of scope: WebSocket streaming.

  T4 - Implement realtime update mechanism
    Outcome: Widget data refreshes at least every 5 seconds.
    Depends on: T3
    Acceptance criteria:
      - Client receives fresh data within the required interval.
      - Disconnect or failed refresh behavior is defined.
    Verification: Integration or browser/manual proof depending on project tooling.
    Regression risk: Polling/streaming load or stale data.
    Out of scope: New queue or broker unless already required by the project.

  T5 - Build bandwidth widget UI
    Outcome: Current Mbps and 5-minute chart render in the existing UI.
    Depends on: T3, T4
    Acceptance criteria:
      - Current Mbps is visible.
      - Chart shows the last 5 minutes.
      - Empty/loading/error states do not break layout.
    Verification: Component/browser test or screenshot/manual smoke check.
    Regression risk: Chart breaks on empty data or mobile widths.
    Out of scope: Theme redesign.

  T6 - Add warning state
    Outcome: Usage above 80 percent is clearly indicated.
    Depends on: T5
    Acceptance criteria:
      - Warning appears above threshold.
      - Warning clears below threshold.
      - Threshold source is the one defined in T1.
    Verification: UI test or manual proof with threshold fixtures.
    Regression risk: Off-by-one or unit mismatch.
    Out of scope: Alerting/notifications.

  T7 - Persist history for reports
    Outcome: Bandwidth samples are stored for later reporting.
    Depends on: T1, T3
    Acceptance criteria:
      - Retention and storage key format are defined.
      - Samples can be written and read.
      - Storage failure behavior is explicit.
    Verification: Storage integration tests or focused service tests.
    Regression risk: Unbounded retention or cross-tenant leakage.
    Out of scope: Building reports.

Done gate:
  - Hero flow works end-to-end.
  - Required tests or manual proofs are recorded.
  - Auth/theme non-goals remain untouched.
```

## Folder Input Pattern

When the input is a folder of docs, aggregate markdown files in deterministic
path order and preserve source markers:

```text
# From: README.md
...
---
# From: features/auth.md
...
---
# From: api/endpoints.md
...
```

Then decompose by:

- feature docs into top-level tasks;
- architecture/infrastructure docs into foundation tasks;
- API docs into contract and implementation tasks under relevant features;
- cross-cutting concerns into their own tasks when they affect multiple features;
- dependencies across files into explicit `Depends on` entries.

## Mapping From PRD To Tasks

| PRD element | Task output |
|---|---|
| Product thesis | Milestone context and scope guard |
| Hero flow | Milestone acceptance criteria |
| Feature acceptance criteria | Task acceptance criteria |
| Decisions table | Task constraints and dependencies |
| Deferred roadmap | Out-of-scope or later milestone notes |
| Risks | Regression risk and verification requirements |
