#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
command -v python3 >/dev/null || { echo 'FAIL: python3 required'; exit 2; }
python3 - <<'PY'
import hashlib, json, os, pathlib, tempfile, time
def digest(data): return hashlib.sha256(data).hexdigest()
with tempfile.TemporaryDirectory(prefix="gaia-omega-verify-") as temp:
    root=pathlib.Path(temp)
    source=root/"source.bin"
    restored=root/"restored.bin"
    payload=os.urandom(65536)
    source.write_bytes(payload)
    expected=digest(payload)
    manifest={"schema":1,"sha256":expected,"size":len(payload),"timestamp":time.time()}
    (root/"manifest.json").write_text(json.dumps(manifest))
    restored.write_bytes(source.read_bytes())
    assert digest(restored.read_bytes())==expected, "restore mismatch"
    assert len(restored.read_bytes())==manifest["size"], "size mismatch"
    tampered=bytearray(restored.read_bytes())
    tampered[0]^=1
    restored.write_bytes(tampered)
    assert digest(restored.read_bytes())!=expected, "tamper detection failed"
    print(json.dumps({"local_fs":"PASS","sha256_restore":"PASS","tamper_detection":"PASS","remote_sync":"NOT_TESTED","ml_kem":"NOT_TESTED","mcp":"NOT_TESTED","imaging":"NOT_TESTED"},indent=2))
PY
