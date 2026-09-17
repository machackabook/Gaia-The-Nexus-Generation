#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

GAIA_HOME="${GAIA_HOME:-$HOME/.gaia}"
STATE_DIR="$GAIA_HOME/state"
RUN_DIR="$GAIA_HOME/run"
LOG_DIR="$GAIA_HOME/log"
CONFIG="$GAIA_HOME/node.env"
mkdir -p "$STATE_DIR" "$RUN_DIR" "$LOG_DIR"
chmod 700 "$GAIA_HOME" "$STATE_DIR" "$RUN_DIR" "$LOG_DIR"

if [[ ! -f "$CONFIG" ]]; then
  cat > "$CONFIG" <<'EOF'
# Local-only configuration. Never commit this file.
GAIA_INSTANCE_ID=
GAIA_GATEWAY_URL=
GAIA_NODE_ROLE=remote-node
GAIA_TRANSPORT=ssh
GAIA_HEARTBEAT_SECONDS=30
EOF
  chmod 600 "$CONFIG"
fi

# Load only local configuration; do not place secrets in this script.
# shellcheck disable=SC1090
source "$CONFIG"

INSTANCE_ID="${GAIA_INSTANCE_ID:-termux-$(uname -m)-$(hostname)}"
HEARTBEAT="${GAIA_HEARTBEAT_SECONDS:-30}"
STATE="$STATE_DIR/instance.json"

cat > "$STATE" <<EOF
{
  "instance_id": "${INSTANCE_ID}",
  "class": "android",
  "role": "${GAIA_NODE_ROLE:-remote-node}",
  "transport": "${GAIA_TRANSPORT:-ssh}",
  "state": "AWAITING",
  "pid": $$,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

trap 'printf "{\"state\":\"STOPPED\",\"instance_id\":\"%s\"}\n" "$INSTANCE_ID" > "$STATE"' EXIT

printf '[GAIA] instance=%s state=AWAITING transport=%s\n' "$INSTANCE_ID" "${GAIA_TRANSPORT:-ssh}"
printf '[GAIA] gateway=%s\n' "${GAIA_GATEWAY_URL:-UNCONFIGURED}"
printf '[GAIA] This node will not claim ONLINE until authenticated and attested.\n'

while :; do
  # Waiting is intentional when no gateway is configured.
  # When a gateway is configured, health probing provides the first real
  # connectivity transition; authentication/attestation remains gateway-owned.
  if [[ -n "${GAIA_GATEWAY_URL:-}" ]] && command -v curl >/dev/null 2>&1; then
    if curl --fail --silent --show-error --connect-timeout 5 \
      "$GAIA_GATEWAY_URL/health" >/dev/null 2>&1; then
      python - "$STATE" "$INSTANCE_ID" <<'PY'
import json,sys,time
p=sys.argv[1]; iid=sys.argv[2]
with open(p,'w',encoding='utf-8') as f:
    json.dump({'instance_id':iid,'class':'android','state':'GATEWAY_REACHABLE','observed_at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())},f)
PY
      printf '[GAIA] gateway reachable; awaiting authenticated handshake.\n'
    else
      printf '[GAIA] gateway unreachable; remaining in AWAITING.\n'
    fi
  fi
  sleep "$HEARTBEAT"
done
