---
name: maestro-deep-work
description: "Orchestrate broad, multi-place, uncertain work through planning, refute-first review, serial execution, synthesis, and verification."
---

# Maestro Deep Work

Use this skill when the task is too broad or uncertain to push through in one normal
implementation pass: large refactors, multi-module cleanup, migrations, cross-cutting
research, or work that must be decomposed before it is safe to edit.

## Route first

Before using the full deep-work loop, choose the smaller workflow when it fits:

- Use `maestro-deep-analysis` for a read-only audit, production-readiness review, or
  unknown subsystem investigation.
- Use `maestro-implement` for a defined feature, bug fix, or bounded refactor.
- Use `architect-design` or `architect-refine` when the main risk is an architecture,
  ownership, data model, or public-contract decision.
- Use this skill when the work is broad, multi-place, and still needs decomposition.

## Four stages

1. **Plan without editing.** Read `AGENTS.md`, `README.md`, relevant `docs/`, recent
   history, and the files likely to change. Decompose the work into subtasks with scope,
   dependencies, touched files, risk, and verification.
2. **Refute the plan.** Run a `maestro-adversarial-verify` pass on the plan. Look for
   hidden dependencies, shared files that would collide, missing verification, and a
   smaller subtraction path. Revise the plan before editing.
3. **Execute safely.** Run subtasks that touch the same files serially. Parallelize only
   read-only work or disjoint file changes when the environment supports it. Give each
   slice a concrete file/path scope and a verification command.
4. **Synthesize and verify.** Re-read the complete diff against the original goal, run
   the broadest relevant checks, update docs, and verify the result from real evidence
   rather than self-reported completion.

## Guardrails

- Do not start mutating files until the plan and refutation pass are coherent.
- Do not run destructive commands without explicit user approval.
- Keep commits atomic when the user asks for commits: one coherent slice per commit.
- Treat same-working-tree write conflicts as serial work.
- Record unknowns and residual risk instead of filling gaps with confident guesses.
- Do not use this workflow to smuggle in unrelated refactors.

## Output format

```text
Goal:
Route decision:
Plan:
  Slice:
    Scope:
    Dependencies:
    Files:
    Risk:
    Verification:
Refutation findings:
Execution notes:
Verification evidence:
Docs updated:
Residual risk / follow-up:
```
