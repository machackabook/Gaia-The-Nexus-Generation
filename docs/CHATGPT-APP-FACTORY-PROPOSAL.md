# Proposal: First-Class Mobile App Build Toolchains in ChatGPT Work

## Summary

Provide an opt-in, isolated build capability that lets ChatGPT Work turn generated Android and Apple source projects into verifiable application artifacts.

## User value

A coding session could move through one continuous loop:

```text
SPECIFY -> GENERATE -> COMPILE -> TEST -> VERIFY -> ARTIFACT
```

For Android this means a pinned JDK, Android SDK, AGP and Gradle environment. For Apple platforms it means a macOS build worker with a selectable Xcode toolchain.

## Safety and trust model

- Toolchains are isolated from the user's devices by default.
- Application signing keys are never generated or retained silently.
- Release signing requires explicit user configuration.
- Build network access can be constrained.
- Build logs, compiler versions and artifact hashes are returned as evidence.
- Installation to physical devices remains an explicit authorized action.
- No credential material is written into generated repositories.

## Proposed surfaces

1. **Build Android APK/AAB**
2. **Build iOS/iPadOS simulator app**
3. **Run lint/tests**
4. **Inspect compiler diagnostics**
5. **Return signed hashes and SBOM/provenance**
6. **Optional remote-device installation after explicit authorization**

## Reference implementation

This repository's `factory/` directory demonstrates the model using GitHub-hosted Ubuntu and macOS builders. It is intentionally CI-native so the toolchain can be recreated instead of depending on hidden machine state.

## Quality-of-service objective

The main improvement is closure of the coding loop. Source generation is useful; source generation plus deterministic compilation and evidence is substantially more useful for production application work.
