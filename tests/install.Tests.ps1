$ErrorActionPreference = 'Stop'
$installer = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts\install.ps1'
$tempRoot = Join-Path $env:USERPROFILE '.codex\.tmp\enxame-install-guid'
$temp = Join-Path $tempRoot ([guid]::NewGuid().ToString('N'))
$repo = Join-Path $temp 'repo'
$profileHome = Join-Path $temp 'home'
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $repo 'scripts'), (Join-Path $repo 'templates'), $profileHome -Force | Out-Null
Copy-Item -LiteralPath $installer -Destination (Join-Path $repo 'scripts\install.ps1')
Set-Content -LiteralPath (Join-Path $repo 'SKILL.md') -Value 'fixture v1'
Set-Content -LiteralPath (Join-Path $repo 'templates\sample.md') -Value 'sample'

function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "ASSERT: $Message" } }
function Remove-FixtureTree([string]$Path) {
    $absolutePath = [IO.Path]::GetFullPath($Path)
    $fixtureRoot = [IO.Path]::GetFullPath($temp).TrimEnd('\')
    $allowedRoot = $fixtureRoot + '\'
    if (-not $absolutePath.Equals($fixtureRoot, [StringComparison]::OrdinalIgnoreCase) -and -not $absolutePath.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Recusa de limpeza fora da fixture: $absolutePath" }
    if (Test-Path -LiteralPath $absolutePath) {
        $item = Get-Item -LiteralPath $absolutePath -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { [IO.Directory]::Delete($absolutePath, $false); return }
        foreach ($item in Get-ChildItem -LiteralPath $absolutePath -Force -Recurse) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse point dentro da fixture: $($item.FullName)" }
        }
        Remove-Item -LiteralPath $absolutePath -Recurse -Force
    }
}
function Remove-Fixture {
    $fixturePath = [IO.Path]::GetFullPath($temp)
    $allowedRoot = [IO.Path]::GetFullPath($tempRoot).TrimEnd('\') + '\'
    if (-not $fixturePath.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Recusa de limpeza fora da fixture: $fixturePath" }
    foreach ($junction in @((Join-Path $profileHome '.claude\skills\enxame'), (Join-Path $profileHome '.enxame-backups'))) {
        if (Test-Path -LiteralPath $junction) {
            $item = Get-Item -LiteralPath $junction -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { [IO.Directory]::Delete($junction, $false) }
        }
    }
    Remove-FixtureTree $fixturePath
}
try {
    & (Join-Path $repo 'scripts\install.ps1') -Target All -HomePath $profileHome -Confirm:$false | Out-Null
    $destinations = @(
        '.codex\skills\enxame', '.claude\skills\enxame', '.hermes\skills\enxame',
        '.gemini\config\skills\enxame', '.gemini\antigravity\skills\enxame'
    ) | ForEach-Object { Join-Path $profileHome $_ }
    foreach ($destination in $destinations) {
        Assert (Test-Path -LiteralPath (Join-Path $destination 'SKILL.md')) "install $destination"
        Assert ((Get-FileHash (Join-Path $repo 'SKILL.md')).Hash -eq (Get-FileHash (Join-Path $destination 'SKILL.md')).Hash) "hash $destination"
    }
    $customHermes = Join-Path $temp 'hermes-active-profile'
    & (Join-Path $repo 'scripts\install.ps1') -Target Hermes -HomePath $profileHome -HermesHome $customHermes -Confirm:$false | Out-Null
    Assert ((Get-FileHash (Join-Path $repo 'SKILL.md')).Hash -eq (Get-FileHash (Join-Path $customHermes 'skills\enxame\SKILL.md')).Hash) 'custom Hermes profile'
    $original = Join-Path $destinations[0] 'SKILL.md'
    Set-Content -LiteralPath $original -Value 'user version'
    Set-Content -LiteralPath (Join-Path $repo 'SKILL.md') -Value 'fixture v2'
    & (Join-Path $repo 'scripts\install.ps1') -Target Codex -HomePath $profileHome -Confirm:$false | Out-Null
    Assert ((Get-Content -Raw -LiteralPath $original).Trim() -eq 'fixture v2') 'update'
    Assert ((Get-ChildItem (Join-Path $profileHome '.enxame-backups') -Filter SKILL.md -Recurse | Where-Object { (Get-Content -Raw $_.FullName).Trim() -eq 'user version' }).Count -eq 1) 'backup'
    $backupCount = (Get-ChildItem (Join-Path $profileHome '.enxame-backups') -Directory).Count
    $unchangedOutput = & (Join-Path $repo 'scripts\install.ps1') -Target Codex -HomePath $profileHome -Confirm:$false
    Assert ($unchangedOutput -match '^UNCHANGED Codex:') 'idempotent output'
    Assert ((Get-ChildItem (Join-Path $profileHome '.enxame-backups') -Directory).Count -eq $backupCount) 'idempotent backup'
    Set-Content -LiteralPath (Join-Path $repo 'SKILL.md') -Value 'fixture v3'
    & (Join-Path $repo 'scripts\install.ps1') -Target Codex -HomePath $profileHome -WhatIf -Confirm:$false | Out-Null
    Assert ((Get-Content -Raw -LiteralPath $original).Trim() -eq 'fixture v2') 'WhatIf mutated destination'
    $outside = Join-Path $temp 'outside'
    New-Item -ItemType Directory -Path $outside -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $outside 'sentinel') -Value 'untouched'
    $linkedDestination = Join-Path $profileHome '.claude\skills\enxame'
    Remove-FixtureTree $linkedDestination
    New-Item -ItemType Junction -Path $linkedDestination -Target $outside | Out-Null
    $reparseRejected = $false
    try { & (Join-Path $repo 'scripts\install.ps1') -Target Claude -HomePath $profileHome | Out-Null } catch { $reparseRejected = $true }
    Assert $reparseRejected 'reparse destination accepted'
    Assert ((Get-Content -Raw (Join-Path $outside 'sentinel')).Trim() -eq 'untouched') 'reparse target changed'
    [IO.Directory]::Delete($linkedDestination, $false)
    $backupPath = Join-Path $profileHome '.enxame-backups'
    Move-Item -LiteralPath $backupPath -Destination (Join-Path $profileHome '.enxame-backups.saved')
    New-Item -ItemType Junction -Path $backupPath -Target $outside | Out-Null
    $backupLinkRejected = $false
    try { & (Join-Path $repo 'scripts\install.ps1') -Target Codex -HomePath $profileHome -Confirm:$false | Out-Null } catch { $backupLinkRejected = $true }
    Assert $backupLinkRejected 'backupRoot junction accepted'
    Assert ((Get-Content -Raw (Join-Path $outside 'sentinel')).Trim() -eq 'untouched') 'backup junction target changed'
    Assert ((Get-Content -Raw -LiteralPath $original).Trim() -eq 'fixture v2') 'backup junction allowed destination update'
    [IO.Directory]::Delete($backupPath, $false)
    Move-Item -LiteralPath (Join-Path $profileHome '.enxame-backups.saved') -Destination $backupPath
    Write-Output 'PASS: targets, hashes, backup, idempotence, WhatIf, reparse rejection'
} finally { Remove-Fixture }
