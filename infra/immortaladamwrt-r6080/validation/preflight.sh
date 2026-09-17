#!/bin/sh
# Secret-free R6080/ADAMWrt preflight. Run on the router before applying policy.
set -eu

fail=0
check() {
  name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '[OK] %s\n' "$name"
  else
    printf '[FAIL] %s\n' "$name"
    fail=1
  fi
}

printf '%s\n' '=== ImmortalADAMWrt R6080 preflight ==='

check 'OpenWrt present' test -f /etc/openwrt_release
check 'UCI present' command -v uci
check 'ip present' command -v ip
check 'free-space report' sh -c 'df -h /overlay 2>/dev/null || df -h /'

printf '\n-- Hardware --\n'
cat /etc/openwrt_release 2>/dev/null || true
printf '\n-- Interfaces --\n'
ip -br link 2>/dev/null || true
printf '\n-- Routes --\n'
ip route 2>/dev/null || true
printf '\n-- Firewall --\n'
if command -v nft >/dev/null 2>&1; then nft list ruleset 2>/dev/null | sed -n '1,160p' || true; fi

printf '\n-- Tailscale --\n'
if command -v tailscale >/dev/null 2>&1; then
  tailscale version || true
  tailscale status || true
else
  printf '%s\n' '[INFO] tailscale binary not installed; do not install blindly on the 8 MiB R6080.'
fi

printf '\n-- Security checks --\n'
if uci -q get firewall.@defaults[0].input >/dev/null 2>&1; then
  printf 'firewall input: '; uci -q get firewall.@defaults[0].input || true
fi
if uci -q get firewall.@defaults[0].forward >/dev/null 2>&1; then
  printf 'firewall forward: '; uci -q get firewall.@defaults[0].forward || true
fi

# Refuse to claim an allowlist is active merely because a registry exists.
if uci show dhcp 2>/dev/null | grep -q "mac="; then
  printf '%s\n' '[OK] DHCP contains at least one static MAC reservation.'
else
  printf '%s\n' '[WARN] No static DHCP MAC reservation detected; inventory enforcement is incomplete.'
fi

printf '\n=== RESULT ===\n'
if [ "$fail" -eq 0 ]; then
  printf '%s\n' 'Preflight completed. Review output before changing firewall/routing.'
else
  printf '%s\n' 'Preflight found required-command failures. Do not apply the full policy yet.'
  exit 1
fi
