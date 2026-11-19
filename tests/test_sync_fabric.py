import json
import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from gaia_sync_fabric import Fabric, HTTPSFeed, import_mesh

class SyncFabricTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.fabric = Fabric(self.root / "fabric.sqlite3")

    def tearDown(self):
        self.tmp.cleanup()

    def test_event_deduplication_redaction_and_audit(self):
        a = self.fabric.event("github", "event-1", "push", {"repo":"demo","token":"never-store"})
        b = self.fabric.event("github", "event-1", "push", {"repo":"demo","token":"never-store"})
        self.assertTrue(a["inserted"])
        self.assertFalse(b["inserted"])
        with self.fabric.db() as c:
            payload = json.loads(c.execute("SELECT payload_json FROM events").fetchone()[0])
        self.assertEqual(payload["token"], "[REDACTED]")
        self.assertEqual(self.fabric.verify()["records"], 1)

    def test_atomic_cursor_commit_and_duplicate_page(self):
        run = self.fabric.start_run("alpha", "test")
        items = [{"id":"one","type":"release","data":{"tag":"v1"}},{"id":"two","data":{"x":2}}]
        self.assertEqual(self.fabric.commit_page("alpha",run["run_id"],None,"c2",items),2)
        run2 = self.fabric.start_run("alpha","test")
        self.assertEqual(run2["cursor"],"c2")
        self.assertEqual(self.fabric.commit_page("alpha",run2["run_id"],"c2","c3",items),0)
        self.assertEqual(self.fabric.snapshot()["events"],2)

    def test_failure_backoff(self):
        run = self.fabric.start_run("feed","test")
        self.fabric.fail_run("feed",run["run_id"],"TimeoutError")
        self.assertIsNone(self.fabric.start_run("feed","test"))

    def test_heartbeat_sequence_and_capability_lease(self):
        self.fabric.heartbeat("hp-win","boot-1","Windows",{"ram_mb":16000,"gpu":True},1)
        with self.assertRaises(ValueError):
            self.fabric.heartbeat("hp-win","boot-1","Windows",{"ram_mb":16000},1)
        tid = self.fabric.create_task("artifact_verify",{"artifact":"sha256:abc"},{"min_ram_mb":8000,"gpu":True},priority=5)
        lease = self.fabric.lease_task("hp-win",120)
        self.assertEqual(lease["task_id"],tid)
        receipt = self.fabric.receipt(tid,"hp-win","succeeded",{"verified":True})
        self.assertEqual(receipt["state"],"succeeded")
        self.assertEqual(self.fabric.snapshot()["tasks"]["completed"],1)

    def test_stale_or_unknown_nodes_cannot_lease(self):
        self.fabric.create_task("inventory",{})
        with self.assertRaises(ValueError):
            self.fabric.lease_task("unregistered")

    def test_task_executor_allowlist(self):
        with self.assertRaises(ValueError):
            self.fabric.create_task("arbitrary_shell",{"command":"id"})

    def test_cryptic_mesh_receipt_and_tdoc_import_are_idempotent(self):
        root, private = self.root/"mesh", self.root/"private"
        receipts = root/"devices"/"samsung"/"receipts"
        receipts.mkdir(parents=True)
        (receipts/"job.json").write_text(json.dumps({"packet_id":"job-1","receipt_sha256":"a"*64,"state":"succeeded"}))
        dev = private/"samsung"
        dev.mkdir(parents=True)
        (dev/"tdoc.jsonl").write_text(json.dumps({"tdoc_id":"TDOC-1","entry_sha256":"b"*64})+"\n")
        first = import_mesh(self.fabric,root,private)
        second = import_mesh(self.fabric,root,private)
        self.assertEqual((first["receipts"],first["tdoc"]),(1,1))
        self.assertEqual(second["duplicates"],2)
        self.assertEqual(self.fabric.snapshot()["events"],2)

    def test_feed_requires_https(self):
        with self.assertRaises(ValueError):
            HTTPSFeed({"id":"demo","endpoint":"http://example.invalid/feed"})

if __name__ == "__main__":
    unittest.main(verbosity=2)
