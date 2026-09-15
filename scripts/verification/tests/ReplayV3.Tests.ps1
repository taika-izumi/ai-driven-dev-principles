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
function New-ReplayCtx([hashtable]$Limits=@{},[int]$CleanupSeconds=30,[int]$DeadlineIn=900){
    # 基準版は合成題材（calc.py）と README・.git の一部（再実行へ搬入しないことを確かめる）。
    # 停止猶予は既定30秒（計画の初期値）。偽sbxは1呼び出し約1.2秒かかり、5秒では停止後の世代照会が cleanupDeadlineAt を越えて停止未確認になることがあった（実測）。
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

# 8. Invoke-VerificationReplay の VM 作成前の拒否（sbx を1回も呼ばない）: 非ready・標準ライブラリ外 import・別 digest の profile。
function Assert-NoSbxCall([hashtable]$Ctx,[string]$Label){Assert-True (-not(Test-Path -LiteralPath $Ctx.case.callsPath)) "${Label}: sbx を呼ばない（VM 未作成）"}
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText});$proposal.status='incomplete'
$r=Invoke-VerificationReplay $ctx.prepared $proposal $ctx.replayProfile $null
Assert-True ($r.status -ceq 'blocked' -and $r.failure.stage -ceq 'proposal-input' -and $r.failure.reason -ceq 'proposal-not-ready' -and $null -eq $r.mode -and $r.sandboxes.Count -eq 0 -and $null -eq $r.allStopped) "非ready: blocked（$(ConvertTo-VerificationCanonicalJson $r)）"
Assert-NoSbxCall $ctx '非ready'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Tests ([ordered]@{'test_calc.py'="import unittest`nimport yaml`nimport calc`n"})
$r=Invoke-VerificationReplay $ctx.prepared $proposal $ctx.replayProfile $null
Assert-True ($r.status -ceq 'blocked' -and $r.failure.stage -ceq 'stdlib' -and $r.failure.reason -ceq 'stdlib-outside' -and $r.mode -ceq 'reproduction-only' -and $r.sandboxes.Count -eq 0 -and $null -eq $r.before) "標準ライブラリ外: VM 未作成の blocked（$(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.runRoot 'replay-inputs/before'))) '標準ライブラリ外: replay-inputs を作らない'
Assert-NoSbxCall $ctx '標準ライブラリ外'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$otherDigest=$ctx.replayProfile.Clone();$otherDigest.templateDigest='docker.io/docker/sandbox-templates@sha256:'+('0'*64)
$r=Invoke-VerificationReplay $ctx.prepared $proposal $otherDigest $null
Assert-True ($r.status -ceq 'blocked' -and $r.failure.stage -ceq 'profile' -and $r.sandboxes.Count -eq 0) "別 digest の profile（証拠と対応しない）: blocked（$(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-NoSbxCall $ctx '別 digest の profile'
$count++

