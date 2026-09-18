# 試験失敗を握りつぶさず、実装用worktree内の新規領域だけを利用する。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Value, [string]$Because) {
    if (-not $Value) { throw "ASSERT: $Because" }
}
function Assert-Equal($Actual, $Expected, [string]$Because) {
    if ($Actual -cne $Expected) { throw "ASSERT: $Because; actual=$Actual expected=$Expected" }
}
function Assert-Throws([scriptblock]$Action, [string]$MessagePattern) {
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_ }
    if ($null -eq $failure -or $failure.Exception.Message -notlike $MessagePattern) {
        throw "ASSERT: expected exception $MessagePattern"
    }
}
function New-TestCase([string]$Name) {
    if ($Name -notmatch '^[a-z0-9-]+$') { throw '試験名は英小文字・数字・ハイフンに限定する' }
    $repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
    $root = Join-Path $repo ('.tmp/verification-tests/' + [guid]::NewGuid() + '-' + $Name)
    $source = Join-Path $root 'source'
    $runs = Join-Path $root 'runs'
    [void][IO.Directory]::CreateDirectory($source)
    [void][IO.Directory]::CreateDirectory($runs)
    $emptyTemplate = Join-Path $root 'empty-template'
    [void][IO.Directory]::CreateDirectory($emptyTemplate)
    & git -C $source init --quiet "--template=$emptyTemplate"
    if ($LASTEXITCODE -ne 0) { throw '試験用Git初期化失敗' }
    [IO.File]::WriteAllText((Join-Path $source 'tracked.txt'), 'baseline')
    & git -C $source add -- tracked.txt
    if ($LASTEXITCODE -ne 0) { throw '試験用ファイルのステージ失敗' }
    @{
        root=$root; sourceRoot=$source; runsRoot=$runs
        request=@{
            schemaVersion=1; caller='codex'; sourceRoot=$source
            objective='コピーされたファイルを検証する'
            acceptanceCriteria=@('入力とコピーの内容が一致する'); extraInputPaths=@()
        }
        settings=@{
            codexPath=(Get-Command codex -ErrorAction Stop).Source
            pwshPath=(Get-Command pwsh -ErrorAction Stop).Source
            runsRoot=$runs; model='unit-test'; timeoutSeconds=30
        }
    }
}
Export-ModuleMember -Function Assert-True,Assert-Equal,Assert-Throws,New-TestCase
