-- Additive schema for the existing nexus-penguin-relay-v1 Worker.
-- Safe to re-run: CREATE TABLE/INDEX IF NOT EXISTS only.
CREATE TABLE IF NOT EXISTS relay_audit (
  seq INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id TEXT NOT NULL UNIQUE,
  actor_id TEXT,
  actor_label TEXT,
  action TEXT NOT NULL,
  object_id TEXT,
  detail_hash TEXT,
  previous_hash TEXT,
  entry_hash TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS relay_audit_created_idx ON relay_audit(created_at DESC);

CREATE TABLE IF NOT EXISTS relay_devices (
  device_id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  last_seen INTEGER NOT NULL,
  revoked_at INTEGER
);
CREATE INDEX IF NOT EXISTS relay_devices_active_idx ON relay_devices(token_hash, revoked_at);

CREATE TABLE IF NOT EXISTS relay_enrollment (
  code_hash TEXT PRIMARY KEY,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER,
  label TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS relay_enrollment_expiry_idx ON relay_enrollment(expires_at, consumed_at);

CREATE TABLE IF NOT EXISTS relay_messages (
  message_id TEXT PRIMARY KEY,
  direction TEXT NOT NULL CHECK (direction IN ('to_device','from_device')),
  kind TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  status TEXT NOT NULL,
  device_id TEXT,
  delivered_at INTEGER
);
CREATE INDEX IF NOT EXISTS relay_messages_dispatch_idx ON relay_messages(direction, status, device_id, expires_at, created_at);
CREATE INDEX IF NOT EXISTS relay_messages_expiry_idx ON relay_messages(expires_at);
