param([Parameter(Mandatory)][string]$FixtureRoot, [switch]$NormalOnly)
$ErrorActionPreference = 'Stop'
# 固定した試験用コピーだけを変異させ、共有Pesterを変更しない。
$fixture = [IO.Path]::GetFullPath($FixtureRoot)
$run = Join-Path $fixture 'run'
$work = Join-Path $run ('attempt-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -ErrorAction Stop | Out-Null
$source = Join-Path $work 'subject.ps1'
$test = Join-Path $work 'subject.Tests.ps1'
$encoding = [Text.UTF8Encoding]::new($false)
$created = @($work, $source, $test, (Join-Path $work 'child-allowed.txt'))
$original = 'function Get-ProbeTotal { param($a,$b) $a + $b }'
[IO.File]::WriteAllText($source, $original, $encoding)
$testText = ". '$($source.Replace("'", "''"))'`nDescribe '加算コピーの検査' { It '2と3の合計は5' { (Get-ProbeTotal 2 3) | Should Be 5 } }"
[IO.File]::WriteAllText($test, $testText, $encoding)
Import-Module Pester -RequiredVersion 3.4.0
$normal = Invoke-Pester -Script $test -PassThru -Quiet
[IO.File]::WriteAllText($source, 'function Get-ProbeTotal { param($a,$b) $a - $b }', $encoding)
$mutated = Invoke-Pester -Script $test -PassThru -Quiet
[IO.File]::WriteAllText($source, $original, $encoding)
$restored = Invoke-Pester -Script $test -PassThru -Quiet
if ($NormalOnly) {
    @{normal=$normal.PassedCount;mutated=$mutated.FailedCount;restored=$restored.PassedCount} | ConvertTo-Json -Compress
    if ($normal.TotalCount -ne 1 -or $normal.PassedCount -ne 1 -or $mutated.FailedCount -ne 1 -or $restored.PassedCount -ne 1) { exit 1 }
    exit 0
}
$denials = @()
foreach ($path in @((Join-Path $fixture 'protected/original.txt'), (Join-Path $fixture 'protected/shared-tool.txt'), (Join-Path $run 'session-log.json'), (Join-Path $fixture 'controller/server.ps1'))) {
    try {
        [IO.File]::WriteAllText($path, 'unexpected-write', $encoding)
        throw "保護対象への書き込みが成功: $path"
    } catch {
        if ($_.Exception.GetBaseException() -isnot [UnauthorizedAccessException]) { throw }
        $denials += @{ path=$path; denied=$true; exception=$_.Exception.GetBaseException().GetType().FullName }
    }
}
$childCode = "[IO.File]::WriteAllText('$((Join-Path $work 'child-allowed.txt').Replace("'", "''"))','ok'); try { [IO.File]::WriteAllText('$((Join-Path $fixture 'protected/original.txt').Replace("'", "''"))','unexpected-child'); exit 9 } catch { if (`$_.Exception.GetBaseException() -is [UnauthorizedAccessException]) { Write-Output 'child-denied'; exit 0 }; throw }"
$childOutput = & 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe' -NoProfile -NonInteractive -EncodedCommand ([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCode)))
$childExit = $LASTEXITCODE
$result = [ordered]@{
    normal=@{total=$normal.TotalCount;passed=$normal.PassedCount;failed=$normal.FailedCount;failures=@($normal.TestResult | Where-Object {$_.Passed -eq $false} | Select-Object Name,FailureMessage)}
    mutated=@{total=$mutated.TotalCount;passed=$mutated.PassedCount;failed=$mutated.FailedCount;failures=@($mutated.TestResult | Where-Object {$_.Passed -eq $false} | Select-Object Name,FailureMessage)}
    restored=@{total=$restored.TotalCount;passed=$restored.PassedCount;failed=$restored.FailedCount}
    denials=$denials
    child=@{exitCode=$childExit;output=@($childOutput);allowedContent=[IO.File]::ReadAllText((Join-Path $work 'child-allowed.txt'))}
    cleanupCandidates=$created
    cleanupExcluded=@((Join-Path $run 'session-log.json'))
    deleted=@()
}
$result | ConvertTo-Json -Depth 8 -Compress
if ($normal.TotalCount -ne 1 -or $normal.PassedCount -ne 1 -or $mutated.FailedCount -ne 1 -or $restored.PassedCount -ne 1 -or $childExit -ne 0 -or $childOutput -notcontains 'child-denied') { exit 1 }
