$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../SbxRuntime.psm1') -Force
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
function Get-RuntimeFailure([scriptblock]$Action){
    $failure=Get-Failure $Action
    Assert-True ($failure.Data.Contains('runtimeFailure')) "runtimeFailure expected: $($failure.Message)"
    $record=$failure.Data['runtimeFailure'] | ConvertFrom-Json -AsHashtable
    $record.status=$failure.Data['status'];$record.message=$failure.Message
    $record
}
function Get-Calls([hashtable]$Ctx,[string]$First=''){@(Read-FakeSbxCalls $Ctx.case | Where-Object {$First -eq '' -or ($_.argv.Count -gt 0 -and $_.argv[0] -eq $First)})}

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

"SbxRuntimeV3: $count cases passed"
