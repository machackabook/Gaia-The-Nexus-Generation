#!/usr/bin/env python3
"""GAIA Sync Fabric v1.0.0: provider events, node heartbeats, bounded task leases.
Stdlib-only; local-first; no arbitrary remote shell execution.
"""
from __future__ import annotations
import argparse, contextlib, datetime as dt, hashlib, hmac, json, os, re, signal, sqlite3, sys, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs, urlencode
from urllib.request import Request, urlopen

VERSION = "1.0.0"
ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$")
TASK_KINDS = {"inventory", "diagnostic", "artifact_verify", "checkpoint_restore_plan"}
SENSITIVE = {"authorization","token","access_token","refresh_token","password","secret","cookie","set-cookie","api_key","private_key"}
DEFAULT_DB = Path(os.getenv("GAIA_SYNC_DB", str(Path.home()/"Æ/sync-fabric/fabric.sqlite3"))).expanduser()

def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()

def canon(v):
    return json.dumps(v, sort_keys=True, separators=(",",":"), ensure_ascii=False).encode()

def digest(b):
    return hashlib.sha256(b).hexdigest()

def ident(v):
    if not isinstance(v,str) or not ID.fullmatch(v): raise ValueError("invalid identifier")
    return v

def clean(v):
    if isinstance(v,dict): return {str(k):("[REDACTED]" if str(k).lower() in SENSITIVE else clean(x)) for k,x in v.items()}
    if isinstance(v,list): return [clean(x) for x in v]
    return v

