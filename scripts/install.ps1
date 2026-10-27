[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Codex', 'Claude', 'Hermes', 'Antigravity', 'All')]
    [string]$Target = 'All',
    [string]$HomePath = $HOME,
    [string]$HermesHome = ''
)

$ErrorActionPreference = 'Stop'
$sourceRoot = $PSScriptRoot | Split-Path -Parent
$skillName = 'enxame'
$backupRoot = Join-Path $HomePath '.enxame-backups'

function Assert-NoReparsePoints([string]$Path) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($fullPath)
    $current = $root
    foreach ($part in $fullPath.Substring($root.Length).Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $part
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse point recusado: $current" }
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'SKILL.md') -PathType Leaf)) { throw "Payload incompleto: $(Join-Path $sourceRoot 'SKILL.md') ausente" }

$payload = @(Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force | Where-Object {
    $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
    $relative -eq 'SKILL.md' -or $relative -match '^(templates|references|scripts|agents)\\' -and $relative -notmatch '^(scripts\\install\.ps1|tests\\)'
})
foreach ($file in $payload) { Assert-NoReparsePoints $file.FullName }
if (-not ($payload | Where-Object { $_.FullName -eq (Join-Path $sourceRoot 'SKILL.md') })) { throw 'Payload sem SKILL.md' }

$destinations = @{}
if ($Target -in @('Codex', 'All')) { $destinations.Codex = Join-Path $HomePath ".codex\skills\$skillName" }
if ($Target -in @('Claude', 'All')) { $destinations.Claude = Join-Path $HomePath ".claude\skills\$skillName" }
if (-not $HermesHome) { $HermesHome = Join-Path $HomePath '.hermes' }
if ($Target -in @('Hermes', 'All')) { $destinations.Hermes = Join-Path $HermesHome "skills\$skillName" }
if ($Target -in @('Antigravity', 'All')) {
    $destinations.Antigravity = Join-Path $HomePath ".gemini\config\skills\$skillName"
    $destinations.AntigravityLegacy = Join-Path $HomePath ".gemini\antigravity\skills\$skillName"
}

$backupId = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N')
foreach ($entry in $destinations.GetEnumerator()) {
    $destination = $entry.Value
    Assert-NoReparsePoints $destination
    if (Test-Path -LiteralPath $destination) {
        foreach ($item in Get-ChildItem -LiteralPath $destination -Recurse -Force) { Assert-NoReparsePoints $item.FullName }
    }
    $unchanged = Test-Path -LiteralPath $destination -PathType Container
    if ($unchanged) {
        foreach ($file in $payload) {
            $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
            $targetFile = Join-Path $destination $relative
            if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf) -or (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) { $unchanged = $false; break }
        }
    }
    if ($unchanged) { Write-Output "UNCHANGED $($entry.Key): $destination"; continue }
    Write-Output "$($entry.Key): $destination ($($payload.Count) arquivos; hash SHA-256 após cópia)"
    if (-not $PSCmdlet.ShouldProcess($destination, 'Instalar ou atualizar skill')) { continue }
    if (Test-Path -LiteralPath $destination) { Assert-NoReparsePoints $backupRoot }
    $backup = Join-Path (Join-Path $backupRoot $backupId) $entry.Key
    if (Test-Path -LiteralPath $destination) {
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        foreach ($item in Get-ChildItem -LiteralPath $destination -Force -Recurse) {
            $relative = $item.FullName.Substring($destination.Length).TrimStart('\', '/')
            $backupItem = Join-Path $backup $relative
            if ($item.PSIsContainer) { New-Item -ItemType Directory -Path $backupItem -Force | Out-Null }
            else {
                New-Item -ItemType Directory -Path (Split-Path -Parent $backupItem) -Force | Out-Null
                Copy-Item -LiteralPath $item.FullName -Destination $backupItem
            }
        }
    }
    foreach ($file in $payload) {
        $relative = $file.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $targetFile = Join-Path $destination $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $targetFile) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force
        if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) { throw "Hash divergente: $targetFile" }
    }
}
