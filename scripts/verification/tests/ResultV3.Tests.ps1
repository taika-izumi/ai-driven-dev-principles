$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/V3TestContext.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../SbxRuntime.psm1') -Force -DisableNameChecking   # runtime profile の期待値（profileHash・実効設定ラベル）を試験側でも同じ検査で得る
Import-Module (Join-Path $PSScriptRoot '../Result.psm1') -Force
# 照合（仕様03）の試験。準備・提案・再実行の記録は、各ブロックの報告と実装どおりの保存先と形でファイルとして組み立てる（sbx・VM・モデルは起動しない）。
# 原本だけは実 Git の作業ツリーにし、照合が原本を再列挙できるようにする。ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。
$clock=[Diagnostics.Stopwatch]::StartNew()
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$base=Join-Path $repo '.tmp/verification-tests'
$utf8=[Text.UTF8Encoding]::new($false)
$schemaPath=Join-Path $PSScriptRoot '../result.schema.json'
$pilot=Join-Path $PSScriptRoot 'fixtures/pilot-source'
$buggyText=[IO.File]::ReadAllText((Join-Path $pilot 'source/calc.py'),$utf8)
$fixedText=[IO.File]::ReadAllText((Join-Path $pilot 'replacements/calc.py'),$utf8)
$testText=[IO.File]::ReadAllText((Join-Path $pilot 'tests/test_calc.py'),$utf8)
$daemon=@{pid=4242;startedAt='2026-09-15T00:00:00.0000000Z';version='v0.42.1 fake';socket='fake'}
$replayArgv=@('python3','-m','unittest','discover','-s','.verification-tests','-p','test_*.py','-v')
$modeRoles=@{'candidate-comparison'=@('before','after');'reproduction-only'=@('before');recheck=@('after')}
$executionKeys='exitCodeForCli,failureStage,pilotInputHash,pilotInputId,pilotInputPath,proposalCreated,proposalStopped,replayAllStopped,replayCreatedCount'
$count=0
$manifestCache=@{}

