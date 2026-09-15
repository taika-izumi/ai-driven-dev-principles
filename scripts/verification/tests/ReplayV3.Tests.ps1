$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/V3TestContext.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../SbxRuntime.psm1') -Force -DisableNameChecking   # Acquire- は仕様02の公開操作名（未承認動詞の警告を抑止）
Import-Module (Join-Path $PSScriptRoot '../Replay.psm1') -Force
# 再実行（仕様04）の試験。入力検査・入力生成と差分照合・標準ライブラリ検査・未実行結果は VM なしで内部関数を直接呼び、VM を要する経路だけ偽sbxを使う。
# 実 VM・実デーモン・ホストの Python は動かさない（受け取ったテスト・修正候補をホストで実行しない）。偽sbxの成功を実機の実証に数えない。
# ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$base=Join-Path $repo '.tmp/verification-tests'
$utf8=[Text.UTF8Encoding]::new($false)
$pilot=Join-Path $PSScriptRoot 'fixtures/pilot-source'
$stdlibFixture=Join-Path $PSScriptRoot 'fixtures/stdlib-modules.txt'
$replayModule=Get-Module Replay
$count=0
$allCases=[Collections.Generic.List[hashtable]]::new()
$buggyText=[IO.File]::ReadAllText((Join-Path $pilot 'source/calc.py'),$utf8)
$fixedText=[IO.File]::ReadAllText((Join-Path $pilot 'replacements/calc.py'),$utf8)
$testText=[IO.File]::ReadAllText((Join-Path $pilot 'tests/test_calc.py'),$utf8)
function Get-Hash([string]$Path){Get-V3TestHash $Path}
function New-ReplayCtx([hashtable]$Limits=@{},[int]$CleanupSeconds=5,[int]$DeadlineIn=900){
    # 基準版は合成題材（calc.py）と README・.git の一部（再実行へ搬入しないことを確かめる）。
    $root=Join-Path $base ('r5'+[guid]::NewGuid().ToString('N').Substring(0,6))
    $files=[ordered]@{'calc.py'=$buggyText;'README.md'="# pilot`n";'.git/HEAD'="ref: refs/heads/master`n"}
    $ctx=New-V3TestContext $root $files -Limits $Limits -CleanupSeconds $CleanupSeconds -DeadlineIn $DeadlineIn -StdlibModulesPath $stdlibFixture
    $script:allCases.Add($ctx)
    $ctx
}
function New-Proposal([hashtable]$Ctx,[System.Collections.IDictionary]$Tests=$null,[System.Collections.IDictionary]$Replacements=$null,[string]$Origin='generated'){
    # Proposal の ready 結果と同じ形（accepted/tests・accepted/replacements、control/proposal/manifest.json、testsManifestHash は test の {path,size,sha256} の正規化JSONの SHA256）。
    if($null -eq $Tests){$Tests=[ordered]@{'test_calc.py'=$testText}}
    if($null -eq $Replacements){$Replacements=[ordered]@{}}
    $accepted=$Ctx.prepared.acceptedRoot
    $artifacts=[Collections.Generic.List[object]]::new()
    foreach($name in $Tests.Keys){Write-V3TestText (Join-Path $accepted "tests/$name") ([string]$Tests[$name]);$full=Join-Path $accepted "tests/$name";$artifacts.Add(@{kind='test';path="tests/$name";size=[long]([IO.FileInfo]::new($full)).Length;sha256=(Get-Hash $full)})}
    foreach($target in $Replacements.Keys){Write-V3TestText (Join-Path $accepted "replacements/$target") ([string]$Replacements[$target]);$full=Join-Path $accepted "replacements/$target";$artifacts.Add(@{kind='replacement';path="replacements/$target";size=[long]([IO.FileInfo]::new($full)).Length;sha256=(Get-Hash $full)})}
    $artifacts.Sort([Comparison[object]]{param($l,$r) [string]::CompareOrdinal($l.path,$r.path)})
    $sorted=[object[]]$artifacts.ToArray()
    $testsHash=Get-VerificationCanonicalHash -Object ([object[]]@($sorted | Where-Object {$_.kind -eq 'test'} | ForEach-Object {@{path=$_.path;size=$_.size;sha256=$_.sha256}}))
    $manifestPath=Join-Path $Ctx.controlRoot 'proposal/manifest.json'
    Write-VerificationNewFile $manifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$Ctx.runId;origin=$Origin;artifacts=$sorted;testsManifestHash=$testsHash})
    $sandbox=$null;$stopState='not-created'
    if($Origin -eq 'generated'){$sandbox=@{runId=$Ctx.runId;role='proposal';name=$Ctx.names.proposal;id=[guid]::NewGuid().ToString();createdAt=[DateTime]::UtcNow.ToString('o')};$stopState='stopped'}
    else{$Ctx.prepared.recheckArtifacts=[object[]]@($sorted | ForEach-Object {@{kind='test';path=$_.path;size=$_.size;sha256=$_.sha256;previousRunId=[guid]::NewGuid().ToString()}})}
    @{schemaVersion=3;runId=$Ctx.runId;status='ready';origin=$Origin;sandbox=$sandbox;summary='fixture';findings=@();artifacts=$sorted;manifestPath=$manifestPath;manifestHash=(Get-Hash $manifestPath);testsManifestHash=$testsHash;stopState=$stopState;failure=$null}
}
function Invoke-Internal([scriptblock]$Block,[object[]]$Arguments){& $replayModule $Block @Arguments}
function Get-Failure([scriptblock]$Action){try{& $Action | Out-Null}catch{return $_.Exception};throw "ASSERT: expected an exception (line $($MyInvocation.ScriptLineNumber))"}
function Assert-Failure([scriptblock]$Action,[string]$Status,[string]$Reason,[string]$Label){
    $failure=Get-Failure $Action
    Assert-True ($failure.Data['status'] -ceq $Status -and $failure.Data['reason'] -ceq $Reason) "${Label}: $Status / $Reason（実際 $($failure.Data['status']) / $($failure.Data['reason']): $($failure.Message)）"
}
function Test-Proposal([hashtable]$Ctx,[hashtable]$Proposal){Invoke-Internal {param($p,$r) Test-ReplayProposal $p $r} @($Ctx.prepared,$Proposal)}
function Build-Inputs([hashtable]$Ctx,[hashtable]$Checked){
    # mode どおりに replay-inputs を作る（Invoke-VerificationReplay と同じ組合せ）。
    Invoke-Internal {param($p,$c)
        $before=$null;$after=$null
        if($c.mode -cne 'recheck'){$before=New-ReplayInput $p $c 'before' $false}
        if($c.mode -cne 'reproduction-only'){$after=New-ReplayInput $p $c 'after' ($c.mode -ceq 'candidate-comparison')}
        @{before=$before;after=$after}
    } @($Ctx.prepared,$Checked)
}
function Test-Inputs([hashtable]$Checked,[hashtable]$Roots){Invoke-Internal {param($c,$r) Test-ReplayInputs $c $c.mode $r.before $r.after} @($Checked,$Roots)}