# 9. VM 作成の失敗（New-VerificationSandbox を試験だけが Replay の script スコープで差し替える）: 作成成否不明は not_run・未作成へ丸めず incomplete（creation-unresolved・allStopped=false）。
# 作成済み・停止済みの部分 handle は sandboxes に残し、次の役割の VM を作らない。
function Invoke-WithCreationFailure([hashtable]$Ctx,[hashtable]$Proposal,[string]$Status,$RuntimeFailure){
    & $replayModule {param($s,$rf)
        $script:FakeCreation=@{status=$s;runtimeFailure=$rf;calls=[Collections.Generic.List[string]]::new()}
        function script:New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile,[hashtable]$Lease){
            $script:FakeCreation.calls.Add($Role)
            $e=[InvalidOperationException]::new('fake creation failure');$e.Data['status']=$script:FakeCreation.status
            if($null -ne $script:FakeCreation.runtimeFailure){$e.Data['runtimeFailure']=$script:FakeCreation.runtimeFailure}
            throw $e
        }
    } $Status $RuntimeFailure
    try{$r=Invoke-VerificationReplay $Ctx.prepared $Proposal $Ctx.replayProfile $null;$calls=& $replayModule {@($script:FakeCreation.calls)}}
    finally{
        # 差し替えは取り込み済みの公開操作を上書きするので、Replay を読み直して元へ戻す（SbxRuntime は -Force なしの取り込みで同じインスタンスを使う）。
        Import-Module (Join-Path $PSScriptRoot '../Replay.psm1') -Force
        $script:replayModule=Get-Module Replay
    }
    @{result=$r;calls=@($calls)}
}
function New-RuntimeFailureJson([string]$Creation,[string]$Stop,$Handle){ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId='x';role='replay-before';stage='create';reason='create-timed-out';message='m';creationState=$Creation;handle=$Handle;stopState=$Stop}}
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$o=Invoke-WithCreationFailure $ctx $proposal 'incomplete' (New-RuntimeFailureJson 'unknown' 'unverified' $null)
Assert-True ($o.result.status -ceq 'incomplete' -and $o.result.failure.reason -ceq 'creation-unresolved' -and $o.result.failure.stage -ceq 'replay-before' -and $o.result.sandboxes.Count -eq 0 -and $o.result.allStopped -eq $false -and $null -eq $o.result.before -and $null -eq $o.result.after) "作成成否不明: incomplete（$(ConvertTo-VerificationCanonicalJson $o.result)）"
Assert-Equal ($o.calls -join ',') 'replay-before' '作成成否不明: after の VM を作らない'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$o=Invoke-WithCreationFailure $ctx $proposal 'incomplete' $null
Assert-True ($o.result.status -ceq 'incomplete' -and $o.result.failure.reason -ceq 'creation-unresolved' -and $o.result.allStopped -eq $false) 'runtimeFailure の欠落: creation-unresolved'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$partial=@{schemaVersion=3;runId=$ctx.runId;role='replay-before';name=$ctx.names['replay-before'];id=[guid]::NewGuid().ToString();createdAt='2026-09-15T00:00:00.0000000Z';profileHash=('A'*64);effectiveSettingsHash=('B'*64);activationRecordPath=$null;activationRecordHash=$null}
$o=Invoke-WithCreationFailure $ctx $proposal 'blocked' (New-RuntimeFailureJson 'created' 'stopped' $partial)
Assert-True ($o.result.status -ceq 'blocked' -and $o.result.sandboxes.Count -eq 1 -and $o.result.sandboxes[0].id -ceq $partial.id -and $o.result.allStopped -eq $true -and $null -eq $o.result.before) "作成後の失敗・停止済み: blocked・部分 handle を残す（$(ConvertTo-VerificationCanonicalJson $o.result)）"
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$o=Invoke-WithCreationFailure $ctx $proposal 'incomplete' (New-RuntimeFailureJson 'created' 'unverified' $partial)
Assert-True ($o.result.status -ceq 'incomplete' -and $o.result.sandboxes.Count -eq 1 -and $o.result.allStopped -eq $false) '作成後の失敗・停止未確認: incomplete・allStopped=false'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$o=Invoke-WithCreationFailure $ctx $proposal 'blocked' (New-RuntimeFailureJson 'not-created' 'not-created' $null)
Assert-True ($o.result.status -ceq 'blocked' -and $o.result.sandboxes.Count -eq 0 -and $null -eq $o.result.allStopped) '作成前の拒否: blocked・sandboxes=[]・allStopped=null'
# activationRecord が handle と対応しない（別 sandboxId）: 搬入せず blocked。作成済みの VM は止めて sandboxes に残す（作成・停止・搬入は試験だけの差し替え）。
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx
$activationPath=Join-Path $ctx.controlRoot 'runtime/replay-before-activation.json'
$handle=@{runId=$ctx.runId;role='replay-before';name=$ctx.names['replay-before'];id=[guid]::NewGuid().ToString();createdAt='2026-09-15T00:00:00.0000000Z';profileHash=('A'*64);effectiveSettingsHash=('B'*64);activationRecordPath=$activationPath;activationRecordHash=$null;keepAliveHandle=$null}
Write-VerificationNewFile $activationPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$ctx.runId;sandboxId=[guid]::NewGuid().ToString();sandboxName=$handle.name;role='replay-before';profileHash=$handle.profileHash;effectiveSettingsHash=$handle.effectiveSettingsHash;checks=@{}})
$handle.activationRecordHash=Get-Hash $activationPath
& $replayModule {param($h)
    $script:FakeCalls=[Collections.Generic.List[string]]::new();$script:FakeHandle=$h
    function script:New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile,[hashtable]$Lease){$script:FakeCalls.Add("create:$Role");$script:FakeHandle}
    function script:Copy-VerificationSandboxInput{$script:FakeCalls.Add('copy')}
    function script:Stop-VerificationSandbox([hashtable]$Handle,[hashtable]$RunBudget){$script:FakeCalls.Add("stop:$($RunBudget.phase)");@{stopState='stopped'}}
} $handle
try{$r=Invoke-VerificationReplay $ctx.prepared $proposal $ctx.replayProfile $null;$fakeCalls=& $replayModule {@($script:FakeCalls)}}
finally{Import-Module (Join-Path $PSScriptRoot '../Replay.psm1') -Force;$replayModule=Get-Module Replay}
Assert-True ($r.status -ceq 'blocked' -and $r.failure.reason -ceq 'activation-record' -and $r.sandboxes.Count -eq 1 -and $r.allStopped -eq $true -and $null -eq $r.before) "activationRecord 不一致: blocked（$(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-Equal (@($fakeCalls) -join ',') 'create:replay-before,stop:cleanup' 'activationRecord 不一致: 搬入せず、cleanup 相の予算で停止'
Assert-Equal (& $replayModule {(Get-Command New-VerificationSandbox).ModuleName}) 'SbxRuntime' '差し替えを戻した（Replay から見える New-VerificationSandbox は SbxRuntime の公開操作）'
$count++

