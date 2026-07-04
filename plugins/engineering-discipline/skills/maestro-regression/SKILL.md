---
name: maestro-regression
description: "Prove a change did not break existing behavior by combining suite evidence, blast-radius review, coverage honesty, and a structured verdict."
---

# Maestro Regression

Use this skill before marking a meaningful change complete, especially when the diff
touches shared behavior, public contracts, data ownership, authorization, billing,
queues, jobs, APIs, or documented architecture.

The goal is not to prove the new work exists. The goal is to try to prove the change
broke something that already worked, and report the evidence honestly.

## Process

1. **Identify the change under test.** Inspect `git diff`, staged changes, the commit
   range, or the named task/PRD. If there is no diff, say so and emit a trivial verdict.
2. **Run the existing suite.** Discover the project test command from docs, config, or
   conventions. Run it against current source, not stale build artifacts. For Python,
   prefer `PYTHONDONTWRITEBYTECODE=1` or a clean cache strategy when cache freshness
   matters. Any relevant suite failure is a regression signal.
3. **Probe blast radius.** Read `docs/architecture/`, ADRs, interfaces, callers, and
   tests touched by the diff. Ask what depends on the changed symbols, tables, routes,
   jobs, or contracts. For high-risk changes, use `maestro-adversarial-verify`.
4. **Report coverage honestly.** Name changed areas with no test or smoke coverage as
   `unverified-risk`. For risky untested behavior, recommend characterization tests that
   pin current behavior before further change.
5. **Emit a verdict.** Fail on suite failure or a violated documented contract. Pass only
   when the suite/probe evidence supports it. Never invent a pass because no test command
   was found.

## Characterization guidance

When changing risky untested code, first capture current behavior through a native project
test: function output, CLI output and exit code, HTTP response, serialized file, or other
observable boundary. The test is a correctness net only after it passes against the
unchanged behavior and then runs after the change.

## Optional documentation breadcrumb

For a confirmed regression or residual risk worth remembering, append a concise entry to
`docs/.scribe/capture.log` when that file exists. Keep it advisory; do not create a new
storage engine or gate.

## Verdict JSON

```json
{
  "status": "pass | fail",
  "suite": {
    "ran": true,
    "passed": 0,
    "failed": 0,
    "output_ref": "command and short result"
  },
  "blast_radius": [
    {
      "contract": "docs/architecture/... or caller group",
      "risk": "violated | at-risk | clear",
      "evidence": "path:line, command output, or reasoning anchored to artifacts"
    }
  ],
  "coverage": {
    "changed_untested": ["path:symbol"],
    "characterization_candidates": ["path:symbol"]
  },
  "verdict_reasoning": "One paragraph naming the worst remaining finding."
}
```