function New-CaseRoot([string]$Prefix){Join-Path $base ($Prefix+[guid]::NewGuid().ToString('N').Substring(0,6))}
function New-GitSource(){
    # 原本: 追跡ファイル1件の Git 作業ツリー（コミットなし）。
    $root=New-CaseRoot 'r6s';$src=Join-Path $root 'src';$template=Join-Path $root 'tpl'
    foreach($dir in @($src,$template)){[void][IO.Directory]::CreateDirectory($dir)}
    & git -C $src init --quiet "--template=$template";if($LASTEXITCODE -ne 0){throw '試験用Git初期化失敗'}
    [IO.File]::WriteAllText((Join-Path $src 'tracked.txt'),'baseline',$utf8)
    & git -C $src add -- tracked.txt;if($LASTEXITCODE -ne 0){throw '試験用ファイルのステージ失敗'}
    $src
}
function Now(){Get-VerificationUtcNow}
function Write-Canonical([string]$Path,$Value){Write-VerificationNewFile $Path (ConvertTo-VerificationCanonicalJson $Value);Get-V3TestHash $Path}
function New-ResultCtx([string]$SourceRoot){
    # PreparedRunV3 と同じ形の文脈。source manifest と固定入力記録は実 Git の原本から作り直す（V3TestContext の合成値を置き換える）。
    $files=[ordered]@{'calc.py'=$buggyText;'util.py'="VALUE = 1`n";'.git/HEAD'="ref: refs/heads/master`n"}
    $ctx=New-V3TestContext (New-CaseRoot 'r6') $files -CleanupSeconds 30
    $ctx.prepared.sourceRoot=$SourceRoot;$ctx.prepared.request.sourceRoot=$SourceRoot
    if(-not$manifestCache.ContainsKey($SourceRoot)){$manifestCache[$SourceRoot]=ConvertTo-VerificationCanonicalJson (Get-VerificationSourceManifest $ctx.prepared.request $ctx.settings)}
    [IO.File]::WriteAllText($ctx.prepared.sourceManifestPath,$manifestCache[$SourceRoot],$utf8)
    $ctx.prepared.sourceManifestHash=Get-V3TestHash $ctx.prepared.sourceManifestPath
    $pilotRecord=@{schemaVersion=3;inputId='pilot-fixture';scope='synthetic-pilot';sourceRoot=$SourceRoot;sourceManifestHash=$ctx.prepared.sourceManifestHash;approvalReference=@{path='docs/records/reviews/fixture.md';version='0000000'}}
    [IO.File]::WriteAllText($ctx.prepared.pilotInputPath,(ConvertTo-VerificationCanonicalJson $pilotRecord),$utf8)
    $ctx.prepared.pilotInputHash=Get-V3TestHash $ctx.prepared.pilotInputPath
    # runtime profile（証拠つき）を settings の profile パスへ書き、照合が読む値と同じ検査で期待値を得る。
    $ctx.expect=@{}
    foreach($pair in @(@('proposal','proposal','proposalProfilePath'),@('replay','replay-before','replayProfilePath'))){
        $profile=$(if($pair[0] -ceq 'replay'){$ctx.replayProfile}else{New-V3TestProfile $ctx 'proposal'})
        [IO.File]::WriteAllText($ctx.settings[$pair[2]],(ConvertTo-VerificationCanonicalJson $profile),$utf8)
        $ctx.expect[$pair[0]]=@{profileHash=(Test-VerificationRuntimeProfile $profile $pair[1] $ctx.settings);effectiveSettingsHash=(Get-VerificationEffectiveSettingsHash $profile $ctx.settings);templateDigest=$profile.templateDigest}
    }
    $ctx
}
function New-Sandbox([hashtable]$Ctx,[string]$Role,[hashtable]$Options){
    # SbxRuntime と同じ保存先と形: 作成記録 control/runtime/<role>-sandbox.json、activationRecord <role>-activation.json、停止記録 <role>-stop-<時刻>.json。
    if($null -eq $Options){$Options=@{}}
    $runtime=Join-Path $Ctx.controlRoot 'runtime'
    $id=$(if($Options.ContainsKey('id')){$Options.id}else{[guid]::NewGuid().ToString()});$name=$Ctx.names[$Role]
    $expected=$Ctx.expect[$(if($Role -ceq 'proposal'){'proposal'}else{'replay'})]
    $profileHash=$(if($Options.ContainsKey('profileHash')){$Options.profileHash}else{$expected.profileHash})
    $effective=$(if($Options.ContainsKey('effectiveSettingsHash')){$Options.effectiveSettingsHash}else{$expected.effectiveSettingsHash})
    $instance=$(if($Options.ContainsKey('daemon')){$Options.daemon}else{$daemon})
    $checks=@{};foreach($key in @('policy','mount','resource','credentialExposure','sshForwarding','clipboardImagePaste','mcpServers','otherVmTraffic')){$checks[$key]=@{verdict='verified';expected=@{};observed=@{};source='fixture'}}
    $activationPath=Join-Path $runtime "$Role-activation.json"
    $activationHash=Write-Canonical $activationPath @{schemaVersion=3;runId=$Ctx.runId;sandboxId=$id;sandboxName=$name;role=$Role;daemonInstance=$instance;profileHash=$profileHash;effectiveSettingsHash=$effective;checkedAt=(Now);checks=$checks}
    $handle=@{runId=$Ctx.runId;role=$Role;name=$name;id=$id;createdAt=(Now);profileHash=$profileHash;effectiveSettingsHash=$effective;activationRecordPath=$activationPath;activationRecordHash=$activationHash;keepAliveHandle=$null}
    $record=@{schemaVersion=3};foreach($key in @('runId','role','name','id','createdAt','profileHash','effectiveSettingsHash','activationRecordPath','activationRecordHash')){$record[$key]=$handle[$key]}
    [void](Write-Canonical (Join-Path $runtime "$Role-sandbox.json") $record)
    if(-not$Options.ContainsKey('noStop')){
        Start-Sleep -Milliseconds 2
        $stopState=$(if($Options.ContainsKey('stopState')){$Options.stopState}else{'stopped'})
        [void](Write-Canonical (Join-Path $runtime "$Role-stop-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')).json") @{schemaVersion=3;runId=$Ctx.runId;role=$Role;name=$name;id=$id;budget=@{cleanupDeadlineAt=(Now);cleanupSeconds=30};stopIssuedAt=(Now);stopCall=$null;daemonBefore=$instance;daemonAfter=$instance;listObserved=$stopState;stopLogLine='fixture';keepAlive=$null;stopState=$stopState;reason=$null})
    }
    $handle
}
function New-Proposal([hashtable]$Ctx,[string]$Mode,[hashtable]$Options){
    # Proposal の ready 結果と同じ形（accepted/tests・accepted/replacements、control/proposal/manifest.json、testsManifestHash）。recheck は reused-tests と recheck manifest。
    $accepted=$Ctx.prepared.acceptedRoot
    $artifacts=[Collections.Generic.List[object]]::new()
    $entries=[ordered]@{'tests/test_calc.py'=@('test',$testText)}
    if($Mode -ceq 'candidate-comparison'){$entries['replacements/calc.py']=@('replacement',$fixedText)}
    foreach($path in $entries.Keys){$full=Join-Path $accepted $path;Write-V3TestText $full $entries[$path][1];$artifacts.Add(@{kind=$entries[$path][0];path=$path;size=[long]([IO.FileInfo]::new($full)).Length;sha256=(Get-V3TestHash $full)})}
    $sorted=[object[]]$artifacts.ToArray()
    $testsHash=Get-VerificationTestsManifestHash ([object[]]@($sorted | Where-Object {$_.kind -eq 'test'}))
    $origin=$(if($Mode -ceq 'recheck'){'reused-tests'}else{'generated'})
    $manifestPath=Join-Path $Ctx.controlRoot 'proposal/manifest.json'
    $manifestHash=Write-Canonical $manifestPath @{schemaVersion=3;runId=$Ctx.runId;origin=$origin;artifacts=$sorted;testsManifestHash=$testsHash}
    $sandbox=$null;$stopState='not-created'
    if($origin -ceq 'generated'){$sandbox=New-Sandbox $Ctx 'proposal' $Options;$stopState='stopped'}
    else{
        $previous=[guid]::NewGuid().ToString()
        $Ctx.prepared.recheckArtifacts=[object[]]@(foreach($a in $sorted){@{kind='test';path=$a.path;size=$a.size;sha256=$a.sha256;previousRunId=$previous}})
        $path=Join-Path $Ctx.controlRoot 'recheck-manifest.json'
        $Ctx.prepared.recheckManifestHash=Write-Canonical $path @{schemaVersion=3;runId=$Ctx.runId;previousRunId=$previous;previousResultPath="C:\runs\$previous\control\result.json";previousResultHash=('C'*64);tests=$Ctx.prepared.recheckArtifacts}
        $Ctx.prepared.recheckManifestPath=$path;$Ctx.previousRunId=$previous
    }
    @{schemaVersion=3;runId=$Ctx.runId;status='ready';origin=$origin;sandbox=$sandbox;summary='子の要約（未信頼）';findings=@(@{description='add が差を返す';sourcePaths=@('calc.py')});artifacts=$sorted;manifestPath=$manifestPath;manifestHash=$manifestHash;testsManifestHash=$testsHash;stopState=$stopState;failure=$null}
}
function New-ReplayInput([hashtable]$Ctx,[string]$Key,[string]$Mode,[hashtable]$Proposal,[System.Collections.IDictionary]$Extra){
    # replay-inputs/<before|after>（基準版の作業ファイル＋.verification-tests＋after だけ replacement）と control/replay/replay-<role>-input-manifest.json。
    # manifest の testsManifestHash は再実行が主張する値（提案の値）を書く。現物が違う入力は照合が検出する。
    $root=Join-Path $Ctx.runRoot "replay-inputs/$Key"
    Write-V3TestText (Join-Path $root 'calc.py') $(if($Key -ceq 'after' -and $Mode -ceq 'candidate-comparison'){$fixedText}else{$buggyText})
    Write-V3TestText (Join-Path $root 'util.py') "VALUE = 1`n"
    Write-V3TestText (Join-Path $root '.verification-tests/test_calc.py') $testText
    if($null -ne $Extra){foreach($path in $Extra.Keys){Write-V3TestText (Join-Path $root $path) ([string]$Extra[$path])}}
    $role="replay-$Key"
    $path=Join-Path $Ctx.controlRoot "replay/$role-input-manifest.json"
    $hash=Write-Canonical $path @{schemaVersion=3;runId=$Ctx.runId;role=$role;mode=$Mode;files=(Get-V3TestTreeManifest $root);testsManifestHash=$Proposal.testsManifestHash}
    @{path=$path;hash=$hash}
}
function New-ReplayReference([hashtable]$Ctx,[string]$Key,[hashtable]$Handle,[hashtable]$InputManifest,[hashtable]$Proposal,[int]$ExitCode){
    # Replay の外側記録 control/replay/<role>/<commandId>.json（replay-record.schema.json）と、SbxRuntime が置く出力 control/runtime/<role>/commands/<commandId>.stdout|.stderr。
    $role="replay-$Key";$commandId="$role-"+[guid]::NewGuid().ToString('N').Substring(0,12)
    $commands=Join-Path $Ctx.controlRoot "runtime/$role/commands"
    $stdout=Join-Path $commands "$commandId.stdout";$stderr=Join-Path $commands "$commandId.stderr"
    Write-V3TestText $stdout '';Write-V3TestText $stderr $(if($ExitCode -eq 0){"Ran 1 test in 0.001s`n`nOK`n"}else{"Ran 1 test in 0.001s`n`nFAILED (failures=1)`n"})
    $started=Now
    $record=@{
        schemaVersion=3;commandId=$commandId;runId=$Ctx.runId;role=$role;sandboxId=$Handle.id;profileHash=$Handle.profileHash;effectiveSettingsHash=$Handle.effectiveSettingsHash;templateDigest=$Ctx.expect.replay.templateDigest
        sourceManifestHash=$Ctx.prepared.sourceManifestHash;inputManifestHash=$InputManifest.hash;testsManifestHash=$Proposal.testsManifestHash;argv=$replayArgv;workingDirectory='/home/agent/workspace/source'
        startedAt=$started;finishedAt=(Now);exitCode=$ExitCode;stdoutPath=$stdout;stdoutHash=(Get-V3TestHash $stdout);stderrPath=$stderr;stderrHash=(Get-V3TestHash $stderr)
        timedOut=$false;outputExceeded=$false;stopVerified=$true;transportVerified=$true;activationRecordPath=$Handle.activationRecordPath;activationRecordHash=$Handle.activationRecordHash;limits=$Ctx.settings.limits
    }
    $path=Join-Path $Ctx.controlRoot "replay/$role/$commandId.json"
    $hash=Write-Canonical $path $record
    @{role=$role;commandId=$commandId;recordPath=$path;recordHash=$hash;sandbox=$Handle;inputManifestPath=$InputManifest.path;inputManifestHash=$InputManifest.hash}
}
function New-Run([string]$Mode='candidate-comparison',[int]$BeforeExit=1,[int]$AfterExit=0,[hashtable]$Options=@{},[string]$SourceRoot=$sharedSource,[switch]$SkipReplay){
    # 1 run 分の3入力と control の記録。Options: proposal/before/after → New-Sandbox の設定、beforeExtra/afterExtra → replay input へ足す・上書くファイル。
    $ctx=New-ResultCtx $SourceRoot
    $proposal=New-Proposal $ctx $Mode $Options['proposal']
    $replay=@{schemaVersion=3;runId=$ctx.runId;status='completed';mode=$Mode;sandboxes=[object[]]@();before=$null;after=$null;allStopped=$null;failure=$null}
    if(-not$SkipReplay){
        $handles=[Collections.Generic.List[object]]::new()
        foreach($key in $modeRoles[$Mode]){
            $inputManifest=New-ReplayInput $ctx $key $Mode $proposal $Options["${key}Extra"]
            $handle=New-Sandbox $ctx "replay-$key" $Options[$key];$handles.Add($handle)
            $replay[$key]=New-ReplayReference $ctx $key $handle $inputManifest $proposal $(if($key -ceq 'before'){$BeforeExit}else{$AfterExit})
        }
        $replay.sandboxes=[object[]]$handles.ToArray();$replay.allStopped=$true
    }
    @{ctx=$ctx;proposal=$proposal;replay=$replay}
}
function Update-Record([hashtable]$Reference,[scriptblock]$Edit){
    # 記録を書き換え、参照の recordHash も合わせる（ハッシュだけでは偽造を見抜けない入力）。
    $value=[IO.File]::ReadAllText($Reference.recordPath,$utf8) | ConvertFrom-Json -AsHashtable -DateKind String
    & $Edit $value
    [IO.File]::WriteAllText($Reference.recordPath,(ConvertTo-VerificationCanonicalJson $value),$utf8)
    $Reference.recordHash=Get-V3TestHash $Reference.recordPath
}
function Assert-Saved([hashtable]$Ctx,$Result,[string]$Label){
    # control/result.json が返した結果と同じ正規化JSONで1件だけ保存され、schema（execution の pilotInput 3項目を含む9キー）に適合する。
    $path=Join-Path $Ctx.controlRoot 'result.json'
    $text=[IO.File]::ReadAllText($path,$utf8)
    Assert-Equal $text (ConvertTo-VerificationCanonicalJson $Result) "${label}: 保存した結果と返した結果が同じ"
    Assert-True (Test-Json -Json $text -SchemaFile $schemaPath) "${label}: result.schema.json（v3）に適合"
    Assert-Equal ((@($Result.execution.Keys) | Sort-Object -CaseSensitive) -join ',') $executionKeys "${label}: execution のキー集合"
}
function Invoke-Result([hashtable]$Run,[string]$Label){
    $r=Complete-VerificationRun $Run.ctx.prepared $Run.proposal $Run.replay
    Assert-Saved $Run.ctx $r $Label
    $r
}
function Assert-Outcome($Result,[string]$Status,[string]$Verdict,[int]$Exit,[string]$Label){
    Assert-True ($Result.status -ceq $Status -and $Result.replayVerdict -ceq $Verdict -and $Result.execution.exitCodeForCli -eq $Exit) "${Label}: status=$($Result.status) verdict=$($Result.replayVerdict) exit=$($Result.execution.exitCodeForCli) stage=$($Result.execution.failureStage) unverified=$(@($Result.unverified) -join ' | ')"
}
function Assert-Unverified($Result,[string]$Pattern,[string]$Label){
    Assert-True (@($Result.unverified | Where-Object {$_ -like $Pattern}).Count -gt 0) "${Label}: unverified に $Pattern（実際: $(@($Result.unverified) -join ' | ')）"
}

