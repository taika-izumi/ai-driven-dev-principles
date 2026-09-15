# v3の依頼・設定・固定入力の検査と、基準版・提案用コピー・再検証テストの準備を、VMなしで検証する。
$ErrorActionPreference='Stop'
$env:GIT_CONFIG_GLOBAL='NUL';$env:GIT_CONFIG_NOSYSTEM='1'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
$count=0
$startedAt='2026-09-15T00:00:00Z'
function Invoke-TestGit([string]$Root,[string[]]$Arguments){
    $out=& git -c user.name=VerificationTest -c user.email=test@example.invalid -C $Root @Arguments 2>&1
    if($LASTEXITCODE -ne 0){throw "git failed: $($Arguments -join ' '): $out"}
    (($out | ForEach-Object {"$_"}) -join "`n").Trim()
}
function Write-JsonFile([string]$Path,$Object){[IO.File]::WriteAllText($Path,($Object | ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($false))}
function Write-PilotRecord($Case){
    # 固定入力記録は外側の主担当が準備する。試験では同じ公開関数で現物manifestのhashを計算して記録に書く。
    $manifest=Get-VerificationSourceManifest $Case.request $Case.settings
    $Case.record.sourceManifestHash=Get-VerificationCanonicalHash $manifest
    Write-JsonFile $Case.settings.pilotInputPath $Case.record
}
function New-V3Case([string]$Name){
    # 試験名は8文字以下に保つ。baseline/.git/objects/pack のパスが Windows の MAX_PATH に達すると履歴の取り込みが失敗する。
    if($Name.Length -gt 8){throw "試験名が長すぎる: $Name"}
    $case=New-TestCase $Name
    [IO.File]::WriteAllText((Join-Path $case.sourceRoot 'calc.py'),"def add(a, b):`n    return a - b`n")
    $null=Invoke-TestGit $case.sourceRoot @('add','calc.py')
    $null=Invoke-TestGit $case.sourceRoot @('commit','--quiet','-m','synthetic defect')
    $sbx=Join-Path $case.root 'sbx.cmd';[IO.File]::WriteAllText($sbx,"@echo off`r`nexit /b 3`r`n")
    $profiles=Join-Path $case.root 'profiles';[void][IO.Directory]::CreateDirectory($profiles)
    foreach($role in @('proposal','replay')){Write-JsonFile (Join-Path $profiles "$role.json") @{placeholder=$role}}
    $case.request=@{schemaVersion=3;caller='claude-code';sourceRoot=$case.sourceRoot;objective='合成題材の欠陥を再現する';acceptanceCriteria=@('再現テストが修正前に失敗し修正後に成功する');extraInputPaths=@()}
    $case.settings=@{
        schemaVersion=3;sbxPath=$sbx;pwshPath=(Get-Command pwsh -ErrorAction Stop).Source;runsRoot=$case.runsRoot;model='unit-test-model'
        proposalProfilePath=(Join-Path $profiles 'proposal.json');replayProfilePath=(Join-Path $profiles 'replay.json');pilotInputPath=(Join-Path $case.root 'pilot-input.json')
        limits=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=30;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1048576;maxProposalBytes=8388608;maxWireBytes=16777216;maxOutputBytes=16777216}
    }
    $case.record=@{schemaVersion=3;inputId="pilot-$Name";scope='synthetic-pilot';sourceRoot=$case.sourceRoot;sourceManifestHash='';approvalReference=@{path='docs/records/reviews/2026-09-10-synthetic-pilot-scope-r2.md';version='5259d22'}}
    Write-PilotRecord $case
    $case
}
function Get-Failure([scriptblock]$Action){$failure=$null;try{& $Action | Out-Null}catch{$failure=$_};Assert-True ($null -ne $failure) '失敗を期待';$failure}
function Check-Status($Request,$Settings,[string]$Expected='blocked',[string]$Started=$startedAt){
    # 失敗ケース1件。$count は New-VerificationRun の呼び出し（成功・期待した失敗）と補助関数の検査をケースとして数える。
    $failure=Get-Failure {New-VerificationRun $Request $Settings $Started}
    Assert-Equal $failure.Exception.Data['status'] $Expected "期待した状態 ($($failure.Exception.Message))"
    $script:count++
    $failure
}
function Get-FileSha([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Read-JsonFile([string]$Path){[IO.File]::ReadAllText($Path) | ConvertFrom-Json -AsHashtable -Depth 25}

# ---- 補助関数 ----
Assert-Equal (ConvertTo-VerificationCanonicalJson @{b=1;a=@('x',$true,$null);c=@{z=[long]2;y="日本語`"\"};d=@()}) '{"a":["x",true,null],"b":1,"c":{"y":"日本語\"\\","z":2},"d":[]}' 'キー序数順・空白なしの正規化JSON'
Assert-Equal (Get-VerificationCanonicalHash @{a=1}) ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('{"a":1}')))) '正規化JSONのSHA256'
Assert-True ((Get-VerificationUtcNow) -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$') 'UTCのISO8601'
Assert-True (Test-VerificationJsonDuplicateKeys '{"a":1,"a":2}') '同一オブジェクト内の重複キー'
Assert-True (Test-VerificationJsonDuplicateKeys '{"a":{"b":1,"b":2}}') '入れ子の重複キー'
Assert-True (Test-VerificationJsonDuplicateKeys '[{"k":1},{"k":2,"k":3}]') '配列要素内の重複キー'
Assert-True (-not(Test-VerificationJsonDuplicateKeys '{"a":{"b":1},"c":{"b":2}}')) '別オブジェクトの同名キーは重複ではない'
$helper=New-TestCase 'v3-help'
$newFile=Join-Path $helper.root 'sub/new.txt'
Write-VerificationNewFile $newFile "a`r`nb`n"
Assert-Equal (([IO.File]::ReadAllBytes($newFile) | ForEach-Object {$_.ToString('x2')}) -join ' ') '61 0a 62 0a' 'BOMなし・LF'
Assert-Throws {Write-VerificationNewFile $newFile 'again'} '*'
$count+=9

# ---- 正常（新規） ----
$case=New-V3Case 'v3-new'
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '未追跡 note.txt'),'日本語')
Write-PilotRecord $case
$sourceStatus=Invoke-TestGit $case.sourceRoot @('status','--porcelain=v1')
$sourceHead=Invoke-TestGit $case.sourceRoot @('rev-parse','HEAD')
$run=New-VerificationRun $case.request $case.settings $startedAt
Assert-Equal $run.schemaVersion 3 'PreparedRunV3の版'
Assert-True ($run.runId -match '^[0-9a-f-]{36}$') 'UUIDのrunId'
foreach($part in @('baseline','proposal-input','quarantine','accepted','replay-inputs','temp','control/empty-template','control/runtime','control/proposal','control/replay')){Assert-True ([IO.Directory]::Exists((Join-Path $run.runRoot $part))) "run配置: $part"}
Assert-True (-not(Test-Path -LiteralPath (Join-Path $run.runRoot 'work'))) 'v3ではworkを作らない'
Assert-Equal $run.baselineRoot (Join-Path $run.runRoot 'baseline') 'baselineRoot'
Assert-Equal $run.proposalInputRoot (Join-Path $run.runRoot 'proposal-input') 'proposalInputRoot'
Assert-Equal $run.acceptedRoot (Join-Path $run.runRoot 'accepted') 'acceptedRoot'
Assert-Equal $run.controlRoot (Join-Path $run.runRoot 'control') 'controlRoot'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.controlRoot 'request.json'))) (ConvertTo-VerificationCanonicalJson $case.request) 'control/request.json は受理した依頼の正規化JSON'
Assert-Equal $run.sourceManifestPath (Join-Path $run.controlRoot 'source-manifest.json') 'sourceManifestPath'
Assert-Equal (Get-FileSha $run.sourceManifestPath) $run.sourceManifestHash 'sourceManifestHash は現物と一致'
Assert-Equal $run.sourceManifestHash $case.record.sourceManifestHash '固定入力記録のhashと正規化manifestのhashが一致'
$sourceManifest=Read-JsonFile $run.sourceManifestPath
Assert-Equal $sourceManifest.head $sourceHead 'source-manifest の head'
Assert-Equal $run.baselineManifestPath (Join-Path $run.controlRoot 'baseline-manifest.json') 'baselineManifestPath'
Assert-Equal (Get-FileSha $run.baselineManifestPath) $run.baselineManifestHash 'baselineManifestHash は現物と一致'
$baselineManifest=Read-JsonFile $run.baselineManifestPath
$baselinePaths=@($baselineManifest.files | ForEach-Object path)
Assert-True ($baselinePaths -ccontains '.git/HEAD') 'baseline-manifest は .git を含む'
Assert-True ($baselinePaths -ccontains 'calc.py' -and $baselinePaths -ccontains '未追跡 note.txt') 'baseline-manifest は作業ファイルを含む'
$sortedPaths=[string[]]$baselinePaths.Clone();[Array]::Sort($sortedPaths,[StringComparer]::Ordinal)
Assert-Equal ($baselinePaths -join '|') ($sortedPaths -join '|') 'baseline-manifest は序数順'
Assert-True ($baselinePaths.IndexOf('.git/HEAD') -lt $baselinePaths.IndexOf('.git/config')) '序数順では大文字が小文字より先'
foreach($file in $baselineManifest.files){
    Assert-Equal (Get-FileSha (Join-Path $run.baselineRoot $file.path)) $file.sha256 "baseline現物とmanifestの一致: $($file.path)"
    Assert-Equal (Get-FileSha (Join-Path $run.proposalInputRoot $file.path)) $file.sha256 "proposal-input はbaselineのファイル単位コピー: $($file.path)"
}
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.baselineRoot 'calc.py'))) "def add(a, b):`n    return a - b`n" 'baselineの本文'
Assert-Equal (Invoke-TestGit $run.baselineRoot @('rev-parse','HEAD')) $sourceHead 'baselineの独立Gitは原本のHEADを保持'
Assert-Equal (Invoke-TestGit $run.baselineRoot @('rev-parse','--absolute-git-dir')).Replace('/','\') (Join-Path $run.baselineRoot '.git') 'baselineのGitは自分の中を指す'
Assert-Equal (Invoke-TestGit $run.proposalInputRoot @('rev-parse','--absolute-git-dir')).Replace('/','\') (Join-Path $run.proposalInputRoot '.git') 'proposal-inputのGitは自分の中を指す'
Assert-Equal (Invoke-TestGit $run.proposalInputRoot @('rev-parse','--git-common-dir')) '.git' 'proposal-inputはbaselineと管理領域を共有しない'
Assert-Equal (Invoke-TestGit $run.proposalInputRoot @('rev-parse','HEAD')) $sourceHead 'proposal-inputの履歴'
Assert-True (Test-Path -LiteralPath (Join-Path $run.controlRoot 'history.bundle')) '履歴bundleはcontrolに残る'
Assert-Equal $run.pilotInputId $case.record.inputId 'pilotInputId'
Assert-Equal $run.pilotInputPath (Join-Path $run.controlRoot 'pilot-input.json') '記録はcontrolへ複製'
Assert-Equal $run.pilotInputHash (Get-FileSha $case.settings.pilotInputPath) '複製のhashは元記録と一致'
Assert-Equal $run.pilotInputHash (Get-FileSha $run.pilotInputPath) 'pilotInputHash は複製現物と一致'
Assert-Equal $run.startedAt $startedAt 'startedAt は引数のまま'
Assert-Equal $run.deadlineAt '2026-09-15T00:30:00.0000000Z' 'deadlineAt は startedAt + totalSeconds'
Assert-Equal $run.cleanupSeconds 30 'cleanupSeconds'
Assert-True ($null -eq $run.recheckManifestPath -and $null -eq $run.recheckManifestHash -and $run.recheckArtifacts.Count -eq 0) 'recheckなしの既定値'
Assert-Equal (Invoke-TestGit $case.sourceRoot @('status','--porcelain=v1')) $sourceStatus '原本の作業内容を保全'
$count++

# ---- 依頼・設定の拒否 ----
$bad=New-V3Case 'v3-inv'
$r=$bad.request.Clone();$r.unexpected='x';$null=Check-Status $r $bad.settings
$r=$bad.request.Clone();$r.schemaVersion='3';$null=Check-Status $r $bad.settings
$r=$bad.request.Clone();$r.schemaVersion=2;$null=Check-Status $r $bad.settings
$r=$bad.request.Clone();$r.caller='other';$null=Check-Status $r $bad.settings
$r=$bad.request.Clone();$r.recheck=@{previousResultPath='x';testPaths=@('tests/a.py');extra=1};$null=Check-Status $r $bad.settings
$null=Check-Status $bad.request $bad.settings 'blocked' ''
$null=Check-Status $bad.request $bad.settings 'blocked' '2026-09-15T09:00:00+09:00'
$s=$bad.settings.Clone();$s.extra='x';$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.schemaVersion='3';$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.pids=64;$f=Check-Status $bad.request $s
Assert-True ($f.Exception.Message -like '*pids*') '旧pidsキーは未知キーとして名指しで拒否'
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.cpus=4;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.memoryMiB=4096;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.totalSeconds='1800';$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.proposalSeconds=1801;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.limits=$bad.settings.limits.Clone();$s.limits.replaySeconds=1801;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.sbxPath='sbx.cmd';$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.sbxPath=(Join-Path $bad.root 'missing-sbx.cmd');$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.replayProfilePath=$null;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.model=$null;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.proposalProfilePath=$null;$null=Check-Status $bad.request $s
$s=$bad.settings.Clone();$s.model='';$null=Check-Status $bad.request $s
Assert-Equal (Get-ChildItem -LiteralPath $bad.runsRoot).Count 0 '拒否時はrunを作らない'

# ---- 固定入力記録の照合 ----
$pilot=New-V3Case 'v3-pilot'
$record=$pilot.record.Clone();$record.sourceManifestHash='0'*64;Write-JsonFile $pilot.settings.pilotInputPath $record
$f=Check-Status $pilot.request $pilot.settings
Assert-True ($f.Exception.Message -like '*source manifest hash*') 'hash不一致を名指し'
Assert-Equal $f.Exception.Data['stage'] 'pilot-input' '失敗段階'
Assert-Equal (Get-ChildItem -LiteralPath $pilot.runsRoot).Count 0 'hash不一致ではrunを作らない'
$record=$pilot.record.Clone();$record.sourceRoot=$pilot.root;Write-JsonFile $pilot.settings.pilotInputPath $record
$null=Check-Status $pilot.request $pilot.settings
$record=$pilot.record.Clone();$record.scope='real-project';Write-JsonFile $pilot.settings.pilotInputPath $record
$null=Check-Status $pilot.request $pilot.settings
$record=$pilot.record.Clone();$record.extra='x';Write-JsonFile $pilot.settings.pilotInputPath $record
$null=Check-Status $pilot.request $pilot.settings
[IO.File]::WriteAllText($pilot.settings.pilotInputPath,'{"schemaVersion":3,"schemaVersion":3}')
$f=Check-Status $pilot.request $pilot.settings
Assert-True ($f.Exception.Message -like '*duplicate keys*') '記録の重複キー'
Write-PilotRecord $pilot
[IO.File]::WriteAllText((Join-Path $pilot.sourceRoot 'calc.py'),"def add(a, b):`n    return a + b`n")
$null=Check-Status $pilot.request $pilot.settings
Write-PilotRecord $pilot
$null=New-VerificationRun $pilot.request $pilot.settings $startedAt
$count++

# ---- runsRoot と予約名 ----
$roots=New-V3Case 'v3-roots'
foreach($badRoot in @($roots.sourceRoot,$roots.root)){$s=$roots.settings.Clone();$s.runsRoot=$badRoot;$null=Check-Status $roots.request $s}
# 原本内 runsRoot は baseline/.git/objects/pack のパスが Windows の MAX_PATH に達しやすいため、名前と runsRoot を短くする。
$nested=New-V3Case 'v3n';$nested.settings.runsRoot=Join-Path $nested.sourceRoot 'r'
[void][IO.Directory]::CreateDirectory($nested.settings.runsRoot)
[IO.File]::WriteAllText((Join-Path $nested.settings.runsRoot 'old.txt'),'preserve')
Write-PilotRecord $nested
$nr=New-VerificationRun $nested.request $nested.settings $startedAt
Assert-True (-not(Test-Path -LiteralPath (Join-Path $nr.baselineRoot 'r'))) '原本内のrunsRootを列挙から除外'
Assert-True (@((Read-JsonFile $nr.sourceManifestPath).exclusions | Where-Object reason -EQ 'run_output').Count -gt 0) '除外理由を残す'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $nested.settings.runsRoot 'old.txt'))) 'preserve' '既存出力を保全'
$count++
foreach($reserved in @('.verification-tests','.verification-control')){
    $rc=New-V3Case 'v3-res'
    [void][IO.Directory]::CreateDirectory((Join-Path $rc.sourceRoot $reserved))
    [IO.File]::WriteAllText((Join-Path $rc.sourceRoot "$reserved/x.txt"),'x')
    $f=Check-Status $rc.request $rc.settings
    Assert-True ($f.Exception.Message -like "*$reserved*") "予約名の衝突: $reserved"
}

