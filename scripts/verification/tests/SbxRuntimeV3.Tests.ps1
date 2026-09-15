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
$allCases=[Collections.Generic.List[hashtable]]::new()   # 全ケースの calls.jsonl を最後に検査する（SSH_AUTH_SOCK の不在）
# 試験プロセスに SSH_AUTH_SOCK のダミー値を置く。親環境を丸ごと渡す誤実装なら偽sbxの calls.jsonl に現れる。終了時に元へ戻す。
$sshAuthSockBefore=[Environment]::GetEnvironmentVariable('SSH_AUTH_SOCK')
$sshAuthSockDummy='\\.\pipe\iv-test-dummy-ssh-agent'
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
    $script:allCases.Add($ctx)
    foreach($pair in @(@('proposal','proposal'),@('replay-before','before'),@('replay-after','after'))){$ctx.names[$pair[0]]='iv-'+$runId.Substring(0,8)+'-'+$pair[1]}
    $ctx.replayProfile=New-Profile $ctx 'replay';$ctx.proposalProfile=New-Profile $ctx 'proposal'
    $ctx
}
function New-Budget([hashtable]$Ctx,[string]$Phase='work',[int]$CommandSeconds=120,$CleanupIn=$null){
    @{deadlineAt=$Ctx.prepared.deadlineAt;cleanupDeadlineAt=$(if($null -eq $CleanupIn){$null}else{[DateTime]::UtcNow.AddSeconds([double]$CleanupIn).ToString('o')});limits=@{maxOutputBytes=$Ctx.settings.limits.maxOutputBytes;commandSeconds=$CommandSeconds};phase=$Phase}
}
function Get-Failure([scriptblock]$Action){try{& $Action | Out-Null}catch{return $_.Exception};throw "ASSERT: expected an exception (called from line $($MyInvocation.ScriptLineNumber))"}
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
# daemonDisconnect は unverified だけを受ける（ADR-0196。verified と書ける観測が表に無い。偽 fixture の証拠に verified を付けても通さない）。
Assert-Throws {Test-VerificationRuntimeProfile (New-Profile $ctx 'replay' @{} {param($e) $e.checks.daemonDisconnect.verdict='verified'}) 'replay-before' $ctx.settings} '*daemonDisconnect must be unverified*'
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
# 偽sbxの後片付け（Get-CaseFakeProcesses・Stop-CaseFakeProcesses）は fixtures/FakeSbxScenario.psm1 に置く（Proposal/Replay/CLI の v3 試験と共用）。
function Stop-TestSandbox([hashtable]$Item,[hashtable]$RunBudget){
    $result=Stop-VerificationSandbox $Item.handle $RunBudget
    $Item.stopped=$true
    $result
}
function Get-StopCalls([hashtable]$Ctx){$calls=@(Get-Calls $Ctx 'stop');$calls | ForEach-Object {$_.argv[1]}}
$handles=[Collections.Generic.List[object]]::new()
[Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK',$sshAuthSockDummy)
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
# 既存の名前付き Mutex を開く場合 initiallyOwned は効かないため、WaitOne で所有権を取ってから合図する（放棄状態でも取得できる）。
$holder=Start-ThreadJob -ScriptBlock {param($m,$e) $mutex=[Threading.Mutex]::new($false,$m);try{[void]$mutex.WaitOne(5000)}catch [Threading.AbandonedMutexException]{};$signal=[Threading.EventWaitHandle]::OpenExisting($e);[void]$signal.Set();Start-Sleep -Seconds 120;$mutex.ReleaseMutex()} -ArgumentList $mutexName,$eventName
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
$busy=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout ('{"sandboxes":[{"name":"iv-other","id":"0badc0de-0000-0000-0000-000000000000","agent":"shell","status":"running"}]}') -Synthetic $true -First
Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'other-sandbox-active' -and $failure.creationState -ceq 'not-created' -and $failure.status -ceq 'blocked') "running あり: blocked（$($failure.message)）"
$ctx.case.entries.Remove($busy) | Out-Null
# 未観測の status 値（running/stopped 以外）の VM があれば作らず blocked（ブリーフ「status が stopped 以外のVM（running、または未観測の値）」）。
$unobserved=Get-FakeSbxResponse 'lsUnobservedStatus' @{name='iv-other';id='0badc0de-0000-0000-0000-000000000002';status='paused'}
$busy=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout $unobserved.text -Synthetic $unobserved.synthetic -Source $unobserved.source -First
Write-FakeSbxScenario $ctx.case
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'other-sandbox-active' -and $failure.message -like '*(paused)*' -and $failure.creationState -ceq 'not-created' -and $failure.status -ceq 'blocked') "未観測の status: blocked（$($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 0 '未観測の status: create 0回'
$ctx.case.entries.Remove($busy) | Out-Null
$sameName=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout ('{"sandboxes":[{"name":"'+$vm.name+'","id":"0badc0de-0000-0000-0000-000000000001","agent":"shell","status":"stopped"}]}') -Synthetic $true -First
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
$override500=Add-FakeSbxResponse $ctx.case @('create','shell','--name',[regex]::Escape($vm.name),'--cpus','2','--memory','2g','--no-share-skills','--deny-network','\*','--template','.+') -Stderr $create500.text -ExitCode 1 -Synthetic $create500.synthetic -Source $create500.source -First
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.reason -ceq 'create-failed' -and $failure.creationState -ceq 'not-created' -and $failure.stopState -ceq 'not-created' -and $failure.status -ceq 'blocked' -and $failure.message -like '*500*') "create 500: not-created（$($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 1 'create 500: create 1回'
Assert-Equal @(Get-Calls $ctx 'ls').Count 2 'create 500: 作成前と作成後の ls'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json'))) 'create 500: 作成記録なし'
# 7b. create 発行後の例外（出力の読取り失敗などを模す）: 作成要求を送った後なので unknown・unverified のまま返し、未作成へ推定しない（呼出し側は incomplete）。
#     例外は試験だけがモジュール内の Invoke-VerificationSbx を包んで create の戻り直後に投げる（定数の差し替えと同じく script スコープで行い、元へ戻す）。
$ctx.case.entries.Remove($override500) | Out-Null;Write-FakeSbxScenario $ctx.case
& $module {
    $script:InvokeSbxOriginal=${function:Invoke-VerificationSbx}
    Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value {
        param([hashtable]$Client,[string[]]$Argv,[hashtable]$Budget,[string]$Tag,[byte[]]$StdinBytes=$null,[bool]$ReadText=$true)
        $call=& $script:InvokeSbxOriginal $Client $Argv $Budget $Tag $StdinBytes $ReadText
        if($Tag -ceq 'create'){throw [IO.IOException]::new('injected: create output unreadable')}
        $call
    }
}
try{
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
}finally{& $module {Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value $script:InvokeSbxOriginal}}
Assert-True ($failure.stage -ceq 'create' -and $failure.creationState -ceq 'unknown' -and $failure.stopState -ceq 'unverified' -and $failure.status -ceq 'incomplete' -and $null -eq $failure.handle -and $failure.message -like '*injected*') "create 後の例外: unknown・unverified・incomplete（$($failure.creationState)/$($failure.stopState)/$($failure.status): $($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 2 'create 後の例外: 作成要求は発行済み'
Release-VerificationPilotLease $lease
$count++

