# GAIA Sync Fabric v1.0.0

**Parent:** GAIA / NEXUS Quintessential Quine Mesh v4.1  
**Canonical repository:** Gaia — The Nexus Generation  
**Runtime:** Python 3.11+ / SQLite WAL / HTTPS provider feeds / signed node API  
**Status:** source committed to integration branch; provider credentials and node enrollment are not configured

## 1. Why this implementation reuses the troves

The archive review found several existing pieces with distinct responsibilities:

| Existing artifact | Reusable role | Boundary |
|---|---|---|
| CRYPTIC Device Mesh v6.1.0 (`cryptic_mesh.py`, install script, job contract) | Per-device inboxes, immutable job manifests, local approval, receipts, per-device TDOC chain, additive rclone transport | It is a device job transport/executor, not a provider ingestion engine. Its remote transport must be configured on each real device. |
| GAIA Memory portal v1.2 snapshot | Owner vault, scoped node enrollment, heartbeat, selected-memory exchange, digest receipts | It explicitly does not scan providers or grant ChatGPT/Gemini/Drive/OneDrive sessions. |
| GAIA Host / Universal Runtime topology | Shared event bus, identity authority, immutable ledger, orchestrator, telemetry, Android/Penguin/desktop roles | Architectural specification; not proof that the full runtime is deployed. |
| GAIA Receipt Protocol v1.0.0 record | ACK → VERIFY → COMMIT, HMAC authenticity, nonce/sequence replay protection, atomic commit, ledger verification | Its recorded 16-test result is local verification; remote delivery was not verified in the cited project note. |
| TDOC-0003 Cloud Hybrid Sync Daemon | Historical cloud mirror concept | Not reused as-is: it contains `rsync --delete` and its background launch path needs correction before use. |
| Memory Fabric Kronosphere | Three.js visualization language | Visual prototype only; not a durable sync service. |
| Nexus Spine | On-demand HTTP/WebSocket integration pattern | Its page contains endpoint placeholders and should not be treated as an active backend. |

The fabric combines these roles without replacing the device mesh, Memory Bridge, or canonical source repository.

## 2. Runtime responsibilities

The fabric provides five services in one local-first process:

1. **Provider event ingestion:** generic HTTPS JSON-feed adapter and signed webhook endpoint.
2. **Durable synchronization:** cursor leases, deduplication, atomic event-plus-cursor commit, retry backoff.
3. **Node registry:** signed heartbeats, incarnation IDs, monotonic sequence numbers, measured capabilities, stale-node rejection.
4. **Cooperative task leases:** allowlisted task envelopes, capability matching, expiry, retry exhaustion, signed receipts.
5. **Evidence reconciliation:** imports CRYPTIC Mesh v6.1 receipt files and private TDOC JSONL into the append-only event ledger.

SQLite is the initial local durable store. The service exposes a read-only dashboard snapshot and health endpoint. It does not silently deploy itself to Cloudflare or claim to be a D1/R2 service.

## 3. Data flow

```text
GitHub / Cloudflare / alphaXiv / Manus / authorized APIs
                         |
               provider-specific adapter
                         |
              HTTPS feed / signed webhook
                         |
             normalize + redact + validate
                         |
              dedupe by provider/source ID
                         |
            SQLite event + cursor transaction
                         |
             append-only hash audit ledger
                         |
       +-----------------+------------------+
       |                 |                  |
   Memory Bridge     node scheduler      UI snapshot
   provenance        task leases         read model
       |                 |
       +-------- CRYPTIC Device Mesh -----+
                  inbox / receipts / TDOC
```

The initial provider adapter is deliberately generic. A real GitHub, Cloudflare, alphaXiv, or Manus adapter must map that provider's authenticated API/webhook format to the normalized event contract. No provider-specific OAuth client or API secret is included in this repository.

## 4. Event contract

Normalized events contain:
- provider ID and stable source event ID
- event type and source occurrence time
- ingestion time
- canonical JSON payload and SHA-256 digest
- provenance/transport metadata

Secrets and credential-like fields are redacted before persistence. Duplicate provider/source IDs are ignored. A page's events and next cursor are committed in one SQLite transaction; a failed page does not advance the cursor.

## 5. Background sync

