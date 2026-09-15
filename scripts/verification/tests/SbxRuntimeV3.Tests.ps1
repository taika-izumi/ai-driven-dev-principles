$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../SbxRuntime.psm1') -Force -DisableNameChecking   # Acquire- は仕様02の公開操作名（未承認動詞の警告を抑止）
# すべて偽sbx（tests/fixtures）と偽の状態ディレクトリで行い、実VM・実デーモンは使わない。偽sbxの成功を実機の保護実証に数えない。
# ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$base=Join-Path $repo '.tmp/verification-tests'
$utf8=[Text.UTF8Encoding]::new($false)
$digest=Get-FakeSbxTemplateDigest
$limitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
$evidenceTemplate=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fixtures/activation-evidence.json'),$utf8)
$module=Get-Module SbxRuntime
$count=0
function Get-Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Write-Text([string]$Path,[string]$Text){[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path));[IO.File]::WriteAllText($Path,$Text,$utf8)}
function New-Profile([hashtable]$Ctx,[string]$Role,[hashtable]$Overrides=@{},[scriptblock]$EvidenceEdit=$null){
    # 試験用 profile。evidence は fixture の雛形から profileHash と証拠パス/ハッシュを埋めてケース領域へ書く。
    $profile=@{
        schemaVersion=3;role=$Role;sbxVersion='v0.42.1';templateDigest=$digest;agent=$(if($Role -eq 'proposal'){'codex'}else{'shell'});model=$(if($Role -eq 'proposal'){'unit-model'}else{$null})
        startupArgv=[string[]]$(if($Role -eq 'proposal'){@('codex','exec','--json')}else{@('sh')});executableInVm=$(if($Role -eq 'proposal'){'/usr/local/bin/codex'}else{'/usr/bin/python3'})
        policyExpectation=@{networkPolicy='deny *'};mountExpectation=@{workspace='none';shareSkills=$false;sshAgentForwarding=$false}
        scope='synthetic-pilot';acceptedLimitations=$limitations
        stdlibModulesPath='stdlib-modules.txt';stdlibModulesHash=(Get-Hash (Join-Path $Ctx.prof 'stdlib-modules.txt'))
        activationEvidencePath=$null;activationEvidenceHash=$null
    }
    foreach($key in $Overrides.Keys){$profile[$key]=$Overrides[$key]}
    # profileHash は試験側で独立に計算する（evidence の2項目を除いた正規化JSONの SHA256）。
    $subset=@{};foreach($key in $profile.Keys){if($key -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$key]=$profile[$key]}}
    $profileHash=Get-VerificationCanonicalHash $subset
    $json=$evidenceTemplate.Replace('{{profileHash}}',$profileHash).Replace('{{evidencePath}}','evidence-note.txt').Replace('{{evidenceHash}}',(Get-Hash (Join-Path $Ctx.prof 'evidence-note.txt')))
    $evidence=$json | ConvertFrom-Json -AsHashtable -Depth 10
    $evidence.Remove('_comment')
    if($evidence.checkedAt -is [DateTime]){$evidence.checkedAt=$evidence.checkedAt.ToUniversalTime().ToString('o')}   # ConvertFrom-Json は ISO 日時を DateTime にする
    if($null -ne $EvidenceEdit){& $EvidenceEdit $evidence}
    $Ctx.evidenceSeq++
    $evidenceName="ev-$Role-$($Ctx.evidenceSeq).json"
    Write-Text (Join-Path $Ctx.prof $evidenceName) (ConvertTo-VerificationCanonicalJson $evidence)
    $profile.activationEvidencePath=$evidenceName
    $profile.activationEvidenceHash=Get-Hash (Join-Path $Ctx.prof $evidenceName)
    $profile
}
function New-Case([int]$CleanupSeconds=30,[int]$DeadlineIn=600){
    $root=Join-Path $base ('s3'+[guid]::NewGuid().ToString('N').Substring(0,6))
    $case=New-FakeSbxCase $root
    $runId=[guid]::NewGuid().ToString()
    $runRoot=Join-Path $root 'run';$control=Join-Path $runRoot 'control';$prof=Join-Path $root 'prof';$source=Join-Path $root 'src'
    foreach($dir in @($control,(Join-Path $control 'runtime'),(Join-Path $runRoot 'quarantine'),$prof,$source,(Join-Path $root 'in'))){[void][IO.Directory]::CreateDirectory($dir)}
    Write-Text (Join-Path $prof 'evidence-note.txt') "fixture evidence note`n"
    Write-Text (Join-Path $prof 'stdlib-modules.txt') "os`nsys`nunittest`n"
    Write-Text (Join-Path $prof 'replay.json') '{}';Write-Text (Join-Path $prof 'proposal.json') '{}'
    $manifest=@{schemaVersion=3;files=@(@{path='tracked.txt';size=8;sha256=('A'*64)})}
    $manifestPath=Join-Path $control 'source-manifest.json'
    Write-VerificationNewFile $manifestPath (ConvertTo-VerificationCanonicalJson $manifest)
    $manifestHash=Get-Hash $manifestPath
    $pilot=@{schemaVersion=3;inputId='pilot-fixture';scope='synthetic-pilot';sourceRoot=$source;sourceManifestHash=$manifestHash;approvalReference=@{path='docs/records/reviews/fixture.md';version='0000000'}}
    $pilotPath=Join-Path $control 'pilot-input.json'
    Write-VerificationNewFile $pilotPath (ConvertTo-VerificationCanonicalJson $pilot)
    $settings=@{
        schemaVersion=3;sbxPath=$case.sbxPath;pwshPath=(Get-Command pwsh).Source;runsRoot=(Join-Path $root 'runs');model='unit-model'
        proposalProfilePath=(Join-Path $prof 'proposal.json');replayProfilePath=(Join-Path $prof 'replay.json');pilotInputPath=$pilotPath
        limits=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=$CleanupSeconds;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1MB;maxProposalBytes=8MB;maxWireBytes=16MB;maxOutputBytes=16MB}
    }
    $now=[DateTime]::UtcNow
    $prepared=@{
        schemaVersion=3;runId=$runId;sourceRoot=$source;runRoot=$runRoot;baselineRoot=(Join-Path $runRoot 'baseline');proposalInputRoot=(Join-Path $runRoot 'proposal-input');acceptedRoot=(Join-Path $runRoot 'accepted');controlRoot=$control
        request=@{schemaVersion=3};settings=$settings
        sourceManifestPath=$manifestPath;sourceManifestHash=$manifestHash;baselineManifestPath=$null;baselineManifestHash=$null;recheckManifestPath=$null;recheckManifestHash=$null;recheckArtifacts=@()
        startedAt=$now.ToString('o');deadlineAt=$now.AddSeconds($DeadlineIn).ToString('o');cleanupSeconds=$CleanupSeconds
        pilotInputId='pilot-fixture';pilotInputPath=$pilotPath;pilotInputHash=(Get-Hash $pilotPath)
    }
    $ctx=@{case=$case;root=$root;runId=$runId;runRoot=$runRoot;controlRoot=$control;prof=$prof;settings=$settings;prepared=$prepared;evidenceSeq=0;names=@{}}
    foreach($pair in @(@('proposal','proposal'),@('replay-before','before'),@('replay-after','after'))){$ctx.names[$pair[0]]='iv-'+$runId.Substring(0,8)+'-'+$pair[1]}
    $ctx.replayProfile=New-Profile $ctx 'replay';$ctx.proposalProfile=New-Profile $ctx 'proposal'
    $ctx
}
function New-Budget([hashtable]$Ctx,[string]$Phase='work',[int]$CommandSeconds=120,$CleanupIn=$null){
    @{deadlineAt=$Ctx.prepared.deadlineAt;cleanupDeadlineAt=$(if($null -eq $CleanupIn){$null}else{[DateTime]::UtcNow.AddSeconds([double]$CleanupIn).ToString('o')});limits=@{maxOutputBytes=$Ctx.settings.limits.maxOutputBytes;commandSeconds=$CommandSeconds};phase=$Phase}
}
function Get-Failure([scriptblock]$Action){try{& $Action | Out-Null}catch{return $_.Exception};throw 'ASSERT: expected an exception'}
function Get-Utc($Value){
    # ConvertFrom-Json は ISO 日時を DateTime にするため、文字列と DateTime の両方を UTC の DateTime にそろえる。
    if($Value -is [DateTime]){return $Value.ToUniversalTime()}
    [DateTimeOffset]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime
}
function Get-RuntimeFailure([scriptblock]$Action){
    $failure=Get-Failure $Action
    Assert-True ($failure.Data.Contains('runtimeFailure')) "runtimeFailure expected: $($failure.Message)"
    $record=$failure.Data['runtimeFailure'] | ConvertFrom-Json -AsHashtable
    $record.status=$failure.Data['status'];$record.message=$failure.Message
    $record
}
function Get-Calls([hashtable]$Ctx,[string]$First=''){$calls=@(Read-FakeSbxCalls $Ctx.case);$calls | Where-Object {$First -eq '' -or ($_.argv.Count -gt 0 -and $_.argv[0] -eq $First)}}