# 8. id 確定後の失敗（inspect 失敗／policy 不一致／daemon.log に SSH forwarder 行）: 作成記録を残し、停止を試みて runtimeFailure.creationState=created・stopState=stopped（偽 stop が成立）→ blocked。
function Test-ActivationFailureVariant([string]$Variant){
    $ctx=New-Case;$vm=Add-Vm $ctx
    $createEntry=@($ctx.case.entries | Where-Object {$_.argv[0] -eq 'create'})[0]
    switch($Variant){
        'inspect-failed'{Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stderr "Error: inspect failed`n" -ExitCode 1 -Synthetic $true -First | Out-Null}
        'policy-mismatch'{Add-FakeSbxResponse $ctx.case @('policy','ls',[regex]::Escape($vm.name),'--json') -Stdout '{"rules":[]}' -Synthetic $true -First | Out-Null}
        'ssh-forwarder'{Add-FakeDaemonLogLine $ctx.case 'sshForwarder' $vm.name}
        # runtimes/<name>.json の判定キーの欠落・型違い（sbx の版でフィールド名が変わった場合を模す。創作）。
        'runtime-lacks-workspace'{$createEntry.writeFile[0].text=$createEntry.writeFile[0].text.Replace('"WorkspaceDir":"",','');$createEntry.synthetic=$true}
        'runtime-lacks-ssh-socket'{$createEntry.writeFile[0].text=$createEntry.writeFile[0].text.Replace('"SSHAgentSocketPath":"",','');$createEntry.synthetic=$true}
        'runtime-cpus-string'{$createEntry.writeFile[0].text=$createEntry.writeFile[0].text.Replace('"CPUs":2,','"CPUs":"2",');$createEntry.synthetic=$true}
        # 作成時の値の不一致（V2）。runtimes/<name>.json は New-FakeRuntimeFileText -Overrides で、image digest と secrets は inspect の応答で作る（いずれも創作）。
        'runtime-workspace-set'{$createEntry.writeFile[0].text=New-FakeRuntimeFileText $vm.name $vm.id -Overrides @{workspaceDir='/host/workspace'};$createEntry.synthetic=$true}
        'runtime-ssh-socket-set'{$createEntry.writeFile[0].text=New-FakeRuntimeFileText $vm.name $vm.id -Overrides @{sshAgentSocketPath='/run/host-services/ssh-auth.sock'};$createEntry.synthetic=$true}
        'runtime-cpus-4'{$createEntry.writeFile[0].text=New-FakeRuntimeFileText $vm.name $vm.id -Overrides @{cpus='4'};$createEntry.synthetic=$true}
        'inspect-digest-mismatch'{
            # Add-FakeSbxSandboxScenario -Digest は create の --template の照合にも使われ、profile と別の digest では create 自体が一致しないので、inspect の image_digest だけを変える。
            $other='docker.io/docker/sandbox-templates@sha256:'+('1'*64)
            $inspect=Get-FakeSbxResponse 'inspect' @{name=$vm.name;agent='shell';digest=$other;imageDigest=$other.Substring($other.IndexOf('@')+1)}
            Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stdout $inspect.text -Synthetic $true -First | Out-Null
        }
        'inspect-extra-secret'{
            $inspect=Get-FakeSbxResponse 'inspect' @{name=$vm.name;agent='shell';digest=$digest;imageDigest=$digest.Substring($digest.IndexOf('@')+1)}
            Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stdout ($inspect.text.Replace('"secrets": [','"secrets": [{"name":"OPENAI_API_KEY","source":"host"},')) -Synthetic $true -First | Out-Null
        }
    }
    Write-FakeSbxScenario $ctx.case
    $lease=Acquire-VerificationPilotLease $ctx.prepared
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
    Assert-True ($failure.creationState -ceq 'created' -and $failure.stage -ceq 'activation' -and $failure.handle.id -ceq $vm.id -and $failure.handle.name -ceq $vm.name) "${Variant}: creationState=created と handle（$($failure.message)）"
    Assert-True ($failure.stopState -ceq 'stopped' -and $failure.status -ceq 'blocked') "${Variant}: 停止できたので blocked（stopState=$($failure.stopState)）"
    Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name "${Variant}: 当該名へ stop 1回"
    if($Variant -in @('policy-mismatch','ssh-forwarder')){Assert-True ($failure.message -like '*activation checks failed*') "${Variant}: 理由"}
    if($Variant -eq 'policy-mismatch'){Assert-True ($failure.message -like '*policy*') 'policy-mismatch: policy を名指す'}
    if($Variant -eq 'ssh-forwarder'){Assert-True ($failure.message -like '*sshForwarding*') 'ssh-forwarder: sshForwarding を名指す'}
    $expectedCheck=@{'runtime-workspace-set'='mount';'runtime-ssh-socket-set'='sshForwarding';'runtime-cpus-4'='resource';'inspect-digest-mismatch'='mount';'inspect-extra-secret'='credentialExposure'}[$Variant]
    if($null -ne $expectedCheck){Assert-True ($failure.reason -ceq 'activation-mismatch' -and $failure.message -like "*activation checks failed*$expectedCheck*") "${Variant}: 値の不一致を $expectedCheck で名指す（$($failure.message)）"}
    $expectedKey=@{'runtime-lacks-workspace'='WorkspaceDir';'runtime-lacks-ssh-socket'='SSHAgentSocketPath';'runtime-cpus-string'='CPUs'}[$Variant]
    if($null -ne $expectedKey){Assert-True ($failure.reason -ceq 'activation-mismatch' -and $failure.message -like "*Spec.$expectedKey is missing or not a*") "${Variant}: 取得できないキーを名指す（$($failure.message)）"}
    $record=Get-Content -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json') -Raw | ConvertFrom-Json -AsHashtable
    Assert-True ($record.runId -ceq $ctx.runId -and $record.id -ceq $vm.id -and $null -eq $record.activationRecordPath) "${Variant}: 作成記録（activation は null）"
    Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-activation.json'))) "${Variant}: activationRecord は作られない"
    Assert-Equal @(Get-Calls $ctx 'exec').Count 0 "${Variant}: 保持 exec は開始されない"
    Release-VerificationPilotLease $lease
}
foreach($variant in @('inspect-failed','policy-mismatch','ssh-forwarder')){Test-ActivationFailureVariant $variant}
$count++

