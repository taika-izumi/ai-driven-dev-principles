# sbx 実行基盤を外側の記録で管理する。実行設定（runtime profile）の検査、pilot 排他、VM の作成・搬入・照合・実行・停止、
# activationRecord、デーモン起動世代、記録済み ID の復旧停止（ADR-0194）。VM を扱う操作はこのモジュールに閉じ、他ブロックは公開操作だけを呼ぶ。
# sbx CLI は常に外側で固定 argv を組み立て、最小の環境辞書（SSH_AUTH_SOCK を含めない）で起動する。子からホストコマンド・フラグ・接続先を受け取らない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')   # 正規化JSON・ハッシュ・新規作成書込・UTC時刻・重複キー検査を共用する
Import-Module (Join-Path $PSScriptRoot 'Execution.psm1')     # 上限付きプロセス実行と背景起動
# exec 以外のコマンドの時間上限（秒）。計画「時間上限の全域表」の定数。limits・CLI 入力・子からは変えず、試験だけが script スコープで小さい値へ差し替える。
$script:QuerySeconds=60      # 照会（daemon status・ls・inspect・policy・settings・mcp）と stop
$script:SetupSeconds=240     # 作成・搬入・所有者調整・搬入照合（create・cp・chown・Confirm の exec）
$script:KeepAliveStopGraceSeconds=5
$script:RequiredChecks=@{
    common=@('daemonHealthAndTemplate','noWorkspaceNoSkillsNoMcp','hostPathIsolation','resourceAndOutsideStop','limitsAndTransport','abnormalExitRecovery','daemonDisconnect')
    proposal=@('credentialMethod','modelEndpointAllowOnly');replay=@('replayNetworkDeny')
}
$script:TransportContrastKeys=@('exit0','exit7','exit127','timeout','clientKilled')
$script:AcceptedLimitations=@('clipboard-text-write-possible','pid-count-unbounded','daemon-disconnect-unverified')
$script:RoleSuffix=@{proposal='proposal';'replay-before'='before';'replay-after'='after';probe='probe'}
$script:CreatableRoles=@('proposal','replay-before','replay-after')

# ---- 共通補助 ----
function Throw-VerificationRuntimeFailure([string]$Message,[string]$Status='blocked',[string]$Reason='') {
    $failure=[InvalidOperationException]::new($Message);$failure.Data['status']=$Status
    if($Reason){$failure.Data['reason']=$Reason}
    throw $failure
}
function Test-VerificationRuntimeSchema([hashtable]$Object,[string]$SchemaName,[string]$Label) {
    $json=$Object | ConvertTo-Json -Depth 20
    $errors=$null
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot $SchemaName) -ErrorAction SilentlyContinue -ErrorVariable errors)){
        $detail=$(if($errors -and $errors.Count -gt 0){$errors[0].Exception.Message}else{'schema violation'})
        Throw-VerificationRuntimeFailure "invalid $Label schema: $detail" 'blocked' 'schema'
    }
}
function Read-VerificationJsonFile([string]$Path,[string]$Label) {
    if(-not[IO.File]::Exists($Path)){Throw-VerificationRuntimeFailure "$Label missing: $Path"}
    $json=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if(Test-VerificationJsonDuplicateKeys $json){Throw-VerificationRuntimeFailure "$Label has duplicate keys"}
    $value=$json | ConvertFrom-Json -AsHashtable -Depth 20
    if($value -isnot [hashtable]){Throw-VerificationRuntimeFailure "$Label must be a JSON object"}
    $value
}
function Get-VerificationFileHash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Resolve-VerificationRelativePath([string]$Value,[string]$BaseDir) {
    # 絶対パスはそのまま、相対パスは基準ディレクトリ（profile や evidence のあるディレクトリ）から解決する。再解析ポイントは拒否する。
    if([string]::IsNullOrWhiteSpace($Value)){Throw-VerificationRuntimeFailure 'path required'}
    if([IO.Path]::IsPathFullyQualified($Value)){return Resolve-VerificationPath $Value}
    Resolve-VerificationPath ([IO.Path]::GetFullPath((Join-Path $BaseDir $Value)))
}

