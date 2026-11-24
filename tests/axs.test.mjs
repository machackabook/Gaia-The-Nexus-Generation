import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { fileURLToPath } from "node:url";
import {
  AXIR_SCHEMA, VERSION, tokenize, parseCommand, gcd, lcm, modInverse,
  sha256, buildPackagePlan, executeBackend, runtimeManifest, quineSource
} from "../setup/omega/axs.mjs";

test("recognizes the longest PIPETHRUUC operator first", () => {
  const operators = tokenize("a <-- b > out < in | c")
    .filter(token => token.kind === "operator")
    .map(token => token.value);
  assert.deepEqual(operators, ["<--", ">", "<", "|"]);
});

test("preserves raw input and builds a canonical pipeline", () => {
  const input = "python::print('gaia') | node --version";
  const ir = parseCommand(input, { id: "test-id", createdAt: "2026-01-01T00:00:00.000Z" });
  assert.equal(ir.schema, AXIR_SCHEMA);
  assert.equal(ir.id, "test-id");
  assert.equal(ir.source.raw, input);
  assert.equal(ir.source.language, "python");
  assert.equal(ir.pipeline.length, 2);
  assert.deepEqual(ir.operators.map(item => item.value), ["|"]);
});

test("rejects an unclosed quote", () => {
  assert.throws(() => tokenize("python::print('unterminated"), /parse_unclosed_quote/);
});

test("BigInt arithmetic is exact", () => {
  assert.equal(gcd("12345678901234567890", "90"), 90n);
  assert.equal(lcm("21", "6"), 42n);
  assert.equal(modInverse("3", "11"), 4n);
  assert.equal(modInverse("6", "9"), null);
});

test("SHA-256 uses the standard UTF-8 digest", () => {
  assert.equal(
    sha256("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  );
});

test("package plans are argument vectors and reject shell syntax", () => {
  const plan = buildPackagePlan("npm", "@scope/example");
  assert.deepEqual(plan.args, ["install", "--global", "@scope/example"]);
  assert.equal(plan.execution, "plan_only");
  assert.throws(() => buildPackagePlan("npm", "pkg;rm -rf"), /package_name_invalid/);
});

test("native execution is fail-closed without explicit opt-in", () => {
  assert.throws(
    () => executeBackend("node", ["--version"], { env: { AXS_ENABLE_NATIVE_EXEC: "0", AXS_EXEC_BACKENDS: "node" } }),
    /native_execution_disabled/
  );
  assert.throws(
    () => executeBackend("node", ["--version"], { env: { AXS_ENABLE_NATIVE_EXEC: "1", AXS_EXEC_BACKENDS: "python" } }),
    /native_backend_not_granted/
  );
});

test("manifest advertises explicit boundaries", () => {
  const manifest = runtimeManifest();
  assert.equal(manifest.version, VERSION);
  assert.equal(manifest.shebang_required, false);
  assert.equal(manifest.native_execution, "disabled_by_default");
  assert.equal(manifest.package_installation, "plan_only_by_default");
});

test("quine source is byte-for-byte the executing source file", () => {
  const ownPath = fileURLToPath(new URL("../setup/omega/axs.mjs", import.meta.url));
  assert.equal(quineSource(), fs.readFileSync(ownPath, "utf8"));
});
