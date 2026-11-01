# TDOC-10428 — GAIA Native Hosted Agent Foundation
**v0.1.0-draft | Epoch 2026-10-31 | FOUNDATION PREPARED — NOT CERTIFIED**

This is an incremental architecture proposal for a hosted assistant with bounded orchestration, least-privilege tools, supervised learning, workload-aware scheduling, browser automation and calendar integration. It is not proof of build, tests, hosting, calendar connection, or production readiness.

## Topology
Client (PWA/mobile/desktop) → authenticated OIDC gateway → identity + deny-by-default capability policy → bounded orchestrator/job queue → planner, typed tool broker, isolated browser, reviewed memory, scheduler/calendar adapter → provenance journal/checkpoints → durable database/object storage/backups.

## Browser & agent safety
- Read-only, per-session isolated browser and domain allowlist by default.
- Page content is untrusted data; never policy or authorization.
- Block localhost/private-network destinations by default; quarantine downloads.
- No payment/purchase, account security changes, publishing, destructive actions, or device control without distinct grants and explicit human confirmation.
- Server-side secret injection only; timeouts, quotas, cancellation, idempotency, redacted audit.
- “Self-learning” is reviewed feedback/outcome ingestion → minimization/redaction → quarantine → offline evaluation → versioned proposal → human acceptance → staged rollout/rollback. No self-granted privileges, tool registration, policy edits, or unreviewed generated code execution.

## Formal integrity model
“Mathematica” denotes the formal computation/verification layer; no installed Wolfram runtime is claimed.
`H_art = SHA256("GAIA:ARTIFACT:v1\\0" || C(artifact))`
`H_i = SHA256("GAIA:EVENT:v1\\0" || H_(i-1) || C(event_i))`
`H_lineage = SHA256("GAIA:LINEAGE:v1\\0" || C({tdoc,parents,artifact_hash,toolchain,created_at}))`
`H_seed = SHA256("GAIA:TDOC-SEED:v1\\0" || UTF8("TDOC-10428|GAIA-NATIVE-AGENT|2026-10-31"))`
Seed digest: `65d157fc7963e331c726e9e6957a362052847aefcef26baf675b9dec65a31971`.
Seed is a public lineage namespace—not a secret, entropy source, signature, authorship proof or trust root. Use a tested canonical JSON standard (e.g. RFC 8785) for cross-language signatures.

## Invariants
1. Canonical hash determinism and explicit parent lineage/genesis.
2. Execute only with authenticated identity, scoped capability, allowed target and required approval.
3. Validate authoritative lock owner/fence within the same transaction as commit.
4. Commit payload, receipt, sequence and checkpoint atomically or through tested WAL recovery.
5. Durable replay/idempotency protection.
6. Scheduler obeys dependencies, time windows, timezone and resource budgets.
7. Authorized operator pause/cancel/revoke/rollback.
8. Provenance labels sources, tool outcomes, confidence; model inference distinguished.
9. Tool/page content cannot change policy.
10. No silent calendar edits; preview and approval before writes.

## Year planner
Use a rolling 12-month backlog; tasks carry owner, priority, estimated duration/uncertainty, dependencies, due/window, recurrence, compute class, permission scopes, review gate and cancellation policy. Bucket load = sum(expected task minutes); utilization = load / capacity. Initial adjustable policy: <=70% planned; 70–85% warning; >85% re-scope/defer. These are planning defaults, not measured system capacity.
M1 inventory/threat model; M2 identity/capability broker; M3 job lifecycle/idempotency; M4 read-only browser security; M5 memory quarantine/promote; M6 calendar free/busy + estimator; M7 approved calendar-write/reconcile; M8 recurrence/dependency/DST/overload; M9 observability and restore; M10 paired-device scoped grants; M11 independent abuse/security review; M12 limited-beta decision. This is a backlog—not created calendar appointments.
Scheduler reads approved backlog and free/busy, builds a conflict-explained proposal, then waits for explicit approval before provider writes. Reconcile drift without moving commitments silently.

## Annotation/extensibility
Annotations are typed metadata, not authority. Register stable ID/version, purpose, input/output schema, required capability, resource scope, side-effect class (read/write/destructive), approval, timeout, retries/idempotency, data class/retention, provenance, errors, test/health, owner and deprecation. Reject unknown annotations/capabilities and privilege escalation. Admin approval is required for new tools; model/page content cannot register tools.

## Cloud provider boundary
No Insforge connector action/API was available in this work session; no provisioning or deployment occurred. Provider mapping must verify current auth, database, functions, object storage, secret store, migrations and deployment APIs. Separate dev/preview/staging/prod; enforce tenant/row authorization server-side, rate limits, schema checks, request IDs, secrets external to source, tested migration/restore, health checks, graceful shutdown and rollback.

## Gates
G0 inventory+hash; G1 clean compile/lint; G2 unit hash/chain/auth; G3 transaction/fence/idempotency/recovery; G4 browser scope/injection/download tests; G5 scheduler cycles/DST/recurrence/load; G6 privacy/secret scan/log redaction; G7 staging migration/restore/rollback; G8 explicit limited beta. No gate passes without machine-readable retained evidence.

## Carried-forward receipt blockers
Prior v2.1.1 review noted non-atomic cross-process lock acquisition, incomplete authoritative fencing, unproven atomic multi-record persistence, incomplete receipt metadata authentication, caller-controlled recovery boolean, test-isolation/fencing-test defects, a `valleys` syntax typo and incomplete WebSocket lifecycle controls. This TDOC does not assert these are fixed.

## Acceptance tests
Canonical equivalent objects hash equally; mutations alter digest; parent/event edits fail verification; replay is resolved/rejected; stale fences cannot commit; injected crashes recover; no calendar write before approval; hostile web content cannot grant tools/reveal secrets; baseline browser cannot access private destinations; scheduler detects cycles/timezone overload; revocation stops work; each test has private temp state.

**Disposition:** FOUNDATION DRAFT / VERIFICATION PENDING. Compile, tests, deploy, calendar, browser control and production readiness unverified.