class Fabric:
    def __init__(self,path=DEFAULT_DB):
        self.path=Path(path).expanduser(); self.path.parent.mkdir(parents=True,exist_ok=True); self.init()
    @contextlib.contextmanager
    def db(self):
        c=sqlite3.connect(self.path,timeout=15,isolation_level=None); c.row_factory=sqlite3.Row
        c.execute("PRAGMA busy_timeout=15000"); c.execute("PRAGMA foreign_keys=ON")
        try: yield c
        finally: c.close()
    def init(self):
        with self.db() as c:
            c.execute("PRAGMA journal_mode=WAL")
            c.executescript("""
            CREATE TABLE IF NOT EXISTS provider_state(provider_id TEXT PRIMARY KEY,cursor TEXT,status TEXT NOT NULL DEFAULT 'unknown',last_success TEXT,lease_owner TEXT,lease_until REAL,last_error TEXT,failure_count INTEGER NOT NULL DEFAULT 0,next_poll_at REAL);
            CREATE TABLE IF NOT EXISTS events(event_id TEXT PRIMARY KEY,provider_id TEXT NOT NULL,source_id TEXT NOT NULL,event_type TEXT NOT NULL,occurred_at TEXT,ingested_at TEXT NOT NULL,payload_json TEXT NOT NULL,payload_sha256 TEXT NOT NULL,provenance_json TEXT NOT NULL,UNIQUE(provider_id,source_id));
            CREATE INDEX IF NOT EXISTS events_provider_time ON events(provider_id,ingested_at);
            CREATE TABLE IF NOT EXISTS sync_runs(run_id TEXT PRIMARY KEY,provider_id TEXT NOT NULL,started_at TEXT NOT NULL,finished_at TEXT,state TEXT NOT NULL,received INTEGER DEFAULT 0,inserted INTEGER DEFAULT 0,cursor_before TEXT,cursor_after TEXT,error_class TEXT);
            CREATE TABLE IF NOT EXISTS nodes(node_id TEXT PRIMARY KEY,incarnation TEXT NOT NULL,platform TEXT NOT NULL,capabilities TEXT NOT NULL,last_seen REAL NOT NULL,state TEXT NOT NULL,seq INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS nonces(node_id TEXT NOT NULL,nonce TEXT NOT NULL,seen_at REAL NOT NULL,PRIMARY KEY(node_id,nonce));
            CREATE TABLE IF NOT EXISTS tasks(task_id TEXT PRIMARY KEY,kind TEXT NOT NULL,payload TEXT NOT NULL,requirements TEXT NOT NULL,state TEXT NOT NULL,priority INTEGER NOT NULL,created_at TEXT NOT NULL,expires REAL NOT NULL,lease_node TEXT,lease_until REAL,attempts INTEGER NOT NULL,max_attempts INTEGER NOT NULL);
            CREATE INDEX IF NOT EXISTS task_queue ON tasks(state,priority DESC,created_at);
            CREATE TABLE IF NOT EXISTS receipts(receipt_id TEXT PRIMARY KEY,task_id TEXT NOT NULL,node_id TEXT NOT NULL,state TEXT NOT NULL,result TEXT NOT NULL,result_sha256 TEXT NOT NULL,created_at TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS audit(seq INTEGER PRIMARY KEY AUTOINCREMENT,at TEXT NOT NULL,actor TEXT NOT NULL,action TEXT NOT NULL,subject TEXT NOT NULL,detail TEXT NOT NULL,prev TEXT NOT NULL,hash TEXT NOT NULL UNIQUE);
            """)
    def audit(self,c,actor,action,subject,detail):
        r=c.execute("SELECT hash FROM audit ORDER BY seq DESC LIMIT 1").fetchone(); prev=r[0] if r else "0"*64
        b={"at":now(),"actor":actor,"action":action,"subject":subject,"detail":clean(detail),"prev":prev}
        c.execute("INSERT INTO audit(at,actor,action,subject,detail,prev,hash) VALUES(?,?,?,?,?,?,?)",(b["at"],actor,action,subject,canon(b["detail"]).decode(),prev,digest(canon(b))))
    def verify(self):
        prev="0"*64; count=0
        with self.db() as c:
            for r in c.execute("SELECT * FROM audit ORDER BY seq"):
                b={"at":r["at"],"actor":r["actor"],"action":r["action"],"subject":r["subject"],"detail":json.loads(r["detail"]),"prev":r["prev"]}
                if r["prev"]!=prev or digest(canon(b))!=r["hash"]: raise ValueError("audit chain mismatch at "+str(r["seq"]))
                prev,count=r["hash"],count+1
        return {"valid":True,"records":count,"head_sha256":prev}
    def event(self,provider,source,event_type,payload,occurred=None,provenance=None):
        provider,source,event_type=map(ident,(provider,source,event_type)); raw=canon(clean(payload))
        if len(raw)>512000: raise ValueError("event payload too large")
        eid=digest((provider+"\0"+source).encode())
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE")
            cur=c.execute("INSERT OR IGNORE INTO events VALUES(?,?,?,?,?,?,?,?,?)",(eid,provider,source,event_type,occurred,now(),raw.decode(),digest(raw),canon(clean(provenance or {})).decode()))
            inserted=cur.rowcount==1
            if inserted: self.audit(c,"provider:"+provider,"EVENT_INGESTED",eid,{"payload_sha256":digest(raw),"type":event_type})
            c.commit()
        return {"event_id":eid,"inserted":inserted,"payload_sha256":digest(raw)}
    def start_run(self,pid,owner):
        t=time.time(); rid=str(uuid.uuid4())
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); r=c.execute("SELECT * FROM provider_state WHERE provider_id=?",(pid,)).fetchone()
            if r and ((r["lease_until"] or 0)>t or (r["next_poll_at"] or 0)>t): c.rollback(); return None
            cursor=r["cursor"] if r else None
            c.execute("INSERT INTO provider_state(provider_id,cursor,status,lease_owner,lease_until) VALUES(?,?,'syncing',?,?) ON CONFLICT(provider_id) DO UPDATE SET status='syncing',lease_owner=excluded.lease_owner,lease_until=excluded.lease_until",(pid,cursor,owner,t+90))
            c.execute("INSERT INTO sync_runs(run_id,provider_id,started_at,state,cursor_before) VALUES(?,?,?,'running',?)",(rid,pid,now(),cursor)); c.commit()
        return {"run_id":rid,"cursor":cursor}
    def commit_page(self,pid,rid,before,after,items):
        inserted=0
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE")
            for item in items:
                source=ident(str(item["id"])); typ=ident(str(item.get("type","update"))); raw=canon(clean(item.get("data",item)))
                if len(raw)>512000: raise ValueError("event payload too large")
                eid=digest((pid+"\0"+source).encode())
                cur=c.execute("INSERT OR IGNORE INTO events VALUES(?,?,?,?,?,?,?,?,?)",(eid,pid,source,typ,item.get("occurred_at"),now(),raw.decode(),digest(raw),canon({"adapter":"https-json-feed"}).decode()))
                inserted+=int(cur.rowcount==1)
            c.execute("INSERT INTO provider_state(provider_id,cursor,status,last_success) VALUES(?,?,'healthy',?) ON CONFLICT(provider_id) DO UPDATE SET cursor=excluded.cursor,status='healthy',last_success=excluded.last_success,lease_owner=NULL,lease_until=NULL,last_error=NULL,failure_count=0,next_poll_at=NULL",(pid,after,now()))
            c.execute("UPDATE sync_runs SET finished_at=?,state='committed',received=?,inserted=?,cursor_after=? WHERE run_id=?",(now(),len(items),inserted,after,rid))
            self.audit(c,"provider:"+pid,"PAGE_COMMITTED",rid,{"received":len(items),"inserted":inserted,"cursor_before":before,"cursor_after":after}); c.commit()
        return inserted
    def fail_run(self,pid,rid,error):
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); r=c.execute("SELECT failure_count FROM provider_state WHERE provider_id=?",(pid,)).fetchone()
            count=(r[0] if r else 0)+1; delay=min(3600,15*(2**min(count-1,7)))
            c.execute("UPDATE provider_state SET status='degraded',lease_owner=NULL,lease_until=NULL,last_error=?,failure_count=?,next_poll_at=? WHERE provider_id=?",(error,count,time.time()+delay,pid))
            c.execute("UPDATE sync_runs SET finished_at=?,state='failed',error_class=? WHERE run_id=?",(now(),error,rid))
            self.audit(c,"provider:"+pid,"SYNC_FAILED",rid,{"error_class":error,"retry_after_seconds":delay}); c.commit()
    def heartbeat(self,nid,incarnation,platform,caps,seq):
        nid,incarnation=ident(nid),ident(incarnation)
        if not isinstance(caps,dict) or len(canon(caps))>16384: raise ValueError("invalid capabilities")
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); old=c.execute("SELECT * FROM nodes WHERE node_id=?",(nid,)).fetchone()
            if old and old["incarnation"]==incarnation and seq<=old["seq"]: c.rollback(); raise ValueError("stale node sequence")
            c.execute("INSERT INTO nodes VALUES(?,?,?,?,?,'healthy',?) ON CONFLICT(node_id) DO UPDATE SET incarnation=excluded.incarnation,platform=excluded.platform,capabilities=excluded.capabilities,last_seen=excluded.last_seen,state='healthy',seq=excluded.seq",(nid,incarnation,str(platform)[:128],canon(clean(caps)).decode(),time.time(),int(seq)))
            self.audit(c,"node:"+nid,"HEARTBEAT",incarnation,{"seq":seq,"capabilities":caps}); c.commit()
        return {"node_id":nid,"state":"healthy","seq":seq}
    def create_task(self,kind,payload,requirements=None,priority=0,ttl=3600,max_attempts=3):
        if kind not in TASK_KINDS: raise ValueError("task kind is not allowlisted")
        if not isinstance(payload,dict) or len(canon(payload))>32768: raise ValueError("invalid task payload")
        tid=str(uuid.uuid4())
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); c.execute("INSERT INTO tasks VALUES(?,?,?,?,?,?,?, ?,NULL,NULL,0,?)",(tid,kind,canon(clean(payload)).decode(),canon(requirements or {}).decode(),"queued",int(priority),now(),time.time()+max(60,min(int(ttl),86400)),max(1,min(int(max_attempts),5))))
            self.audit(c,"owner","TASK_QUEUED",tid,{"kind":kind}); c.commit()
        return tid
    def lease_task(self,nid,seconds=120):
        t=time.time()
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); node=c.execute("SELECT * FROM nodes WHERE node_id=?",(nid,)).fetchone()
            if not node or node["state"]!="healthy" or t-node["last_seen"]>180: c.rollback(); raise ValueError("node heartbeat missing or stale")
            caps=json.loads(node["capabilities"])
            c.execute("UPDATE tasks SET state='queued',lease_node=NULL,lease_until=NULL WHERE state='leased' AND lease_until<? AND attempts<max_attempts",(t,))
            c.execute("UPDATE tasks SET state='expired' WHERE expires<? AND state IN ('queued','leased')",(t,))
            for r in c.execute("SELECT * FROM tasks WHERE state='queued' AND expires>? AND attempts<max_attempts ORDER BY priority DESC,created_at LIMIT 100",(t,)).fetchall():
                req=json.loads(r["requirements"])
                ok=all((caps.get(k[4:]) is not None and isinstance(caps.get(k[4:]),(int,float)) and caps[k[4:]]>=v) if k.startswith("min_") else caps.get(k)==v for k,v in req.items())
                if ok:
                    until=t+max(30,min(int(seconds),600)); c.execute("UPDATE tasks SET state='leased',lease_node=?,lease_until=?,attempts=attempts+1 WHERE task_id=?",(nid,until,r["task_id"]))
                    self.audit(c,"node:"+nid,"TASK_LEASED",r["task_id"],{"lease_until":until}); c.commit()
                    return {"task_id":r["task_id"],"kind":r["kind"],"payload":json.loads(r["payload"]),"lease_until":until,"attempt":r["attempts"]+1}
            c.commit()
        return None
    def receipt(self,tid,nid,state,result):
        if state not in {"succeeded","failed","blocked"}: raise ValueError("invalid receipt state")
        raw=canon(clean(result))
        if len(raw)>64000: raise ValueError("receipt too large")
        h=digest(raw); rid=str(uuid.uuid4())
        with self.db() as c:
            c.execute("BEGIN IMMEDIATE"); task=c.execute("SELECT * FROM tasks WHERE task_id=?",(tid,)).fetchone()
            if not task or task["state"]!="leased" or task["lease_node"]!=nid or task["lease_until"]<time.time(): c.rollback(); raise ValueError("task lease invalid or expired")
            c.execute("INSERT INTO receipts VALUES(?,?,?,?,?,?,?)",(rid,tid,nid,state,raw.decode(),h,now()))
            c.execute("UPDATE tasks SET state=?,lease_node=NULL,lease_until=NULL WHERE task_id=?",("completed" if state=="succeeded" else state,tid))
            self.audit(c,"node:"+nid,"TASK_RECEIPT",tid,{"state":state,"result_sha256":h}); c.commit()
        return {"receipt_id":rid,"task_id":tid,"state":state,"result_sha256":h}
    def snapshot(self):
        with self.db() as c:
            ps=[dict(r) for r in c.execute("SELECT provider_id,status,last_success,last_error,cursor,next_poll_at FROM provider_state ORDER BY provider_id")]
            ns=[dict(r) for r in c.execute("SELECT * FROM nodes ORDER BY node_id")]
            for n in ns: n["capabilities"]=json.loads(n.pop("capabilities"))
            counts={r["state"]:r["n"] for r in c.execute("SELECT state,COUNT(*) n FROM tasks GROUP BY state")}
            ev=c.execute("SELECT COUNT(*) FROM events").fetchone()[0]
        return {"version":VERSION,"as_of":now(),"providers":ps,"nodes":ns,"tasks":counts,"events":ev,"audit":self.verify()}

