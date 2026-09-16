# タスク8a の probe。個別承認（2026-09-16）を得た「AIなしの実VM 1台」で、再実行・停止・記録の実体を測る。
# 本スクリプトは Invoke-IsolatedVerification.ps1 を通さず、自前の足場 run を作って sbx CLI を固定 argv で直接起動する
# （実装計画「タスク8a: 固定argv直接 / 8b: 公開操作の実証」）。SbxRuntime の VM 作成経路は role=probe を受けないため、
# 作成・搬入・実行はここで組み立て、作成記録の書込み（Write-VerificationSandboxRecord）と復旧停止
# （Stop-VerificationRecordedSandboxes）だけ製品の公開操作を使う。
#
# 取得する観測（各ステップの結果は runRoot/obs/ へ都度書き出す。probe が落ちても -Resume で続けられる）:
#   00-setup           デーモン状態・起動世代・既存VMの一覧・固定 argv での VM 作成・作成記録・セッション保持 exec の開始
#   01-version-stdlib  python3 の版と標準ライブラリ一覧
#   02-input-unittest  合成題材の搬入（cp）・所有者調整（chown）・搬入照合・unittest 1本（要約行の出力ストリームの実測）
#   03-transport       transport 対照5種（終了0・7・127・時間超過・sbx クライアント子プロセスの外側からの強制終了）
#   04-flood           出力洪水の exec 1本が合算出力上限で打ち切られること
#   05-queries         inspect・policy ls・settings get・mcp ls・runtimes/<VM名>.json・daemon.log の当該行
#   06-hold            約30分の連続保持（保持 exec だけで VM が running のまま、自動停止行が出ないこと）
#   07-kill            probe プロセス（CLI 相当）の強制終了。ここで自らを落とす
#   08-resume          -Resume で再開し、保持プロセスの消失・自動停止行・他VM不変を観測してから復旧操作を実行する
#
# 安全側の約束: 既存VM（iv-sbx-capability-20260914-01・iv-sbx-smoke-20260909-01）へは ls --json の一覧読取り以外を発行しない。
# デーモンの起動・停止・再起動・設定変更・VM 削除は行わない。sbx CLI へ渡す環境は明示した最小辞書で、SSH_AUTH_SOCK を含めない。
[CmdletBinding()]
param(
    # 足場の実行設定。recovery-input.schema.json（schemaVersion=3・sbxPath・pwshPath・runsRoot・limits）で検査する。
    [string]$SettingsPath,
    # 中断した probe の runRoot。指定すると未了のステップから続ける（07-kill の自己終了後の観測はこの経路でしか取れない）。
    [string]$Resume,
    # 証拠取得するVMの役割。proposalは個別承認後にだけ実行する。
    [ValidateSet('probe','proposal')][string]$Role='probe',
    # proposalの1台目は停止確認、2台目は異常終了後の復旧確認を取る。
    [ValidateSet('limitsAndTransport','abnormalExitRecovery')][string]$ProposalPhase,
    # 連続保持の秒数（既定は計画の「約30分」）。
    [int]$HoldSeconds=1800,
    # 08-resume で自動停止行を待つ上限（実測の猶予は30秒。余裕を見た既定）。
    [int]$AutoStopWaitSeconds=180
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:VerificationRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Import-Module (Join-Path $script:VerificationRoot 'RequestCopy.psm1') -DisableNameChecking
Import-Module (Join-Path $script:VerificationRoot 'Execution.psm1') -DisableNameChecking
Import-Module (Join-Path $script:VerificationRoot 'SbxRuntime.psm1') -DisableNameChecking

# 既存VM（観測は ls --json の一覧だけ）。名前を持つことで「当該名へコマンドを出していない」検査を calls.jsonl に対して行える。
$script:PreexistingVms=@('iv-sbx-capability-20260914-01','iv-sbx-smoke-20260909-01')
$script:TemplateDigest='docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476'
$script:SourceDestination='/home/agent/workspace/source'   # Replay.psm1 と同じ搬入先
$script:UnittestArgv=[string[]]@('python3','-m','unittest','discover','-s','.verification-tests','-p','test_*.py','-v')
$script:QuerySeconds=60      # SbxRuntime と同じ照会の上限
$script:SetupSeconds=240     # SbxRuntime と同じ作成・搬入・照合の上限
$script:CallSequence=0

# ---- 足場の入出力 ----
function ConvertTo-ProbeJsonSafe($Value) {
    # ConvertFrom-Json は ISO 8601 風の文字列を DateTime へ変換する。正規化JSON（ConvertTo-VerificationCanonicalJson）は
    # DateTime を受けないため、読み込んだ値を再帰的に文字列へ戻してから観測や状態として扱う。
    if($null -eq $Value){return $null}
    if($Value -is [DateTime]){return $Value.ToUniversalTime().ToString('o',[Globalization.CultureInfo]::InvariantCulture)}
    if($Value -is [DateTimeOffset]){return $Value.UtcDateTime.ToString('o',[Globalization.CultureInfo]::InvariantCulture)}
    if($Value -is [string] -or $Value -is [bool] -or $Value -is [decimal] -or $Value.GetType().IsPrimitive){return $Value}
    if($Value -is [Collections.IDictionary]){
        $map=@{}
        foreach($key in @($Value.Keys)){$map[[string]$key]=ConvertTo-ProbeJsonSafe $Value[$key]}
        return $map
    }
    if($Value -is [Collections.IEnumerable]){return ,@(foreach($item in $Value){ConvertTo-ProbeJsonSafe $item})}
    $Value
}
function ConvertFrom-ProbeJsonText([string]$Text) { ConvertTo-ProbeJsonSafe ($Text | ConvertFrom-Json -AsHashtable -Depth 30) }
function Get-VerificationFileHashText([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Read-ProbeSettings([string]$Path) {
    $json=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if(Test-VerificationJsonDuplicateKeys $json){throw "probe settings has duplicate keys: $Path"}
    $settings=ConvertFrom-ProbeJsonText $json
    if($settings -isnot [hashtable]){throw 'probe settings must be a JSON object'}
    $errors=$null
    if(-not(Test-Json -Json ($settings | ConvertTo-Json -Depth 20) -SchemaFile (Join-Path $script:VerificationRoot 'recovery-input.schema.json') -ErrorAction SilentlyContinue -ErrorVariable errors)){
        throw ('probe settings does not match recovery-input.schema.json: '+$(if($errors){$errors[0].Exception.Message}else{'schema violation'}))
    }
    $settings
}
function Save-ProbeState() {
    # 途中経過は毎回書き直す（観測そのものは obs/ の新規ファイルに残す。ここは再開のための索引）。
    $path=Join-Path $script:State.runRoot 'probe-state.json'
    [IO.File]::WriteAllBytes($path,[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-VerificationCanonicalJson $script:State)+"`n"))
}
function Write-ProbeObservation([string]$Name,[hashtable]$Value) {
    # 観測は新規作成でしか書かない（上書きしない）。再開で同名を書こうとした場合は連番を足して両方残す。
    $path=Join-Path $script:State.runRoot ('obs/'+$Name+'.json')
    $retry=1
    while([IO.File]::Exists($path)){$retry++;$path=Join-Path $script:State.runRoot ('obs/'+$Name+'-r'+$retry+'.json')}
    Write-VerificationNewFile $path ((ConvertTo-VerificationCanonicalJson $Value)+"`n")
    Write-Host ("  観測を保存: obs/$Name.json")
    $path
}
function Complete-ProbeStep([string]$Name) {
    if($script:State.completed -notcontains $Name){$script:State.completed=@($script:State.completed)+@($Name)}
    Save-ProbeState
    Write-Host ("ステップ完了: $Name")
}
function Test-ProbeStepDone([string]$Name) { @($script:State.completed) -contains $Name }

# ---- sbx CLI の起動（固定 argv・最小環境辞書） ----
function Get-ProbeSbxEnvironment([string]$SbxPath) {
    # SbxRuntime.psm1 の Get-VerificationSbxEnvironment と同じ辞書。SSH_AUTH_SOCK は渡さない。
    $environment=@{}
    foreach($key in @('SystemRoot','USERPROFILE','LOCALAPPDATA','APPDATA','TEMP')){
        $value=[Environment]::GetEnvironmentVariable($key)
        if([string]::IsNullOrEmpty($value)){throw "host environment variable missing: $key"}
        $environment[$key]=$value
    }
    $environment['PATH']=[IO.Path]::GetDirectoryName($SbxPath)
    $environment
}
function New-ProbeStartInfo([string[]]$Argv) {
    $start=[Diagnostics.ProcessStartInfo]::new($script:State.sbxPath)
    $start.WorkingDirectory=$script:State.runRoot;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.Environment.Clear();foreach($key in $script:SbxEnvironment.Keys){$start.Environment[$key]=$script:SbxEnvironment[$key]}
    foreach($arg in $Argv){$start.ArgumentList.Add($arg)}
    $start
}
function New-ProbeBudget([int]$CommandSeconds,[long]$MaxOutputBytes) {
    @{deadlineAt=$script:State.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=$MaxOutputBytes;commandSeconds=$CommandSeconds};phase='work'}
}
function Add-ProbeCall([string[]]$Argv,[string]$Tag,[string]$IssuedAt,[hashtable]$Result) {
    # 発行した sbx 呼び出しをすべて追記する。「停止確認後に当該VM名へコマンドを出していない」の検査はこの記録に対して行う。
    $line=(ConvertTo-VerificationCanonicalJson @{seq=$script:CallSequence;tag=$Tag;argv=@($Argv);issuedAt=$IssuedAt;exitCode=$Result.exitCode;started=$Result.started;timedOut=$Result.timedOut;outputExceeded=$Result.outputExceeded;refusedReason=$Result.refusedReason})+"`n"
    [IO.File]::AppendAllText((Join-Path $script:State.runRoot 'calls.jsonl'),$line,[Text.UTF8Encoding]::new($false))
}
function Read-ProbeText([string]$Path,[int]$MaxChars=4000) {
    if(-not[IO.File]::Exists($Path)){return ''}
    $text=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if($text.Length -gt $MaxChars){return $text.Substring(0,$MaxChars)+"`n…(truncated)"}
    $text
}
function Invoke-ProbeSbx([string[]]$Argv,[int]$Seconds,[string]$Tag,[long]$MaxOutputBytes=0,[byte[]]$StdinBytes=$null) {
    # sbx CLI を1回起動する。出力は runRoot/cli/ に連番で残し、要旨を戻り値に載せる。
    if($MaxOutputBytes -le 0){$MaxOutputBytes=[long]$script:State.limits.maxOutputBytes}
    $script:CallSequence++
    $base=Join-Path $script:State.runRoot ('cli/{0:D3}-{1}' -f $script:CallSequence,$Tag)
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($base))
    $paths=@{stdoutPath=$base+'.out';stderrPath=$base+'.err'}
    $issuedAt=Get-VerificationUtcNow
    $result=Invoke-VerificationProcessV3 -StartInfo (New-ProbeStartInfo $Argv) -StdinBytes $StdinBytes -OutputPaths $paths -RunBudget (New-ProbeBudget $Seconds $MaxOutputBytes)
    Add-ProbeCall $Argv $Tag $issuedAt $result
    @{argv=@($Argv);tag=$Tag;issuedAt=$issuedAt;finishedAt=$result.finishedAt;started=$result.started;refusedReason=$result.refusedReason;exitCode=$result.exitCode
      timedOut=$result.timedOut;outputExceeded=$result.outputExceeded;processTreeStopped=$result.processTreeStopped
      stdoutPath=$paths.stdoutPath;stderrPath=$paths.stderrPath;stdoutBytes=$result.stdoutBytes;stderrBytes=$result.stderrBytes
      stdout=(Read-ProbeText $paths.stdoutPath);stderr=(Read-ProbeText $paths.stderrPath)}
}
function Assert-ProbeSbxOk([hashtable]$Call) {
    if(-not($Call.started -and $null -eq $Call.refusedReason -and -not$Call.timedOut -and -not$Call.outputExceeded -and $Call.exitCode -eq 0)){
        throw ("sbx $($Call.tag) failed: exit=$($Call.exitCode) started=$($Call.started) refused=$($Call.refusedReason) timedOut=$($Call.timedOut) outputExceeded=$($Call.outputExceeded) stderr=$($Call.stderr.Trim())")
    }
    $Call
}
function Invoke-ProbeSbxJson([string[]]$Argv,[string]$Tag) {
    $call=Assert-ProbeSbxOk (Invoke-ProbeSbx $Argv $script:QuerySeconds $Tag)
    $value=ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($call.stdoutPath,[Text.UTF8Encoding]::new($false)))
    @{call=$call;value=$value}
}
function Invoke-ProbeVmExec([string[]]$Argv,[int]$Seconds,[string]$Tag,[long]$MaxOutputBytes=0) {
    # 実コマンドは exec -w <作業ディレクトリ> <VM名> <argv…> に固定する（SbxRuntime の Invoke-VerificationSandboxCommand と同じ形）。
    Invoke-ProbeSbx (@('exec','-w',$script:SourceDestination,$script:State.name)+$Argv) $Seconds $Tag $MaxOutputBytes
}

