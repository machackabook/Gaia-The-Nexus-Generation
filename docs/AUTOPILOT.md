# Gaia Autopilot Pull → Catalog → Push → Advance

The repository now has a repeatable control loop intended to replace manual code-by-code setup.

```text
TARGET NODE
   │
   ├── pull automation branch
   │
   ├── inspect + catalog environment
   │
   ├── execute deterministic bootstrap/verification
   │
   ├── write non-secret state
   │
   └── push state
          │
          ▼
      GITHUB
          │
          ├── Actions validates
          ├── generated state is committed
          └── PR is opened for integration
          │
          ▼
     NEXT STEP
```

## What is automatic

- Environment discovery and catalog generation.
- Repository structure verification.
- Deterministic state files under `.gaia/state/`.
- Pull/commit/push loop from a target node.
- GitHub Actions execution and PR creation.

## What is intentionally not automatic

- Secret extraction or secret publication.
- Uploading private keys, tokens, credentials, `.sparsebundle` contents, or personal data.
- Destructive device operations.
- Automatic merge into `main`.
- Treating USB kernel-driver registration as evidence of device ownership.

The current USB audit result is compatible with this policy: no USB-serial devnodes were present, so the connected-device count is zero; kernel driver registration alone is not interpreted as a connected owned device.

## Target-node command

From a clone of the repository:

```bash
bash scripts/gaia-pull-next.sh
```

For a clean machine, clone the repository first, then run the same command. The script requires `git` and authenticated GitHub CLI (`gh`).

## State contract

`.gaia/state/environment.json` is descriptive state. `.gaia/state/next-step.md` is the handoff contract. These files are intentionally non-secret and deterministic enough to review in a pull request.
