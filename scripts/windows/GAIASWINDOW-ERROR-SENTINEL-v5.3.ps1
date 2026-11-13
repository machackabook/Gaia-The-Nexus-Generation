# [TDOC][GAIASWINDOW-ERROR-SENTINEL-V5.3]
# TDOC-ID: GAIA-20261010-WINDOWS-ERROR-SENTINEL
# VERSION: 5.3.0
# SOURCE: machackabook/Gaia-The-Nexus-Generation
# PIPELINE: DISCOVER -> OBSERVE -> CLASSIFY -> VERIFY -> FINGERPRINT -> PUBLISH -> REVERIFY
# SECURITY: Redacted error codes only to GitHub. Raw stderr stays local.
# PURPOSE: Detect CLI failures, render errors red, report failures to feature branch.
[CmdletBinding()]
param([switch]$InstallMissing,[switch]$NoPublish)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Root = Join-Path $env:USERPROFILE 'GAIA'
$LogDir = Join-Path $Root 'logs'
$StateDir = Join-Path $Root 'state'
foreach($dir in @($LogDir,$StateDir)){[void](New-Item -ItemType Directory -Path $dir -Force)}
$LocalLog = Join-Path $LogDir 'tdoc-error-sentinel-private.log'
$ReportFile = Join-Path $StateDir 'tdoc-error-sentinel-last.json'
$Failures = New-Object System.Collections.ArrayList
$Results = [ordered]@{}
$Stage='DISCOVER'
$Git = $null
$Gh = $null
$PublishError=$null

function Status([string]$message){Write-Host "[OK] $message" -ForegroundColor Green}
function Red([string]$message){Write-Host "[ERROR] $message" -ForegroundColor Red}
function Fail([string]$code,[string]$stage,[string]$detail){
    [void]$script:Failures.Add([ordered]@{code=$code;stage=$stage})
    # Detail stays local ONLY. It can contain private machine paths or tool stderr.
    Add-Content -LiteralPath $script:LocalLog -Value (
      ('{0:o} [{1}] {2}: {3}' -f [DateTime]::UtcNow,$stage,$code,$detail)
    ) -Encoding UTF8
    Red "$stage / $code (details in local log)"
}
function Native([string]$program,[string[]]$args,[string]$code){
    $output = @(& $program @args 2>&1 | Out-String)
    $exitCode=$LASTEXITCODE
    if($exitCode -ne 0){
        Fail $code $script:Stage ($output -join '')
        return $false
    }
    return $true
}
function ToolCheck([string]$command,[string]$package,[string]$npm){
    $cmd=Get-Command $command -ErrorAction SilentlyContinue
    if(-not $cmd -and $script:InstallMissing -and $npm){
        $script:Stage='REMEDY'
        [void](Native $npm @('install','--global',$package) 'NPM_INSTALL_FAILED')
        $cmd=Get-Command $command -ErrorAction SilentlyContinue
    }
    $script:Stage='VERIFY'
    if(-not $cmd){Fail 'CLI_NOT_FOUND' $script:Stage $command;return $false}
    return (Native $cmd.Source @('--version') 'CLI_VERSION_FAILED')
}
function PublishAllowlisted([object]$report) {
    $script:Stage='PUBLISH'
    if(-not $script:Gh){Fail 'GH_NOT_FOUND' 'PUBLISH' 'gh.exe unavailable';return $false}
    if(-not (Native $script:Gh @('auth','status') 'GH_AUTH_FAILED')){return $false}
    # GitHub API commits only the generated allowlisted JSON; leaves checkout untouched.
    # The workflow targets the existing review branch, not main.
    $endpoint='repos/machackabook/Gaia-The-Nexus-Generation/contents/reports/public/gaiawindow-errors.json'
    $branch='feature/adam-public-factory-v5'
    $payload=($report | ConvertTo-Json -Depth 6 -Compress)
    $bytes=[Text.Encoding]::UTF8.GetBytes($payload)
    $encoded=[Convert]::ToBase64String($bytes)
    $sha=$null
    $existing=@(& $script:Gh api "$endpoint?ref=$branch" --jq '.sha' 2>$null)
    if($LASTEXITCODE -eq 0 -and $existing.Count -gt 0){$sha=($existing | Select-Object -Last 1).Trim()}
    $body=[ordered]@{
        message='chore(tdoc): update sanitized GAIAWINDOW error evidence'
        branch=$branch
        content=$encoded
    }
    if($sha){$body.sha=$sha}
    $temp=Join-Path $script:StateDir 'github-error-api-request-private.json'
    try{
        $body | ConvertTo-Json -Compress | Set-Content -LiteralPath $temp -Encoding UTF8
        # gh api --input reads body file (no credentials in command parameters).
        $response=@(& $script:Gh api --method PUT $endpoint --input $temp 2>&1 | Out-String)
        if($LASTEXITCODE -ne 0){
            Fail 'GH_API_PUBLISH_FAILED' 'PUBLISH' ($response -join '')
            return $false
        }
        Status 'Sanitized error receipt committed to GitHub review branch'
        return $true
    }finally{
        Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
    }
}

