# [TDOC][GAIASWINDOW-GITHUB-MESH-V5.2]
# TDOC-ID: GAIASWINDOW-GITHUB-MESH-20261010
# NODE: GAIASWINDOW
# PHASE: DISCOVER > VERIFY > FINGERPRINT > REMEDY > REVERIFY > SYNC
# PURPOSE: Maintain standard Gemini, Codex, Ollama and bounded GitHub reporting.
# SAFETY: public report is allowlisted; no paths, usernames, IPs, tokens, or router state.
# VERSION: 5.2.0
# EXECUTION: PowerShell 5.1+; invoke from a trusted checked-out Git repository.
[CmdletBinding()]
param(
 [switch]$Publish,
 [switch]$RegisterTask
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Root = Join-Path $env:USERPROFILE 'GAIA'
$State = Join-Path $Root 'state'
$Logs = Join-Path $Root 'logs'
foreach($d in @($State,$Logs)){[void](New-Item -ItemType Directory -Force -Path $d)}
$Log = Join-Path $Logs 'tdoc-github-mesh.jsonl'
function Event([string]$kind,[object]$data){
  $record = [ordered]@{utc=[DateTime]::UtcNow.ToString('o');event=$kind;data=$data}
  Add-Content -LiteralPath $Log -Value ($record | ConvertTo-Json -Depth 5 -Compress)
}
function Require([string]$name){
  $r = Get-Command $name -ErrorAction SilentlyContinue
  if(-not $r){throw "Missing $name. Install Git/GitHub CLI and rerun."}
  return $r.Source
}
function Run([string]$exe,[string[]]$arguments){
  & $exe @arguments
  if($LASTEXITCODE -ne 0){throw "Command failed ($LASTEXITCODE): $exe"}
}
$Git = Require 'git.exe'
$Gh  = Require 'gh.exe'
if(-not(Test-Path (Join-Path $Repo '.git'))){throw 'Not a Git repository'}
$Origin = (& $Git -C $Repo remote get-url origin).Trim()
if($LASTEXITCODE -ne 0 -or $Origin -notmatch '(?i)(github.com[:/])machackabook/Gaia-The-Nexus-Generation(\.git)?$'){
  throw 'Unexpected origin; refusing changes'
}
Event 'DISCOVER' @{repo='machackabook/Gaia-The-Nexus-Generation';phase='started'}
$Node = Get-Command node.exe -ErrorAction SilentlyContinue
$Npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
if(-not $Node -or -not $Npm){throw 'Node/npm absent: install supported Node.js LTS first'}
$Major = [int]((& $Node.Source --version).TrimStart('v').Split('.')[0])
if($Major -lt 20){throw 'Node.js 20+ required'}
$prefix = (& $Npm.Source config get prefix | Select-Object -Last 1).Trim()
if($LASTEXITCODE -ne 0 -or -not(Test-Path $prefix)){throw 'npm prefix unavailable'}
$env:PATH = "$prefix;$env:PATH"
function EnsureNpm([string]$package,[string]$launcher){
  $cmd=Join-Path $prefix $launcher
  if(-not(Test-Path $cmd)){Run $Npm.Source @('install','--global',$package)}
  if(-not(Test-Path $cmd)){throw "CLI launcher missing: $launcher"}
  & $cmd --version | Out-Null
  if($LASTEXITCODE -ne 0){throw "CLI verification failed: $launcher"}
  return $cmd
}
$Gemini=EnsureNpm '@google/gemini-cli@latest' 'gemini.cmd'
$Codex=EnsureNpm '@openai/codex@latest' 'codex.cmd'
$Ollama=Get-Command ollama.exe -ErrorAction SilentlyContinue
if(-not $Ollama){
  $Winget=Get-Command winget.exe -ErrorAction SilentlyContinue
  if($Winget){
    Run $Winget.Source @('install','--id','Ollama.Ollama','--exact','--accept-package-agreements','--accept-source-agreements')
    $Ollama=Get-Command ollama.exe -ErrorAction SilentlyContinue
  }
}
$OllamaOk = $false
if($Ollama){
  & $Ollama.Source --version | Out-Null
  $OllamaOk=($LASTEXITCODE -eq 0)
}
$toolState=[ordered]@{git=$true;github_cli=$true;node=$true;gemini=$true;codex=$true;ollama=$OllamaOk}
Event 'REVERIFY' $toolState
# No machine-specific paths, hosts, IPs, account names, process lists or raw versions in public report.
$Public=[ordered]@{
  schema='gaia.public.toolchain/v1'
  tdoc='GAIASWINDOW-GITHUB-MESH-V5.2'
  timestamp_utc=[DateTime]::UtcNow.ToString('o')
  checks=$toolState
  verdict= $(if($OllamaOk){'verified-tools'}else{'partial-ollama-missing'})
}
$Local=Join-Path $State 'toolchain-public-report.json'
$Public | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $Local
Event 'FINGERPRINT' @{report_sha256=(Get-FileHash -Algorithm SHA256 $Local).Hash.ToLowerInvariant()}
if($RegisterTask){
  $shell=(Get-Command powershell.exe -ErrorAction Stop).Source
  $task='GAIA-GitHub-Mesh-Hourly'
  $arg='/Create /SC HOURLY /MO 1 /TN ' + $task
  $command='"' + $shell + '" -NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
  # Scheduled task runs local verification only; publishing requires explicit approval.
  & schtasks.exe /Create /SC HOURLY /MO 1 /TN $task /TR $command /F | Out-Null
  if($LASTEXITCODE -ne 0){throw 'Task registration failed'}
  Event 'SCHEDULE' @{task=$task;publishes=$false}
}
if($Publish){
  Run $Gh @('auth','status')
  $branch=(& $Git -C $Repo branch --show-current).Trim()
  if($branch -ne 'feature/adam-public-factory-v5'){throw 'Publishing requires feature/adam-public-factory-v5 branch'}
  $dirty=@(& $Git -C $Repo status --porcelain)
  if($dirty.Count -gt 0){throw 'Checkout has local changes; publication halted'}
  $reportPath='reports/public/gaiawindow-toolchain.json'
  $destination=Join-Path $Repo $reportPath
  [void](New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent))
  Copy-Item -LiteralPath $Local -Destination $destination -Force
  Run $Git @('-C',$Repo,'add','--',$reportPath)
  $staged=@(& $Git -C $Repo diff --cached --name-only)
  if($staged.Count -ne 1 -or $staged[0] -ne $reportPath){throw 'Unexpected staged files'}
  & $Git -C $Repo diff --cached --quiet
  if($LASTEXITCODE -eq 1){
    Run $Git @('-C',$Repo,'commit','-m','chore(adam): publish allowlisted toolchain status')
    Run $Git @('-C',$Repo,'push','origin','HEAD:feature/adam-public-factory-v5')
    Event 'SYNC' @{remote='github';published=$true}
  }elseif($LASTEXITCODE -ne 0){throw 'Git staged diff failed'}
}
Write-Host 'TDOC v5.2 VERIFIED: Gemini / Codex CLI detected; Ollama status recorded.' -ForegroundColor Green
Write-Host "Local evidence: $Local"
Write-Host 'Use -Publish on the reviewed feature branch for allowlisted GitHub reporting.'
