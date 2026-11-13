# [TDOC][GAIASWINDOW-GITHUB-CYCLE-V5.2]
# VERSION: 5.2.0
# MODE: Repository-first / evidence-first
# SYNC: Git pull (ff-only) / reviewed push / ADAM PR

GAIASWINDOW uses the official Node/npm distributions for Gemini CLI and Codex CLI, and the official Windows Ollama installation through winget. A bare curl command is **not** a universally supported Windows Codex installer and should not be used for arbitrary remote script execution. Codex and Gemini are launched as `codex` and `gemini` after installation; Windows npm usually generates `.cmd` shims.

## Canonical GAIASWINDOW pull-to-execute cycle

Run from PowerShell. This block does not create, overwrite or reset a repository and does not push private machine information.

```powershell
# [TDOC][GAIASWINDOW-GITHUB-CYCLE-V5.2] SOURCE=GITHUB VERIFIED_BRANCH=feature/adam-public-factory-v5
$ErrorActionPreference='Stop'
$repo=Join-Path $env:USERPROFILE 'GAIA\src\Gaia-The-Nexus-Generation'
if(!(Test-Path (Join-Path $repo '.git'))){throw 'GAIA repository missing; finish bootstrap first'}
if(@(git -C $repo status --porcelain).Count -ne 0){throw 'Working tree has changes; no automatic overwrite'}
git -C $repo fetch origin feature/adam-public-factory-v5
if($LASTEXITCODE -ne 0){throw 'Fetch failed'}
git -C $repo switch feature/adam-public-factory-v5
if($LASTEXITCODE -ne 0){git -C $repo switch --track origin/feature/adam-public-factory-v5}
if($LASTEXITCODE -ne 0){throw 'Switch failed'}
git -C $repo pull --ff-only origin feature/adam-public-factory-v5
if($LASTEXITCODE -ne 0){throw 'Pull failed'}
& (Join-Path $repo 'scripts\windows\GAIASWINDOW-GITHUB-MESH-v5.2.ps1')
```

After verified execution, pass `-RegisterTask` to schedule hourly **local** validation. Pass `-Publish` only when an authenticated GitHub CLI and a clean, reviewed feature-branch checkout are available. This uploads a minimal allowlisted public status JSON, never complete environment variables or PATH entries.

Read-only evidence stays in `%USERPROFILE%\GAIA\state`; it is not part of Git. The repository also hosts only public runtime interfaces and CI workflows. Private recovery materials and Netgear profiles remain in a separate private trust boundary.

## Codex iteration

Run `codex` from the clean feature-branch directory. Review the agent's diff; run tests; commit only selected paths; push; update the PR. Avoid making every local agent execution an automatic public commit.

## Implementation gates

Official installation verified by executable version; local status generated; sanitized GitHub report optional; CI evaluates proposed changes; reviewer approves promotion to main. This does not claim production deployment or remote command access.