# ---- ここから偽sbx の VM を使う経路 ----
$unitOk=Get-FakeSbxResponse 'unittestOk';$unitFail=Get-FakeSbxResponse 'unittestFail'
function Get-TextEntry([string]$Path,[string]$Text){@{path=$Path;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text)))}}
function Get-InputEntries([string]$CalcText,[string[]]$TestNames=@('test_calc.py')){
    @(Get-TextEntry 'calc.py' $CalcText)+@(Get-TextEntry 'README.md' "# pilot`n")+@(foreach($name in $TestNames){Get-TextEntry ".verification-tests/$name" $testText})
}
function Add-ReplayVm([hashtable]$Ctx,[string]$Role,[string]$CalcText,[string]$Stdout='',[string]$Stderr='',[int]$ExitCode=0,[double]$DelaySeconds=0,[string]$Source='unittest の出力（ストリームと形式）は 8a で実測して差し替える'){
    # 1台分の既定応答（作成〜停止）と、固定 argv の unittest の応答。unittest の応答は実測が無い創作（synthetic）。
    $sbxRole="replay-$Role";$name=$Ctx.names[$sbxRole];$id=[guid]::NewGuid().ToString()
    Add-FakeSbxSandboxScenario $Ctx.case $name $id -Agent 'shell' -ConfirmFiles (Get-InputEntries $CalcText)
    Add-FakeSbxResponse $Ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($name),'python3','-m','unittest','discover','-s','\.verification-tests','-p','test_\*\.py','-v') -Stdout $Stdout -Stderr $Stderr -ExitCode $ExitCode -DelaySeconds $DelaySeconds -Synthetic $true -Source $Source | Out-Null
    @{name=$name;id=$id}
}
function Invoke-Replay([hashtable]$Ctx,[hashtable]$Proposal){
    Write-FakeSbxScenario $Ctx.case
    $lease=Acquire-VerificationPilotLease $Ctx.prepared
    try{Invoke-VerificationReplay $Ctx.prepared $Proposal $Ctx.replayProfile $lease}finally{Release-VerificationPilotLease $lease}
}
function Read-Record([hashtable]$Reference){Get-Content -LiteralPath $Reference.recordPath -Raw | ConvertFrom-Json -AsHashtable -DateKind String}
function Get-CallIndex([object[]]$Calls,[scriptblock]$Predicate){for($i=0;$i -lt $Calls.Count;$i++){if(& $Predicate $Calls[$i]){return $i}};-1}
function Assert-StopsOnly([hashtable]$Ctx,[string[]]$Names,[string]$Label){
    # stop は run が作った当該名だけに発行する（残置VM・他の名前への stop 0件）。
    $stops=@(Read-FakeSbxCalls $Ctx.case | Where-Object {$_.argv[0] -eq 'stop'} | ForEach-Object {$_.argv[1]})
    Assert-Equal @($stops | Where-Object {$Names -cnotcontains $_}).Count 0 "${Label}: 当該名以外への stop が0件（$($stops -join ',')）"
    foreach($name in $Names){Assert-Equal @($stops | Where-Object {$_ -ceq $name}).Count 1 "${Label}: $name へ stop 1回"}
}
function Assert-NoLeftover([hashtable]$Ctx,[string]$Label){
    Stop-CaseFakeProcesses @($Ctx)
    Assert-Equal @(Get-CaseFakeProcesses @($Ctx)).Count 0 "${Label}: 当該ケースの偽sbxプロセスが残っていない"
}
$recordSchema=Join-Path $PSScriptRoot '../replay-record.schema.json'