$sharedSource=New-GitSource

# 1. candidate-comparison の正常対照: before 非0・after 0 → completed・candidate-supported・終了0。scope と既知の制約、checks・artifacts・findings・execution。
$run=New-Run 'candidate-comparison' 1 0
$r=Invoke-Result $run '正常'
Assert-Outcome $r 'completed' 'candidate-supported' 0 '正常'
Assert-True ($r.sourceState -ceq 'unchanged' -and $r.baselineState -ceq 'unchanged' -and $r.proposalVerdict -ceq 'reference-only' -and $null -eq $r.previousRunId -and $r.unverified.Count -eq 0) '正常: 原本・基準版 unchanged、提案は reference-only、未確認なし'
Assert-True ($r.scope -ceq 'synthetic-pilot' -and (@($r.limitations) -join ',') -ceq 'clipboard-text-write-possible,pid-count-unbounded,daemon-disconnect-unverified') '正常: scope と既知の制約3件を省略しない'
Assert-True ($r.checks.Count -eq 2 -and $r.checks[0].role -ceq 'replay-before' -and $r.checks[0].exitCode -eq 1 -and $r.checks[1].exitCode -eq 0 -and $r.checks[0].commandId -ceq $run.replay.before.commandId -and $r.checks[0].sandboxId -ceq $run.replay.before.sandbox.id -and $r.checks[0].recordHash -ceq $run.replay.before.recordHash) '正常: checks は外側記録の role・commandId・sandboxId・hash・終了値'
Assert-True ((@($r.artifacts | ForEach-Object {"$($_.kind):$($_.path):$($null -eq $_.previousRunId)"}) -join ',') -ceq 'replacement:replacements/calc.py:True,test:tests/test_calc.py:True') '正常: artifacts は検査済みの accepted 一覧'
Assert-True ($r.findings.Count -eq 2 -and $r.findings[0].description -ceq '子の要約（未信頼）' -and $r.findings[1].sourcePaths[0] -ceq 'calc.py') '正常: 子の説明は findings に分けて返す'
Assert-True ($r.execution.proposalCreated -eq $true -and $r.execution.proposalStopped -eq $true -and $r.execution.replayCreatedCount -eq 2 -and $r.execution.replayAllStopped -eq $true -and $null -eq $r.execution.failureStage) '正常: execution の作成と停止'
Assert-True ($r.execution.pilotInputId -ceq 'pilot-fixture' -and $r.execution.pilotInputPath -ceq $run.ctx.prepared.pilotInputPath -and $r.execution.pilotInputHash -ceq $run.ctx.prepared.pilotInputHash -and $r.sourceManifestPath -ceq $run.ctx.prepared.sourceManifestPath -and $r.runRoot -ceq $run.ctx.runRoot) '正常: execution の pilotInput 3項目と保存先'
$count++

