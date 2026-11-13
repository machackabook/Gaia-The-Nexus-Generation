# Connected Computer Instances — Deep Dive Pass 2

Reviewed: 2026-09-26

## Evidence model

This map distinguishes three levels:

- **Confirmed in connected sources** — explicitly named in Drive or GitHub material.
- **Intended role** — a source document assigns a function, but current deployment is not independently verified.
- **Historical/proposed** — scripts or prose describe an approach that may be incomplete, unsafe, obsolete, or technically inaccurate.

## 1. GAIASWINDOW — Windows node

**Source evidence:** `Nexus Overlord Command Suite` explicitly labels its target as `HP All-in-One (GAIASWINDOW) -> Serves Dell Optiplex`.

Documented intended functions include:

- Windows/PowerShell control surface under `C:\Nexus`
- HTTP/IIS boot staging
- PXE/TFTP preparation for the Dell
- development/runtime package installation
- local logging/evidence directories
- integrity checks
- network/firewall preparation

### Assessment

The document is valuable as lineage, but it should not be executed wholesale. It contains self-copy/profile persistence, broad service disabling, firewall changes, and assumptions about PXE/network state. A modern GaiasWindow implementation should convert these into idempotent, reversible modules with explicit operator approval.

**GitHub correlation:** `nexus-repo-sync/config/gaia-sync.json` explicitly declares project `GAIASWINDOW`, confirming that the name is represented in the repository synchronization backend.

## 2. Dell OptiPlex — headless/compute target

**Source evidence:** both `Hardware Bridge Protocol` and `Nexus Overlord Command Suite` identify a Dell/OptiPlex as a target served or reconstructed from the surrounding environment.

Documented intended roles:

- headless development/compute hub
- Ethernet/PXE boot target
- SSH-accessible Linux node after provisioning
- downstream machine served by GaiasWindow

### Assessment

The architectural role is well evidenced. Current OS, model, boot state, and network identity are not established by the sources reviewed in this pass. The historical claim that a simple USB-A/USB-C cable makes Android a KVM is not technically sufficient by itself and should not be treated as deployed functionality.

## 3. Samsung Android / Termux — mobile controller and bridge

**Source evidence:** Drive contains repeated `Sovereign OmniKernel` deployment documents explicitly targeting a Samsung device with Termux/Acode, plus `Hardware Bridge Protocol` and `Device Triage & Kernel Manager`.

Documented intended roles:

- Termux command environment
- mobile controller/bridge
- repository tooling
- USB-hub/device interaction
- possible network/PXE helper
- Acode-facing development surface

### Assessment

Samsung/Termux is one of the most consistently documented physical control surfaces. Some historical device-triage material includes destructive wipe/recovery operations and placeholder tooling; these are not evidence of a working deployment and should remain quarantined as historical material.

## 4. Chromebook / Crostini

**Source evidence:** searches correlate Chromebook/Crostini terms with `IP Ledger - Enhanced Interoperable System`, Nexus workspace renderers, and ADAM/Memory-Convergence material.

Documented/project-context role:

- Linux/Crostini development environment
- repository/CLI working node
- bridge between ChromeOS and the wider Gaia/Nexus development mesh

### Assessment

The role is supported, but this pass did not retrieve a source that identifies exact Chromebook hardware or a definitive current configuration. Treat the node as **evidenced but incompletely characterized**.

## 5. ZTE Android tablet

**Source evidence:** `Device Triage & Kernel Manager` targets a ZTE tablet and assumes ADB connectivity.

### Assessment

Existence as a project target is evidenced. The script contains a placeholder IP and destructive wipe logic, so it does not establish a currently connected or configured ZTE instance.

## 6. iPad / Apple Watch / Apple-adjacent endpoints

**Source evidence:** historical bridge/triage documents describe an iPad DFU target and an Apple Watch Series 5 as a shortcut/haptic command endpoint.

### Assessment

These are documented integration targets, not verified current online nodes. The iPad script references placeholder DFU utilities/payloads and must not be treated as operational evidence.

## 7. TV / Fire TV / Roku-class display endpoints

**Source evidence:** `Hardware Bridge Protocol` discusses an Insignia/Roku TV conditionally; the broader Drive corpus includes tvOS/WebTVOS material. Earlier project architecture also treats display/streaming devices as output/control surfaces.

### Assessment

The connected Drive search did not produce a strong current inventory record for Roku or Fire TV in this pass. Treat these as intended display/edge endpoints pending a dedicated media-device inventory pass.

## 8. Router / OpenWRT network plane

The computer-instance architecture repeatedly assumes a shared Ethernet/router plane and later project material describes OpenWRT/ImmortalWrt as a routing/security component. Historical scripts contain hard-coded gateway assumptions; those must not be promoted into canonical configuration without a fresh network inventory.

## Current topology hypothesis

```text
                   GitHub / Drive
                        |
                 synchronization
                        |
              +-------------------+
              |   GAIASWINDOW     |
              | HP AIO / Win 10   |
              +---------+---------+
                        |
               Ethernet / control
                        |
              +---------v---------+
              | Dell OptiPlex     |
              | compute/headless  |
              +-------------------+

 Samsung / Termux -----------------+
 mobile control / bridge           |
                                   +--> shared network / repository mesh

 Chromebook / Crostini ------------+
 Linux development node

 Display / TV / tablet endpoints
 remain partially characterized.
```

This diagram is a **source-derived working hypothesis**, not a live network scan.

## Recommended next evidence pass

1. Extract the IP Ledger structure without publishing addresses or credentials.
2. Read the Samsung OmniKernel deployment documents and compare duplicates/versions.
3. Inspect Windows AppHang/AppCrash collections to determine what actually failed on GaiasWindow.
4. Locate GaiasWindow-related GitHub commit history beyond code search.
5. Build a sanitized `instances.yaml` schema containing roles and capabilities, but no secrets, MAC addresses, tokens, or private IPs.
6. Compare intended topology against repository workflows so each physical node has one explicit authority and recovery path.