# 10. candidate-comparison の正常系: before（-before）終了1・after（-after）終了0 → completed（合否は付けない）。別 VM・別 id・effectiveSettingsHash 一致・記録の schema・停止の順序。
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stderr $unitFail.text -ExitCode 1
$vmAfter=Add-ReplayVm $ctx 'after' $fixedText -Stderr $unitOk.text -ExitCode 0
$r=Invoke-Replay $ctx $proposal
Assert-True ($r.status -ceq 'completed' -and $r.mode -ceq 'candidate-comparison' -and $null -eq $r.failure -and $r.allStopped -eq $true) "正常: completed（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-Equal (@($r.Keys | Sort-Object) -join ',') 'after,allStopped,before,failure,mode,runId,sandboxes,schemaVersion,status' '正常: ReplayResultV3 のキー'
Assert-True ($r.sandboxes.Count -eq 2 -and $r.sandboxes[0].name -ceq $vmBefore.name -and $r.sandboxes[1].name -ceq $vmAfter.name -and $r.sandboxes[0].id -ceq $vmBefore.id -and $r.sandboxes[1].id -ceq $vmAfter.id) '正常: sandboxes は before・after の順の handle'
Assert-True ($vmBefore.id -cne $vmAfter.id -and $proposal.sandbox.id -notin @($vmBefore.id,$vmAfter.id)) '正常: 各役割の sandbox id が相異なり、提案VMとも別'
Assert-True ($r.sandboxes[0].effectiveSettingsHash -ceq $r.sandboxes[1].effectiveSettingsHash -and $r.sandboxes[0].effectiveSettingsHash -ceq (Get-VerificationEffectiveSettingsHash $ctx.replayProfile $ctx.settings)) '正常: before/after の effectiveSettingsHash が一致'
$beforeRecord=Read-Record $r.before;$afterRecord=Read-Record $r.after
foreach($pair in @(@($r.before,$beforeRecord,$vmBefore,1,'replay-before'),@($r.after,$afterRecord,$vmAfter,0,'replay-after'))){
    $reference=$pair[0];$record=$pair[1];$vm=$pair[2];$label=$pair[4]
    Assert-True (Test-Json -Json ([IO.File]::ReadAllText($reference.recordPath,$utf8)) -SchemaFile $recordSchema) "${label}: 記録が replay-record.schema.json に適合"
    Assert-True ($reference.recordPath -ceq (Join-Path $ctx.controlRoot "replay/$label/$($record.commandId).json") -and $reference.recordHash -ceq (Get-Hash $reference.recordPath) -and $reference.sandbox.id -ceq $vm.id -and $reference.commandId -ceq $record.commandId) "${label}: 参照（記録の外側パス・SHA256・handle）"
    Assert-True ($record.role -ceq $label -and $record.sandboxId -ceq $vm.id -and $record.runId -ceq $ctx.runId -and $record.exitCode -eq $pair[3] -and $record.transportVerified -eq $true -and $record.stopVerified -eq $true -and -not$record.timedOut -and -not$record.outputExceeded) "${label}: runId・role・sandboxId・終了コード・transportVerified・stopVerified"
    Assert-True ($record.profileHash -ceq $reference.sandbox.profileHash -and $record.effectiveSettingsHash -ceq $reference.sandbox.effectiveSettingsHash -and $record.activationRecordPath -ceq $reference.sandbox.activationRecordPath -and $record.activationRecordHash -ceq (Get-Hash $record.activationRecordPath)) "${label}: profileHash・effectiveSettingsHash・activationRecord"
    Assert-True ($record.templateDigest -ceq $ctx.replayProfile.templateDigest -and $record.sourceManifestHash -ceq $ctx.prepared.sourceManifestHash -and $record.testsManifestHash -ceq $proposal.testsManifestHash -and $record.inputManifestHash -ceq (Get-Hash $reference.inputManifestPath)) "${label}: templateDigest・sourceManifestHash・testsManifestHash・inputManifestHash"
    Assert-True (($record.argv -join ' ') -ceq 'python3 -m unittest discover -s .verification-tests -p test_*.py -v' -and $record.workingDirectory -ceq '/home/agent/workspace/source' -and $record.stderrHash -ceq (Get-Hash $record.stderrPath) -and $record.startedAt -match 'Z$' -and $record.finishedAt -match 'Z$' -and $record.limits.replaySeconds -eq 120 -and $record.limits.cpus -eq 2) "${label}: argv・作業ディレクトリ・出力hash・時刻・limits"
}
Assert-True ($beforeRecord.testsManifestHash -ceq $afterRecord.testsManifestHash -and $beforeRecord.inputManifestHash -cne $afterRecord.inputManifestHash) '正常: before/after は同じ testsManifestHash・別の入力'
$calls=@(Read-FakeSbxCalls $ctx.case)
$createBefore=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create' -and $c.argv[3] -ceq $vmBefore.name}
$stopBefore=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop' -and $c.argv[1] -ceq $vmBefore.name}
$createAfter=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create' -and $c.argv[3] -ceq $vmAfter.name}
$unitAfter=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'exec' -and $c.argv -contains 'unittest' -and $c.argv -contains $vmAfter.name}
$stopAfter=Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop' -and $c.argv[1] -ceq $vmAfter.name}
Assert-True ($createBefore -ge 0 -and $createBefore -lt $stopBefore -and $stopBefore -lt $createAfter -and $createAfter -lt $unitAfter -and $unitAfter -lt $stopAfter) "順序: before の作成・停止の後に after を作る（$createBefore,$stopBefore,$createAfter,$unitAfter,$stopAfter）"
Assert-Equal (@($calls | Where-Object {$_.argv[0] -eq 'exec' -and $_.argv -contains 'unittest'} | ForEach-Object {$_.argv -join ' '}) -join ' | ') "exec -w /home/agent/workspace/source $($vmBefore.name) python3 -m unittest discover -s .verification-tests -p test_*.py -v | exec -w /home/agent/workspace/source $($vmAfter.name) python3 -m unittest discover -s .verification-tests -p test_*.py -v" '固定 argv（-e なし・作業ディレクトリ固定）'
$cps=@($calls | Where-Object {$_.argv[0] -eq 'cp'})
Assert-True ($cps.Count -eq 2 -and $cps[0].argv[1] -ceq (Join-Path $ctx.runRoot 'replay-inputs\before') -and $cps[0].argv[2] -ceq "$($vmBefore.name):/home/agent/workspace/source" -and $cps[1].argv[1] -ceq (Join-Path $ctx.runRoot 'replay-inputs\after')) '搬入元: replay-inputs/before・after だけ（baseline・accepted・control を渡さない）'
foreach($call in $calls){Assert-True ($call.envKeys -notcontains 'SSH_AUTH_SOCK') '環境辞書: SSH_AUTH_SOCK を渡さない'}
Assert-StopsOnly $ctx @($vmBefore.name,$vmAfter.name) '正常'
Assert-NoLeftover $ctx '正常'
$count++