# 2. candidate-comparison の観測分類: before 非0・after 非0 → still-failing（終了1）、before 0 → not-reproduced（終了1）。
$r=Invoke-Result (New-Run 'candidate-comparison' 1 1) 'still-failing'
Assert-Outcome $r 'completed' 'still-failing' 1 'still-failing'
$r=Invoke-Result (New-Run 'candidate-comparison' 0 0) 'not-reproduced'
Assert-Outcome $r 'completed' 'not-reproduced' 1 'candidate-comparison の not-reproduced'
$count++

# 3. reproduction-only: before だけを照合する（after VM・入力なし）。before 非0 → reproduced（1）、before 0 → not-reproduced（1）。
$run=New-Run 'reproduction-only' 1
$r=Invoke-Result $run 'reproduced'
Assert-Outcome $r 'completed' 'reproduced' 1 'reproduction-only の reproduced'
Assert-True ($r.checks.Count -eq 1 -and $r.execution.replayCreatedCount -eq 1 -and $r.artifacts.Count -eq 1) 'reproduction-only: before の記録1件'
$r=Invoke-Result (New-Run 'reproduction-only' 0) 'reproduction-only not-reproduced'
Assert-Outcome $r 'completed' 'not-reproduced' 1 'reproduction-only の not-reproduced'
$count++