# 1. 実行設定検査: replay/proposal の正常 profile は profileHash（evidence の2項目を除く正規化JSONの SHA256）を返す。
$ctx=New-Case
$hash=Test-VerificationRuntimeProfile $ctx.replayProfile 'replay-before' $ctx.settings
Assert-True ($hash -match '^[A-F0-9]{64}$') 'profile: profileHash は大文字16進64桁'
$subset=@{};foreach($k in $ctx.replayProfile.Keys){if($k -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$k]=$ctx.replayProfile[$k]}}
Assert-Equal $hash (Get-VerificationCanonicalHash $subset) 'profile: 独立計算の profileHash と一致'
Assert-Equal (Test-VerificationRuntimeProfile $ctx.replayProfile 'replay-after' $ctx.settings) $hash 'profile: replay-after も同じ replay profile を受ける'
Assert-True ((Test-VerificationRuntimeProfile $ctx.proposalProfile 'proposal' $ctx.settings) -match '^[A-F0-9]{64}$') 'profile: proposal の正常 profile'
$count++

# 2. 実行設定検査の拒否: 役割不整合・model 不一致・必須条件名欠落・verdict 非 verified・daemonDisconnect の failed・evidence/stdlib/profileHash の不一致・未知キー・タグ指定・probe。
Assert-Throws {Test-VerificationRuntimeProfile $ctx.replayProfile 'proposal' $ctx.settings} '*does not match requested role*'
Assert-Throws {Test-VerificationRuntimeProfile $ctx.proposalProfile 'replay-before' $ctx.settings} '*does not match requested role*'
$otherModel=@{};foreach($k in $ctx.settings.Keys){$otherModel[$k]=$ctx.settings[$k]};$otherModel.model='other-model'
Assert-Throws {Test-VerificationRuntimeProfile $ctx.proposalProfile 'proposal' $otherModel} '*model does not match*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{model='unit-model'}) 'replay-before' $ctx.settings} '*must not name a model*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.Remove('replayNetworkDeny')}) 'replay-before' $ctx.settings} '*lacks required check: replayNetworkDeny*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'proposal' @{} {param($e) $e.checks.Remove('modelEndpointAllowOnly')}) 'proposal' $ctx.settings} '*lacks required check: modelEndpointAllowOnly*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.hostPathIsolation.verdict='unverified'}) 'replay-before' $ctx.settings} '*not verified: hostPathIsolation*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.daemonDisconnect.verdict='failed'}) 'replay-before' $ctx.settings} '*daemonDisconnect*'
[void](Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.daemonDisconnect.verdict='verified'}) 'replay-before' $ctx.settings)
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.transportContrast.Remove('clientKilled')}) 'replay-before' $ctx.settings} '*schema*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.limitsAndTransport.evidenceHash=('B'*64)}) 'replay-before' $ctx.settings} '*evidence hash mismatch for check limitsAndTransport*'
$tampered=New-Profile $ctx 'replay';$tampered.activationEvidenceHash=('C'*64)
Assert-Throws {Test-VerificationRuntimeProfile $tampered 'replay-before' $ctx.settings} '*activation evidence hash mismatch*'
$mismatch=New-Profile $ctx 'replay';$mismatch.sbxVersion='v0.42.2'
$mismatch.activationEvidenceHash=Get-Hash (Join-Path $ctx.prof $mismatch.activationEvidencePath)
Assert-Throws {Test-VerificationRuntimeProfile $mismatch 'replay-before' $ctx.settings} '*profileHash does not match*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{stdlibModulesHash=('D'*64)}) 'replay-before' $ctx.settings} '*stdlib modules hash mismatch*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{extra='x'}) 'replay-before' $ctx.settings} '*schema*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{templateDigest='docker.io/docker/sandbox-templates:latest'}) 'replay-before' $ctx.settings} '*schema*'
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{acceptedLimitations=@('clipboard-text-write-possible','pid-count-unbounded','pid-count-unbounded')}) 'replay-before' $ctx.settings} '*acceptedLimitations*'
Assert-Throws {Test-VerificationRuntimeProfile $ctx.replayProfile 'probe' $ctx.settings} '*unsupported role*'
$count++