# ---- 実行設定（runtime profile）の検査 ----
function Get-VerificationProfileRole([string]$Role) {
    # replay-before/replay-after は検査時だけ profile.role=replay へ対応付ける（記録上の役割は統合しない）。probe は profile 検査を通らない足場なので受けない。
    switch($Role){
        'proposal'{return 'proposal'}
        'replay-before'{return 'replay'}
        'replay-after'{return 'replay'}
        default{Throw-VerificationRuntimeFailure "unsupported role: $Role"}
    }
}
function Get-VerificationProfileHash([hashtable]$Profile) {
    # activationEvidencePath/Hash を除いた正規化JSONの SHA256（証拠への相互参照でハッシュが循環しないため）。
    $subset=@{}
    foreach($key in $Profile.Keys){if($key -notin @('activationEvidencePath','activationEvidenceHash')){$subset[$key]=$Profile[$key]}}
    Get-VerificationCanonicalHash $subset
}
function Test-VerificationRuntimeProfile([hashtable]$Profile,[string]$Role,[hashtable]$Settings) {
    # 1つでも欠ければ blocked。返り値は profileHash。
    $profileRole=Get-VerificationProfileRole $Role
    if($null -eq $Profile){Throw-VerificationRuntimeFailure 'runtime profile required'}
    if($null -eq $Settings -or -not$Settings.ContainsKey('limits')){Throw-VerificationRuntimeFailure 'settings with limits required'}
    Test-VerificationRuntimeSchema $Profile 'runtime-profile.schema.json' 'runtime profile'
    if($Profile.role -cne $profileRole){Throw-VerificationRuntimeFailure "profile role '$($Profile.role)' does not match requested role '$Role'"}
    $expectedAgent=$(if($profileRole -eq 'proposal'){'codex'}else{'shell'})
    if($Profile.agent -cne $expectedAgent){Throw-VerificationRuntimeFailure "profile agent must be $expectedAgent for $profileRole"}
    if($profileRole -eq 'proposal'){
        if($null -eq $Profile.model -or -not$Settings.ContainsKey('model') -or $null -eq $Settings.model -or $Profile.model -cne $Settings.model){Throw-VerificationRuntimeFailure 'profile model does not match settings model'}
    }elseif($null -ne $Profile.model){Throw-VerificationRuntimeFailure 'replay profile must not name a model'}
    if((ConvertTo-VerificationCanonicalJson @($Profile.acceptedLimitations)) -cne (ConvertTo-VerificationCanonicalJson $script:AcceptedLimitations)){Throw-VerificationRuntimeFailure 'acceptedLimitations must be the fixed synthetic-pilot list'}
    # 相対パスは Settings の当該役割の profile パスのディレクトリから解決する。
    $profilePathKey=$(if($profileRole -eq 'proposal'){'proposalProfilePath'}else{'replayProfilePath'})
    if(-not$Settings.ContainsKey($profilePathKey) -or $Settings[$profilePathKey] -isnot [string]){Throw-VerificationRuntimeFailure "settings.$profilePathKey required"}
    $baseDir=[IO.Path]::GetDirectoryName((Resolve-VerificationPath $Settings[$profilePathKey]))
    $stdlibPath=Resolve-VerificationRelativePath $Profile.stdlibModulesPath $baseDir
    if(-not[IO.File]::Exists($stdlibPath)){Throw-VerificationRuntimeFailure 'stdlib modules file missing'}
    if((Get-VerificationFileHash $stdlibPath) -ine $Profile.stdlibModulesHash){Throw-VerificationRuntimeFailure 'stdlib modules hash mismatch'}
    $evidencePath=Resolve-VerificationRelativePath $Profile.activationEvidencePath $baseDir
    if(-not[IO.File]::Exists($evidencePath)){Throw-VerificationRuntimeFailure 'activation evidence missing'}
    if((Get-VerificationFileHash $evidencePath) -ine $Profile.activationEvidenceHash){Throw-VerificationRuntimeFailure 'activation evidence hash mismatch'}
    $evidence=Read-VerificationJsonFile $evidencePath 'activation evidence'
    Test-VerificationRuntimeSchema $evidence 'activation-evidence.schema.json' 'activation evidence'
    $profileHash=Get-VerificationProfileHash $Profile
    if($evidence.profileHash -ine $profileHash){Throw-VerificationRuntimeFailure 'activation evidence profileHash does not match profile'}
    # 必須条件名がすべて存在し、daemonDisconnect 以外は verified（ADR-0196）。各条件の証拠ファイルの hash も一致すること（profiles/evidence-checks.md）。
    $evidenceDir=[IO.Path]::GetDirectoryName($evidencePath)
    foreach($name in @($script:RequiredChecks.common)+@($script:RequiredChecks[$profileRole])){
        if(-not$evidence.checks.ContainsKey($name)){Throw-VerificationRuntimeFailure "activation evidence lacks required check: $name"}
        $check=$evidence.checks[$name]
        if($name -eq 'daemonDisconnect'){
            if($check.verdict -notin @('verified','unverified')){Throw-VerificationRuntimeFailure "activation check $name must be verified or unverified"}
        }elseif($check.verdict -cne 'verified'){Throw-VerificationRuntimeFailure "activation check not verified: $name ($($check.verdict))"}
        $checkPath=Resolve-VerificationRelativePath $check.evidencePath $evidenceDir
        if(-not[IO.File]::Exists($checkPath)){Throw-VerificationRuntimeFailure "evidence file missing for check $name"}
        if((Get-VerificationFileHash $checkPath) -ine $check.evidenceHash){Throw-VerificationRuntimeFailure "evidence hash mismatch for check $name"}
    }
    foreach($key in $script:TransportContrastKeys){if(-not$evidence.transportContrast.ContainsKey($key)){Throw-VerificationRuntimeFailure "transportContrast lacks $key"}}
    $profileHash
}
function Get-VerificationEffectiveSettingsHash([hashtable]$Profile,[hashtable]$Settings) {
    # 意図した実行条件のラベル（role を含めない。before/after で一致すべき値）。実効値の証拠は activationRecord の checks が担う。
    $limits=@{};foreach($key in $Settings.limits.Keys){$limits[$key]=$Settings.limits[$key]}
    Get-VerificationCanonicalHash @{agent=$Profile.agent;templateDigest=$Profile.templateDigest;cpus=$Settings.limits.cpus;memoryMiB=$Settings.limits.memoryMiB;networkPolicy=$Profile.policyExpectation.networkPolicy;shareSkills=$false;workspace='none';limits=$limits}
}
# ---- sbx CLI の起動（固定 argv・最小環境辞書・上限付き） ----
$script:PilotLeases=@{}      # leaseId -> @{mutex;runId;daemonKey}。Mutex ハンドルは外へ出さない。
$script:Sandboxes=@{}        # VM名 -> 内部状態（client・状態ディレクトリ・世代・activation の期待値・保持セッション・停止結果）。handle は JSON 化可能な項目だけ持つ。
$script:CommandSequence=0
function Get-VerificationSbxEnvironment([string]$SbxPath) {
    # 明示辞書だけを渡す。PATH は sbx の親ディレクトリのみ。SSH_AUTH_SOCK は含めない。
    $environment=@{}
    foreach($key in @('SystemRoot','USERPROFILE','LOCALAPPDATA','APPDATA','TEMP')){
        $value=[Environment]::GetEnvironmentVariable($key)
        if([string]::IsNullOrEmpty($value)){Throw-VerificationRuntimeFailure "host environment variable missing: $key"}
        $environment[$key]=$value
    }
    $environment['PATH']=[IO.Path]::GetDirectoryName($SbxPath)
    $environment
}
function New-VerificationSbxClient([string]$SbxPath,[string]$OutDir,[long]$MaxOutputBytes) {
    $path=Resolve-VerificationPath $SbxPath
    if(-not[IO.File]::Exists($path)){Throw-VerificationRuntimeFailure 'sbx executable missing'}
    if($MaxOutputBytes -le 0){Throw-VerificationRuntimeFailure 'maxOutputBytes must be positive'}
    [void][IO.Directory]::CreateDirectory($OutDir)
    @{sbxPath=$path;outDir=$OutDir;maxOutputBytes=[long]$MaxOutputBytes;environment=(Get-VerificationSbxEnvironment $path)}
}
function New-VerificationSbxStartInfo([hashtable]$Client,[string[]]$Argv) {
    $start=[Diagnostics.ProcessStartInfo]::new($Client.sbxPath)
    $start.WorkingDirectory=$Client.outDir;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.Environment.Clear();foreach($key in $Client.environment.Keys){$start.Environment[$key]=$Client.environment[$key]}
    foreach($arg in $Argv){$start.ArgumentList.Add($arg)}
    $start
}
function New-VerificationSbxBudget([hashtable]$RunBudget,[int]$CommandSeconds,[long]$MaxOutputBytes) {
    # 呼出し側の期限（deadlineAt・cleanupDeadlineAt・phase）はそのまま、当該コマンドの上限だけを定数で置く（残時間との小さい方は Execution 側が取る）。
    if($null -eq $RunBudget -or -not$RunBudget.ContainsKey('deadlineAt') -or -not$RunBudget.ContainsKey('phase')){Throw-VerificationRuntimeFailure 'RunBudget with deadlineAt and phase required'}
    @{deadlineAt=$RunBudget.deadlineAt;cleanupDeadlineAt=$(if($RunBudget.ContainsKey('cleanupDeadlineAt')){$RunBudget.cleanupDeadlineAt}else{$null});limits=@{maxOutputBytes=$MaxOutputBytes;commandSeconds=$CommandSeconds};phase=$RunBudget.phase}
}
function New-VerificationCleanupBudgetCore([string]$DeadlineAt,[int]$CleanupSeconds,[long]$MaxOutputBytes,[int]$TargetCount) {
    # 停止フェーズの予算: cleanupDeadlineAt = now + cleanupSeconds × 停止対象台数（対象0台なら1台分）。全体期限までの残時間は繰り入れない。
    $count=[Math]::Max(1,$TargetCount)
    @{deadlineAt=$DeadlineAt;cleanupDeadlineAt=[DateTime]::UtcNow.AddSeconds($CleanupSeconds*$count).ToString('o',[Globalization.CultureInfo]::InvariantCulture);limits=@{maxOutputBytes=$MaxOutputBytes;commandSeconds=$script:QuerySeconds};phase='cleanup'}
}
function New-VerificationCleanupBudget([hashtable]$PreparedRun,[int]$TargetCount) {
    if($null -eq $PreparedRun -or -not$PreparedRun.ContainsKey('cleanupSeconds') -or -not$PreparedRun.ContainsKey('deadlineAt')){Throw-VerificationRuntimeFailure 'PreparedRunV3 required'}
    New-VerificationCleanupBudgetCore $PreparedRun.deadlineAt ([int]$PreparedRun.cleanupSeconds) ([long]$PreparedRun.settings.limits.maxOutputBytes) $TargetCount
}
function New-VerificationWorkBudget([hashtable]$PreparedRun) {
    @{deadlineAt=$PreparedRun.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long]$PreparedRun.settings.limits.maxOutputBytes;commandSeconds=$script:QuerySeconds};phase='work'}
}
function Invoke-VerificationSbx([hashtable]$Client,[string[]]$Argv,[hashtable]$Budget,[string]$Tag,[byte[]]$StdinBytes=$null,[bool]$ReadText=$true) {
    # 1回の sbx CLI 起動。出力は client の outDir に連番で残す。
    $script:CommandSequence++
    $basePath=Join-Path $Client.outDir ('{0:D4}-{1}' -f $script:CommandSequence,$Tag)
    $paths=@{stdoutPath=$basePath+'.out';stderrPath=$basePath+'.err'}
    $issuedAt=Get-VerificationUtcNow
    $result=Invoke-VerificationProcessV3 -StartInfo (New-VerificationSbxStartInfo $Client $Argv) -StdinBytes $StdinBytes -OutputPaths $paths -RunBudget $Budget
    $call=@{argv=$Argv;issuedAt=$issuedAt;result=$result;stdout='';stderr='';stdoutPath=$paths.stdoutPath;stderrPath=$paths.stderrPath}
    if($ReadText){
        foreach($pair in @(@('stdoutPath','stdout'),@('stderrPath','stderr'))){if(Test-Path -LiteralPath $paths[$pair[0]]){$call[$pair[1]]=[IO.File]::ReadAllText($paths[$pair[0]],[Text.UTF8Encoding]::new($false))}}
    }
    $call
}
function Test-VerificationSbxCallOk([hashtable]$Call) {
    $r=$Call.result
    $r.started -and $null -eq $r.refusedReason -and -not$r.timedOut -and -not$r.outputExceeded -and $r.exitCode -eq 0
}
function Invoke-VerificationSbxQuery([hashtable]$Client,[string[]]$Argv,[hashtable]$RunBudget,[string]$Tag) {
    # 照会（上限 QuerySeconds）。起動拒否・時間超過・非0終了はすべて取得不能として失敗にする。
    $call=Invoke-VerificationSbx $Client $Argv (New-VerificationSbxBudget $RunBudget $script:QuerySeconds $Client.maxOutputBytes) $Tag
    $r=$call.result
    if(-not$r.started){Throw-VerificationRuntimeFailure "sbx $Tag not started: $($r.refusedReason)" $(if($r.refusedReason -eq 'deadline-reached'){'timed_out'}else{'blocked'}) $(if($r.refusedReason -eq 'deadline-reached'){'deadline-reached'}else{'query-failed'})}
    if($r.timedOut){Throw-VerificationRuntimeFailure "sbx $Tag timed out (limit $($script:QuerySeconds)s)" 'blocked' 'query-timed-out'}
    if($r.outputExceeded -or $r.exitCode -ne 0){Throw-VerificationRuntimeFailure "sbx $Tag failed (exit $($r.exitCode)): $($call.stderr.Trim())" 'blocked' 'query-failed'}
    $call
}
function Invoke-VerificationSbxJson([hashtable]$Client,[string[]]$Argv,[hashtable]$RunBudget,[string]$Tag) {
    $call=Invoke-VerificationSbxQuery $Client $Argv $RunBudget $Tag
    try{$value=$call.stdout | ConvertFrom-Json -AsHashtable -Depth 20 -ErrorAction Stop}catch{Throw-VerificationRuntimeFailure "sbx $Tag returned invalid JSON" 'blocked' 'query-failed'}
    if($value -isnot [hashtable]){Throw-VerificationRuntimeFailure "sbx $Tag must return a JSON object" 'blocked' 'query-failed'}
    $value
}

