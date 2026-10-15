# Gaia System Integration Pipeline v2

## Purpose

Unify repository discovery, instance cataloging, Sentinel hardening, ADAM memory intake, Termux connection readiness, bidirectional node messaging, and Gaia reconciliation behind one auditable workflow.

## Canonical flow

```text
DISCOVER
  -> CATALOG
  -> CLASSIFY
  -> QUARANTINE
  -> PROVENANCE
  -> SENTINEL SCAN
  -> ADAM INGEST
  -> POLICY CHECK
  -> GRAPH / INSTANCE REGISTRY
  -> PROPOSE
  -> VERIFY
  -> PROMOTE
  -> LEDGER
  -> SYNC
  -> RECONCILE
  -> REPORT
```

No discovery result is silently promoted to canonical state.

## System planes

### 1. Repository plane

Sources currently identified include:

- `machackabook/Gaia-The-Nexus-Generation` — public Gaia publication/control-plane surface.
- `machackabook/Nexus_Core` — private core implementation boundary.
- `machackabook/NEXUS-SENTINEL-LEDGER` — defensive ledger and Sentinel material.
- `machackabook/ENCLAVE-ADAM-REUNITED` — ADAM-oriented memory/profile reconstruction material.
- `machackabook/nexus-repo-sync` — repository synchronization and convergence documentation.
- `machackabook/nexus-repo-sync` also contains an engram/convergence document tying the Enclave Protocol, ADAM/GAIA semantic layer, Memory Fabric, provenance, and Gaia runtime together.
- `machackabook/termux-failsafe` — Termux recovery surface.
- `machackabook/lilith-termux` — private Termux environment surface.

The catalog is descriptive; it does not imply that every repository should be merged into one codebase.

### 2. Instance catalog

Each discovered node or service receives an instance record:

```json
{
  "instance_id": "stable-id",
  "class": "android|linux|windows|cloud|agent|repository|service",
  "role": "controller|builder|gateway|memory|sentinel|worker|observer",
  "capabilities": [],
  "endpoint": null,
  "transport": "ssh|https|websocket|local",
  "state": "DISCOVERED",
  "provenance": {},
  "last_seen": null
}
```

Secrets, tokens, private addresses, and private keys are never stored in the catalog.

### 3. Sentinel plane

The Sentinel is the defensive verification layer. The repository implementation already uses append-only ledger, manifests, quarantine, locking, and synchronization concepts. The integration pipeline should consume those concepts rather than duplicate them.

Required checks:

- repository identity and expected remote;
- clean/known working tree state;
- dependency and secret scan;
- manifest/hash validation;
- policy violations;
- unexpected endpoint or credential material;
- provenance completeness;
- ledger continuity.

A failed check produces a quarantine record and blocks promotion.

### 4. ADAM Memory Fabric plane

ADAM is an external canonical memory architecture, not ChatGPT Memory. Intake follows:

```text
QUARANTINE -> PROVENANCE -> GRAPH -> PROMOTION -> LEDGER
```

The ADAM adapter may classify, correlate, hash, and propose records. It must not silently convert `DISCOVERED` into `CANONICAL`.

### 5. Termux connection plane

Termux is treated as a node awaiting authenticated connection, not as the canonical controller by itself.

Connection lifecycle:

```text
AWAITING
  -> HANDSHAKE
  -> AUTHENTICATED
  -> ATTESTED
  -> CAPABILITY-SCOPED
  -> ONLINE
  -> HEARTBEAT
  -> DRAINING/OFFLINE
```

The existing Gemini CLI setup can provide a local command surface and self-healing part. Network access should be mediated by the authenticated Gaia/Nexus gateway rather than by embedding credentials in shell files.

### 6. Bidirectional transport

The node protocol is symmetric at the message layer:

```text
Gaia Controller <-> Nexus Gateway <-> Node
```

Messages contain:

- protocol version;
- message ID;
- correlation ID;
- sender instance;
- receiver instance;
- capability requested;
- timestamp;
- nonce;
- payload hash;
- acknowledgement state.

Commands are idempotent where practical. Replay protection and authorization are mandatory.

### 7. Gaia runtime plane

The Gaia Runtime remains decomposed into identity, ledger, event bus, geocore, anahat, chronosphere, renderer, orchestrator, workspace, mesh, telemetry, and mobile/controller modules.

The Android-first controller model is preserved: phone/controller -> Gaia control plane -> event bus -> connected nodes. The controller does not bypass the policy or Sentinel planes.

## Workflow state machine

```text
DISCOVERED
   |
   v
CATALOGED
   |
   v
QUARANTINED --[reject]--> BLOCKED
   |
   v
VERIFIED
   |
   v
PROPOSED
   |
   +--[policy fail]--> QUARANTINED
   |
   v
PROMOTED
   |
   v
LEDGERED
   |
   v
SYNCED
   |
   v
RECONCILED
```

## Safety boundaries

- Public Gaia repositories contain interfaces, schemas, tests, and orchestration logic.
- Private Enclave contents, credentials, signing keys, customer secrets, and encrypted sparsebundle data remain outside the public repository.
- ADAM and Sentinel may propose state transitions but promotion is policy-controlled.
- AI agents receive scoped capabilities, never root authority.
- Destructive or sovereignty-changing operations require explicit human authorization outside the automated pipeline.

## Operational objective

The pipeline is complete when a newly discovered repository or node can move through the same deterministic path:

`discover -> catalog -> sentinel -> ADAM -> policy -> verify -> ledger -> sync -> reconcile`.

This makes the environment extensible without turning every new integration into bespoke shell-by-shell work.
