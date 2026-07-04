# Planning Question Bank

Use this reference when decomposing a PRD, feature, roadmap item, or folder of
docs into `taskmanager-lite` tasks. Ask only questions whose answers change task
ordering, acceptance criteria, or verification.

## General

| Question | Ask When |
|---|---|
| What deployment target must this support? | Deployment affects tasks or verification. |
| Is there an existing CI/CD pipeline? | Release or validation tasks depend on it. |
| What environments are needed? | Setup, config, or smoke tests are in scope. |
| What monitoring or observability is expected? | Runtime behavior or operations are in scope. |
| Are budget, hosting, or infrastructure limits relevant? | Architecture or dependency choices are open. |

## Laravel / PHP

| Question | Ask When |
|---|---|
| Which Laravel and PHP versions are targeted? | Version is not evident from the repo. |
| Queue driver preference? | Async work, retries, notifications, imports, or reports are in scope. |
| File storage driver? | Uploads, exports, documents, or media are in scope. |
| Mail driver? | Email or notifications are in scope. |
| Session driver? | Auth, carts, or multi-instance deployment is in scope. |
| Tenancy model? | Multi-tenant behavior is mentioned or implied. |

## Filament

| Question | Ask When |
|---|---|
| Which Filament major version is installed? | Version is unclear. |
| Single panel or multiple panels? | Admin/customer/support surfaces are planned. |
| Should resources use soft deletes? | CRUD resources and data recovery are relevant. |
| Are forms simple pages or wizard-style flows? | Creation/editing flows are complex. |

## API

| Question | Ask When |
|---|---|
| REST, GraphQL, tRPC, or project-standard API? | New public or internal API is planned. |
| API versioning strategy? | Public clients or long-lived integrations exist. |
| Authentication method? | API auth is in scope. |
| Rate limiting strategy? | Public or high-volume API is in scope. |
| API docs expectation? | External or cross-team API users exist. |

## Database

| Question | Ask When |
|---|---|
| Database engine? | Not evident from the repo or PRD. |
| Migration strategy? | Schema work is in scope. |
| Seeding/factory expectations? | Tests or demos need data. |
| Retention/soft-delete policy? | Deletion, audit, or compliance is relevant. |

## Auth And Authorization

| Question | Ask When |
|---|---|
| Auth approach? | Authentication is part of the feature. |
| Role/permission model? | Access control differs by actor. |
| MFA required or optional? | Security is a requirement. |
| Social/SSO providers? | External identity is mentioned. |

## Frontend / UX

| Question | Ask When |
|---|---|
| SPA, SSR, server-rendered, or framework-native UI? | UI implementation path is unclear. |
| Component library/design system? | New UI components are planned. |
| Responsive requirements? | UI surfaces are user-facing. |
| Accessibility target? | Public or compliance-sensitive UI exists. |
| Internationalization? | Multi-language users are in scope. |

## Task Decomposition Prompts

- What is the smallest user-visible vertical slice?
- Which foundation task unblocks the most downstream work?
- Which tasks can be reverted independently?
- Which acceptance criteria prove the hero flow?
- Which tests fail if the implementation is removed?
- Which tasks carry auth, money, data loss, or tenant-isolation risk?
- What is explicitly out of scope for this plan?