# 4. recheck: reused-tests（提案VMなし＝停止値 null）と after だけ。after 0 → current-pass（0）、after 非0 → current-fail（1）。前回の runId と由来を返す。
$run=New-Run 'recheck' 0 0
$r=Invoke-Result $run 'current-pass'
Assert-Outcome $r 'completed' 'current-pass' 0 'recheck の current-pass'
Assert-True ($r.previousRunId -ceq $run.ctx.previousRunId -and $r.artifacts.Count -eq 1 -and $r.artifacts[0].previousRunId -ceq $run.ctx.previousRunId) 'recheck: previousRunId と artifacts の由来'
Assert-True ($r.execution.proposalCreated -eq $false -and $null -eq $r.execution.proposalStopped -and $r.execution.replayCreatedCount -eq 1) 'recheck: 未作成の提案VMは停止値 null'
$r=Invoke-Result (New-Run 'recheck' 0 1) 'current-fail'
Assert-Outcome $r 'completed' 'current-fail' 1 'recheck の current-fail'
$count++

# 5. 架空の commandId・記録と別の sandboxId・別の起動世代（daemonInstance）→ incomplete・undetermined・終了2。
# 架空の commandId: 記録のパス・hash は架空の commandId に合わせ（本物の記録を別名で複製）、中身の commandId との不一致そのもので落ちること。
$run=New-Run;$fake='replay-before-0123456789ab'
$fakePath=Join-Path $run.ctx.controlRoot "replay/replay-before/$fake.json"
[IO.File]::Copy($run.replay.before.recordPath,$fakePath)
$run.replay.before.commandId=$fake;$run.replay.before.recordPath=$fakePath;$run.replay.before.recordHash=Get-V3TestHash $fakePath
$r=Invoke-Result $run '架空 commandId'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '架空 commandId'
Assert-Unverified $r 'result/replay-before-record:record-mismatch: replay record commandId does not match*' '架空 commandId'
Assert-True (@($r.unverified | Where-Object {$_ -like '*record-missing*' -or $_ -like '*evidence path*'}).Count -eq 0) '架空 commandId: パスの位置ではなく commandId の不一致で落ちる'
$run=New-Run;Update-Record $run.replay.after {param($v) $v.sandboxId=[guid]::NewGuid().ToString()}
$r=Invoke-Result $run '別 sandboxId'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '記録が別 sandboxId'
Assert-Unverified $r 'result/replay-after-record:record-mismatch*' '記録が別 sandboxId'
$run=New-Run -Options @{after=@{daemon=@{pid=5151;startedAt='2026-09-15T01:00:00.0000000Z';version='v0.42.1 fake';socket='fake'}}}
$r=Invoke-Result $run '別世代'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'after が別の起動世代'
Assert-Unverified $r '*daemon-changed*' 'after が別の起動世代'
$run=New-Run 'reproduction-only' 1 -Options @{proposal=@{daemon=@{pid=6161;startedAt='2026-09-15T02:00:00.0000000Z';version='v0.42.1 fake';socket='fake'}}}
$r=Invoke-Result $run '提案VMと別世代'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '1台だけの mode でも提案VMの世代と照合'
Assert-Unverified $r '*daemon-changed*' '1台だけの mode でも提案VMの世代と照合'
$count++

# 5b. 役割と VM id の対応（I1）: 参照が別役割の VM を指す、before と after が同じ id、再実行 VM が提案 VM と同じ id → incomplete。
$run=New-Run
Update-Record $run.replay.before {param($v) $v.sandboxId=$run.replay.after.sandbox.id;$v.activationRecordPath=$run.replay.after.sandbox.activationRecordPath;$v.activationRecordHash=$run.replay.after.sandbox.activationRecordHash}
$run.replay.before.sandbox=$run.replay.after.sandbox
$r=Invoke-Result $run '役割を入れ替えた参照'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '役割を入れ替えた参照'
Assert-Unverified $r 'result/replay-before-record:record-sandbox: replay before reference points to a sandbox of another role*' '役割を入れ替えた参照'
$same=[guid]::NewGuid().ToString()
$r=Invoke-Result (New-Run -Options @{before=@{id=$same};after=@{id=$same}}) '同一 id の before/after'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '同一 id の before/after'
Assert-Unverified $r 'result/replay-sandbox:sandbox-reused*' '同一 id の before/after'
$same=[guid]::NewGuid().ToString()
$r=Invoke-Result (New-Run 'reproduction-only' 1 -Options @{proposal=@{id=$same};before=@{id=$same}}) '提案VMと同一 id'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '再実行 VM が提案 VM と同じ id'
Assert-Unverified $r 'result/replay-sandbox:sandbox-reused*' '再実行 VM が提案 VM と同じ id'
$count++

