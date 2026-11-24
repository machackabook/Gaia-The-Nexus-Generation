import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { createHash, randomUUID } from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

export const VERSION = "0.1.0";
export const AXIR_SCHEMA = "AE.AXIR/1";

const MANAGERS = [
  ["winget", "winget", ["win32"], "system"],
  ["choco", "choco", ["win32"], "system"],
  ["scoop", "scoop", ["win32"], "system"],
  ["brew", "brew", ["darwin"], "system"],
  ["port", "port", ["darwin"], "system"],
  ["apt", "apt", ["linux", "android"], "system"],
  ["dpkg", "dpkg", ["linux", "android"], "system"],
  ["dnf", "dnf", ["linux"], "system"],
  ["yum", "yum", ["linux"], "system"],
  ["pacman", "pacman", ["linux"], "system"],
  ["zypper", "zypper", ["linux"], "system"],
  ["apk", "apk", ["linux"], "system"],
  ["emerge", "emerge", ["linux"], "system"],
  ["nix", "nix", ["linux", "darwin"], "system"],
  ["guix", "guix", ["linux"], "system"],
  ["flatpak", "flatpak", ["linux"], "system"],
  ["snap", "snap", ["linux"], "system"],
  ["pkg", "pkg", ["freebsd", "android"], "system"],
  ["pkgin", "pkgin", ["netbsd"], "system"],
  ["pip", "pip", ["all"], "language"],
  ["uv", "uv", ["all"], "language"],
  ["poetry", "poetry", ["all"], "language"],
  ["pdm", "pdm", ["all"], "language"],
  ["conda", "conda", ["all"], "language"],
  ["mamba", "mamba", ["all"], "language"],
  ["npm", "npm", ["all"], "language"],
  ["pnpm", "pnpm", ["all"], "language"],
  ["yarn", "yarn", ["all"], "language"],
  ["bun", "bun", ["all"], "language"],
  ["cargo", "cargo", ["all"], "language"],
  ["go", "go", ["all"], "language"],
  ["gem", "gem", ["all"], "language"],
  ["composer", "composer", ["all"], "language"],
  ["dotnet", "dotnet", ["all"], "language"],
  ["mvn", "mvn", ["all"], "language"],
  ["gradle", "gradle", ["all"], "language"],
  ["Rscript", "Rscript", ["all"], "language"],
  ["wolframscript", "wolframscript", ["all"], "language"]
].map(([id, command, platforms, scope]) => ({ id, command, platforms, scope }));

const BACKENDS = {
  node: ["node"],
  python: ["python3", "python"],
  python3: ["python3"],
  bash: ["bash"],
  pwsh: ["pwsh"],
  powershell: ["powershell"],
  sqlite3: ["sqlite3"],
  wolframscript: ["wolframscript"]
};

const PACKAGE_ARGS = {
  winget: p => ["install", "--id", p, "--exact"],
  choco: p => ["install", p, "-y"],
  scoop: p => ["install", p],
  brew: p => ["install", p],
  port: p => ["install", p],
  apt: p => ["install", p],
  dpkg: p => ["--install", p],
  dnf: p => ["install", "-y", p],
  yum: p => ["install", "-y", p],
  pacman: p => ["-S", "--noconfirm", p],
  zypper: p => ["install", "-y", p],
  apk: p => ["add", p],
  emerge: p => ["--ask", p],
  nix: p => ["profile", "install", "nixpkgs#" + p],
  guix: p => ["install", p],
  flatpak: p => ["install", "--user", "flathub", p],
  snap: p => ["install", p],
  pkg: p => ["install", p],
  pkgin: p => ["install", p],
  pip: p => ["install", p],
  uv: p => ["tool", "install", p],
  poetry: p => ["add", p],
  pdm: p => ["add", p],
  conda: p => ["install", p],
  mamba: p => ["install", p],
  npm: p => ["install", "--global", p],
  pnpm: p => ["add", "--global", p],
  yarn: p => ["global", "add", p],
  bun: p => ["add", "--global", p],
  cargo: p => ["install", p],
  go: p => ["install", p],
  gem: p => ["install", p],
  composer: p => ["global", "require", p],
  dotnet: p => ["tool", "install", "--global", p],
  mvn: p => ["--version"],
  gradle: p => ["--version"],
  Rscript: p => ["-e", "install.packages('" + p + "')"],
  wolframscript: p => ["-code", 'PacletInstall["' + p + '"]']
};

