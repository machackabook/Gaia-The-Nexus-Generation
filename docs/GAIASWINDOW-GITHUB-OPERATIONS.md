# GAIASWINDOW GitHub and Codex workflow

This document is the public engineering interface, not a source of credentials or private network configuration.

## Initial authentication

From PowerShell (not Bash):

```powershell
gh auth login --web
gh auth status
git --version
codex --version
```

Use interactive sign-in for Codex via `codex login` when needed. Do not place API keys in command history or repository files.

## Daily evidence-first procedure

The following is one copy-pasteable PowerShell block. It preserves uncommitted work and never uses destructive reset or forced push.

```powershell
$ErrorActionPreference = 'Stop'
$repo = Join-Path $env:USERPROFILE 'GAIA\src\Gaia-The-Nexus-Generation'
if (-not (Test-Path (Join-Path $repo '.git'))) { throw "Repository not found: $repo" }
git -C $repo fetch origin --prune
if ($LASTEXITCODE -ne 0) { throw 'Fetch failed' }
$status = @(git -C $repo status --porcelain)
if ($status.Count -gt 0) { throw 'Local edits exist; review or commit them before syncing' }
git -C $repo switch main
if ($LASTEXITCODE -ne 0) { throw 'Branch switch failed' }
git -C $repo pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'Fast-forward pull failed' }
$branch = 'feature/gaia-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
git -C $repo switch -c $branch
if ($LASTEXITCODE -ne 0) { throw 'Feature branch creation failed' }
Set-Location $repo
Write-Host "Development branch: $branch"
Write-Host 'Use: codex'
Write-Host 'Once changes are reviewed:'
Write-Host '  git status --short'
Write-Host '  git diff --check'
Write-Host '  git add -- <reviewed-paths>'
Write-Host '  git commit -m "feat: descriptive change"'
Write-Host '  git push -u origin HEAD'
Write-Host '  gh pr create --base main --fill'
```

Never substitute `git add .` for reviewed path selection when working in the public repository. Review every staged diff for secret material before pushing.

## Pull request production gate

ADAM Public Gate runs on pull requests and main pushes. The Pages deployment runs only after a main push affecting docs or a manual invocation. Both use restricted repository permissions; no private runner, server, or local network is exposed.

In repository settings, enable Pages with **GitHub Actions** as the build source, configure the `github-pages` environment, protect main with required reviews/status checks, and restrict Actions to trusted sources. GitHub's environment and branch-protection settings must be configured by an authorized administrator; a workflow file alone does not enforce them.

## Security boundaries

- The GitHub Actions token remains ephemeral and job-scoped.
- No long-lived personal access token in YAML.
- No direct GitHub-to-Netgear or public-to-private network connection.
- Never publish recovery codes, proprietary .sparsebundle content, personal files, or configuration exports.
- Gitleaks and policy checks are helpful detection layers, not proof that all repository history is free of secrets.
- A CSP meta element cannot enforce `frame-ancestors`; use a hosting-layer response header where that protection is required.

## ADAM pipeline

DISCOVER → OBSERVE → NORMALIZE → CLASSIFY → VERIFY → FINGERPRINT → LOOKUP_REMEDY → APPLY_REMEDY → REVERIFY.

Automated public checks implement only a subset of these gates. A successful CI check must not be labeled full ADAM production certification. Promote only with explicit evidence and review.