# 11. reproduction-only（before 終了0 = 非再現も completed）で after VM を作らない。recheck（after 終了1、stdout に偽の成功文字列 "OK"）で before VM を作らず、終了コードを覆さない。
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stderr $unitOk.text -ExitCode 0
$r=Invoke-Replay $ctx $proposal
Assert-True ($r.status -ceq 'completed' -and $r.mode -ceq 'reproduction-only' -and $null -eq $r.after -and $r.sandboxes.Count -eq 1 -and $r.allStopped -eq $true -and (Read-Record $r.before).exitCode -eq 0) "reproduction-only: before 0 でも completed（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-Equal @(Read-FakeSbxCalls $ctx.case | Where-Object {$_.argv[0] -eq 'create' -and $_.argv[3] -like '*-after'}).Count 0 'reproduction-only: after VM を作らない'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'replay/replay-after'))) 'reproduction-only: after の記録なし'
Assert-StopsOnly $ctx @($vmBefore.name) 'reproduction-only'
Assert-NoLeftover $ctx 'reproduction-only'
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx -Origin 'reused-tests'
$vmAfter=Add-ReplayVm $ctx 'after' $buggyText -Stdout "OK`nall tests passed`n" -Stderr $unitFail.text -ExitCode 1
$r=Invoke-Replay $ctx $proposal
$record=Read-Record $r.after
Assert-True ($r.status -ceq 'completed' -and $r.mode -ceq 'recheck' -and $null -eq $r.before -and $r.sandboxes.Count -eq 1 -and $r.sandboxes[0].role -ceq 'replay-after') "recheck: after だけで completed（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-True ($record.exitCode -eq 1 -and $record.transportVerified -eq $true -and ([IO.File]::ReadAllText($record.stdoutPath,$utf8)).StartsWith('OK')) '偽成功文字列: stdout に OK があっても終了1を記録する'
Assert-Equal @(Read-FakeSbxCalls $ctx.case | Where-Object {$_.argv[0] -eq 'create' -and $_.argv[3] -like '*-before'}).Count 0 'recheck: before VM を作らない'
Assert-StopsOnly $ctx @($vmAfter.name) 'recheck'
Assert-NoLeftover $ctx 'recheck'
$count++

