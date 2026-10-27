param([string]$ShellPath = (Get-Process -Id $PID).Path)
$ErrorActionPreference = 'Stop'
$collector = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts/enxame-diff.ps1'
$fixtureRoot = Join-Path $env:USERPROFILE ('.codex/.tmp/enxame-diff-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$script:checks = 0
function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERT: $Message" }
    $script:checks++
}
function Invoke-FixtureGit([string[]]$Arguments) {
    $output = & git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Fixture Git failed: $output" }
    $output
}
function Collect([string]$Directory, [string]$Extra = '') {
    $escaped = $collector.Replace("'", "''")
    $command = "& '$escaped' $Extra" + '; exit $LASTEXITCODE'
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    Push-Location -LiteralPath $Directory
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $ShellPath -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded 2>&1)
        $code = $LASTEXITCODE
        [pscustomobject]@{ Code = $code; Text = $output -join "`n" }
    } finally { Pop-Location }
}
function Hash-Of($Result) { [regex]::Match($Result.Text, 'PATCH_SHA256: ([a-f0-9]{64})').Groups[1].Value }

try {
    $outside = Collect $fixtureRoot
    Assert ($outside.Code -ne 0 -and $outside.Text.Contains('COLLECTION: FAIL')) 'non-repository fails'
    $repo = Join-Path $fixtureRoot 'repo'
    New-Item -ItemType Directory -Path $repo | Out-Null
    Invoke-FixtureGit @('-C', $repo, 'init', '-q') | Out-Null
    Set-Content -LiteralPath (Join-Path $repo 'existing.txt') -Value 'baseline'
    Invoke-FixtureGit @('-C', $repo, 'add', '.') | Out-Null
    $unborn = Collect $repo
    Assert ($unborn.Code -eq 0 -and $unborn.Text.Contains('+baseline') -and $unborn.Text.Contains('HEAD: UNBORN')) 'unborn staged change is collected'
    Set-Content -LiteralPath (Join-Path $repo 'existing.txt') -Value 'UNSTAGED_UNBORN'
    $unbornBoth = Collect $repo
    Assert ($unbornBoth.Code -eq 0 -and $unbornBoth.Text.Contains('+UNSTAGED_UNBORN')) 'unborn unstaged change is collected'
    Invoke-FixtureGit @('-C', $repo, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'baseline') | Out-Null
    Set-Content -LiteralPath (Join-Path $repo 'new file.txt') -Value 'UNTRACKED_MARKER'
    Set-Content -LiteralPath (Join-Path $repo 'dependencies.lock') -Value 'LOCK_REVIEW_MARKER'
    $beforeIndex = (Invoke-FixtureGit @('-C', $repo, 'ls-files', '--stage')) -join "`n"
    $changes = Collect $repo
    Assert ($changes.Code -eq 0 -and $changes.Text.Contains('+UNTRACKED_MARKER')) 'untracked content with spaces is included'
    Assert ($changes.Text.Contains('+LOCK_REVIEW_MARKER')) 'lockfiles are not silently excluded'
    Assert ($changes.Text.Contains('+UNSTAGED_UNBORN')) 'tracked working change is included'
    Assert ($changes.Text.Contains('VALIDATION: NOT_RUN')) 'missing verification is explicit'
    Assert ((Hash-Of $changes).Length -eq 64) 'snapshot has SHA-256'
    $afterIndex = (Invoke-FixtureGit @('-C', $repo, 'ls-files', '--stage')) -join "`n"
    Assert ($beforeIndex -eq $afterIndex) 'collection preserves index'
    Assert ((Hash-Of $changes) -eq (Hash-Of (Collect $repo))) 'same snapshot has stable hash'
    $scope = Collect $repo "-Paths 'new file.txt'"
    Assert ($scope.Code -eq 0 -and $scope.Text.Contains('+UNTRACKED_MARKER') -and -not $scope.Text.Contains('LOCK_REVIEW_MARKER')) 'literal path scope works'
    $invalid = Collect $repo "-BaseRef 'does-not-exist'"
    Assert ($invalid.Code -ne 0 -and $invalid.Text.Contains('COLLECTION: FAIL')) 'invalid base cannot produce successful collection'
    $passed = Collect $repo '-VerifyCommand ''Write-Output "checked"'''
    Assert ($passed.Code -eq 0 -and $passed.Text.Contains('VALIDATION: PASS')) 'PowerShell verification succeeds'
    $failed = Collect $repo '-VerifyCommand ''cmd /c exit 7'''
    Assert ($failed.Code -eq 7 -and $failed.Text.Contains('VALIDATION: FAIL')) 'native verification error propagates'
    $thrown = Collect $repo '-VerifyCommand ''throw "fixture failure"'''
    Assert ($thrown.Code -ne 0 -and $thrown.Text.Contains('VALIDATION: FAIL')) 'PowerShell verification exception fails'
    $exitFailure = Collect $repo '-VerifyCommand ''exit 9'''
    Assert ($exitFailure.Code -eq 9 -and $exitFailure.Text.Contains('VALIDATION: FAIL')) 'exit in verification cannot skip failure status'
    $binary = Join-Path $repo 'binary.dat'
    [IO.File]::WriteAllBytes($binary, [byte[]]@(0,1,2,3,0,255))
    $binary1 = Collect $repo
    [IO.File]::WriteAllBytes($binary, [byte[]]@(0,1,2,4,0,255))
    $binary2 = Collect $repo
    Assert ($binary2.Code -eq 0 -and $binary2.Text.Contains('[binary payload omitted')) 'binary payload is identified without flooding context'
    Assert ((Hash-Of $binary1) -ne (Hash-Of $binary2)) 'binary content affects snapshot hash'
    $unicodeName = 'a' + [char]0x00E7 + [char]0x00E3 + 'o.txt'
    Set-Content -LiteralPath (Join-Path $repo $unicodeName) -Value 'UNICODE_PATH_MARKER'
    $unicode = Collect $repo ("-Paths '" + $unicodeName + "'")
    Assert ($unicode.Code -eq 0 -and $unicode.Text.Contains('+UNICODE_PATH_MARKER')) 'Unicode filename is included'
    $baseline = (Invoke-FixtureGit @('-C', $repo, 'rev-parse', 'HEAD')) -join ''
    Invoke-FixtureGit @('-C', $repo, 'add', '.') | Out-Null
    Invoke-FixtureGit @('-C', $repo, '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'changes') | Out-Null
    $committed = Collect $repo ("-BaseRef '" + $baseline + "'")
    Assert ($committed.Code -eq 0 -and $committed.Text.Contains('+UNTRACKED_MARKER')) 'explicit baseline includes committed changes'
    $clean = Collect $repo
    Assert ($clean.Code -eq 0 -and $clean.Text.Contains('CLEAN') -and -not $clean.Text.Contains('+UNTRACKED_MARKER')) 'clean HEAD has no stale patch'
    Write-Output "PASS: $script:checks collector checks ($ShellPath)"
} finally {
    $resolved = [IO.Path]::GetFullPath($fixtureRoot)
    $allowedRoot = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.codex/.tmp')) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
