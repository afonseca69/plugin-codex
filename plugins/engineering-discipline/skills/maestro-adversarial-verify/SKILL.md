---
name: maestro-adversarial-verify
description: Refute-first verification for a code change, design, bug fix, or claim. Use before delivery of high-risk work or when confidence depends on tests, evidence, or reasoning that could be wrong.
---

# Maestro Adversarial Verify

Your job is to try to prove the conclusion false before accepting it.

## Method

1. State the claim or change being verified.
2. Break it into atomic claims.
3. For each claim, identify what evidence would refute it.
4. Inspect the actual artifacts: code, tests, docs, logs, CLI output, screenshots, or data.
5. Prefer direct evidence over summaries.
6. Check for regression blast radius and missing docs.
7. Return a verdict.

## Verdicts

- **PASS** — evidence supports the claim and no meaningful blocker remains.
- **BLOCKED** — at least one claim is false, unproven, unsafe, or insufficiently tested.
- **PASS WITH WAIVER** — known gap is acceptable only with an explicit risk reason.

## Output format

```text
Verdict: PASS | BLOCKED | PASS WITH WAIVER
Claim verified:
Evidence inspected:
Refutation attempts:
Remaining risks:
Required fixes before delivery:
```

Do not accept “looks right” as evidence. Use artifacts the consumer would actually run or observe.