try{
# 1. 入力検査の正常系: mode は replacement ありで candidate-comparison、なしで reproduction-only、recheck で recheck。基準版の .git は作業ファイルに入れない。
$ctx=New-ReplayCtx
$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}))
Assert-Equal $checked.mode 'candidate-comparison' '入力検査: replacement ありは candidate-comparison'
Assert-Equal (@($checked.workFiles.Keys) -join ',') 'README.md,calc.py' '入力検査: 作業ファイルは .git を除く基準版'
Assert-True (@($checked.tests).Count -eq 1 -and $checked.tests[0].name -ceq 'test_calc.py' -and @($checked.replacements).Count -eq 1 -and $checked.replacements[0].target -ceq 'calc.py') '入力検査: tests と replacements の区分'
$ctx=New-ReplayCtx
Assert-Equal (Test-Proposal $ctx (New-Proposal $ctx)).mode 'reproduction-only' '入力検査: replacement なしは reproduction-only'
$ctx=New-ReplayCtx
Assert-Equal (Test-Proposal $ctx (New-Proposal $ctx -Origin 'reused-tests')).mode 'recheck' '入力検査: 再利用テストは recheck'
$count++

# 2. 入力検査の拒否（すべて blocked）: 非ready・別runId・origin ごとの条件・manifestHash・一覧の相違・accepted の追加/改変・baseline の期待hash/改変・基準版に無い replacement。
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$edited=$proposal.Clone();$edited.status='failed'
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'proposal-not-ready' '非ready'
$edited=$proposal.Clone();$edited.runId=[guid]::NewGuid().ToString()
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'run-id' '別runId'
$edited=$proposal.Clone();$edited.stopState='unverified'
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'proposal-origin' 'generated で提案VMの停止未確認'
$edited=$proposal.Clone();$edited.origin='reused-tests';$edited.sandbox=$null;$edited.stopState='not-created'
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'proposal-origin' 'recheck でない run の reused-tests'
$edited=$proposal.Clone();$edited.manifestHash=('A'*64)
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'proposal-manifest' 'manifestHash 不一致'
$edited=$proposal.Clone();$edited.artifacts=[object[]]@($proposal.artifacts | Where-Object {$_.kind -eq 'test'})
Assert-Failure {Test-Proposal $ctx $edited} 'blocked' 'proposal-manifest' 'artifacts が manifest と違う'
Write-V3TestText (Join-Path $ctx.prepared.acceptedRoot 'tests/test_extra.py') "import unittest`n"
Assert-Failure {Test-Proposal $ctx $proposal} 'blocked' 'accepted-changed' 'accepted に一覧外のファイル'
[IO.File]::Move((Join-Path $ctx.prepared.acceptedRoot 'tests/test_extra.py'),(Join-Path $ctx.root 'moved-extra.py'))
Write-V3TestText (Join-Path $ctx.prepared.acceptedRoot 'replacements/calc.py') "def add(a, b):`n    return 3`n"
Assert-Failure {Test-Proposal $ctx $proposal} 'blocked' 'accepted-changed' 'accepted の内容が変わった'
Write-V3TestText (Join-Path $ctx.prepared.acceptedRoot 'replacements/calc.py') $fixedText
[void](Test-Proposal $ctx $proposal)
$edited=$ctx.prepared.Clone();$edited.baselineManifestHash=('B'*64)
Assert-Failure {Invoke-Internal {param($p,$r) Test-ReplayProposal $p $r} @($edited,$proposal)} 'blocked' 'baseline-manifest' 'baseline manifest の期待hash 不一致'
Write-V3TestText (Join-Path $ctx.prepared.baselineRoot 'README.md') "# changed`n"
Assert-Failure {Test-Proposal $ctx $proposal} 'blocked' 'baseline-changed' 'baseline の改変'
$ctx=New-ReplayCtx
Assert-Failure {Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'other.py'="x = 1`n"}))} 'blocked' 'proposal-artifacts' '基準版に無い replacement'
$count++