# 3. effectiveSettingsHash: role を含まず before/after で一致し、limits・agent・digest が違えば変わる。
$replayHash=Get-VerificationEffectiveSettingsHash $ctx.replayProfile $ctx.settings
Assert-True ($replayHash -match '^[A-F0-9]{64}$') 'effective: 形式'
Assert-Equal (Get-VerificationEffectiveSettingsHash (New-Profile $ctx 'replay' @{sbxVersion='v0.42.9'}) $ctx.settings) $replayHash 'effective: role・sbxVersion に依存しない（before/after で一致する値）'
Assert-True ((Get-VerificationEffectiveSettingsHash $ctx.proposalProfile $ctx.settings) -cne $replayHash) 'effective: agent が違えば変わる'
$otherLimits=@{};foreach($k in $ctx.settings.Keys){$otherLimits[$k]=$ctx.settings[$k]};$otherLimits.limits=@{};foreach($k in $ctx.settings.limits.Keys){$otherLimits.limits[$k]=$ctx.settings.limits[$k]};$otherLimits.limits.replaySeconds=121
Assert-True ((Get-VerificationEffectiveSettingsHash $ctx.replayProfile $otherLimits) -cne $replayHash) 'effective: limits が違えば変わる'
$count++

function Add-Vm([hashtable]$Ctx,[string]$Role='replay-before',[object[]]$ConfirmFiles=@(),[string]$Agent='shell'){
    $name=$Ctx.names[$Role];$id=[guid]::NewGuid().ToString()
    Add-FakeSbxSandboxScenario $Ctx.case $name $id -Agent $Agent -ConfirmFiles $ConfirmFiles
    @{name=$name;id=$id}
}
function Test-ProcessAlive([int]$ProcessId){$null -ne (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)}
function Stop-LeftoverTree([int]$ProcessId){
    # 実測: MSIX 版 pwsh が ProcessHost のとき、非パッケージの子（cmd.exe 等）は VerificationJob に入らず、Execution のジョブ停止が届かない
    # （タスク3報告の逸脱候補。Execution.psm1 側の修正待ち）。試験は自分が起動した偽sbx（fake-sbx.cmd）の PID とその子孫だけを止める。名前では止めない。
    $all=@(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,CommandLine)
    $root=$all | Where-Object {$_.ProcessId -eq $ProcessId -and $_.CommandLine -like '*fake-sbx.cmd*'}
    if($null -eq $root){return}
    $queue=[Collections.Generic.Queue[int]]::new();$queue.Enqueue($ProcessId);$targets=@()
    while($queue.Count -gt 0){$current=$queue.Dequeue();$targets+=$current;foreach($child in ($all | Where-Object {$_.ParentProcessId -eq $current})){$queue.Enqueue([int]$child.ProcessId)}}
    foreach($target in $targets){Stop-Process -Id $target -Force -ErrorAction SilentlyContinue}
}
function Stop-TestSandbox([hashtable]$Item,[hashtable]$RunBudget){
    $result=Stop-VerificationSandbox $Item.handle $RunBudget
    if($null -ne $Item.handle.keepAliveHandle){Stop-LeftoverTree $Item.handle.keepAliveHandle.processId}
    $Item.stopped=$true
    $result
}
function Get-StopCalls([hashtable]$Ctx){$calls=@(Get-Calls $Ctx 'stop');$calls | ForEach-Object {$_.argv[1]}}
$handles=[Collections.Generic.List[object]]::new()
try{
# 4. pilot 排他: デーモン停止時は Lease を取らず blocked（理由に通常起動）。running なら Lease{runId,daemonKey,leaseId}。取得後にデーモンが止まれば New-VerificationSandbox は create 0回で blocked。
$ctx=New-Case
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
Assert-True ($lease.runId -ceq $ctx.runId -and $lease.daemonKey -match '^[A-F0-9]{16}$' -and $lease.leaseId -match '^[0-9a-f-]{36}$') 'lease: 形'
Assert-Equal (@($lease.Keys | Sort-Object) -join ',') 'daemonKey,leaseId,runId' 'lease: 3項目だけ（Mutex ハンドルを外へ出さない）'
$stoppedStatus=Get-FakeSbxResponse 'daemonStatusStopped'
Add-FakeSbxResponse $ctx.case @('daemon','status','--json') -Stdout $stoppedStatus.text -Synthetic $stoppedStatus.synthetic -First | Out-Null
Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.message -like '*daemon is not running*' -and $failure.message -like '*通常端末*') "daemon stopped: 理由に通常起動（$($failure.message)）"
Assert-True ($failure.creationState -ceq 'not-created' -and $failure.stopState -ceq 'not-created' -and $failure.status -ceq 'blocked' -and $null -eq $failure.handle) 'daemon stopped: not-created・blocked'
Assert-Equal @(Get-Calls $ctx 'create').Count 0 'daemon stopped: create 0回'
Assert-Equal @(Get-Calls $ctx 'ls').Count 0 'daemon stopped: 停止中デーモンへ ls を発行しない'
Release-VerificationPilotLease $lease
Assert-Throws {Release-VerificationPilotLease $lease} '*unknown pilot lease*'
$failure=Get-Failure {Acquire-VerificationPilotLease $ctx.prepared}
Assert-True ($failure.Message -like '*daemon is not running*' -and $failure.Data['status'] -eq 'blocked') 'lease: デーモン停止時は取得せず blocked'
$count++

