# GAIA / NEXUS unified setup pipeline

## Purpose
GitHub is the version-controlled control plane. Recovered data stays local until it has been classified and explicitly approved for inclusion. This branch is **integration only**; do not promote until ADAM evidence is available.

## Run local verification
```bash
bash setup/pipeline/run.sh
```

## Inventory recovered code, read-only
```bash
python3 setup/pipeline/inventory.py /path/to/recovered/files --output /private/path/gaia-inventory.json
```
Inventory contains relative filenames, sizes, and SHA-256 hashes. Filenames may reveal sensitive details; keep the output private. Inventory does not audit the contents or prove that files are safe.

## Profiles
- Chromebook: Linux/Crostini control and development node.
- GAIASWINDOW: Windows runtime and optional authorized local agent.
- Optiplex: Linux/server or storage agent after hardware and OS verification.
- Samsung: Browser/PWA first; native features require explicitly installed permissions and an Android agent.

## Promotion gates
1. Discover candidate source and verify provenance.
2. Classify as code, documentation, asset, configuration, secret or obsolete.
3. Security review (secrets, dependencies, external calls, licenses, unsafe operations).
4. Validate syntax and reproducible build with pinned dependencies.
5. Run unit and real integration tests; mark unavailable environments NOT_TESTED.
6. Package with checksums, SBOM and rollback instructions.
7. Approve PR and deployment target.
8. Deploy only to explicitly enrolled devices.
9. Reverify installed services, data integrity, and health.

The CI pipeline currently verifies manifest policy, Python syntax, local file/hash tests, and simple credential patterns. It **does not** perform full secret scanning, dependency auditing, remote installation, device imaging, post-quantum cryptography, or end-to-end convergence tests. Those must be added and evidenced separately.

## Non-negotiable boundaries
Never commit API tokens, rclone configs, private telemetry, hardware identifiers, device backups, or credentials. Do not download and execute remote scripts without review. No automatic self-rewriting or self-deploying code. Prefer versioned releases and rollback over modifying a running installation.
