# TDOC Provenance and Signed History

TDOC is the project provenance layer.

For every promoted change, record:

- TDOC document ID
- UTC timestamp
- actor/profile
- repository and branch
- source commit SHA
- parent TDOC ID where applicable
- changed paths
- SHA-256 manifest
- validation result
- rollback reference
- signature status

## Signing

Local human commits/tags should use a configured GPG or SSH signing identity. Protected branches should require verified signatures once the existing unsigned history has been reconciled.

Automation should use GitHub-native verified commits or a dedicated signing identity; private signing keys must never be committed.

## Golden G copyright header

Source files should carry a short SPDX-compatible project header where the file format permits comments. Generated/binary/vendor files are exempt. A CI check should validate presence without rewriting source during CI.

## History

The append-only TDOC ledger must never be rewritten by a watcher. Watchers produce candidate events; promotion into canonical history occurs through reviewed commits/PRs.