# ---- デーモンの確認と起動世代 ----
function Get-VerificationDaemonLogLines([string]$Path,[string]$Contains) {
    # daemon.log の各行を JSON として読む（書込み中の共有読取り）。切り詰められた行（実測原文にある）は読み飛ばす。time は UTC の DateTime に、原文は raw に持つ。
    $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try{$reader=[IO.StreamReader]::new($stream,[Text.UTF8Encoding]::new($false));$text=$reader.ReadToEnd()}finally{$stream.Dispose()}
    $lines=[Collections.Generic.List[hashtable]]::new()
    foreach($line in $text.Split("`n")){
        $raw=$line.TrimEnd("`r")
        if(-not$raw.Contains($Contains)){continue}
        try{$item=$raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop}catch{continue}
        if($item -isnot [hashtable] -or -not$item.ContainsKey('msg')){continue}
        $time=$null
        if($item.ContainsKey('time')){
            if($item.time -is [DateTime]){$time=$item.time.ToUniversalTime()}
            elseif($item.time -is [string]){try{$time=[DateTimeOffset]::Parse($item.time,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}catch{}}
        }
        $lines.Add(@{msg=[string]$item.msg;time=$time;runtime=$(if($item.ContainsKey('runtime')){[string]$item.runtime}else{$null});version=$(if($item.ContainsKey('version')){[string]$item.version}else{$null});raw=$raw})
    }
    ,$lines.ToArray()
}
function Get-VerificationRuntimeLogLines([string]$Path,[string]$Name) {
    # 当該 runtime の行だけ（runtime キーがあれば厳密一致。無い行は名前を含めば採る）。
    $lines=Get-VerificationDaemonLogLines $Path $Name
    ,@($lines | Where-Object {$null -eq $_.runtime -or $_.runtime -ceq $Name})
}
function Get-VerificationDaemonStatus([hashtable]$Client,[hashtable]$RunBudget) {
    # 停止中でも呼んでよい唯一の照会（自動起動しないことを実測済み）。running 以外・取得不能は running=false で返す。
    $call=Invoke-VerificationSbx $Client @('daemon','status','--json') (New-VerificationSbxBudget $RunBudget $script:QuerySeconds $Client.maxOutputBytes) 'daemon-status'
    $status=$null
    if(Test-VerificationSbxCallOk $call){try{$status=$call.stdout | ConvertFrom-Json -AsHashtable -ErrorAction Stop}catch{$status=$null}}
    if($status -isnot [hashtable] -or -not$status.ContainsKey('status')){return @{running=$false;status=$null;reason='daemon status unavailable'}}
    @{running=($status.status -ceq 'running');status=$status;reason=$(if($status.status -ceq 'running'){$null}else{"daemon status is '$($status.status)'"})}
}
function Throw-VerificationDaemonNotRunning([string]$Detail) {
    Throw-VerificationRuntimeFailure "sbx daemon is not running ($Detail): 利用者が通常端末でデーモンを起動する必要がある" 'blocked' 'daemon-not-running'
}
function Get-VerificationDaemonInstance([hashtable]$Client,[hashtable]$RunBudget) {
    # 起動世代: daemon status の logs から状態ディレクトリを導き、sandboxd.pid・daemon.log の最後の starting sandboxd 行・OS プロセスの StartTime を対応付ける。取得不能は blocked。
    $daemon=Get-VerificationDaemonStatus $Client $RunBudget
    if(-not$daemon.running){Throw-VerificationDaemonNotRunning $daemon.reason}
    $status=$daemon.status
    foreach($key in @('logs','socket')){if(-not$status.ContainsKey($key) -or $status[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($status[$key])){Throw-VerificationRuntimeFailure "daemon status lacks $key" 'blocked' 'daemon-generation'}}
    $logPath=[IO.Path]::GetFullPath($status.logs)
    if(-not[IO.File]::Exists($logPath)){Throw-VerificationRuntimeFailure 'daemon.log missing' 'blocked' 'daemon-generation'}
    $stateRoot=[IO.Path]::GetDirectoryName($logPath)
    $pidPath=Join-Path $stateRoot 'sandboxd.pid'
    if(-not[IO.File]::Exists($pidPath)){Throw-VerificationRuntimeFailure 'sandboxd.pid missing' 'blocked' 'daemon-generation'}
    $daemonPid=0
    if(-not[int]::TryParse([IO.File]::ReadAllText($pidPath).Trim(),[ref]$daemonPid) -or $daemonPid -le 0){Throw-VerificationRuntimeFailure 'sandboxd.pid unreadable' 'blocked' 'daemon-generation'}
    $logLines=Get-VerificationDaemonLogLines $logPath 'starting sandboxd'
    $startLines=@($logLines | Where-Object {$_.msg -ceq 'starting sandboxd'})
    if($startLines.Count -eq 0){Throw-VerificationRuntimeFailure 'starting sandboxd line missing in daemon.log' 'blocked' 'daemon-generation'}
    $startLine=$startLines[-1]
    $process=Get-Process -Id $daemonPid -ErrorAction SilentlyContinue
    if($null -eq $process){Throw-VerificationRuntimeFailure "daemon process $daemonPid not found" 'blocked' 'daemon-generation'}
    try{$startedAt=$process.StartTime.ToUniversalTime().ToString('o',[Globalization.CultureInfo]::InvariantCulture)}catch{Throw-VerificationRuntimeFailure 'daemon process StartTime unavailable' 'blocked' 'daemon-generation'}
    @{instance=@{pid=$daemonPid;startedAt=$startedAt;version=[string]$startLine.version;socket=[string]$status.socket};stateRoot=$stateRoot;logPath=$logPath;startLogTime=$startLine.time}
}
function Test-VerificationDaemonInstanceEqual([hashtable]$Left,[hashtable]$Right) {
    (ConvertTo-VerificationCanonicalJson $Left) -ceq (ConvertTo-VerificationCanonicalJson $Right)
}

# ---- pilot 排他（同一ログオンセッション内の名前付き Mutex） ----
function Get-VerificationDaemonKey([string]$Socket) {
    # ユーザー名とローカル daemon 接続先の SHA256 先頭16桁。runId・runsRoot は含めない。
    (Get-VerificationCanonicalHash @{user=[Environment]::UserName;socket=$Socket}).Substring(0,16)
}
function Acquire-VerificationPilotLeaseCore([string]$RunId,[string]$DaemonKey) {
    # Global\ は非昇格プロセスで作れないため Local\ を使う（別ログオンセッションからの同時実行は排他できない。README の既知の制約）。
    # 放棄された Mutex も取得扱いにするが、一覧確認（New-VerificationSandbox の ls）は省略しない。取得競合は待たずに blocked。
    if([string]::IsNullOrWhiteSpace($RunId)){Throw-VerificationRuntimeFailure 'runId required'}
    $mutex=[Threading.Mutex]::new($false,('Local\iv-sbx-pilot-'+$DaemonKey))
    $acquired=$false
    try{$acquired=$mutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$acquired=$true}
    if(-not$acquired){$mutex.Dispose();Throw-VerificationRuntimeFailure 'pilot lease is held by another run (稼働中の run がある)' 'blocked' 'lease-conflict'}
    $leaseId=[guid]::NewGuid().ToString()
    $script:PilotLeases[$leaseId]=@{mutex=$mutex;runId=$RunId;daemonKey=$DaemonKey}
    @{runId=$RunId;daemonKey=$DaemonKey;leaseId=$leaseId}
}
function Acquire-VerificationPilotLease([hashtable]$PreparedRun) {
    if($null -eq $PreparedRun -or $PreparedRun.schemaVersion -ne 3 -or -not$PreparedRun.ContainsKey('runId')){Throw-VerificationRuntimeFailure 'PreparedRunV3 required'}
    $client=New-VerificationSbxClient $PreparedRun.settings.sbxPath (Join-Path $PreparedRun.controlRoot 'runtime') ([long]$PreparedRun.settings.limits.maxOutputBytes)
    $daemon=Get-VerificationDaemonStatus $client (New-VerificationWorkBudget $PreparedRun)
    if(-not$daemon.running){Throw-VerificationDaemonNotRunning $daemon.reason}
    if(-not$daemon.status.ContainsKey('socket') -or [string]::IsNullOrWhiteSpace($daemon.status.socket)){Throw-VerificationRuntimeFailure 'daemon status lacks socket' 'blocked' 'daemon-generation'}
    Acquire-VerificationPilotLeaseCore ([string]$PreparedRun.runId) (Get-VerificationDaemonKey ([string]$daemon.status.socket))
}
function Release-VerificationPilotLease([hashtable]$Lease) {
    if($null -eq $Lease -or -not$Lease.ContainsKey('leaseId') -or -not$script:PilotLeases.ContainsKey($Lease.leaseId)){throw 'unknown pilot lease'}
    $entry=$script:PilotLeases[$Lease.leaseId];$script:PilotLeases.Remove($Lease.leaseId)
    try{$entry.mutex.ReleaseMutex()}catch{}   # 取得したスレッド以外からの解放は失敗するが、Dispose でハンドルは閉じる
    $entry.mutex.Dispose()
}
function Test-VerificationLeaseValid([hashtable]$Lease,[string]$RunId) {
    ($null -ne $Lease) -and $Lease.ContainsKey('leaseId') -and $script:PilotLeases.ContainsKey($Lease.leaseId) -and ($script:PilotLeases[$Lease.leaseId].runId -ceq $RunId) -and ($Lease.runId -ceq $RunId)
}

# ---- 作成記録と handle ----
function Get-VerificationSandboxName([string]$RunId,[string]$Role) {
    if(-not$script:RoleSuffix.ContainsKey($Role)){Throw-VerificationRuntimeFailure "unsupported role: $Role"}
    $guid=[guid]::Empty
    if(-not[guid]::TryParse($RunId,[ref]$guid)){Throw-VerificationRuntimeFailure 'runId must be a UUID'}
    'iv-'+$RunId.Substring(0,8).ToLowerInvariant()+'-'+$script:RoleSuffix[$Role]
}
function Get-VerificationHandleRecord([hashtable]$Handle) {
    # 作成記録は handle の JSON 化可能な項目。keepAliveHandle は含めない。
    @{schemaVersion=3;runId=$Handle.runId;role=$Handle.role;name=$Handle.name;id=$Handle.id;createdAt=$Handle.createdAt;profileHash=$Handle.profileHash;effectiveSettingsHash=$Handle.effectiveSettingsHash;activationRecordPath=$Handle.activationRecordPath;activationRecordHash=$Handle.activationRecordHash}
}
function Write-VerificationSandboxRecord([string]$RunRoot,[hashtable]$Handle) {
    # control/runtime/<role>-sandbox.json を CreateNew で書く。復旧操作はこの記録の runId・name・id を正本にする。足場（probe）も同じ形式で書ける。
    foreach($key in @('runId','role','name','id','createdAt')){if(-not$Handle.ContainsKey($key) -or $Handle[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($Handle[$key])){Throw-VerificationRuntimeFailure "handle.$key required"}}
    if(-not$script:RoleSuffix.ContainsKey($Handle.role)){Throw-VerificationRuntimeFailure "unsupported role: $($Handle.role)"}
    $path=Join-Path $RunRoot ('control/runtime/'+$Handle.role+'-sandbox.json')
    Write-VerificationNewFile $path (ConvertTo-VerificationCanonicalJson (Get-VerificationHandleRecord $Handle))
    $path
}
function Update-VerificationSandboxRecord([string]$Path,[hashtable]$Handle) {
    # activation 確定後に自分の作成記録へ activation の2項目を書き足す（作成時の項目は変えない）。
    [IO.File]::WriteAllBytes($Path,[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-VerificationCanonicalJson (Get-VerificationHandleRecord $Handle))))
}
function Get-VerificationSandboxEntry([hashtable]$Handle) {
    if($null -eq $Handle -or -not$Handle.ContainsKey('name') -or -not$script:Sandboxes.ContainsKey($Handle.name)){throw 'unknown sandbox handle'}
    $entry=$script:Sandboxes[$Handle.name]
    if($entry.handle.id -cne $Handle.id -or $entry.handle.runId -cne $Handle.runId){throw 'sandbox handle does not match the recorded sandbox'}
    $entry
}
function Get-VerificationSandboxList([hashtable]$Client,[hashtable]$RunBudget) {
    $list=Invoke-VerificationSbxJson $Client @('ls','--json') $RunBudget 'ls'
    if(-not$list.ContainsKey('sandboxes') -or $list.sandboxes -isnot [Collections.IEnumerable]){Throw-VerificationRuntimeFailure 'ls --json lacks sandboxes' 'blocked' 'query-failed'}
    ,@(foreach($item in $list.sandboxes){
        if($item -isnot [hashtable]){Throw-VerificationRuntimeFailure 'ls --json item must be an object' 'blocked' 'query-failed'}
        foreach($key in @('name','id','status')){if(-not$item.ContainsKey($key) -or $item[$key] -isnot [string]){Throw-VerificationRuntimeFailure "ls --json item lacks $key" 'blocked' 'query-failed'}}
        @{name=$item.name;id=$item.id;status=$item.status}
    })
}

# ---- デーモン単位の確認（VM 不要） ----
function Get-VerificationClipboardImagePaste([hashtable]$Client,[hashtable]$RunBudget) {
    $setting=Invoke-VerificationSbxJson $Client @('settings','get','--json','clipboard.imagePaste') $RunBudget 'settings-clipboard'
    if(-not$setting.ContainsKey('value') -or $setting.value -isnot [bool]){Throw-VerificationRuntimeFailure 'clipboard.imagePaste value unavailable' 'blocked' 'query-failed'}
    [bool]$setting.value
}
function Get-VerificationMcpServerCount([hashtable]$Client,[hashtable]$RunBudget) {
    $mcp=Invoke-VerificationSbxJson $Client @('mcp','ls','--json') $RunBudget 'mcp-ls'
    if(-not$mcp.ContainsKey('servers') -or $null -eq $mcp.servers -or $mcp.servers -isnot [Collections.IEnumerable] -or $mcp.servers -is [string]){Throw-VerificationRuntimeFailure 'mcp ls --json lacks servers' 'blocked' 'query-failed'}
    @($mcp.servers).Count
}

# ---- VM 作成前の再照合 ----
function Test-VerificationPilotInputUnchanged([hashtable]$PreparedRun) {
    $path=[string]$PreparedRun.pilotInputPath
    if(-not[IO.File]::Exists($path)){Throw-VerificationRuntimeFailure 'control/pilot-input.json missing' 'blocked' 'pilot-input'}
    if((Get-VerificationFileHash $path) -ine [string]$PreparedRun.pilotInputHash){Throw-VerificationRuntimeFailure 'control/pilot-input.json does not match PreparedRun.pilotInputHash' 'blocked' 'pilot-input'}
    $record=Read-VerificationJsonFile $path 'pilot input record'
    Test-VerificationRuntimeSchema $record 'pilot-input.schema.json' 'pilot input'
    if($record.inputId -cne [string]$PreparedRun.pilotInputId){Throw-VerificationRuntimeFailure 'pilot input id mismatch' 'blocked' 'pilot-input'}
    $recordRoot=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($record.sourceRoot))
    $runRootSource=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath([string]$PreparedRun.sourceRoot))
    if(-not$recordRoot.Equals($runRootSource,[StringComparison]::OrdinalIgnoreCase)){Throw-VerificationRuntimeFailure 'pilot input sourceRoot does not match PreparedRun' 'blocked' 'pilot-input'}
    if($record.sourceManifestHash -ine [string]$PreparedRun.sourceManifestHash){Throw-VerificationRuntimeFailure 'pilot input sourceManifestHash does not match PreparedRun' 'blocked' 'pilot-input'}
    if(-not[IO.File]::Exists([string]$PreparedRun.sourceManifestPath) -or (Get-VerificationFileHash $PreparedRun.sourceManifestPath) -ine $record.sourceManifestHash){Throw-VerificationRuntimeFailure 'control/source-manifest.json does not match pilot input' 'blocked' 'pilot-input'}
}