# 9. 正常作成: handle の項目、作成記録、activationRecord（schema・全条件 verified/非該当）、保持セッションの生存、固定 argv と環境辞書（SSH_AUTH_SOCK なし）。停止で stopped、保持プロセス消失、当該名以外へ stop なし。
$ctx=New-Case;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case   # 停止猶予は既定30秒（5秒では負荷で停止後の世代照会が期限を越えることがある。ProposalV3 の d7a14a2 と同じ）
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
$keepAliveTarget=$handle.keepAliveHandle.processId
$stop=Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1)
Assert-True ($stop.stopState -ceq 'stopped' -and (Test-Path -LiteralPath $stop.evidencePath)) "停止: stopped と証拠ファイル（$($stop.reason)）"
Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name '停止: 当該名だけに stop 1回'
$stopEvidence=Get-Content -LiteralPath $stop.evidencePath -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($stopEvidence.listObserved -ceq 'stopped' -and $stopEvidence.stopLogLine -like '*stopped runtime container*' -and $stopEvidence.daemonBefore.pid -eq $PID -and $stopEvidence.daemonAfter.pid -eq $PID) '停止: 証拠の3点（ls・停止行・世代不変）'
# 保持ジョブの停止: Issue-0147 の修正でジョブへ明示割当された対象（sbx クライアント＝ここでは fake-sbx.cmd の cmd.exe）が止まることを確かめる。
# keepAlive.stopped=true は確認しない。実測（修正ラウンド1）で、cmd.exe が起動する MSIX 版 pwsh（偽sbxの本体）はジョブを継承せず出力パイプを握り続けるため、
# 偽sbxでは processTreeStopped が false になる（実機の sbx.exe はこの二段構成ではない）。残った偽sbxは当該ケースの PID だけを止め、残存0を確かめる。
Assert-True ($null -ne $stopEvidence.keepAlive -and $stopEvidence.keepAlive.stopped -is [bool] -and -not$stopEvidence.keepAlive.ContainsKey('error')) "停止: 保持ジョブの停止を実行した（$(ConvertTo-VerificationCanonicalJson $stopEvidence.keepAlive)）"
Assert-True (-not(Test-ProcessAlive $keepAliveTarget)) '停止: 保持セッションの対象（ジョブ内の sbx クライアント）が止まった'
Stop-CaseFakeProcesses @($ctx)
Assert-Equal @(Get-CaseFakeProcesses @($ctx)).Count 0 '停止: 当該ケースの偽sbxプロセスが残っていない'
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
$ctx=New-Case;$trusted=New-Input $ctx;$vm=Add-Vm $ctx -ConfirmFiles $trusted.manifest.files
$unitOk=Get-FakeSbxResponse 'unittestOk';$unitFail=Get-FakeSbxResponse 'unittestFail'
$unitArgv=@('exec','-w','/home/agent/workspace/source','-e','PYTHONDONTWRITEBYTECODE=1','-e','PYTHONHASHSEED=0',[regex]::Escape($vm.name),'python3','-m','unittest','discover','-s','\.verification-tests','-p','test_\*\.py','-v')
Add-FakeSbxResponse $ctx.case $unitArgv -Stderr $unitFail.text -ExitCode 1 -Synthetic $unitFail.synthetic | Out-Null
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name),'python3','--version') -Stdout "Python 3.12.3`n" -Synthetic $true -Source '版の出力は 8a で実測する（値は創作）' | Out-Null
# transport 対照の応答（終了7・127・137、クライアント強制終了、proposal-export.py の JSON 1行）。exitCode は index.json の値。
$transportResponses=[ordered]@{exec7=@('sh','-c','exit 7');exec127=@('sh','-c','no-such-command');exec137=@('sh','-c','bounded-load');execClientKilled=@('sh','-c','client-killed');proposalExportJson=@('python3','/home/agent/proposal-export.py')}
foreach($key in $transportResponses.Keys){
    $response=Get-FakeSbxResponse $key
    $patterns=@('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name))+@($transportResponses[$key] | ForEach-Object {[regex]::Escape($_)})
    if($key -eq 'proposalExportJson'){Add-FakeSbxResponse $ctx.case $patterns -Stdout $response.text -ExitCode $response.exitCode -Synthetic $response.synthetic -Source $response.source | Out-Null}
    else{Add-FakeSbxResponse $ctx.case $patterns -Stderr $response.text -ExitCode $response.exitCode -Synthetic $response.synthetic -Source $response.source | Out-Null}
}
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
# transport 対照: exitCode はそのまま記録し、打ち切りが無く署名が指定ストリームにあれば transportVerified=true。出力の無い終了（137・クライアント強制終了）は署名が現れず false。
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','exit 7') $null $dest @{} $unitBudget @{pattern='command failed with status 7';stream='stderr'}
Assert-True ($record.exitCode -eq 7 -and $record.transportVerified -eq $true) "transport: 終了7を記録し stderr の署名で true（exit=$($record.exitCode), tv=$($record.transportVerified)）"
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','no-such-command') $null $dest @{} $unitBudget @{pattern='not found$';stream='stderr'}
Assert-True ($record.exitCode -eq 127 -and $record.transportVerified -eq $true) "transport: 終了127を記録し stderr の署名で true（exit=$($record.exitCode), tv=$($record.transportVerified)）"
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','bounded-load') $null $dest @{} $unitBudget @{pattern='\S';stream='stdout'}
Assert-True ($record.exitCode -eq 137 -and $record.transportVerified -eq $false -and -not$record.timedOut) "transport: 終了137（出力なし）を記録し、署名が現れないので false（exit=$($record.exitCode), tv=$($record.transportVerified)）"
$record=Invoke-VerificationSandboxCommand $handle @('sh','-c','client-killed') $null $dest @{} $unitBudget @{pattern='\S';stream='stderr'}
Assert-True ($record.exitCode -eq -1 -and $record.transportVerified -eq $false) "transport: クライアント強制終了（synthetic）の終了コードを記録し false（exit=$($record.exitCode), tv=$($record.transportVerified)）"
$record=Invoke-VerificationSandboxCommand $handle @('python3','/home/agent/proposal-export.py') $null $dest @{} $unitBudget @{pattern='^\{.*\}\r?$';stream='stdout'}
Assert-True ($record.exitCode -eq 0 -and $record.transportVerified -eq $true -and ([IO.File]::ReadAllText($record.stdoutPath) | ConvertFrom-Json).schemaVersion -eq 3) "transport: proposal-export.py の JSON 1行（synthetic）が stdout にあり true（tv=$($record.transportVerified)）"
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
$override=Add-FakeSbxResponse $ctx.case @('inspect',[regex]::Escape($vm.name),'--json') -Stdout ($inspectStopped.text.Replace('"state": "{{state:vm:'+$vm.name+'|running}}"','"state": "stopped"')) -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
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
$ctx=New-Case;$vm=Add-Vm $ctx   # 停止猶予は既定30秒（5秒ではランナーで1回、停止後の世代照会が期限を越えて停止未確認になった）
Add-FakeSbxResponse $ctx.case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($vm.name),'sh','-c','yes') -Stdout ('y'*(3*1024*1024)) -Synthetic $true -Source '出力洪水の応答は 8a で実測する（内容は創作）' | Out-Null
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
Assert-True ($cleanupAt -ge $before.AddSeconds(30) -and $cleanupAt -le [DateTime]::UtcNow.AddSeconds(30)) '出力超過: 停止予算は現在時刻起点の1台分（全体期限を含まない）'
$failure=Get-Failure {Invoke-VerificationSandboxCommand $handle @('python3','--version') $null '/home/agent/workspace/source' @{} $flood $null}
Assert-True ($failure.Data['reason'] -eq 'sandbox-stopped') '出力超過: 停止後は exec を発行しない'
[void](Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1))
Assert-Equal @(Get-StopCalls $ctx).Count 1 '出力超過: 確認済みの停止を再発行しない'
Release-VerificationPilotLease $lease
$count++

