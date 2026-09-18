$ErrorActionPreference='Stop'
$pwsh=(Get-Command pwsh -ErrorAction Stop).Source
# v1 の4群と v3 の7群を順に実行し、失敗した群で止まる。v3 は偽sbxを使い、実VM・実デーモン・モデルは起動しない（全体で約26分）。
# 群は同じ名前付き Mutex などを共有するので並行に実行しない。各群の開始前に群名を、終了後に経過秒を出す（最後の行は従来どおり）。
$suites=@(
    'RequestCopy.Tests.ps1','History.Tests.ps1','Execution.Tests.ps1','Result.Tests.ps1',
    'RequestCopyV3.Tests.ps1','ExecutionV3.Tests.ps1','SbxRuntimeV3.Tests.ps1','ProposalV3.Tests.ps1','ReplayV3.Tests.ps1','ResultV3.Tests.ps1','CliV3.Tests.ps1'
)
foreach($test in $suites){
    "suite: $test"
    $watch=[Diagnostics.Stopwatch]::StartNew()
    & $pwsh -NoProfile -File (Join-Path $PSScriptRoot $test)
    $exitCode=$LASTEXITCODE
    $watch.Stop()
    "suite: $test finished in $([int]$watch.Elapsed.TotalSeconds)s (exit $exitCode)"
    if($exitCode -ne 0){exit $exitCode}
}
"Independent verification: $($suites.Count) suites passed (no agent launched)"