try {
    $Stage='DISCOVER'
    $g=Get-Command git.exe -ErrorAction SilentlyContinue
    $h=Get-Command gh.exe -ErrorAction SilentlyContinue
    if($g){$Git=$g.Source}else{Fail 'GIT_NOT_FOUND' $Stage 'git.exe not found'}
    if($h){$Gh=$h.Source}else{Fail 'GH_NOT_FOUND' $Stage 'gh.exe not found'}
    if($Git){
        $remote=(& $Git -C $Repo remote get-url origin 2>&1 | Out-String).Trim()
        if($LASTEXITCODE -ne 0 -or $remote -notmatch '(?i)github\.com[:/]machackabook/Gaia-The-Nexus-Generation(\.git)?$'){
            Fail 'REMOTE_MISMATCH' $Stage 'Git remote was not the expected GAIA repo'
        }
    }
    $Stage='OBSERVE'
    $n=Get-Command node.exe -ErrorAction SilentlyContinue
    $npmCmd=Get-Command npm.cmd -ErrorAction SilentlyContinue
    if(-not $n){Fail 'NODE_NOT_FOUND' $Stage 'Node missing'}
    if(-not $npmCmd){Fail 'NPM_NOT_FOUND' $Stage 'npm missing'}
    if($npmCmd){
        $prefix=(& $npmCmd.Source config get prefix 2>&1 | Out-String).Trim()
        if($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $prefix)){
            $env:Path="$prefix;$env:Path"
        }else{Fail 'NPM_PREFIX_UNAVAILABLE' $Stage $prefix}
    }
    $Stage='VERIFY'
    $Results['git']=($null -ne $Git)
    $Results['github_cli']=($null -ne $Gh)
    $Results['node']=($null -ne $n)
    $Results['gemini']=ToolCheck 'gemini.cmd' '@google/gemini-cli@latest' $(if($npmCmd){$npmCmd.Source}else{''})
    $Results['codex']=ToolCheck 'codex.cmd' '@openai/codex@latest' $(if($npmCmd){$npmCmd.Source}else{''})
    $Results['ollama']=ToolCheck 'ollama.exe' '' ''
    $Stage='CLASSIFY'
    $Public=[ordered]@{
        schema='gaia.public.error-report/v1'
        tdoc='GAIASWINDOW-ERROR-SENTINEL-V5.3'
        generated_utc=[DateTime]::UtcNow.ToString('o')
        checks=$Results
        errors=@($Failures | ForEach-Object { [ordered]@{code=$_.code;stage=$_.stage} })
        status= $(if($Failures.Count -eq 0){'PASS'}else{'FAIL'})
    }
    $Public | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportFile -Encoding UTF8
    $Stage='FINGERPRINT'
    $digest=(Get-FileHash -LiteralPath $ReportFile -Algorithm SHA256).Hash.ToLowerInvariant()
    Status "Local error receipt fingerprinted ($($digest.Substring(0,12)))"
    if(-not $NoPublish){[void](PublishAllowlisted $Public)}
    if($Failures.Count -eq 0){Status 'ADAM CLI checks completed; no errors returned'}
    else{Red "$($Failures.Count) failure(s) recorded; only error codes were published"}
}
catch {
    Fail 'SENTINEL_EXCEPTION' $Stage $_.Exception.Message
    $fallback=[ordered]@{
      schema='gaia.public.error-report/v1';tdoc='GAIASWINDOW-ERROR-SENTINEL-V5.3'
      generated_utc=[DateTime]::UtcNow.ToString('o')
      checks=$Results
      errors=@($Failures | ForEach-Object {[ordered]@{code=$_.code;stage=$_.stage}})
      status='FAIL'
    }
    $fallback | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportFile -Encoding UTF8
    if(-not $NoPublish -and $Gh){[void](PublishAllowlisted $fallback)}
}
if($Failures.Count -gt 0){exit 1}