# 13. 停止未確認: ls が stopped にならなければ unverified。自動停止行だけでは stopped と判定しない。保持ジョブの停止はどちらでも行う。
foreach($variant in @('ls-still-running','auto-stop-line-only')){
    $ctx=New-Case -CleanupSeconds 20;$vm=Add-Vm $ctx   # 偽sbxの照会は約1秒/回で負荷により伸びるので、停止前後の世代照会と ls の待機を含めて余裕のある予算にする（8秒では揺れた）
    $stopText=(Get-FakeSbxResponse 'stop' @{name=$vm.name}).text
    # stop の本文は 41-stop.txt 由来だが、「一覧が stopped にならない」「停止行の代わりに自動停止行が出る」という状態遷移は未観測の創作。
    if($variant -eq 'ls-still-running'){Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vm.name)) -Stdout $stopText -Synthetic $true -First | Out-Null}
    else{Add-FakeSbxResponse $ctx.case @('stop',[regex]::Escape($vm.name)) -Stdout $stopText -Sets @{"vm:$($vm.name)"='stopped'} -AppendFile @(@{path=$ctx.case.logPath;text=(New-FakeSbxLogLine 'autoStopped' $vm.name)}) -Synthetic $true -First | Out-Null}
    Write-FakeSbxScenario $ctx.case
    $lease=Acquire-VerificationPilotLease $ctx.prepared
    $handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $stop=Stop-TestSandbox $item (New-VerificationCleanupBudget $ctx.prepared 1)
    $watch.Stop()
    Assert-True ($stop.stopState -ceq 'unverified') "${variant}: unverified（$($stop.reason)）"
    $evidence=Get-Content -LiteralPath $stop.evidencePath -Raw | ConvertFrom-Json -AsHashtable
    # 理由の文言は負荷による照会失敗の混入で変わりうるので、判定の根拠（stopped の一覧を観測していない・停止行を採用していない）を証拠の観測値で確かめる。
    if($variant -eq 'ls-still-running'){Assert-True ($evidence.listObserved -cne 'stopped' -and $watch.Elapsed.TotalSeconds -ge 18) "${variant}: stopped の一覧を観測しないまま cleanupSeconds（20秒）を待ってから諦める（$([int]$watch.Elapsed.TotalSeconds)秒: listObserved=$($evidence.listObserved)）"}
    else{Assert-True ($null -eq $evidence.stopLogLine) "${variant}: 自動停止行を外側停止の証拠（停止行）に採用しない（$($stop.reason)）"}
    Assert-True ($null -ne $evidence.keepAlive -and $evidence.keepAlive.stopped -is [bool] -and $null -eq $evidence.stopLogLine) "${variant}: 保持ジョブの停止を実行し、停止行なし"
    Assert-True (-not(Test-ProcessAlive $handle.keepAliveHandle.processId)) "${variant}: 未確認でも保持セッションの対象は止まった"
    Stop-CaseFakeProcesses @($ctx)
    Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name "${variant}: stop は当該名へ1回"
    Release-VerificationPilotLease $lease
}
$count++

# 14. 停止予算: cleanupDeadlineAt = now + cleanupSeconds × 台数（0台なら1台分）。全体期限までの残時間を含まない。
$ctx=New-Case -CleanupSeconds 30 -DeadlineIn 3600
$before=[DateTime]::UtcNow
$budget=New-VerificationCleanupBudget $ctx.prepared 3
$cleanupAt=Get-Utc $budget.cleanupDeadlineAt
Assert-True ($cleanupAt -ge $before.AddSeconds(90) -and $cleanupAt -le [DateTime]::UtcNow.AddSeconds(90)) '予算: 3台分'
Assert-True ($cleanupAt -lt (Get-Utc $ctx.prepared.deadlineAt)) '予算: 全体期限（1時間先）を繰り入れない'
Assert-True ($budget.phase -ceq 'cleanup' -and $budget.deadlineAt -ceq $ctx.prepared.deadlineAt -and $budget.limits.commandSeconds -eq 60 -and $budget.limits.maxOutputBytes -eq 16MB) '予算: phase/limits'
$zero=Get-Utc (New-VerificationCleanupBudget $ctx.prepared 0).cleanupDeadlineAt
Assert-True ($zero -ge $before.AddSeconds(30) -and $zero -le [DateTime]::UtcNow.AddSeconds(30)) '予算: 0台なら1台分'
$count++