# 5c. 実行設定の能力証拠（I2）: settings の profile が検査を通らない、VM の profileHash が profile と違う、記録の templateDigest が profile と違う → incomplete。
$run=New-Run
$profile=[IO.File]::ReadAllText($run.ctx.settings.replayProfilePath,$utf8) | ConvertFrom-Json -AsHashtable
$profile.stdlibModulesHash=('0'*64)
[IO.File]::WriteAllText($run.ctx.settings.replayProfilePath,(ConvertTo-VerificationCanonicalJson $profile),$utf8)
$r=Invoke-Result $run 'profile 不合格'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'replay profile が検査を通らない'
Assert-Unverified $r 'result/replay-profile:profile-rejected: runtime profile rejected*' 'replay profile が検査を通らない'
$r=Invoke-Result (New-Run -Options @{after=@{profileHash=('D'*64)}}) 'profileHash 不一致'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'VM の profileHash が profile と違う'
Assert-Unverified $r 'result/replay-sandbox:profile-mismatch*' 'VM の profileHash が profile と違う'
$r=Invoke-Result (New-Run 'reproduction-only' 1 -Options @{proposal=@{profileHash=('E'*64)}}) '提案 profileHash 不一致'
Assert-Unverified $r 'result/proposal-sandbox:profile-mismatch*' '提案 VM の profileHash が proposal profile と違う'
$run=New-Run;Update-Record $run.replay.after {param($v) $v.templateDigest='docker.io/docker/sandbox-templates@sha256:'+('1'*64)}
$r=Invoke-Result $run 'templateDigest 不一致'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '記録の templateDigest が profile と違う'
Assert-Unverified $r 'result/replay-after-record:profile-mismatch*' '記録の templateDigest が profile と違う'
$count++

# 6. before/after の effectiveSettingsHash 不一致（candidate-comparison だけ照合）→ incomplete。
$run=New-Run -Options @{after=@{effectiveSettingsHash=('C'*64)}}
$r=Invoke-Result $run 'effectiveSettingsHash'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'effectiveSettingsHash 不一致'
Assert-Unverified $r 'result/effective-settings:effective-settings-differ*' 'effectiveSettingsHash 不一致'
$count++

# 7. 自己申告 pass だけ（再実行が completed と言うが記録参照・VM なし）→ incomplete。
$run=New-Run -SkipReplay
$r=Invoke-Result $run '自己申告'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '自己申告の completed だけ'
Assert-Unverified $r 'result/replay-evidence:reference-missing*' '自己申告の completed だけ'
Assert-True ($r.checks.Count -eq 0) '自己申告: 検査済みの記録なし'
$count++

# 8. 基準版の Git 改変 → baselineState=changed・incomplete（blocked より優先）。
$run=New-Run;[IO.File]::WriteAllText((Join-Path $run.ctx.prepared.baselineRoot '.git/HEAD'),"ref: refs/heads/evil`n",$utf8)
$run.replay.status='blocked';$run.replay.failure=@{stage='replay-after';reason='activation-record'}
$r=Invoke-Result $run '基準Git改変'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '基準版の Git 改変'
Assert-True ($r.baselineState -ceq 'changed' -and $r.execution.failureStage -ceq 'result/baseline') '基準版の Git 改変: changed で、blocked より先に基準版改変を返す'
$count++

# 9. 原本更新 → source_changed。scope は付けない（limitations=[]）。
$ownSource=New-GitSource
$run=New-Run -SourceRoot $ownSource
[IO.File]::WriteAllText((Join-Path $ownSource 'tracked.txt'),'changed',$utf8)
$r=Invoke-Result $run '原本更新'
Assert-Outcome $r 'source_changed' 'undetermined' 2 '原本更新'
Assert-True ($r.sourceState -ceq 'changed' -and $null -eq $r.scope -and $r.limitations.Count -eq 0) '原本更新: 古い結果に scope を付けない'
$count++

# 10. 出力欠落（stdout を移動）→ incomplete。検査済みの記録は checks に残し、観測分類は作らない。
$run=New-Run;[IO.File]::Move((Join-Path $run.ctx.controlRoot "runtime/replay-after/commands/$($run.replay.after.commandId).stdout"),(Join-Path $run.ctx.controlRoot 'moved.stdout'))
$r=Invoke-Result $run '出力欠落'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '出力欠落'
Assert-Unverified $r 'result/replay-after-record:record-output*' '出力欠落'
$count++

# 11. 同一テストでない比較（after の tests が違う）と、after の差分が replacement 一覧を超える入力 → incomplete。
$run=New-Run -Options @{afterExtra=[ordered]@{'.verification-tests/test_calc.py'="import unittest`nclass T(unittest.TestCase):`n    def test_ok(self): pass`n"}}
$r=Invoke-Result $run '同一テストでない'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '同一テストでない比較'
Assert-Unverified $r 'result/replay-after-input:replay-tests-differ*' '同一テストでない比較'
$run=New-Run -Options @{afterExtra=[ordered]@{'util.py'="VALUE = 2`n"}}
$r=Invoke-Result $run 'replacement 超過'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'replacement 一覧を超える差分'
Assert-Unverified $r 'result/replay-diff:replay-diff-outside-replacements*' 'replacement 一覧を超える差分'
$count++