A provider configuration is opt-in per source. The example shape is:

```json
{
  "providers": [
    {
      "id": "provider-id",
      "enabled": false,
      "endpoint": "https://your-authorized-api.example/v1/events",
      "token_env": "GAIA_SYNC_PROVIDER_TOKEN",
      "page_size": 100
    }
  ]
}
```

The endpoint must return:

```json
{
  "items": [
    {
      "id": "stable-source-event-id",
      "type": "change",
      "occurred_at": "2026-11-19T12:00:00Z",
      "data": {}
    }
  ],
  "next_cursor": "opaque-provider-cursor"
}
```

The adapter uses HTTPS only, reads credentials from environment variables, and never prints token values. A missing credential or invalid page leaves the cursor unchanged and places the provider into bounded backoff.

## 6. Node assistance and execution boundary

Nodes authenticate with per-node HMAC keys configured as environment secrets. Requests bind timestamp, nonce, and exact body bytes. The server rejects stale timestamps, duplicate nonces, stale heartbeat sequences, and task receipts from expired or mismatched leases.

Task kinds are restricted to:
- `inventory`
- `diagnostic`
- `artifact_verify`
- `checkpoint_restore_plan`

The fabric does not accept arbitrary shell commands. A node must have a fresh heartbeat (180-second freshness window) and satisfy the task's measured capability requirements before it receives a lease. The executor is still responsible for its own local policy and sandbox. A helper can return a verified artifact/checkpoint or a diagnostic result without taking over the recipient's identity or credentials.

## 7. HTTP endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/healthz` | Minimal process health |
| GET | `/v1/snapshot` | Providers, nodes, task counts, event count, audit head |
| POST | `/v1/webhooks/{provider}` | HMAC-authenticated event delivery |
| POST | `/v1/nodes/heartbeat` | HMAC-authenticated capability heartbeat |
| POST | `/v1/tasks` | Owner-authorized task creation |
| POST | `/v1/tasks/lease` | Node-authenticated task lease |
| POST | `/v1/tasks/{id}/receipt` | Node-authenticated result receipt |

The server binds to loopback by default. A non-loopback bind is refused unless an explicit private-bind override is set; production exposure must sit behind an authenticated TLS gateway. Do not expose debug ports or unauthenticated endpoints.

## 8. Commands

```bash
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" init
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" status
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" verify
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" ingest-mesh
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" sync-once --config providers.json
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" sync-loop --config providers.json --interval 60
python3 src/gaia_sync_fabric.py --db "$HOME/Æ/sync-fabric/fabric.sqlite3" serve --host 127.0.0.1 --port 8787
```

Run the sync loop under a service manager on a host that remains awake. Do not assume Android will keep a background process alive indefinitely; Android battery policy and Termux:Boot configuration must be checked on the device.

## 9. Current readiness

- Source and unit-test files are committed to the existing integration branch.
- CI workflow is included; a successful GitHub Actions run has not yet been observed.
- Provider adapters are generic; provider-specific app registration, scopes, tokens, and webhooks remain unconfigured.
- Node HMAC keys are not provisioned; no HP/Penguin/Termux node has been enrolled into this new service.
- The existing Memory Bridge enrollment service remains a separate service; no API contract has been assumed between it and this fabric.
- Cloudflare Worker/D1/R2 deployment, public dashboard connection, and backup replication are not performed by this commit.
- No production health or cross-device communication is claimed.

## 10. Verification gates

1. Python compile and unit tests pass in CI.
2. Provider feed cursor restart, duplicate delivery, invalid schema, and backoff tests pass.
3. HMAC heartbeat/webhook signature and nonce replay tests pass.
4. Node lease freshness, capability matching, expiry, and receipt verification tests pass.
5. CRYPTIC Mesh receipt/TDOC import is idempotent.
6. End-to-end three-node test proves HP, Penguin, and Samsung are distinct identities.
7. R2 checkpoint upload/read-back/restore digest test passes.
8. Adaptive website reads only the fabric snapshot and labels stale/unknown states honestly.

---

The Architect / Nexus / Cryptic News LLC / Project: The Nexus Generation: GaiaSSoul / SERIES: The Nexus of Gaia / ID: 137451921129154222|040592|433855274
