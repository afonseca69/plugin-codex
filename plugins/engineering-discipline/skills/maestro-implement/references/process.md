# Implementation Process

Use this reference when `maestro-implement` needs more structure than the
summary in `SKILL.md`. Scale the ceremony to the risk.

## 0. Intake

Goal: understand the requested outcome before touching files.

1. Restate the outcome in one sentence.
2. Classify the size:
   - trivial: one obvious reversible change;
   - standard: a feature slice, bugfix, or refactor with a few decisions;
   - epic: multi-subsystem, architectural, or broad modernization work.
3. Read before asking:
   - `AGENTS.md`, `README.md`, and relevant `docs/`;
   - nearby code, tests, manifests, and documented contracts;
   - recent git history when it helps explain current direction.
4. Ask only decision-changing questions. Do not ask for facts the repo or the
   request already answers.

## 1. Investigate

Goal: know what you will change and what depends on it.

- Read full files, not only the target function or paragraph.
- Read callers, tests, docs, and registration/wiring.
- Identify local conventions: naming, errors, validation, tests, i18n, comments.
- Check whether `docs/deep-analysis/` records known flaws in the touched area.
- Map blast radius: schema, public API, auth/tenancy, money, data deletion,
  user-facing strings, runtime/restart assumptions, docs.
- For bugs, reproduce or characterize the failure before changing behavior when
  practical.

Security and edge reflex:

- Path input: validate against an allowlist or scoped root.
- External/user input: fail closed where auth, tenancy, or money is involved.
- Retryable work: consider idempotency.
- File/output reads: avoid unbounded reads where the code path can grow.
- Secrets: do not print or commit them.

## 2. Plan

Goal: choose a concrete path that can be disagreed with.

- Prefer the smallest change that is actually correct, not merely the smallest
  diff.
- Match repository idioms and framework conventions.
- Use generators when the stack provides them.
- Keep adjacent refactors out unless they are required for correctness.
- For standard work, keep an ordered checklist and proceed.
- For epic/high-risk work, write a dependency-ordered plan and get approval if
  project rules require it.

Define done as:

- observable behavior or content change;
- verification that would fail if the change were reverted;
- docs updated where behavior, commands, or constraints changed;
- exclusions explicitly named.

## 3. Build

Goal: make focused changes in dependency order.

- Work foundation -> domain/service -> interface/UI -> docs.
- Preserve existing public contracts unless changing them is the requested work.
- Keep user-facing strings complete across supported locales.
- Add comments only where they reduce real parsing cost.
- Do not create migrations, background jobs, integrations, or tooling outside
  the requested scope.
- Avoid speculative abstractions and future engine work.

## 4. Verify

Goal: produce fresh evidence before making claims.

- Run the narrowest meaningful checks first.
- Broaden checks when blast radius warrants it.
- For tests, prefer checks that fail if the feature/fix is removed.
- For docs/template-only work, run structural validation, link/path checks,
  frontmatter/JSON syntax checks, and diff review.
- For UI, verify in a browser when tooling exists.
- For high-risk changes or non-obvious conclusions, use
  `maestro-adversarial-verify` before delivery.
- Report skipped checks explicitly with the reason.

Do not rely on hooks as proof. Hooks may remind or warn; completion claims need
fresh command output or direct evidence from this run.

## 5. Deliver

Summarize:

- changed files and behavior;
- verification commands and results;
- docs updated;
- risks, deploy/restart/migration implications;
- deliberate exclusions and remaining gaps.

Use a conventional commit when committing locally, scoped to the actual change.
