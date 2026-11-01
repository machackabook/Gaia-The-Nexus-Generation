/** TDOC-10428 hash reference primitives. Node.js; illustrative, not a production signature/transaction system. */
import { createHash } from "node:crypto";
const sha=(b:Buffer|string)=>createHash("sha256").update(b).digest("hex");
export function canonicalJson(v:any):string {
 if(v===null||typeof v!=="object") return JSON.stringify(v);
 if(Array.isArray(v)) return `[${v.map(canonicalJson).join(",")}]`;
 return `{${Object.keys(v).sort().map(k=>`${JSON.stringify(k)}:${canonicalJson(v[k])}`).join(",")}}`;
}
export const artifactDigest=(v:unknown)=>sha(Buffer.concat([Buffer.from("GAIA:ARTIFACT:v1\0"),Buffer.from(canonicalJson(v))]));
export const seedDigest=()=>sha(Buffer.concat([Buffer.from("GAIA:TDOC-SEED:v1\0"),Buffer.from("TDOC-10428|GAIA-NATIVE-AGENT|2026-10-31")]));
export function nextEventDigest(prev:string,event:unknown) {
 if(!/^[0-9a-f]{64}$/.test(prev)) throw new Error("expected SHA-256 hex");
 return sha(Buffer.concat([Buffer.from("GAIA:EVENT:v1\0"),Buffer.from(prev,"hex"),Buffer.from(canonicalJson(event))]));
}
