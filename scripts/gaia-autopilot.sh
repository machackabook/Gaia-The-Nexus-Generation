#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/.gaia/state"
CATALOG="$STATE/environment.json"
NEXT="$STATE/next-step.md"
mkdir -p "$STATE"

log(){ printf '[GAIA-AUTOPILOT] %s\n' "$*"; }

catalog(){
  local os kernel arch shell git node python gh
  os="$(uname -s 2>/dev/null || true)"
  kernel="$(uname -r 2>/dev/null || true)"
  arch="$(uname -m 2>/dev/null || true)"
  shell="${SHELL:-unknown}"
  git="$(git --version 2>/dev/null || echo unavailable)"
  node="$(node --version 2>/dev/null || echo unavailable)"
  python="$(python3 --version 2>/dev/null || echo unavailable)"
  gh="$(gh --version 2>/dev/null | head -n1 || echo unavailable)"
  cat > "$CATALOG" <<EOF
{
  "schema": "gaia.environment.v1",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repository": "${GAIA_REPO:-local}",
  "runner_or_host": {
    "os": "$os",
    "kernel": "$kernel",
    "arch": "$arch",
    "shell": "$shell"
  },
  "toolchain": {
    "git": "$git",
    "node": "$node",
    "python": "$python",
    "gh": "$gh"
  },
  "usb_serial_policy": {
    "status": "catalog-only",
    "expected_connected_serial_devnodes": 0,
    "note": "Kernel serial driver registration is not treated as ownership or device presence."
  },
  "project_layers": [
    "runtime",
    "identity",
    "ledger",
    "eventbus",
    "memory-fabric",
    "orchestrator",
    "workspace",
    "mesh",
    "telemetry",
    "mobile",
    "gateway"
  ]
}
EOF
}

next_step(){
  cat > "$NEXT" <<'EOF'
# Gaia Autopilot — Next Step

1. Pull this branch on the target node.
2. Run the same catalog command locally.
3. Compare local state with `.gaia/state/environment.json`.
4. Commit only deterministic, non-secret state.
5. Push the result.
6. GitHub Actions advances the pipeline and produces the next state.
7. Human review remains required before merging into `main`.

Secrets, tokens, private keys, `.sparsebundle` data, device credentials, and personal data are never catalogued into Git.
EOF
}

verify(){
  test -f "$ROOT/README.md" || printf '# Gaia — Next Generation\n' > "$ROOT/README.md"
  test -d "$ROOT/.github/workflows"
  test -f "$ROOT/scripts/gaia-autopilot.sh"
  log "repository structure verified"
}

advance(){
  catalog
  next_step
  verify
  printf '%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$STATE/last-advanced.txt"
  log "state catalogued and next step emitted"
}

case "${1:-advance}" in
  bootstrap|catalog|verify|advance) "$([ "$1" = bootstrap ] && echo advance || echo "$1")" ;;
  *) echo "Usage: $0 {bootstrap|catalog|verify|advance}" >&2; exit 64 ;;
esac