# ---- recheck ----
function New-PreviousRun($Case,[string]$TestBody='import unittest',[hashtable]$Override=@{}){
    $prevId=[guid]::NewGuid().ToString()
    $prevRoot=Join-Path $Case.runsRoot $prevId
    [void][IO.Directory]::CreateDirectory((Join-Path $prevRoot 'accepted/tests'));[void][IO.Directory]::CreateDirectory((Join-Path $prevRoot 'control'))
    $testPath=Join-Path $prevRoot 'accepted/tests/test_calc.py'
    [IO.File]::WriteAllText($testPath,$TestBody,[Text.UTF8Encoding]::new($false))
    $result=@{
        schemaVersion=3;runId=$prevId;status='completed';previousRunId=$null
        execution=@{proposalCreated=$true;proposalStopped=$true;replayCreatedCount=2;replayAllStopped=$true}
        artifacts=@(@{kind='test';path='tests/test_calc.py';size=(Get-Item -LiteralPath $testPath).Length;sha256=(Get-FileSha $testPath)},@{kind='replacement';path='replacements/calc.py';size=1;sha256=('A'*64)})
    }
    foreach($key in $Override.Keys){$result[$key]=$Override[$key]}
    $resultPath=Join-Path $prevRoot 'control/result.json'
    Write-JsonFile $resultPath $result
    @{runId=$prevId;root=$prevRoot;resultPath=$resultPath;testPath=$testPath}
}
$re=New-V3Case 'v3-rec'
$prev=New-PreviousRun $re
$re.request.recheck=@{previousResultPath=$prev.resultPath;testPaths=@('tests/test_calc.py')}
$re.settings.model=$null;$re.settings.proposalProfilePath=$null
$rr=New-VerificationRun $re.request $re.settings $startedAt
$copiedTest=Join-Path $rr.acceptedRoot 'tests/test_calc.py'
Assert-True ([IO.File]::Exists($copiedTest)) '前回テストをaccepted/testsへ複製'
Assert-Equal (Get-FileSha $copiedTest) (Get-FileSha $prev.testPath) '複製のhash'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $rr.proposalInputRoot 'tests'))) 'proposal-inputへテストを搬入しない'
Assert-Equal $rr.recheckArtifacts.Count 1 'recheckArtifacts 件数'
$artifact=$rr.recheckArtifacts[0]
Assert-Equal $artifact.kind 'test' 'kind'
Assert-Equal $artifact.path 'tests/test_calc.py' 'acceptedからの相対パス'
Assert-Equal $artifact.sha256 (Get-FileSha $prev.testPath) 'sha256'
Assert-Equal $artifact.size (Get-Item -LiteralPath $prev.testPath).Length 'size'
Assert-Equal $artifact.previousRunId $prev.runId 'previousRunId'
Assert-Equal $rr.recheckManifestPath (Join-Path $rr.controlRoot 'recheck-manifest.json') 'recheckManifestPath'
Assert-Equal (Get-FileSha $rr.recheckManifestPath) $rr.recheckManifestHash 'recheckManifestHash は現物と一致'
$recheckManifest=Read-JsonFile $rr.recheckManifestPath
Assert-Equal $recheckManifest.previousRunId $prev.runId 'recheck-manifest の由来'
Assert-Equal $recheckManifest.previousResultHash (Get-FileSha $prev.resultPath) '前回結果のhashを記録'
Assert-Equal $recheckManifest.tests[0].sha256 $artifact.sha256 'recheck-manifest のテストhash'
Assert-Equal ([IO.File]::ReadAllText((Join-Path $rr.controlRoot 'request.json'))) (ConvertTo-VerificationCanonicalJson $re.request) 'recheck付き依頼の記録'
$count++
# 改変されたテスト
$prevChanged=New-PreviousRun $re
[IO.File]::WriteAllText($prevChanged.testPath,'import unittest  # tampered')
$re.request.recheck=@{previousResultPath=$prevChanged.resultPath;testPaths=@('tests/test_calc.py')}
$f=Check-Status $re.request $re.settings
Assert-True ($f.Exception.Message -like '*changed since its result*') '改変テストを拒否'
Assert-Equal $f.Exception.Data['stage'] 'recheck' 'recheck段階の失敗'
Assert-True ([IO.Directory]::Exists($f.Exception.Data['runRoot'])) '作成済み領域を残す'
# 範囲外・未掲載・重複
$prevOk=New-PreviousRun $re
foreach($paths in @(@('../control/result.json'),@('tests/../tests/test_calc.py'),@('tests\test_calc.py'),@((Join-Path $prevOk.root 'accepted/tests/test_calc.py')),@('test_calc.py'),@('tests/test_other.py'),@('replacements/calc.py'),@('tests/test_calc.py','tests/test_calc.py'))){
    $re.request.recheck=@{previousResultPath=$prevOk.resultPath;testPaths=$paths}
    $null=Check-Status $re.request $re.settings
}
# 停止未確認・時間超過・runsRoot外・runIdと場所の不一致
$prevUnstopped=New-PreviousRun $re -Override @{execution=@{proposalCreated=$true;proposalStopped=$true;replayCreatedCount=2;replayAllStopped=$false};status='incomplete'}
$re.request.recheck=@{previousResultPath=$prevUnstopped.resultPath;testPaths=@('tests/test_calc.py')}
$f=Check-Status $re.request $re.settings
Assert-True ($f.Exception.Message -like '*stop unverified*') '停止未確認を拒否'
$prevProposalUnstopped=New-PreviousRun $re -Override @{execution=@{proposalCreated=$true;proposalStopped=$false;replayCreatedCount=2;replayAllStopped=$true};status='incomplete'}
$re.request.recheck=@{previousResultPath=$prevProposalUnstopped.resultPath;testPaths=@('tests/test_calc.py')}
$null=Check-Status $re.request $re.settings
$prevTimedOut=New-PreviousRun $re -Override @{status='timed_out'}
$re.request.recheck=@{previousResultPath=$prevTimedOut.resultPath;testPaths=@('tests/test_calc.py')}
$f=Check-Status $re.request $re.settings
Assert-True ($f.Exception.Message -like '*timed out*') 'timed_outを拒否'
$prevV1=New-PreviousRun $re -Override @{schemaVersion=1}
$re.request.recheck=@{previousResultPath=$prevV1.resultPath;testPaths=@('tests/test_calc.py')}
$null=Check-Status $re.request $re.settings
$outside=Join-Path $re.root 'outside-result.json';Copy-Item -LiteralPath $prevOk.resultPath -Destination $outside
$re.request.recheck=@{previousResultPath=$outside;testPaths=@('tests/test_calc.py')}
$null=Check-Status $re.request $re.settings
$moved=Join-Path $re.runsRoot 'not-the-run-id/control';[void][IO.Directory]::CreateDirectory($moved);Copy-Item -LiteralPath $prevOk.resultPath -Destination (Join-Path $moved 'result.json')
$re.request.recheck=@{previousResultPath=(Join-Path $moved 'result.json');testPaths=@('tests/test_calc.py')}
$null=Check-Status $re.request $re.settings
$re.request.recheck=@{previousResultPath=(Join-Path $re.runsRoot 'missing/control/result.json');testPaths=@('tests/test_calc.py')}
$null=Check-Status $re.request $re.settings

# ---- コピー中の原本変更（v1試験と同じく内部コピー関数を包み、本体の再照合を実行する） ----
$changing=New-V3Case 'v3-chg'
$changePath=Join-Path $changing.sourceRoot 'tracked.txt'
& (Get-Module RequestCopy) {
    param($path)
    $script:testChangePath=$path
    $script:originalCopy=(Get-Command Copy-VerificationFile).ScriptBlock
    function script:Copy-VerificationFile($Source,$Destination){& $script:originalCopy $Source $Destination;[IO.File]::WriteAllText($script:testChangePath,'changed-during-copy')}
} $changePath
$f=Check-Status $changing.request $changing.settings 'source_changed'
Assert-True ([IO.Directory]::Exists($f.Exception.Data['runRoot'])) '途中成果の場所を保持'
"RequestCopyV3: $count cases passed"
