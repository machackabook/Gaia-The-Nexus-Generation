# GAIA Cross-Platform App Factory v1

This directory defines a reproducible mobile application build pipeline for Android and Apple platforms.

## Current toolchain

- Android Gradle Plugin: 9.4.0
- Gradle: 9.6.0
- JDK: 17
- Android compile/target SDK: 37
- Android Build Tools: 36.0.0
- GitHub Ubuntu runner for Android
- GitHub macOS 26 runner with Xcode 26.6 for Apple builds

## Pipeline

```text
SOURCE
  |
  +--> Android Gate --> lint --> unit tests --> assembleDebug --> APK --> SHA-256
  |
  +--> Apple Gate   --> XcodeGen --> xcodebuild --> Simulator .app --> SHA-256
  |
  +--> build-manifest + immutable CI evidence
```

No signing secrets are committed. Android debug signing is ephemeral. Apple builds are unsigned simulator builds by default.

Production Android signing should use encrypted GitHub Actions secrets or an external KMS. Production iOS/iPadOS distribution requires an Apple Developer signing identity and provisioning profile.

## Local use

The factory is designed so the same projects can be built locally when the matching SDK is available. CI remains the reproducible reference path.

## Security

- No credentials in source.
- No embedded API keys.
- No automatic device control.
- Build artifacts are hashed.
- CI logs form the evidence record for each build.