class HTTPSFeed:
    def __init__(self,spec):
        self.pid=ident(spec["id"]); u=urlparse(spec["endpoint"])
        if u.scheme!="https" or not u.hostname: raise ValueError("provider endpoint must use HTTPS")
        self.url=spec["endpoint"]; self.token_env=spec.get("token_env"); self.limit=max(1,min(int(spec.get("page_size",100)),250))
    def fetch(self,cursor):
        u=urlparse(self.url); q=parse_qs(u.query)
        if cursor: q["cursor"]=[cursor]
        q["limit"]=[str(self.limit)]
        headers={"Accept":"application/json","User-Agent":"GAIA-Sync-Fabric/"+VERSION}
        if self.token_env:
            token=os.getenv(self.token_env)
            if not token: raise ValueError("provider credential env var is missing")
            headers["Authorization"]="Bearer "+token
        with urlopen(Request(u._replace(query=urlencode(q,doseq=True)).geturl(),headers=headers),timeout=20) as r: body=r.read(1000001)
        if len(body)>1000000: raise ValueError("feed page too large")
        obj=json.loads(body)
        if not isinstance(obj,dict) or not isinstance(obj.get("items"),list) or len(obj["items"])>self.limit: raise ValueError("feed schema invalid")
        return obj["items"],obj.get("next_cursor")