# 5. Mutex 競合: 別スレッドが同名 Mutex を保持していれば待たずに blocked、create 0回。解放後は取得できる。
$ctx=New-Case;Write-FakeSbxScenario $ctx.case
$probe=Acquire-VerificationPilotLease $ctx.prepared;$mutexName='Local\iv-sbx-pilot-'+$probe.daemonKey;Release-VerificationPilotLease $probe
$eventName='Local\iv-sbx-test-'+[guid]::NewGuid().ToString('N')
$ready=[Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$eventName)
$holder=Start-ThreadJob -ScriptBlock {param($m,$e) $mutex=[Threading.Mutex]::new($true,$m);$signal=[Threading.EventWaitHandle]::OpenExisting($e);[void]$signal.Set();Start-Sleep -Seconds 120;$mutex.ReleaseMutex()} -ArgumentList $mutexName,$eventName
try{
    Assert-True ($ready.WaitOne(15000)) 'mutex: 保持スレッドの準備'
    $failure=Get-Failure {Acquire-VerificationPilotLease $ctx.prepared}
    Assert-True ($failure.Message -like '*held by another run*' -and $failure.Data['status'] -eq 'blocked') 'mutex: 競合は待たずに blocked'
    Assert-Equal @(Get-Calls $ctx 'create').Count 0 'mutex: create 0回'
}finally{Stop-Job $holder;Remove-Job $holder -Force;$ready.Dispose()}
$lease=Acquire-VerificationPilotLease $ctx.prepared
Assert-True ($null -ne $lease) 'mutex: 放棄後は取得できる'
Release-VerificationPilotLease $lease
$count++

# 6. 作成前の拒否（create 0回）: running のVMがある／同名がある／Lease が別 run／固定入力不一致／clipboard.imagePaste=true／MCP 登録1件。
$ctx=New-Case;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$runningLs=(Get-Content -LiteralPath $ctx.case.scenarioPath -Raw | ConvertFrom-Json -AsHashtable -Depth 10) | Where-Object {$_.argv[0] -eq 'ls'} | Select-Object -First 1
$busy=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout ('{"sandboxes":[{"name":"iv-other","id":"0badc0de-0000-0000-0000-000000000000","agent":"shell","status":"running"}]}') -First
Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'other-sandbox-active' -and $failure.creationState -ceq 'not-created' -and $failure.status -ceq 'blocked') "running あり: blocked（$($failure.message)）"
$ctx.case.entries.Remove($busy) | Out-Null
$sameName=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout ('{"sandboxes":[{"name":"'+$vm.name+'","id":"0badc0de-0000-0000-0000-000000000001","agent":"shell","status":"stopped"}]}') -First
Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'name-exists' -and $failure.creationState -ceq 'not-created') "同名あり: blocked（$($failure.message)）"
$ctx.case.entries.Remove($sameName) | Out-Null;Write-FakeSbxScenario $ctx.case
$foreign=@{runId=[guid]::NewGuid().ToString();daemonKey=$lease.daemonKey;leaseId=$lease.leaseId}
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $foreign}
Assert-True ($failure.reason -ceq 'lease-invalid' -and $failure.creationState -ceq 'not-created') 'Lease 不一致: blocked'
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile @{runId=$ctx.runId;daemonKey=$lease.daemonKey;leaseId=[guid]::NewGuid().ToString()}}
Assert-True ($failure.reason -ceq 'lease-invalid') 'Lease 未登録: blocked'
$pilotPath=$ctx.prepared.pilotInputPath;$pilotBytes=[IO.File]::ReadAllBytes($pilotPath)
[IO.File]::WriteAllText($pilotPath,([IO.File]::ReadAllText($pilotPath).Replace('pilot-fixture','pilot-other')),$utf8)
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'pilot-input' -and $failure.creationState -ceq 'not-created' -and $failure.status -ceq 'blocked') "固定入力不一致: blocked（$($failure.message)）"
[IO.File]::WriteAllBytes($pilotPath,$pilotBytes)
$clipTrue=Get-FakeSbxResponse 'settingsClipboardTrue'
$clip=Add-FakeSbxResponse $ctx.case @('settings','get','--json','clipboard\.imagePaste') -Stdout $clipTrue.text -Synthetic $clipTrue.synthetic -First;Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'daemon-settings' -and $failure.message -like '*clipboard.imagePaste*' -and $failure.creationState -ceq 'not-created') 'clipboard 画像読取 true: blocked'
$ctx.case.entries.Remove($clip) | Out-Null
$mcpOne=Get-FakeSbxResponse 'mcpLsOne'
$mcp=Add-FakeSbxResponse $ctx.case @('mcp','ls','--json') -Stdout $mcpOne.text -Synthetic $mcpOne.synthetic -First;Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'daemon-settings' -and $failure.message -like '*mcp ls*' -and $failure.creationState -ceq 'not-created') 'MCP 登録1件: blocked'
$ctx.case.entries.Remove($mcp) | Out-Null;Write-FakeSbxScenario $ctx.case
Assert-Equal @(Get-Calls $ctx 'create').Count 0 '作成前の拒否: create 0回'
Release-VerificationPilotLease $lease
$count++

# 7. create の 500（synthetic）: 作成要求後の ls で不在を確かめてから not-created。create は1回。
$ctx=New-Case;$vm=Add-Vm $ctx
$create500=Get-FakeSbxResponse 'create500' @{name=$vm.name}
Add-FakeSbxResponse $ctx.case @('create','shell','--name',[regex]::Escape($vm.name),'--cpus','2','--memory','2g','--no-share-skills','--deny-network','\*','--template','.+') -Stderr $create500.text -ExitCode 1 -Synthetic $create500.synthetic -First | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'create-failed' -and $failure.creationState -ceq 'not-created' -and $failure.stopState -ceq 'not-created' -and $failure.status -ceq 'blocked' -and $failure.message -like '*500*') "create 500: not-created（$($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 1 'create 500: create 1回'
Assert-Equal @(Get-Calls $ctx 'ls').Count 2 'create 500: 作成前と作成後の ls'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json'))) 'create 500: 作成記録なし'
Release-VerificationPilotLease $lease
$count++

