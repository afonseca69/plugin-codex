---
name: filament-conventions
description: "Apply Laravel Filament panel conventions for resources, schemas, relation managers, navigation, auth, redirects, dashboard pages, and verification."
---

# Filament Conventions

Use this skill when editing a Laravel project that uses Filament. First verify the
installed Filament major version from `composer.lock`, `composer.json`, or vendor/docs in
the target project. Filament APIs vary by major version; apply version-specific rules only
when the project evidence supports them.

The upstream convention this port preserves is aimed at Filament v5 projects.

For Filament v5 examples, namespaces, auth/profile snippets, redirect patterns, and
verification reminders, use `references/filament-5-recipes.md` after confirming the target
project's installed Filament version.

## Process

1. **Confirm version and layout.** Read `composer.json`, `composer.lock`, existing
   `app/Filament` or package panel paths, and nearby resources/pages before editing.
2. **Follow project patterns.** Match existing panel providers, resource folders, policy
   checks, localization, tests, and route/auth conventions.
3. **Use generators for new surfaces.** Scaffold resources, pages, relation managers, and
   users through Artisan when the project provides those commands.
4. **Apply the rules below.** Keep form layout, navigation, actions, redirects, profile,
   auth, dashboard, and relation behavior consistent.
5. **Verify in the project.** Run focused tests or a manual panel smoke check and report
   exact evidence.

## Core rules

1. **Scaffold with Artisan when adding new Filament surfaces.** Prefer the project's
   existing generators and file layout over hand-rolled resource/page structure.
2. **Organize forms before fields.** Use `Section`, `Fieldset`, tabs, grids, or the
   project's established layout components before dropping in individual inputs. Avoid a
   flat bag of fields.
3. **Use version-correct namespaces.** For Filament v5, forms, schema layout, actions, and
   tables may live in different namespaces than older examples. Verify imports before
   editing.
4. **Group navigation intentionally.** Resources and pages should sit in meaningful
   navigation groups, preferably using existing enums/constants where the project has them.
5. **Provide relation managers for real relations.** Register relation managers on the
   resource and keep each manager responsible for its own form/table behavior.
6. **Keep destructive actions in the list/table flow.** Prefer delete actions on table
   rows and bulk action groups. Remove default edit-page delete actions when the product
   convention is "delete from list".
7. **Redirect create/edit saves deliberately.** If the product expects users to return to
   the index list after save, configure panel-wide redirects or override page redirect
   methods consistently.
8. **User menu needs profile/settings.** Register a profile or settings page where account
   management, password, and optional MFA controls live.
9. **Use native Filament auth when available.** Enable login, avoid public registration
   unless explicitly required, and use the framework-supported authenticator-app MFA flow
   when the installed version supports it.
10. **Own the dashboard.** Prefer a custom dashboard page with explicit widgets and column
    layout over an uncontrolled stock dashboard when product UX matters.

## Laravel guardrails

- Follow `laravel-conventions` first for tenancy, policies, factories, tests, localization,
  and `.env` safety.
- Do not create migrations or reset databases unless explicitly in scope.
- Do not patch a package through `vendor/`; edit the package source when the project uses
  symlinked local packages.
- Preserve existing panel/provider/resource organization.

## Verification checklist

- Resource form opens with grouped layout.
- Relation managers cover important Eloquent relations.
- Delete actions are in the expected table/list location.
- Create and edit redirects match product convention.
- Panel auth has login, profile/settings, optional MFA when required, and no unintended
  public registration.
- Dashboard registration does not duplicate the stock dashboard.
- Relevant Pest/PHPUnit tests or manual Filament smoke checks ran, with exact command or
  evidence reported.

## Output format

```text
Filament version evidence:
Files changed:
Rules applied:
Auth/profile/dashboard impact:
Tests or smoke checks:
Residual risks:
```
