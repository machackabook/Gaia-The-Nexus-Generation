#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
python3 setup/pipeline/validate.py
bash setup/omega/verify.sh
echo "LOCAL VALIDATION COMPLETE. External host, crypto and integration tests remain NOT_TESTED."
echo "No device deployment or recovered-file upload has occurred."