# ---- activationRecord ----
function Get-VerificationNetworkRules([hashtable]$Policy) {
    if(-not$Policy.ContainsKey('rules') -or $Policy.rules -isnot [Collections.IEnumerable]){Throw-VerificationRuntimeFailure 'policy ls --json lacks rules' 'blocked' 'query-failed'}
    ,@(foreach($rule in $Policy.rules){
        if($rule -isnot [hashtable] -or -not$rule.ContainsKey('resource_type') -or $rule.resource_type -cne 'network'){continue}
        @{scope=[string]$rule.scope;decision=[string]$rule.decision;resources=@(foreach($r in @($rule.resources)){[string]$r});status=$(if($rule.ContainsKey('status')){[string]$rule.status}else{$null})}
    })
}
function Get-VerificationInspectSummary([hashtable]$Inspect) {
    foreach($key in @('state','image_digest','secrets','mcp_gateway','network_policy')){if(-not$Inspect.ContainsKey($key)){Throw-VerificationRuntimeFailure "inspect --json lacks $key" 'blocked' 'query-failed'}}
    @{state=[string]$Inspect.state;imageDigest=[string]$Inspect.image_digest;secrets=@(foreach($s in @($Inspect.secrets)){@{name=[string]$s.name;source=$(if($s.ContainsKey('source')){[string]$s.source}else{$null})}});mcpGateway=[bool]$Inspect.mcp_gateway;networkPolicy=$Inspect.network_policy}
}
function New-VerificationActivationRecord([hashtable]$Entry,[hashtable]$Profile,[hashtable]$Daemon,[bool]$ClipboardImagePaste,[int]$McpServerCount,[object[]]$List,[hashtable]$RunBudget) {
    # 実効値を inspect・policy ls・runtimes/<name>.json・daemon.log と、(3) で取った clipboard・MCP の転記から組む。期待値と不一致なら例外（呼出し側が停止を試みる）。
    $client=$Entry.client;$name=$Entry.handle.name;$id=$Entry.handle.id
    $inspect=Get-VerificationInspectSummary (Invoke-VerificationSbxJson $client @('inspect',$name,'--json') $RunBudget 'inspect')
    $rules=Get-VerificationNetworkRules (Invoke-VerificationSbxJson $client @('policy','ls',$name,'--json') $RunBudget 'policy-ls')
    $runtimePath=Join-Path $Entry.stateRoot ('runtimes/'+$name+'.json')
    $runtime=Read-VerificationJsonFile $runtimePath 'runtime file'
    if(-not$runtime.ContainsKey('Spec') -or $runtime.Spec -isnot [hashtable]){Throw-VerificationRuntimeFailure 'runtime file lacks Spec' 'blocked' 'activation-mismatch'}
    $spec=$runtime.Spec
    if($runtime.ContainsKey('ID') -and [string]$runtime.ID -cne $id){Throw-VerificationRuntimeFailure 'runtime file ID differs from listed id' 'blocked' 'activation-mismatch'}
    $logLines=Get-VerificationRuntimeLogLines $Entry.logPath $name
    $expectedDigest=$Profile.templateDigest.Substring($Profile.templateDigest.IndexOf('@')+1)
    $denyAll=@($rules | Where-Object {$_.decision -ceq 'deny' -and $_.scope -ceq "sandbox:$name" -and (@($_.resources) -ccontains '*')}).Count -gt 0
    $forwarderLines=@($logLines | Where-Object {$_.msg -ceq 'started SSH agent forwarder'}).Count
    $otherSecrets=@($inspect.secrets | Where-Object {$_.name -cne 'mcpgateway'} | ForEach-Object {$_.name})
    $otherRunning=@($List | Where-Object {$_.id -cne $id -and $_.status -cne 'stopped'} | ForEach-Object {$_.name})
    $checks=@{
        policy=@{verdict=$(if($denyAll -and $inspect.networkPolicy -is [hashtable] -and $inspect.networkPolicy.scope -ceq 'sandbox'){'verified'}else{'failed'});expected=@{networkPolicy=$Profile.policyExpectation.networkPolicy;scope='sandbox'};observed=@{rules=$rules;networkPolicy=$inspect.networkPolicy};source='policy ls <name> --json / inspect --json'}
        mount=@{verdict=$(if([string]$spec.WorkspaceDir -eq '' -and $spec.ShareSkills -eq $false -and $inspect.imageDigest -ceq $expectedDigest -and $inspect.state -ceq 'running'){'verified'}else{'failed'});expected=@{workspaceDir='';shareSkills=$false;imageDigest=$expectedDigest;state='running'};observed=@{workspaceDir=[string]$spec.WorkspaceDir;shareSkills=$spec.ShareSkills;imageDigest=$inspect.imageDigest;state=$inspect.state};source='runtimes/<name>.json / inspect --json'}
        resource=@{verdict=$(if($spec.CPUs -eq 2 -and [string]$spec.Memory -ceq '2g'){'verified'}else{'failed'});expected=@{cpus=2;memory='2g'};observed=@{cpus=$spec.CPUs;memory=$spec.Memory};source='runtimes/<name>.json'}
        credentialExposure=@{verdict=$(if($otherSecrets.Count -eq 0){'verified'}else{'failed'});expected=@{secretsOtherThanMcpGateway=@()};observed=@{secrets=$inspect.secrets};source='inspect --json secrets'}
        sshForwarding=@{verdict=$(if([string]$spec.SSHAgentSocketPath -eq '' -and $forwarderLines -eq 0){'verified'}else{'failed'});expected=@{sshAgentSocketPath='';forwarderLines=0};observed=@{sshAgentSocketPath=[string]$spec.SSHAgentSocketPath;forwarderLines=$forwarderLines};source='runtimes/<name>.json / daemon.log'}
        clipboardImagePaste=@{verdict=$(if(-not$ClipboardImagePaste){'verified'}else{'failed'});expected=@{value=$false};observed=@{value=$ClipboardImagePaste};source='settings get --json clipboard.imagePaste'}
        # ADR-0195: 登録0件で verified。製品が常設するゲートウェイと mcpgateway secret の存在は製品挙動として記録する。
        mcpServers=@{verdict=$(if($McpServerCount -eq 0){'verified'}else{'failed'});expected=@{servers=0};observed=@{servers=$McpServerCount;mcpGateway=$inspect.mcpGateway;mcpgatewaySecret=(@($inspect.secrets | Where-Object {$_.name -ceq 'mcpgateway'}).Count -gt 0)};source='mcp ls --json / inspect --json'}
        # 同時1VMの条件下では他に稼働VMが無いため非該当。根拠は ls --json に他の running が無いこと。
        otherVmTraffic=@{verdict=$(if($otherRunning.Count -eq 0){'not-applicable'}else{'failed'});expected=@{otherRunningSandboxes=@()};observed=@{otherRunningSandboxes=$otherRunning};source='ls --json（同時1VM）'}
    }
    $failed=@(foreach($key in $checks.Keys){if($checks[$key].verdict -ceq 'failed'){$key}})
    $record=@{schemaVersion=3;runId=$Entry.handle.runId;sandboxId=$id;sandboxName=$name;role=$Entry.handle.role;daemonInstance=$Daemon.instance;profileHash=$Entry.handle.profileHash;effectiveSettingsHash=$Entry.handle.effectiveSettingsHash;checkedAt=(Get-VerificationUtcNow);checks=$checks}
    if($failed.Count -gt 0){Throw-VerificationRuntimeFailure ('activation checks failed: '+(($failed | Sort-Object) -join ', ')) 'blocked' 'activation-mismatch'}
    Test-VerificationRuntimeSchema $record 'activation-record.schema.json' 'activation record'
    # 実コマンド直前の維持確認で照合する期待値（作成時の観測値）。
    $expected=@{state='running';imageDigest=$inspect.imageDigest;secrets=(ConvertTo-VerificationCanonicalJson $inspect.secrets);mcpGateway=$inspect.mcpGateway;rules=(ConvertTo-VerificationCanonicalJson $rules);clipboardImagePaste=$ClipboardImagePaste;mcpServers=$McpServerCount}
    @{record=$record;expected=$expected}
}

