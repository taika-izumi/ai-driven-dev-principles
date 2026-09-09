# 履歴を渡さない変更、原本との共有、現在のファイルの上書きを検出する。
$ErrorActionPreference='Stop'
$env:GIT_CONFIG_GLOBAL='NUL';$env:GIT_CONFIG_NOSYSTEM='1'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
function Invoke-TestGit([string]$Root,[string[]]$Arguments){
    $out=& git -c user.name=VerificationTest -c user.email=test@example.invalid -C $Root @Arguments 2>&1
    if($LASTEXITCODE -ne 0){throw "git failed: $($Arguments -join ' '): $out"}
    (($out | ForEach-Object {"$_"}) -join "`n").Trim()
}
$case=New-TestCase 'history'
$null=Invoke-TestGit $case.sourceRoot @('commit','--quiet','-m','first')
$first=Invoke-TestGit $case.sourceRoot @('rev-parse','HEAD')
$null=Invoke-TestGit $case.sourceRoot @('tag','v1')
$null=Invoke-TestGit $case.sourceRoot @('branch','context')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'tracked.txt'),'second')
$null=Invoke-TestGit $case.sourceRoot @('add','tracked.txt');$null=Invoke-TestGit $case.sourceRoot @('commit','--quiet','-m','second')
$null=Invoke-TestGit $case.sourceRoot @('checkout','--quiet','--detach')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'tracked.txt'),'detached')
$null=Invoke-TestGit $case.sourceRoot @('add','tracked.txt');$null=Invoke-TestGit $case.sourceRoot @('commit','--quiet','-m','detached')
$head=Invoke-TestGit $case.sourceRoot @('rev-parse','HEAD')
$null=Invoke-TestGit $case.sourceRoot @('config','transfer.probe','do-not-import')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'tracked.txt'),'working-change')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot 'extra.txt'),'untracked')
$sourceStatus=Invoke-TestGit $case.sourceRoot @('status','--porcelain=v1')
$sourceConfig=(Get-FileHash (Join-Path $case.sourceRoot '.git/config')).Hash
$run=New-VerificationRun $case.request $case.settings
Assert-Equal (Invoke-TestGit $run.workRoot @('rev-parse','HEAD')) $head '履歴のHEADを保持'
Assert-Equal (Invoke-TestGit $run.workRoot @('rev-list','--count','HEAD')) '3' 'HEADの履歴を保持'
Assert-Equal (Invoke-TestGit $run.workRoot @('show',($first+':tracked.txt'))) 'baseline' '過去の本文を参照'
Assert-Equal (Invoke-TestGit $run.workRoot @('rev-parse','v1')) $first 'タグを参照'
Assert-Equal (Invoke-TestGit $run.workRoot @('rev-parse','context')) $first '別ブランチを参照'
Assert-True ((Invoke-TestGit $run.workRoot @('blame','--line-porcelain','HEAD','--','tracked.txt')).Contains('summary detached')) '履歴のblame'
Assert-Equal (Invoke-TestGit $run.workRoot @('status','--porcelain=v1')) $sourceStatus '未コミットと未追跡を保持'
Assert-True (-not([IO.File]::ReadAllText((Join-Path $run.workRoot '.git/config')).Contains('do-not-import'))) '原本の設定を持ち込まない'
Assert-True (-not(Test-Path (Join-Path $run.workRoot '.git/objects/info/alternates'))) '外部オブジェクト参照なし'
Assert-Equal (Invoke-TestGit $run.workRoot @('rev-parse','--git-common-dir')) '.git' '原本と管理領域を共有しない'
$null=Invoke-TestGit $run.workRoot @('fsck','--full','--no-reflogs')
Assert-Equal (Invoke-TestGit $case.sourceRoot @('status','--porcelain=v1')) $sourceStatus '原本の作業内容を保全'
Assert-Equal (Get-FileHash (Join-Path $case.sourceRoot '.git/config')).Hash $sourceConfig '原本の設定を保全'
# HEADやファイルが同じでも、別ブランチが動いたら対象版の更新である。
$null=Invoke-TestGit $case.sourceRoot @('update-ref','refs/heads/context',$head)
$after=Get-VerificationSourceManifest $case.request $case.settings
Assert-True (-not(Test-VerificationManifestEqual $run.sourceManifest $after)) '参照先の更新を検出'
# 初回コミット前は空の履歴として正常に準備する。
$empty=New-TestCase 'history-empty'
$er=New-VerificationRun $empty.request $empty.settings
Assert-True ($null -eq $er.sourceManifest.head) 'コミットなしを偽の履歴にしない'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $er.workRoot 'tracked.txt'))) 'baseline' 'コミット前の内容を保持'
# 入力がlinked worktreeでも、コピーは共通Git管理領域へ依存しない。
$linked=Join-Path $case.root 'linked'
$null=Invoke-TestGit $case.sourceRoot @('worktree','add','--quiet','--detach',$linked,$first)
$request=$case.request.Clone();$request.sourceRoot=$linked
$lr=New-VerificationRun $request $case.settings
Assert-Equal (Invoke-TestGit $lr.workRoot @('show','HEAD:tracked.txt')) 'baseline' 'worktree入力の履歴'
Assert-Equal (Invoke-TestGit $lr.workRoot @('rev-parse','--git-common-dir')) '.git' 'worktree入力でも管理領域は独立'
# 不完全な履歴を完全と報告せず、外部から自動取得しない。
$null=Invoke-TestGit $case.sourceRoot @('config','remote.unavailable.promisor','true')
Assert-Throws {New-VerificationRun $case.request $case.settings} '*shallow/partial*'
$null=Invoke-TestGit $case.sourceRoot @('config','--unset','remote.unavailable.promisor')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '.git/shallow'),$head+"`n")
Assert-Throws {New-VerificationRun $case.request $case.settings} '*shallow/partial*'
$unborn=New-TestCase 'hu'
$null=Invoke-TestGit $unborn.sourceRoot @('commit','--quiet','-m','existing history')
$null=Invoke-TestGit $unborn.sourceRoot @('branch','-M','master')
$null=Invoke-TestGit $unborn.sourceRoot @('symbolic-ref','HEAD','refs/heads/unborn')
$ur=New-VerificationRun $unborn.request $unborn.settings
Assert-Throws {Invoke-TestGit $ur.workRoot @('rev-parse','--verify','HEAD')} '*git failed*'
$attached=New-TestCase 'attached'
$null=Invoke-TestGit $attached.sourceRoot @('commit','--quiet','-m','attached')
$sourceHeadRef=Invoke-TestGit $attached.sourceRoot @('symbolic-ref','HEAD')
$ar=New-VerificationRun $attached.request $attached.settings
Assert-Equal (Invoke-TestGit $ar.workRoot @('symbolic-ref','HEAD')) $sourceHeadRef '原本のブランチ名を保持'
Assert-Equal (Invoke-TestGit $ur.workRoot @('symbolic-ref','HEAD')) 'refs/heads/unborn' 'コミット前のブランチ名も保持'
$null=Invoke-TestGit $attached.sourceRoot @('branch','same-commit')
$beforeSwitch=Get-VerificationSourceManifest $attached.request $attached.settings
$null=Invoke-TestGit $attached.sourceRoot @('symbolic-ref','HEAD','refs/heads/same-commit')
$afterSwitch=Get-VerificationSourceManifest $attached.request $attached.settings
Assert-True (-not(Test-VerificationManifestEqual $beforeSwitch $afterSwitch)) '同じコミットへのブランチ切り替えも検出'
'History: 23 assertions and git fsck passed'
