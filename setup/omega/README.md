# GAIA Ω setup integration

This directory is the setup entry point for the Crystalline Triforce / Polyglot Quine architecture.

Run from a checked-out repository:

```bash
bash setup/omega/verify.sh
```

The verification script performs a real local filesystem write, hash check, restore and tamper-detection test in a temporary directory. It does not claim post-quantum encryption, remote synchronization, device imaging, or MCP connectivity.

The prior GAIA Ω.1 bootstrap was generated in a separate conversation environment. Its complete source has **not** been independently audited or imported into this repository; do not treat that bootstrap as a trusted production dependency. Once the exact source is available and reviewed, add it here as a versioned component with dedicated cryptographic and integration tests.

Recommended setup order:
1. Run local verification.
2. Enroll authorized hosts explicitly.
3. Install local agents and configure private credentials outside Git.
4. Execute real peer-to-peer transfer and restore tests.
5. Verify ML-KEM provider and authenticated session rekey tests.
6. Pass ADAM proof gates and review the promotion PR.

The script is non-destructive to existing system data and does not modify services or network settings.
