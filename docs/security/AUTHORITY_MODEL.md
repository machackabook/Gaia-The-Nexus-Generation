# Gaia Authority Model

## Identities

### machackabook — source/root recovery authority
Purpose: repository ownership, destructive-but-recoverable maintenance, source-of-truth recovery, protected-branch administration.

### Azazeleous / ARCHITECT_ROOT_01 — defensive operations authority
Purpose: public-facing Gaia security identity, authorized internal defensive testing, CTF/lab exercises, incident response, CVE validation, configuration hardening and evidence collection.

Azazel is not an unrestricted bypass identity. High-impact operations require an explicit target scope, an authorization record, evidence capture and a rollback path.

### NexusGaia — runtime/observability authority
Purpose: telemetry, dashboards, ADAM interfaces, repository state, integrity observation and Sentinel forwarding. No implicit privilege elevation.

## Separation-of-power invariants

- Public automation does not carry root credentials.
- Production/default branch does not accept force pushes.
- Destructive operations are never the default path.
- Network/security tests are allowlist-scoped to owned/authorized targets.
- Every privileged change emits a TDOC/ledger event.
- Secrets remain in platform secret stores, never source files.
