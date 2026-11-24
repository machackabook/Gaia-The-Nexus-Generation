# AE.AXS Polyglot Kernel v0.1.0

Status: implemented kernel foundation; cross-platform production coverage remains pending.

## Invocation

The source has no shebang. Invoke it through an installed Node runtime:

```sh
node setup/omega/axs.mjs doctor
node setup/omega/axs.mjs parse "python::print('hello') | node --version"
node setup/omega/axs.mjs math gcd 12345678901234567890 90
node setup/omega/axs.mjs hash "GAIA NEXUS"
node setup/omega/axs.mjs pkg list
node setup/omega/axs.mjs pkg plan npm @scope/example
node setup/omega/axs.mjs manifest
node setup/omega/axs.mjs quine
```

## Canonical representation

The parser emits `AE.AXIR/1`, retaining the original source string, detected language prefix, source offsets, tokens, pipeline stages, operators, and required capabilities. It recognizes `<--` before `<` and `>`, preserving the PIPETHRUUC distinction.

## Native semantics and security

This kernel does not pretend that Bash, PowerShell, Python, SQL, or package managers have interchangeable semantics. It preserves the selected native backend and routes through explicit argument vectors.

- Native execution is disabled unless `AXS_ENABLE_NATIVE_EXEC=1` and the backend is listed in `AXS_EXEC_BACKENDS`.
- Package installation is disabled unless `AXS_ENABLE_PACKAGE_INSTALL=1` and the caller supplies `--confirm`.
- Package plans use argument arrays and `shell:false`; they are not evaluated as shell text.
- `pkg plan` is read-only and does not install anything.
- The runtime has no network access and no third-party dependencies.

## Package-manager federation

The discovery catalog covers Windows (WinGet, Chocolatey, Scoop), macOS (Homebrew, MacPorts), Linux families (APT/dpkg, DNF/YUM, Pacman, Zypper, APK, Portage, Nix, Guix, Flatpak, Snap), BSD (pkg, pkgin), Android/Termux (pkg/apt), and language ecosystems (pip, uv, Poetry, PDM, Conda/Mamba, npm/pnpm/Yarn/Bun, Cargo, Go, RubyGems, Composer, .NET, Maven, Gradle, R, and Wolfram).

Discovery reports only commands actually present on the current host. It does not claim that a manager is installed merely because the operating system supports it.

## Mathematical kernel

Exact BigInt GCD, LCM, modular inverse, and SHA-256 are implemented without external dependencies. Additional symbolic and numerical engines remain provider adapters, not silently substituted implementations.

## Verification

Run:

```sh
node --test tests/axs.test.mjs
```

The test suite checks token precedence, source preservation, exact arithmetic, SHA-256, package-plan validation, fail-closed execution, manifest boundaries, and exact self-source reproduction.

This release is a working kernel foundation, not yet a universal binary, full interpreter for every language, or proof that every package manager has been exercised on every operating system.
