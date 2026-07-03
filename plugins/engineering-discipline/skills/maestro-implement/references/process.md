# Implementation process

## 0. Intake

Restate the outcome. Classify the work as trivial, standard, or epic. Read project instructions, `docs/`, nearby code, tests, and recent git history before asking questions.

## 1. Investigate

Read the files that will change, their callers, tests, and documented contracts. Identify the smallest safe path. For bug fixes, find or create a failing reproduction before changing behavior when practical.

## 2. Plan

For standard work, give a concise approach and proceed. For epic or high-risk work, provide a dependency-ordered plan and wait for approval if required by project rules.

Define done as:

- observable behavior;
- tests or checks that prove it;
- docs updated;
- known exclusions named.

## 3. Build

Make focused changes. Prefer existing framework generators and conventions. Keep user-facing strings complete across supported locales. Avoid speculative abstractions.

## 4. Verify

Run the narrowest meaningful checks first, then broaden if risk warrants it. Capture real command output. For high-risk work, run `maestro-adversarial-verify` before delivery.

## 5. Deliver

Summarize:

- changed files and behavior;
- verification commands/results;
- risks and deploy/restart implications;
- leftovers or follow-up work.
