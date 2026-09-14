# Gaia — The Nexus Generation

**A software AI-factory architecture for turning compute, models, data, automation, provenance, and secure delivery into repeatable products.**

> This repository publishes the software architecture and reusable control-plane concepts. Secrets, credentials, private customer data, encrypted enclave contents, and deployment infrastructure are intentionally excluded.

## Why this exists

AI factories are becoming strategic infrastructure. Europe is building a network of AI Factories and Antennas, and EuroHPC has launched a 2026 call for up to seven AI Gigafactories backed by EU and national funding and expected to unlock major private investment. Gaia is aimed at the complementary software layer: making compute and intelligence operationally useful, reproducible, governable, and monetizable.

## The Factory Loop

```text
INTENT
  ↓
PLAN → COMPUTE → BUILD → VERIFY → PACKAGE
  ↓                         ↓
DATA / MEMORY          PROVENANCE / POLICY
  ↓                         ↓
DELIVER ← ENTITLE ← PAYMENT ← CUSTOMER
  ↓
TELEMETRY → LEARN → IMPROVE → REPEAT
```

## Core layers

- **Factory** — orchestration of build, test, packaging, release, and service workflows.
- **Gaia** — runtime/control-plane layer for nodes, workloads, state, and reconciliation.
- **Nexus** — coordination boundary connecting tools, agents, data, and execution surfaces.
- **Memory Fabric** — durable project knowledge, artifacts, decisions, provenance, and operational state.
- **Secure Enclave** — isolated handling of sensitive material; public code never contains enclave contents or credentials.
- **Singularity layer** — the project’s unification boundary: one control model across local, cloud, edge, and agent execution. It is an architectural term here, not a claim of physical or scientific singularity.
- **Economic loop** — Stripe-backed checkout, entitlement, billing, retention, and revenue telemetry.
- **GitHub gate** — source control, review, CI, provenance, releases, and the auditable engineering frame.

## Revenue-first operating principle

The factory is not finished when the architecture is impressive. It is finished when a real customer can:

1. understand the value;
2. pay;
3. receive the product or service;
4. use it successfully;
5. renew or purchase again; and
6. generate measurable evidence that the factory improved.

The first commercial target is therefore a narrow, useful developer/security automation product built from the factory itself. Platform expansion follows demonstrated demand.

## 1-day hardening sprint

### P0 — Revenue path

- define one paid offer;
- create a deterministic build artifact;
- add installation/usage documentation;
- connect Stripe Checkout;
- implement payment → entitlement;
- record activation and retention events;
- test the complete purchase path in Stripe test mode.

### P1 — Production gate

- CI tests and linting;
- dependency and secret scanning;
- provenance metadata on production artifacts;
- reproducible build information;
- release checks;
- rollback procedure;
- public/private boundary audit.

### P2 — International readiness

- product classification and tax-category mapping;
- Stripe Tax assessment before enabling tax collection;
- customer country/address handling;
- VAT/GST/sales-tax registration tracking;
- privacy and data-retention documentation;
- export and regional deployment considerations.

### P3 — Scale

- subscriptions;
- customer portal;
- usage telemetry;
- team/enterprise access;
- regional compute adapters;
- workload scheduling;
- external AI/provider adapters;
- marketplace/partner distribution where justified by demand.

## Security boundary

Never commit:

- API keys or OAuth tokens;
- private certificates or signing keys;
- encrypted sparsebundle contents;
- customer secrets;
- payment credentials;
- private gateway addresses or credentials;
- generated `.pyc`, caches, local logs, or machine-specific state.

Sensitive infrastructure belongs behind authenticated gateways and secret managers. The public repository contains interfaces, schemas, documentation, tests, and reproducible build logic—not the secrets that make private infrastructure private.

## Status

**Architecture published. Productionization in progress.**

The next milestone is not more abstraction. It is a verified customer transaction flowing through the factory: **build → release → checkout → entitlement → activation → telemetry**.

## License

Licensing will be declared explicitly before the first external commercial distribution. Until then, treat the repository as an architectural publication rather than an implicit grant of commercial rights.
