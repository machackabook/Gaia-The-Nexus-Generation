# ImmortalADAMWrt — NETGEAR R6080

This directory defines the reproducible network-control-plane configuration for a NETGEAR R6080 running an OpenWrt-family firmware build. The R6080 is a constrained platform: 64 MiB RAM, 8 MiB flash, and Fast Ethernet. OpenWrt documents the default port mapping as WAN=`eth0.2` and LAN=`br-lan`/`eth0.1`, with physical switch ports WAN=4 and LAN 1–4=3,2,1,0. See the upstream hardware page before flashing or upgrading.

## Design intent

```text
AT&T Fiber / upstream
        |
        | Ethernet
        v
+---------------------------+
| NETGEAR R6080             |
| ImmortalADAMWrt           |
|                           |
| WAN/DEV ingress           |
|  - Tailscale              |
|  - mobile/dev clients     |
|  - controlled streaming  |
|                           |
| LAN / wired core          |
|  - Gaia's Window/OptiPlex |
|  - Ethernet hub           |
|  - Chromebook             |
+-------------+-------------+
              |
              +---- OptiPlex / Gaia
              +---- Ethernet hub
              +---- Chromebook
              +---- other allowlisted wired nodes

Tailscale control plane
        |
        +---- subnet routes for approved LAN services
        +---- optional exit-node advertisement
        +---- remote administration

Optional remote exit node:
Fire TV/streaming device running a supported Tailscale client
```

The router is the **network policy boundary**, not the storage or compute authority. ADAM/Gaia services remain on the LAN/compute nodes. The public AT&T gateway should not expose private services directly.

## Important constraints

1. Do not treat an arbitrary IP-address reservation table as infinite storage. IPv4 addresses are routing identifiers, not storage containers. The implementation therefore uses fixed CIDRs, DHCP reservations, an explicit device registry, firewall zones, and an allowlist.
2. Do not put credentials, auth keys, Tailscale state, sparsebundle contents, or private gateway addresses in this public repository.
3. The R6080's 8 MiB flash and 64 MiB RAM make a full stock Tailscale installation potentially unsuitable. Use a firmware/package combination that actually fits, or build a minimal Tailscale package as documented by OpenWrt. The repository contains only configuration and validation logic; it does not pretend that an unverified binary will fit.
4. The Fire TV/streaming device should be treated as an **optional exit node**, not a trust anchor. The router remains the policy enforcement point.
5. Public services belong behind an authenticated gateway/reverse proxy on a capable Linux host. Do not DMZ the OptiPlex or expose SSH/LuCI/Tailscale administration to the public WAN.

## Network roles

| Segment | Example CIDR | Purpose |
|---|---:|---|
| `core` | `10.42.0.0/24` | trusted wired infrastructure |
| `dev` | `10.42.10.0/24` | mobile/development devices |
| `services` | `10.42.20.0/24` | Ollama/MCP/Gaia services |
| `iot` | `10.42.30.0/24` | streaming/TV/limited IoT |
| `mgmt` | `10.42.40.0/28` | router/network administration |
| Tailscale | `100.64.0.0/10` | Tailnet overlay; do not hard-code node addresses |

The exact VLAN capability of the deployed R6080 firmware must be verified before applying these zones. If the constrained build cannot provide multiple VLANs, keep the same logical roles but enforce the boundary with separate physical ports/SSID policy or move inter-zone routing to the OptiPlex/firewall host.

## Device identity

Each approved device gets:

- stable device UUID generated outside the router;
- hostname;
- MAC address(es);
- physical port/role;
- DHCP reservation;
- Tailscale node identity when applicable;
- capability profile;
- owner/operator label;
- last-seen and audit metadata.

Do not use MAC address alone as a cryptographic identity. MACs are mutable and are not proof of device ownership.

## Routing policy

Default posture:

- WAN -> router management: deny.
- WAN -> LAN: deny unless an explicit, authenticated service is published.
- LAN -> WAN: allowed for ordinary wired clients unless policy requires a Tailscale exit path.
- DEV -> SERVICES: allow only required application ports.
- DEV -> CORE/MGMT: deny by default.
- IOT -> LAN: deny by default.
- IOT -> WAN: allow only the minimum required for streaming/update operation.
- Tailscale -> approved services: allow by capability.
- Router administration: LAN/Tailscale only.

## Tailscale modes

The router can be configured as:

- **subnet router**: advertise approved internal CIDRs to the tailnet;
- **exit node**: advertise the router itself as an internet egress point;
- **exit-node client**: route selected router/LAN traffic through a remote Tailscale exit node.

Do not enable all three blindly. Select the mode per deployment and verify the route table and firewall after every change.

For the proposed streaming-device exit path, the preferred design is:

```text
wired client
  -> R6080 policy router
  -> Tailscale overlay
  -> approved Fire TV/streaming exit node
  -> internet
```

This requires the streaming device to actually support Tailscale and IP forwarding/exit-node operation. If it cannot, place the exit-node role on a Linux host physically adjacent to the TV instead.

## Repository layout

```text
infra/immortaladamwrt-r6080/
├── README.md
├── device-registry.yaml
├── network-plan.yaml
├── tailscale-policy.yaml
├── validation/
│   └── preflight.sh
└── openwrt/
    ├── firewall-snippet.nft
    └── firstboot.sh
```

The configuration is intentionally declarative and secret-free so it can be reviewed in GitHub before being applied to the physical router.
