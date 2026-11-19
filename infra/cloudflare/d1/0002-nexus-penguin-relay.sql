-- Reproducible schema for the existing nexus-penguin-relay-v1 Worker.
-- Matches the inspected SQLite schema. Safe to re-run.
CREATE TABLE IF NOT EXISTS relay_audit (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT NOT NULL UNIQUE,
  actor_id TEXT NOT NULL,
  actor_label TEXT NOT NULL,
  action TEXT NOT NULL,
  object_id TEXT,
  detail_hash TEXT NOT NULL,
  previous_hash TEXT NOT NULL,
  entry_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS relay_devices (
  device_id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  last_seen TEXT,
  revoked_at TEXT
);
CREATE TABLE IF NOT EXISTS relay_enrollment (
  code_hash TEXT PRIMARY KEY,
  expires_at TEXT NOT NULL,
  consumed_at TEXT,
  label TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS relay_messages (
  message_id TEXT PRIMARY KEY,
  direction TEXT NOT NULL CHECK(direction IN ('to_device','from_device')),
  kind TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'queued',
  device_id TEXT,
  delivered_at TEXT
);
CREATE INDEX IF NOT EXISTS relay_audit_created_idx ON relay_audit(created_at DESC);
CREATE INDEX IF NOT EXISTS relay_devices_active_idx ON relay_devices(token_hash, revoked_at);
CREATE INDEX IF NOT EXISTS relay_enrollment_expiry_idx ON relay_enrollment(expires_at, consumed_at);
CREATE INDEX IF NOT EXISTS relay_messages_device ON relay_messages(device_id, direction, created_at);
CREATE INDEX IF NOT EXISTS relay_messages_dispatch_idx ON relay_messages(direction, status, device_id, expires_at, created_at);
CREATE INDEX IF NOT EXISTS relay_messages_expiry_idx ON relay_messages(expires_at);
CREATE INDEX IF NOT EXISTS relay_messages_inbox ON relay_messages(direction, status, created_at);