# 8. id 確定後の失敗（inspect 失敗／policy 不一致／daemon.log に SSH forwarder 行）: 作成記録を残し、停止を試みて runtimeFailure.creationState=created・stopState=stopped（偽 stop が成立）→ blocked。
foreach($variant in @('inspect-failed','policy-mismatch','ssh-forwarder')){
    $ctx=New-Case;$vm=Add-Vm $ctx
    switch($variant){
        'inspect-failed'{Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stderr "Error: inspect failed`n" -ExitCode 1 -Synthetic $true -First | Out-Null}
        'policy-mismatch'{Add-FakeSbxResponse $ctx.case @('policy','ls',[regex]::Escape($vm.name),'--json') -Stdout '{"rules":[]}' -Synthetic $true -First | Out-Null}
        'ssh-forwarder'{Add-FakeDaemonLogLine $ctx.case 'sshForwarder' $vm.name}
    }
    Write-FakeSbxScenario $ctx.case
    $lease=Acquire-VerificationPilotLease $ctx.prepared
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
    Assert-True ($failure.creationState -ceq 'created' -and $failure.stage -ceq 'activation' -and $failure.handle.id -ceq $vm.id -and $failure.handle.name -ceq $vm.name) "${variant}: creationState=created と handle（$($failure.message)）"
    Assert-True ($failure.stopState -ceq 'stopped' -and $failure.status -ceq 'blocked') "${variant}: 停止できたので blocked（stopState=$($failure.stopState)）"
    Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name "${variant}: 当該名へ stop 1回"
    if($variant -ne 'inspect-failed'){Assert-True ($failure.message -like '*activation checks failed*') "${variant}: 理由"}
    if($variant -eq 'policy-mismatch'){Assert-True ($failure.message -like '*policy*') 'policy-mismatch: policy を名指す'}
    if($variant -eq 'ssh-forwarder'){Assert-True ($failure.message -like '*sshForwarding*') 'ssh-forwarder: sshForwarding を名指す'}
    $record=Get-Content -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json') -Raw | ConvertFrom-Json -AsHashtable
    Assert-True ($record.runId -ceq $ctx.runId -and $record.id -ceq $vm.id -and $null -eq $record.activationRecordPath) "${variant}: 作成記録（activation は null）"
    Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-activation.json'))) "${variant}: activationRecord は作られない"
    Assert-Equal @(Get-Calls $ctx 'exec').Count 0 "${variant}: 保持 exec は開始されない"
    Release-VerificationPilotLease $lease
}
$count++

# 9. 正常作成: handle の項目、作成記録、activationRecord（schema・全条件 verified/非該当）、保持セッションの生存、固定 argv と環境辞書（SSH_AUTH_SOCK なし）。停止で stopped、保持プロセス消失、当該名以外へ stop なし。
$ctx=New-Case -CleanupSeconds 5;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
Assert-Equal (@($handle.Keys | Sort-Object) -join ',') 'activationRecordHash,activationRecordPath,createdAt,effectiveSettingsHash,id,keepAliveHandle,name,profileHash,role,runId' 'handle: 項目'
Assert-True ($handle.runId -ceq $ctx.runId -and $handle.role -ceq 'replay-before' -and $handle.name -ceq $vm.name -and $handle.id -ceq $vm.id) 'handle: runId/role/name/id'
Assert-True ($handle.createdAt -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$') 'handle: createdAt'
Assert-Equal $handle.effectiveSettingsHash (Get-VerificationEffectiveSettingsHash $ctx.replayProfile $ctx.settings) 'handle: effectiveSettingsHash'
Assert-Equal $handle.activationRecordHash (Get-Hash $handle.activationRecordPath) 'handle: activationRecordHash は現物と一致'
$record=Get-Content -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($record.id -ceq $vm.id -and $record.activationRecordPath -ceq $handle.activationRecordPath -and $record.activationRecordHash -ceq $handle.activationRecordHash -and -not$record.ContainsKey('keepAliveHandle')) '作成記録: activation を書き足し、keepAliveHandle を含まない'
$activation=Get-Content -LiteralPath $handle.activationRecordPath -Raw | ConvertFrom-Json -AsHashtable
Assert-True (Test-Json -Json (Get-Content -LiteralPath $handle.activationRecordPath -Raw) -SchemaFile (Join-Path $PSScriptRoot '../activation-record.schema.json')) 'activationRecord: schema'
Assert-True ($activation.sandboxId -ceq $vm.id -and $activation.daemonInstance.pid -eq $PID -and $activation.profileHash -ceq $handle.profileHash) 'activationRecord: sandboxId・世代・profileHash'
foreach($key in @('policy','mount','resource','credentialExposure','sshForwarding','clipboardImagePaste','mcpServers')){Assert-Equal $activation.checks[$key].verdict 'verified' "activationRecord: $key"}
Assert-Equal $activation.checks.otherVmTraffic.verdict 'not-applicable' 'activationRecord: otherVmTraffic は非該当（同時1VM）'
Assert-True ($activation.checks.mcpServers.observed.mcpGateway -eq $true -and $activation.checks.mcpServers.observed.mcpgatewaySecret -eq $true) 'activationRecord: ゲートウェイと mcpgateway secret を記録'
Assert-True (Test-ProcessAlive $handle.keepAliveHandle.processId) '保持: 背景の sbx クライアントが生きている'
$createCall=@(Get-Calls $ctx 'create')[0]
Assert-Equal ($createCall.argv -join ' ') "create shell --name $($vm.name) --cpus 2 --memory 2g --no-share-skills --deny-network * --template $digest" '固定 argv'
foreach($call in (Get-Calls $ctx)){Assert-True ($call.envKeys -notcontains 'SSH_AUTH_SOCK') '環境辞書: SSH_AUTH_SOCK を渡さない'}
Assert-True (@(Get-Calls $ctx)[0].envKeys -contains 'PATH' -and @(Get-Calls $ctx)[0].envKeys -contains 'SystemRoot') '環境辞書: 明示した変数'
$stop=Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1)
Assert-True ($stop.stopState -ceq 'stopped' -and (Test-Path -LiteralPath $stop.evidencePath)) "停止: stopped と証拠ファイル（$($stop.reason)）"
Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name '停止: 当該名だけに stop 1回'
$stopEvidence=Get-Content -LiteralPath $stop.evidencePath -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($stopEvidence.listObserved -ceq 'stopped' -and $stopEvidence.stopLogLine -like '*stopped runtime container*' -and $stopEvidence.daemonBefore.pid -eq $PID -and $stopEvidence.daemonAfter.pid -eq $PID) '停止: 証拠の3点（ls・停止行・世代不変）'
# keepAlive.stopped は Execution のジョブ停止が cmd 系の子へ届かない実測（逸脱候補）により false になりうるため、停止を試みた記録だけを確認する。
Assert-True ($null -ne $stopEvidence.keepAlive -and $stopEvidence.keepAlive.ContainsKey('stopped')) '停止: 保持ジョブの停止を試みた記録'
$stopLine=$stopEvidence.stopLogLine | ConvertFrom-Json
Assert-True ((Get-Utc $stopLine.time) -ge (Get-Utc $stopEvidence.stopIssuedAt)) '停止: 停止行は stop 発行以後'
$again=Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $ctx.prepared 1)
Assert-True ($again.evidencePath -ceq $stop.evidencePath -and @(Get-StopCalls $ctx).Count -eq 1) '停止: 確認済みなら再発行しない'
Release-VerificationPilotLease $lease
$count++

