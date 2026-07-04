# Default Stack Profile

This is a reusable default profile for greenfield SaaS PRDs when the user has
not specified a stack. It is inherited from the upstream PRD Builder reference
material and adapted for Codex.

Do not treat version numbers or package maintenance as permanently true. Before
committing to a dependency or version in a PRD, verify current official docs,
release history, license, and security posture, then record the date and source
in the PRD dependency table.

## Default Shape

| Concern | Default |
|---|---|
| Backend framework | Laravel |
| Admin/UI | Filament |
| Language | Current supported PHP for the chosen Laravel version |
| Database | PostgreSQL |
| File storage | Laravel filesystem with S3-compatible driver |
| Tests | Pest/PHPUnit plus browser tests for critical flows when available |
| Machine-to-machine API | Laravel Sanctum or project-standard token auth |

## Hard Rules To Offer

- Web authentication should be owned by Filament panels when Filament is the UI
  surface.
- Machine-to-machine APIs should be separate from Filament web auth.
- Prefer first-party or framework-native capabilities over community plugins.
- Every third-party package needs a dependency decision: package, function,
  license, maintenance evidence, and adopt/avoid/review choice.

## SaaS Conventions To Offer

Use these as recommended defaults only when the product is actually a SaaS.

- One tenant per subdomain when subdomain tenancy serves the product.
- Default to a single database with `tenant_id` and fail-closed tenant scoping
  unless there is a real isolation, residency, or portability requirement.
- A global user identity may belong to multiple tenants.
- No public self-registration unless explicitly required.
- Controlled provisioning by a superadmin or tenant owner.
- Minimal launch roles: superadmin, owner, member.
- Keep at least one owner per tenant.
- Audit sensitive actions.
- Native Filament profile/settings and MFA when supported by the installed
  Filament version.
- Payments and subscriptions are out of scope unless the user explicitly asks.

## Decision Table Row

Record the stack choice in the PRD:

| Decision | Choice | Owner | Rationale | Date |
|---|---|---|---|---|
| Tech stack | Default Laravel/Filament SaaS profile, or custom stack | `<owner>` | `<why this serves the hero flow>` | `YYYY-MM-DD` |
