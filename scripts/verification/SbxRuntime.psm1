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
$script:ProposalDeniedHosts=@('api.openai.com','openai.com','files.openai.com','registry.npmjs.org','api.github.com','github.com','codeload.github.com','archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com','download.docker.com')
$script:ProposalAllowedHosts=@('auth.openai.com','chatgpt.com')

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
    $expectedPolicy=$(if($profileRole -eq 'proposal'){'allow auth.openai.com chatgpt.com all ports only'}else{'deny *'})
    if($Profile.policyExpectation.networkPolicy -cne $expectedPolicy){Throw-VerificationRuntimeFailure "profile networkPolicy must be $expectedPolicy for $profileRole"}
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
            # ADR-0196: synthetic-pilot では未確認のまま認める条件で、verified と書ける観測は無い（profiles/evidence-checks.md）。verified を付けた証拠は表に無い観測での主張として拒否する。
            if($check.verdict -cne 'unverified'){Throw-VerificationRuntimeFailure "activation check $name must be unverified (ADR-0196)"}
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
function Get-VerificationCreateArgv([string]$Agent,[string]$Name,[string]$Digest) {
    $argv=@('create',$Agent,'--name',$Name,'--cpus','2','--memory','2g','--no-share-skills')
    if($Agent -ceq 'codex'){
        foreach($hostName in $script:ProposalDeniedHosts){$argv+=@('--deny-network',$hostName)}
    }else{$argv+=@('--deny-network','*')}
    $argv+=@('--template',$Digest)
    ,$argv
}
function Get-VerificationProposalNetworkTargets() {
    $targets=@()
    foreach($hostName in $script:ProposalAllowedHosts){
        foreach($port in @(443,8443)){$targets+=@{host=$hostName;port=$port;allowed=$true;target="https://$($hostName):$port"}}
    }
    foreach($hostName in $script:ProposalDeniedHosts+@('example.com')){
        $port=$(if($hostName -in @('archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com')){80}else{443})
        $scheme=$(if($port -eq 80){'http'}else{'https'})
        $targets+=@{host=$hostName;port=$port;allowed=$false;target="$($scheme)://$($hostName):$port"}
    }
    $targets
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
    # 呼出し側の期限（deadlineAt・cleanupDeadlineAt・phase・runId）はそのまま、当該コマンドの上限だけを定数で置く（残時間との小さい方は Execution 側が取る）。
    # runId は run 単位の単調時計の鍵（Execution が壁時計の残りと単調時計の残りの小さい方を取る）。
    if($null -eq $RunBudget -or -not$RunBudget.ContainsKey('deadlineAt') -or -not$RunBudget.ContainsKey('phase')){Throw-VerificationRuntimeFailure 'RunBudget with deadlineAt and phase required'}
    @{deadlineAt=$RunBudget.deadlineAt;cleanupDeadlineAt=$(if($RunBudget.ContainsKey('cleanupDeadlineAt')){$RunBudget.cleanupDeadlineAt}else{$null});limits=@{maxOutputBytes=$MaxOutputBytes;commandSeconds=$CommandSeconds};phase=$RunBudget.phase;runId=$(if($RunBudget.ContainsKey('runId')){$RunBudget.runId}else{$null})}
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
    @{deadlineAt=$PreparedRun.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long]$PreparedRun.settings.limits.maxOutputBytes;commandSeconds=$script:QuerySeconds};phase='work';runId=[string]$PreparedRun.runId}
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
    # 期限到達で照会自体を起動しなかった場合は、デーモン停止ではなく時間超過（呼出し側は作成要求の前なので not-created のまま timed_out を返す）。
    if(-not$call.result.started -and $call.result.refusedReason -eq 'deadline-reached'){Throw-VerificationRuntimeFailure 'deadline reached before sbx daemon status' 'timed_out' 'deadline-reached'}
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
function ConvertTo-VerificationSbxVersion([string]$Value) {
    # 版の表記をそろえる: 前後の空白を除き、最初の空白までの語（daemon.log の起動行は "v0.42.1 <commit>"）の先頭の v を1つ除く。
    $word=([string]$Value).Trim()
    $space=$word.IndexOfAny([char[]]@(' ',"`t"))
    if($space -ge 0){$word=$word.Substring(0,$space)}
    if($word.Length -gt 1 -and ($word[0] -ceq 'v' -or $word[0] -ceq 'V')){$word=$word.Substring(1)}
    $word
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
function Test-VerificationProposalPolicy([object[]]$Checks) {
    $expected=@{}
    foreach($target in Get-VerificationProposalNetworkTargets){$expected["$($target.host):$($target.port)"]=$target.allowed}
    if($Checks.Count -ne $expected.Count){return $false}
    $seen=@{}
    foreach($check in $Checks){
        if($check -isnot [hashtable] -or -not$check.ContainsKey('host') -or -not$check.ContainsKey('allowed')){return $false}
        $hostName=[string]$check.host
        if(-not$expected.ContainsKey($hostName) -or $seen.ContainsKey($hostName) -or $check.allowed -isnot [bool] -or $check.allowed -ne $expected[$hostName]){return $false}
        $seen[$hostName]=$true
    }
    $true
}
function Test-VerificationProposalRules([object[]]$Rules,[string]$Name) {
    # policy ls は実効規則の全体を見る。既知の対照先だけが拒否でも、追加allowがあれば承認範囲外となる。
    $kitHosts=@($script:ProposalAllowedHosts)+@(foreach($hostName in $script:ProposalDeniedHosts){if($hostName -in @('archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com')){"$($hostName):80"}else{$hostName}})
    $allowSeen=@{};$denySeen=@{}
    foreach($rule in $Rules){
        if($rule -isnot [hashtable] -or $rule.status -cne 'active'){continue}
        foreach($resource in @($rule.resources)){
            $hostName=[string]$resource
            if($rule.decision -ceq 'allow'){
                if($kitHosts -cnotcontains $hostName){return $false}
                $allowSeen[$hostName]=$true
            }elseif($rule.decision -ceq 'deny' -and $rule.scope -ceq "sandbox:$Name"){
                if($resource -ceq '*'){return $false}
                $denySeen[$hostName]=$true
            }
        }
    }
    foreach($hostName in $kitHosts){if(-not$allowSeen.ContainsKey($hostName)){return $false}}
    foreach($hostName in $script:ProposalDeniedHosts){if(-not$denySeen.ContainsKey($hostName)){return $false}}
    $true
}
function Get-VerificationProposalPolicyChecks([hashtable]$Client,[string]$Name,[hashtable]$RunBudget) {
    $checks=@()
    foreach($target in Get-VerificationProposalNetworkTargets){
        $result=Invoke-VerificationSbxJson $Client @('policy','check','network','--sandbox',$Name,$target.target,'--json') $RunBudget 'policy-check'
        if(-not$result.ContainsKey('allowed') -or $result.allowed -isnot [bool]){Throw-VerificationRuntimeFailure "policy check lacks boolean allowed for $($target.host):$($target.port)" 'blocked' 'query-failed'}
        $checks+=@{host="$($target.host):$($target.port)";allowed=$result.allowed}
    }
    $checks
}
function Test-VerificationCredentialExposure([string]$Role,[object[]]$Secrets) {
    $allowed=$(if($Role -ceq 'proposal'){@('mcpgateway','openai')}else{@('mcpgateway')})
    foreach($secret in $Secrets){
        if($secret -isnot [hashtable] -or -not$secret.ContainsKey('name') -or $allowed -cnotcontains [string]$secret.name){return $false}
    }
    $true
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
    # 判定に使うキーの存在と型を先に要求する。欠落は $null→'' の変換で期待値と一致してしまい、sbx の版でフィールド名が変わると観測なしで verified になるため。
    # 欠落・型違いは「取得できない」扱いで例外にし、呼出し側が作成済み ID の停止を試みる（runtimeFailure.creationState=created）。
    if(-not$runtime.ContainsKey('ID') -or $runtime.ID -isnot [string]){Throw-VerificationRuntimeFailure 'runtime file lacks string ID' 'blocked' 'activation-mismatch'}
    foreach($pair in @(@('WorkspaceDir','string'),@('SSHAgentSocketPath','string'),@('ShareSkills','bool'),@('CPUs','integer'),@('Memory','string'))){
        $key=$pair[0];$value=$(if($spec.ContainsKey($key)){$spec[$key]}else{$null})
        $typed=switch($pair[1]){'string'{$value -is [string]}'bool'{$value -is [bool]}'integer'{($value -is [int]) -or ($value -is [long])}}
        if(-not$spec.ContainsKey($key) -or -not$typed){Throw-VerificationRuntimeFailure "runtime file Spec.$key is missing or not a $($pair[1])" 'blocked' 'activation-mismatch'}
    }
    if($runtime.ID -cne $id){Throw-VerificationRuntimeFailure 'runtime file ID differs from listed id' 'blocked' 'activation-mismatch'}
    $logLines=Get-VerificationRuntimeLogLines $Entry.logPath $name
    $expectedDigest=$Profile.templateDigest.Substring($Profile.templateDigest.IndexOf('@')+1)
    $denyAll=@($rules | Where-Object {$_.decision -ceq 'deny' -and $_.scope -ceq "sandbox:$name" -and (@($_.resources) -ccontains '*')}).Count -gt 0
    $proposal=($Profile.role -ceq 'proposal')
    $networkChecks=$(if($proposal){@(Get-VerificationProposalPolicyChecks $client $name $RunBudget)}else{@()})
    $policyVerified=$(if($proposal){(Test-VerificationProposalRules $rules $name) -and (Test-VerificationProposalPolicy $networkChecks) -and -not$denyAll}else{$denyAll})
    $forwarderLines=@($logLines | Where-Object {$_.msg -ceq 'started SSH agent forwarder'}).Count
    $allowedSecrets=$(if($proposal){@('mcpgateway','openai')}else{@('mcpgateway')})
    $secretsVerified=Test-VerificationCredentialExposure $Profile.role $inspect.secrets
    $otherRunning=@($List | Where-Object {$_.id -cne $id -and $_.status -cne 'stopped'} | ForEach-Object {$_.name})
    $checks=@{
        policy=@{verdict=$(if($policyVerified -and $inspect.networkPolicy -is [hashtable] -and $inspect.networkPolicy.scope -ceq 'sandbox'){'verified'}else{'failed'});expected=@{networkPolicy=$Profile.policyExpectation.networkPolicy;scope='sandbox'};observed=@{rules=$rules;networkPolicy=$inspect.networkPolicy;networkChecks=$networkChecks};source=$(if($proposal){'policy check network --sandbox <name> --json / policy ls <name> --json / inspect --json'}else{'policy ls <name> --json / inspect --json'})}
        mount=@{verdict=$(if([string]$spec.WorkspaceDir -eq '' -and $spec.ShareSkills -eq $false -and $inspect.imageDigest -ceq $expectedDigest -and $inspect.state -ceq 'running'){'verified'}else{'failed'});expected=@{workspaceDir='';shareSkills=$false;imageDigest=$expectedDigest;state='running'};observed=@{workspaceDir=[string]$spec.WorkspaceDir;shareSkills=$spec.ShareSkills;imageDigest=$inspect.imageDigest;state=$inspect.state};source='runtimes/<name>.json / inspect --json'}
        resource=@{verdict=$(if($spec.CPUs -eq 2 -and [string]$spec.Memory -ceq '2g'){'verified'}else{'failed'});expected=@{cpus=2;memory='2g'};observed=@{cpus=$spec.CPUs;memory=$spec.Memory};source='runtimes/<name>.json'}
        credentialExposure=@{verdict=$(if($secretsVerified){'verified'}else{'failed'});expected=@{allowedServiceNames=$allowedSecrets};observed=@{secrets=$inspect.secrets};source='inspect --json secrets'}
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
    $budget=New-VerificationSbxBudget $RunBudget $script:QuerySeconds $Entry.client.maxOutputBytes
    # 開始マーカーの読取りが ProcessHost の書込みと競合して失敗することがある（断続的。Execution 側の既存欠陥として報告済み）ため、1回だけ再試行する。
    # 失敗した起動は Start-VerificationBackgroundProcess が木ごと止めてから投げる。
    $lastError=$null
    foreach($attempt in @(1,2)){
        $paths=@{stdoutPath=(Join-Path $Entry.client.outDir "keepalive-$attempt.out");stderrPath=(Join-Path $Entry.client.outDir "keepalive-$attempt.err")}
        try{return (Start-VerificationBackgroundProcess -StartInfo (New-VerificationSbxStartInfo $Entry.client $argv) -OutputPaths $paths -RunBudget $budget)}
        catch{$lastError=$_.Exception;if($lastError.Data.Contains('refusedReason')){break}}
    }
    Throw-VerificationRuntimeFailure ('keep-alive session not started: '+$lastError.Message) 'incomplete' 'keepalive-failed'
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
    $problems=[Collections.Generic.List[string]]::new()   # 未確認の理由をすべて集める（上書きしない）
    # 手順の途中の例外（daemon.log を開けない、Execution の再送出など）は問題として記録し、unverified の停止証拠を書くところまで進める。
    # stopResult は例外で抜ける場合も finally で必ず設定し、「停止後はコマンドを出さない」防護（Assert-VerificationSandboxUnchanged）を効かせる。
    $evidencePath=$null;$written=$false
    try{
        try{Invoke-VerificationStopProcedure $Entry $RunBudget $evidence $problems}
        catch{
            # 想定外の例外で手順を打ち切った。例外のあった停止は確認済みにしない。
            $evidence.stopState='unverified'
            $problems.Add('stop procedure failed: '+$_.Exception.Message)
        }finally{
            # 保持セッションのジョブ停止は stop 確認の成否に関わらず行う（Stop-VerificationSandboxKeepAlive は例外を戻り値に変える）。
            $evidence.keepAlive=Stop-VerificationSandboxKeepAlive $Entry
        }
        if($evidence.stopState -cne 'stopped'){$evidence.reason='stop unverified: '+($problems -join '; ')}
        $evidencePath=Join-Path $Entry.runtimeDir ($Entry.handle.role+'-stop-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
        Write-VerificationNewFile $evidencePath (ConvertTo-VerificationCanonicalJson $evidence)
        $written=$true
    }finally{
        # 証拠を書けなかった場合（例外が伝播する）は stopped を名乗らず unverified にする（再試行で証拠を残せるように、確認済みの早期戻りに入れない）。
        $Entry.stopResult=@{stopState=$(if($written){$evidence.stopState}else{'unverified'});stopIssuedAt=$evidence.stopIssuedAt;evidencePath=$(if($written){$evidencePath}else{$null});reason=$(if($written){$evidence.reason}else{'stop evidence was not written'});name=$name;id=$id}
    }
    $Entry.stopResult
}
function Invoke-VerificationStopProcedure([hashtable]$Entry,[hashtable]$RunBudget,[hashtable]$Evidence,[Collections.Generic.List[string]]$Problems) {
    # 停止手順の本体。観測を Evidence に、未確認の理由を Problems に書く。個々の照会の失敗は理由として続け、想定外の例外は呼出し側が理由にする。
    $client=$Entry.client;$name=$Entry.handle.name;$id=$Entry.handle.id;$evidence=$Evidence;$problems=$Problems
    $before=$null
    try{$before=Get-VerificationDaemonInstance $client $RunBudget;$evidence.daemonBefore=$before.instance}catch{$problems.Add('daemon generation unavailable before stop: '+$_.Exception.Message)}
    if($null -ne $before){
        $generationSame=Test-VerificationDaemonInstanceEqual $before.instance $Entry.daemonInstance
        if(-not$generationSame){$problems.Add('daemon generation changed before stop')}
        $evidence.stopIssuedAt=Get-VerificationUtcNow
        $issued=[DateTimeOffset]::Parse($evidence.stopIssuedAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
        $stop=Invoke-VerificationSbx $client @('stop',$name) (New-VerificationSbxBudget $RunBudget $script:QuerySeconds $client.maxOutputBytes) 'stop'
        $evidence.stopCall=@{started=$stop.result.started;exitCode=$stop.result.exitCode;timedOut=$stop.result.timedOut;refusedReason=$stop.result.refusedReason;stdoutPath=$stop.stdoutPath}
        $waitUntil=[DateTime]::UtcNow.AddSeconds($Entry.cleanupSeconds)
        $cleanupDeadline=Get-VerificationBudgetUtc $RunBudget 'cleanupDeadlineAt'
        if($cleanupDeadline -lt $waitUntil){$waitUntil=$cleanupDeadline}
        $observed=$null
        while($true){
            try{$list=Get-VerificationSandboxList $client $RunBudget}catch{$problems.Add('ls unavailable after stop: '+$_.Exception.Message);break}
            $same=@($list | Where-Object {$_.id -ceq $id -and $_.name -ceq $name})
            $observed=$(if($same.Count -eq 1){$same[0].status}else{'not-listed'})
            if($observed -ceq 'stopped' -or [DateTime]::UtcNow -ge $waitUntil){break}
            Start-Sleep -Milliseconds 500
        }
        $evidence.listObserved=$observed
        try{
            $runtimeLines=Get-VerificationRuntimeLogLines $Entry.logPath $name
            $stopLines=@($runtimeLines | Where-Object {$_.msg -ceq 'stopped runtime container' -and $null -ne $_.time -and $_.time -ge $issued})
            if($stopLines.Count -gt 0){$evidence.stopLogLine=$stopLines[-1].raw}
        }catch{$problems.Add('daemon.log unreadable after stop: '+$_.Exception.Message)}
        try{$after=Get-VerificationDaemonInstance $client $RunBudget;$evidence.daemonAfter=$after.instance}catch{$problems.Add('daemon generation unavailable after stop: '+$_.Exception.Message)}
        $generationStable=$generationSame -and ($null -ne $evidence.daemonAfter) -and (Test-VerificationDaemonInstanceEqual $before.instance $evidence.daemonAfter)
        if($observed -ceq 'stopped' -and $null -ne $evidence.stopLogLine -and $generationStable){$evidence.stopState='stopped'}
        else{
            if($observed -cne 'stopped'){$problems.Add("ls status '$observed'")}
            if($null -eq $evidence.stopLogLine){$problems.Add('no stopped-runtime-container line after stop')}
            if(-not$generationStable){$problems.Add('daemon generation not stable')}
        }
    }
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
        # 仕様02「版・テンプレート一致」: 通常起動済みデーモンの版（daemon.log の起動行）が profile の sbxVersion と一致しなければ VM を作らない。
        $daemonVersion=ConvertTo-VerificationSbxVersion ([string]$daemon.instance.version)
        if([string]::IsNullOrEmpty($daemonVersion) -or $daemonVersion -cne (ConvertTo-VerificationSbxVersion ([string]$Profile.sbxVersion))){Throw-VerificationRuntimeFailure "sbx daemon version '$($daemon.instance.version)' does not match profile sbxVersion '$($Profile.sbxVersion)'" 'blocked' 'sbx-version'}
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
        $argv=Get-VerificationCreateArgv $Profile.agent $name $Profile.templateDigest
        $createdAt=Get-VerificationUtcNow
        # 作成要求を送る直前から unknown/unverified とする（仕様02「作成要求送信後に作成成否を確認できない場合はunknown・unverifiedとし、未作成へ推定しない」）。
        # create の呼び出し中・戻り後の例外（出力ファイルの読取り失敗、Invoke-VerificationProcessV3 の例外など）も unknown のまま catch へ入る。
        # not-created へ戻すのは「起動前の拒否（期限到達で何も起動していない）」と「クライアントが自ら終了した後に ls で不在を確かめた」場合だけ。
        $creationState='unknown';$stopState='unverified'
        $create=Invoke-VerificationSbx $client $argv (New-VerificationSbxBudget $budget $script:SetupSeconds $client.maxOutputBytes) 'create'
        $createResult=$create.result
        if(-not$createResult.started -and $createResult.refusedReason -eq 'deadline-reached'){
            # 期限到達で ProcessHost も起動していない（作成要求は送られていない）。
            $creationState='not-created';$stopState='not-created'
            Throw-VerificationRuntimeFailure 'deadline reached before create' 'timed_out' 'deadline-reached'
        }
        $createOk=(Test-VerificationSbxCallOk $create) -and $create.stdout.Contains("Created sandbox $name")
        # ls の不在を「未作成」の確認に使えるのは、クライアントが外側の打ち切りなしに自ら終了した場合か、ホストが対象を起動できずジョブも空になった場合（launch-failed かつ processTreeStopped）だけ。
        # 時間超過・出力超過・起動側の失敗（host-failed）で外側が止めたのはクライアントだけで、デーモン側の作成が止まった保証はなく、ls の後に完成しうる。
        # ジョブ割当の失敗（assign-failed）は、対象（sbx クライアント）が起動済みでジョブ外にあり、作成要求を送った可能性があるので、作成要求の発行済みとして unknown に残す。
        $clientSettled=(-not$createResult.timedOut -and -not$createResult.outputExceeded) -and (($createResult.started -and $null -ne $createResult.exitCode) -or (-not$createResult.started -and $createResult.refusedReason -eq 'launch-failed' -and $createResult.processTreeStopped))
        $createDetail=$(if($createResult.timedOut){"timed out (limit $($script:SetupSeconds)s)"}elseif($createResult.outputExceeded){'output exceeded the limit'}elseif(-not$createResult.started){"not started ($($createResult.refusedReason))"}else{"exit $($createResult.exitCode): $($create.stderr.Trim())"})
        $createReason=$(if($createResult.timedOut){'create-timed-out'}else{'create-failed'})
        $stage='confirm-id'
        $after=Get-VerificationSandboxList $client $budget
        $found=@($after | Where-Object {$_.name -ceq $name})
        if($found.Count -eq 0){
            if($createOk){Throw-VerificationRuntimeFailure "create reported success but $name is not listed" 'incomplete' 'create-unlisted'}
            # 打ち切ったクライアントの作成要求は unknown・unverified のまま返す（呼出し側は incomplete）。記録が無いので復旧操作の対象にならず、後続 run は ls の検査で blocked になりうる。
            if(-not$clientSettled){Throw-VerificationRuntimeFailure "sbx create did not settle ($createDetail); $name is not listed yet but may still be created by the daemon" 'incomplete' $createReason}
            $creationState='not-created';$stopState='not-created'
            Throw-VerificationRuntimeFailure "sbx create failed: $createDetail" 'blocked' $createReason
        }
        if($found.Count -gt 1){Throw-VerificationRuntimeFailure "duplicate sandbox names listed: $name" 'incomplete' 'create-unlisted'}
        $id=[string]$found[0].id
        $creationState='created'
        $handle=@{runId=$runId;role=$Role;name=$name;id=$id;createdAt=$createdAt;profileHash=$profileHash;effectiveSettingsHash=$effectiveSettingsHash;activationRecordPath=$null;activationRecordHash=$null;keepAliveHandle=$null}
        $entry=@{handle=$handle;client=$client;stateRoot=$daemon.stateRoot;logPath=$daemon.logPath;daemonInstance=$daemon.instance;runRoot=$PreparedRun.runRoot;runtimeDir=$runtimeDir;cleanupSeconds=[int]$PreparedRun.cleanupSeconds;deadlineAt=[string]$PreparedRun.deadlineAt;createdAtUtc=[DateTimeOffset]::Parse($createdAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime;expected=$null;keepAlive=$null;stopResult=$null}
        $script:Sandboxes[$name]=$entry
        $stage='record'
        [void](Write-VerificationSandboxRecord $PreparedRun.runRoot $handle)
        # 時間超過などで失敗扱いの create でも、一覧に名前があれば id を確定して作成記録を書き、停止を試みる（catch 側）。
        if(-not$createOk){Throw-VerificationRuntimeFailure "sbx create did not report success but $name is listed ($createDetail)" 'blocked' $createReason}
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
# ---- 実コマンド直前の維持確認（仕様02「各実コマンド直前にも、同じVM id・デーモン起動世代・実効設定が維持されているか確認する」） ----
function Test-VerificationVmPath([string]$Value) {
    # VM 内の固定絶対パス。sh -c へ埋め込むため、単純な区切りと文字だけを受ける。
    if($Value -notmatch '^(/[A-Za-z0-9._-]+)+$'){Throw-VerificationRuntimeFailure "VM path must be an absolute POSIX path with plain segments: $Value"}
}
function Assert-VerificationSandboxUnchanged([hashtable]$Entry,[hashtable]$RunBudget) {
    # 変化・取得不能・自動停止の痕跡があれば実行せず失敗（理由 sandbox-restarted → incomplete、settings-changed → blocked）。
    if($null -ne $Entry.stopResult){Throw-VerificationRuntimeFailure 'sandbox already stopped; no commands after stop' 'blocked' 'sandbox-stopped'}
    if($null -eq $Entry.expected){Throw-VerificationRuntimeFailure 'partial handle (activation incomplete) cannot run commands' 'blocked' 'sandbox-partial'}
    $client=$Entry.client;$name=$Entry.handle.name;$id=$Entry.handle.id;$expected=$Entry.expected
    try{
        $daemon=Get-VerificationDaemonInstance $client $RunBudget
        if(-not(Test-VerificationDaemonInstanceEqual $daemon.instance $Entry.daemonInstance)){Throw-VerificationRuntimeFailure 'daemon generation changed since creation' 'incomplete' 'sandbox-restarted'}
        $list=Get-VerificationSandboxList $client $RunBudget
        $same=@($list | Where-Object {$_.id -ceq $id})
        if($same.Count -ne 1 -or $same[0].name -cne $name -or $same[0].status -cne 'running'){Throw-VerificationRuntimeFailure "sandbox $name is not listed as the same running VM" 'incomplete' 'sandbox-restarted'}
        $lines=Get-VerificationRuntimeLogLines $Entry.logPath $name
        $autoStopped=@($lines | Where-Object {$_.msg -ceq 'auto-stopped runtime after last session disconnected' -and $null -ne $_.time -and $_.time -ge $Entry.createdAtUtc})
        if($autoStopped.Count -gt 0){Throw-VerificationRuntimeFailure 'auto-stop recorded in daemon.log after creation' 'incomplete' 'sandbox-restarted'}
        $inspect=Get-VerificationInspectSummary (Invoke-VerificationSbxJson $client @('inspect',$name,'--json') $RunBudget 'inspect')
        if($inspect.state -cne $expected.state -or $inspect.imageDigest -cne $expected.imageDigest){Throw-VerificationRuntimeFailure 'inspect state or image digest changed' 'incomplete' 'sandbox-restarted'}
        if((ConvertTo-VerificationCanonicalJson $inspect.secrets) -cne $expected.secrets -or $inspect.mcpGateway -ne $expected.mcpGateway){Throw-VerificationRuntimeFailure 'inspect secrets or mcp_gateway changed' 'blocked' 'settings-changed'}
        $rules=Get-VerificationNetworkRules (Invoke-VerificationSbxJson $client @('policy','ls',$name,'--json') $RunBudget 'policy-ls')
        if((ConvertTo-VerificationCanonicalJson $rules) -cne $expected.rules){Throw-VerificationRuntimeFailure 'network policy rules changed' 'blocked' 'settings-changed'}
        if((Get-VerificationClipboardImagePaste $client $RunBudget) -ne $expected.clipboardImagePaste){Throw-VerificationRuntimeFailure 'clipboard.imagePaste changed' 'blocked' 'settings-changed'}
        if((Get-VerificationMcpServerCount $client $RunBudget) -ne $expected.mcpServers){Throw-VerificationRuntimeFailure 'mcp servers changed' 'blocked' 'settings-changed'}
    }catch{
        $reason=$(if($_.Exception.Data.Contains('reason')){[string]$_.Exception.Data['reason']}else{''})
        # 期限到達による照会の起動拒否は、維持確認の失敗（incomplete）に言い換えず時間超過のまま返す。
        if($reason -in @('sandbox-restarted','settings-changed','deadline-reached')){throw}
        # 取得不能（照会失敗・期限）も維持確認の失敗として扱う。
        Throw-VerificationRuntimeFailure ('pre-command check failed: '+$_.Exception.Message) 'incomplete' 'sandbox-restarted'
    }
}

# ---- 実コマンド ----
function Invoke-VerificationSandboxCommand([hashtable]$Handle,[string[]]$Argv,[byte[]]$StdinBytes,[string]$WorkingDirectory,[hashtable]$Environment,[hashtable]$RunBudget,[hashtable]$OutputSignature) {
    # argv は exec -w <wd> [-e K=V...] <name> <argv...> に固定し、stdin は Invoke-VerificationProcessV3 で転送する。
    # transportVerified: 維持確認が成立し、sbx クライアントが開始マーカーを残し、外側の打ち切りなしに終了し、出力署名が指定ストリームにあるとき true。署名なし（Codex 本体）は null。
    $entry=Get-VerificationSandboxEntry $Handle
    if($null -eq $Argv -or $Argv.Count -eq 0){Throw-VerificationRuntimeFailure 'argv required'}
    foreach($arg in $Argv){if($null -eq $arg -or $arg.Length -eq 0){Throw-VerificationRuntimeFailure 'argv elements must be non-empty strings'}}
    Test-VerificationVmPath $WorkingDirectory
    if($null -eq $Environment){$Environment=@{}}
    $envArgs=@()
    foreach($key in @($Environment.Keys | Sort-Object)){
        if($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$'){Throw-VerificationRuntimeFailure "invalid environment variable name: $key"}
        $value=$Environment[$key]
        if($value -isnot [string] -or $value.IndexOfAny([char[]]@([char]0,"`n","`r")) -ge 0){Throw-VerificationRuntimeFailure "invalid environment variable value: $key"}
        $envArgs+=@('-e',"$key=$value")
    }
    if($null -ne $OutputSignature){
        if(-not$OutputSignature.ContainsKey('pattern') -or $OutputSignature.pattern -isnot [string] -or [string]::IsNullOrEmpty($OutputSignature.pattern) -or -not$OutputSignature.ContainsKey('stream') -or $OutputSignature.stream -notin @('stdout','stderr')){Throw-VerificationRuntimeFailure 'OutputSignature must be {pattern, stream=stdout|stderr}'}
    }
    if($null -eq $RunBudget -or -not$RunBudget.ContainsKey('limits') -or $RunBudget.limits -isnot [hashtable]){Throw-VerificationRuntimeFailure 'RunBudget.limits hashtable required'}
    Assert-VerificationSandboxUnchanged $entry $RunBudget
    $full=@('exec','-w',$WorkingDirectory)+$envArgs+@($entry.handle.name)+@($Argv)
    $commandId=$entry.handle.role+'-'+[guid]::NewGuid().ToString('N').Substring(0,12)
    # 署名を要求しない出力（提案本体の Codex 実行）は未信頼データとして quarantine/ に置く。
    $outDir=$(if($null -eq $OutputSignature){Join-Path $entry.runRoot 'quarantine/commands'}else{Join-Path $entry.runtimeDir ($entry.handle.role+'/commands')})
    [void][IO.Directory]::CreateDirectory($outDir)
    $paths=@{stdoutPath=(Join-Path $outDir "$commandId.stdout");stderrPath=(Join-Path $outDir "$commandId.stderr")}
    $budget=@{deadlineAt=$RunBudget.deadlineAt;cleanupDeadlineAt=$(if($RunBudget.ContainsKey('cleanupDeadlineAt')){$RunBudget.cleanupDeadlineAt}else{$null});limits=@{maxOutputBytes=[long]$RunBudget.limits.maxOutputBytes;commandSeconds=[int]$RunBudget.limits.commandSeconds};phase=$RunBudget.phase;runId=$(if($RunBudget.ContainsKey('runId')){$RunBudget.runId}else{$null})}
    $startedAt=Get-VerificationUtcNow
    $result=Invoke-VerificationProcessV3 -StartInfo (New-VerificationSbxStartInfo $entry.client $full) -StdinBytes $StdinBytes -OutputPaths $paths -RunBudget $budget
    $transportVerified=$null
    if($null -ne $OutputSignature){
        $clean=$result.started -and $null -eq $result.refusedReason -and -not$result.timedOut -and -not$result.outputExceeded -and $result.processTreeStopped -and $null -ne $result.exitCode
        $found=$false
        if($clean){
            $streamPath=$paths[$OutputSignature.stream+'Path']
            if(Test-Path -LiteralPath $streamPath){$found=[regex]::IsMatch([IO.File]::ReadAllText($streamPath,[Text.UTF8Encoding]::new($false)),$OutputSignature.pattern,[Text.RegularExpressions.RegexOptions]::Multiline)}
        }
        $transportVerified=[bool]($clean -and $found)
    }
    $record=@{
        commandId=$commandId;runId=$entry.handle.runId;role=$entry.handle.role;sandboxId=$entry.handle.id;argv=$full;workingDirectory=$WorkingDirectory
        startedAt=$startedAt;finishedAt=$result.finishedAt;started=$result.started;refusedReason=$result.refusedReason;exitCode=$result.exitCode
        stdoutPath=$paths.stdoutPath;stdoutHash=$result.stdoutHash;stdoutBytes=$result.stdoutBytes;stderrPath=$paths.stderrPath;stderrHash=$result.stderrHash;stderrBytes=$result.stderrBytes
        timedOut=$result.timedOut;outputExceeded=$result.outputExceeded;processTreeStopped=$result.processTreeStopped;transportVerified=$transportVerified;stopState=$null
    }
    if($result.outputExceeded){
        # 出力超過は当該 VM を停止する（仕様02）。停止予算は現在時刻起点の1台分。
        $stop=Stop-VerificationSandboxEntry $entry (New-VerificationCleanupBudgetCore $entry.deadlineAt $entry.cleanupSeconds $entry.client.maxOutputBytes 1)
        $record.stopState=$stop.stopState
    }
    $record
}

# ---- 搬入と照合 ----
function Get-VerificationExpectedFiles([hashtable]$ExpectedManifest) {
    if($null -eq $ExpectedManifest -or -not$ExpectedManifest.ContainsKey('files')){Throw-VerificationRuntimeFailure 'ExpectedManifest.files required'}
    $map=@{}
    foreach($file in @($ExpectedManifest.files)){
        if($file -isnot [hashtable] -or -not$file.ContainsKey('path') -or -not$file.ContainsKey('sha256')){Throw-VerificationRuntimeFailure 'manifest entries need path and sha256'}
        $path=[string]$file.path
        if([string]::IsNullOrWhiteSpace($path) -or $path.StartsWith('/') -or $path.Contains('\') -or $map.ContainsKey($path)){Throw-VerificationRuntimeFailure "invalid or duplicate manifest path: $path"}
        $map[$path]=@{sha256=([string]$file.sha256).ToUpperInvariant();size=$(if($file.ContainsKey('size')){$file.size}else{$null})}
    }
    $map
}
function Get-VerificationDirectoryFiles([string]$Root) {
    # 搬入元の通常ファイル一覧（相対 POSIX パス → sha256・size）。再解析ポイントは拒否する。
    $rootFull=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    foreach($dir in [IO.Directory]::EnumerateDirectories($rootFull,'*',[IO.SearchOption]::AllDirectories)){if(([IO.DirectoryInfo]::new($dir)).Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationRuntimeFailure "reparse point in trusted input: $dir"}}
    $map=@{}
    foreach($file in [IO.Directory]::EnumerateFiles($rootFull,'*',[IO.SearchOption]::AllDirectories)){
        $info=[IO.FileInfo]::new($file)
        if($info.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationRuntimeFailure "reparse point in trusted input: $file"}
        $map[$file.Substring($rootFull.Length+1).Replace('\','/')]=@{sha256=(Get-VerificationFileHash $file);size=$info.Length}
    }
    $map
}
function Get-VerificationFileMapDifference([hashtable]$Expected,[hashtable]$Actual) {
    $missing=@($Expected.Keys | Where-Object {-not$Actual.ContainsKey($_)} | Sort-Object)
    $unexpected=@($Actual.Keys | Where-Object {-not$Expected.ContainsKey($_)} | Sort-Object)
    $mismatched=@($Expected.Keys | Where-Object {$Actual.ContainsKey($_) -and ($Actual[$_].sha256 -ine $Expected[$_].sha256 -or ($null -ne $Expected[$_].size -and $Actual[$_].ContainsKey('size') -and $Actual[$_].size -ne $Expected[$_].size))} | Sort-Object)
    $parts=@()
    if($missing.Count -gt 0){$parts+='missing: '+($missing -join ', ')}
    if($unexpected.Count -gt 0){$parts+='unexpected: '+($unexpected -join ', ')}
    if($mismatched.Count -gt 0){$parts+='mismatched: '+($mismatched -join ', ')}
    $parts -join '; '
}
function Test-VerificationSetupCall([hashtable]$Call,[string]$Tag) {
    # cp・chown は CommandRecord を持たず、終了0以外を失敗として扱う。
    $r=$Call.result
    # ジョブ割当の失敗（assign-failed）は対象がジョブ外で起動済みでありうる（搬入・所有者調整が外側の上限なしに進みうる）ので、失敗ではなく incomplete にする。
    if(-not$r.started -and $r.refusedReason -eq 'assign-failed'){Throw-VerificationRuntimeFailure "sbx $Tag started outside the job (job assignment failed)" 'incomplete' 'setup-assign-failed'}
    if(-not$r.started){Throw-VerificationRuntimeFailure "sbx $Tag not started: $($r.refusedReason)" $(if($r.refusedReason -eq 'deadline-reached'){'timed_out'}else{'failed'}) 'setup-failed'}
    if($r.timedOut){Throw-VerificationRuntimeFailure "sbx $Tag timed out (limit $($script:SetupSeconds)s)" 'incomplete' 'setup-timed-out'}
    if($r.outputExceeded){Throw-VerificationRuntimeFailure "sbx $Tag output exceeded the limit" 'incomplete' 'setup-output-exceeded'}
    if($r.exitCode -ne 0){Throw-VerificationRuntimeFailure "sbx $Tag failed (exit $($r.exitCode)): $($Call.stderr.Trim())" 'failed' 'setup-failed'}
}
function Copy-VerificationSandboxInput([hashtable]$Handle,[string]$TrustedInputRoot,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget) {
    # 外側で検査済みの通常ファイルだけを固定 Destination へ搬入する。cp を1回、続けて所有者調整（作成・搬入の上限式）。回収には使わない。
    $entry=Get-VerificationSandboxEntry $Handle
    $source=Resolve-VerificationPath $TrustedInputRoot
    if(-not[IO.Directory]::Exists($source)){Throw-VerificationRuntimeFailure 'trusted input root missing'}
    Test-VerificationVmPath $Destination
    $expected=Get-VerificationExpectedFiles $ExpectedManifest
    $actual=Get-VerificationDirectoryFiles $source
    $difference=Get-VerificationFileMapDifference $expected $actual
    if($difference){Throw-VerificationRuntimeFailure "trusted input differs from the expected manifest ($difference)" 'blocked' 'input-changed'}
    Assert-VerificationSandboxUnchanged $entry $RunBudget
    $budget=New-VerificationSbxBudget $RunBudget $script:SetupSeconds $entry.client.maxOutputBytes
    $copy=Invoke-VerificationSbx $entry.client @('cp',$source,($entry.handle.name+':'+$Destination)) $budget 'cp'
    Test-VerificationSetupCall $copy 'cp'
    $chown=Invoke-VerificationSbx $entry.client @('exec','-u','root',$entry.handle.name,'chown','-R','agent:agent',$Destination) $budget 'chown'
    Test-VerificationSetupCall $chown 'chown'
    @{copied=$true;fileCount=$actual.Count;destination=$Destination;copyStdoutPath=$copy.stdoutPath;chownStdoutPath=$chown.stdoutPath}
}
function Confirm-VerificationSandboxInput([hashtable]$Handle,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget) {
    # 固定コマンドで搬入後のハッシュを照会し、外側の ExpectedManifest と照合する。相違・欠落・予定外ファイルは blocked。
    [void](Get-VerificationSandboxEntry $Handle)
    Test-VerificationVmPath $Destination
    $expected=Get-VerificationExpectedFiles $ExpectedManifest
    $argv=@('sh','-c',"cd $Destination && find . -type f -print0 | sort -z | xargs -0 sha256sum")
    $budget=New-VerificationSbxBudget $RunBudget $script:SetupSeconds ([long]$RunBudget.limits.maxOutputBytes)
    $record=Invoke-VerificationSandboxCommand $Handle $argv $null $Destination @{} $budget @{pattern='^[0-9a-f]{64}  \S';stream='stdout'}
    if($record.transportVerified -ne $true -or $record.exitCode -ne 0){Throw-VerificationRuntimeFailure "input confirmation command did not complete (exit $($record.exitCode), transportVerified=$($record.transportVerified))" 'incomplete' 'confirm-failed'}
    $actual=@{}
    foreach($line in [IO.File]::ReadAllLines($record.stdoutPath,[Text.UTF8Encoding]::new($false))){
        if($line.Length -eq 0){continue}
        $match=[regex]::Match($line,'^([0-9a-f]{64})  (?:\./)?(.+)$')
        if(-not$match.Success){Throw-VerificationRuntimeFailure "unexpected sha256sum line: $line" 'blocked' 'confirm-format'}
        $path=$match.Groups[2].Value
        if($actual.ContainsKey($path)){Throw-VerificationRuntimeFailure "duplicate path in sha256sum output: $path" 'blocked' 'confirm-format'}
        $actual[$path]=@{sha256=$match.Groups[1].Value.ToUpperInvariant()}
    }
    $difference=Get-VerificationFileMapDifference $expected $actual
    if($difference){Throw-VerificationRuntimeFailure "sandbox input differs from the expected manifest ($difference)" 'blocked' 'input-mismatch'}
    @{confirmed=$true;fileCount=$actual.Count;commandRecord=$record}
}

# ---- 記録済み ID の復旧停止（ADR-0194） ----
function Save-VerificationRecoveryResult([string]$RuntimeDir,[hashtable]$Result) {
    Test-VerificationRuntimeSchema $Result 'recovery-result.schema.json' 'recovery result'
    Write-VerificationNewFile (Join-Path $RuntimeDir ('recovery-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')) (ConvertTo-VerificationCanonicalJson $Result)
    $Result
}
function Stop-VerificationRecordedSandboxes([string]$RunRoot,[hashtable]$RecoveryInput) {
    # control/runtime/<role>-sandbox.json の runId・name・id を正本に、running の対象だけへ停止手順を適用する。記録に無い VM には触れない。VerificationResultV3 を名乗らない。
    # 読めない作成記録は unverified として列挙して残りを続け、対象ごとの例外も当該対象の unverified にする。
    # Lease 取得後に世代・一覧を照会できなかった場合も、停止を発行せず全対象 unverified（stateBefore=query-failed）の recovery-result を CreateNew で保存し、その結果を返す
    # （CLI は stdout に結果を返して終了値2。理由の説明文は stderr へ出す）。
    if($null -eq $RecoveryInput){Throw-VerificationRuntimeFailure 'RecoveryInput required'}
    Test-VerificationRuntimeSchema $RecoveryInput 'recovery-input.schema.json' 'recovery input'
    if($RecoveryInput.schemaVersion -ne 3){Throw-VerificationRuntimeFailure 'recovery input schemaVersion must be integer 3'}
    foreach($key in @($RecoveryInput.limits.Keys)){$value=$RecoveryInput.limits[$key];if(-not(($value -is [int]) -or ($value -is [long])) -or $value -le 0){Throw-VerificationRuntimeFailure "limits.$key must be a positive integer"}}
    $root=Resolve-VerificationPath $RunRoot
    if(-not[IO.Directory]::Exists($root)){Throw-VerificationRuntimeFailure 'run root missing'}
    $runtimeDir=Join-Path $root 'control/runtime'
    $records=@()   # 記録ファイルごとの @{record(読めなければ null);name;id}
    if([IO.Directory]::Exists($runtimeDir)){
        foreach($file in @(Get-ChildItem -LiteralPath $runtimeDir -File -Filter '*-sandbox.json' | Sort-Object Name)){
            if($file.Name -notmatch '^(proposal|replay-before|replay-after|probe)-sandbox\.json$'){continue}
            $record=$null;$raw=$null
            try{
                $raw=Read-VerificationJsonFile $file.FullName 'sandbox record'
                foreach($key in @('runId','role','name','id')){if(-not$raw.ContainsKey($key) -or $raw[$key] -isnot [string] -or [string]::IsNullOrWhiteSpace($raw[$key])){Throw-VerificationRuntimeFailure "sandbox record lacks $key`: $($file.Name)"}}
                $record=$raw
            }catch{$record=$null}
            # 読めない記録の name・id は、取り出せた値があればそれを、無ければ記録ファイル名を示す印を置く（停止対象として特定できないことを明示し、推定で名指ししない）。
            $known={param($key) if($raw -is [hashtable] -and $raw.ContainsKey($key) -and $raw[$key] -is [string] -and -not[string]::IsNullOrWhiteSpace($raw[$key])){[string]$raw[$key]}else{"(unreadable record: $($file.Name))"}}
            $records+=@{record=$record;name=(& $known 'name');id=(& $known 'id')}
        }
    }
    $readable=@($records | Where-Object {$null -ne $_.record})
    $checkedAt=Get-VerificationUtcNow
    $runId=$(if($readable.Count -gt 0){[string]$readable[0].record.runId}else{$null})
    foreach($item in $readable){if($item.record.runId -cne $runId){Throw-VerificationRuntimeFailure 'sandbox records span multiple runs' 'blocked' 'records-inconsistent'}}
    $cleanupSeconds=[int]$RecoveryInput.limits.cleanupSeconds
    $client=New-VerificationSbxClient $RecoveryInput.sbxPath (Join-Path $runtimeDir 'recovery') ([long]$RecoveryInput.limits.maxOutputBytes)
    $result=@{schemaVersion=3;runId=$runId;checkedAt=$checkedAt;daemonRunning=$false;targetCount=$records.Count;targets=@();lease=$null}
    $unverifiedItem={param($item) @{name=$item.name;id=$item.id;stateBefore='unknown';stopState='unverified';evidencePath=$null}}
    $daemon=Get-VerificationDaemonStatus $client (New-VerificationCleanupBudgetCore $checkedAt $cleanupSeconds $client.maxOutputBytes $records.Count)
    if(-not$daemon.running){
        # 停止中デーモンへ ls を発行しない。記録済みの id/name を列挙だけして全対象 unverified（利用者の通常起動が必要）。
        $result.targets=@(foreach($item in $records){& $unverifiedItem $item})
        return Save-VerificationRecoveryResult $runtimeDir $result
    }
    $result.daemonRunning=$true
    if($records.Count -eq 0){return Save-VerificationRecoveryResult $runtimeDir $result}
    if($readable.Count -eq 0){
        # 停止対象を特定できる記録が無い（すべて読めない）。Lease も照会も使わずに全対象 unverified で保存する。
        $result.targets=@(foreach($item in $records){& $unverifiedItem $item})
        return Save-VerificationRecoveryResult $runtimeDir $result
    }
    $lease=Acquire-VerificationPilotLeaseCore $runId (Get-VerificationDaemonKey ([string]$daemon.status.socket))   # 競合時は「稼働中の run がある」として何もせず blocked
    $queryFailure=$null
    try{
        $result.lease=@{leaseId=$lease.leaseId;daemonKey=$lease.daemonKey}
        $probeBudget=New-VerificationCleanupBudgetCore $checkedAt $cleanupSeconds $client.maxOutputBytes $readable.Count
        $instance=$null;$list=$null
        try{$instance=Get-VerificationDaemonInstance $client $probeBudget;$list=Get-VerificationSandboxList $client $probeBudget}
        catch{
            # 世代・一覧を取れなければ停止を発行せず、全対象を unverified・stateBefore=query-failed で保存して返す（結果の形は変えない。説明文は stderr）。
            $queryFailure=$_
            Write-VerificationStageError 'recovery' 'probe' 'query-failed' $_.Exception
        }
        $targets=@(foreach($item in $records){
            $stateBefore=$(if($null -ne $queryFailure){'query-failed'}else{'unknown'})
            if($null -ne $item.record -and $null -eq $queryFailure){
                $same=@($list | Where-Object {$_.id -ceq $item.record.id -and $_.name -ceq $item.record.name})
                $stateBefore=$(if($same.Count -eq 1){$same[0].status}else{'not-listed'})
            }
            @{item=$item;stateBefore=$stateBefore}
        })
        $toStop=@($targets | Where-Object {$null -ne $_.item.record -and $_.stateBefore -cnotin @('stopped','not-listed','unknown','query-failed')})
        # 現在時刻を起点に新しい予算（startedAt=now、deadlineAt=now、cleanupDeadlineAt=now + cleanupSeconds×対象台数、phase=cleanup）。
        $budget=New-VerificationCleanupBudgetCore $checkedAt $cleanupSeconds $client.maxOutputBytes $toStop.Count
        foreach($target in $targets){
            $item=& $unverifiedItem $target.item
            $item.stateBefore=$target.stateBefore
            $record=$target.item.record
            if($null -ne $record -and $target.stateBefore -ceq 'stopped'){$item.stopState='stopped'}
            elseif($null -ne $record -and $target.stateBefore -cnotin @('not-listed','unknown','query-failed')){
                $entry=@{handle=@{runId=$record.runId;role=$record.role;name=$record.name;id=$record.id};client=$client;stateRoot=$instance.stateRoot;logPath=$instance.logPath;daemonInstance=$instance.instance;runRoot=$root;runtimeDir=$runtimeDir;cleanupSeconds=$cleanupSeconds;deadlineAt=$checkedAt;createdAtUtc=$null;expected=$null;keepAlive=$null;stopResult=$null}
                try{$stop=Stop-VerificationSandboxEntry $entry $budget;$item.stopState=$stop.stopState;$item.evidencePath=$stop.evidencePath}
                catch{
                    # 停止手順は例外でも stopResult を設定する（証拠を書けなかった場合は evidencePath=null・unverified）。
                    $item.stopState='unverified';$item.evidencePath=$(if($null -ne $entry.stopResult){$entry.stopResult.evidencePath}else{$null})
                }
            }
            $result.targets+=$item
        }
    }finally{
        # Lease は必ず解放し、結果は必ず保存する（保存に失敗した場合だけ例外が伝播する。保存できない結果は主張しない）。
        try{Release-VerificationPilotLease $lease}
        finally{$saved=Save-VerificationRecoveryResult $runtimeDir $result}
    }
    $saved
}
Export-ModuleMember -Function Test-VerificationRuntimeProfile,Get-VerificationEffectiveSettingsHash,Get-VerificationCreateArgv,Get-VerificationProposalNetworkTargets,Get-VerificationNetworkRules,Test-VerificationProposalRules,Test-VerificationProposalPolicy,Test-VerificationCredentialExposure,Acquire-VerificationPilotLease,Release-VerificationPilotLease,New-VerificationSandbox,Copy-VerificationSandboxInput,Confirm-VerificationSandboxInput,Invoke-VerificationSandboxCommand,Stop-VerificationSandbox,Stop-VerificationRecordedSandboxes,Write-VerificationSandboxRecord,New-VerificationCleanupBudget
