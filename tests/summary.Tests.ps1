$ErrorActionPreference = 'Stop'
$summary = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/enxame-summary.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('enxame-summary-' + [guid]::NewGuid().ToString('N') + '.jsonl')
$script:checks = 0
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERT: $Message" }
    $script:checks++
}

try {
    @(
        '{"arm":"adaptive","task":"a","cost":0.5,"escalations":1,"accepted":true}'
        '{"arm":"adaptive","task":"b","cost":0.25,"escalations":0,"accepted":false}'
        ''
        '{"arm":"solo","task":"a","cost":null,"accepted":true}'
        '{"arm":"economic","task":"a","cost":0.1,"accepted":false}'
    ) | Set-Content -LiteralPath $fixture -Encoding UTF8
    $rows = @(& $summary -Path $fixture)
    $adaptive = $rows | Where-Object Arm -eq 'adaptive'
    Assert ($rows.Count -eq 3) 'one row per arm'
    Assert ($adaptive.Runs -eq 2 -and $adaptive.Accepted -eq 1 -and $adaptive.Escalations -eq 1) 'counts runs, accepts, escalations'
    Assert ($adaptive.CostPerAccepted -eq 0.75) 'cost per accepted includes rejected runs'
    Assert (($rows | Where-Object Arm -eq 'solo').CostPerAccepted -eq 'n/a') 'unknown cost is not zero'
    Assert (($rows | Where-Object Arm -eq 'economic').CostPerAccepted -eq 'n/a') 'no accepted run is n/a'

    '{"arm":"x",' | Set-Content -LiteralPath $fixture -Encoding UTF8
    $failed = $false
    try { & $summary -Path $fixture | Out-Null } catch { $failed = $_.Exception.Message -like '*line 1*' }
    Assert $failed 'invalid JSON reports its line'
    Write-Output "PASS: $script:checks summary checks"
} finally {
    Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue
}
