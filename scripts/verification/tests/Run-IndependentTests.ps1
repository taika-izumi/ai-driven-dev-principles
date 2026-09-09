$ErrorActionPreference='Stop'
$pwsh=(Get-Command pwsh -ErrorAction Stop).Source
foreach($test in @('RequestCopy.Tests.ps1','Execution.Tests.ps1','Result.Tests.ps1')){
    & $pwsh -NoProfile -File (Join-Path $PSScriptRoot $test)
    if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
}
'Independent verification: 3 suites passed (no agent launched)'
