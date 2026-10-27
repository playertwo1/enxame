<#
.SYNOPSIS
    Summarizes pilot runs (JSONL, one run per line) by arm.
.DESCRIPTION
    Cost per accepted task is n/a when no run was accepted or any run in the
    arm has unknown cost: null means unknown, never zero.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Path)

$ErrorActionPreference = 'Stop'
$lineNumber = 0
$runs = foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
    $lineNumber++
    if ($line.Trim() -eq '') { continue }
    try { $line | ConvertFrom-Json } catch { throw "Invalid JSON on line ${lineNumber}: $line" }
}

foreach ($group in @($runs) | Group-Object { if ($_.arm) { $_.arm } else { 'unspecified' } } | Sort-Object Name) {
    $items = @($group.Group)
    $accepted = @($items | Where-Object { $_.accepted -eq $true }).Count
    $known = @($items | Where-Object { $null -ne $_.cost })
    $unknown = $items.Count - $known.Count
    $cost = ($known | Measure-Object -Property cost -Sum).Sum
    if ($null -eq $cost) { $cost = 0 }
    $escalations = ($items | Where-Object { $null -ne $_.escalations } | Measure-Object -Property escalations -Sum).Sum
    $perAccepted = if ($accepted -gt 0 -and $unknown -eq 0) { [math]::Round($cost / $accepted, 4) } else { 'n/a' }
    [pscustomobject]@{
        Arm             = $group.Name
        Runs            = $items.Count
        Accepted        = $accepted
        Escalations     = [int]$escalations
        KnownCost       = [math]::Round($cost, 4)
        UnknownCostRuns = $unknown
        CostPerAccepted = $perAccepted
    }
}