# 10. 搬入・照合・実コマンド: cp→chown の固定 argv、搬入元と manifest の不一致で cp を発行しない、Confirm の一致・欠落・予定外、出力署名と transportVerified、署名なしは null で quarantine/ へ。
function New-Input([hashtable]$Ctx){
    $in=Join-Path $Ctx.root 'in'
    Write-Text (Join-Path $in 'a.py') "print('a')`n";Write-Text (Join-Path $in 'sub/b.py') "print('b')`n"
    $files=@(foreach($rel in @('a.py','sub/b.py')){$path=Join-Path $in $rel;@{path=$rel;size=([IO.FileInfo]::new($path)).Length;sha256=(Get-Hash $path)}})
    @{root=$in;manifest=@{schemaVersion=3;runId=$Ctx.runId;files=$files}}
}
$ctx=New-Case -CleanupSeconds 5;$trusted=New-Input $ctx;$vm=Add-Vm $ctx -ConfirmFiles $trusted.manifest.files
$unitOk=Get-FakeSbxResponse 'unittestOk';$unitFail=Get-FakeSbxResponse 'unittestFail'
$unitArgv=@('exec','-w','/home/agent/workspace/source','-e','PYTHONDONTWRITEBYTECODE=1','-e','PYTHONHASHSEED=0',[regex]::Escape($vm.name),'python3','-m','unittest','discover','-s','\.verification-tests','-p','test_\*\.py','-v')
Add-FakeSbxResponse $ctx.case $unitArgv -Stderr $unitFail.text -ExitCode 1 -Synthetic $unitFail.synthetic | Out-Null
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name),'python3','--version') -Stdout "Python 3.12.3`n" | Out-Null
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name),'sh','-c','echo only-stdout') -Stdout $unitOk.text -Synthetic $true | Out-Null
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/proposal',[regex]::Escape($vm.name),'codex','exec','--json') -Stdout "{`"untrusted`":true}`n" -Synthetic $true | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
$work=New-Budget $ctx
$dest='/home/agent/workspace/source'
Write-Text (Join-Path $trusted.root 'extra.txt') 'x'
$failure=Get-Failure {Copy-VerificationSandboxInput $handle $trusted.root $dest $trusted.manifest $work}
Assert-True ($failure.Data['reason'] -eq 'input-changed' -and $failure.Message -like '*unexpected: extra.txt*') "Copy: 搬入元が manifest と違えば blocked（$($failure.Message)）"
Assert-Equal @(Get-Calls $ctx 'cp').Count 0 'Copy: 不一致では cp を発行しない'
[IO.File]::Delete((Join-Path $trusted.root 'extra.txt'))
Assert-Throws {Copy-VerificationSandboxInput $handle $trusted.root 'relative/path' $trusted.manifest $work} '*absolute POSIX path*'
$copied=Copy-VerificationSandboxInput $handle $trusted.root $dest $trusted.manifest $work
Assert-True ($copied.copied -and $copied.fileCount -eq 2) 'Copy: 戻り'
$cpCall=@(Get-Calls $ctx 'cp')[0];Assert-Equal ($cpCall.argv -join ' ') "cp $($trusted.root) $($vm.name):$dest" 'Copy: cp の固定 argv'
$chownCall=@(Get-Calls $ctx 'exec' | Where-Object {$_.argv[1] -eq '-u'})[0];Assert-Equal ($chownCall.argv -join ' ') "exec -u root $($vm.name) chown -R agent:agent $dest" 'Copy: chown の固定 argv'
Assert-True ([DateTime]$chownCall.time -ge [DateTime]$cpCall.time) 'Copy: cp の後に chown'
$confirmed=Confirm-VerificationSandboxInput $handle $dest $trusted.manifest $work
Assert-True ($confirmed.confirmed -and $confirmed.fileCount -eq 2 -and $confirmed.commandRecord.transportVerified -eq $true -and $confirmed.commandRecord.exitCode -eq 0) 'Confirm: 一致'
$confirmCall=@(Get-Calls $ctx 'exec' | Where-Object {$_.argv -contains 'sh' -and ($_.argv -join ' ') -like '*sha256sum*'})[0]
Assert-Equal ($confirmCall.argv -join ' ') "exec -w $dest $($vm.name) sh -c cd $dest && find . -type f -print0 | sort -z | xargs -0 sha256sum" 'Confirm: 固定コマンド'
$less=@{schemaVersion=3;runId=$ctx.runId;files=@($trusted.manifest.files[0])}
$failure=Get-Failure {Confirm-VerificationSandboxInput $handle $dest $less $work}
Assert-True ($failure.Data['reason'] -eq 'input-mismatch' -and $failure.Message -like '*unexpected: sub/b.py*') "Confirm: 予定外ファイル（$($failure.Message)）"
$more=@{schemaVersion=3;runId=$ctx.runId;files=@($trusted.manifest.files)+@(@{path='c.py';size=1;sha256=('E'*64)})}
$failure=Get-Failure {Confirm-VerificationSandboxInput $handle $dest $more $work}
Assert-True ($failure.Data['reason'] -eq 'input-mismatch' -and $failure.Message -like '*missing: c.py*') "Confirm: 欠落（$($failure.Message)）"
$changed=@{schemaVersion=3;runId=$ctx.runId;files=@(@{path='a.py';size=10;sha256=('F'*64)},$trusted.manifest.files[1])}
$failure=Get-Failure {Confirm-VerificationSandboxInput $handle $dest $changed $work}
Assert-True ($failure.Data['reason'] -eq 'input-mismatch' -and $failure.Message -like '*mismatched: a.py*') 'Confirm: 内容相違'
$signature=@{pattern='Ran \d+ tests? in';stream='stderr'}
$unitBudget=New-Budget $ctx -CommandSeconds 120
$record=Invoke-VerificationSandboxCommand $handle @('python3','-m','unittest','discover','-s','.verification-tests','-p','test_*.py','-v') $null $dest @{PYTHONHASHSEED='0';PYTHONDONTWRITEBYTECODE='1'} $unitBudget $signature
Assert-True ($record.exitCode -eq 1 -and $record.transportVerified -eq $true -and -not$record.timedOut -and -not$record.outputExceeded) 'Invoke: unittest 失敗（終了1）でも stderr の署名で transportVerified=true'
Assert-Equal ($record.argv -join ' ') "exec -w $dest -e PYTHONDONTWRITEBYTECODE=1 -e PYTHONHASHSEED=0 $($vm.name) python3 -m unittest discover -s .verification-tests -p test_*.py -v" 'Invoke: -w/-e/名前/argv の固定形（環境はキー順）'
Assert-True ($record.commandId -like 'replay-before-*' -and $record.stdoutPath -like '*control\runtime\replay-before\commands\*' -and (Test-Path -LiteralPath $record.stderrPath)) 'Invoke: commandId と出力の置き場'
Assert-Equal $record.stderrHash (Get-Hash $record.stderrPath) 'Invoke: stderrHash は現物と一致'
Assert-True ($record.startedAt -match 'Z$' -and $record.finishedAt -match 'Z$' -and $record.sandboxId -ceq $vm.id -and $record.runId -ceq $ctx.runId) 'Invoke: 時刻・id'
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','echo only-stdout') $null $dest @{} $unitBudget $signature
Assert-True ($record.exitCode -eq 0 -and $record.transportVerified -eq $false) 'Invoke: 署名が stdout にだけあれば false（stderr 指定）'
$record=Invoke-VerificationSandboxCommand $handle @('python3','--version') $null $dest @{} $unitBudget $signature
Assert-True ($record.exitCode -eq 0 -and $record.transportVerified -eq $false) 'Invoke: 署名が無ければ false'
$record=Invoke-VerificationSandboxCommand $handle @('python3','--version') $null $dest @{} $unitBudget @{pattern='^Python 3\.\d+';stream='stdout'}
Assert-True ($record.transportVerified -eq $true) 'Invoke: 取得系は期待形式の署名で true'
$record=Invoke-VerificationSandboxCommand $handle @('codex','exec','--json') ([Text.Encoding]::UTF8.GetBytes('request')) '/home/agent/workspace/proposal' @{} (New-Budget $ctx -CommandSeconds 600) $null
Assert-True ($null -eq $record.transportVerified -and $record.exitCode -eq 0 -and $record.stdoutPath -like '*quarantine\commands\*') 'Invoke: 署名なし（Codex 本体）は transportVerified=null で quarantine/ へ'
Assert-Throws {Invoke-VerificationSandboxCommand $handle @('true') $null $dest @{'BAD KEY'='1'} $unitBudget $null} '*environment variable name*'
Assert-Throws {Invoke-VerificationSandboxCommand $handle @('true') $null $dest @{} $unitBudget @{pattern='x';stream='both'}} '*OutputSignature*'
Assert-Throws {Invoke-VerificationSandboxCommand @{name='iv-none';id='x';runId=$ctx.runId} @('true') $null $dest @{} $unitBudget $null} '*unknown sandbox handle*'
$count++