function platformName(platform = process.platform, env = process.env) {
  if (platform === "android" || env.TERMUX_VERSION || String(env.PREFIX || "").includes("/com.termux/")) return "android";
  if (platform === "win32") return "win32";
  if (platform === "darwin") return "darwin";
  if (platform === "freebsd") return "freebsd";
  if (platform === "netbsd") return "netbsd";
  return "linux";
}

export function findExecutable(command, env = process.env, platform = process.platform) {
  const dirs = String(env.PATH || "").split(path.delimiter).filter(Boolean);
  const suffixes = platform === "win32"
    ? String(env.PATHEXT || ".EXE;.CMD;.BAT").split(";")
    : [""];
  for (const dir of dirs) {
    for (const suffix of suffixes) {
      const candidate = path.join(dir, command + suffix);
      try {
        const stat = fs.statSync(candidate);
        if (!stat.isFile()) continue;
        if (platform !== "win32") fs.accessSync(candidate, fs.constants.X_OK);
        return candidate;
      } catch {}
    }
  }
  return null;
}

export function detectPackageManagers(options = {}) {
  const env = options.env || process.env;
  const platform = platformName(options.platform || process.platform, env);
  return MANAGERS
    .filter(manager => manager.platforms.includes("all") || manager.platforms.includes(platform))
    .map(manager => ({ ...manager, path: findExecutable(manager.command, env, options.platform || process.platform) }))
    .map(manager => ({ ...manager, available: Boolean(manager.path) }));
}

function validPackageName(value) {
  return typeof value === "string" &&
    /^[A-Za-z0-9@][A-Za-z0-9@._/+:-]{0,127}$/.test(value);
}

export function buildPackagePlan(managerId, packageName) {
  if (!validPackageName(packageName)) throw new Error("package_name_invalid");
  const manager = MANAGERS.find(item => item.id === managerId);
  const buildArgs = PACKAGE_ARGS[managerId];
  if (!manager || !buildArgs) throw new Error("package_manager_unsupported");
  return {
    manager: manager.id,
    command: manager.command,
    args: buildArgs(packageName),
    package: packageName,
    execution: "plan_only",
    requires: ["AXS_ENABLE_PACKAGE_INSTALL=1", "--confirm"]
  };
}

export function tokenize(input) {
  const source = String(input);
  const tokens = [];
  let value = "";
  let start = 0;
  let quote = null;
  let quoted = false;
  const flush = end => {
    if (value.length) tokens.push({ kind: "word", value, start, end, quoted });
    value = "";
    quoted = false;
  };
  for (let i = 0; i < source.length;) {
    const ch = source[i];
    if (quote) {
      if (ch === "\\" && i + 1 < source.length) {
        value += source[i + 1];
        i += 2;
        continue;
      }
      if (ch === quote) {
        quote = null;
        i += 1;
        continue;
      }
      value += ch;
      i += 1;
      continue;
    }
    if (/\s/.test(ch)) {
      flush(i);
      i += 1;
      continue;
    }
    if (source.startsWith("<--", i)) {
      flush(i);
      tokens.push({ kind: "operator", value: "<--", start: i, end: i + 3 });
      i += 3;
      start = i;
      continue;
    }
    if (ch === "|" || ch === ">" || ch === "<") {
      flush(i);
      tokens.push({ kind: "operator", value: ch, start: i, end: i + 1 });
      i += 1;
      start = i;
      continue;
    }
    if (ch === "'" || ch === '"') {
      if (!value.length) start = i;
      quote = ch;
      quoted = true;
      i += 1;
      continue;
    }
    if (!value.length) start = i;
    value += ch;
    i += 1;
  }
  if (quote) throw new Error("parse_unclosed_quote");
  flush(source.length);
  return tokens;
}

