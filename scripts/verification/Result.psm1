# 検証担当の申告を実イベントと成果物へ結び付け、根拠の欠けた合格を返さない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')
# v3 の照合で runtime profile の検査（Test-VerificationRuntimeProfile）と実効設定ラベルを共用する。-Force なしで、読込み済みのインスタンス（CLI の Lease）を分けない。
Import-Module (Join-Path $PSScriptRoot 'SbxRuntime.psm1') -DisableNameChecking
function Get-VerificationArtifact([hashtable]$Run,[string]$Relative) {
    if([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':') -or ($Relative.Replace('\','/').Split('/') -contains '..')){throw 'invalid artifact relative path'}
    $path=Resolve-VerificationPath (Join-Path $Run.runRoot $Relative)
    if(-not(Test-VerificationContainment $Run.runRoot $path) -or -not[IO.File]::Exists($path)){throw 'artifact missing or outside run'}
    @{path=$Relative;size=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
}
# v1（schemaVersion=1）の照合本体。公開契約と挙動を変えないため本文は抽出前のまま置く。
function Complete-LegacyVerificationRun([hashtable]$PreparedRun,[hashtable]$ExecutionResult) {
    $control=Resolve-VerificationPath $PreparedRun.controlRoot
    if(-not(Test-VerificationContainment $PreparedRun.runRoot $control)){throw 'control outside run'}
    $destination=Join-Path $control 'result.json'
    if(Test-Path -LiteralPath $destination){throw 'result already exists'}
    $result=[ordered]@{schemaVersion=1;runId=$PreparedRun.runId;status='incomplete';summary='';sourceState='unreadable';agentVerdict=$null;checks=@();findings=@();artifacts=@();unverified=@();execution=$ExecutionResult;runRoot=$PreparedRun.runRoot}
    try{
        $now=Get-VerificationSourceManifest $PreparedRun.request $PreparedRun.settings
        $result.sourceState=if(Test-VerificationManifestEqual $PreparedRun.sourceManifest $now){'unchanged'}else{'changed'}
    }catch{$result.unverified+=('source unreadable: '+$_.Exception.Message)}
    if($ExecutionResult.timedOut){$result.status='timed_out';$result.summary='execution timed out'}
    elseif(-not$ExecutionResult.started){$result.status='blocked';$result.summary='execution did not start'}
    elseif($result.sourceState -eq 'changed'){$result.status='source_changed';$result.summary='source changed since preparation'}
    elseif($result.sourceState -eq 'unreadable'){$result.summary='source state could not be checked'}
    else{
        try{
            if($ExecutionResult.runId -cne $PreparedRun.runId){throw 'execution runId mismatch'}
            if(-not$ExecutionResult.processTreeStopped){throw 'process tree stop unverified'}
            if($ExecutionResult.exitCode -ne 0){throw 'agent process did not exit successfully'}
            foreach($key in @('eventsPath','agentResultPath')){
                $path=Resolve-VerificationPath $ExecutionResult[$key]
                if(-not(Test-VerificationContainment $control $path) -or -not[IO.File]::Exists($path)){throw "missing control output: $key"}
            }
            $agentJson=[IO.File]::ReadAllText($ExecutionResult.agentResultPath)
            if(-not(Test-Json -Json $agentJson -SchemaFile (Join-Path $PSScriptRoot 'agent-result.schema.json') -ErrorAction SilentlyContinue)){throw 'invalid agent response'}
            $agent=$agentJson | ConvertFrom-Json -AsHashtable
            if($agent.runId -cne $PreparedRun.runId){throw 'agent runId mismatch'}
            $result.agentVerdict=$agent.verdict
            $result.findings=@($agent.findings)
            if($agent.verdict -eq 'incomplete' -or $agent.unverified.Count -gt 0){$result.unverified+=@($agent.unverified);throw 'agent reports unverified checks'}
            $events=[Collections.Generic.List[object]]::new()
            foreach($line in [IO.File]::ReadLines($ExecutionResult.eventsPath)){
                if([string]::IsNullOrWhiteSpace($line)){continue}
                $events.Add(($line | ConvertFrom-Json -AsHashtable -ErrorAction Stop))
            }
            if(@($events | Where-Object type -EQ 'thread.started').Count -ne 1 -or @($events | Where-Object type -EQ 'turn.completed').Count -ne 1 -or @($events | Where-Object type -In @('turn.failed','error')).Count -gt 0){throw 'missing or failed execution events'}
            $commands=@($events | Where-Object {$_.type -eq 'item.completed' -and $_.ContainsKey('item') -and $_.item.type -eq 'command_execution'})
            if($agent.checks.Count -eq 0){throw 'no executed checks reported'}
            $checks=[Collections.Generic.List[object]]::new();$artifacts=[Collections.Generic.List[object]]::new()
            foreach($check in $agent.checks){
                $matches=@($commands | Where-Object {$_.item.command -ceq $check.command})
                if($matches.Count -ne 1){throw 'command event is missing or ambiguous'}
                $item=$matches[0].item
                if(-not$item.ContainsKey('exit_code') -or $item.exit_code -cne $check.exitCode -or -not$item.ContainsKey('id')){throw 'command exit code or id mismatch'}
                $null=Get-VerificationArtifact $PreparedRun $check.evidencePath
                $checks.Add(@{command=$check.command;exitCode=$check.exitCode;evidencePath=$check.evidencePath;eventId=$item.id})
            }
            foreach($path in $agent.artifacts){$artifacts.Add((Get-VerificationArtifact $PreparedRun $path))}
            $result.checks=@($checks.ToArray());$result.artifacts=@($artifacts.ToArray())
            $result.status='completed';$result.summary=$agent.summary
        }catch{$result.status='incomplete';$result.summary=$_.Exception.Message;$result.unverified+=@($_.Exception.Message)}
    }
    if(-not$ExecutionResult.processTreeStopped){$result.unverified+=@('process tree stop unverified')}
    $json=$result | ConvertTo-Json -Depth 25
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'result.schema.json') -ErrorAction SilentlyContinue)){throw 'result does not satisfy schema'}
    $stream=[IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($json);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    return $result
}
function Complete-VerificationRun {
    # 2引数（PreparedRun, ExecutionResult）は既存 v1、3引数（PreparedRunV3, ProposalResultV3, ReplayResultV3）は v3 の照合。
    # 版の混在（v3 の準備結果を2引数で渡す、v1 の準備結果を3引数で渡す）と未実装 v2 は、結果を作らずに拒否する。
    param([hashtable]$PreparedRun,[hashtable]$ExecutionResult,[hashtable]$ReplayResult)
    if(-not$PSBoundParameters.ContainsKey('ReplayResult')){
        if($null -ne $PreparedRun -and $PreparedRun.ContainsKey('schemaVersion')){throw 'v1 collation takes a v1 prepared run; schemaVersion 3 requires ProposalResultV3 and ReplayResultV3'}
        return Complete-LegacyVerificationRun $PreparedRun $ExecutionResult
    }
    return Complete-ProposalReplayRun $PreparedRun $ExecutionResult $ReplayResult
}

# ---- v3（仕様03）: 準備・提案・再実行の3入力を、外側で保存した control の記録と現物で照合する。子の自己申告・上流の completed/ready を単独で信頼しない。 ----
$script:StrictUtf8=[Text.UTF8Encoding]::new($false,$true)
$script:Limitations=[string[]]@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
$script:ReplayRoles=[ordered]@{before='replay-before';after='replay-after'}
$script:ModeRoles=@{'candidate-comparison'=@('before','after');'reproduction-only'=@('before');recheck=@('after')}
# 優先順位（仕様03）: timed_out → incomplete（作成不明・作成済みの停止未確認・基準版改変）→ blocked → source_changed → incomplete（その他）。
$script:CategoryOrder=@('timed_out','incomplete-critical','blocked','source_changed','incomplete')
$script:CategoryStatus=@{timed_out='timed_out';'incomplete-critical'='incomplete';blocked='blocked';source_changed='source_changed';incomplete='incomplete'}

function Add-ResultProblem([hashtable]$State,[string]$Category,[string]$Stage,[string]$Reason,[string]$Detail='') {
    # 問題はすべて残す（仕様03「複数問題はすべてunverifiedへ残す」）。status は Resolve-ResultStatus が優先順位で1つ選ぶ。
    $State.problems.Add(@{category=$Category;stage=$Stage;reason=$Reason})
    $State.unverified.Add("$Stage`:$Reason"+$(if($Detail){": $Detail"}else{''}))
}
function Invoke-ResultCheck([hashtable]$State,[string]$Category,[string]$Stage,[scriptblock]$Check) {
    # 照合1件を実行し、例外なら理由（Data['reason']、無ければ check-failed）と外側で作った説明を問題として残して $null を返す。
    try{return (& $Check)}
    catch{Add-ResultProblem $State $Category $Stage (Get-VerificationExceptionValue $_.Exception 'reason' 'check-failed') $_.Exception.Message;return $null}
}
function Resolve-ResultStatus([hashtable]$State) {
    foreach($category in $script:CategoryOrder){
        $first=@($State.problems | Where-Object {$_.category -ceq $category} | Select-Object -First 1)
        if($first.Count -gt 0){return @{status=$script:CategoryStatus[$category];stage=$first[0].stage;reason=$first[0].reason}}
    }
    @{status='completed';stage=$null;reason=$null}
}
function Get-ResultControlPath([string]$Control,$Path,[string]$Expected,[string]$Reason) {
    # 証拠パスは当該 run の control 内だけ（再解析ポイントを含む経路は受けない）。Expected を渡したときはその位置に限る。
    if($Path -isnot [string] -or -not[IO.Path]::IsPathFullyQualified($Path)){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "evidence path must be an absolute path: $Path"}
    try{$full=Resolve-VerificationPath $Path}catch{Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "evidence path is not a plain path: $Path"}
    if(-not(Test-VerificationContainment $Control $full)){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "evidence path is outside control of this run: $Path"}
    if($Expected -and -not$full.Equals([IO.Path]::GetFullPath($Expected),[StringComparison]::OrdinalIgnoreCase)){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "evidence path is not the expected record: $Path"}
    $full
}
function Read-ResultJson([string]$Path,[string]$ExpectedHash,[string]$Reason) {
    # runId を持たない記録（source manifest・固定入力記録）と、期待hashを持たない記録（作成記録・停止記録）の読込み。
    # 期待hashがあればそのバイト列で照合し、厳格 UTF-8・重複キー・オブジェクトを確かめる（期待hashを現物から作り直さない）。
    if(-not[IO.File]::Exists($Path)){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record is missing: $Path"}
    $bytes=[IO.File]::ReadAllBytes($Path)
    if($ExpectedHash -and (Get-VerificationBytesHash $bytes) -ine $ExpectedHash){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record does not match its expected hash: $Path"}
    try{$json=$script:StrictUtf8.GetString($bytes)}catch{Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record is not valid UTF-8: $Path"}
    $duplicate=$true
    try{$duplicate=Test-VerificationJsonDuplicateKeys $json}catch{Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record is not JSON: $Path"}
    if($duplicate){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record has duplicate keys: $Path"}
    $value=$json | ConvertFrom-Json -AsHashtable -Depth 20 -DateKind String
    if($value -isnot [hashtable]){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "record must be a JSON object: $Path"}
    $value
}
function Read-ResultVerifiedRecord([string]$Path,[string]$ExpectedHash,[string]$RunId,[string]$ListKey,[string]$Reason) {
    try{Read-VerificationVerifiedJson $Path $ExpectedHash $RunId $ListKey 'incomplete' $Reason}catch{Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message $_.Exception.Message}
}
function Test-ResultSchema($Value,[string]$SchemaName,[string]$Reason) {
    $errors=$null
    if(-not(Test-Json -Json (ConvertTo-VerificationCanonicalJson $Value) -SchemaFile (Join-Path $PSScriptRoot $SchemaName) -ErrorAction SilentlyContinue -ErrorVariable errors)){
        Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message ("record does not match $SchemaName"+$(if($errors -and $errors.Count -gt 0){': '+$errors[0].Exception.Message}else{''}))
    }
}
function ConvertFrom-ResultUtc($Value,[string]$Reason,[string]$Label) {
    $parsed=[DateTimeOffset]::MinValue
    if($Value -isnot [string] -or -not[DateTimeOffset]::TryParse($Value,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal,[ref]$parsed)){Invoke-VerificationFailure -Status 'incomplete' -Reason $Reason -Message "$Label is not a time: $Value"}
    $parsed.UtcDateTime
}
function Test-ResultDaemonInstance([hashtable]$State,$Instance,[string]$Label) {
    # 同じ run の activationRecord（proposal・replay-before・replay-after）と停止記録の前後の daemonInstance は、pid・startedAt を持ち、全項目が同一であること（形の検査は RequestCopy の共通補助。Replay と同じ判定）。
    $json=Get-VerificationDaemonInstanceJson $Instance
    if($null -eq $json){Invoke-VerificationFailure -Status 'incomplete' -Reason 'daemon-instance' -Message "$Label lacks daemonInstance with pid and startedAt"}
    if($null -eq $State.daemon){$State.daemon=$json;$State.daemonLabel=$Label}
    elseif($State.daemon -cne $json){Invoke-VerificationFailure -Status 'incomplete' -Reason 'daemon-changed' -Message "daemonInstance of $Label differs from $($State.daemonLabel)"}
}
function Get-ResultRuntimeProfile([hashtable]$PreparedRun,[string]$Role) {
    # 仕様03手順1「実行設定の能力証拠」: settings の profile パス（proposal は proposalProfilePath、再実行は replayProfilePath）から profile を読み、
    # SbxRuntime の Test-VerificationRuntimeProfile（schema・証拠ファイルと各条件の hash・evidence の profileHash）で検査して、照合に使う profileHash・templateDigest・effectiveSettingsHash を返す。
    $key=$(if($Role -ceq 'proposal'){'proposalProfilePath'}else{'replayProfilePath'})
    $path=Get-VerificationValue $PreparedRun.settings $key
    if($path -isnot [string] -or -not[IO.Path]::IsPathFullyQualified($path)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'profile-rejected' -Message "settings.$key must be an absolute path"}
    try{$full=Resolve-VerificationPath $path}catch{Invoke-VerificationFailure -Status 'incomplete' -Reason 'profile-rejected' -Message "settings.$key is not a plain path"}
    $profile=Read-ResultJson $full '' 'profile-rejected'
    try{$profileHash=Test-VerificationRuntimeProfile $profile $Role $PreparedRun.settings;$effective=Get-VerificationEffectiveSettingsHash $profile $PreparedRun.settings}
    catch{Invoke-VerificationFailure -Status 'incomplete' -Reason 'profile-rejected' -Message ("runtime profile rejected: "+$_.Exception.Message)}
    @{profileHash=[string]$profileHash;templateDigest=[string]$profile.templateDigest;effectiveSettingsHash=[string]$effective}
}
function Test-ResultSandbox([hashtable]$State,[hashtable]$PreparedRun,[string]$Control,$Handle,[string[]]$Roles,$Expected) {
    # 作成済み VM の handle を、外側の作成記録（control/runtime/<role>-sandbox.json）と activationRecord（handle の記録hashで1回読む）に照合する。
    # activationRecord が無い handle（作成後の起動確認前に失敗したもの）は作成記録だけを照合する。activationRecord の不在を未作成の根拠にしない。
    if($Handle -isnot [hashtable]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'sandbox-handle' -Message 'sandbox handle must be an object'}
    $role=Get-VerificationValue $Handle 'role'
    foreach($key in @('runId','role','name','id')){if((Get-VerificationValue $Handle $key) -isnot [string] -or [string]::IsNullOrEmpty($Handle[$key])){Invoke-VerificationFailure -Status 'incomplete' -Reason 'sandbox-handle' -Message "sandbox handle lacks $key"}}
    if($Handle.runId -cne [string]$PreparedRun.runId -or $role -cnotin $Roles){Invoke-VerificationFailure -Status 'incomplete' -Reason 'sandbox-handle' -Message "sandbox handle does not belong to this run and role: $($Handle.name)"}
    # 検査済みの runtime profile（Expected。取得できなかった場合は $null で、その問題は呼出し側が記録済み）と handle の profileHash・effectiveSettingsHash。
    if($null -ne $Expected -and ([string](Get-VerificationValue $Handle 'profileHash') -ine $Expected.profileHash -or [string](Get-VerificationValue $Handle 'effectiveSettingsHash') -ine $Expected.effectiveSettingsHash)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'profile-mismatch' -Message "profileHash or effectiveSettingsHash of $role does not match the checked runtime profile"}
    $runtime=Join-Path $Control 'runtime'
    $record=Read-ResultJson (Join-Path $runtime "$role-sandbox.json") '' 'sandbox-record'
    foreach($key in @('runId','role','name','id','profileHash','effectiveSettingsHash')){
        if([string](Get-VerificationValue $record $key) -cne [string](Get-VerificationValue $Handle $key)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'sandbox-record' -Message "sandbox record $key does not match the handle of $role"}
    }
    $activationPath=Get-VerificationValue $Handle 'activationRecordPath'
    if([string]::IsNullOrEmpty($activationPath)){return $false}
    $path=Get-ResultControlPath $Control $activationPath (Join-Path $runtime "$role-activation.json") 'activation-record'
    $activation=Read-ResultVerifiedRecord $path ([string](Get-VerificationValue $Handle 'activationRecordHash')) ([string]$PreparedRun.runId) '' 'activation-record'
    Test-ResultSchema $activation 'activation-record.schema.json' 'activation-record'
    foreach($pair in @(@('sandboxId','id'),@('sandboxName','name'),@('role','role'),@('profileHash','profileHash'),@('effectiveSettingsHash','effectiveSettingsHash'))){
        if([string]$activation[$pair[0]] -cne [string]$Handle[$pair[1]]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'activation-record' -Message "activation record $($pair[0]) does not match the handle of $role"}
    }
    Test-ResultDaemonInstance $State $activation.daemonInstance "$role activation record"
    $true
}
function Get-ResultStopState([hashtable]$State,[hashtable]$PreparedRun,[string]$Control,[hashtable]$Handle) {
    # 作成した VM ごとに外側の停止記録（control/runtime/<role>-stop-<時刻>.json）を必要とする。同じ runId・名前・id の最後の記録が stopped で、
    # stop 発行時刻が作成時刻以後、停止前後のデーモン世代が run の activationRecord と同じなら stopped。記録なし・未確認は unverified（結果照合から stop・exec は発行しない）。
    $matching=[Collections.Generic.List[hashtable]]::new()
    $runtime=Join-Path $Control 'runtime'
    $files=[string[]]@(if([IO.Directory]::Exists($runtime)){[IO.Directory]::EnumerateFiles($runtime,"$($Handle.role)-stop-*.json")})
    [Array]::Sort($files,[StringComparer]::Ordinal)   # 名前の時刻（yyyyMMddTHHmmssfff）の順
    foreach($file in $files){
        $null=Get-ResultControlPath $Control $file '' 'stop-record'
        $evidence=Read-ResultJson $file '' 'stop-record'
        if((Get-VerificationValue $evidence 'runId') -ceq [string]$PreparedRun.runId -and (Get-VerificationValue $evidence 'name') -ceq $Handle.name -and (Get-VerificationValue $evidence 'id') -ceq $Handle.id){$matching.Add($evidence)}
    }
    if($matching.Count -eq 0){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message "no stop record for $($Handle.role) ($($Handle.name))"}
    $last=$matching[$matching.Count-1]
    if((Get-VerificationValue $last 'stopState') -cne 'stopped'){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message "last stop record of $($Handle.role) is not stopped"}
    $issued=ConvertFrom-ResultUtc (Get-VerificationValue $last 'stopIssuedAt') 'stop-unverified' 'stopIssuedAt'
    $created=ConvertFrom-ResultUtc (Get-VerificationValue $Handle 'createdAt') 'stop-unverified' 'createdAt'
    if($issued -lt $created){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message "stop of $($Handle.role) was issued before its creation"}
    foreach($key in @('daemonBefore','daemonAfter')){Test-ResultDaemonInstance $State (Get-VerificationValue $last $key) "$($Handle.role) stop record $key"}
    'stopped'
}
function Get-ResultReplayVerdict([string]$Mode,$BeforeExit,$AfterExit) {
    # 仕様03「観測からの判定」。終了値の観測分類で、期待する欠陥に由来する失敗かを認定しない。
    switch -CaseSensitive ($Mode){
        'candidate-comparison'{
            if($null -eq $BeforeExit -or $null -eq $AfterExit){return $null}
            if($BeforeExit -eq 0){return @{verdict='not-reproduced';exit=1}}
            if($AfterExit -eq 0){return @{verdict='candidate-supported';exit=0}}
            return @{verdict='still-failing';exit=1}
        }
        'reproduction-only'{if($null -eq $BeforeExit){return $null};if($BeforeExit -ne 0){return @{verdict='reproduced';exit=1}};return @{verdict='not-reproduced';exit=1}}
        'recheck'{if($null -eq $AfterExit){return $null};if($AfterExit -eq 0){return @{verdict='current-pass';exit=0}};return @{verdict='current-fail';exit=1}}
    }
    $null
}
function New-ResultShell($RunId,$RunRoot,$SourceManifestPath,$PilotInputId,$PilotInputPath,$PilotInputHash) {
    [ordered]@{
        schemaVersion=3;runId=$RunId;status='incomplete';summary='';sourceState='unreadable';baselineState='unreadable';proposalVerdict=$null;replayVerdict='undetermined'
        checks=[object[]]@();findings=[object[]]@();artifacts=[object[]]@();unverified=[object[]]@()
        execution=[ordered]@{proposalCreated=$false;replayCreatedCount=0;proposalStopped=$null;replayAllStopped=$null;failureStage=$null;exitCodeForCli=2;pilotInputId=$PilotInputId;pilotInputPath=$PilotInputPath;pilotInputHash=$PilotInputHash}
        previousRunId=$null;runRoot=$RunRoot;sourceManifestPath=$SourceManifestPath;scope=$null;limitations=[object[]]@()
    }
}
function Save-ResultV3([string]$Destination,$Result) {
    # schema に照らしてから control/result.json を CreateNew で一度だけ書く（既存があれば例外で保全する）。
    $json=ConvertTo-VerificationCanonicalJson $Result
    $errors=$null
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'result.schema.json') -ErrorAction SilentlyContinue -ErrorVariable errors)){throw ('result does not satisfy schema'+$(if($errors -and $errors.Count -gt 0){': '+$errors[0].Exception.Message}else{''}))}
    if([IO.File]::Exists($Destination)){throw "result already exists: $Destination"}
    Write-VerificationNewFile $Destination $json
}
function Get-ResultUpstreamCategory([string]$Status) {
    # Proposal/Replay の status 写像（仕様03）: failed→incomplete、blocked→blocked、timed_out→timed_out、incomplete→incomplete。値域外も incomplete。
    switch -CaseSensitive ($Status){'blocked'{'blocked'}'timed_out'{'timed_out'}default{'incomplete'}}
}

function Complete-ProposalReplayRun([hashtable]$PreparedRun,[hashtable]$ProposalResult,[hashtable]$ReplayResult) {
    foreach($given in @(@('PreparedRunV3',$PreparedRun),@('ProposalResultV3',$ProposalResult),@('ReplayResultV3',$ReplayResult))){
        $version=Get-VerificationValue $given[1] 'schemaVersion'
        if($null -eq $given[1] -or -not(($version -is [int]) -or ($version -is [long])) -or $version -ne 3){throw "$($given[0]) with schemaVersion 3 is required (versions must not be mixed)"}
    }
    $runId=[string]$PreparedRun.runId
    if([string]::IsNullOrEmpty($runId)){throw 'PreparedRunV3 runId is required'}
    $control=Resolve-VerificationPath ([string]$PreparedRun.controlRoot)
    if(-not(Test-VerificationContainment ([string]$PreparedRun.runRoot) $control)){throw 'control outside run'}
    $destination=Join-Path $control 'result.json'
    if([IO.File]::Exists($destination)){throw "result already exists: $destination"}
    $state=@{problems=[Collections.Generic.List[hashtable]]::new();unverified=[Collections.Generic.List[string]]::new();daemon=$null;daemonLabel=$null}
    $result=New-ResultShell $runId ([string]$PreparedRun.runRoot) ([string]$PreparedRun.sourceManifestPath) (Get-VerificationValue $PreparedRun 'pilotInputId') (Get-VerificationValue $PreparedRun 'pilotInputPath') (Get-VerificationValue $PreparedRun 'pilotInputHash')
    $proposalStatus=[string](Get-VerificationValue $ProposalResult 'status');$replayStatus=[string](Get-VerificationValue $ReplayResult 'status')
    $recheck=@(Get-VerificationValue $PreparedRun 'recheckArtifacts' | Where-Object {$null -ne $_}).Count -gt 0

    # 1. 3入力の runId と上流の status（非ready/not_run は未実施の証拠を要求せず、成立した段階の記録と失敗理由から優先順位で返す）。
    foreach($pair in @(@('proposal',$ProposalResult),@('replay',$ReplayResult))){
        if((Get-VerificationValue $pair[1] 'runId') -cne $runId){Add-ResultProblem $state 'incomplete' "$($pair[0])" 'run-id' "$($pair[0]) result belongs to another run"}
    }
    foreach($pair in @(@('proposal',$ProposalResult,$proposalStatus,'ready'),@('replay',$ReplayResult,$replayStatus,'completed'))){
        if($pair[2] -ceq $pair[3] -or $pair[2] -ceq 'not_run'){continue}
        $failure=Get-VerificationValue $pair[1] 'failure'
        $stage=[string](Get-VerificationValue $failure 'stage');$reason=[string](Get-VerificationValue $failure 'reason')
        Add-ResultProblem $state (Get-ResultUpstreamCategory $pair[2]) ("$($pair[0])/"+$(if($stage){$stage}else{'status'})) $(if($reason){$reason}else{"status-$($pair[2])"})
    }
    # not_run は原因となる上流結果に従い、単独で completed にしない。提案が ready なのに再実行が not_run、提案が非ready なのに再実行が completed は不整合。
    if($replayStatus -ceq 'not_run' -and $proposalStatus -ceq 'ready'){Add-ResultProblem $state 'incomplete' 'replay' 'not-run-without-cause' 'replay did not run although the proposal is ready'}
    if($replayStatus -ceq 'completed' -and $proposalStatus -cne 'ready'){Add-ResultProblem $state 'incomplete' 'replay' 'completed-without-proposal' 'replay reports completed although the proposal is not ready'}

    # 1b. 作成済み VM の handle・作成記録・activationRecord・daemonInstance（proposal・replay-before・replay-after で同一）。
    $proposalHandle=Get-VerificationValue $ProposalResult 'sandbox'
    $replayHandles=@(Get-VerificationValue $ReplayResult 'sandboxes' | Where-Object {$null -ne $_})
    # 実行設定の能力証拠: 作成した VM がある役割だけ、settings の profile を検査して期待値にする（未作成の役割には証拠を要求しない）。
    $proposalProfile=$null;$replayProfile=$null
    if($null -ne $proposalHandle){$proposalProfile=Invoke-ResultCheck $state 'incomplete' 'result/proposal-profile' {Get-ResultRuntimeProfile $PreparedRun 'proposal'}}
    if($replayHandles.Count -gt 0){$replayProfile=Invoke-ResultCheck $state 'incomplete' 'result/replay-profile' {Get-ResultRuntimeProfile $PreparedRun 'replay-before'}}
    $activated=@{}
    if($null -ne $proposalHandle){
        $ok=Invoke-ResultCheck $state 'incomplete' 'result/proposal-sandbox' {Test-ResultSandbox $state $PreparedRun $control $proposalHandle @('proposal') $proposalProfile}
        if($ok -eq $true){$activated['proposal']=$true}
    }
    # 役割ごとに新しい VM（仕様03手順4・仕様04）: 再実行 VM の id は互いにも提案 VM とも重ならず、同じ役割の VM は1台だけ。
    $seenIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$seenRoles=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $proposalId=[string](Get-VerificationValue $proposalHandle 'id')
    if(-not[string]::IsNullOrEmpty($proposalId)){[void]$seenIds.Add($proposalId)}
    foreach($handle in $replayHandles){
        $ok=Invoke-ResultCheck $state 'incomplete' 'result/replay-sandbox' {Test-ResultSandbox $state $PreparedRun $control $handle @('replay-before','replay-after') $replayProfile}
        $id=[string](Get-VerificationValue $handle 'id');$handleRole=[string](Get-VerificationValue $handle 'role')
        $unique=$true
        if(-not[string]::IsNullOrEmpty($id) -and -not$seenIds.Add($id)){$unique=$false;Add-ResultProblem $state 'incomplete' 'result/replay-sandbox' 'sandbox-reused' "sandbox id $id is used by more than one sandbox of this run"}
        if(-not[string]::IsNullOrEmpty($handleRole) -and -not$seenRoles.Add($handleRole)){$unique=$false;Add-ResultProblem $state 'incomplete' 'result/replay-sandbox' 'sandbox-role-repeated' "more than one sandbox claims role $handleRole"}
        if($ok -eq $true -and $unique){$activated[$id]=$true}
    }
    $references=[ordered]@{}
    foreach($key in $script:ReplayRoles.Keys){$value=Get-VerificationValue $ReplayResult $key;if($null -ne $value){$references[$key]=$value}}
    if([string](Get-VerificationValue $ReplayResult 'mode') -ceq 'candidate-comparison' -and $references.Count -eq 2){
        [void](Invoke-ResultCheck $state 'incomplete' 'result/effective-settings' {
            $left=[string](Get-VerificationValue (Get-VerificationValue $references.before 'sandbox') 'effectiveSettingsHash');$right=[string](Get-VerificationValue (Get-VerificationValue $references.after 'sandbox') 'effectiveSettingsHash')
            if([string]::IsNullOrEmpty($left) -or $left -cne $right){Invoke-VerificationFailure -Status 'incomplete' -Reason 'effective-settings-differ' -Message 'effectiveSettingsHash of replay-before and replay-after differ'}
        })
    }

    # 2. PreparedRunV3 の各 manifest 期待hashと現物（固定入力記録・source・baseline・recheck）。期待hashを現物から作り直さない。
    $pilotOk=Invoke-ResultCheck $state 'incomplete' 'result/pilot-input' {
        $path=Get-ResultControlPath $control (Get-VerificationValue $PreparedRun 'pilotInputPath') (Join-Path $control 'pilot-input.json') 'pilot-input'
        $record=Read-ResultJson $path ([string](Get-VerificationValue $PreparedRun 'pilotInputHash')) 'pilot-input'
        Test-ResultSchema $record 'pilot-input.schema.json' 'pilot-input'
        if($record.inputId -cne [string](Get-VerificationValue $PreparedRun 'pilotInputId')){Invoke-VerificationFailure -Status 'incomplete' -Reason 'pilot-input' -Message 'pilot input id differs from the prepared run'}
        $recordRoot=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($record.sourceRoot))
        foreach($root in @([string]$PreparedRun.sourceRoot,[string](Get-VerificationValue $PreparedRun.request 'sourceRoot'))){
            if([string]::IsNullOrEmpty($root) -or -not$recordRoot.Equals([IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($root)),[StringComparison]::OrdinalIgnoreCase)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'pilot-input' -Message 'pilot input sourceRoot differs from the prepared run'}
        }
        if($record.sourceManifestHash -ine [string]$PreparedRun.sourceManifestHash){Invoke-VerificationFailure -Status 'incomplete' -Reason 'pilot-input' -Message 'pilot input sourceManifestHash differs from the prepared run'}
        $true
    }
    $storedSource=Invoke-ResultCheck $state 'incomplete' 'result/source-manifest' {
        $path=Get-ResultControlPath $control ([string]$PreparedRun.sourceManifestPath) (Join-Path $control 'source-manifest.json') 'source-manifest'
        Read-ResultJson $path ([string]$PreparedRun.sourceManifestHash) 'source-manifest'
    }
    if($null -ne $storedSource){
        try{
            $now=Get-VerificationSourceManifest $PreparedRun.request $PreparedRun.settings
            $result.sourceState=$(if(Test-VerificationManifestEqual $storedSource $now){'unchanged'}else{'changed'})
        }catch{Add-ResultProblem $state 'incomplete' 'result/source' 'source-unreadable' $_.Exception.Message}
        if($result.sourceState -ceq 'changed'){Add-ResultProblem $state 'source_changed' 'result/source' 'source-changed' 'source files, HEAD or history references differ from the source manifest'}
    }
    $baselineWork=$null
    try{
        $path=Get-ResultControlPath $control ([string]$PreparedRun.baselineManifestPath) (Join-Path $control 'baseline-manifest.json') 'baseline-unreadable'
        if([IO.File]::Exists($path) -and (Get-VerificationBytesHash ([IO.File]::ReadAllBytes($path))) -ine [string]$PreparedRun.baselineManifestHash){$result.baselineState='changed';Invoke-VerificationFailure -Status 'incomplete' -Reason 'baseline-changed' -Message 'baseline manifest does not match its expected hash'}
        $manifest=Read-ResultVerifiedRecord $path ([string]$PreparedRun.baselineManifestHash) $runId 'files' 'baseline-unreadable'
        $expected=ConvertTo-VerificationFileMap $manifest.files 'incomplete' 'baseline-unreadable'
        try{$actual=Get-VerificationTreeFiles ([string]$PreparedRun.baselineRoot) 'incomplete' 'baseline-changed'}catch{$result.baselineState='changed';throw}
        $difference=Get-VerificationMapDifference $expected $actual
        if($difference){$result.baselineState='changed';Invoke-VerificationFailure -Status 'incomplete' -Reason 'baseline-changed' -Message "baseline differs from its manifest ($difference)"}
        $result.baselineState='unchanged'
        $baselineWork=[Collections.Generic.SortedDictionary[string,object]]::new([StringComparer]::Ordinal)
        foreach($file in $expected.Values){if(@($file.path.Split('/') | Where-Object {$_ -ieq '.git'}).Count -eq 0){$baselineWork.Add($file.path,$file)}}
    }catch{
        $category=$(if($result.baselineState -ceq 'changed'){'incomplete-critical'}else{'incomplete'})
        Add-ResultProblem $state $category 'result/baseline' (Get-VerificationExceptionValue $_.Exception 'reason' 'baseline-unreadable') $_.Exception.Message
    }
    $recheckTests=$null
    if($recheck -or -not[string]::IsNullOrEmpty([string](Get-VerificationValue $PreparedRun 'recheckManifestPath'))){
        $recheckTests=Invoke-ResultCheck $state 'incomplete' 'result/recheck-manifest' {
            $path=Get-ResultControlPath $control (Get-VerificationValue $PreparedRun 'recheckManifestPath') (Join-Path $control 'recheck-manifest.json') 'recheck-manifest'
            $manifest=Read-ResultVerifiedRecord $path ([string](Get-VerificationValue $PreparedRun 'recheckManifestHash')) $runId 'tests' 'recheck-manifest'
            $previousRunId=Get-VerificationValue $manifest 'previousRunId'
            if($previousRunId -isnot [string] -or [string]::IsNullOrEmpty($previousRunId)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'recheck-manifest' -Message 'recheck manifest lacks previousRunId'}
            $tests=ConvertTo-VerificationFileMap $manifest.tests 'incomplete' 'recheck-manifest'
            $prepared=ConvertTo-VerificationFileMap ([object[]]@(Get-VerificationValue $PreparedRun 'recheckArtifacts')) 'incomplete' 'recheck-manifest'
            if(Get-VerificationMapDifference $tests $prepared){Invoke-VerificationFailure -Status 'incomplete' -Reason 'recheck-manifest' -Message 'recheck manifest tests differ from the prepared recheck artifacts'}
            $result.previousRunId=$previousRunId
            ,$tests
        }
    }

    # 3. 提案の manifest・accepted 現物・testsManifestHash、各 replay input と差分（candidate-comparison だけ replacement 一覧に限る）。
    $proposal=$null
    if($proposalStatus -ceq 'ready'){
        $proposal=Invoke-ResultCheck $state 'incomplete' 'result/proposal-manifest' {
            $origin=[string](Get-VerificationValue $ProposalResult 'origin')
            $expectedOrigin=$(if($recheck){'reused-tests'}else{'generated'})
            if($origin -cne $expectedOrigin){Invoke-VerificationFailure -Status 'incomplete' -Reason 'proposal-origin' -Message "proposal origin $origin does not fit this run"}
            if($origin -ceq 'generated' -and ($null -eq $proposalHandle -or (Get-VerificationValue $ProposalResult 'stopState') -cne 'stopped')){Invoke-VerificationFailure -Status 'incomplete' -Reason 'proposal-origin' -Message 'generated proposal requires its stopped sandbox'}
            if($origin -ceq 'reused-tests' -and ($null -ne $proposalHandle -or (Get-VerificationValue $ProposalResult 'stopState') -cne 'not-created')){Invoke-VerificationFailure -Status 'incomplete' -Reason 'proposal-origin' -Message 'reused tests must not claim a proposal sandbox'}
            $path=Get-ResultControlPath $control (Get-VerificationValue $ProposalResult 'manifestPath') (Join-Path $control 'proposal/manifest.json') 'proposal-manifest'
            $manifest=Read-ResultVerifiedRecord $path ([string](Get-VerificationValue $ProposalResult 'manifestHash')) $runId 'artifacts' 'proposal-manifest'
            # manifest と ProposalResult の対応・artifacts の区分・testsManifestHash は RequestCopy の共通補助（Replay と同じ判定。status だけ incomplete）。
            $listed=Test-VerificationProposalManifest $manifest $ProposalResult 'incomplete'
            $split=Split-VerificationProposalArtifacts $listed $baselineWork $recheck ([string](Get-VerificationValue $ProposalResult 'testsManifestHash')) 'incomplete'
            if($recheck){
                if($null -eq $recheckTests){Invoke-VerificationFailure -Status 'incomplete' -Reason 'recheck-manifest' -Message 'recheck tests were not verified'}
                $testMap=ConvertTo-VerificationFileMap ([object[]]@($split.tests)) 'incomplete' 'proposal-artifacts'
                if(Get-VerificationMapDifference $recheckTests $testMap){Invoke-VerificationFailure -Status 'incomplete' -Reason 'proposal-artifacts' -Message 'reused tests differ from the recheck manifest'}
            }
            $difference=Get-VerificationMapDifference $listed (Get-VerificationTreeFiles ([string]$PreparedRun.acceptedRoot) 'incomplete' 'accepted-changed')
            if($difference){Invoke-VerificationFailure -Status 'incomplete' -Reason 'accepted-changed' -Message "accepted differs from the proposal manifest ($difference)"}
            $mode=$(if($recheck){'recheck'}elseif($split.replacements.Count -gt 0){'candidate-comparison'}else{'reproduction-only'})
            @{mode=$mode;testsManifestHash=$split.testsManifestHash;listed=$listed;replacements=$split.replacements}
        }
        $childSummary=Get-VerificationValue $ProposalResult 'summary'
        $findings=[Collections.Generic.List[object]]::new()
        # 子の説明は未信頼のまま findings へ分けて返す（要約も説明の1件として sourcePaths なしで先頭に置く）。採否・status には使わない。
        if($childSummary -is [string] -and $childSummary.Length -gt 0){$findings.Add([ordered]@{description=$childSummary;sourcePaths=[object[]]@()})}
        foreach($finding in @(Get-VerificationValue $ProposalResult 'findings' | Where-Object {$null -ne $_})){
            $findings.Add([ordered]@{description=[string](Get-VerificationValue $finding 'description');sourcePaths=[object[]]@(foreach($p in @(Get-VerificationValue $finding 'sourcePaths' | Where-Object {$null -ne $_})){[string]$p})})
        }
        $result.findings=[object[]]$findings.ToArray()
    }
    if($null -ne $proposal){
        $result.proposalVerdict='reference-only'
        $result.artifacts=[object[]]@(foreach($artifact in $proposal.listed.Values){[ordered]@{kind=$artifact.kind;path=$artifact.path;size=$artifact.size;sha256=$artifact.sha256;previousRunId=$(if($recheck){$result.previousRunId}else{$null})}})
        $replayMode=Get-VerificationValue $ReplayResult 'mode'
        if($null -ne $replayMode -and [string]$replayMode -cne $proposal.mode){Add-ResultProblem $state 'incomplete' 'result/replay-mode' 'replay-mode' "replay mode $replayMode differs from $($proposal.mode) derived from the proposal"}
        $expectedRoles=$script:ModeRoles[$proposal.mode]
        foreach($key in @($references.Keys)){if($key -notin $expectedRoles){Add-ResultProblem $state 'incomplete' 'result/replay-evidence' 'reference-unexpected' "replay $key is not part of mode $($proposal.mode)"}}
        if($replayStatus -ceq 'completed'){
            # completed の自己申告だけでは信頼しない。mode に必要な役割の記録参照が揃っていること。
            foreach($key in $expectedRoles){if(-not$references.Contains($key)){Add-ResultProblem $state 'incomplete' 'result/replay-evidence' 'reference-missing' "replay reports completed without a $key record"}}
        }
        $inputs=@{}
        foreach($key in @($references.Keys | Where-Object {$_ -in $expectedRoles})){
            $role=$script:ReplayRoles[$key]
            $checked=Invoke-ResultCheck $state 'incomplete' "result/$role-input" {
                $reference=$references[$key]
                $path=Get-ResultControlPath $control (Get-VerificationValue $reference 'inputManifestPath') (Join-Path $control "replay/$role-input-manifest.json") 'replay-input-manifest'
                $manifest=Read-ResultVerifiedRecord $path ([string](Get-VerificationValue $reference 'inputManifestHash')) $runId 'files' 'replay-input-manifest'
                if((Get-VerificationValue $manifest 'role') -cne $role -or (Get-VerificationValue $manifest 'mode') -cne $proposal.mode -or [string](Get-VerificationValue $manifest 'testsManifestHash') -cne $proposal.testsManifestHash){Invoke-VerificationFailure -Status 'incomplete' -Reason 'replay-input-manifest' -Message "input manifest of $role does not match the role, mode or tests"}
                $files=ConvertTo-VerificationFileMap $manifest.files 'incomplete' 'replay-input-manifest'
                $difference=Get-VerificationMapDifference $files (Get-VerificationTreeFiles (Join-Path ([string]$PreparedRun.runRoot) "replay-inputs/$key") 'incomplete' 'replay-input-changed')
                if($difference){Invoke-VerificationFailure -Status 'incomplete' -Reason 'replay-input-changed' -Message "replay-inputs/$key differs from its input manifest ($difference)"}
                $tests=[Collections.Generic.List[object]]::new()
                $work=[Collections.Generic.SortedDictionary[string,object]]::new([StringComparer]::Ordinal)
                foreach($file in $files.Values){
                    if($file.path.StartsWith('.verification-tests/',[StringComparison]::Ordinal)){$tests.Add(@{path='tests/'+$file.path.Substring(20);size=$file.size;sha256=$file.sha256})}else{$work.Add($file.path,$file)}
                }
                if((Get-VerificationTestsManifestHash $tests.ToArray()) -cne $proposal.testsManifestHash){Invoke-VerificationFailure -Status 'incomplete' -Reason 'replay-tests-differ' -Message "tests in replay-inputs/$key are not the accepted tests"}
                @{work=$work;tests=(ConvertTo-VerificationCanonicalJson ([object[]]$tests.ToArray()))}
            }
            if($null -ne $checked){$inputs[$key]=$checked}
        }
        $baseKey=$(if($proposal.mode -ceq 'recheck'){'after'}else{'before'})
        if($inputs.ContainsKey($baseKey) -and $null -ne $baselineWork){
            [void](Invoke-ResultCheck $state 'incomplete' "result/$($script:ReplayRoles[$baseKey])-input" {
                $difference=Get-VerificationMapDifference $baselineWork $inputs[$baseKey].work
                if($difference){Invoke-VerificationFailure -Status 'incomplete' -Reason 'replay-input-baseline' -Message "replay-inputs/$baseKey differs from the baseline work files ($difference)"}
            })
        }
        if($proposal.mode -ceq 'candidate-comparison' -and $inputs.ContainsKey('before') -and $inputs.ContainsKey('after')){
            [void](Invoke-ResultCheck $state 'incomplete' 'result/replay-diff' {
                if($inputs.before.tests -cne $inputs.after.tests){Invoke-VerificationFailure -Status 'incomplete' -Reason 'replay-tests-differ' -Message 'replay-before and replay-after do not run the same tests'}
                # 差分照合は RequestCopy の共通補助（Replay と同じ。存在・size・sha256 の差分）。
                Test-VerificationReplacementDiff $inputs.before.work $inputs.after.work ([object[]]@($proposal.replacements)) 'incomplete'
            })
        }
    }

    # 4. 外側の再実行記録（runId/role/VM id/profile/template/argv/対象版/時刻/出力パス・ハッシュ/transportVerified/停止）。証拠パスは control 内だけ。
    $exits=@{};$commandIds=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$templates=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $checks=[Collections.Generic.List[object]]::new()
    $replayIds=@($replayHandles | ForEach-Object {[string](Get-VerificationValue $_ 'id')})
    foreach($key in @($references.Keys)){
        $role=$script:ReplayRoles[$key]
        $record=Invoke-ResultCheck $state 'incomplete' "result/$role-record" {
            $reference=$references[$key]
            $sandbox=Get-VerificationValue $reference 'sandbox'
            $commandId=[string](Get-VerificationValue $reference 'commandId')
            if((Get-VerificationValue $reference 'role') -cne $role -or $commandId -notmatch "^$role-[0-9a-f]{12}$"){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-reference' -Message "replay $key reference does not name a $role command"}
            if($sandbox -isnot [hashtable] -or [string](Get-VerificationValue $sandbox 'role') -cne $role){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-sandbox' -Message "replay $key reference points to a sandbox of another role"}
            if([string](Get-VerificationValue $sandbox 'id') -cnotin $replayIds -or -not$activated.ContainsKey([string]$sandbox.id)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-sandbox' -Message "replay $key sandbox is not a verified sandbox of this run"}
            if(-not$commandIds.Add($commandId)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'command-reused' -Message "commandId is used twice: $commandId"}
            $path=Get-ResultControlPath $control (Get-VerificationValue $reference 'recordPath') (Join-Path $control "replay/$role/$commandId.json") 'record-missing'
            $recordHash=[string](Get-VerificationValue $reference 'recordHash')
            $value=Read-ResultVerifiedRecord $path $recordHash $runId '' 'record-missing'
            Test-ResultSchema $value 'replay-record.schema.json' 'record-schema'
            foreach($pair in @(@('commandId',$commandId),@('role',$role),@('sandboxId',[string]$sandbox.id),@('profileHash',[string](Get-VerificationValue $sandbox 'profileHash')),@('effectiveSettingsHash',[string](Get-VerificationValue $sandbox 'effectiveSettingsHash')),@('activationRecordPath',[string](Get-VerificationValue $sandbox 'activationRecordPath')),@('activationRecordHash',[string](Get-VerificationValue $sandbox 'activationRecordHash')),@('inputManifestHash',[string](Get-VerificationValue $reference 'inputManifestHash')))){
                if([string]$value[$pair[0]] -cne $pair[1]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-mismatch' -Message "replay record $($pair[0]) does not match the $role sandbox or reference"}
            }
            if([string]$value.sourceManifestHash -ine [string]$PreparedRun.sourceManifestHash){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-mismatch' -Message 'replay record sourceManifestHash differs from the prepared run'}
            if($null -ne $proposal -and $value.testsManifestHash -cne $proposal.testsManifestHash){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-mismatch' -Message 'replay record testsManifestHash differs from the proposal'}
            if((ConvertTo-VerificationCanonicalJson $value.limits) -cne (ConvertTo-VerificationCanonicalJson (Get-VerificationValue $PreparedRun.settings 'limits'))){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-mismatch' -Message 'replay record limits differ from the settings'}
            [void]$templates.Add([string]$value.templateDigest)
            if($null -ne $replayProfile -and [string]$value.templateDigest -cne $replayProfile.templateDigest){Invoke-VerificationFailure -Status 'incomplete' -Reason 'profile-mismatch' -Message "replay $key record templateDigest differs from the checked replay profile"}
            if($templates.Count -gt 1){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-mismatch' -Message 'replay-before and replay-after use different templates'}
            $checks.Add([ordered]@{role=$role;commandId=$commandId;sandboxId=[string]$sandbox.id;recordPath=$path;recordHash=$recordHash.ToUpperInvariant();exitCode=$value.exitCode})
            # ここから観測の完全性（時刻・出力・transport・停止）。不成立は観測分類を作らない。
            if($value.timedOut -or $value.outputExceeded -or $value.transportVerified -ne $true -or $null -eq $value.exitCode){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-transport' -Message "replay $key did not finish with a verified transport (timedOut=$($value.timedOut), outputExceeded=$($value.outputExceeded), transportVerified=$($value.transportVerified))"}
            $started=ConvertFrom-ResultUtc $value.startedAt 'record-time' 'startedAt';$finished=ConvertFrom-ResultUtc $value.finishedAt 'record-time' 'finishedAt'
            $runStarted=ConvertFrom-ResultUtc ([string]$PreparedRun.startedAt) 'record-time' 'run startedAt';$created=ConvertFrom-ResultUtc ([string](Get-VerificationValue $sandbox 'createdAt')) 'record-time' 'sandbox createdAt'
            if($started -lt $runStarted -or $started -lt $created -or $finished -lt $started -or $finished -gt [DateTime]::UtcNow.AddMinutes(5)){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-time' -Message "replay $key times are outside the run"}
            foreach($stream in @('stdout','stderr')){
                $streamPath=Get-ResultControlPath $control $value["${stream}Path"] (Join-Path $control "runtime/$role/commands/$commandId.$stream") 'record-output'
                if(-not[IO.File]::Exists($streamPath) -or $null -eq $value["${stream}Hash"] -or (Get-FileHash -LiteralPath $streamPath -Algorithm SHA256).Hash -ine [string]$value["${stream}Hash"]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-output' -Message "replay $key $stream output is missing or changed"}
            }
            if($value.stopVerified -ne $true){Invoke-VerificationFailure -Status 'incomplete' -Reason 'record-stop' -Message "replay $key record does not verify the stop"}
            $value
        }
        if($null -ne $record){$exits[$key]=$record.exitCode}
    }
    $result.checks=[object[]]$checks.ToArray()

    # 5. 作成した proposal とすべての再実行 VM の停止記録。reused-tests・未作成は null（停止を架空に記録しない）。作成成否不明は停止未確認として扱う。
    $runtimeDir=Join-Path $control 'runtime'
    if($null -ne $proposalHandle){
        $result.execution.proposalCreated=$true
        $stopped=Invoke-ResultCheck $state 'incomplete-critical' 'result/proposal-stop' {
            if($proposalHandle -isnot [hashtable]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message 'proposal sandbox handle is not an object'}
            if((Get-VerificationValue $ProposalResult 'stopState') -cne 'stopped'){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message 'proposal result does not report a verified stop'}
            Get-ResultStopState $state $PreparedRun $control $proposalHandle
        }
        $result.execution.proposalStopped=($stopped -ceq 'stopped')
    }elseif((Get-VerificationValue $ProposalResult 'stopState') -cne 'not-created' -or [IO.File]::Exists((Join-Path $runtimeDir 'proposal-sandbox.json'))){
        $result.execution.proposalStopped=$false
        Add-ResultProblem $state 'incomplete-critical' 'result/proposal-stop' 'creation-unresolved' 'proposal sandbox creation is not confirmed as not-created'
    }
    $result.execution.replayCreatedCount=$replayHandles.Count
    $allStopped=$true
    foreach($handle in $replayHandles){
        $stopped=Invoke-ResultCheck $state 'incomplete-critical' 'result/replay-stop' {
            if($handle -isnot [hashtable]){Invoke-VerificationFailure -Status 'incomplete' -Reason 'stop-unverified' -Message 'replay sandbox handle is not an object'}
            Get-ResultStopState $state $PreparedRun $control $handle
        }
        if($stopped -cne 'stopped'){$allStopped=$false}
    }
    $reportedAll=Get-VerificationValue $ReplayResult 'allStopped'
    # 作成記録があるのに結果に載っていない役割は、作成済みの可能性を捨てずに作成不明として扱う。
    $reportedRoles=@($replayHandles | ForEach-Object {[string](Get-VerificationValue $_ 'role')})
    $unlisted=@(foreach($roleName in $script:ReplayRoles.Values){if([IO.File]::Exists((Join-Path $runtimeDir "$roleName-sandbox.json")) -and $roleName -cnotin $reportedRoles){$roleName}})
    if($replayHandles.Count -eq 0){
        if($reportedAll -eq $false -or $unlisted.Count -gt 0){
            $result.execution.replayAllStopped=$false
            Add-ResultProblem $state 'incomplete-critical' 'result/replay-stop' 'creation-unresolved' 'replay sandbox creation is not confirmed as not-created'
        }
    }else{
        if($allStopped -and $reportedAll -ne $true){$allStopped=$false;Add-ResultProblem $state 'incomplete-critical' 'result/replay-stop' 'stop-unverified' 'replay result does not report all sandboxes stopped'}
        if($unlisted.Count -gt 0){$allStopped=$false;Add-ResultProblem $state 'incomplete-critical' 'result/replay-stop' 'creation-unresolved' ('sandbox records exist for unreported roles: '+($unlisted -join ', '))}
        $result.execution.replayAllStopped=$allStopped
    }

    # 6. status と観測分類。scope は固定入力記録と原本の再照合が通ったときだけ付ける。
    $resolved=Resolve-ResultStatus $state
    if($resolved.status -ceq 'completed'){
        $verdict=$(if($null -ne $proposal){Get-ResultReplayVerdict $proposal.mode $exits['before'] $exits['after']}else{$null})
        if($null -eq $verdict){Add-ResultProblem $state 'incomplete' 'result/verdict' 'observation-missing' 'no observation classification could be made';$resolved=Resolve-ResultStatus $state}
        else{$result.replayVerdict=$verdict.verdict;$result.execution.exitCodeForCli=$verdict.exit}
    }
    $result.status=$resolved.status
    $result.execution.failureStage=$resolved.stage
    if($pilotOk -eq $true -and $result.sourceState -ceq 'unchanged'){$result.scope='synthetic-pilot';$result.limitations=[object[]]$script:Limitations}
    $result.unverified=[object[]]$state.unverified.ToArray()
    $result.summary=$(if($resolved.status -ceq 'completed'){"completed: $($result.replayVerdict) ($($proposal.mode)); observation only, the caller judges adoption"}else{"$($resolved.status): $($resolved.stage):$($resolved.reason)"+$(if($state.problems.Count -gt 1){" (+$($state.problems.Count-1) more in unverified)"}else{''})})

    # 7. control/result.json を CreateNew で一度だけ保存する。
    Save-ResultV3 $destination $result
    $result
}

function New-VerificationFailureResult([hashtable]$RequestContext,[hashtable]$Failure) {
    # 正常な PreparedRunV3 を作れない場合（または準備後に結果を組み立てられない例外）の VerificationResultV3。照合関数へ無効な準備結果を渡さない。
    # RequestContext: runId・runRoot・sourceRoot（確定していなければ null）、判明していれば pilotInputId/Path/Hash と VM 情報（proposalCreated・proposalStopped・replayCreatedCount・replayAllStopped）。
    # Failure: status（blocked/timed_out/source_changed/incomplete）・stage・reason。未起動は停止未確認事故と区別し、判明済みの作成済み VM の停止未確認だけを incomplete に上げる。
    $status=[string](Get-VerificationValue $Failure 'status');$stage=[string](Get-VerificationValue $Failure 'stage');$reason=[string](Get-VerificationValue $Failure 'reason')
    if($status -cnotin @('blocked','timed_out','source_changed','incomplete') -or [string]::IsNullOrEmpty($stage) -or [string]::IsNullOrEmpty($reason)){throw 'Failure with status (blocked, timed_out, source_changed or incomplete), stage and reason required'}
    $text={param($name) $value=Get-VerificationValue $RequestContext $name;if($value -is [string] -and $value.Length -gt 0){$value}else{$null}}
    $runRoot=& $text 'runRoot'
    if($null -ne $runRoot -and -not([IO.Path]::IsPathFullyQualified($runRoot) -and [IO.Directory]::Exists($runRoot))){$runRoot=$null}
    $hash=& $text 'pilotInputHash'
    if($null -ne $hash -and $hash -notmatch '^[A-Fa-f0-9]{64}$'){$hash=$null}
    $result=New-ResultShell (& $text 'runId') $runRoot $null (& $text 'pilotInputId') (& $text 'pilotInputPath') $hash
    $unverified=[Collections.Generic.List[string]]::new();$unverified.Add("$stage`:$reason")
    $proposalCreated=(Get-VerificationValue $RequestContext 'proposalCreated') -eq $true
    $replayCount=Get-VerificationValue $RequestContext 'replayCreatedCount'
    $replayCount=$(if((($replayCount -is [int]) -or ($replayCount -is [long])) -and $replayCount -gt 0){[int]$replayCount}else{0})
    $result.execution.proposalCreated=$proposalCreated
    $result.execution.replayCreatedCount=$replayCount
    foreach($key in @('proposalStopped','replayAllStopped')){$value=Get-VerificationValue $RequestContext $key;if($value -is [bool]){$result.execution[$key]=$value}}
    if($proposalCreated -and $result.execution.proposalStopped -ne $true){$result.execution.proposalStopped=$false;$unverified.Add('result/proposal-stop:stop-unverified')}
    elseif(-not$proposalCreated -and $result.execution.proposalStopped -eq $true){$result.execution.proposalStopped=$null}
    if($replayCount -gt 0 -and $result.execution.replayAllStopped -ne $true){$result.execution.replayAllStopped=$false;$unverified.Add('result/replay-stop:stop-unverified')}
    elseif($replayCount -eq 0 -and $result.execution.replayAllStopped -eq $true){$result.execution.replayAllStopped=$null}
    $stopUnverified=($result.execution.proposalStopped -eq $false) -or ($result.execution.replayAllStopped -eq $false)
    $result.status=$(if($status -cne 'timed_out' -and $stopUnverified){'incomplete'}else{$status})
    $result.execution.failureStage=$stage
    $result.unverified=[object[]]$unverified.ToArray()
    $result.summary="$($result.status): $stage`:$reason"
    if($null -ne $runRoot){
        # 保存先（作成済みの run の control）がある場合だけ記録する。既存の結果は上書きしない。
        $control=Join-Path $runRoot 'control'
        if([IO.Directory]::Exists($control) -and -not(([IO.DirectoryInfo]::new($control)).Attributes -band [IO.FileAttributes]::ReparsePoint)){Save-ResultV3 (Join-Path $control 'result.json') $result}
    }
    $result
}
Export-ModuleMember -Function Complete-VerificationRun,New-VerificationFailureResult