# 12. 停止未確認: 作成済み after の停止記録が unverified（再実行は blocked）→ incomplete が blocked より優先。提案VMの停止記録なしも incomplete。
$run=New-Run -Options @{after=@{stopState='unverified'}}
$run.replay.status='blocked';$run.replay.failure=@{stage='replay-after';reason='activation-record'};$run.replay.after=$null;$run.replay.allStopped=$false
$r=Invoke-Result $run '停止未確認'
Assert-Outcome $r 'incomplete' 'undetermined' 2 'after の停止未確認'
Assert-True ($r.execution.failureStage -ceq 'result/replay-stop' -and $r.execution.replayAllStopped -eq $false -and $r.execution.replayCreatedCount -eq 2) '停止未確認: blocked より先に停止未確認を返す'
Assert-Unverified $r 'replay/replay-after:activation-record' '停止未確認: 上流の理由も残す'
$run=New-Run -Options @{proposal=@{noStop=$true}}
$r=Invoke-Result $run '提案VMの停止記録なし'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '提案VMの停止記録なし（結果は stopped と自己申告）'
Assert-True ($r.execution.proposalStopped -eq $false -and $r.execution.failureStage -ceq 'result/proposal-stop') '提案VMの停止記録なし: proposalStopped=false'
$count++

# 13. not_run は上流に従う: 提案が未作成で blocked → blocked、提案が停止済みで timed_out → timed_out、提案 ready なのに not_run → incomplete。
$ctx=New-ResultCtx $sharedSource
$proposal=@{schemaVersion=3;runId=$ctx.runId;status='blocked';origin='generated';sandbox=$null;summary=$null;findings=$null;artifacts=@();manifestPath=$null;manifestHash=$null;testsManifestHash=$null;stopState='not-created';failure=@{stage='sandbox';reason='daemon-not-running'}}
$replay=@{schemaVersion=3;runId=$ctx.runId;status='not_run';mode=$null;sandboxes=@();before=$null;after=$null;allStopped=$null;failure=@{stage='sandbox';reason='daemon-not-running'}}
$r=Complete-VerificationRun $ctx.prepared $proposal $replay;Assert-Saved $ctx $r 'not_run blocked'
Assert-Outcome $r 'blocked' 'undetermined' 2 'not_run が未作成の blocked に従う'
Assert-True ($r.execution.failureStage -ceq 'proposal/sandbox' -and $r.execution.proposalCreated -eq $false -and $null -eq $r.execution.proposalStopped -and $r.execution.replayCreatedCount -eq 0 -and $null -eq $r.execution.replayAllStopped -and $null -eq $r.proposalVerdict -and $r.scope -ceq 'synthetic-pilot') 'not_run blocked: 未作成の停止値は null で事故扱いしない'
$ctx=New-ResultCtx $sharedSource
$proposal=@{schemaVersion=3;runId=$ctx.runId;status='timed_out';origin='generated';sandbox=(New-Sandbox $ctx 'proposal' @{});summary=$null;findings=$null;artifacts=@();manifestPath=$null;manifestHash=$null;testsManifestHash=$null;stopState='stopped';failure=@{stage='agent';reason='agent-timed-out'}}
$replay=@{schemaVersion=3;runId=$ctx.runId;status='not_run';mode=$null;sandboxes=@();before=$null;after=$null;allStopped=$null;failure=@{stage='agent';reason='agent-timed-out'}}
$r=Complete-VerificationRun $ctx.prepared $proposal $replay;Assert-Saved $ctx $r 'not_run timed_out'
Assert-Outcome $r 'timed_out' 'undetermined' 2 'not_run が timed_out に従う'
Assert-True ($r.execution.proposalCreated -eq $true -and $r.execution.proposalStopped -eq $true) 'not_run timed_out: 停止済みの提案VM'
# 提案VMの作成成否が不明（sandbox なし・stopState=unverified）で、再実行は VM を作っていない not_run（allStopped=null）: 照合が提案結果から incomplete にし、再実行側の停止値は null のまま。
$ctx=New-ResultCtx $sharedSource
$proposal=@{schemaVersion=3;runId=$ctx.runId;status='incomplete';origin='generated';sandbox=$null;summary=$null;findings=$null;artifacts=@();manifestPath=$null;manifestHash=$null;testsManifestHash=$null;stopState='unverified';failure=@{stage='sandbox';reason='create-timed-out'}}
$replay=@{schemaVersion=3;runId=$ctx.runId;status='not_run';mode=$null;sandboxes=@();before=$null;after=$null;allStopped=$null;failure=@{stage='sandbox';reason='create-timed-out'}}
$r=Complete-VerificationRun $ctx.prepared $proposal $replay;Assert-Saved $ctx $r 'not_run 提案作成不明'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '提案VMの作成成否不明'
Assert-True ($r.execution.proposalStopped -eq $false -and $r.execution.replayCreatedCount -eq 0 -and $null -eq $r.execution.replayAllStopped) '提案VMの作成成否不明: 提案側は停止未確認、再実行側の停止値は null'
Assert-Unverified $r 'result/proposal-stop:creation-unresolved*' '提案VMの作成成否不明'
$run=New-Run -SkipReplay;$run.replay.status='not_run';$run.replay.failure=@{stage='proposal-input';reason='x'}
$r=Invoke-Result $run 'ready なのに not_run'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '提案 ready なのに not_run'
Assert-Unverified $r 'replay:not-run-without-cause*' '提案 ready なのに not_run'
$count++