# 12. 署名が stderr に無い出力（接続失敗の模擬。stdout にだけ要約がある場合）: 終了0でも incomplete（transportVerified=false）。記録と停止は残す。
$ctx=New-ReplayCtx;$proposal=New-Proposal $ctx
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stdout $unitOk.text -ExitCode 0
$r=Invoke-Replay $ctx $proposal
$record=Read-Record $r.before
Assert-True ($r.status -ceq 'incomplete' -and $r.failure.reason -ceq 'command-transport-unverified' -and $r.failure.stage -ceq 'replay-before' -and $record.transportVerified -eq $false -and $record.exitCode -eq 0 -and $record.stopVerified -eq $true -and $r.allStopped -eq $true) "stdout だけの署名: incomplete（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-StopsOnly $ctx @($vmBefore.name) 'stdout だけの署名'
Assert-NoLeftover $ctx 'stdout だけの署名'
$count++

# 13. before 停止未確認: after を作らず incomplete（stop-unverified・allStopped=false・記録の stopVerified=false）。
$ctx=New-ReplayCtx -CleanupSeconds 3;$proposal=New-Proposal $ctx -Replacements ([ordered]@{'calc.py'=$fixedText})
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stderr $unitFail.text -ExitCode 1
$vmAfter=Add-ReplayVm $ctx 'after' $fixedText -Stderr $unitOk.text -ExitCode 0
Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vmBefore.name)) -Stdout (Get-FakeSbxResponse 'stop' @{name=$vmBefore.name}).text -Synthetic $true -Source '一覧が stopped にならない状態遷移は未観測の創作' -First | Out-Null
$r=Invoke-Replay $ctx $proposal
Assert-True ($r.status -ceq 'incomplete' -and $r.failure.reason -ceq 'stop-unverified' -and $r.allStopped -eq $false -and $null -eq $r.after -and $r.sandboxes.Count -eq 1 -and (Read-Record $r.before).stopVerified -eq $false) "before 停止未確認: incomplete（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-Equal @(Read-FakeSbxCalls $ctx.case | Where-Object {$_.argv[0] -eq 'create' -and $_.argv[3] -ceq $vmAfter.name}).Count 0 'before 停止未確認: after VM を作らない'
Assert-StopsOnly $ctx @($vmBefore.name) 'before 停止未確認'
Assert-NoLeftover $ctx 'before 停止未確認'
$count++