# 11. 実コマンド前の維持確認: inspect/policy/settings/mcp の値変化・世代変化・自動停止痕跡で実行拒否（exec を発行しない）。
$execBefore=@(Get-Calls $ctx 'exec').Count
function Assert-Refused([string]$Label,[string]$Reason,[string]$Status){
    $failure=Get-Failure {Invoke-VerificationSandboxCommand $handle @('python3','--version') $null $dest @{} $unitBudget $null}
    Assert-True ($failure.Data['reason'] -eq $Reason -and $failure.Data['status'] -eq $Status) "${Label}: 理由 $Reason / 状態 $Status（$($failure.Message) / $($failure.Data['reason'])）"
    Assert-Equal @(Get-Calls $ctx 'exec').Count $script:execBefore "${Label}: exec を発行しない"
}
$inspectStopped=Get-FakeSbxResponse 'inspect' @{name=$vm.name;agent='shell';digest=$digest;imageDigest=$digest.Substring($digest.IndexOf('@')+1)}
$override=Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stdout ($inspectStopped.text.Replace('"state": "{{state:vm:'+$vm.name+'|running}}"','"state": "stopped"')) -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'inspect state 変化' 'sandbox-restarted' 'incomplete'
$ctx.case.entries.Remove($override) | Out-Null
$override=Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stdout ($inspectStopped.text.Replace('"secrets": [','"secrets": [{"name":"OPENAI_API_KEY","source":"host"},')) -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'inspect secrets 変化' 'settings-changed' 'blocked'
$ctx.case.entries.Remove($override) | Out-Null
$override=Add-FakeSbxResponse $ctx.case @('policy','ls',[regex]::Escape($vm.name),'--json') -Stdout '{"rules":[]}' -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'policy 変化' 'settings-changed' 'blocked'
$ctx.case.entries.Remove($override) | Out-Null
$override=Add-FakeSbxResponse $ctx.case @('settings','get','--json','clipboard\.imagePaste') -Stdout (Get-FakeSbxResponse 'settingsClipboardTrue').text -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'clipboard 変化' 'settings-changed' 'blocked'
$ctx.case.entries.Remove($override) | Out-Null
$override=Add-FakeSbxResponse $ctx.case @('mcp','ls','--json') -Stdout (Get-FakeSbxResponse 'mcpLsOne').text -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'MCP 登録変化' 'settings-changed' 'blocked'
$ctx.case.entries.Remove($override) | Out-Null;Write-FakeSbxScenario $ctx.case
$otherPid=(Get-Process -Id $PID).Parent.Id
Write-Text $ctx.case.pidPath ([string]$otherPid)
Assert-Refused '世代変化（PID）' 'sandbox-restarted' 'incomplete'
Write-Text $ctx.case.pidPath ([string]$PID)
$override=Add-FakeSbxResponse $ctx.case @('daemon','status','--json') -Stdout (Get-FakeSbxResponse 'daemonStatusStopped').text -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
Assert-Refused 'デーモン停止（取得不能）' 'sandbox-restarted' 'incomplete'
$ctx.case.entries.Remove($override) | Out-Null;Write-FakeSbxScenario $ctx.case
[void](Invoke-VerificationSandboxCommand $handle @('python3','--version') $null $dest @{} $unitBudget $null);$execBefore=@(Get-Calls $ctx 'exec').Count
Add-FakeDaemonLogLine $ctx.case 'autoStopped' $vm.name
Assert-Refused '自動停止の痕跡' 'sandbox-restarted' 'incomplete'
$stop=Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1)
Assert-True ($stop.stopState -ceq 'stopped') '維持確認後の停止'
$stopIndex=[Array]::FindIndex(@(Get-Calls $ctx),[Predicate[object]]{param($c) $c.argv[0] -eq 'stop'})
$after=@(@(Get-Calls $ctx) | Select-Object -Skip ($stopIndex+1) | Where-Object {$_.argv[0] -in @('exec','cp')})
Assert-Equal $after.Count 0 '停止後: 当該名への exec/cp が0件'
Assert-Refused '停止後' 'sandbox-stopped' 'blocked'
Release-VerificationPilotLease $lease
$count++