# 3. 入力生成と差分照合（candidate-comparison）: before は基準版、after は replacement 適用後。両方の .verification-tests に同じ tests。.git は搬入しない。input manifest を CreateNew で保存。
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}))
$roots=Build-Inputs $ctx $checked
$verified=Test-Inputs $checked $roots
Assert-True ($verified.diffChecked -eq $true) '差分照合: candidate-comparison で実施'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $roots.before 'calc.py'),$utf8)) $buggyText 'before: 基準版の calc.py'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $roots.after 'calc.py'),$utf8)) $fixedText 'after: replacement 適用後の calc.py'
foreach($root in @($roots.before,$roots.after)){
    Assert-Equal ([IO.File]::ReadAllText((Join-Path $root '.verification-tests/test_calc.py'),$utf8)) $testText "入力: .verification-tests 直下に test（$root）"
    Assert-True (-not(Test-Path -LiteralPath (Join-Path $root '.git'))) "入力: .git を搬入しない（$root）"
}
Assert-True ($roots.before -ceq (Join-Path $ctx.runRoot 'replay-inputs/before') -and $roots.after -ceq (Join-Path $ctx.runRoot 'replay-inputs/after')) '入力: replay-inputs/before・after'
$saved=Invoke-Internal {param($p,$v) Save-ReplayInputManifest $p 'candidate-comparison' $v.inputs.after} @($ctx.prepared,$verified)
$manifest=Get-Content -LiteralPath $saved.path -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($saved.path -ceq (Join-Path $ctx.controlRoot 'replay/replay-after-input-manifest.json') -and $saved.hash -ceq (Get-Hash $saved.path)) 'input manifest: control/replay の保存先と hash'
Assert-Equal (@($manifest.files | ForEach-Object {$_.path}) -join ',') '.verification-tests/test_calc.py,README.md,calc.py' 'input manifest: 全搬入ファイル（序数順）'
Assert-True ($manifest.testsManifestHash -ceq $checked.testsManifestHash -and $manifest.role -ceq 'replay-after' -and $manifest.runId -ceq $ctx.runId) 'input manifest: testsManifestHash・role・runId'
Assert-True ((@($saved.expected.files | Where-Object {$_.path -eq 'calc.py'})[0].sha256) -ceq (Get-Hash (Join-Path $roots.after 'calc.py'))) 'input manifest: 搬入の期待一覧は after の実体'
$failure=Get-Failure {Invoke-Internal {param($p,$v) Save-ReplayInputManifest $p 'candidate-comparison' $v.inputs.after} @($ctx.prepared,$verified)}
Assert-True ($failure -is [IO.IOException] -or $failure.InnerException -is [IO.IOException]) "input manifest: 既存を上書きしない（CreateNew。$($failure.GetType().Name)）"
$failure=Get-Failure {Build-Inputs $ctx $checked}
Assert-True ($failure.Data['reason'] -ceq 'replay-input-exists') '入力: 既存の replay-inputs へは作り直さない'
$count++

