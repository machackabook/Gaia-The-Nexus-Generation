# GAIASWINDOW Reformation Masterwork — Pass 3

Status: PREPARATION / CLEAN-ROOM REBUILD
Target: newly reconstructed GAIASWINDOW image, with staged Windows 11 migration
Prepared: 2026-09-26

## Source-derived identity

Connected Drive evidence identifies:

- GAIASWINDOW as an HP All-in-One Windows 10/11 node.
- Historical user/data-vault path: `C:\Users\architect.GaiasWindow\GG`.
- Historical profiles: `ArchitectAZAZEL` (master configuration/deployment role) and `NexusGaia` (analysis, protection, monitoring).
- Samsung/Termux and HPAIO were historically assigned bidirectional SSH connectivity.
- Existing GitHub sync backend declares project `GAIASWINDOW`.
- Existing Sentinel authority lives in `NEXUS-SENTINEL-LEDGER`.

Historical private IP addresses are deliberately omitted from this public repository.

## Reformation principle

This build preserves the useful semantics of the historical profiles without preserving unsafe authority language or bypass behavior.

### AZAZEL profile — reconstructed meaning

`AZAZEL` becomes an explicit **administrator/operator profile**, not a permission-bypass mechanism.

Responsibilities:

- machine bootstrap
- package/runtime installation
- approved system configuration
- recovery-point creation
- Git/Drive integration
- controlled service changes

Every privileged mutation must be logged and reversible.

### GAIA profile

`NexusGaia` becomes the runtime/observability profile:

- telemetry collection
- integrity observation
- repository state
- network-health observation
- local dashboards
- ADAM interfaces
- Sentinel event forwarding

It does not silently elevate privileges.

## Target Windows architecture

```text
C:\GAIA
├── bin\
├── config\
│   ├── machine\
│   ├── network\
│   ├── profiles\
│   └── templates\
├── runtime\
│   ├── adam\
│   ├── gaia\
│   ├── synapse\
│   └── adapters\
├── sentinel\
│   ├── baseline\
│   ├── manifests\
│   ├── events\
│   └── quarantine\
├── telemetry\
├── repos\
├── cloud\
├── logs\
├── evidence\
├── recovery\
└── archive\legacy
```

The historical `GG` vault should initially be mounted/imported read-only or copied into an evidence/import stage before normalization.

## Staged reformation

### Phase 0 — immutable evidence capture

Before tuning:

- Windows edition/build and activation state
- BIOS/UEFI mode and Secure Boot state
- TPM state
- CPU/RAM/storage inventory
- disk/partition/BitLocker status
- installed drivers and signed-driver inventory
- Windows Update history
- installed applications/packages
- services and scheduled tasks
- firewall profiles/rules
- network adapters/routes/DNS configuration
- listening ports
- SSH configuration
- PowerShell version/modules
- Git/GitHub CLI state
- WSL/Hyper-V/Virtual Machine Platform state
- rclone version and **remote names only**
- Event Viewer summaries
- Reliability Monitor / crash evidence
- existing GAIA/Nexus directories and hashes

Do not collect passwords, tokens, rclone secrets, browser cookies, or private keys into Git.

### Phase 1 — Windows 11 readiness

Validate before upgrade:

- supported CPU
- TPM 2.0
- UEFI + Secure Boot capability
- >= 4 GB RAM and >= 64 GB storage (project target should exceed minimums)
- driver/firmware health
- current backup/recovery media
- BitLocker recovery-key availability if encryption is enabled

No registry/installer bypass should be part of the canonical build.

### Phase 2 — base performance

Use evidence-driven tuning:

- update BIOS/firmware and OEM drivers where appropriate
- Windows Update fully current
- balanced/high-performance power policy selected based on workload and thermals
- startup-app audit
- storage health/TRIM verification
- remove only confirmed unwanted packages
- retain Windows Security, Update, Search/SysMain unless measurements justify a specific change
- configure Developer Mode only when required
- enable long paths for development where compatible

### Phase 3 — development substrate

Target toolchain:

- PowerShell 7
- Git + GitHub CLI
- Windows Terminal
- Python
- Node.js LTS
- VS Code or selected editor
- WSL2 with a supported Linux distribution
- OpenSSH client; server only if needed
- Docker/containers only if hardware and workload justify them
- rclone
- Tailscale or selected mesh layer only after network policy is defined

### Phase 4 — ADAM / GAIA integration

ADAM should consume explicit interfaces rather than scanning arbitrary user files:

```text
filesystem import -> quarantine -> provenance -> normalized index
                                     |
                                     v
                               ADAM memory
                                     |
                  +------------------+------------------+
                  |                                     |
                GAIA                                Sentinel
             runtime/UI                       integrity/events
```

Memory ingestion must preserve source path, source hash, timestamp, classification and promotion state.

### Phase 5 — Sentinel

Windows collector forwards normalized observations to the existing Sentinel lineage:

- file-integrity manifests
- selected configuration hashes
- Defender/security status
- firewall state
- service changes
- scheduled-task changes
- repository integrity
- authentication/SSH configuration changes
- crash/reliability events

Observation does not equal automatic remediation. High-impact remediation remains review-gated.

### Phase 6 — cloud/rclone

Treat `rclone.conf` as a secret-bearing configuration file.

Rules:

- never commit the real file
- never print obscured passwords/tokens into CI logs
- inventory remote **names/types** into a sanitized manifest
- keep configuration under the user's protected profile or another ACL-restricted secret path
- use `rclone config redacted`/equivalent redaction when generating diagnostics where supported
- mount/sync only explicitly approved paths
- use dry-run before destructive sync operations

Historical material describing API-key regex scanning, vault crumb reconstruction, or arbitrary credential discovery is deprecated and must not be reintroduced.

### Phase 7 — network reformation

Build the network from observation first:

1. identify physical adapters
2. identify gateway/DNS/DHCP state
3. inventory current routes
4. establish host firewall baseline
5. enable SSH only on required profiles/interfaces
6. authenticate mesh/VPN nodes individually
7. assign explicit roles to GAIASWINDOW, Samsung, Chromebook and OptiPlex
8. keep management and experimental services separately scoped where feasible
9. record topology without committing private addressing/MACs

No hard-coded historical IP address is canonical.

### Phase 8 — migration into Windows 11

After Phase 0 evidence and Phase 1 readiness succeed:

- create system recovery point/image
- export application/tool manifests
- export sanitized GAIA configuration
- upgrade using Microsoft's supported path
- rerun inventory
- compare before/after state
- restore GAIA services incrementally
- validate WSL/network/Git/rclone/Sentinel
- only then enable higher-level ADAM/GAIA automation

## Performance philosophy

The old `Nexus Overlord` script disabled Windows services broadly. The reformation replaces that with measurement:

```text
baseline -> benchmark -> change one subsystem -> benchmark -> retain/revert
```

CPU, memory pressure, storage latency, boot time, network throughput and application startup should be measured before claiming an enhancement.

## Public/private boundary

Safe for GitHub:

- scripts
- schemas
- templates
- sanitized machine roles
- package manifests
- documentation
- tests
- hashes of public artifacts

Keep private:

- rclone.conf
- tokens/API keys
- SSH private keys
- passwords
- BitLocker recovery material
- exact private network inventory when unnecessary
- raw security logs containing identifiers
- browser/session databases
- credential exports

## Immediate deliverables to build after live inventory

- `windows/bootstrap/Invoke-GaiaBootstrap.ps1`
- `windows/audit/Get-GaiaBaseline.ps1`
- `windows/network/Get-GaiaNetworkState.ps1`
- `windows/sentinel/Export-GaiaSentinelEvent.ps1`
- `windows/cloud/Get-RcloneSanitizedInventory.ps1`
- `windows/migration/Test-Windows11Readiness.ps1`
- `config/instances.example.yaml`
- `config/profiles/azazel.json`
- `config/profiles/nexus-gaia.json`
- `docs/GAIASWINDOW-WINDOWS11-MIGRATION.md`

These should be generated only after the live baseline identifies what this fresh image actually contains.
