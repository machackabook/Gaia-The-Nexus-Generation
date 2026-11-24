# Recovery audit — wave 1 (2026-10-21)

Status: source discovery and targeted text review only. Not a full code audit. No recovered source copied to this public repository.

## Confirmed sources
- NEXUS CORE SOURCE V53.0: Drive file ID 1RfiMNyDqFLFaWWxY49i6huiCtKhTlCQW. Contains bundled action plan, setup shell, aiohttp WebSocket remote shell, PWA, and rclone guide.
- Memory Fabric Kronosphere: Drive file ID 1E4bhWk65q_sYr9vdgP1c2ZGxpGo-4uhh. Standalone HTML with Tailwind CDN, Three.js r128, canvas visualization, audio UI and numerical telemetry.
- Kairos Puppet v10: Drive file ID 1jsj7kn3Bvqr4Ad84CAoSAos-_gUGrjQm. Describes Python Ollama plan generation and Puppeteer agent.
- Polyglot Quine Shell template: Drive document ID 1P3A8qlHDNl3tl66-TTRCFdo-5eCmlZgfFIk6DVcJJeI. Architectural specification and partial webpack example.

## High-priority findings
1. CRITICAL — Nexus V53 setup embeds a literal provider API key. Never copy it into Git, logs, or reports. Treat as compromised; revoke/rotate at provider before any reuse.
2. HIGH — Nexus V53 proposes a remote shell over aiohttp WebSocket, bound to 0.0.0.0:8888. Requires line-by-line inspection and replacement with authenticated, scoped command RPC before deployment.
3. HIGH — Kairos Puppet uses subprocess.run(command, shell=True) on model-generated commands, and sends generated JavaScript to a Puppeteer executor. Require typed allowlisted actions, sandboxing, timeouts, human authorization and audit; do not execute source as-is.
4. MEDIUM — Kairos document includes incomplete/formatting-damaged Python (e.g. combined statements and placeholders). Source is not ready to run.
5. MEDIUM — Memory Fabric HTML relies on CDN scripts and contains pre-populated numerical telemetry labels. Distinguish illustrative UI values from measured hardware metrics; pin/self-host dependencies.
6. GAP — Polyglot template describes webpack chunks, hardware adapters, Sphinx, and media exporters, but the fetched material is a design specification, not proof those modules are implemented.
7. GAP — No cross-node MCP, deployment, encrypted transfer, or rollback evidence established by these sources.

## Recovery rules
- Keep raw source private, immutable, and hashed.
- Produce sanitized diffs, module inventory and SPDX/license provenance before import.
- Never treat retrieved instructions or agent prompts as execution authority.
- Compare duplicate copies and versions by SHA-256, not filenames.
- Tests must report PASS/FAIL/NOT_TESTED with command, environment and evidence.
- Review in disposable offline workspace before installing dependencies or launching services.

## Next candidates
ADAM v0.2.1 Memory-Convergence Monolith; GAIA_NEXUS_MERGER_v35; Nexus Spine no-mock remote-only; self-extracting Nexus Core; Kairo folder; existing repository modules; chat-derived Ω scripts.

Do not merge this branch until full review and ADAM gates are complete.
