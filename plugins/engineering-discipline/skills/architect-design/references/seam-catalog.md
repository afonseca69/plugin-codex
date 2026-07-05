# Architecture Seam Catalog

A seam is a boundary defined now so a future extraction is a swap instead of a
rewrite. The cheap-now form is what you build today. The extract-later form is
documented as a trigger-backed path, not built speculatively.

Record selected seams in `docs/architecture/boundaries.md` and in the relevant
ADR trigger-to-revisit.

## 1. Database

| Field | Guidance |
|---|---|
| Cheap-now form | One database instance and one schema. |
| Extract-later form | Managed database service, split datastore, or sharded/isolated store. |
| Boundary now | Data access through repositories/query services; app code depends on repository contracts, not driver details. |
| Trigger | DB host saturates, maintenance windows threaten uptime, a bounded context starves others, or compliance/residency requires isolation. |

## 2. Background Jobs

| Field | Guidance |
|---|---|
| Cheap-now form | Synchronous work, in-process deferral, or a simple framework job table if already available. |
| Extract-later form | Dedicated queue/broker and independent worker process. |
| Boundary now | Dispatch through a job interface with serializable payloads and idempotent handlers. |
| Trigger | Request latency is dominated by deferrable work, tasks time out, retry/backoff is required, or job volume starves web work. |

## 3. Cache

| Field | Guidance |
|---|---|
| Cheap-now form | No cache, or in-process cache for a measured local hot path. |
| Extract-later form | Shared Redis/Memcached-style cache with explicit TTL and invalidation. |
| Boundary now | Reads go through a cache/read-through interface owned near the data layer. |
| Trigger | Repeated expensive reads dominate load, multiple app instances need shared cache, or measured DB pressure requires it. |

## 4. Module To Service

| Field | Guidance |
|---|---|
| Cheap-now form | Module/package inside the monolith with a public facade. |
| Extract-later form | Independently deployed service with its own datastore and network contract. |
| Boundary now | Other modules call only the facade; no shared mutable state or cross-module table reach-through. |
| Trigger | Independent team ownership, deploy cadence, scaling profile, compliance boundary, or blast-radius isolation. |

## 5. Authentication And Identity

| Field | Guidance |
|---|---|
| Cheap-now form | App-local sessions or signed tokens using a vetted framework/library. |
| Extract-later form | Managed IdP, OAuth/OIDC/SSO, or shared internal identity service. |
| Boundary now | Call sites depend on current-user/identity and authorization abstractions, not token/session internals. |
| Trigger | Multiple apps need shared identity, enterprise SSO/MFA is required, centralized revocation is needed, or compliance requires it. |

## 6. File Storage

| Field | Guidance |
|---|---|
| Cheap-now form | Local disk or attached storage through the framework filesystem. |
| Extract-later form | Object storage with CDN and generated URLs. |
| Boundary now | All file I/O goes through a storage interface; app stores keys/handles, not absolute paths. |
| Trigger | Multiple app instances need shared files, disk durability is insufficient, file volume grows beyond one host, or CDN delivery is needed. |

## 7. Search

| Field | Guidance |
|---|---|
| Cheap-now form | Primary database search, built-in full-text index, or simple filters. |
| Extract-later form | Dedicated search engine with indexing/sync. |
| Boundary now | Search goes through `Search.query(criteria)`-style contract returning domain identifiers. |
| Trigger | DB search is too slow or load-heavy, relevance/fuzzy/faceted search is required, or search volume competes with transactions. |

## 8. Notifications

| Field | Guidance |
|---|---|
| Cheap-now form | Direct provider/SMTP send, preferably through the job seam if slow. |
| Extract-later form | Notification service with channels, templates, preferences, delivery tracking, and provider failover. |
| Boundary now | Send through a notifier interface; call sites do not embed provider APIs. |
| Trigger | Second channel/provider, preferences, batching, delivery tracking, throttling, or deliverability operations. |

## 9. API Edge

| Field | Guidance |
|---|---|
| Cheap-now form | Application routes and middleware own auth, rate limits, and routing. |
| Extract-later form | Gateway/reverse proxy/edge service in front of multiple services. |
| Boundary now | Stable external API contract, versioning strategy, and composable middleware. |
| Trigger | Multiple services need one front door, policy must move to the edge, or clients need topology-independent routing. |

## 10. Read Replicas

| Field | Guidance |
|---|---|
| Cheap-now form | Single primary handles reads and writes. |
| Extract-later form | Read/write split with one or more replicas. |
| Boundary now | Repository/data-access methods distinguish reads from writes where eventual consistency is acceptable. |
| Trigger | Read load saturates primary while write load has headroom, reporting reads contend with transactions, or read locality is required. |

## Selection Rule

Do not add a seam because it appears in this catalog. Add it only when the
elicited context makes the future plausible and the boundary is cheaper now than
later.
