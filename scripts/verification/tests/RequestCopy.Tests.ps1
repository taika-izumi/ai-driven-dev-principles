$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
$modulePath=Join-Path $PSScriptRoot '../RequestCopy.psm1'
Assert-True (Test-Path -LiteralPath $modulePath) 'コピー準備モジュールが未実装'
Import-Module $modulePath -Force
$count=0
function Check-Blocked($Request,$Settings) {
    $failure=$null
    try { New-VerificationRun -Request $Request -Settings $Settings | Out-Null }catch{$failure=$_}
    Assert-True ($null -ne $failure) '不正入力を拒否'
    Assert-Equal $failure.Exception.Data['status'] 'blocked' '起動前の拒否状態'
}
$case=New-TestCase 'copy-invalid'
$invalids=@(
    @{key='unexpected';value='unknown'},@{key='schemaVersion';value='1'},
    @{key='acceptanceCriteria';value=@()},@{key='acceptanceCriteria';value=@(' ')},
    @{key='extraInputPaths';value=@('../outside.txt')},@{key='extraInputPaths';value=@($case.root)},
    @{key='objective';value=''},@{key='caller';value='other'}
)
foreach($change in $invalids){$request=$case.request.Clone();$request[$change.key]=$change.value;Check-Blocked $request $case.settings;$count++}
$settings=$case.settings.Clone();$settings['extra']='bad';Check-Blocked $case.request $settings;$count++
foreach($bad in @($case.sourceRoot,$case.root)){$settings=$case.settings.Clone();$settings.runsRoot=$bad;Check-Blocked $case.request $settings;$count++}
$case=New-TestCase 'copy-content'
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'tracked.txt'),'working-tree')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '未追跡 file.txt'),'日本語')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '.gitignore'),'ignored.txt')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'ignored.txt'),'explicit-extra')
$case.request.extraInputPaths=@('ignored.txt')
[void][IO.Directory]::CreateDirectory((Join-Path $case.sourceRoot '.codex'))
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '.codex/config.toml'),'do-not-copy')
$run=New-VerificationRun -Request $case.request -Settings $case.settings
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.workRoot 'tracked.txt'))) 'working-tree' 'indexではなく作業内容'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.workRoot '未追跡 file.txt'))) '日本語' '空白と日本語の未追跡'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.workRoot 'ignored.txt'))) 'explicit-extra' '明示した無視対象'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $run.workRoot '.codex'))) '自動読込設定を除外'
Assert-True (@($run.sourceManifest.exclusions | Where-Object reason -EQ 'startup_config').Count -gt 0) '除外理由を残す'
Assert-Equal (& git -C $run.workRoot rev-parse --show-toplevel).Replace('/','\') $run.workRoot.Replace('/','\') '独立Git'
$count+=6
$nested=New-TestCase 'copy-nested';$nested.settings.runsRoot=Join-Path $nested.sourceRoot 'runs'
[void][IO.Directory]::CreateDirectory($nested.settings.runsRoot)
[IO.File]::WriteAllText((Join-Path $nested.settings.runsRoot 'old.txt'),'preserve')
$nr=New-VerificationRun -Request $nested.request -Settings $nested.settings
Assert-True (-not(Test-Path -LiteralPath (Join-Path $nr.workRoot 'runs'))) '原本内の出力を複製しない'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $nested.settings.runsRoot 'old.txt'))) 'preserve' '既存出力を保全'
$count+=2
$deleted=New-TestCase 'copy-deleted'
$deletePath=Join-Path $deleted.sourceRoot 'tracked.txt'
Assert-True ($deletePath.StartsWith($deleted.root+[IO.Path]::DirectorySeparatorChar)) '自分の試験領域だけを削除'
Remove-Item -LiteralPath $deletePath
$dr=New-VerificationRun -Request $deleted.request -Settings $deleted.settings
Assert-True (-not(Test-Path -LiteralPath (Join-Path $dr.workRoot 'tracked.txt'))) '削除済みを復活しない'
Assert-True $dr.sourceManifest.files[0].deleted '削除状態を保持'
$count+=2
$links=New-TestCase 'copy-links'
New-Item -ItemType Junction -Path (Join-Path $links.sourceRoot 'escape') -Target $links.runsRoot | Out-Null
Check-Blocked $links.request $links.settings
$linkedRequest=$links.request.Clone();$linkedRequest.sourceRoot=Join-Path $links.sourceRoot 'escape'
Check-Blocked $linkedRequest $links.settings
$count+=2
# コピー中変更を決定的に再現する。テストだけで内部コピー関数を包み、本体の再照合を実行する。
$changing=New-TestCase 'copy-changing'
$changePath=Join-Path $changing.sourceRoot 'tracked.txt'
& (Get-Module RequestCopy) {
    param($path)
    $script:testChangePath=$path
    $script:originalCopy=(Get-Command Copy-VerificationFile).ScriptBlock
    function script:Copy-VerificationFile($Source,$Destination){& $script:originalCopy $Source $Destination;[IO.File]::WriteAllText($script:testChangePath,'changed-during-copy')}
} $changePath
$failure=$null
try{New-VerificationRun -Request $changing.request -Settings $changing.settings | Out-Null}catch{$failure=$_}
Assert-True ($null -ne $failure) '途中変更で失敗'
Assert-Equal $failure.Exception.Data['status'] 'source_changed' '途中変更を検出'
Assert-True ([IO.Directory]::Exists($failure.Exception.Data['runRoot'])) '途中成果の場所を保持'
$count+=3
"RequestCopy: $count assertions/cases passed"