# ---- セッション保持（ADR-0193） ----
function Start-VerificationSandboxKeepAlive([hashtable]$Entry,[hashtable]$RunBudget) {
    # exec <name> sh -c 'sleep <deadlineAt + cleanupSeconds×3 までの秒数>' を背景起動する。期限で打ち切られず、停止は Stop の手順だけで行う。保持プロセスの終了を VM 停止の証拠にしない。
    $deadline=[DateTimeOffset]::Parse($Entry.deadlineAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
    $seconds=[int][Math]::Max(1,[Math]::Ceiling(($deadline.AddSeconds($Entry.cleanupSeconds*3)-[DateTime]::UtcNow).TotalSeconds))
    $argv=@('exec',$Entry.handle.name,'sh','-c',"sleep $seconds")
    $paths=@{stdoutPath=(Join-Path $Entry.client.outDir 'keepalive.out');stderrPath=(Join-Path $Entry.client.outDir 'keepalive.err')}
    try{Start-VerificationBackgroundProcess -StartInfo (New-VerificationSbxStartInfo $Entry.client $argv) -OutputPaths $paths -RunBudget (New-VerificationSbxBudget $RunBudget $script:QuerySeconds $Entry.client.maxOutputBytes)}
    catch{Throw-VerificationRuntimeFailure ('keep-alive session not started: '+$_.Exception.Message) 'incomplete' 'keepalive-failed'}
}
function Stop-VerificationSandboxKeepAlive([hashtable]$Entry) {
    if($null -eq $Entry.keepAlive){return $null}
    $handle=$Entry.keepAlive;$Entry.keepAlive=$null
    try{$stopped=Stop-VerificationBackgroundProcess -Handle $handle -GraceSeconds $script:KeepAliveStopGraceSeconds;@{stopped=[bool]$stopped.processTreeStopped;exitCode=$stopped.exitCode}}
    catch{@{stopped=$false;error=$_.Exception.Message}}
}

# ---- 停止の手順（内部。公開の Stop-VerificationSandbox と復旧操作が使う） ----
function Get-VerificationBudgetUtc([hashtable]$RunBudget,[string]$Key) {
    [DateTimeOffset]::Parse($RunBudget[$Key],[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
}
function Stop-VerificationSandboxEntry([hashtable]$Entry,[hashtable]$RunBudget) {
    # 保持セッションを生かしたまま stop <name> を1回 → cleanupSeconds 内に ls --json で同一 ID の stopped を確認 → 保持セッションのジョブを止める（ADR-0193 改訂後の順序）。
    # stopped の証拠は ls の同一ID/stopped・stop 発行時刻以後の当該 runtime 行 'stopped runtime container'（自動停止行は証拠にしない）・操作前後の世代不変。揃わなければ unverified。
    if($null -eq $RunBudget -or $RunBudget.phase -cne 'cleanup' -or -not$RunBudget.ContainsKey('cleanupDeadlineAt') -or $null -eq $RunBudget.cleanupDeadlineAt){Throw-VerificationRuntimeFailure 'RunBudget.phase=cleanup with cleanupDeadlineAt required'}
    if($null -ne $Entry.stopResult -and $Entry.stopResult.stopState -ceq 'stopped'){return $Entry.stopResult}   # 停止確認済みの VM へは何も発行しない
    $client=$Entry.client;$name=$Entry.handle.name;$id=$Entry.handle.id
    $evidence=@{schemaVersion=3;runId=$Entry.handle.runId;role=$Entry.handle.role;name=$name;id=$id;budget=@{cleanupDeadlineAt=$RunBudget.cleanupDeadlineAt;cleanupSeconds=$Entry.cleanupSeconds};stopIssuedAt=$null;stopCall=$null;daemonBefore=$null;daemonAfter=$null;listObserved=$null;stopLogLine=$null;keepAlive=$null;stopState='unverified';reason=$null}
    try{
        $before=$null
        try{$before=Get-VerificationDaemonInstance $client $RunBudget;$evidence.daemonBefore=$before.instance}catch{$evidence.reason='daemon generation unavailable before stop: '+$_.Exception.Message}
        if($null -ne $before){
            $generationSame=Test-VerificationDaemonInstanceEqual $before.instance $Entry.daemonInstance
            if(-not$generationSame){$evidence.reason='daemon generation changed before stop'}
            $evidence.stopIssuedAt=Get-VerificationUtcNow
            $issued=[DateTimeOffset]::Parse($evidence.stopIssuedAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
            $stop=Invoke-VerificationSbx $client @('stop',$name) (New-VerificationSbxBudget $RunBudget $script:QuerySeconds $client.maxOutputBytes) 'stop'
            $evidence.stopCall=@{started=$stop.result.started;exitCode=$stop.result.exitCode;timedOut=$stop.result.timedOut;refusedReason=$stop.result.refusedReason;stdoutPath=$stop.stdoutPath}
            $waitUntil=[DateTime]::UtcNow.AddSeconds($Entry.cleanupSeconds)
            $cleanupDeadline=Get-VerificationBudgetUtc $RunBudget 'cleanupDeadlineAt'
            if($cleanupDeadline -lt $waitUntil){$waitUntil=$cleanupDeadline}
            $observed=$null
            while($true){
                try{$list=Get-VerificationSandboxList $client $RunBudget}catch{$evidence.reason='ls unavailable after stop: '+$_.Exception.Message;break}
                $same=@($list | Where-Object {$_.id -ceq $id -and $_.name -ceq $name})
                $observed=$(if($same.Count -eq 1){$same[0].status}else{'not-listed'})
                if($observed -ceq 'stopped' -or [DateTime]::UtcNow -ge $waitUntil){break}
                Start-Sleep -Milliseconds 500
            }
            $evidence.listObserved=$observed
            $runtimeLines=Get-VerificationRuntimeLogLines $Entry.logPath $name
            $stopLines=@($runtimeLines | Where-Object {$_.msg -ceq 'stopped runtime container' -and $null -ne $_.time -and $_.time -ge $issued})
            if($stopLines.Count -gt 0){$evidence.stopLogLine=$stopLines[-1].raw}
            try{$after=Get-VerificationDaemonInstance $client $RunBudget;$evidence.daemonAfter=$after.instance}catch{$evidence.reason='daemon generation unavailable after stop: '+$_.Exception.Message}
            $generationStable=$generationSame -and ($null -ne $evidence.daemonAfter) -and (Test-VerificationDaemonInstanceEqual $before.instance $evidence.daemonAfter)
            if($observed -ceq 'stopped' -and $null -ne $evidence.stopLogLine -and $generationStable){$evidence.stopState='stopped'}
            elseif($null -eq $evidence.reason){
                $missing=@();if($observed -cne 'stopped'){$missing+="ls status '$observed'"};if($null -eq $evidence.stopLogLine){$missing+='no stopped-runtime-container line after stop'};if(-not$generationStable){$missing+='daemon generation not stable'}
                $evidence.reason='stop unverified: '+($missing -join '; ')
            }
        }
    }finally{
        # 保持セッションのジョブ停止は stop 確認の成否に関わらず行う。
        $evidence.keepAlive=Stop-VerificationSandboxKeepAlive $Entry
    }
    $evidencePath=Join-Path $Entry.runtimeDir ($Entry.handle.role+'-stop-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
    Write-VerificationNewFile $evidencePath (ConvertTo-VerificationCanonicalJson $evidence)
    $result=@{stopState=$evidence.stopState;stopIssuedAt=$evidence.stopIssuedAt;evidencePath=$evidencePath;reason=$evidence.reason;name=$name;id=$id}
    $Entry.stopResult=$result
    $result
}

# ---- VM 作成 ----
function New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile,[hashtable]$Lease) {
    # 順序: Lease 検査 → profile 検査 → 固定入力・limits の再照合 → デーモン世代 → デーモン単位の確認（clipboard・MCP）→ 排他内で ls → 固定 argv で create → ls で id 確定
    # → 作成記録 → activationRecord → 保持セッション。失敗は runtimeFailure{creationState,stopState} を例外の Data へ載せ、作成済みなら停止を試みてから投げる。
    $stage='arguments';$creationState='not-created';$stopState='not-created';$handle=$null;$entry=$null;$runId=$null;$client=$null
    try{
        if($null -eq $PreparedRun -or $PreparedRun.schemaVersion -ne 3 -or -not$PreparedRun.ContainsKey('runId')){Throw-VerificationRuntimeFailure 'PreparedRunV3 required'}
        if($Role -notin $script:CreatableRoles){Throw-VerificationRuntimeFailure "unsupported role: $Role"}
        $runId=[string]$PreparedRun.runId;$settings=$PreparedRun.settings
        $stage='lease'
        if(-not(Test-VerificationLeaseValid $Lease $runId)){Throw-VerificationRuntimeFailure 'valid pilot lease for this run required' 'blocked' 'lease-invalid'}
        $stage='profile'
        $profileHash=Test-VerificationRuntimeProfile $Profile $Role $settings
        $effectiveSettingsHash=Get-VerificationEffectiveSettingsHash $Profile $settings
        $stage='pilot-input'
        Test-VerificationPilotInputUnchanged $PreparedRun
        if($settings.limits.cpus -ne 2 -or $settings.limits.memoryMiB -ne 2048){Throw-VerificationRuntimeFailure 'limits must be cpus=2 and memoryMiB=2048' 'blocked' 'limits'}
        $stage='daemon'
        $name=Get-VerificationSandboxName $runId $Role
        $runtimeDir=Join-Path $PreparedRun.controlRoot 'runtime'
        $recordPath=Join-Path $runtimeDir "$Role-sandbox.json"
        if(Test-Path -LiteralPath $recordPath){Throw-VerificationRuntimeFailure "sandbox record already exists for role $Role" 'blocked' 'record-exists'}
        if($script:Sandboxes.ContainsKey($name)){Throw-VerificationRuntimeFailure "sandbox already created in this process: $name" 'blocked' 'record-exists'}
        $client=New-VerificationSbxClient $settings.sbxPath (Join-Path $runtimeDir $Role) ([long]$settings.limits.maxOutputBytes)
        $budget=New-VerificationWorkBudget $PreparedRun
        $daemon=Get-VerificationDaemonInstance $client $budget
        $stage='daemon-settings'
        $clipboard=Get-VerificationClipboardImagePaste $client $budget
        if($clipboard){Throw-VerificationRuntimeFailure 'clipboard.imagePaste must be false' 'blocked' 'daemon-settings'}
        $mcpServers=Get-VerificationMcpServerCount $client $budget
        if($mcpServers -ne 0){Throw-VerificationRuntimeFailure "mcp ls --json lists $mcpServers server(s); none allowed" 'blocked' 'daemon-settings'}
        $stage='list'
        $list=Get-VerificationSandboxList $client $budget
        foreach($vm in $list){
            if($vm.name -ceq $name){Throw-VerificationRuntimeFailure "sandbox name already exists: $name" 'blocked' 'name-exists'}
            if($vm.status -cne 'stopped'){Throw-VerificationRuntimeFailure "another sandbox is not stopped: $($vm.name) ($($vm.status))" 'blocked' 'other-sandbox-active'}
        }
        $stage='create'
        $argv=@('create',$Profile.agent,'--name',$name,'--cpus','2','--memory','2g','--no-share-skills','--deny-network','*','--template',$Profile.templateDigest)
        $createdAt=Get-VerificationUtcNow
        $create=Invoke-VerificationSbx $client $argv (New-VerificationSbxBudget $budget $script:SetupSeconds $client.maxOutputBytes) 'create'
        if(-not$create.result.started -and $create.result.refusedReason -eq 'deadline-reached'){Throw-VerificationRuntimeFailure 'deadline reached before create' 'timed_out' 'deadline-reached'}
        # 作成要求を送った後は、ls で存否を確かめるまで未作成へ推定しない。
        $creationState='unknown';$stopState='unverified'
        $createOk=(Test-VerificationSbxCallOk $create) -and $create.stdout.Contains("Created sandbox $name")
        $stage='confirm-id'
        $after=Get-VerificationSandboxList $client $budget
        $found=@($after | Where-Object {$_.name -ceq $name})
        if($found.Count -eq 0){
            if($createOk){Throw-VerificationRuntimeFailure "create reported success but $name is not listed" 'incomplete' 'create-unlisted'}
            $creationState='not-created';$stopState='not-created'
            $detail=$(if($create.result.timedOut){"timed out (limit $($script:SetupSeconds)s)"}else{"exit $($create.result.exitCode): $($create.stderr.Trim())"})
            Throw-VerificationRuntimeFailure "sbx create failed: $detail" 'blocked' $(if($create.result.timedOut){'create-timed-out'}else{'create-failed'})
        }
        if($found.Count -gt 1){Throw-VerificationRuntimeFailure "duplicate sandbox names listed: $name" 'incomplete' 'create-unlisted'}
        $id=[string]$found[0].id
        $creationState='created'
        $handle=@{runId=$runId;role=$Role;name=$name;id=$id;createdAt=$createdAt;profileHash=$profileHash;effectiveSettingsHash=$effectiveSettingsHash;activationRecordPath=$null;activationRecordHash=$null;keepAliveHandle=$null}
        $entry=@{handle=$handle;client=$client;stateRoot=$daemon.stateRoot;logPath=$daemon.logPath;daemonInstance=$daemon.instance;runRoot=$PreparedRun.runRoot;runtimeDir=$runtimeDir;cleanupSeconds=[int]$PreparedRun.cleanupSeconds;deadlineAt=[string]$PreparedRun.deadlineAt;createdAtUtc=[DateTimeOffset]::Parse($createdAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime;expected=$null;keepAlive=$null;stopResult=$null}
        $script:Sandboxes[$name]=$entry
        $stage='record'
        [void](Write-VerificationSandboxRecord $PreparedRun.runRoot $handle)
        if(-not$createOk){Throw-VerificationRuntimeFailure "sbx create reported failure but $name is listed (exit $($create.result.exitCode))" 'blocked' 'create-failed'}
        if($found[0].status -cne 'running'){Throw-VerificationRuntimeFailure "created sandbox is not running: $($found[0].status)" 'blocked' 'activation-mismatch'}
        $stage='activation'
        $activation=New-VerificationActivationRecord $entry $Profile $daemon $clipboard $mcpServers $after $budget
        $activationPath=Join-Path $runtimeDir "$Role-activation.json"
        Write-VerificationNewFile $activationPath (ConvertTo-VerificationCanonicalJson $activation.record)
        $handle.activationRecordPath=$activationPath;$handle.activationRecordHash=Get-VerificationFileHash $activationPath
        $entry.expected=$activation.expected
        Update-VerificationSandboxRecord $recordPath $handle
        $stage='keep-alive'
        $entry.keepAlive=Start-VerificationSandboxKeepAlive $entry $budget
        $handle.keepAliveHandle=$entry.keepAlive
        return $handle
    }catch{
        $inner=$_.Exception
        $reason=$(if($inner.Data.Contains('reason')){[string]$inner.Data['reason']}else{'runtime-failure'})
        if($creationState -ceq 'created' -and $null -ne $entry){
            # 作成済み ID を保持して停止を試みる（停止予算は現在時刻起点の1台分）。
            try{$stopState=(Stop-VerificationSandboxEntry $entry (New-VerificationCleanupBudgetCore $entry.deadlineAt $entry.cleanupSeconds $client.maxOutputBytes 1)).stopState}catch{$stopState='unverified'}
        }
        $status=$(if($creationState -ceq 'not-created'){if($inner.Data.Contains('status')){[string]$inner.Data['status']}else{'blocked'}}elseif($stopState -ceq 'stopped'){'blocked'}else{'incomplete'})
        $failure=@{schemaVersion=3;runId=$runId;role=$Role;stage=$stage;reason=$reason;message=$inner.Message;creationState=$creationState;handle=$(if($null -ne $handle){Get-VerificationHandleRecord $handle}else{$null});stopState=$stopState}
        $wrapped=[InvalidOperationException]::new("sandbox creation failed at $stage`: $($inner.Message)",$inner)
        $wrapped.Data['status']=$status;$wrapped.Data['stage']=$stage;$wrapped.Data['reason']=$reason;$wrapped.Data['runtimeFailure']=(ConvertTo-VerificationCanonicalJson $failure)
        throw $wrapped
    }
}
function Stop-VerificationSandbox([hashtable]$Handle,[hashtable]$RunBudget) {
    # 呼出し側が停止フェーズの予算（cleanupDeadlineAt = now + cleanupSeconds × 停止対象台数、phase=cleanup）を渡す。stop 自体の上限は照会と同じ QuerySeconds。
    Stop-VerificationSandboxEntry (Get-VerificationSandboxEntry $Handle) $RunBudget
}
Export-ModuleMember -Function Test-VerificationRuntimeProfile,Get-VerificationEffectiveSettingsHash,Acquire-VerificationPilotLease,Release-VerificationPilotLease,New-VerificationSandbox,Stop-VerificationSandbox,Write-VerificationSandboxRecord,New-VerificationCleanupBudget