# 15. 定数の時間上限: 照会（QuerySeconds）・作成（SetupSeconds）を超える遅延で timedOut・runtimeFailure。定数は script スコープで試験だけが差し替える。
$ctx=New-Case;$vm=Add-Vm $ctx
$slowLs=Add-FakeSbxResponse $ctx.case @('ls','--json') -Stdout '{"sandboxes":[]}' -DelaySeconds 15 -Synthetic $true -First;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
& $module {$script:QuerySeconds=6}   # 上限は ls 以外の照会（daemon status・settings・mcp）にもかかるので、偽sbxの1呼び出し（約1秒、負荷で伸びる）より十分長く、遅延15秒より短い値
try{
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
    $watch.Stop()
    Assert-True ($failure.reason -ceq 'query-timed-out' -and $failure.creationState -ceq 'not-created' -and $failure.message -like '*sbx ls timed out*') "照会上限: ls の時間超過（$($failure.message)）"
    Assert-True ($watch.Elapsed.TotalSeconds -lt 25) "照会上限: 遅延15秒の ls を定数6秒で打ち切り、遅延を待たない（$([int]$watch.Elapsed.TotalSeconds)秒）"
    Assert-Equal @(Get-Calls $ctx 'create').Count 0 '照会上限: create 0回'
}finally{& $module {$script:QuerySeconds=60}}
$ctx.case.entries.Remove($slowLs) | Out-Null
Add-FakeSbxResponse $ctx.case @('create','shell','--name',[regex]::Escape($vm.name),'--cpus','2','--memory','2g','--no-share-skills','--deny-network','\*','--template','.+') -DelaySeconds 8 -Synthetic $true -First | Out-Null
Write-FakeSbxScenario $ctx.case
& $module {$script:SetupSeconds=4}
try{
    # 時間超過した create は、直後の ls に名前が無くても not-created と確定しない（外側が止めたのはクライアントだけで、デーモン側の作成は後から完成しうる）。
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
    Assert-True ($failure.reason -ceq 'create-timed-out' -and $failure.creationState -ceq 'unknown' -and $failure.stopState -ceq 'unverified' -and $failure.status -ceq 'incomplete' -and $null -eq $failure.handle -and $failure.message -like '*timed out (limit 4s)*') "作成上限: 一覧に無くても unknown・unverified・incomplete（$($failure.creationState)/$($failure.stopState)/$($failure.status): $($failure.message)）"
    Assert-Equal @(Get-Calls $ctx 'create').Count 1 '作成上限: create 1回'
    Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json'))) '作成上限: 名前が一覧に無いので作成記録は無い'
}finally{& $module {$script:SetupSeconds=240}}
Assert-True ((& $module {$script:QuerySeconds}) -eq 60 -and (& $module {$script:SetupSeconds}) -eq 240) '定数を元に戻した'
Release-VerificationPilotLease $lease
Stop-CaseFakeProcesses @($ctx)   # 固定待ちの代わりに、ジョブ外に残った遅延中の偽sbx（上の実測）を PID で止める
Assert-Equal @(Get-CaseFakeProcesses @($ctx)).Count 0 '作成上限: 遅延中の偽sbxが残っていない'
# 15b. 時間超過した create の後に一覧へ名前が現れた場合（デーモン側で作成済み）: id を確定して作成記録を書き、停止を試みる（creationState=created）。
$ctx=New-Case;$vm=@{name=$ctx.names['replay-before'];id=[guid]::NewGuid().ToString()}
Add-FakeSbxSandboxScenario $ctx.case $vm.name $vm.id -CreateDelaySeconds 8
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
& $module {$script:SetupSeconds=4}
try{
    $failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}
}finally{& $module {$script:SetupSeconds=240}}
Assert-True ($failure.reason -ceq 'create-timed-out' -and $failure.creationState -ceq 'created' -and $failure.handle.id -ceq $vm.id -and $failure.stopState -ceq 'stopped' -and $failure.status -ceq 'blocked') "作成上限(一覧に出現): created・停止試行（$($failure.creationState)/$($failure.stopState)/$($failure.status): $($failure.message)）"
$record=Get-Content -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($record.id -ceq $vm.id -and $record.name -ceq $vm.name -and $record.runId -ceq $ctx.runId) '作成上限(一覧に出現): 作成記録に id を確定'
Assert-Equal (@(Get-StopCalls $ctx) -join ',') $vm.name '作成上限(一覧に出現): 当該名へ stop 1回'
Assert-Equal @(Get-Calls $ctx 'create').Count 1 '作成上限(一覧に出現): create 1回'
Release-VerificationPilotLease $lease
Stop-CaseFakeProcesses @($ctx)
Assert-Equal @(Get-CaseFakeProcesses @($ctx)).Count 0 '作成上限(一覧に出現): 遅延中の偽sbxが残っていない'
$count++

