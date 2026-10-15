# [TDOC][GAIA-HARDWARE-MESH-GITHUB-BRIDGE-V5.5]
# TDOC-ID: GAIA-20261010-HARDWARE-EVIDENCE
# VERSION: 5.5.0
# ORIGIN: machackabook/Gaia-The-Nexus-Generation
# FLOW: DISCOVER -> OBSERVE -> CLASSIFY -> VERIFY -> FINGERPRINT -> PUBLISH
# PRIVATE EVIDENCE: machackabook/gaia-device-evidence (create if absent)
# SECURITY: no raw network addresses, usernames, hostnames, serials, paths or stderr to GitHub
[CmdletBinding()]
param([switch]$NoPublish)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$owner='machackabook'
$repoName='gaia-device-evidence'
$repo="$owner/$repoName"
$root=Join-Path ([Environment]::GetFolderPath('UserProfile')) 'GAIA'
$local=Join-Path $root 'logs'
[void](New-Item -ItemType Directory -Force -Path $local)
$privateLog=Join-Path $local 'tdoc-hardware-mesh-private.log'
$errors=New-Object System.Collections.ArrayList
$stage='DISCOVER'
function OK([string]$message){Write-Host "[OK] $message" -ForegroundColor Green}
function Bad([string]$code,[string]$detail){
    [void]$script:errors.Add([ordered]@{stage=$script:stage;code=$code})
    Add-Content -LiteralPath $script:privateLog -Encoding UTF8 -Value ("{0:o} [{1}] {2}: {3}" -f [DateTime]::UtcNow,$script:stage,$code,$detail)
    Write-Host "[ERROR] $code" -ForegroundColor Red
}
function GitHub([string[]]$args){
    $out=@(& gh.exe @args 2>&1 | Out-String)
    if($LASTEXITCODE -ne 0){throw (($out -join '').Trim())}
    return ($out -join '').Trim()
}
$results=[ordered]@{ethernet_adapters=0;active_ethernet_links=0;usb_storage_devices=0;local_disks=0;github_cli=$false}
try {
    $stage='DISCOVER'
    $adapters=@(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {$_.InterfaceDescription -match '(?i)ethernet|gigabit|realtek|intel|lan|usb.*eth'})
    $results.ethernet_adapters=$adapters.Count
    $results.active_ethernet_links=@($adapters | Where-Object {$_.Status -eq 'Up'}).Count
    $disks=@(Get-Disk -ErrorAction Stop)
    $results.local_disks=$disks.Count
    $results.usb_storage_devices=@($disks | Where-Object {$_.BusType -eq 'USB'}).Count
    $stage='VERIFY'
    $ghCmd=Get-Command gh.exe -ErrorAction SilentlyContinue
    $results.github_cli=($null -ne $ghCmd)
    if(-not $ghCmd){Bad 'GH_CLI_MISSING' 'gh.exe not found'}
    else {
        try { $null=GitHub @('auth','status'); OK 'GitHub CLI authenticated' }
        catch { Bad 'GH_AUTH_FAILED' $_.Exception.Message }
    }
    if($results.active_ethernet_links -eq 0){Bad 'NO_ACTIVE_ETHERNET' 'No connected Ethernet link'}
    OK 'Read-only hardware inspection completed'
} catch {
    Bad 'DISCOVERY_FAILURE' $_.Exception.Message
}
$stage='CLASSIFY'
$report=[ordered]@{
    schema='gaia.hardware.mesh-evidence/v1'
    tdoc='GAIA-HARDWARE-MESH-GITHUB-BRIDGE-V5.5'
    collected_utc=[DateTime]::UtcNow.ToString('o')
    node_role='GAIASWINDOW'
    checks=$results
    errors=@($errors.ToArray())
    verdict=$(if($errors.Count -eq 0){'PASS'}else{'NEEDS_REVIEW'})
}
$payload=$report | ConvertTo-Json -Depth 6 -Compress
$localReport=Join-Path $local 'hardware-mesh-sanitized.json'
[IO.File]::WriteAllText($localReport,$payload,[Text.UTF8Encoding]::new($false))
$fingerprint=(Get-FileHash -Algorithm SHA256 -LiteralPath $localReport).Hash.ToLowerInvariant()
OK "Sanitized evidence SHA256: $fingerprint"
if(-not $NoPublish){
    $stage='PUBLISH'
    if(-not $results.github_cli){Bad 'PUBLISH_UNAVAILABLE' 'GitHub CLI missing'}
    else {
        try {
            # Confirm account and private target; no public fallback.
            $login=(GitHub @('api','user','--jq','.login')).Trim()
            if($login -ne $owner){throw 'Authenticated GitHub user is not the expected repository owner'}
            $repoInfo=$null
            try { $repoInfo=(GitHub @('api',"repos/$repo",'--jq','.private')) } catch {
                # Require a genuine 404 before creating; do not confuse permissions and outages with absence.
                $probe=@(& gh.exe api "repos/$repo" 2>&1 | Out-String);$status=$LASTEXITCODE
                if($status -eq 0){throw 'Repository lookup inconsistent'}
                if(($probe -join '') -notmatch '(?i)404|not found'){throw 'Cannot establish repository absence; refusing creation'}
                $null=GitHub @('repo','create',$repo,'--private','--description','Private GAIA sanitized hardware evidence receipts','--disable-issues','--disable-wiki')
                $repoInfo=(GitHub @('api',"repos/$repo",'--jq','.private'))
            }
            if($repoInfo -ne 'true'){throw 'Target repository is not private; refusing upload'}
            $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
            $target="reports/$stamp-hardware-mesh.json"
            $encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($payload))
            $body=[ordered]@{message='tdoc: add sanitized hardware evidence';content=$encoded} | ConvertTo-Json -Compress
            $tmp=Join-Path $local 'gh-upload-request-private.json'
            try {
                [IO.File]::WriteAllText($tmp,$body,[Text.UTF8Encoding]::new($false))
                $null=GitHub @('api','--method','PUT',"repos/$repo/contents/$target",'--input',$tmp)
            } finally {Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}
            OK "Evidence published: https://github.com/$repo/blob/HEAD/$target"
        } catch {Bad 'GITHUB_EVIDENCE_PUBLISH_FAILED' $_.Exception.Message}
    }
}
if($errors.Count -gt 0){exit 1}