# 14. 固定入力記録の改変 → scope を付けず incomplete。
$run=New-Run;[IO.File]::AppendAllText($run.ctx.prepared.pilotInputPath,' ',$utf8)
$r=Invoke-Result $run '固定入力改変'
Assert-Outcome $r 'incomplete' 'undetermined' 2 '固定入力記録の改変'
Assert-Unverified $r 'result/pilot-input:pilot-input*' '固定入力記録の改変'
Assert-True ($null -eq $r.scope -and $r.limitations.Count -eq 0 -and $r.execution.pilotInputHash -ceq $run.ctx.prepared.pilotInputHash) '固定入力記録の改変: scope なし、pilotInput は PreparedRun の値'
$count++

# 15. 失敗結果の null 書式（準備前）と、run 作成済みの保存・判明済み VM の停止未確認・時間超過の優先。
$f=New-VerificationFailureResult @{runId=$null;runRoot=$null;sourceRoot=$null} @{status='blocked';stage='request';reason='invalid-request'}
Assert-True (Test-Json -Json (ConvertTo-VerificationCanonicalJson $f) -SchemaFile $schemaPath) '失敗結果: schema に適合'
Assert-True ($f.status -ceq 'blocked' -and $null -eq $f.runId -and $null -eq $f.runRoot -and $null -eq $f.sourceManifestPath -and $null -eq $f.previousRunId -and $f.sourceState -ceq 'unreadable' -and $f.baselineState -ceq 'unreadable' -and $null -eq $f.proposalVerdict -and $f.replayVerdict -ceq 'undetermined') '失敗結果: null と unreadable'
Assert-True ($f.checks.Count -eq 0 -and $f.findings.Count -eq 0 -and $f.artifacts.Count -eq 0 -and $null -eq $f.scope -and $f.limitations.Count -eq 0) '失敗結果: 空配列、scope=null'
Assert-True ($f.execution.proposalCreated -eq $false -and $f.execution.replayCreatedCount -eq 0 -and $null -eq $f.execution.proposalStopped -and $null -eq $f.execution.replayAllStopped -and $f.execution.failureStage -ceq 'request' -and $f.execution.exitCodeForCli -eq 2 -and $null -eq $f.execution.pilotInputId -and $null -eq $f.execution.pilotInputPath -and $null -eq $f.execution.pilotInputHash) '失敗結果: execution の未起動値'
Assert-Equal ((@($f.execution.Keys) | Sort-Object -CaseSensitive) -join ',') $executionKeys '失敗結果: execution のキー集合'
$ctx=New-ResultCtx $sharedSource
$f=New-VerificationFailureResult @{runId=$ctx.runId;runRoot=$ctx.runRoot;sourceRoot=$sharedSource;pilotInputId='pilot-fixture';pilotInputPath=$ctx.prepared.pilotInputPath;pilotInputHash=$ctx.prepared.pilotInputHash;proposalCreated=$true;proposalStopped=$false} @{status='blocked';stage='assemble';reason='result-error'}
Assert-Saved $ctx $f '失敗結果（run 作成済み）'
Assert-True ($f.status -ceq 'incomplete' -and $f.runRoot -ceq $ctx.runRoot -and $f.execution.proposalCreated -eq $true -and $f.execution.proposalStopped -eq $false -and $f.execution.pilotInputHash -ceq $ctx.prepared.pilotInputHash) '失敗結果: 判明済みの作成済みVMの停止未確認は blocked を incomplete に上げる'
$f=New-VerificationFailureResult @{runRoot=(Join-Path $base 'absent-run');replayCreatedCount=1;replayAllStopped=$false} @{status='timed_out';stage='replay';reason='deadline'}
Assert-True ($f.status -ceq 'timed_out' -and $null -eq $f.runRoot -and $f.execution.replayAllStopped -eq $false) '失敗結果: 時間超過を優先し、存在しない runRoot は返さない'
Assert-Throws {New-VerificationFailureResult @{} @{status='completed';stage='x';reason='y'}} '*Failure with status*'
$count++

# 16. 既存 result.json の保全（照合・失敗結果とも上書きしない）と、版の混在の拒否。
$run=New-Run;$existing=Join-Path $run.ctx.controlRoot 'result.json';[IO.File]::WriteAllText($existing,'original',$utf8)
Assert-Throws {Complete-VerificationRun $run.ctx.prepared $run.proposal $run.replay} '*already exists*'
Assert-Throws {New-VerificationFailureResult @{runRoot=$run.ctx.runRoot} @{status='blocked';stage='x';reason='y'}} '*already exists*'
Assert-Equal ([IO.File]::ReadAllText($existing,$utf8)) 'original' '既存結果を保全'
$run=New-Run
Assert-Throws {Complete-VerificationRun $run.ctx.prepared $run.proposal} '*schemaVersion 3*'
$v1Run=@{runId=$run.ctx.runId;runRoot=$run.ctx.runRoot;controlRoot=$run.ctx.controlRoot;sourceRoot=$sharedSource}
Assert-Throws {Complete-VerificationRun $v1Run $run.proposal $run.replay} '*PreparedRunV3 with schemaVersion 3*'
$run.replay.schemaVersion=2
Assert-Throws {Complete-VerificationRun $run.ctx.prepared $run.proposal $run.replay} '*schemaVersion 3*'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $run.ctx.controlRoot 'result.json'))) '版の混在: 結果を作らない'
$count++

"ResultV3: $count cases passed ($([int]$clock.Elapsed.TotalSeconds)s)"