# 16. 復旧操作（ADR-0194）: デーモン停止時は ls を発行せず全対象 unverified、Lease 競合では何もしない、記録0件は targetCount=0、
#     記録済み2台だけを台数分の新しい予算で停止し記録外の running VM に触れない。結果は recovery-result の schema に適合し recovery-<時刻>.json に残る。
function New-RecoveryInput([hashtable]$Ctx,[int]$CleanupSeconds){@{schemaVersion=3;sbxPath=$Ctx.settings.sbxPath;pwshPath=$Ctx.settings.pwshPath;runsRoot=$Ctx.settings.runsRoot;limits=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=$CleanupSeconds;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1MB;maxProposalBytes=8MB;maxWireBytes=16MB;maxOutputBytes=16MB}}}
function Get-RecoveryFiles([hashtable]$Ctx){@(Get-ChildItem -LiteralPath (Join-Path $Ctx.controlRoot 'runtime') -Filter 'recovery-*.json')}
$schemaPath=Join-Path $PSScriptRoot '../recovery-result.schema.json'
$ctx=New-Case
$recorded=@(@{role='probe';suffix='probe'},@{role='replay-before';suffix='before'})
foreach($r in $recorded){
    $r.name='iv-'+$ctx.runId.Substring(0,8)+'-'+$r.suffix;$r.id=[guid]::NewGuid().ToString()
    Add-FakeSbxSandboxScenario $ctx.case $r.name $r.id -AlreadyPresent -InitialStatus running
    [void](Write-VerificationSandboxRecord $ctx.runRoot @{runId=$ctx.runId;role=$r.role;name=$r.name;id=$r.id;createdAt=(Get-VerificationUtcNow);profileHash=$null;effectiveSettingsHash=$null;activationRecordPath=$null;activationRecordHash=$null})
}
$unrecorded=@{name='iv-'+$ctx.runId.Substring(0,8)+'-after';id=[guid]::NewGuid().ToString()}
Add-FakeSbxSandboxScenario $ctx.case $unrecorded.name $unrecorded.id -AlreadyPresent -InitialStatus running
$stoppedDaemon=Add-FakeSbxResponse $ctx.case @('daemon','status','--json') -Stdout (Get-FakeSbxResponse 'daemonStatusStopped').text -Synthetic $true -First
Write-FakeSbxScenario $ctx.case
Assert-Throws {Stop-VerificationRecordedSandboxes $ctx.runRoot @{schemaVersion=3;sbxPath=$ctx.settings.sbxPath}} '*schema*'
$result=Stop-VerificationRecordedSandboxes $ctx.runRoot (New-RecoveryInput $ctx 6)
Assert-True (-not$result.daemonRunning -and $result.targetCount -eq 2 -and $result.runId -ceq $ctx.runId -and $null -eq $result.lease) '復旧(停止中): 列挙だけ'
Assert-True (@($result.targets | Where-Object {$_.stopState -ceq 'unverified' -and $_.stateBefore -ceq 'unknown' -and $null -eq $_.evidencePath}).Count -eq 2) '復旧(停止中): 全対象 unverified'
Assert-Equal @(Get-Calls $ctx 'ls').Count 0 '復旧(停止中): 停止中デーモンへ ls を発行しない'
Assert-Equal @(Get-Calls $ctx 'stop').Count 0 '復旧(停止中): stop 0回'
Assert-True (Test-Json -Json (Get-Content -LiteralPath (Get-RecoveryFiles $ctx)[0].FullName -Raw) -SchemaFile $schemaPath) '復旧(停止中): 結果ファイルが schema に適合'
$ctx.case.entries.Remove($stoppedDaemon) | Out-Null;Write-FakeSbxScenario $ctx.case
$probe=Acquire-VerificationPilotLease $ctx.prepared;$mutexName='Local\iv-sbx-pilot-'+$probe.daemonKey;Release-VerificationPilotLease $probe
$eventName='Local\iv-sbx-test-'+[guid]::NewGuid().ToString('N')
$ready=[Threading.EventWaitHandle]::new($false,[Threading.EventResetMode]::ManualReset,$eventName)
# 既存の名前付き Mutex を開く場合 initiallyOwned は効かないため、WaitOne で所有権を取ってから合図する（放棄状態でも取得できる）。
$holder=Start-ThreadJob -ScriptBlock {param($m,$e) $mutex=[Threading.Mutex]::new($false,$m);try{[void]$mutex.WaitOne(5000)}catch [Threading.AbandonedMutexException]{};$signal=[Threading.EventWaitHandle]::OpenExisting($e);[void]$signal.Set();Start-Sleep -Seconds 120;$mutex.ReleaseMutex()} -ArgumentList $mutexName,$eventName
try{
    Assert-True ($ready.WaitOne(15000)) '復旧(競合): 保持スレッドの準備'
    $failure=Get-Failure {Stop-VerificationRecordedSandboxes $ctx.runRoot (New-RecoveryInput $ctx 6)}
    Assert-True ($failure.Message -like '*held by another run*' -and $failure.Data['status'] -eq 'blocked') '復旧(競合): 稼働中の run があるとして blocked'
    Assert-Equal @(Get-Calls $ctx 'stop').Count 0 '復旧(競合): 何もしない'
    Assert-Equal @(Get-Calls $ctx 'ls').Count 0 '復旧(競合): ls も発行しない'
}finally{Stop-Job $holder;Remove-Job $holder -Force;$ready.Dispose()}
$checkedBefore=[DateTime]::UtcNow
$result=Stop-VerificationRecordedSandboxes $ctx.runRoot (New-RecoveryInput $ctx 30)   # 停止を確認するので猶予は既定の30秒
Assert-True ($result.daemonRunning -and $result.targetCount -eq 2 -and $null -ne $result.lease -and $result.lease.daemonKey -ceq $probe.daemonKey) '復旧: 対象2台と Lease'
foreach($target in $result.targets){Assert-True ($target.stateBefore -ceq 'running' -and $target.stopState -ceq 'stopped' -and (Test-Path -LiteralPath $target.evidencePath)) "復旧: $($target.name) を停止（$($target.stopState)）"}
Assert-Equal ((@(Get-StopCalls $ctx) | Sort-Object) -join ',') ((@($recorded | ForEach-Object {$_.name}) | Sort-Object) -join ',') '復旧: 記録済み2台だけに stop（記録外の running VM には触れない）'
$firstEvidence=Get-Content -LiteralPath $result.targets[0].evidencePath -Raw | ConvertFrom-Json -AsHashtable
$evidence=Get-Content -LiteralPath $result.targets[1].evidencePath -Raw | ConvertFrom-Json -AsHashtable
# 予算は停止フェーズ開始時に1回だけ確定する: 2台の証拠の cleanupDeadlineAt が同一で、1台目の証拠で下限（開始前時刻＋2台×30秒）を満たす。
# 対象ごとに now+30 を計算し直す誤実装は、2台の値が食い違い、1台目が下限を割る。
$firstCleanupAt=Get-Utc $firstEvidence.budget.cleanupDeadlineAt
$cleanupAt=Get-Utc $evidence.budget.cleanupDeadlineAt
Assert-True ($firstCleanupAt -eq $cleanupAt) "復旧: 2台の停止予算は同一の cleanupDeadlineAt（$firstCleanupAt / $cleanupAt）"
Assert-True ($firstCleanupAt -ge $checkedBefore.AddSeconds(60) -and $firstCleanupAt -le $checkedBefore.AddSeconds(60+10)) "復旧: 予算は現在時刻起点で台数分（2台×30秒）に延びる（1台目の証拠: $firstCleanupAt）"
Assert-True ($null -eq $evidence.keepAlive) '復旧: 保持ジョブが無ければ停止を省く'
$json=ConvertTo-VerificationCanonicalJson $result
Assert-True (Test-Json -Json $json -SchemaFile $schemaPath) '復旧: 戻り値が schema に適合'
$files=Get-RecoveryFiles $ctx
Assert-True ($files.Count -eq 2 -and (Get-Content -LiteralPath $files[-1].FullName -Raw) -ceq $json) '復旧: 同じ内容を recovery-<時刻>.json に保存'
$again=Stop-VerificationRecordedSandboxes $ctx.runRoot (New-RecoveryInput $ctx 6)
Assert-True (@($again.targets | Where-Object {$_.stateBefore -ceq 'stopped' -and $_.stopState -ceq 'stopped'}).Count -eq 2 -and @(Get-StopCalls $ctx).Count -eq 2) '復旧(再実行): 停止済みには stop を発行しない'
Assert-True (-not(& $module {$script:PilotLeases.Count -gt 0})) '復旧: Lease を解放した'
$empty=New-Case;Write-FakeSbxScenario $empty.case
$result=Stop-VerificationRecordedSandboxes $empty.runRoot (New-RecoveryInput $empty 6)
Assert-True ($result.targetCount -eq 0 -and $result.daemonRunning -and $null -eq $result.runId -and $result.targets.Count -eq 0 -and $null -eq $result.lease) '復旧(記録0件): targetCount=0'
Assert-Equal @(Get-Calls $empty 'ls').Count 0 '復旧(記録0件): ls を発行しない'
Assert-True ((Get-RecoveryFiles $empty).Count -eq 1) '復旧(記録0件): 結果ファイル'
$count++

# 16b. 全体期限の後: daemon status の照会は起動を拒否されるので、Acquire は「デーモン停止」ではなく timed_out（deadline-reached）。
#      New-VerificationSandbox も作成要求の前に timed_out・not-created で返り、create 0回・sbx 呼び出し0回（期限前に取った Lease でも同じ）。
$ctx=New-Case;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$expired=$ctx.prepared.Clone();$expired.deadlineAt=[DateTime]::UtcNow.AddSeconds(-1).ToString('o')
$callsBefore=@(Get-Calls $ctx).Count
$failure=Get-Failure {Acquire-VerificationPilotLease $expired}
Assert-True ($failure.Data['status'] -ceq 'timed_out' -and $failure.Data['reason'] -ceq 'deadline-reached' -and $failure.Message -notlike '*daemon is not running*') "期限後の Acquire: timed_out・deadline-reached（$($failure.Data['status']) $($failure.Data['reason']): $($failure.Message)）"
$failure=Get-RuntimeFailure {New-VerificationSandbox $expired 'replay-before' $ctx.replayProfile $lease}
Assert-True ($failure.status -ceq 'timed_out' -and $failure.reason -ceq 'deadline-reached' -and $failure.creationState -ceq 'not-created' -and $failure.stopState -ceq 'not-created' -and $null -eq $failure.handle) "期限後の New-VerificationSandbox: timed_out・not-created（$($failure.status) $($failure.reason) $($failure.creationState)）"
Assert-Equal @(Get-Calls $ctx).Count $callsBefore '期限後: sbx を1回も呼ばない（照会も起動しない）'
Assert-Equal @(Get-Calls $ctx 'create').Count 0 '期限後: create 0回'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json'))) '期限後: 作成記録を書かない'
Release-VerificationPilotLease $lease
$count++