export function parseCommand(input, options = {}) {
  const raw = String(input);
  const match = /^([A-Za-z][A-Za-z0-9_-]*)::/.exec(raw);
  const language = match ? match[1].toLowerCase() : "axs";
  const body = match ? raw.slice(match[0].length) : raw;
  const tokens = tokenize(body);
  const pipeline = [];
  let stage = [];
  for (const token of tokens) {
    if (token.kind === "operator" && token.value === "|") {
      pipeline.push(stage);
      stage = [];
    } else {
      stage.push(token);
    }
  }
  if (stage.length) pipeline.push(stage);
  const operators = tokens.filter(token => token.kind === "operator");
  return {
    schema: AXIR_SCHEMA,
    id: options.id || randomUUID(),
    created_at: options.createdAt || new Date().toISOString(),
    source: { raw, language, body },
    tokens,
    pipeline,
    operators,
    required_capabilities: language === "axs" ? [] : ["native.exec." + language]
  };
}

export function gcd(a, b) {
  let x = BigInt(a), y = BigInt(b);
  x = x < 0n ? -x : x;
  y = y < 0n ? -y : y;
  while (y !== 0n) [x, y] = [y, x % y];
  return x;
}

export function lcm(a, b) {
  const x = BigInt(a), y = BigInt(b);
  if (x === 0n || y === 0n) return 0n;
  const result = (x / gcd(x, y)) * y;
  return result < 0n ? -result : result;
}

export function modInverse(a, modulus) {
  const m = BigInt(modulus);
  if (m <= 1n) throw new Error("modulus_invalid");
  let oldR = ((BigInt(a) % m) + m) % m, r = m;
  let oldS = 1n, s = 0n;
  while (r !== 0n) {
    const q = oldR / r;
    [oldR, r] = [r, oldR - q * r];
    [oldS, s] = [s, oldS - q * s];
  }
  if (oldR !== 1n) return null;
  return ((oldS % m) + m) % m;
}

export function sha256(value) {
  return createHash("sha256").update(String(value), "utf8").digest("hex");
}

export function runtimeManifest() {
  return {
    schema: "AE.AXS.MANIFEST/1",
    name: "AE.AXS Polyglot Kernel",
    version: VERSION,
    entrypoint: "setup/omega/axs.mjs",
    invocation: "node setup/omega/axs.mjs",
    shebang_required: false,
    dependencies: [],
    intermediate_representation: AXIR_SCHEMA,
    capabilities: ["parse", "math.bigint", "hash.sha256", "package.discovery", "package.plan", "self.source"],
    native_execution: "disabled_by_default",
    package_installation: "plan_only_by_default",
    backends: Object.keys(BACKENDS),
    semantics: "Native backend semantics are preserved; this kernel routes and records rather than pretending languages are interchangeable."
  };
}

export function executeBackend(backend, args, options = {}) {
  const env = options.env || process.env;
  if (env.AXS_ENABLE_NATIVE_EXEC !== "1") throw new Error("native_execution_disabled");
  const grants = String(env.AXS_EXEC_BACKENDS || "").split(",").map(x => x.trim()).filter(Boolean);
  if (!grants.includes(backend)) throw new Error("native_backend_not_granted");
  const candidates = BACKENDS[backend];
  if (!candidates) throw new Error("native_backend_unsupported");
  const executable = backend === "node" ? process.execPath : candidates.map(name => findExecutable(name, env, options.platform || process.platform)).find(Boolean);
  if (!executable) throw new Error("native_backend_unavailable");
  const result = spawnSync(executable, args, {
    cwd: options.cwd || process.cwd(),
    env,
    encoding: "utf8",
    shell: false,
    timeout: options.timeout || 30000,
    maxBuffer: 1024 * 1024,
    stdio: options.stdio || "inherit"
  });
  if (result.error) throw result.error;
  return typeof result.status === "number" ? result.status : 1;
}

