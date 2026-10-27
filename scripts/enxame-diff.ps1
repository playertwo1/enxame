<#
.SYNOPSIS
    Collects a review patch without staging files or changing the user's index.
.DESCRIPTION
    Includes tracked and untracked changes. Paths are relative to the repository
    root. VerifyCommand is trusted operator input, never text from a patch.
    Exit 0 means collection succeeded; VALIDATION may still be NOT_RUN.
#>
[CmdletBinding()]
param(
    [string]$VerifyCommand = '',
    [string]$BaseRef = '',
    [string[]]$Paths = @('.')
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $OutputEncoding

function Invoke-Git {
    param([string[]]$Arguments, [int[]]$Allowed = @(0))
    $ErrorActionPreference = 'Continue'
    $result = @(& git --no-pager -c core.quotepath=false @Arguments 2>&1)
    $code = $LASTEXITCODE
    if ($code -notin $Allowed) {
        throw "Git failed ($code): $($result -join [Environment]::NewLine)"
    }
    $result -join "`n"
}

try {
    if (-not $Paths.Count -or @($Paths | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count) {
        throw 'Paths must contain at least one repository path.'
    }
    $repoRoot = Invoke-Git -Arguments @('rev-parse', '--show-toplevel')
    Push-Location -LiteralPath $repoRoot
    try {
        # Literal pathspecs keep filenames from being interpreted as Git magic.
        $scope = @($Paths | ForEach-Object { ':(literal)' + $_ })
        if ($Paths -contains '.') { $scope = @('.') }
        $headRef = Invoke-Git -Arguments @('rev-parse', '--verify', '--quiet', 'HEAD') -Allowed @(0, 1)
        if ($BaseRef) {
            $base = Invoke-Git -Arguments @('rev-parse', '--verify', '--end-of-options', ($BaseRef + '^{commit}'))
        } else { $base = $headRef }

        Write-Output ('HEAD: ' + $(if ($headRef) { $headRef } else { 'UNBORN' }))
        Write-Output ('BASE: ' + $(if ($base) { $base } else { 'EMPTY_TREE' }))
        if ($VerifyCommand) {
            # A child shell prevents exit/throw from bypassing the validation state.
            $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($VerifyCommand))
            $verification = @'
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
try {
    Invoke-Expression ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('PAYLOAD')))
    $ok = $?
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if (-not $ok) { exit 1 }
} catch { Write-Error $_ -ErrorAction Continue; exit 1 }
'@.Replace('PAYLOAD', $encoded)
            $shell = (Get-Process -Id $PID).Path
            $ErrorActionPreference = 'Continue'
            $verificationOutput = @(& $shell -NoProfile -NonInteractive -Command $verification 2>&1)
            $verificationExit = $LASTEXITCODE
            $ErrorActionPreference = 'Stop'
            Write-Output $verificationOutput
            if ($verificationExit -ne 0) {
                Write-Output "VALIDATION: FAIL (exit $verificationExit)"
                exit $verificationExit
            }
            Write-Output 'VALIDATION: PASS'
        } else { Write-Output 'VALIDATION: NOT_RUN' }

        $status = Invoke-Git -Arguments (@('status', '--short', '--untracked-files=all', '--') + $scope)
        $diffOptions = @('diff', '--binary', '--no-ext-diff', '--no-textconv', '--no-color', '-U3')
        $patches = @()
        if ($base) {
            $patches += Invoke-Git -Arguments ($diffOptions + @($base, '--') + $scope)
        } else {
            # With no HEAD, staged then unstaged patches describe the full change.
            $patches += Invoke-Git -Arguments ($diffOptions + @('--cached', '--') + $scope)
            $patches += Invoke-Git -Arguments ($diffOptions + @('--') + $scope)
        }
        $newFiles = Invoke-Git -Arguments (@('ls-files', '--others', '--exclude-standard', '-z', '--') + $scope)
        foreach ($file in @($newFiles -split "`0" | Where-Object { $_ })) {
            $item = Get-Item -LiteralPath $file -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Untracked link requires separate review: $file"
            }
            $patches += Invoke-Git -Arguments ($diffOptions + @('--no-index', '--', '/dev/null', $file)) -Allowed @(0, 1)
        }
        $patch = ($patches | Where-Object { $_ }) -join "`n"
        $snapshot = "HEAD=$headRef`nBASE=$base`nSTATUS=$status`n$patch"
        $hasher = [Security.Cryptography.SHA256]::Create()
        try {
            $hash = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($snapshot))).Replace('-', '').ToLowerInvariant()
        } finally { $hasher.Dispose() }
        Write-Output "PATCH_SHA256: $hash"
        Write-Output '--- STATUS ---'
        if ($status) { Write-Output $status } else { Write-Output 'CLEAN' }
        Write-Output '--- PATCH ---'
        # Hash binary payloads too, but keep them out of the reviewer's text context.
        Write-Output ([regex]::Replace($patch, '(?ms)^GIT binary patch\r?\n.*?(?=^diff --git |\z)', '[binary payload omitted; inspect the source asset separately]' + "`n"))
        Write-Output '--- END PATCH ---'
        Write-Output 'REVIEW: COLLECTED (binary content requires separate inspection)'
    } finally { Pop-Location }
} catch {
    Write-Output 'COLLECTION: FAIL'
    Write-Error $_ -ErrorAction Continue
    exit 1
}
exit 0
