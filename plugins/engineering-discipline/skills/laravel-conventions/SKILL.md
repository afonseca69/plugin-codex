---
name: laravel-conventions
description: Laravel project conventions for Codex.
---

# Laravel Conventions

Use this skill when the target repository is Laravel.

## Rules

- Follow existing Laravel, Filament, Eloquent, factory, policy, and test style.
- Keep tenant boundaries fail-closed.
- Use existing authorization patterns.
- Do not create migrations or run database reset commands unless the project explicitly allows it.
- Do not read or print `.env` or secrets.
- Keep user-facing strings complete across supported locales.

## Verification

Run the relevant Pest or PHPUnit tests and report exact commands/results. If tests cannot run, explain why.