# 4. 差分照合の拒否（incomplete）: tests が before/after で違う・replacement 一覧に無い差分・replacement が after に反映されていない。内容が基準版と同じ replacement は拒否しない。
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.after '.verification-tests/test_calc.py') ($testText+"`n# changed`n")
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-tests-differ' 'テスト集合が before/after で異なる'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.after '.verification-tests/test_more.py') "import unittest`n"
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-tests-differ' 'after にだけ test が増えた'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.after 'README.md') "# changed outside replacements`n"
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-diff-outside-replacements' 'after の差分が replacement 一覧に無いパスを含む'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.after 'extra.py') "x = 1`n"
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-diff-outside-replacements' 'after に基準版に無いファイル'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.after 'calc.py') $buggyText
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replacement-not-applied' 'replacement が after に反映されていない（差分なし）'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText}));$roots=Build-Inputs $ctx $checked
Write-V3TestText (Join-Path $roots.before 'calc.py') $fixedText
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-input-baseline' 'before が基準版と違う'
$count++

# 5. 内容が基準版と同一の replacement・recheck（差分照合を行わない）・reproduction-only（after を作らない）。
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$buggyText}))
Assert-Equal $checked.mode 'candidate-comparison' '同一内容の replacement: mode'
$roots=Build-Inputs $ctx $checked
$verified=Test-Inputs $checked $roots
Assert-True ($verified.diffChecked -eq $true) '同一内容の replacement: 差分に現れなくても incomplete にしない'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Origin 'reused-tests')
$roots=Build-Inputs $ctx $checked
Assert-True ($null -eq $roots.before -and -not(Test-Path -LiteralPath (Join-Path $ctx.runRoot 'replay-inputs/before'))) 'recheck: before の入力を作らない'
$verified=Test-Inputs $checked $roots
Assert-True ($verified.diffChecked -eq $false -and -not$verified.inputs.Contains('before') -and $verified.inputs.after.testsManifestHash -ceq $checked.testsManifestHash) 'recheck: 差分照合を行わず、testsManifestHash と基準版だけを照合'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $roots.after 'calc.py'),$utf8)) $buggyText 'recheck: after は現在版（基準版）そのもの'
Write-V3TestText (Join-Path $roots.after 'README.md') "# changed`n"
Assert-Failure {Test-Inputs $checked $roots} 'incomplete' 'replay-input-baseline' 'recheck: after が基準版と違えば incomplete'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx)
$roots=Build-Inputs $ctx $checked
Assert-True ($null -eq $roots.after -and -not(Test-Path -LiteralPath (Join-Path $ctx.runRoot 'replay-inputs/after'))) 'reproduction-only: after の入力を作らない'
Assert-True ((Test-Inputs $checked $roots).diffChecked -eq $false) 'reproduction-only: 差分照合なし'
$count++

# 6. 標準ライブラリ検査（VM 不要）: 題材内（calc・tests の名前）と一覧内は通し、一覧外は blocked。相対 import は数えない。
$modules=Invoke-Internal {param($t) Get-ReplayImportedModules $t} @("import os.path, json as j`nfrom __future__ import annotations`nfrom . import sibling`nfrom .pkg import x`nimport calc  # comment`nx = 1; import re`n    from xml.dom import minidom`n")
Assert-Equal (@($modules | Sort-Object) -join ',') '__future__,calc,json,os,re,xml' 'import 列挙: 最上位名・相対 import を除く・; と字下げ'
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Tests ([ordered]@{'test_calc.py'=$testText;'test_helper_use.py'="import unittest`nimport test_calc`n"}) -Replacements ([ordered]@{'calc.py'="import functools`n"+$fixedText}))
Invoke-Internal {param($p,$r,$c) Test-ReplayStdlibImports $p $r $c} @($ctx.prepared,$ctx.replayProfile,$checked)
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Tests ([ordered]@{'test_calc.py'="import unittest`nimport requests`nimport calc`n"}))
$failure=Get-Failure {Invoke-Internal {param($p,$r,$c) Test-ReplayStdlibImports $p $r $c} @($ctx.prepared,$ctx.replayProfile,$checked)}
Assert-True ($failure.Data['status'] -ceq 'blocked' -and $failure.Data['reason'] -ceq 'stdlib-outside' -and $failure.Message -like '*requests (tests/test_calc.py)*') "標準ライブラリ外（test）: blocked（$($failure.Message)）"
$ctx=New-ReplayCtx;$checked=Test-Proposal $ctx (New-Proposal $ctx -Replacements ([ordered]@{'calc.py'="from numpy import array`n"+$fixedText}))
Assert-Failure {Invoke-Internal {param($p,$r,$c) Test-ReplayStdlibImports $p $r $c} @($ctx.prepared,$ctx.replayProfile,$checked)} 'blocked' 'stdlib-outside' '標準ライブラリ外（replacement）'
$tampered=$ctx.replayProfile.Clone();$tampered.stdlibModulesHash=('C'*64)
Assert-Failure {Invoke-Internal {param($p,$r,$c) Test-ReplayStdlibImports $p $r $c} @($ctx.prepared,$tampered,$checked)} 'blocked' 'stdlib-list' '一覧の hash 不一致'
$count++