def sync_once(f,config):
    cfg=json.loads(Path(config).read_text()); out=[]
    for spec in cfg.get("providers",[]):
        pid=ident(spec["id"])
        if spec.get("enabled") is not True: out.append({"provider":pid,"state":"disabled"}); continue
        run=f.start_run(pid,"sync-worker")
        if not run: out.append({"provider":pid,"state":"leased_or_backoff"}); continue
        try:
            items,cursor=HTTPSFeed(spec).fetch(run["cursor"]); n=f.commit_page(pid,run["run_id"],run["cursor"],cursor,items)
            out.append({"provider":pid,"state":"committed","received":len(items),"inserted":n})
        except Exception as e:
            f.fail_run(pid,run["run_id"],type(e).__name__); out.append({"provider":pid,"state":"failed","error_class":type(e).__name__})
    return out

def import_mesh(f,root,private):
    out={"receipts":0,"tdoc":0,"duplicates":0,"invalid":0}
    for p in (Path(root)/"devices").glob("*/receipts/*.json"):
        try:
            o=json.loads(p.read_text()); src=digest((str(o.get("packet_id",p.stem))+"\0"+str(o.get("receipt_sha256",digest(canon(o))))).encode())
            r=f.event("cryptic-mesh",src,"device_job_receipt",o,o.get("finished_utc"),{"source":"mesh-receipt"})
            out["receipts"]+=1; out["duplicates"]+=int(not r["inserted"])
        except Exception: out["invalid"]+=1
    for p in Path(private).glob("*/tdoc.jsonl"):
        dev=ident(p.parent.name)
        for line in p.read_text().splitlines():
            try:
                o=json.loads(line); src=digest((dev+"\0"+str(o.get("tdoc_id","entry"))+"\0"+str(o.get("entry_sha256",digest(canon(o))))).encode())
                r=f.event("cryptic-mesh",src,"device_tdoc_event",o,o.get("at_utc"),{"source":"private-tdoc"})
                out["tdoc"]+=1; out["duplicates"]+=int(not r["inserted"])
            except Exception: out["invalid"]+=1
    return out