# ---- daemon.log と状態ディレクトリ ----
function Get-ProbeRuntimeLogLines([string]$Contains) {
    $stream=[IO.File]::Open($script:State.logPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try{$reader=[IO.StreamReader]::new($stream,[Text.UTF8Encoding]::new($false));$text=$reader.ReadToEnd()}finally{$stream.Dispose()}
    $lines=[Collections.Generic.List[hashtable]]::new()
    foreach($raw in $text.Split("`n")){
        $line=$raw.TrimEnd("`r")
        if(-not$line.Contains($Contains)){continue}
        try{$item=$line | ConvertFrom-Json -AsHashtable -ErrorAction Stop}catch{continue}
        if($item -isnot [hashtable] -or -not$item.ContainsKey('msg')){continue}
        $time=$null
        if($item.ContainsKey('time') -and $item.time -is [string]){try{$time=[DateTimeOffset]::Parse($item.time,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}catch{}}
        elseif($item.ContainsKey('time') -and $item.time -is [DateTime]){$time=$item.time.ToUniversalTime()}
        $lines.Add(@{msg=[string]$item.msg;time=$(if($null -ne $time){$time.ToString('o',[Globalization.CultureInfo]::InvariantCulture)}else{$null});runtime=$(if($item.ContainsKey('runtime')){[string]$item.runtime}else{$null});version=$(if($item.ContainsKey('version')){[string]$item.version}else{$null});raw=$line})
    }
    ,@($lines.ToArray())
}
function Get-ProbeVmLogLines() {
    ,@((Get-ProbeRuntimeLogLines $script:State.name) | Where-Object {$null -eq $_.runtime -or $_.runtime -ceq $script:State.name})
}
function Test-ProbeAutoStopped() {
    # 作成後の自動停止行（安全規則: 見つかったら当該VMの観測は捨てて報告する）。
    $since=[DateTimeOffset]::Parse($script:State.createdAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
    @((Get-ProbeVmLogLines) | Where-Object {$_.msg -ceq 'auto-stopped runtime after last session disconnected' -and $null -ne $_.time -and ([DateTimeOffset]::Parse($_.time,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime) -ge $since})
}
function Assert-ProbeNoAutoStop([string]$Where) {
    $lines=Test-ProbeAutoStopped
    if(@($lines).Count -gt 0){
        [void](Write-ProbeObservation ('abandoned-autostop-'+$Where) @{where=$Where;checkedAt=(Get-VerificationUtcNow);lines=@($lines)})
        throw "auto-stopped runtime が daemon.log に現れた（$Where）。計画の規則により当該VMの観測を中止する。新しい runId/runRoot での再実施は主担当の判断を待つこと。"
    }
}
function Get-ProbeDaemonInstance() {
    # daemon status → 状態ディレクトリ → sandboxd.pid・starting sandboxd 行・プロセスの StartTime。
    $status=(Invoke-ProbeSbxJson @('daemon','status','--json') 'daemon-status').value
    if($status.status -cne 'running'){throw 'sbx daemon is not running: 利用者が通常端末でデーモンを起動する必要がある（probe は起動しない）'}
    $logPath=[IO.Path]::GetFullPath($status.logs)
    $stateRoot=[IO.Path]::GetDirectoryName($logPath)
    $daemonPid=[int]([IO.File]::ReadAllText((Join-Path $stateRoot 'sandboxd.pid')).Trim())
    $script:State.logPath=$logPath;$script:State.stateRoot=$stateRoot
    $startLines=@((Get-ProbeRuntimeLogLines 'starting sandboxd') | Where-Object {$_.msg -ceq 'starting sandboxd'})
    if($startLines.Count -eq 0){throw 'starting sandboxd line missing in daemon.log'}
    $process=Get-Process -Id $daemonPid -ErrorAction Stop
    @{pid=$daemonPid;startedAt=$process.StartTime.ToUniversalTime().ToString('o',[Globalization.CultureInfo]::InvariantCulture);version=[string]$startLines[-1].version;socket=[string]$status.socket;logs=$logPath;startLine=$startLines[-1].raw}
}
function Get-ProbeSandboxList() {
    $list=(Invoke-ProbeSbxJson @('ls','--json') 'ls').value
    ,@(foreach($item in @($list.sandboxes)){@{name=[string]$item.name;id=[string]$item.id;status=[string]$item.status}})
}

# ---- 出力の型（transport 対照の stderrKind） ----
function Get-ProbeStderrKind([hashtable]$Call) {
    $text=$Call.stderr.Trim()
    if($Call.timedOut -or -not$Call.started){return $(if($text.Length -eq 0){'none-client-killed-by-outside'}else{'client-message-after-outside-stop'})}
    if($text.Length -eq 0){return 'empty'}
    if($text -match 'not found'){return 'shell-not-found'}
    'command-message'
}

# =====================================================================
# ステップ本体
# =====================================================================
function Invoke-ProbeSetup() {
    Write-Host '=== 00-setup: デーモン確認・VM 作成・保持セッション ==='
    $daemon=Get-ProbeDaemonInstance
    $script:State.daemon=$daemon
    if($null -ne $script:State.id){
        # 作成済みの VM がある再開。承認は1台だけなので二重に作らない（保持セッションだけ張り直す）。
        Write-Host "  作成済みの VM を引き継ぐ: $($script:State.name) / $($script:State.id)"
        Start-ProbeKeepAlive
        [void](Write-ProbeObservation '00-setup' @{checkedAt=(Get-VerificationUtcNow);daemon=$daemon;resumedExistingVm=$true;name=$script:State.name;id=$script:State.id;keepAlive=$script:State.keepAlive})
        Complete-ProbeStep '00-setup'
        return
    }
    $before=Get-ProbeSandboxList
    foreach($vm in $before){
        if($vm.name -ceq $script:State.name){throw "sandbox name already exists: $($script:State.name)"}
        if($vm.status -cne 'stopped'){throw "another sandbox is not stopped: $($vm.name) ($($vm.status))"}
    }
    # デーモン単位の設定（VM 作成前に見る値）。ssh.agentSocketPath と ssh.agentForwardingEnabled は 05-queries で改めて記録する。
    $clipboard=(Invoke-ProbeSbxJson @('settings','get','--json','clipboard.imagePaste') 'settings-clipboard').value
    if($clipboard.value -ne $false){throw 'clipboard.imagePaste must be false'}
    $mcp=(Invoke-ProbeSbxJson @('mcp','ls','--json') 'mcp-ls').value
    if(@($mcp.servers).Count -ne 0){throw 'mcp ls --json must list no servers'}
    # 固定 argv は役割別。提案用は承認された2件以外のキット宣言先11件を作成時に拒否する。
    $agent=$(if($script:State.role -ceq 'proposal'){'codex'}else{'shell'})
    $createArgv=Get-VerificationCreateArgv $agent $script:State.name $script:TemplateDigest
    $script:State.createdAt=Get-VerificationUtcNow
    $create=Invoke-ProbeSbx $createArgv $script:SetupSeconds 'create'
    $after=Get-ProbeSandboxList
    $found=@($after | Where-Object {$_.name -ceq $script:State.name})
    if($found.Count -ne 1){throw "create did not produce exactly one listed sandbox (exit $($create.exitCode)): $($create.stderr.Trim())"}
    $script:State.id=$found[0].id
    $script:State.callSequence=$script:CallSequence
    Save-ProbeState   # 作成した ID を直ちに記録する（以後の失敗でも二重作成せずに引き継げる）
    Assert-ProbeSbxOk $create | Out-Null
    if($found[0].status -cne 'running'){throw "created sandbox is not running: $($found[0].status)"}
    # 作成記録は製品の公開操作で書く（復旧操作 Stop-VerificationRecordedSandboxes がこの記録の runId・name・id を正本にする）。
    $handle=@{runId=$script:State.runId;role=$script:State.role;name=$script:State.name;id=$script:State.id;createdAt=$script:State.createdAt;profileHash=$null;effectiveSettingsHash=$null;activationRecordPath=$null;activationRecordHash=$null}
    $recordPath=Write-VerificationSandboxRecord $script:State.runRoot $handle
    $script:State.sandboxRecordPath=$recordPath
    if($script:State.role -ceq 'proposal'){
        $startupInspect=Invoke-ProbeSbxJson @('inspect',$script:State.name,'--json') 'startup-inspect'
        if(-not$startupInspect.value.ContainsKey('sessions') -or ($startupInspect.value.sessions -isnot [int] -and $startupInspect.value.sessions -isnot [long])){throw 'startup inspect lacks integer sessions'}
        # cmd.exe経由のsbxにも1引数として届くよう、Pythonのプログラムは改行のない1文字列にする。
        $processProgram='import json,pathlib; names=[]; exec("for p in pathlib.Path(\"/proc\").glob(\"[0-9]*/comm\"):\n try:\n  names.append(p.read_text().strip())\n except OSError:\n  pass"); print(json.dumps({"codexProcessCount":sum(1 for name in names if name=="codex")}))'
        $processCall=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','-c',$processProgram) $script:QuerySeconds 'startup-processes')
        $processResult=ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($processCall.stdoutPath,[Text.UTF8Encoding]::new($false)))
        if($processResult -isnot [hashtable] -or -not$processResult.ContainsKey('codexProcessCount') -or ($processResult.codexProcessCount -isnot [int] -and $processResult.codexProcessCount -isnot [long])){throw 'startup process probe lacks integer count'}
        $startup=@{checkedAt=(Get-VerificationUtcNow);createdAt=$script:State.createdAt;createExitCode=$create.exitCode;createStdout=$create.stdout;createStderr=$create.stderr
            inspectState=[string]$startupInspect.value.state;inspectSessions=$startupInspect.value.sessions;codexProcessCount=$processResult.codexProcessCount;processProbeStarted=$true
            daemonLog=@(Get-ProbeVmLogLines | ForEach-Object {@{time=$_.time;msg=$_.msg;runtime=$_.runtime}});callsPath=(Join-Path $script:State.runRoot 'calls.jsonl');lastCallSequence=$script:CallSequence
            interpretation='作成直後の観測時点で稼働中のcodexプロセスを調べる。過去全域の未起動は主張しない。'}
        [void](Write-ProbeObservation '00-startup' $startup)
        if(-not(Test-ProbeStartupObservation $startup)){throw 'proposal agent was active before input or startup observation was incomplete'}
        [void](Get-ProbeProxyGateway $startupInspect.value)
    }
    Start-ProbeKeepAlive
    [void](Write-ProbeObservation '00-setup' @{
        checkedAt=(Get-VerificationUtcNow);daemon=$daemon;listBefore=@($before);listAfter=@($after)
        clipboardImagePaste=$clipboard;mcpServers=@($mcp.servers).Count;mcpRaw=$mcp
        createArgv=@($createArgv);create=$create;name=$script:State.name;id=$script:State.id;sandboxRecordPath=$recordPath;keepAlive=$script:State.keepAlive
    })
    Complete-ProbeStep '00-setup'
}
function Start-ProbeKeepAlive() {
    # ADR-0193 のセッション保持 exec。期限監督の対象外で、probe プロセスのジョブに属する
    # （probe が落ちるとジョブハンドルが閉じ、KILL_ON_JOB_CLOSE で保持プロセスが消える = 07-kill の観測対象）。
    $seconds=[int][Math]::Max(600,$script:State.limits.totalSeconds)
    $argv=@('exec',$script:State.name,'sh','-c',"sleep $seconds")
    $base=Join-Path $script:State.runRoot ('cli/keepalive-'+[DateTime]::UtcNow.ToString('HHmmss'))
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($base))
    $handle=Start-VerificationBackgroundProcess -StartInfo (New-ProbeStartInfo $argv) -OutputPaths @{stdoutPath=$base+'.out';stderrPath=$base+'.err'} -RunBudget (New-ProbeBudget $script:QuerySeconds ([long]$script:State.limits.maxOutputBytes))
    $script:CallSequence++
    Add-ProbeCall $argv 'keepalive' (Get-VerificationUtcNow) @{exitCode=$null;started=$true;timedOut=$false;outputExceeded=$false;refusedReason=$null}
    $script:State.keepAlive=@{processId=$handle.processId;jobToken=$handle.jobToken;markerPath=$handle.markerPath;startedAt=$handle.startedAt;argv=@($argv);sleepSeconds=$seconds}
    $script:KeepAliveHandle=$handle
    Write-Host ("  保持セッション開始: sbx クライアント PID $($handle.processId)")
}

function Invoke-ProbeVersionStdlib() {
    Write-Host '=== 01-version-stdlib: python3 の版と標準ライブラリ一覧 ==='
    Assert-ProbeNoAutoStop '01'
    # 作業ディレクトリはまだ搬入前なので、exec -w は使わず VM 既定の作業ディレクトリで動かす。
    $version=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','--version') $script:State.limits.replaySeconds 'python3-version')
    $full=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','-c','import sys;print(sys.version)') $script:State.limits.replaySeconds 'python3-full-version')
    $stdlib=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','-c','import sys;print(chr(10).join(sorted(sys.stdlib_module_names)))') $script:State.limits.replaySeconds 'python3-stdlib')
    $modules=@([IO.File]::ReadAllText($stdlib.stdoutPath,[Text.UTF8Encoding]::new($false)).Replace("`r`n","`n").Split("`n") | ForEach-Object {$_.Trim()} | Where-Object {$_.Length -gt 0} | Sort-Object -Unique)
    $listPath=Join-Path $script:State.runRoot 'obs/stdlib-modules.txt'
    Write-VerificationNewFile $listPath (($modules -join "`n")+"`n")
    [void](Write-ProbeObservation '01-version-stdlib' @{
        checkedAt=(Get-VerificationUtcNow);versionCall=$version;fullVersionCall=$full;stdlibCall=$stdlib
        pythonVersion=$version.stdout.Trim();pythonVersionStream=$(if($version.stdout.Trim().Length -gt 0){'stdout'}else{'stderr'})
        moduleCount=$modules.Count;modulesPath=$listPath;modulesHash=(Get-VerificationFileHashText $listPath)
    })
    Complete-ProbeStep '01-version-stdlib'
}

function New-ProbeTrustedInput() {
    # 合成題材（tests/fixtures/pilot-source/）から、再実行時と同じ配置の搬入元を作る:
    #   <root>/calc.py            … 題材本体
    #   <root>/.verification-tests/test_calc.py … 再現テスト（unittest discover の開始ディレクトリ）
    $root=Join-Path $script:State.runRoot 'input/before'
    if([IO.Directory]::Exists($root)){return $root}
    [void][IO.Directory]::CreateDirectory((Join-Path $root '.verification-tests'))
    $fixtures=Join-Path $PSScriptRoot 'fixtures/pilot-source'
    [IO.File]::Copy((Join-Path $fixtures 'source/calc.py'),(Join-Path $root 'calc.py'))
    [IO.File]::Copy((Join-Path $fixtures 'tests/test_calc.py'),(Join-Path $root '.verification-tests/test_calc.py'))
    $root
}
function Invoke-ProbeInputUnittest() {
    Write-Host '=== 02-input-unittest: 搬入・所有者調整・搬入照合・unittest 1本 ==='
    Assert-ProbeNoAutoStop '02'
    $root=New-ProbeTrustedInput
    $expected=@{}
    foreach($file in [IO.Directory]::EnumerateFiles($root,'*',[IO.SearchOption]::AllDirectories)){
        $expected[$file.Substring($root.Length+1).Replace('\','/')]=(Get-VerificationFileHashText $file).ToUpperInvariant()
    }
    # まず製品（Copy-VerificationSandboxInput）と同じ順序・同じ argv で搬入する。親ディレクトリの事前作成は製品が行わないので、ここでも行わない。
    $copy=Invoke-ProbeSbx @('cp',$root,($script:State.name+':'+$script:SourceDestination)) $script:SetupSeconds 'cp'
    $parentCreate=$null;$copyRetry=$null
    if($copy.exitCode -ne 0 -or -not$copy.started -or $copy.timedOut){
        # 親ディレクトリが無いと搬入できないのなら、それ自体が製品側の欠陥（計画の範囲外の既存欠陥として報告する）。
        # 1台しか作れない run を失わないよう、事実を記録したうえで親を作って続ける。
        Write-Host '  cp が失敗した。親ディレクトリを作って再試行する（この事実は逸脱として報告する）'
        $parentCreate=Invoke-ProbeSbx @('exec','-u','root',$script:State.name,'mkdir','-p','/home/agent/workspace') $script:SetupSeconds 'mkdir-parent'
        $copyRetry=Assert-ProbeSbxOk (Invoke-ProbeSbx @('cp',$root,($script:State.name+':'+$script:SourceDestination)) $script:SetupSeconds 'cp-retry')
    }
    $chown=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec','-u','root',$script:State.name,'chown','-R','agent:agent',$script:SourceDestination) $script:SetupSeconds 'chown')
    # 搬入後の実体（cp がディレクトリの中身を置くのか、ディレクトリごと入れ子にするのかを実測する）
    $confirm=Invoke-ProbeVmExec @('sh','-c',"cd $script:SourceDestination && find . -type f -print0 | sort -z | xargs -0 sha256sum") $script:SetupSeconds 'confirm'
    $actual=@{}
    foreach($line in @([IO.File]::ReadAllText($confirm.stdoutPath,[Text.UTF8Encoding]::new($false)).Replace("`r`n","`n").Split("`n"))){
        $match=[regex]::Match($line,'^([0-9a-f]{64})  (?:\./)?(.+)$')
        if($match.Success){$actual[$match.Groups[2].Value]=$match.Groups[1].Value.ToUpperInvariant()}
    }
    $missing=@($expected.Keys | Where-Object {-not$actual.ContainsKey($_)} | Sort-Object)
    $unexpected=@($actual.Keys | Where-Object {-not$expected.ContainsKey($_)} | Sort-Object)
    $mismatched=@($expected.Keys | Where-Object {$actual.ContainsKey($_) -and $actual[$_] -ine $expected[$_]} | Sort-Object)
    # sbx cp が搬入元ディレクトリの中身を置くのか、ディレクトリごと入れ子にするのかは実測事項。
    # 入れ子だった場合でも unittest の出力ストリームを測れるよう、実体に合わせて作業ディレクトリを決める（入れ子自体は逸脱として報告する）。
    $nested=($missing.Count -gt 0 -and @($unexpected | Where-Object {$_ -clike ('before/*')}).Count -gt 0)
    $workDir=$(if($nested){$script:SourceDestination+'/before'}else{$script:SourceDestination})
    # 固定 argv の unittest 1本。要約行 "Ran N tests in" がどちらのストリームに出るかを実測する（Replay の出力署名の前提）。
    $unittest=Invoke-ProbeSbx (@('exec','-w',$workDir,$script:State.name)+$script:UnittestArgv) $script:State.limits.replaySeconds 'unittest'
    $summaryPattern='Ran \d+ tests? in'
    $inStdout=[regex]::IsMatch($unittest.stdout,$summaryPattern,[Text.RegularExpressions.RegexOptions]::Multiline)
    $inStderr=[regex]::IsMatch($unittest.stderr,$summaryPattern,[Text.RegularExpressions.RegexOptions]::Multiline)
    [void](Write-ProbeObservation '02-input-unittest' @{
        checkedAt=(Get-VerificationUtcNow);trustedInputRoot=$root;expected=$expected;actual=$actual
        copy=$copy;copyParentCreate=$parentCreate;copyRetry=$copyRetry;copyNeededParentDirectory=($null -ne $parentCreate)
        chown=$chown;confirm=$confirm;difference=@{missing=$missing;unexpected=$unexpected;mismatched=$mismatched}
        copyNestedDirectory=$nested;unittestWorkingDirectory=$workDir
        unittest=$unittest;summaryPattern=$summaryPattern;summaryInStdout=$inStdout;summaryInStderr=$inStderr
        summaryStream=$(if($inStderr -and -not$inStdout){'stderr'}elseif($inStdout -and -not$inStderr){'stdout'}elseif($inStdout -and $inStderr){'both'}else{'none'})
    })
    Complete-ProbeStep '02-input-unittest'
}

function Invoke-ProbeTransport() {
    Write-Host '=== 03-transport: 終了0・7・127・時間超過・クライアント強制終了 ==='
    Assert-ProbeNoAutoStop '03'
    $contrast=@{}
    $calls=@{}
    foreach($case in @(@('exit0','exit 0'),@('exit7','exit 7'),@('exit127','no-such-command-probe-8a'))){
        $call=Invoke-ProbeVmExec @('sh','-c',$case[1]) $script:State.limits.replaySeconds ('transport-'+$case[0])
        $calls[$case[0]]=$call
        $contrast[$case[0]]=@{exitCode=$call.exitCode;stderrKind=(Get-ProbeStderrKind $call)}
    }
    # 時間超過: replaySeconds で外側が打ち切る（計画「時間上限の全域表」の probe が発行する exec の上限）。
    $timeout=Invoke-ProbeVmExec @('sh','-c','sleep 300') $script:State.limits.replaySeconds 'transport-timeout'
    $calls['timeout']=$timeout
    $contrast['timeout']=@{exitCode=$timeout.exitCode;stderrKind=(Get-ProbeStderrKind $timeout)}
    # sbx クライアント子プロセスの外側からの強制終了: 背景起動して probe が明示的に止める（期限監督の対象外）。
    $killedArgv=@('exec','-w',$script:SourceDestination,$script:State.name,'sh','-c','sleep 600')
    $base=Join-Path $script:State.runRoot ('cli/transport-clientkilled')
    $handle=Start-VerificationBackgroundProcess -StartInfo (New-ProbeStartInfo $killedArgv) -OutputPaths @{stdoutPath=$base+'.out';stderrPath=$base+'.err'} -RunBudget (New-ProbeBudget $script:State.limits.replaySeconds ([long]$script:State.limits.maxOutputBytes))
    $script:CallSequence++
    Add-ProbeCall $killedArgv 'transport-clientkilled' (Get-VerificationUtcNow) @{exitCode=$null;started=$true;timedOut=$false;outputExceeded=$false;refusedReason=$null}
    Start-Sleep -Seconds 5
    $stopped=Stop-VerificationBackgroundProcess -Handle $handle -GraceSeconds 5
    $killedCall=@{argv=@($killedArgv);tag='transport-clientkilled';processId=$handle.processId;exitCode=$stopped.exitCode;processTreeStopped=$stopped.processTreeStopped
                  started=$true;refusedReason=$null;timedOut=$true;outputExceeded=$false
                  stdoutPath=$base+'.out';stderrPath=$base+'.err';stdout=(Read-ProbeText ($base+'.out'));stderr=(Read-ProbeText ($base+'.err'))}
    $calls['clientKilled']=$killedCall
    $contrast['clientKilled']=@{exitCode=$stopped.exitCode;stderrKind=(Get-ProbeStderrKind $killedCall)}
    [void](Write-ProbeObservation '03-transport' @{checkedAt=(Get-VerificationUtcNow);calls=$calls;transportContrast=$contrast})
    Complete-ProbeStep '03-transport'
}

function Invoke-ProbeFlood() {
    Write-Host '=== 04-flood: 出力洪水が合算出力上限で打ち切られること ==='
    Assert-ProbeNoAutoStop '04'
    $limit=[long]$script:State.limits.maxOutputBytes
    # 改行を含まない1行の Python で無限に書き出す（argv 要素に改行を入れない）。sys.stdout.write は int を返すので iter の番兵 None には到達しない。
    $flood=Invoke-ProbeVmExec @('python3','-c','import sys;list(iter(lambda: sys.stdout.write("x"*4096+chr(10)), None))') $script:State.limits.replaySeconds 'flood' $limit
    [void](Write-ProbeObservation '04-flood' @{checkedAt=(Get-VerificationUtcNow);maxOutputBytes=$limit;call=$flood
        cutOff=$flood.outputExceeded;totalBytes=($flood.stdoutBytes+$flood.stderrBytes);exitCodeCleared=($null -eq $flood.exitCode)})
    Complete-ProbeStep '04-flood'
}

function Test-ProbeStartupObservation([hashtable]$Startup) {
    foreach($key in @('inspectSessions','codexProcessCount','processProbeStarted')){if(-not$Startup.ContainsKey($key)){return $false}}
    $Startup.processProbeStarted -ceq $true -and ($Startup.inspectSessions -is [int] -or $Startup.inspectSessions -is [long]) -and $Startup.inspectSessions -eq 0 -and ($Startup.codexProcessCount -is [int] -or $Startup.codexProcessCount -is [long]) -and $Startup.codexProcessCount -eq 0
}
function Test-ProbeGuestObservation([hashtable]$Guest) {
    foreach($key in @('sshSocketPresent','sshGatewayResponseBytes','proxyControlStatus','nproc','memTotalKiB')){if(-not$Guest.ContainsKey($key)){return $false}}
    -not[bool]$Guest.sshSocketPresent -and [int]$Guest.sshGatewayResponseBytes -eq 0 -and [int]$Guest.proxyControlStatus -eq 403 -and [int]$Guest.nproc -eq 2 -and [int]$Guest.memTotalKiB -ge 1500000 -and [int]$Guest.memTotalKiB -le 2200000
}
function Test-ProbeProposalObservation([hashtable]$Policy,[object[]]$NetworkChecks,[hashtable]$Inspect,[hashtable]$CredentialChecks,[hashtable]$GuestChecks,[hashtable]$PolicyLog,[string]$Name) {
    if($null -eq $Policy -or $null -eq $Inspect -or $null -eq $CredentialChecks -or $null -eq $GuestChecks -or $null -eq $PolicyLog){return $false}
    if(-not$Inspect.ContainsKey('secrets') -or -not$PolicyLog.ContainsKey('blocked_hosts')){return $false}
    $normalized=@(foreach($item in $NetworkChecks){@{host="$($item.host):$($item.port)";allowed=$item.allowed}})
    $rules=Get-VerificationNetworkRules $Policy
    if(-not(Test-VerificationProposalRules $rules $Name) -or -not(Test-VerificationProposalPolicy $normalized) -or -not(Test-VerificationCredentialExposure 'proposal' @($Inspect.secrets)) -or -not(Test-ProbeGuestObservation $GuestChecks)){return $false}
    foreach($key in @('oauthMode','accessSentinel','modelEndpoint','requiresOpenaiAuthDisabled','authPlaceholder')){if(-not$CredentialChecks.ContainsKey($key) -or $CredentialChecks[$key] -cne $true){return $false}}
    @($PolicyLog.blocked_hosts | Where-Object {$_.vm_name -ceq $Name -and $_.host -like 'example.com:*'}).Count -gt 0
}
function Get-ProbeProxyGateway([hashtable]$Inspect) {
    if($null -eq $Inspect -or -not$Inspect.ContainsKey('proxy') -or $Inspect.proxy -isnot [string] -or [string]::IsNullOrWhiteSpace($Inspect.proxy)){throw 'inspect.proxy must be a nonempty IPv4:port string'}
    $address=[string]$Inspect.proxy
    if($address -cnotmatch '^(?<host>(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}):(?<port>[1-9][0-9]{0,4})$'){throw 'inspect.proxy must be a nonempty IPv4:port string'}
    $hostName=[string]$Matches.host;$port=[int]$Matches.port
    if($port -gt 65535 -or @($hostName.Split('.') | Where-Object {[int]$_ -gt 255}).Count -gt 0){throw 'inspect.proxy has an invalid IPv4 address or port'}
    $hostName
}
function Invoke-ProbeGuestObservation([hashtable]$Inspect) {
    $gateway=Get-ProbeProxyGateway $Inspect
    $program=@'
import json,pathlib,socket,subprocess,sys
host=sys.argv[1]
def response(port,payload):
    try:
        with socket.create_connection((host,port),timeout=3) as s:
            s.settimeout(3)
            s.sendall(payload)
            return s.recv(512)
    except (OSError,TimeoutError):
        return b''
ssh=response(3129,bytes.fromhex('000000010b'))
proxy=response(3128,b'GET http://example.com/ HTTP/1.1\r\nHost: example.com\r\n\r\n')
status=int(proxy.split(b' ',2)[1]) if proxy.startswith(b'HTTP/') and len(proxy.split(b' ',2))>1 and proxy.split(b' ',2)[1].isdigit() else 0
nproc=int(subprocess.run(['nproc'],capture_output=True,text=True,check=True).stdout.strip())
mem=int(next(line.split()[1] for line in pathlib.Path('/proc/meminfo').read_text().splitlines() if line.startswith('MemTotal:')))
print(json.dumps({'sshSocketPresent':pathlib.Path('/run/ssh-agent.sock').is_socket(),'sshGatewayResponseBytes':len(ssh),'proxyControlStatus':status,'nproc':nproc,'memTotalKiB':mem}))
'@
    $call=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','-c',$program,$gateway) $script:QuerySeconds 'guest-guards')
    ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($call.stdoutPath,[Text.UTF8Encoding]::new($false)))
}
function Invoke-ProbeQueries() {
    Write-Host '=== 05-queries: inspect・policy ls・settings・mcp・runtime ファイル・daemon.log ==='
    Assert-ProbeNoAutoStop '05'
    $inspect=Invoke-ProbeSbxJson @('inspect',$script:State.name,'--json') 'inspect'
    $policy=Invoke-ProbeSbxJson @('policy','ls',$script:State.name,'--json') 'policy-ls'
    $modelNetworkChecks=@()
    $credentialChecks=$null
    $guestChecks=$null
    $policyLog=$null
    if($script:State.role -ceq 'proposal'){
        foreach($target in Get-VerificationProposalNetworkTargets){
            $checked=Invoke-ProbeSbxJson @('policy','check','network','--sandbox',$script:State.name,$target.target,'--json') ('network-'+$modelNetworkChecks.Count)
            if(-not$checked.value.ContainsKey('allowed') -or $checked.value.allowed -isnot [bool]){throw "policy check lacks boolean allowed: $($target.host):$($target.port)"}
            $modelNetworkChecks+=@{host=$target.host;port=$target.port;allowed=$checked.value.allowed;expectedAllowed=$target.allowed}
        }
        # 値そのものは出力・記録しない。キット宣言のセンチネルとOAuthモードへの一致だけを記録する。
        $credentialProgram='import json,os,pathlib,tomllib; c=tomllib.loads(pathlib.Path("/home/agent/.codex/config.toml").read_text()); p=c["model_providers"]["sandboxd"]; a=json.loads(pathlib.Path("/home/agent/.codex/auth.json").read_text()); print(json.dumps({"oauthMode":os.getenv("SBX_CRED_OPENAI_MODE")=="oauth","accessSentinel":p.get("experimental_bearer_token")=="oai-oat01-proxy-managed","modelEndpoint":p.get("base_url")=="https://chatgpt.com/backend-api/codex","requiresOpenaiAuthDisabled":p.get("requires_openai_auth") is False,"authPlaceholder":a.get("OPENAI_API_KEY")=="proxy-managed"}))'
        $credentialCall=Assert-ProbeSbxOk (Invoke-ProbeSbx @('exec',$script:State.name,'python3','-c',$credentialProgram) $script:QuerySeconds 'credential-sentinel')
        $credentialChecks=ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($credentialCall.stdoutPath,[Text.UTF8Encoding]::new($false)))
        $guestChecks=Invoke-ProbeGuestObservation $inspect.value
        $policyLog=(Invoke-ProbeSbxJson @('policy','log',$script:State.name,'--json') 'policy-log').value
    }
    $settings=@{}
    foreach($key in @('clipboard.imagePaste','ssh.agentForwardingEnabled','ssh.agentSocketPath')){
        $settings[$key]=(Invoke-ProbeSbxJson @('settings','get','--json',$key) ('settings-'+$key.Replace('.','-'))).value
    }
    $mcp=Invoke-ProbeSbxJson @('mcp','ls','--json') 'mcp-ls-2'
    $runtimePath=Join-Path $script:State.stateRoot ('runtimes/'+$script:State.name+'.json')
    $runtime=ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($runtimePath,[Text.UTF8Encoding]::new($false)))
    $spec=$runtime.Spec
    $logLines=Get-ProbeVmLogLines
    $list=Get-ProbeSandboxList
    [void](Write-ProbeObservation '05-queries' @{
        checkedAt=(Get-VerificationUtcNow);inspect=$inspect.value;policy=$policy.value;policyLog=$policyLog;modelNetworkChecks=$modelNetworkChecks;credentialChecks=$credentialChecks;guestChecks=$guestChecks;settings=$settings;mcp=$mcp.value;list=@($list)
        runtimeFilePath=$runtimePath
        runtimeSpec=@{ID=[string]$runtime.ID;WorkspaceDir=[string]$spec.WorkspaceDir;ShareSkills=$spec.ShareSkills;CPUs=$spec.CPUs;Memory=[string]$spec.Memory;SSHAgentSocketPath=[string]$spec.SSHAgentSocketPath;Template=[string]$spec.Template}
        daemonLogLines=@($logLines | ForEach-Object {$_.raw})
        sshForwarderLines=@($logLines | Where-Object {$_.msg -ceq 'started SSH agent forwarder'}).Count
    })
    if($script:State.role -ceq 'proposal'){
        if(-not(Test-ProbeProposalObservation $policy.value $modelNetworkChecks $inspect.value $credentialChecks $guestChecks $policyLog $script:State.name)){
            throw 'proposal observation did not meet ADR-0199 conditions'
        }
    }
    Complete-ProbeStep '05-queries'
}
function Invoke-ProbeProposalStop() {
    Write-Host '=== 06-proposal-stop: 外側停止・同一IDの停止確認 ==='
    $stop=Assert-ProbeSbxOk (Invoke-ProbeSbx @('stop',$script:State.name) $script:QuerySeconds 'proposal-stop')
    $list=Get-ProbeSandboxList
    $same=@($list | Where-Object {$_.name -ceq $script:State.name -and $_.id -ceq $script:State.id})
    [void](Write-ProbeObservation '06-proposal-stop' @{checkedAt=(Get-VerificationUtcNow);stop=$stop;list=@($list);sameIdStopped=($same.Count -eq 1 -and $same[0].status -ceq 'stopped')})
    if($same.Count -ne 1 -or $same[0].status -cne 'stopped'){throw 'proposal VM stop was not confirmed on the same id'}
    if($null -ne $script:KeepAliveHandle){[void](Stop-VerificationBackgroundProcess -Handle $script:KeepAliveHandle -GraceSeconds 5);$script:KeepAliveHandle=$null}
    Complete-ProbeStep '06-proposal-stop'
}
function Stop-ProbeProposalOnError() {
    if($null -eq $script:State -or $script:State.role -cne 'proposal' -or $null -eq $script:State.id){return}
    $result=@{checkedAt=(Get-VerificationUtcNow);name=$script:State.name;id=$script:State.id;stopState='unverified';reason=$null}
    try{
        $list=Get-ProbeSandboxList
        $same=@($list | Where-Object {$_.name -ceq $script:State.name -and $_.id -ceq $script:State.id})
        if($same.Count -ne 1){$result.reason='recorded name and id not found in list'}
        elseif($same[0].status -ceq 'stopped'){$result.stopState='stopped'}
        else{
            $stop=Invoke-ProbeSbx @('stop',$script:State.name) $script:QuerySeconds 'proposal-error-stop'
            $after=Get-ProbeSandboxList
            $confirmed=@($after | Where-Object {$_.name -ceq $script:State.name -and $_.id -ceq $script:State.id -and $_.status -ceq 'stopped'})
            if($stop.exitCode -eq 0 -and $confirmed.Count -eq 1){$result.stopState='stopped'}else{$result.reason='stop or same-id confirmation failed'}
        }
    }catch{$result.reason=$_.Exception.Message}
    try{[void](Write-ProbeObservation 'proposal-error-stop' $result)}catch{}
    if($null -ne $script:KeepAliveHandle){try{[void](Stop-VerificationBackgroundProcess -Handle $script:KeepAliveHandle -GraceSeconds 5)}catch{};$script:KeepAliveHandle=$null}
    Write-Host "  proposal VMの失敗時停止: $($result.stopState) / $($result.reason)"
}

function Invoke-ProbeHold() {
    Write-Host "=== 06-hold: 約 $HoldSeconds 秒の連続保持 ==="
    Assert-ProbeNoAutoStop '06-before'
    $startedAt=Get-VerificationUtcNow
    $polls=@()
    $until=[DateTime]::UtcNow.AddSeconds($HoldSeconds)
    while([DateTime]::UtcNow -lt $until){
        Start-Sleep -Seconds 60
        # 保持中は sbx を叩かない（それ自体が新しいセッションになるため）。daemon.log の読取りとホスト側プロセスの存否だけを見る。
        $alive=$null -ne (Get-Process -Id $script:State.keepAlive.processId -ErrorAction SilentlyContinue)
        $auto=@(Test-ProbeAutoStopped).Count
        $polls+=@{at=(Get-VerificationUtcNow);keepAliveAlive=$alive;autoStopLines=$auto}
        if($auto -gt 0){break}
        if(-not$alive){break}
    }
    Assert-ProbeNoAutoStop '06-after'
    # 保持が効いていたことの確認: 保持以外のコマンドを1本も出さずに経過したあと、VM がまだ running であること。
    $list=Get-ProbeSandboxList
    $same=@($list | Where-Object {$_.id -ceq $script:State.id -and $_.name -ceq $script:State.name})
    $status=$(if($same.Count -eq 1){$same[0].status}else{'not-listed'})
    [void](Write-ProbeObservation '06-hold' @{
        checkedAt=(Get-VerificationUtcNow);holdSeconds=$HoldSeconds;startedAt=$startedAt;polls=@($polls)
        keepAliveProcessId=$script:State.keepAlive.processId;keepAliveAliveAtEnd=($null -ne (Get-Process -Id $script:State.keepAlive.processId -ErrorAction SilentlyContinue))
        listStatusAfterHold=$status;list=@($list);autoStopLinesAfterHold=@(Test-ProbeAutoStopped).Count
    })
    if($status -cne 'running'){throw "保持中に VM が running でなくなった: $status"}
    Complete-ProbeStep '06-hold'
}

function Invoke-ProbeKill() {
    Write-Host '=== 07-kill: probe プロセス（CLI 相当）の強制終了 ==='
    Assert-ProbeNoAutoStop '07'
    $list=Get-ProbeSandboxList
    $script:State.kill=@{
        plannedAt=(Get-VerificationUtcNow);probeProcessId=$PID;keepAliveProcessId=$script:State.keepAlive.processId
        listBeforeKill=@($list)
        preexisting=@(foreach($name in $script:PreexistingVms){@($list | Where-Object {$_.name -ceq $name}) | ForEach-Object {@{name=$_.name;id=$_.id;status=$_.status}}})
    }
    [void](Write-ProbeObservation '07-kill' @{checkedAt=(Get-VerificationUtcNow);kill=$script:State.kill;note='この観測の直後に probe 自身を強制終了する。続きは -Resume <runRoot> で取る。'})
    Complete-ProbeStep '07-kill'
    Write-Host ("  probe プロセス PID $PID を強制終了する。再開は: pwsh -NoProfile -File <このスクリプト> -Resume `"$($script:State.runRoot)`"")
    [Console]::Out.Flush()
    # CLI の異常終了を模す。ジョブハンドルが閉じるので保持セッションの木も一緒に落ちる（KILL_ON_JOB_CLOSE）。
    Stop-Process -Id $PID -Force
    Start-Sleep -Seconds 30   # 到達しない（停止が非同期の場合の保険）
}

function Invoke-ProbeResume() {
    Write-Host '=== 08-resume: 保持プロセスの消失・自動停止・復旧操作 ==='
    $killedAt=Get-VerificationUtcNow
    $keepAlivePid=[int]$script:State.keepAlive.processId
    $keepAliveGone=$null -eq (Get-Process -Id $keepAlivePid -ErrorAction SilentlyContinue)
    $probeGone=$null -eq (Get-Process -Id ([int]$script:State.kill.probeProcessId) -ErrorAction SilentlyContinue)
    # 自動停止行（最後のセッション切断から30秒）が出るまで待つ。sbx は叩かない（叩くと新しいセッションで自動起動してしまう）。
    $autoStopLines=@();$waitedSeconds=0
    $until=[DateTime]::UtcNow.AddSeconds($AutoStopWaitSeconds)
    while([DateTime]::UtcNow -lt $until){
        $autoStopLines=@(Test-ProbeAutoStopped)
        if($autoStopLines.Count -gt 0){break}
        Start-Sleep -Seconds 5;$waitedSeconds+=5
    }
    $vmLines=Get-ProbeVmLogLines
    # 復旧操作: control/runtime/probe-sandbox.json の記録済み ID だけを対象にする。
    $recovery=Stop-VerificationRecordedSandboxes $script:State.runRoot $script:State.recoveryInput
    $listAfter=Get-ProbeSandboxList
    $preexistingAfter=@(foreach($name in $script:PreexistingVms){@($listAfter | Where-Object {$_.name -ceq $name}) | ForEach-Object {@{name=$_.name;id=$_.id;status=$_.status}}})
    # 停止確認後に当該VM名へコマンドを出していないこと、および既存VM名へ ls 以外を出していないことを calls.jsonl で確かめる。
    $calls=@(foreach($line in @([IO.File]::ReadAllText((Join-Path $script:State.runRoot 'calls.jsonl'),[Text.UTF8Encoding]::new($false)).Replace("`r`n","`n").Split("`n"))){
        if($line.Trim().Length -gt 0){ConvertFrom-ProbeJsonText $line}
    })
    $afterStop=@($calls | Where-Object {@($_.argv) -contains $script:State.name -and $_.issuedAt -gt $recovery.checkedAt})
    $preexistingCalls=@($calls | Where-Object {$argv=@($_.argv);@($script:PreexistingVms | Where-Object {$argv -contains $_}).Count -gt 0})
    [void](Write-ProbeObservation '08-resume' @{
        checkedAt=$killedAt;keepAliveProcessId=$keepAlivePid;keepAliveGone=$keepAliveGone;probeProcessGone=$probeGone
        autoStopWaitedSeconds=$waitedSeconds;autoStopLines=@($autoStopLines | ForEach-Object {$_.raw});vmLogLines=@($vmLines | ForEach-Object {$_.raw})
        recovery=$recovery;listAfter=@($listAfter);preexistingBefore=@($script:State.kill.preexisting);preexistingAfter=@($preexistingAfter)
        commandsToProbeVmAfterRecovery=@($afterStop);commandsNamingPreexistingVms=@($preexistingCalls)
    })
    Complete-ProbeStep '08-resume'
    Write-Host ''
    Write-Host '=== probe 完了 ==='
    Write-Host ("  VM: $($script:State.name) / $($script:State.id)")
    Write-Host ("  復旧操作の対象: $($recovery.targetCount) 件。stopState: "+((@($recovery.targets) | ForEach-Object {"$($_.name)=$($_.stopState)(before=$($_.stateBefore))"}) -join ', '))
    Write-Host ("  runRoot: $($script:State.runRoot)")
}

function Get-ProbeSteps([string]$Role,[string]$Phase) {
    if($Role -cnotin @('probe','proposal')){throw "unsupported probe role: $Role"}
    if(($Role -ceq 'proposal' -and $Phase -cnotin @('limitsAndTransport','abnormalExitRecovery')) -or ($Role -ceq 'probe' -and $Phase)){throw "unsupported probe phase: $Role/$Phase"}
    if($Role -ceq 'proposal' -and $Phase -ceq 'limitsAndTransport'){
        return @(
            @{name='00-setup';action={Invoke-ProbeSetup}},
            @{name='01-version-stdlib';action={Invoke-ProbeVersionStdlib}},
            @{name='02-input-unittest';action={Invoke-ProbeInputUnittest}},
            @{name='03-transport';action={Invoke-ProbeTransport}},
            @{name='04-flood';action={Invoke-ProbeFlood}},
            @{name='05-queries';action={Invoke-ProbeQueries}},
            @{name='06-proposal-stop';action={Invoke-ProbeProposalStop}})
    }
    if($Role -ceq 'proposal' -and $Phase -ceq 'abnormalExitRecovery'){
        return @(@{name='00-setup';action={Invoke-ProbeSetup}},@{name='07-kill';action={Invoke-ProbeKill}},@{name='08-resume';action={Invoke-ProbeResume}})
    }
    @(
        @{name='00-setup';action={Invoke-ProbeSetup}},
        @{name='01-version-stdlib';action={Invoke-ProbeVersionStdlib}},
        @{name='02-input-unittest';action={Invoke-ProbeInputUnittest}},
        @{name='03-transport';action={Invoke-ProbeTransport}},
        @{name='04-flood';action={Invoke-ProbeFlood}},
        @{name='05-queries';action={Invoke-ProbeQueries}},
        @{name='06-hold';action={Invoke-ProbeHold}},
        @{name='07-kill';action={Invoke-ProbeKill}},
        @{name='08-resume';action={Invoke-ProbeResume}})
}

# =====================================================================
# 入口
# =====================================================================
if($Resume){
    $runRoot=Resolve-VerificationPath $Resume
    $statePath=Join-Path $runRoot 'probe-state.json'
    if(-not[IO.File]::Exists($statePath)){throw "probe-state.json missing under $runRoot"}
    $script:State=ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($statePath,[Text.UTF8Encoding]::new($false)))
    if(-not$script:State.ContainsKey('role')){$script:State.role='probe'}
    if(-not$script:State.ContainsKey('proposalPhase')){$script:State.proposalPhase=$null}
    if($script:State.role -ceq 'proposal' -and $script:State.ContainsKey('lastError') -and -not[string]::IsNullOrWhiteSpace([string]$script:State.lastError)){throw 'failed proposal probe cannot resume; review the observation before a new runId'}
    # 再開ごとに期限を取り直す（足場の run であり、製品の run 予算ではない）。
    $script:State.deadlineAt=[DateTime]::UtcNow.AddSeconds([int]$script:State.limits.totalSeconds).ToString('o',[Globalization.CultureInfo]::InvariantCulture)
    $script:CallSequence=[int]$script:State.callSequence+1000   # 再開後の出力ファイル名が既存と衝突しないようにずらす
    Write-Host "probe を再開する: $runRoot（完了済み: $(@($script:State.completed) -join ', ')）"
}else{
    if($Role -ceq 'proposal' -and [string]::IsNullOrWhiteSpace($ProposalPhase)){throw 'proposal requires -ProposalPhase'}
    if($Role -ceq 'probe' -and $ProposalPhase){throw '-ProposalPhase is only for proposal'}
    if(-not$SettingsPath){$SettingsPath=Join-Path $PSScriptRoot 'fixtures/probe-settings.json'}
    $settings=Read-ProbeSettings (Resolve-VerificationPath $SettingsPath)
    $runId=[guid]::NewGuid().ToString()
    $runRoot=Join-Path (Resolve-VerificationPath $settings.runsRoot) $runId.Substring(0,8)
    if([IO.Directory]::Exists($runRoot)){throw "run root already exists: $runRoot"}
    [void][IO.Directory]::CreateDirectory((Join-Path $runRoot 'obs'))
    [void][IO.Directory]::CreateDirectory((Join-Path $runRoot 'control/runtime'))
    $script:State=@{
        schemaVersion=3;runId=$runId;runRoot=$runRoot;settingsPath=$SettingsPath
        sbxPath=(Resolve-VerificationPath $settings.sbxPath);limits=$settings.limits
        # 1台ごとに新しいrunIdを発行し、役割を名前に含める。
        role=$Role;proposalPhase=$ProposalPhase
        name=('iv-'+$runId.Substring(0,8).ToLowerInvariant()+'-'+$Role)
        id=$null;createdAt=$null;deadlineAt=[DateTime]::UtcNow.AddSeconds([int]$settings.limits.totalSeconds).ToString('o',[Globalization.CultureInfo]::InvariantCulture)
        daemon=$null;logPath=$null;stateRoot=$null;keepAlive=$null;sandboxRecordPath=$null;kill=$null
        completed=@();callSequence=0
        # 復旧操作へ渡す入力（recovery-input.schema.json）。settings と同じ値を使う。
        recoveryInput=@{schemaVersion=3;sbxPath=$settings.sbxPath;pwshPath=$settings.pwshPath;runsRoot=$settings.runsRoot;limits=$settings.limits}
    }
    Save-ProbeState
    Write-Host "probe を開始する: runId=$runId / VM=$($script:State.name) / runRoot=$runRoot"
}
$script:SbxEnvironment=Get-ProbeSbxEnvironment $script:State.sbxPath
$script:KeepAliveHandle=$null
try{
    $steps=Get-ProbeSteps $script:State.role $script:State.proposalPhase
    foreach($step in $steps){
        if(Test-ProbeStepDone $step.name){Write-Host "ステップ済み（読み飛ばし）: $($step.name)";continue}
        # 07-kill の前に 06-hold まで終えていない状態で再開した場合も、未了のステップから順に続ける。
        if($step.name -ceq '08-resume' -and -not(Test-ProbeStepDone '07-kill')){throw '08-resume は 07-kill の後にだけ実行できる'}
        & $step.action
        $script:State.callSequence=$script:CallSequence
        Save-ProbeState
    }
}catch{
    $primaryError=$_
    Stop-ProbeProposalOnError
    $script:State.lastError=([regex]::Replace([string]$primaryError.Exception.Message,'\s+',' ')).Trim()
    try{Save-ProbeState}catch{}
    Write-Host ''
    Write-Host "probe が中断した: $($script:State.lastError)"
    if($script:State.role -ceq 'proposal'){Write-Host "  runRoot: $($script:State.runRoot)（再実施は観測を確認した後、新しいrunIdで行う）"}
    else{Write-Host "  runRoot: $($script:State.runRoot)（再開は -Resume `"$($script:State.runRoot)`"）"}
    throw $primaryError
}