export function executePackagePlan(managerId, packageName, options = {}) {
  const env = options.env || process.env;
  if (env.AXS_ENABLE_PACKAGE_INSTALL !== "1") throw new Error("package_install_disabled");
  if (options.confirm !== true) throw new Error("package_install_confirmation_required");
  const plan = buildPackagePlan(managerId, packageName);
  const detected = detectPackageManagers({ env, platform: options.platform || process.platform });
  const manager = detected.find(item => item.id === managerId);
  if (!manager || !manager.available) throw new Error("package_manager_unavailable");
  const result = spawnSync(manager.path, plan.args, {
    cwd: options.cwd || process.cwd(),
    env,
    encoding: "utf8",
    shell: false,
    timeout: options.timeout || 120000,
    maxBuffer: 1024 * 1024,
    stdio: options.stdio || "inherit"
  });
  if (result.error) throw result.error;
  return typeof result.status === "number" ? result.status : 1;
}

export function quineSource() {
  return fs.readFileSync(fileURLToPath(import.meta.url), "utf8");
}

function json(value) {
  process.stdout.write(JSON.stringify(value, (_, item) => typeof item === "bigint" ? item.toString() : item, 2) + "\n");
}

function help() {
  process.stdout.write([
    "AE.AXS " + VERSION + " — shebang-free polyglot kernel",
    "doctor                         detect runtime and package managers",
    "parse <language::>command      emit canonical AXIR",
    "math gcd|lcm|modinv A B [M]    exact BigInt arithmetic",
    "hash <text>                    SHA-256 UTF-8 digest",
    "pkg list                       discover native package managers",
    "pkg plan <manager> <package>   print a native install plan",
    "pkg apply --confirm <manager> <package>  explicit opt-in installation",
    "manifest                       print runtime manifest",
    "quine                          print this exact source file",
    "exec <backend> -- <args...>    opt-in native backend dispatch",
    "Native exec requires AXS_ENABLE_NATIVE_EXEC=1 and AXS_EXEC_BACKENDS=<backend>.",
    "Package install requires AXS_ENABLE_PACKAGE_INSTALL=1 and --confirm."
  ].join("\n") + "\n");
}

export function main(argv = process.argv.slice(2), env = process.env) {
  const [command, ...rest] = argv;
  try {
    if (!command || command === "help" || command === "--help") {
      help();
      return 0;
    }
    if (command === "version") {
      process.stdout.write(VERSION + "\n");
      return 0;
    }
    if (command === "manifest") {
      json(runtimeManifest());
      return 0;
    }
    if (command === "doctor") {
      json({
        schema: "AE.AXS.DOCTOR/1",
        runtime: "node",
        version: VERSION,
        node: process.version,
        platform: platformName(process.platform, env),
        kernel_platform: process.platform,
        architecture: os.arch(),
        release: os.release(),
        managers: detectPackageManagers({ env, platform: process.platform })
      });
      return 0;
    }
    if (command === "parse") {
      json(parseCommand(rest.join(" ")));
      return 0;
    }
    if (command === "hash") {
      process.stdout.write(sha256(rest.join(" ")) + "\n");
      return 0;
    }
    if (command === "math") {
      const [op, a, b, c] = rest;
      if (op === "gcd") json({ operation: op, result: gcd(a, b) });
      else if (op === "lcm") json({ operation: op, result: lcm(a, b) });
      else if (op === "modinv") json({ operation: op, result: modInverse(a, b) });
      else throw new Error("math_operation_unsupported");
      return 0;
    }
    if (command === "pkg") {
      const [action, manager, packageName, extra] = rest;
      if (action === "list") {
        json(detectPackageManagers({ env, platform: process.platform }));
        return 0;
      }
      if (action === "plan") {
        json(buildPackagePlan(manager, packageName));
        return 0;
      }
      if (action === "apply") {
        const confirmed = manager === "--confirm";
        const actualManager = confirmed ? packageName : manager;
        const actualPackage = confirmed ? extra : packageName;
        const status = executePackagePlan(actualManager, actualPackage, { env, confirm: confirmed });
        return status;
      }
      throw new Error("package_action_unsupported");
    }
    if (command === "exec") {
      const backend = rest.shift();
      const args = rest[0] === "--" ? rest.slice(1) : rest;
      return executeBackend(backend, args, { env });
    }
    if (command === "quine") {
      process.stdout.write(quineSource());
      return 0;
    }
    throw new Error("command_unsupported");
  } catch (error) {
    process.stderr.write(JSON.stringify({ ok: false, error: error.message || "axs_error" }) + "\n");
    return 2;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = main();
}