def nonce_key(nid): return "GAIA_NODE_KEY_"+ident(nid).upper().replace("-","_")
def verify_node(nid,h,body):
    secret=os.getenv(nonce_key(nid)); stamp=h.get("X-GAIA-Timestamp",""); nonce=h.get("X-GAIA-Nonce",""); sig=h.get("X-GAIA-Signature","")
    if not secret or not ID.fullmatch(nonce): raise PermissionError("node authentication unavailable")
    try: ts=int(stamp)
    except ValueError: raise PermissionError("invalid timestamp")
    if abs(time.time()-ts)>300: raise PermissionError("stale request")
    want=hmac.new(secret.encode(),stamp.encode()+b"\n"+nonce.encode()+b"\n"+body,hashlib.sha256).hexdigest()
    if not hmac.compare_digest(want,sig): raise PermissionError("signature mismatch")
    return nonce

def use_nonce(f,nid,nonce):
    with f.db() as c:
        try: c.execute("INSERT INTO nonces VALUES(?,?,?)",(nid,nonce,time.time()))
        except sqlite3.IntegrityError: raise PermissionError("replayed nonce")
        c.execute("DELETE FROM nonces WHERE seen_at<?",(time.time()-86400,))

class API(BaseHTTPRequestHandler):
    fabric=None
    def log_message(self,fmt,*args): sys.stderr.write("[gaia-sync] "+fmt%args+"\n")
    def sendj(self,status,obj):
        b=canon(obj); self.send_response(status); self.send_header("Content-Type","application/json"); self.send_header("Cache-Control","no-store"); self.send_header("Content-Length",str(len(b))); self.end_headers(); self.wfile.write(b)
    def body(self,limit=128000):
        n=int(self.headers.get("Content-Length","0"))
        if n<1 or n>limit: raise ValueError("invalid body size")
        return self.rfile.read(n)
    def do_GET(self):
        if self.path=="/healthz": self.sendj(200,{"ok":True,"version":VERSION,"time":now()})
        elif self.path=="/v1/snapshot": self.sendj(200,self.fabric.snapshot())
        else: self.sendj(404,{"error":"not_found"})
    def do_POST(self):
        try:
            if self.path.startswith("/v1/webhooks/"):
                pid=ident(self.path.rsplit("/",1)[-1]); b=self.body(256000); secret=os.getenv("GAIA_WEBHOOK_"+pid.upper().replace("-","_")); stamp=self.headers.get("X-GAIA-Timestamp","")
                if not secret or abs(time.time()-int(stamp))>300: raise PermissionError("webhook auth unavailable or stale")
                sig=hmac.new(secret.encode(),stamp.encode()+b"."+b,hashlib.sha256).hexdigest()
                if not hmac.compare_digest(sig,self.headers.get("X-GAIA-Signature","")): raise PermissionError("webhook signature mismatch")
                o=json.loads(b); r=self.fabric.event(pid,str(o["id"]),str(o.get("type","update")),o.get("data",o),o.get("occurred_at"),{"transport":"signed-webhook"}); self.sendj(202,r); return
            if self.path=="/v1/nodes/heartbeat":
                b=self.body(32000); o=json.loads(b); nid=ident(o["node_id"]); nonce=verify_node(nid,self.headers,b); use_nonce(self.fabric,nid,nonce)
                self.sendj(200,self.fabric.heartbeat(nid,ident(o["incarnation_id"]),o.get("platform","unknown"),o.get("capabilities",{}),int(o["seq"]))); return
            if self.path=="/v1/tasks":
                token=os.getenv("GAIA_SYNC_ADMIN_TOKEN")
                if not token or not hmac.compare_digest(self.headers.get("Authorization",""),"Bearer "+token): raise PermissionError("admin authorization required")
                o=json.loads(self.body()); tid=self.fabric.create_task(o["kind"],o.get("payload",{}),o.get("requirements",{}),o.get("priority",0),o.get("ttl",3600),o.get("max_attempts",3)); self.sendj(201,{"task_id":tid,"state":"queued"}); return
            if self.path=="/v1/tasks/lease":
                b=self.body(); o=json.loads(b); nid=ident(o["node_id"]); nonce=verify_node(nid,self.headers,b); use_nonce(self.fabric,nid,nonce)
                self.sendj(200,{"task":self.fabric.lease_task(nid,o.get("lease_seconds",120))}); return
            if self.path.startswith("/v1/tasks/") and self.path.endswith("/receipt"):
                b=self.body(80000); o=json.loads(b); nid=ident(o["node_id"]); nonce=verify_node(nid,self.headers,b); use_nonce(self.fabric,nid,nonce)
                tid=self.path.split("/")[3]; self.sendj(201,self.fabric.receipt(tid,nid,o["state"],o.get("result",{}))); return
            self.sendj(404,{"error":"not_found"})
        except PermissionError as e: self.sendj(401,{"error":str(e)})
        except (ValueError,KeyError,TypeError,json.JSONDecodeError) as e: self.sendj(400,{"error":str(e)})
        except Exception as e: self.sendj(500,{"error_class":type(e).__name__})