# 14. 出力洪水: 出力上限を超えれば incomplete（SbxRuntime が当該VMを止め、Replay の停止は同じ結果を返す）。
$ctx=New-ReplayCtx -Limits @{maxOutputBytes=65536};$proposal=New-Proposal $ctx
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stdout ('y'*(200*1024)) -Stderr $unitFail.text -ExitCode 1 -Source '出力洪水の応答は 8a で実測する（内容は創作）'
$r=Invoke-Replay $ctx $proposal
$record=Read-Record $r.before
Assert-True ($r.status -ceq 'incomplete' -and $r.failure.reason -ceq 'command-output-exceeded' -and $record.outputExceeded -eq $true -and $record.transportVerified -eq $false -and $r.allStopped -eq $true) "出力洪水: incomplete（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure)）"
Assert-StopsOnly $ctx @($vmBefore.name) '出力洪水'
Assert-NoLeftover $ctx '出力洪水'
$count++

# 15. 時間超過: replaySeconds を超えれば timed_out。停止は cleanup 相の予算（cleanupDeadlineAt あり）で当該名へ1回。記録の終了コードは null。
$ctx=New-ReplayCtx -Limits @{replaySeconds=3};$proposal=New-Proposal $ctx
$vmBefore=Add-ReplayVm $ctx 'before' $buggyText -Stderr $unitFail.text -ExitCode 1 -DelaySeconds 8 -Source 'unittest が終わらない状況の創作（遅延）'
$r=Invoke-Replay $ctx $proposal
$record=Read-Record $r.before
Assert-True ($r.status -ceq 'timed_out' -and $r.failure.reason -ceq 'command-timed-out' -and $record.timedOut -eq $true -and $null -eq $record.exitCode -and $record.stopVerified -eq $true -and $r.allStopped -eq $true) "時間超過: timed_out（$($r.status) $(ConvertTo-VerificationCanonicalJson $r.failure) exit=$($record.exitCode)）"
$stopEvidence=@(Get-ChildItem -LiteralPath (Join-Path $ctx.controlRoot 'runtime') -Filter 'replay-before-stop-*.json')
Assert-Equal $stopEvidence.Count 1 '時間超過: 停止証拠1件'
$evidence=Get-Content -LiteralPath $stopEvidence[0].FullName -Raw | ConvertFrom-Json -AsHashtable -DateKind String
Assert-True ($evidence.stopState -ceq 'stopped' -and -not[string]::IsNullOrEmpty([string]$evidence.budget.cleanupDeadlineAt)) '時間超過: 停止は phase=cleanup の予算（cleanupDeadlineAt を持つ）で発行'
Assert-True ([DateTimeOffset]::Parse([string]$evidence.stopIssuedAt).UtcDateTime -ge [DateTimeOffset]::Parse([string]$record.finishedAt).UtcDateTime) '時間超過: 打ち切りの後に停止'
Assert-StopsOnly $ctx @($vmBefore.name) '時間超過'
Assert-NoLeftover $ctx '時間超過'
$count++

}finally{
    if($allCases.Count -gt 0){try{Stop-CaseFakeProcesses $allCases.ToArray()}catch{}}
}
Assert-Equal @(Get-CaseFakeProcesses $allCases.ToArray()).Count 0 '全ケース: 試験が起動した偽sbxプロセスが残っていない'
"ReplayV3: $count cases passed"
