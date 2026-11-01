import { strict as a } from "node:assert";
import { canonicalJson,artifactDigest,seedDigest,nextEventDigest } from "../src/integrity.js";
const x={z:2,a:{y:1,x:true}}, y={a:{x:true,y:1},z:2};
a.equal(canonicalJson(x),canonicalJson(y)); a.equal(artifactDigest(x),artifactDigest(y));
a.match(seedDigest(),/^[0-9a-f]{64}$/); a.notEqual(artifactDigest({n:1}),artifactDigest({n:2}));
const h="0".repeat(64); a.equal(nextEventDigest(h,{k:1}),nextEventDigest(h,{k:1}));
a.notEqual(nextEventDigest(h,{k:1}),nextEventDigest(h,{k:2}));
console.log("Local integrity assertions pass when executed.");