def loop(f,config,interval):
    stop=False
    def halt(*_):
        nonlocal stop; stop=True
    signal.signal(signal.SIGTERM,halt); signal.signal(signal.SIGINT,halt)
    while not stop:
        print(json.dumps({"at":now(),"results":sync_once(f,config)}),flush=True)
        for _ in range(max(15,min(interval,3600))):
            if stop: break
            time.sleep(1)

def main():
    p=argparse.ArgumentParser(description="GAIA Sync Fabric v1"); p.add_argument("--db",default=str(DEFAULT_DB)); sub=p.add_subparsers(dest="cmd",required=True)
    sub.add_parser("init"); sub.add_parser("status"); sub.add_parser("verify")
    s=sub.add_parser("sync-once"); s.add_argument("--config",required=True)
    s=sub.add_parser("sync-loop"); s.add_argument("--config",required=True); s.add_argument("--interval",type=int,default=60)
    s=sub.add_parser("ingest-mesh"); s.add_argument("--root",default=str(Path.home()/"Æ/cryptic-device-mesh")); s.add_argument("--private-root",default=str(Path.home()/".config/cryptic-device-mesh"))
    s=sub.add_parser("serve"); s.add_argument("--host",default="127.0.0.1"); s.add_argument("--port",type=int,default=8787)
    a=p.parse_args(); f=Fabric(a.db)
    if a.cmd=="init": print(json.dumps({"db":str(f.path),"schema":1,"state":"initialized"},indent=2))
    elif a.cmd=="status": print(json.dumps(f.snapshot(),indent=2))
    elif a.cmd=="verify": print(json.dumps(f.verify(),indent=2))
    elif a.cmd=="sync-once": print(json.dumps(sync_once(f,a.config),indent=2))
    elif a.cmd=="sync-loop": loop(f,a.config,a.interval)
    elif a.cmd=="ingest-mesh": print(json.dumps(import_mesh(f,a.root,a.private_root),indent=2))
    elif a.cmd=="serve":
        if a.host not in {"127.0.0.1","::1","localhost"} and os.getenv("GAIA_SYNC_ALLOW_PRIVATE_BIND")!="1": raise SystemExit("non-loopback bind refused; use authenticated TLS gateway")
        API.fabric=f; ThreadingHTTPServer((a.host,a.port),API).serve_forever()

if __name__=="__main__": main()