# 17. runtimes/<name>.json の判定キー（WorkspaceDir・SSHAgentSocketPath・CPUs など）の欠落・型違いは「取得できない」扱い: 観測なしで verified にせず、
#     作成済み ID の停止を試みて runtimeFailure.creationState=created・blocked。
foreach($variant in @('runtime-lacks-workspace','runtime-lacks-ssh-socket','runtime-cpus-string')){Test-ActivationFailureVariant $variant}
# 作成時の値の不一致（WorkspaceDir・SSHAgentSocketPath が空でない、CPUs の値違い、image digest の不一致、mcpgateway 以外の secret）も同じく停止を試みて blocked。
foreach($variant in @('runtime-workspace-set','runtime-ssh-socket-set','runtime-cpus-4','inspect-digest-mismatch','inspect-extra-secret')){Test-ActivationFailureVariant $variant}
$count++

# 17b. デーモンの版の照合（仕様02「版・テンプレート一致」）: daemon.log の起動行の版（"v0.42.1 <commit>"）と profile の sbxVersion が違えば VM を作らず blocked（sbx-version）。
#      表記の差（先頭の v、起動行の commit 部分）は正規化して比べる。
Assert-Equal (& $module {ConvertTo-VerificationSbxVersion 'v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64'}) '0.42.1' '版の正規化: 起動行の commit を除き先頭の v を除く'
Assert-Equal (& $module {ConvertTo-VerificationSbxVersion '0.42.1'}) (& $module {ConvertTo-VerificationSbxVersion ' v0.42.1'}) '版の正規化: v の有無と前後の空白の差を同じとみなす'
$ctx=New-Case;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' (New-Profile $ctx 'replay' @{sbxVersion='v0.42.2'}) $lease}
Assert-True ($failure.reason -ceq 'sbx-version' -and $failure.status -ceq 'blocked' -and $failure.creationState -ceq 'not-created' -and $failure.stopState -ceq 'not-created' -and $failure.message -like '*v0.42.2*') "版の不一致: blocked・not-created（$($failure.reason) $($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 0 '版の不一致: create 0回'
Release-VerificationPilotLease $lease
$count++

# 17c. ジョブ割当の失敗（assign-failed）の create: sbx クライアントはジョブ外で起動済みでありうるので、一覧に名前が無くても not-created にせず unknown・unverified・incomplete。
#      試験だけがモジュール内の Invoke-VerificationSbx を包み、create の戻り値を割当失敗の形（Execution の refusedReason=assign-failed・processTreeStopped=false）にする（7b と同じ差し替え）。
$ctx=New-Case;$vm=Add-Vm $ctx
$create500=Get-FakeSbxResponse 'create500' @{name=$vm.name}
Add-FakeSbxResponse $ctx.case @('create','shell','--name',[regex]::Escape($vm.name),'--cpus','2','--memory','2g','--no-share-skills','--deny-network','\*','--template','.+') -Stderr $create500.text -ExitCode 1 -Synthetic $create500.synthetic -Source $create500.source -First | Out-Null
Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
& $module {
    $script:InvokeSbxOriginal=${function:Invoke-VerificationSbx}
    Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value {
        param([hashtable]$Client,[string[]]$Argv,[hashtable]$Budget,[string]$Tag,[byte[]]$StdinBytes=$null,[bool]$ReadText=$true)
        $call=& $script:InvokeSbxOriginal $Client $Argv $Budget $Tag $StdinBytes $ReadText
        if($Tag -ceq 'create'){$call.result.started=$false;$call.result.exitCode=$null;$call.result.refusedReason='assign-failed';$call.result.processTreeStopped=$false}
        $call
    }
}
try{$failure=Get-RuntimeFailure {New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease}}
finally{& $module {Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value $script:InvokeSbxOriginal}}
Assert-True ($failure.creationState -ceq 'unknown' -and $failure.stopState -ceq 'unverified' -and $failure.status -ceq 'incomplete' -and $null -eq $failure.handle -and $failure.message -like '*assign-failed*') "割当失敗の create: unknown・unverified・incomplete（$($failure.creationState)/$($failure.stopState)/$($failure.status): $($failure.message)）"
Assert-Equal @(Get-Calls $ctx 'create').Count 1 '割当失敗の create: 作成要求は発行済み'
Assert-True (-not(Test-Path -LiteralPath (Join-Path $ctx.controlRoot 'runtime/replay-before-sandbox.json'))) '割当失敗の create: 一覧に無いので作成記録は無い'
Release-VerificationPilotLease $lease
$count++