# 12. 出力超過での停止: outputExceeded=true・exitCode null・当該 VM を停止（stop 1回、予算は現在時刻起点の1台分）。以後の exec は発行しない。
$ctx=New-Case -CleanupSeconds 5;$vm=Add-Vm $ctx
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name),'sh','-c','yes') -Stdout ('y'*(3*1024*1024)) | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
$flood=New-Budget $ctx -CommandSeconds 60;$flood.limits.maxOutputBytes=1MB
$before=[DateTime]::UtcNow
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','yes') $null '/home/agent/workspace/source' @{} $flood @{pattern='x';stream='stdout'}
Assert-True ($record.outputExceeded -and $null -eq $record.exitCode -and $record.transportVerified -eq $false -and $record.stopState -ceq 'stopped') "出力超過: 打ち切りと停止（stopState=$($record.stopState)）"
Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name '出力超過: 当該名へ stop 1回'
$stopEvidence=Get-Content -LiteralPath (Get-ChildItem -LiteralPath (Join-Path $ctx.controlRoot 'runtime') -Filter 'replay-before-stop-*.json')[0].FullName -Raw | ConvertFrom-Json -AsHashtable
$cleanupAt=Get-Utc $stopEvidence.budget.cleanupDeadlineAt
Assert-True ($cleanupAt -ge $before.AddSeconds(5) -and $cleanupAt -le [DateTime]::UtcNow.AddSeconds(5)) '出力超過: 停止予算は現在時刻起点の1台分（全体期限を含まない）'
$failure=Get-Failure {Invoke-VerificationSandboxCommand $handle @('python3','--version') $null '/home/agent/workspace/source' @{} $flood $null}
Assert-True ($failure.Data['reason'] -eq 'sandbox-stopped') '出力超過: 停止後は exec を発行しない'
[void](Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1))
Assert-Equal @(Get-StopCalls $ctx).Count 1 '出力超過: 確認済みの停止を再発行しない'
Release-VerificationPilotLease $lease
$count++

# 13. 停止未確認: ls が stopped にならなければ unverified。自動停止行だけでは stopped と判定しない。保持ジョブの停止はどちらでも行う。
foreach($variant in @('ls-still-running','auto-stop-line-only')){
    $ctx=New-Case -CleanupSeconds 8;$vm=Add-Vm $ctx   # 偽sbxの照会は約1秒/回なので、ls を数回待てる予算にする
    $stopText=(Get-FakeSbxResponse 'stop' @{name=$vm.name}).text
    if($variant -eq 'ls-still-running'){Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vm.name)) -Stdout $stopText -First | Out-Null}
    else{Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vm.name)) -Stdout $stopText -Sets @{"vm:$($vm.name)"='stopped'} -AppendFile @(@{path=$ctx.case.logPath;text=(New-FakeSbxLogLine 'autoStopped' $vm.name)}) -First | Out-Null}
    Write-FakeSbxScenario $ctx.case
    $lease=Acquire-VerificationPilotLease $ctx.prepared
    $handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $stop=Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1)
    $watch.Stop()
    Assert-True ($stop.stopState -ceq 'unverified') "${variant}: unverified（$($stop.reason)）"
    if($variant -eq 'ls-still-running'){Assert-True ($stop.reason -like "*ls status 'running'*" -and $watch.Elapsed.TotalSeconds -ge 6) "${variant}: cleanupSeconds 内で ls を待ってから諦める（$([int]$watch.Elapsed.TotalSeconds)秒: $($stop.reason)）"}
    else{Assert-True ($stop.reason -like '*no stopped-runtime-container line*') "${variant}: 自動停止行は外側停止の証拠にしない（$($stop.reason)）"}
    $evidence=Get-Content -LiteralPath $stop.evidencePath -Raw | ConvertFrom-Json -AsHashtable
    Assert-True ($null -ne $evidence.keepAlive -and $null -eq $evidence.stopLogLine) "${variant}: 保持ジョブの停止を試み、停止行なし"
    Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name "${variant}: stop は当該名へ1回"
    Release-VerificationPilotLease $lease
}
$count++

}finally{
    # 試験が作った VM の保持セッションを必ず止める（途中失敗でも）。
    foreach($item in $handles){if(-not$item.stopped){try{[void](Stop-TestSandbox $item (New-VerificationCleanupBudget $item.ctx.prepared 1))}catch{if($null -ne $item.handle.keepAliveHandle){Stop-LeftoverTree $item.handle.keepAliveHandle.processId}}}}
}
"SbxRuntimeV3: $count cases passed"