# 7. New-VerificationReplayNotRun: status=not_run・sandboxes=[]・before/after/allStopped=null・上流の failure。作成成否不明は not_run へ丸めず incomplete。
$ctx=New-ReplayCtx
$notRun=New-VerificationReplayNotRun $ctx.prepared @{stage='agent';reason='agent-failed'}
Assert-Equal (@($notRun.Keys | Sort-Object) -join ',') 'after,allStopped,before,failure,mode,runId,sandboxes,schemaVersion,status' 'not_run: キー'
Assert-True ($notRun.schemaVersion -eq 3 -and $notRun.runId -ceq $ctx.runId -and $notRun.status -ceq 'not_run' -and $notRun.sandboxes -is [object[]] -and $notRun.sandboxes.Count -eq 0) 'not_run: status・空の sandboxes'
Assert-True ($null -eq $notRun.before -and $null -eq $notRun.after -and $null -eq $notRun.allStopped -and $null -eq $notRun.mode) 'not_run: before/after/allStopped/mode は null'
Assert-True ($notRun.failure.stage -ceq 'agent' -and $notRun.failure.reason -ceq 'agent-failed' -and (@($notRun.failure.Keys | Sort-Object) -join ',') -ceq 'reason,stage') 'not_run: 上流の失敗段階'
Assert-Equal (ConvertTo-VerificationCanonicalJson $notRun) ('{"after":null,"allStopped":null,"before":null,"failure":{"reason":"agent-failed","stage":"agent"},"mode":null,"runId":"'+$ctx.runId+'","sandboxes":[],"schemaVersion":3,"status":"not_run"}') 'not_run: 正規化JSONの書式'
$unresolved=New-VerificationReplayNotRun $ctx.prepared @{stage='sandbox';reason='creation-unresolved'}
Assert-True ($unresolved.status -ceq 'incomplete' -and $unresolved.failure.reason -ceq 'creation-unresolved' -and $unresolved.sandboxes.Count -eq 0) '作成成否不明: not_run へ丸めず incomplete'
$unknown=New-VerificationReplayNotRun $ctx.prepared @{stage='sandbox';reason='create-timed-out';creationState='unknown'}
Assert-True ($unknown.status -ceq 'incomplete' -and $unknown.failure.reason -ceq 'creation-unresolved') 'creationState=unknown も incomplete（理由は creation-unresolved）'
[void](New-Proposal $ctx -Origin 'reused-tests')
Assert-Equal (New-VerificationReplayNotRun $ctx.prepared @{stage='recheck';reason='recheck-tests-changed'}).mode 'recheck' 'not_run: recheck の run は mode=recheck'
Assert-Throws {New-VerificationReplayNotRun $ctx.prepared @{stage='agent'}} '*stage and reason*'
Assert-Throws {New-VerificationReplayNotRun @{schemaVersion=1} @{stage='a';reason='b'}} '*PreparedRunV3*'
Assert-Equal @(Get-CaseFakeProcesses $allCases.ToArray()).Count 0 'VM なしの試験: 偽sbxを起動していない'
$count++

}finally{
    if($allCases.Count -gt 0){try{Stop-CaseFakeProcesses $allCases.ToArray()}catch{}}
}
Assert-Equal @(Get-CaseFakeProcesses $allCases.ToArray()).Count 0 '全ケース: 試験が起動した偽sbxプロセスが残っていない'
"ReplayV3: $count cases passed"