# 17d. 停止手順の例外経路: 停止の途中で daemon.log を開けない・stop の発行が例外になる場合も、unverified の停止証拠を書き、stopResult を設定して以後の exec を拒否する。
#      daemon.log は試験だけが stop の発行直後に排他で開いて塞ぐ（Invoke-VerificationSbx の包み）。2回目は stop の発行そのものを例外にする。
$ctx=New-Case;$vm=Add-Vm $ctx;Write-FakeSbxScenario $ctx.case
$lease=Acquire-VerificationPilotLease $ctx.prepared
$handle=New-VerificationSandbox $ctx.prepared 'replay-before' $ctx.replayProfile $lease;$item=@{handle=$handle;ctx=$ctx;stopped=$false};$handles.Add($item)
$keepAliveTarget=$handle.keepAliveHandle.processId
# 保持セッションの exec（sh -c sleep）は背景で起動し呼び出し記録が遅れて現れうるので数えない。
function Get-CommandExecCount([hashtable]$Ctx){@(Get-Calls $Ctx 'exec' | Where-Object {($_.argv -join ' ') -notlike '* sh -c sleep *'}).Count}
$execBefore=Get-CommandExecCount $ctx
& $module {param($logPath,$mode)
    $script:InvokeSbxOriginal=${function:Invoke-VerificationSbx};$script:StopInjection=@{logPath=$logPath;mode=$mode;lock=$null}
    Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value {
        param([hashtable]$Client,[string[]]$Argv,[hashtable]$Budget,[string]$Tag,[byte[]]$StdinBytes=$null,[bool]$ReadText=$true)
        if($Tag -ceq 'stop' -and $script:StopInjection.mode -ceq 'throw'){throw [IO.IOException]::new('injected: stop call failed')}
        $call=& $script:InvokeSbxOriginal $Client $Argv $Budget $Tag $StdinBytes $ReadText
        if($Tag -ceq 'stop' -and $script:StopInjection.mode -ceq 'lock-log'){$script:StopInjection.lock=[IO.File]::Open($script:StopInjection.logPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}
        $call
    }
} $ctx.case.logPath 'lock-log'
try{$stop=Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $ctx.prepared 1)}
finally{& $module {if($null -ne $script:StopInjection.lock){$script:StopInjection.lock.Dispose()};$script:StopInjection.mode='throw'}}
Assert-True ($stop.stopState -ceq 'unverified' -and $stop.reason -like '*daemon.log unreadable after stop*' -and $null -ne $stop.evidencePath -and (Test-Path -LiteralPath $stop.evidencePath)) "daemon.log を開けない: unverified の停止証拠（$($stop.reason)）"
$stopEvidence=Get-Content -LiteralPath $stop.evidencePath -Raw | ConvertFrom-Json -AsHashtable
Assert-True ($stopEvidence.stopState -ceq 'unverified' -and $stopEvidence.listObserved -ceq 'stopped' -and $null -ne $stopEvidence.keepAlive) 'daemon.log を開けない: 証拠に一覧の観測と保持ジョブの停止を残す'
Assert-True (-not(Test-ProcessAlive $keepAliveTarget)) 'daemon.log を開けない: 保持セッションの対象は止まった'
$failure=Get-Failure {Invoke-VerificationSandboxCommand $handle @('python3','--version') $null '/home/agent/workspace/source' @{} (New-Budget $ctx) $null}
Assert-True ($failure.Data['reason'] -ceq 'sandbox-stopped' -and $failure.Data['status'] -ceq 'blocked') "daemon.log を開けない: 以後の exec を拒否（$($failure.Data['reason'])）"
try{$again=Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $ctx.prepared 1)}
finally{& $module {Set-Item -LiteralPath 'function:script:Invoke-VerificationSbx' -Value $script:InvokeSbxOriginal}}
$item.stopped=$true
Assert-True ($again.stopState -ceq 'unverified' -and $again.reason -like '*stop procedure failed: injected: stop call failed*' -and (Test-Path -LiteralPath $again.evidencePath) -and $again.evidencePath -cne $stop.evidencePath) "stop の例外: 例外を理由にした unverified の停止証拠（$($again.reason)）"
$failure=Get-Failure {Invoke-VerificationSandboxCommand $handle @('python3','--version') $null '/home/agent/workspace/source' @{} (New-Budget $ctx) $null}
Assert-True ($failure.Data['reason'] -ceq 'sandbox-stopped') 'stop の例外: 以後の exec を拒否'
Assert-Equal (Get-CommandExecCount $ctx) $execBefore '停止手順の例外: 停止の後に exec を発行しない（保持セッションの exec を除く）'
Assert-Equal @(Get-StopCalls $ctx).Count 1 '停止手順の例外: 発行できた stop は1回目だけ'
Stop-CaseFakeProcesses @($ctx)
Release-VerificationPilotLease $lease
$count++

# 17e. 復旧操作で作成記録1件が壊れていても、読めない記録を unverified として列挙し、他の記録済み VM を停止して結果を保存する。
$ctx=New-Case
$good=@{name='iv-'+$ctx.runId.Substring(0,8)+'-before';id=[guid]::NewGuid().ToString()}
Add-FakeSbxSandboxScenario $ctx.case $good.name $good.id -AlreadyPresent -InitialStatus running
[void](Write-VerificationSandboxRecord $ctx.runRoot @{runId=$ctx.runId;role='replay-before';name=$good.name;id=$good.id;createdAt=(Get-VerificationUtcNow);profileHash=$null;effectiveSettingsHash=$null;activationRecordPath=$null;activationRecordHash=$null})
Write-Text (Join-Path $ctx.controlRoot 'runtime/proposal-sandbox.json') '{"runId":"broken",'
Write-FakeSbxScenario $ctx.case
$result=Stop-VerificationRecordedSandboxes $ctx.runRoot (New-RecoveryInput $ctx 30)
$broken=@($result.targets | Where-Object {$_.name -like '*unreadable record: proposal-sandbox.json*'})
$stoppedGood=@($result.targets | Where-Object {$_.name -ceq $good.name})
Assert-True ($result.targetCount -eq 2 -and @($result.targets).Count -eq 2 -and $result.runId -ceq $ctx.runId) "壊れた記録: 対象2件を列挙（$(ConvertTo-VerificationCanonicalJson $result.targets)）"
Assert-True ($broken.Count -eq 1 -and $broken[0].stopState -ceq 'unverified' -and $broken[0].stateBefore -ceq 'unknown' -and $null -eq $broken[0].evidencePath) '壊れた記録: unverified として列挙し推定で名指ししない'
Assert-True ($stoppedGood.Count -eq 1 -and $stoppedGood[0].stopState -ceq 'stopped' -and (Test-Path -LiteralPath $stoppedGood[0].evidencePath)) '壊れた記録: 他の記録済み VM は停止して確認する'
Assert-Equal (@(Get-StopCalls $ctx) -join ',') $good.name '壊れた記録: stop は読めた記録の VM だけ'
Assert-True ((Get-RecoveryFiles $ctx).Count -eq 1 -and (Test-Json -Json (Get-Content -LiteralPath (Get-RecoveryFiles $ctx)[0].FullName -Raw) -SchemaFile $schemaPath)) '壊れた記録: recovery-result を保存し schema に適合'
Assert-True (-not(& $module {$script:PilotLeases.Count -gt 0})) '壊れた記録: Lease を解放した'
$count++

# 18. 全ケース（復旧操作の経路を含む）の calls.jsonl に SSH_AUTH_SOCK が無い。試験プロセスにはダミー値を置いている。
Assert-Equal ([Environment]::GetEnvironmentVariable('SSH_AUTH_SOCK')) $sshAuthSockDummy '環境辞書: 試験プロセスには SSH_AUTH_SOCK がある'
$callTotal=0;$recoveryStops=0
foreach($c in $allCases){
    foreach($call in @(Get-Calls $c)){
        $callTotal++
        Assert-True ($call.envKeys -notcontains 'SSH_AUTH_SOCK') "環境辞書: SSH_AUTH_SOCK を渡さない（$($c.case.sbxDir): $($call.argv -join ' ')）"
        Assert-True ($call.envKeys -contains 'PATH' -and $call.envKeys -contains 'SystemRoot') '環境辞書: 明示した変数'
    }
}
foreach($c in $allCases){if(Test-Path -LiteralPath (Join-Path $c.controlRoot 'runtime/recovery')){$recoveryStops+=@(Get-Calls $c 'stop').Count}}
Assert-True ($callTotal -gt 100 -and $recoveryStops -ge 2) "環境辞書: 検査した呼び出し $callTotal 件（復旧操作の stop $recoveryStops 件を含む）"
$count++

}finally{
    # 試験が作った VM の保持セッションを必ず止める（途中失敗でも）。ジョブ外に残った偽sbx（上の実測）は当該ケースの PID だけを止める。
    foreach($item in $handles){if(-not$item.stopped){try{[void](Stop-TestSandbox $item (New-VerificationCleanupBudget $item.ctx.prepared 1))}catch{}}}
    if($allCases.Count -gt 0){try{Stop-CaseFakeProcesses $allCases.ToArray()}catch{}}
    [Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK',$sshAuthSockBefore)
}
"SbxRuntimeV3: $count cases passed"
