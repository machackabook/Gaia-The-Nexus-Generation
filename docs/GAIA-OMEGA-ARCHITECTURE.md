# GAIA Ω — Polyglot Quine Shell integration contract

Status: INTEGRATION / NOT PRODUCTION VERIFIED.

## Three cooperating engines
- Crypto: standardized ML-KEM-768 or ML-KEM-1024 using a maintained provider, independently encapsulated secrets, domain-separated HKDF, authenticated encryption, key epoch rotation, and secure key storage. No QKD/photon claims.
- Data: content-addressed chunks, SHA-256 manifests, checkpointed transfer, explicit host enrollment, read-after-write integrity verification.
- Evolution: bounded event triggers, proposed changes, automated real tests, human-approved promotion, and rollback.

## Event state machine
IDLE -> SYNC_BEGIN -> SYNCING -> VERIFYING -> SYNC_VERIFIED
Failure: any in-progress state -> SYNC_FAILED, with reason and evidence.

No 'complete' UI message is allowed before destination integrity verification.
All events include schema version, node identifier, event ID, timestamp, correlation ID and previous ledger hash. Cross-node replay must deduplicate by event ID.

## Polyglot shell
A self-describing manifest describes adapters for Python, HTML/PWA, Android, CLI, and notebook outputs. The shell can regenerate reproducible packages; it does not self-deploy or propagate without approval.

## Capability boundaries
Browser UI cannot directly image disks, inspect arbitrary hosts, or obtain privileged hardware access. Such operations require an installed, authorized local agent. WebUSB/ADB/WebRTC and sensors are optional permission-gated adapters. AI/MCP calls require real provider authorization.

## Private/public boundary
Public: contracts, source, reproducible tests, dependency lockfiles, safe defaults.
Private: keys, access tokens, host inventory, device IDs, personal files, vault, telemetry, disk images, encrypted key material.

## ADAM gate
DISCOVER -> OBSERVE -> NORMALIZE -> CLASSIFY -> VERIFY -> FINGERPRINT -> LOOKUP_REMEDY -> APPLY_REMEDY -> REVERIFY.

Promotion requires actual logs, hashes, environment details, exit codes and rollback evidence. Missing network access or external credentials must yield NOT_TESTED, never PASS.
