# 隔離検証 v3 の共通CLI。準備（RequestCopy）→ pilot 排他 → 提案（Proposal）→ 再実行（Replay）→ 照合（Result）の順序だけを調整する。
# 使い方:
#   pwsh -NoProfile -File Invoke-IsolatedVerification.ps1 -RequestPath <json> -SettingsPath <json>
#     stdout に VerificationResultV3 の JSON 1件（1行）、stderr に診断。終了値は status=completed なら観測分類の 0/1、それ以外は 2。
#   pwsh -NoProfile -File Invoke-IsolatedVerification.ps1 -StopRecorded -RunRoot <path> -SettingsPath <json>
#     復旧操作（ADR-0194）。VMを作らず、control/runtime の作成記録にあるVMだけを停止・確認し、recovery-result の JSON を stdout に返す。
#     終了値は全対象 stopped（記録0件を含む）で 0、それ以外 2。入力・排他の拒否では stdout に何も書かない。
# 設計上の約束:
# - 各モジュールは -Force なしで1回だけ読み込む。Lease（名前付き Mutex）は SbxRuntime のモジュール状態にあり、別インスタンスを読み込むと
#   Proposal・Replay の New-VerificationSandbox から Lease が見えなくなるため（計画の制約。CliV3 の正常往復が失敗して検出する）。
# - 分岐は status・creationState・stopState とファイルの存否で行い、reason の符号では分岐しない。
# - 全体期限（壁時計の deadlineAt）に達した後は、SbxRuntime が照会・作成・搬入・実行の起動を拒否し、Proposal・Replay は VM を作らず timed_out の型付き結果を返す。
#   CLI はその結果も照合へ渡す（失敗結果で打ち切らない）。停止だけ停止フェーズの予算（台数分）で行う。単調時計（Stopwatch）は到達の診断と例外時の status に使う。
# - clipboard の読取・退避・復元・消去はしない。
[CmdletBinding()]
param(
    [string]$RequestPath,
    [string]$SettingsPath,
    [switch]$StopRecorded,
    [string]$RunRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
# stdout は結果 JSON 1件だけにする。日本語を含む診断・パスを壊さないよう UTF-8（BOM なし）で書く。
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$script:AcceptedLimitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
$script:FailureStatuses=@('blocked','timed_out','source_changed','incomplete')
$script:SandboxRoles=@('proposal','replay-before','replay-after')
$script:JsonWritten=$false

function Write-Diagnostic([string]$Text) { [Console]::Error.WriteLine($Text) }
function Get-OneLine([string]$Text) {
    # 例外メッセージを結果の理由文字列と stderr の1行に収める（改行を空白へ、長さを制限）。
    $line=([regex]::Replace([string]$Text,'\s+',' ')).Trim()
    if($line.Length -gt 400){$line=$line.Substring(0,400)+'...'}
    $line
}
function Format-CliFailure($Result) {
    # 上流の {stage, reason}（無ければ空）を診断の1語にする。
    $failure=Get-VerificationValue $Result 'failure'
    if($null -eq $failure){return ''}
    " failure=$(Get-VerificationValue $failure 'stage'):$(Get-VerificationValue $failure 'reason')"
}
function Write-JsonOut($Object) {
    $script:JsonWritten=$true
    [Console]::Out.Write((ConvertTo-VerificationCanonicalJson $Object)+"`n")
    [Console]::Out.Flush()
}
function Read-CliJson([string]$Path,[string]$Label) {
    # 入力 JSON: 厳格 UTF-8 → 重複キー検査 → オブジェクト。日時らしい文字列を DateTime にしない。
    if([string]::IsNullOrWhiteSpace($Path)){throw "$Label path is required"}
    $full=[IO.Path]::GetFullPath($Path)
    if(-not[IO.File]::Exists($full)){throw "$Label file is missing: $full"}
    $json=[IO.File]::ReadAllText($full,[Text.UTF8Encoding]::new($false,$true))
    if(Test-VerificationJsonDuplicateKeys $json){throw "$Label has duplicate keys: $full"}
    $value=ConvertFrom-Json -InputObject $json -AsHashtable -Depth 32 -DateKind String
    if($value -isnot [hashtable]){throw "$Label must be a JSON object: $full"}
    $value
}
function Write-StartDiagnostics([string]$KnownRunRoot) {
    # 開始時の表示。runRoot を最初の行に置き、結果 JSON が返らなくても復旧操作に必要なパスが分かるようにする。
    Write-Diagnostic ('runRoot: '+$(if([string]::IsNullOrEmpty($KnownRunRoot)){'(作成されていない)'}else{$KnownRunRoot}))
    Write-Diagnostic 'scope: synthetic-pilot'
    Write-Diagnostic ('acceptedLimitations: '+($script:AcceptedLimitations -join ', '))
    Write-Diagnostic '注意: 実行中・直後は clipboard の文字列が書き換わりうる。貼り付ける内容は信頼できる元からコピーし直すこと（このCLIは clipboard を読取・退避・復元・消去しない）。'
}

# ---- 復旧操作（-StopRecorded） ----
function Invoke-CliStopRecorded {
    Write-Diagnostic ('runRoot: '+$RunRoot)
    if(-not[string]::IsNullOrEmpty($RequestPath)){throw '-StopRecorded does not take -RequestPath'}
    if([string]::IsNullOrWhiteSpace($RunRoot)){throw '-StopRecorded requires -RunRoot'}
    $settings=Read-CliJson $SettingsPath 'settings'
    # SettingsV3 でも縮約入力でも、入力にある schemaVersion・sbxPath・pwshPath・runsRoot・limits だけを取り出して recovery-input.schema.json で検査する。
    # schemaVersion は補わない（欠落した入力を v3 として受けない）。他のキー（model・profile パス等）は復旧操作に使わない。
    $recovery=@{}
    foreach($key in @('schemaVersion','sbxPath','pwshPath','runsRoot','limits')){if($settings.ContainsKey($key)){$recovery[$key]=$settings[$key]}}
    $errors=$null
    if(-not(Test-Json -Json ($recovery | ConvertTo-Json -Depth 10) -SchemaFile (Join-Path $PSScriptRoot 'recovery-input.schema.json') -ErrorAction SilentlyContinue -ErrorVariable errors)){
        $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
        throw "recovery input does not satisfy recovery-input.schema.json: $detail"
    }
    $result=Stop-VerificationRecordedSandboxes $RunRoot $recovery
    $targets=@($result.targets)
    Write-Diagnostic "recovery: daemonRunning=$($result.daemonRunning) targetCount=$($result.targetCount)"
    foreach($target in $targets){Write-Diagnostic "recovery: $($target.name) ($($target.id)) stateBefore=$($target.stateBefore) stopState=$($target.stopState)"}
    $allStopped=($targets.Count -eq [int]$result.targetCount) -and (@($targets | Where-Object {$_.stopState -cne 'stopped'}).Count -eq 0)
    if(-not$allStopped){Write-Diagnostic 'recovery: 停止を確認できないVMがある。デーモンが停止中なら利用者が通常端末で起動してから再実行する。残置VMの後片付けは利用者承認の sbx rm で行う。'}
    Write-JsonOut $result
    if($allStopped){0}else{2}
}

# ---- 通常の実行 ----
function Get-CliRecordedRoles([string]$ControlRoot) {
    # 作成記録（id 確定時に SbxRuntime が書く control/runtime/<role>-sandbox.json）がある役割。作成済み VM の正本。
    $roles=@{}
    if([string]::IsNullOrEmpty($ControlRoot)){return $roles}
    foreach($role in $script:SandboxRoles){
        $path=Join-Path $ControlRoot "runtime/$role-sandbox.json"
        if([IO.File]::Exists($path)){
            try{$roles[$role]=Read-CliJson $path "$role sandbox record"}
            catch{$roles[$role]=$null;Write-Diagnostic "stop: $role の作成記録を読めない（$path）: $(Get-OneLine $_.Exception.Message)"}
        }
    }
    $roles
}
function Get-CliContext([hashtable]$Prepared,$Proposal,$Replay,[hashtable]$StopRetry) {
    # 失敗結果の RequestContext。runId/runRoot/sourceRoot と固定入力、判明済みの VM 情報（結果の handle と停止状態、無ければ作成記録）を載せる。
    $context=@{runId=[string]$Prepared.runId;runRoot=[string]$Prepared.runRoot;sourceRoot=[string]$Prepared.sourceRoot;pilotInputId=$Prepared.pilotInputId;pilotInputPath=$Prepared.pilotInputPath;pilotInputHash=$Prepared.pilotInputHash}
    $recorded=Get-CliRecordedRoles ([string]$Prepared.controlRoot)
    $proposalSandbox=Get-VerificationValue $Proposal 'sandbox'
    if($null -ne $proposalSandbox -or $recorded.ContainsKey('proposal')){
        $context.proposalCreated=$true
        $stopped=([string](Get-VerificationValue $Proposal 'stopState') -ceq 'stopped') -or ($StopRetry.ContainsKey('proposal') -and $StopRetry['proposal'] -ceq 'stopped')
        $context.proposalStopped=$stopped
    }
    $replayHandles=@(Get-VerificationValue $Replay 'sandboxes' | Where-Object {$null -ne $_})
    $handleRoles=@($replayHandles | ForEach-Object {[string](Get-VerificationValue $_ 'role')})
    $replayRoles=@(foreach($role in @('replay-before','replay-after')){if($recorded.ContainsKey($role) -or $handleRoles -ccontains $role){$role}})
    if($replayRoles.Count -gt 0){
        $context.replayCreatedCount=$replayRoles.Count
        $reported=(Get-VerificationValue $Replay 'allStopped') -eq $true -and $replayHandles.Count -eq $replayRoles.Count
        $retried=@($replayRoles | Where-Object {$StopRetry.ContainsKey($_) -and $StopRetry[$_] -ceq 'stopped'}).Count -eq $replayRoles.Count
        $context.replayAllStopped=($reported -or $retried)
    }
    $context
}
function Test-CliDeadline([Diagnostics.Stopwatch]$Watch,[hashtable]$Prepared) {
    # 単調時計での全体期限（startedAt を確定した時点から totalSeconds）。壁時計の deadlineAt 到達も到達とみなす（どちらか早い方）。
    ($Watch.Elapsed.TotalSeconds -ge [double]$Prepared.settings.limits.totalSeconds) -or (Test-VerificationDeadlineReached ([string]$Prepared.deadlineAt))
}
function Get-CliLastStopState([string]$ControlRoot,[string]$Role,$Record) {
    # SbxRuntime が停止ごとに書く control/runtime/<role>-stop-<UTC時刻>.json のうち、名前の時刻順で最後の、同じ runId・name・id の証拠の stopState（無ければ $null）。
    $dir=Join-Path $ControlRoot 'runtime'
    if(-not[IO.Directory]::Exists($dir)){return $null}
    foreach($file in @(Get-ChildItem -LiteralPath $dir -File -Filter "$Role-stop-*.json" | Sort-Object Name -Descending)){
        try{$evidence=Read-CliJson $file.FullName 'stop evidence'}catch{Write-Diagnostic "stop: 停止証拠を読めない（$($file.FullName)）: $(Get-OneLine $_.Exception.Message)";continue}
        if([string](Get-VerificationValue $evidence 'runId') -ceq [string]$Record.runId -and [string](Get-VerificationValue $evidence 'name') -ceq [string]$Record.name -and [string](Get-VerificationValue $evidence 'id') -ceq [string]$Record.id){return [string](Get-VerificationValue $evidence 'stopState')}
    }
    $null
}
function Invoke-CliStopPhase([hashtable]$Prepared,$Proposal,$Replay) {
    # 作成済み VM の停止確認。停止を確認できていない VM（作成記録があり、結果が stopped と言っていないもの）だけを対象に、
    # 停止フェーズの予算（現在時刻 + cleanupSeconds × 対象台数）を1回組み、Stop-VerificationSandbox を再試行する。停止確認済みの handle へは SbxRuntime が何も発行しない。
    $outcome=@{}
    $recorded=Get-CliRecordedRoles ([string]$Prepared.controlRoot)
    $targets=[Collections.Generic.List[hashtable]]::new()
    foreach($role in $script:SandboxRoles){
        if(-not$recorded.ContainsKey($role)){continue}
        if($role -ceq 'proposal'){
            if([string](Get-VerificationValue $Proposal 'stopState') -ceq 'stopped'){continue}
        }else{
            $handleRoles=@(Get-VerificationValue $Replay 'sandboxes' | Where-Object {$null -ne $_} | ForEach-Object {[string](Get-VerificationValue $_ 'role')})
            if((Get-VerificationValue $Replay 'allStopped') -eq $true -and $handleRoles -ccontains $role){continue}
        }
        $record=$recorded[$role]
        if($null -eq $record){$outcome[$role]='unverified';Write-Diagnostic "stop: $role の作成記録を読めない。復旧操作で確認する";continue}
        # 再実行の allStopped=false は役割ごとの停止状態を持たないので、当該 VM の最後の停止証拠が stopped の役割は対象から外し、未確認の台数だけで予算を組む。
        if($role -cne 'proposal' -and (Get-CliLastStopState ([string]$Prepared.controlRoot) $role $record) -ceq 'stopped'){continue}
        $targets.Add(@{role=$role;handle=@{runId=[string]$record.runId;role=$role;name=[string]$record.name;id=[string]$record.id}})
    }
    if($targets.Count -eq 0){return $outcome}
    $budget=New-VerificationCleanupBudget $Prepared $targets.Count
    Write-Diagnostic "stop: 停止未確認の VM $($targets.Count) 台を停止フェーズの予算（cleanupDeadlineAt=$($budget.cleanupDeadlineAt)）で再確認する"
    foreach($target in $targets){
        try{
            $stop=Stop-VerificationSandbox $target.handle $budget
            $outcome[$target.role]=[string]$stop.stopState
            Write-Diagnostic "stop: $($target.handle.name) stopState=$($stop.stopState)$(if($stop.reason){' ('+(Get-OneLine $stop.reason)+')'})"
        }catch{
            $outcome[$target.role]='unverified'
            Write-Diagnostic "stop: $($target.handle.name) の停止を再試行できない: $(Get-OneLine $_.Exception.Message)"
        }
    }
    $outcome
}
function Invoke-CliRun {
    $failure=$null;$context=@{};$prepared=$null
    # 1. 入力読込（重複キー検査）。v3 以外（v1・未実装 v2・文字列の "3"）は準備に渡さない（New-VerificationRun の v1 経路で run を作らせない）。
    try{
        if(-not[string]::IsNullOrEmpty($RunRoot)){throw '-RunRoot is only used with -StopRecorded'}
        $request=Read-CliJson $RequestPath 'request'
        $settings=Read-CliJson $SettingsPath 'settings'
        foreach($pair in @(@('request',$request),@('settings',$settings))){
            $version=$(if($pair[1].ContainsKey('schemaVersion')){$pair[1].schemaVersion}else{$null})
            if(-not(($version -is [int]) -or ($version -is [long])) -or $version -ne 3){throw "$($pair[0]) schemaVersion must be integer 3 (this CLI accepts v3 only)"}
        }
    }catch{
        Write-StartDiagnostics $null
        Write-Diagnostic "error: input: $(Get-OneLine $_.Exception.Message)"
        return @{result=(New-VerificationFailureResult @{} @{status='blocked';stage='input';reason=('input-invalid: '+(Get-OneLine $_.Exception.Message))})}
    }
    # 2. startedAt を確定し、同時に単調時計を始める（準備時間も全体期限に含める）。
    $startedAt=Get-VerificationUtcNow
    $watch=[Diagnostics.Stopwatch]::StartNew()
    try{$prepared=New-VerificationRun $request $settings $startedAt}
    catch{
        $data=$_.Exception.Data
        $failedRunRoot=$(if($data.Contains('runRoot')){[string]$data['runRoot']}else{$null})
        Write-StartDiagnostics $failedRunRoot
        Write-Diagnostic "error: preparation: $(Get-OneLine $_.Exception.Message)"
        $status=$(if($data.Contains('status') -and [string]$data['status'] -cin $script:FailureStatuses){[string]$data['status']}else{'blocked'})
        $stage=$(if($data.Contains('stage') -and -not[string]::IsNullOrEmpty([string]$data['stage'])){[string]$data['stage']}else{'preparation'})
        $failedContext=@{runRoot=$failedRunRoot;runId=$(if($failedRunRoot){[IO.Path]::GetFileName($failedRunRoot)}else{$null})}
        return @{result=(New-VerificationFailureResult $failedContext @{status=$status;stage=$stage;reason=('preparation-failed: '+(Get-OneLine $_.Exception.Message))})}
    }
    Write-StartDiagnostics ([string]$prepared.runRoot)
    Write-Diagnostic "startedAt: $($prepared.startedAt) deadlineAt: $($prepared.deadlineAt) totalSeconds: $($prepared.settings.limits.totalSeconds)"
    $context=Get-CliContext $prepared $null $null @{}
    $recheck=@($prepared.recheckArtifacts | Where-Object {$null -ne $_}).Count -gt 0
    # 期限に達していても準備後は失敗結果で打ち切らず、提案・再実行の型付き結果（VM を作らない timed_out）を照合へ渡す（仕様00「not_runの型付き結果を作って照合へ渡す」）。
    if(Test-CliDeadline $watch $prepared){Write-Diagnostic 'deadline: 準備の間に全体期限に到達した。以降は VM を作らず、時間超過の結果を照合へ渡す'}
    # 3. 実行設定の検査（replay は常に、proposal は recheck でないとき）。VM 作成前に拒否する。
    $proposalProfile=$null;$replayProfile=$null
    try{
        $replayProfile=Read-CliJson ([string]$prepared.settings.replayProfilePath) 'replay profile'
        [void](Test-VerificationRuntimeProfile $replayProfile 'replay-before' $prepared.settings)
        if(-not$recheck){
            $proposalProfile=Read-CliJson ([string]$prepared.settings.proposalProfilePath) 'proposal profile'
            [void](Test-VerificationRuntimeProfile $proposalProfile 'proposal' $prepared.settings)
        }
    }catch{
        Write-Diagnostic "error: profile: $(Get-OneLine $_.Exception.Message)"
        return @{result=(New-VerificationFailureResult $context @{status='blocked';stage='profile';reason=('profile-rejected: '+(Get-OneLine $_.Exception.Message))})}
    }
    # 4. pilot 排他（通常提案と recheck の両方）。競合・デーモン停止は VM を作らず blocked。
    #    期限到達で照会を起動できなかった場合（status=timed_out）だけは Lease なしで先へ進み、期限後の Proposal・Replay が VM を作らずに返す timed_out の結果を照合する。
    $lease=$null
    try{$lease=Acquire-VerificationPilotLease $prepared}
    catch{
        $data=$_.Exception.Data
        Write-Diagnostic "error: lease: $(Get-OneLine $_.Exception.Message)"
        $status=$(if($data.Contains('status') -and [string]$data['status'] -cin $script:FailureStatuses){[string]$data['status']}else{'blocked'})
        if($status -cne 'timed_out'){
            $code=$(if($data.Contains('reason') -and -not[string]::IsNullOrEmpty([string]$data['reason'])){[string]$data['reason']}else{'lease-failed'})
            return @{result=(New-VerificationFailureResult $context @{status=$status;stage='lease';reason=("$code`: "+(Get-OneLine $_.Exception.Message))})}
        }
        Write-Diagnostic 'pilot lease: 全体期限に達したため取得しない。VM を作らない時間超過の結果を照合へ渡す'
    }
    if($null -ne $lease){Write-Diagnostic "pilot lease: 取得した（leaseId=$($lease.leaseId)）"}
    $proposal=$null;$replay=$null;$result=$null;$phase='proposal';$stopRetry=@{};$stopPhaseFailed=$false
    try{
        try{
            # 5. 提案。recheck では VM・モデルを起動しない（Proposal が判断する）。
            $proposal=Invoke-VerificationProposal $prepared $proposalProfile $lease
            Write-Diagnostic "proposal: status=$($proposal.status) stopState=$($proposal.stopState)$(Format-CliFailure $proposal)"
            # 敵対的な wire の検査（最大約30秒）の後で期限に達していても、再実行は呼ぶ（期限後の Replay は VM を作らず timed_out を返す）。ここでは診断だけ出す。
            if([string]$proposal.status -ceq 'ready' -and (Test-CliDeadline $watch $prepared)){Write-Diagnostic 'deadline: 提案の後に全体期限に到達した。再実行は VM を作らず時間超過を返す'}
            # 6. 再実行（提案が ready のときだけ）。それ以外は not_run の型付き結果を作る。
            $phase='replay'
            if([string]$proposal.status -ceq 'ready'){
                $replay=Invoke-VerificationReplay $prepared $proposal $replayProfile $lease
                Write-Diagnostic "replay: status=$($replay.status) allStopped=$($replay.allStopped)$(Format-CliFailure $replay)"
            }else{
                $upstreamFailure=Get-VerificationValue $proposal 'failure'
                $upstream=@{stage=[string](Get-VerificationValue $upstreamFailure 'stage');reason=[string](Get-VerificationValue $upstreamFailure 'reason')}
                # 提案VMの作成成否が不明（handle なし・停止未確認）なら not_run へ丸めない（Replay の約束）。
                if($null -eq $proposal.sandbox -and [string]$proposal.stopState -ceq 'unverified'){$upstream.creationState='unknown'}
                $replay=New-VerificationReplayNotRun $prepared $upstream
                Write-Diagnostic "replay: 実行しない（提案が ready でない。status=$($replay.status)）"
            }
            # 7. 照合。control/result.json へ一度だけ保存する。
            $phase='result'
            $result=Complete-VerificationRun $prepared $proposal $replay
        }catch{
            Write-Diagnostic "error: $phase`: $(Get-OneLine $_.Exception.Message)"
            $failure=@{status=$(if(Test-CliDeadline $watch $prepared){'timed_out'}else{'incomplete'});stage=$phase;reason=("$phase-error: "+(Get-OneLine $_.Exception.Message))}
        }
    }finally{
        # 8. 作成済み VM の停止確認と Lease の解放（途中の例外でも必ず行う）。
        try{$stopRetry=Invoke-CliStopPhase $prepared $proposal $replay}catch{$stopPhaseFailed=$true;Write-Diagnostic "stop: 停止確認に失敗した: $(Get-OneLine $_.Exception.Message)"}
        if($null -ne $lease){try{Release-VerificationPilotLease $lease;Write-Diagnostic 'pilot lease: 解放した'}catch{Write-Diagnostic "pilot lease: 解放に失敗した: $(Get-OneLine $_.Exception.Message)"}}
    }
    # 停止確認そのものが失敗した場合も、停止を確認できないものとして復旧操作を案内する。
    if($stopPhaseFailed -or @($stopRetry.Values | Where-Object {$_ -cne 'stopped'}).Count -gt 0){
        Write-Diagnostic "recovery: 停止を確認できない VM がある。復旧操作: pwsh -NoProfile -File `"$PSCommandPath`" -StopRecorded -RunRoot `"$($prepared.runRoot)`" -SettingsPath `"$SettingsPath`"。残置VMの後片付けは利用者承認の sbx rm で行う。"
    }
    if($null -ne $result){return @{result=$result}}
    # 9. 準備後に照合結果を組み立てられない場合は、判明済みの VM 情報を足した失敗結果。control/result.json が既にあれば保存を試みない（上書きしない）。
    $context=Get-CliContext $prepared $proposal $replay $stopRetry
    $existing=Join-Path ([string]$prepared.controlRoot) 'result.json'
    if([IO.File]::Exists($existing)){
        Write-Diagnostic "result: control/result.json が既にあるため保存しない（$existing）。stdout の結果だけを返す"
        # New-VerificationFailureResult は runRoot を受けると保存を試みるので null で作り、返す前に作成済みの runRoot（実在するパス）へ戻す（仕様03）。
        $context.runRoot=$null
        $failed=New-VerificationFailureResult $context $failure
        if([IO.Directory]::Exists([string]$prepared.runRoot)){$failed.runRoot=[string]$prepared.runRoot}
        return @{result=$failed}
    }
    @{result=(New-VerificationFailureResult $context $failure)}
}

# ---- 入口 ----
$exitCode=2
try{
    # -Force なしで1回だけ読み込む（SbxRuntime を先に読み、Proposal・Replay・Result の入れ子の読み込みが同じインスタンスを使う）。
    Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')
    Import-Module (Join-Path $PSScriptRoot 'SbxRuntime.psm1') -DisableNameChecking   # Acquire- は仕様02の公開操作名
    Import-Module (Join-Path $PSScriptRoot 'Proposal.psm1')
    Import-Module (Join-Path $PSScriptRoot 'Replay.psm1')
    Import-Module (Join-Path $PSScriptRoot 'Result.psm1')
    if($StopRecorded){
        $exitCode=Invoke-CliStopRecorded
    }else{
        $outcome=Invoke-CliRun
        $result=$outcome.result
        Write-JsonOut $result
        $exitCode=$(if([string]$result.status -ceq 'completed' -and $result.execution.exitCodeForCli -in @(0,1)){[int]$result.execution.exitCodeForCli}else{2})
        Write-Diagnostic "result: status=$($result.status) replayVerdict=$($result.replayVerdict) exit=$exitCode"
    }
}catch{
    Write-Diagnostic "error: $(Get-OneLine $_.Exception.Message)"
    # 通常の実行で結果をまだ書いていなければ、組み立てられる範囲の失敗結果を1件だけ返す（読み込み前の失敗では返せない）。
    if(-not$StopRecorded -and -not$script:JsonWritten){
        try{Write-JsonOut (New-VerificationFailureResult @{} @{status='incomplete';stage='cli';reason=('cli-error: '+(Get-OneLine $_.Exception.Message))})}catch{Write-Diagnostic "error: 失敗結果を組み立てられない: $(Get-OneLine $_.Exception.Message)"}
    }
    $exitCode=2
}
exit $exitCode
