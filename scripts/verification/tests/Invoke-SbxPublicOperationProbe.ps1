# タスク8b の実証スクリプト。個別承認（2026-09-16、8a と同時）を得た「AIなしの実VM 2台」で、
# SbxRuntime の公開操作（Lease 取得 → VM 作成 → 搬入 → 搬入照合 → 実コマンド → 停止）を replay-before / replay-after の
# 2役で順に呼び、修正前が非0・修正後が0で終わることを外側の記録で取る。
#
# 8a の probe（Invoke-SbxPilotProbe.ps1）と別スクリプトにした理由:
#   8a は「公開操作を通さず固定 argv を直接組み立てる」ことが目的で、自前の足場 run・自己強制終了・-Resume の状態機械を持つ。
#   8b は逆に「公開操作だけを呼ぶ」ことが目的で、通常の SettingsV3 と New-VerificationRun の PreparedRun を使う。
#   同じスクリプトに両方を入れると、足場の作り方・記録の置き場・失敗時の復旧経路がステップごとに分岐して単一責任を失うため、
#   兄弟スクリプトとして分けた（実装計画のファイル表では tests/Invoke-SbxPilotProbe.ps1 が 8a・8b 共通の枠だが、
#   雛形 fixtures/pilot-run/ の読み込みと公開操作の呼び出しはここに閉じる。逸脱として報告する）。
#
# 安全側の約束:
#   - 既存VM（iv-48830e99-probe・iv-sbx-capability-20260914-01・iv-sbx-smoke-20260909-01）へは ls --json の一覧読取りしか行わない。
#   - デーモンの起動・停止・再起動・設定変更・VM 削除は行わない。停止中なら中断して報告する（自分では起動しない）。
#   - 作成後・各観測群の前に daemon.log の当該 runtime 行を読み、create 以後の auto-stopped runtime があれば中断する。
#   - 各観測は取得の都度 runRoot/obs8b/ へファイルとして書く。
#   - 停止が確認できたVMへは以後コマンドを出さない（公開操作側の Assert-VerificationSandboxUnchanged も拒否する）。
[CmdletBinding()]
param(
    # 雛形の置き場（request.json・settings.json・pilot-input.json）。
    [string]$FixtureDir,
    # 足場の親ディレクトリ。この下に runs/（runsRoot）と src-<id>/（sourceRoot）と cfg-<id>/（実体化した設定）を作る。
    # sourceRoot は runsRoot の外に置く（仕様01「runsRoot が sourceRoot を包含する設定を拒否する」）。
    [string]$ScaffoldRoot,
    # 異常終了後の後始末だけを行う入口（記録済みIDだけを停止する。ADR-0194）。
    [string]$StopRecorded,
    # sbx CLI の場所。既定は利用者の通常端末の sbx。実機に触る前の空撃ちで偽sbxへ差し替えるためだけの引数で、
    # 実機の実行では既定値を使う（8a の probe の -HoldSeconds などと同じ、足場専用の引数）。
    [string]$SbxPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:VerificationRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Import-Module (Join-Path $script:VerificationRoot 'RequestCopy.psm1') -DisableNameChecking
Import-Module (Join-Path $script:VerificationRoot 'Execution.psm1') -DisableNameChecking
Import-Module (Join-Path $script:VerificationRoot 'SbxRuntime.psm1') -DisableNameChecking

$script:PreexistingVms=@('iv-48830e99-probe','iv-sbx-capability-20260914-01','iv-sbx-smoke-20260909-01')
$script:SourceDestination='/home/agent/workspace/source'   # Replay.psm1 と同じ搬入先
$script:UnittestArgv=[string[]]@('python3','-m','unittest','discover','-s','.verification-tests','-p','test_*.py','-v')
$script:UnittestSignature=@{pattern='Ran \d+ tests? in';stream='stderr'}   # 8a の実測（要約行は stderr）
$script:Roles=@('replay-before','replay-after')
$script:ObsDir=$null
$script:QuerySeconds=60

# ---- 共通の小道具 ----
function ConvertTo-ProbeJsonSafe($Value) {
    # ConvertFrom-Json は ISO 8601 風の文字列を DateTime にする。正規化JSON は DateTime を受けないので文字列へ戻す。
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
function Read-ProbeJsonFile([string]$Path) { ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))) }
function Get-ProbeFileHash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Write-ProbeObservation([string]$Name,[hashtable]$Value) {
    $path=Join-Path $script:ObsDir ($Name+'.json')
    $retry=1
    while([IO.File]::Exists($path)){$retry++;$path=Join-Path $script:ObsDir ($Name+'-r'+$retry+'.json')}
    Write-VerificationNewFile $path ((ConvertTo-VerificationCanonicalJson (ConvertTo-ProbeJsonSafe $Value))+"`n")
    Write-Host ("  観測を保存: "+[IO.Path]::GetFileName($path))
    $path
}
function Read-ProbeTextHead([string]$Path,[int]$MaxChars=4000) {
    if(-not[IO.File]::Exists($Path)){return ''}
    $text=[IO.File]::ReadAllText($Path,[Text.UTF8Encoding]::new($false))
    if($text.Length -gt $MaxChars){return $text.Substring(0,$MaxChars)+"`n…(truncated)"}
    $text
}

# ---- 読取り専用の sbx 照会（daemon status・ls だけ。VM へは触らない） ----
function New-ProbeSbxEnvironment([string]$SbxPath) {
    $environment=@{}
    foreach($key in @('SystemRoot','USERPROFILE','LOCALAPPDATA','APPDATA','TEMP')){
        $value=[Environment]::GetEnvironmentVariable($key)
        if([string]::IsNullOrEmpty($value)){throw "host environment variable missing: $key"}
        $environment[$key]=$value
    }
    $environment['PATH']=[IO.Path]::GetDirectoryName($SbxPath)
    $environment
}
function Invoke-ProbeQuery([string[]]$Argv,[string]$Tag) {
    # 一覧・状態の読取りだけに使う（承認範囲: 既存VMは ls --json の一覧読取りのみ）。
    $start=[Diagnostics.ProcessStartInfo]::new($script:SbxPath)
    $start.WorkingDirectory=$script:QueryDir;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.Environment.Clear();foreach($key in $script:SbxEnvironment.Keys){$start.Environment[$key]=$script:SbxEnvironment[$key]}
    foreach($arg in $Argv){$start.ArgumentList.Add($arg)}
    $script:QuerySequence++
    $base=Join-Path $script:QueryDir ('{0:D3}-{1}' -f $script:QuerySequence,$Tag)
    $paths=@{stdoutPath=$base+'.out';stderrPath=$base+'.err'}
    $budget=@{deadlineAt=[DateTime]::UtcNow.AddSeconds(600).ToString('o',[Globalization.CultureInfo]::InvariantCulture);cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long]16777216;commandSeconds=$script:QuerySeconds};phase='work'}
    $result=Invoke-VerificationProcessV3 -StartInfo $start -StdinBytes $null -OutputPaths $paths -RunBudget $budget
    if(-not($result.started -and $null -eq $result.refusedReason -and -not$result.timedOut -and -not$result.outputExceeded -and $result.exitCode -eq 0)){
        throw ("sbx $Tag failed: exit=$($result.exitCode) started=$($result.started) refused=$($result.refusedReason) timedOut=$($result.timedOut)")
    }
    ConvertFrom-ProbeJsonText ([IO.File]::ReadAllText($paths.stdoutPath,[Text.UTF8Encoding]::new($false)))
}
function Get-ProbeSandboxList() {
    $list=Invoke-ProbeQuery @('ls','--json') 'ls'
    ,@(foreach($item in @($list.sandboxes)){@{name=[string]$item.name;id=[string]$item.id;status=[string]$item.status}})
}
function Get-ProbeDaemonStatus() { Invoke-ProbeQuery @('daemon','status','--json') 'daemon-status' }

# ---- daemon.log の当該 runtime 行（自動停止の痕跡） ----
function Get-ProbeRuntimeLines([string]$Name) {
    $stream=[IO.File]::Open($script:DaemonLogPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try{$reader=[IO.StreamReader]::new($stream,[Text.UTF8Encoding]::new($false));$text=$reader.ReadToEnd()}finally{$stream.Dispose()}
    $lines=[Collections.Generic.List[hashtable]]::new()
    foreach($raw in $text.Split("`n")){
        $line=$raw.TrimEnd("`r")
        if(-not$line.Contains($Name)){continue}
        try{$item=$line | ConvertFrom-Json -AsHashtable -ErrorAction Stop}catch{continue}
        if($item -isnot [hashtable] -or -not$item.ContainsKey('msg')){continue}
        if($item.ContainsKey('runtime') -and ([string]$item.runtime) -cne $Name){continue}
        $time=$null
        if($item.ContainsKey('time')){
            if($item.time -is [string]){try{$time=[DateTimeOffset]::Parse($item.time,[Globalization.CultureInfo]::InvariantCulture).UtcDateTime}catch{}}
            elseif($item.time -is [DateTime]){$time=$item.time.ToUniversalTime()}
        }
        $lines.Add(@{msg=[string]$item.msg;time=$(if($null -ne $time){$time.ToString('o',[Globalization.CultureInfo]::InvariantCulture)}else{$null});raw=$line})
    }
    ,@($lines.ToArray())
}
function Get-ProbeAutoStopLines([string]$Name,[string]$SinceUtc) {
    $since=[DateTimeOffset]::Parse($SinceUtc,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
    @((Get-ProbeRuntimeLines $Name) | Where-Object {$_.msg -ceq 'auto-stopped runtime after last session disconnected' -and $null -ne $_.time -and ([DateTimeOffset]::Parse($_.time,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime) -ge $since})
}
function Assert-ProbeNoAutoStop([string]$Name,[string]$SinceUtc,[string]$Where) {
    $lines=@(Get-ProbeAutoStopLines $Name $SinceUtc)
    if($lines.Count -gt 0){
        [void](Write-ProbeObservation ('abandoned-autostop-'+$Where) @{where=$Where;name=$Name;checkedAt=(Get-VerificationUtcNow);lines=@($lines)})
        throw "auto-stopped runtime が daemon.log に現れた（$Where / $Name）。安全規則により以後の観測を中止する。"
    }
}

# ---- 足場（雛形の実体化・独立 Git 作業ツリーの複製・run 準備） ----
function Expand-ProbeTemplate([string]$TemplatePath,[hashtable]$Values,[string]$OutPath) {
    $text=[IO.File]::ReadAllText($TemplatePath,[Text.UTF8Encoding]::new($false)).Replace("`r`n","`n")
    foreach($key in $Values.Keys){$text=$text.Replace('{{'+$key+'}}',([string]$Values[$key]).Replace('\','/'))}
    if($text.Contains('{{')){throw "unresolved placeholder in $TemplatePath"}
    Write-VerificationNewFile $OutPath $text
    $OutPath
}
function Invoke-ProbeGit([string]$Root,[string[]]$Arguments) {
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Command git -ErrorAction Stop).Source)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true;$start.WorkingDirectory=$Root
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($arg in $Arguments){$start.ArgumentList.Add($arg)}
    $process=[Diagnostics.Process]::Start($start)
    try{
        $out=$process.StandardOutput.ReadToEndAsync();$err=$process.StandardError.ReadToEndAsync()
        if(-not$process.WaitForExit(60000)){$process.Kill($true);throw 'git timed out'}
        if($process.ExitCode -ne 0){throw ("git "+($Arguments -join ' ')+" failed: "+$err.GetAwaiter().GetResult())}
        $out.GetAwaiter().GetResult()
    }finally{$process.Dispose()}
}
function New-ProbeSourceCopy([string]$Destination) {
    # 合成題材 fixtures/pilot-source/source/ を、リポジトリ本体の履歴を持ち込まない独立した Git 作業ツリーとして複製する
    # （仕様01「sourceRoot must be Git worktree root」。runsRoot の外に置く）。
    [void][IO.Directory]::CreateDirectory($Destination)
    $sourceDir=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'fixtures/pilot-source/source')))
    foreach($file in [IO.Directory]::EnumerateFiles($sourceDir,'*',[IO.SearchOption]::AllDirectories)){
        $relative=$file.Substring($sourceDir.Length+1)
        $target=Join-Path $Destination $relative
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
        [IO.File]::Copy($file,$target,$false)
    }
    [void](Invoke-ProbeGit $Destination @('init','--quiet'))
    [void](Invoke-ProbeGit $Destination @('config','user.name','task8b-probe'))
    [void](Invoke-ProbeGit $Destination @('config','user.email','task8b-probe@example.invalid'))
    [void](Invoke-ProbeGit $Destination @('config','commit.gpgsign','false'))
    [void](Invoke-ProbeGit $Destination @('add','--all'))
    [void](Invoke-ProbeGit $Destination @('commit','--quiet','-m','pilot-source の基準版（タスク8b の合成題材）'))
    @{root=$Destination;head=(Invoke-ProbeGit $Destination @('rev-parse','HEAD')).Trim()}
}
function Get-ProbeDirectoryManifest([string]$Root) {
    # 搬入元の通常ファイル一覧（相対 POSIX パス）。ExpectedManifest の形（files[{path,size,sha256}]）で返す。
    $rootFull=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    $files=[Collections.Generic.List[object]]::new()
    foreach($file in @([IO.Directory]::EnumerateFiles($rootFull,'*',[IO.SearchOption]::AllDirectories) | Sort-Object)){
        $info=[IO.FileInfo]::new($file)
        $files.Add(@{path=$file.Substring($rootFull.Length+1).Replace('\','/');size=$info.Length;sha256=(Get-ProbeFileHash $file)})
    }
    @{files=@($files.ToArray())}
}
function New-ProbeReplayInput([string]$Role,[string]$Destination,[string]$BaselineRoot,[string]$ReplacementDir,[string]$TestsDir) {
    # before = 基準版の作業ファイル、after = 同じ作業ファイルに replacement を上書きしたもの。tests はどちらも .verification-tests/ 直下に平置き。
    # .git は搬入しない（Replay.psm1 の replay-inputs 生成と同じ約束）。
    [void][IO.Directory]::CreateDirectory($Destination)
    $baselineFull=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($BaselineRoot))
    foreach($file in [IO.Directory]::EnumerateFiles($baselineFull,'*',[IO.SearchOption]::AllDirectories)){
        $relative=$file.Substring($baselineFull.Length+1).Replace('\','/')
        if($relative -ceq '.git' -or $relative.StartsWith('.git/')){continue}
        $target=Join-Path $Destination $relative
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
        [IO.File]::Copy($file,$target,$false)
    }
    if($Role -ceq 'replay-after'){
        $replacementFull=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($ReplacementDir))
        foreach($file in [IO.Directory]::EnumerateFiles($replacementFull,'*',[IO.SearchOption]::AllDirectories)){
            $relative=$file.Substring($replacementFull.Length+1).Replace('\','/')
            $target=Join-Path $Destination $relative
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            [IO.File]::Copy($file,$target,$true)
        }
    }
    $testsTarget=Join-Path $Destination '.verification-tests'
    [void][IO.Directory]::CreateDirectory($testsTarget)
    foreach($file in [IO.Directory]::EnumerateFiles([IO.Path]::GetFullPath($TestsDir),'*',[IO.SearchOption]::AllDirectories)){
        [IO.File]::Copy($file,(Join-Path $testsTarget ([IO.Path]::GetFileName($file))),$false)
    }
    $Destination
}

# =====================================================================
# 異常終了後の後始末だけを行う入口
# =====================================================================
if($StopRecorded){
    $runRoot=Resolve-VerificationPath $StopRecorded
    $settings=Read-ProbeJsonFile (Join-Path $runRoot 'control/settings-used.json')
    $recovery=Stop-VerificationRecordedSandboxes $runRoot @{schemaVersion=3;sbxPath=$settings.sbxPath;pwshPath=$settings.pwshPath;runsRoot=$settings.runsRoot;limits=$settings.limits}
    Write-Host ("復旧操作: 対象 $($recovery.targetCount) 件 / "+((@($recovery.targets) | ForEach-Object {"$($_.name)=$($_.stopState)(before=$($_.stateBefore))"}) -join ', '))
    return
}

# =====================================================================
# 本体
# =====================================================================
if(-not$FixtureDir){$FixtureDir=Join-Path $PSScriptRoot 'fixtures/pilot-run'}
if(-not$ScaffoldRoot){$ScaffoldRoot=Join-Path ([IO.Path]::GetFullPath((Join-Path $script:VerificationRoot '../..'))) '.tmp/p8b'}
$FixtureDir=Resolve-VerificationPath $FixtureDir
$ScaffoldRoot=Resolve-VerificationPath $ScaffoldRoot
$scaffoldId=[guid]::NewGuid().ToString('N').Substring(0,8)
$runsRoot=Join-Path $ScaffoldRoot 'runs'
$sourceRoot=Join-Path $ScaffoldRoot ('src-'+$scaffoldId)      # runsRoot の外（仕様01）
$configRoot=Join-Path $ScaffoldRoot ('cfg-'+$scaffoldId)
[void][IO.Directory]::CreateDirectory($runsRoot)
[void][IO.Directory]::CreateDirectory($configRoot)
$script:QueryDir=Join-Path $configRoot 'queries'
[void][IO.Directory]::CreateDirectory($script:QueryDir)
$script:QuerySequence=0
$script:ObsDir=$configRoot   # run 準備前の観測はここへ（準備後に runRoot/obs8b へ移す）

if(-not$SbxPath){$SbxPath='C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe'}
$pwshPath=(Get-Process -Id $PID).Path
$script:SbxPath=Resolve-VerificationPath $SbxPath
$script:SbxEnvironment=New-ProbeSbxEnvironment $script:SbxPath

$lease=$null;$handles=@{};$prepared=$null
try{
    # ---- 00: デーモンと既存VMの確認（他VMは一覧読取りだけ） ----
    Write-Host '=== 00-preflight: デーモン・既存VM・profile 検査 ==='
    $status=Get-ProbeDaemonStatus
    if([string]$status.status -cne 'running'){throw 'sbx daemon is not running: 利用者が通常端末でデーモンを起動する必要がある（本スクリプトは起動しない）'}
    $script:DaemonLogPath=[IO.Path]::GetFullPath([string]$status.logs)
    $listBefore=Get-ProbeSandboxList
    foreach($vm in $listBefore){if($vm.status -cne 'stopped'){throw "既存VMが停止していない: $($vm.name) ($($vm.status))"}}

    # profile 検査（8a が生成した profiles/replay/ が replay-before / replay-after の両方で通ること）
    $replayProfilePath=Join-Path $script:VerificationRoot 'profiles/replay/profile.json'
    $proposalProfilePath=Join-Path $script:VerificationRoot 'profiles/proposal/profile.json'
    $pilotInputPath=Join-Path $configRoot 'pilot-input.json'
    $settingsPath=Expand-ProbeTemplate (Join-Path $FixtureDir 'settings.json') @{
        sbxPath=$script:SbxPath;pwshPath=$pwshPath;runsRoot=$runsRoot
        proposalProfilePath=$proposalProfilePath;replayProfilePath=$replayProfilePath;pilotInputPath=$pilotInputPath
    } (Join-Path $configRoot 'settings.json')
    $settings=Read-ProbeJsonFile $settingsPath
    $runtimeProfile=Read-ProbeJsonFile $replayProfilePath
    $profileHashes=@{}
    foreach($role in $script:Roles){$profileHashes[$role]=Test-VerificationRuntimeProfile $runtimeProfile $role $settings}
    $effectiveSettingsHash=Get-VerificationEffectiveSettingsHash $runtimeProfile $settings
    [void](Write-ProbeObservation '00-preflight' @{checkedAt=(Get-VerificationUtcNow);daemonStatus=$status;listBefore=@($listBefore)
        replayProfilePath=$replayProfilePath;profileHashes=$profileHashes;effectiveSettingsHash=$effectiveSettingsHash})

    # ---- 01: 足場（題材の複製・雛形の実体化・run 準備） ----
    Write-Host '=== 01-scaffold: 独立 Git 作業ツリーの複製と New-VerificationRun ==='
    $copy=New-ProbeSourceCopy $sourceRoot
    $requestPath=Expand-ProbeTemplate (Join-Path $FixtureDir 'request.json') @{sourceRoot=$sourceRoot} (Join-Path $configRoot 'request.json')
    $request=Read-ProbeJsonFile $requestPath
    # 固定入力記録の sourceManifestHash は New-VerificationRun が control/source-manifest.json に書く正規化JSONの SHA256 と同じ値。
    $sourceManifest=Get-VerificationSourceManifest $request $settings
    $sourceManifestHash=Get-VerificationCanonicalHash $sourceManifest
    [void](Expand-ProbeTemplate (Join-Path $FixtureDir 'pilot-input.json') @{sourceRoot=$sourceRoot;sourceManifestHash=$sourceManifestHash} $pilotInputPath)
    $startedAt=Get-VerificationUtcNow
    $prepared=New-VerificationRun $request $settings $startedAt
    $runRoot=[string]$prepared.runRoot
    $script:ObsDir=Join-Path $runRoot 'obs8b'
    [void][IO.Directory]::CreateDirectory($script:ObsDir)
    # 後始末入口（-StopRecorded）が読む設定の控え。
    Write-VerificationNewFile (Join-Path $runRoot 'control/settings-used.json') ((ConvertTo-VerificationCanonicalJson $settings)+"`n")
    Write-Host ("  runId=$($prepared.runId) / runRoot=$runRoot")
    [void](Write-ProbeObservation '01-scaffold' @{checkedAt=(Get-VerificationUtcNow);scaffoldId=$scaffoldId;sourceRoot=$sourceRoot;sourceHead=$copy.head
        sourceManifestHash=$sourceManifestHash;requestPath=$requestPath;settingsPath=$settingsPath;pilotInputPath=$pilotInputPath
        runId=$prepared.runId;runRoot=$runRoot;startedAt=$startedAt;deadlineAt=$prepared.deadlineAt
        preparedSourceManifestHash=$prepared.sourceManifestHash;pilotInputId=$prepared.pilotInputId
        expectedNames=@(foreach($r in $script:Roles){'iv-'+([string]$prepared.runId).Substring(0,8)+'-'+$(if($r -ceq 'replay-before'){'before'}else{'after'})})})

    # ---- 02: VM の外で before / after の入力を組む ----
    Write-Host '=== 02-inputs: before / after の搬入元と manifest ==='
    $fixtures=Join-Path $PSScriptRoot 'fixtures/pilot-source'
    $inputs=@{}
    foreach($role in $script:Roles){
        $dir=Join-Path $runRoot ('replay-inputs/'+$(if($role -ceq 'replay-before'){'before'}else{'after'}))
        [void](New-ProbeReplayInput $role $dir $prepared.baselineRoot (Join-Path $fixtures 'replacements') (Join-Path $fixtures 'tests'))
        $manifest=Get-ProbeDirectoryManifest $dir
        $manifestPath=Join-Path $runRoot ('control/replay/'+$role+'-input-manifest.json')
        Write-VerificationNewFile $manifestPath (ConvertTo-VerificationCanonicalJson @{schemaVersion=3;runId=$prepared.runId;role=$role;files=$manifest.files})
        $inputs[$role]=@{root=$dir;manifest=$manifest;manifestPath=$manifestPath;manifestHash=(Get-ProbeFileHash $manifestPath)}
    }
    [void](Write-ProbeObservation '02-inputs' @{checkedAt=(Get-VerificationUtcNow);inputs=$inputs})

    # ---- 03: 公開操作（役割ごとに順に） ----
    $workBudget=@{deadlineAt=$prepared.deadlineAt;cleanupDeadlineAt=$null;limits=@{maxOutputBytes=[long]$settings.limits.maxOutputBytes;commandSeconds=[int]$settings.limits.replaySeconds};phase='work';runId=[string]$prepared.runId}
    Write-Host '=== 03-operations: Acquire-VerificationPilotLease ==='
    # Lease は run 単位の排他なので1回だけ取り、両役を通してから解放する（実装計画の 8b の手順どおり。
    # 同一プロセスで二重取得すると Mutex の再入と解放順序の扱いが増えるため、取得は1回にした）。
    $lease=Acquire-VerificationPilotLease $prepared
    $roleResults=@{}
    foreach($role in $script:Roles){
        Write-Host ("=== 03-"+$role+": 作成 → 搬入 → 搬入照合 → unittest → 停止 ===")
        $handle=New-VerificationSandbox $prepared $role $runtimeProfile $lease
        $handles[$role]=$handle
        Write-Host ("  VM 作成: $($handle.name) / $($handle.id)")
        Assert-ProbeNoAutoStop $handle.name $handle.createdAt "$role-after-create"
        $activation=Read-ProbeJsonFile $handle.activationRecordPath
        $copyResult=Copy-VerificationSandboxInput $handle $inputs[$role].root $script:SourceDestination $inputs[$role].manifest $workBudget
        Assert-ProbeNoAutoStop $handle.name $handle.createdAt "$role-after-copy"
        $confirmResult=Confirm-VerificationSandboxInput $handle $script:SourceDestination $inputs[$role].manifest $workBudget
        Assert-ProbeNoAutoStop $handle.name $handle.createdAt "$role-after-confirm"
        $command=Invoke-VerificationSandboxCommand $handle $script:UnittestArgv $null $script:SourceDestination @{} $workBudget $script:UnittestSignature
        Write-Host ("  unittest: exitCode=$($command.exitCode) transportVerified=$($command.transportVerified)")
        $stop=Stop-VerificationSandbox $handle (New-VerificationCleanupBudget $prepared 1)
        Write-Host ("  停止: stopState=$($stop.stopState)")
        $listAfterStop=Get-ProbeSandboxList
        $stopEvidence=$(if($stop.evidencePath -and [IO.File]::Exists($stop.evidencePath)){Read-ProbeJsonFile $stop.evidencePath}else{$null})
        $roleResults[$role]=@{
            handle=$handle;activationRecord=$activation;copy=$copyResult
            confirm=@{confirmed=$confirmResult.confirmed;fileCount=$confirmResult.fileCount;commandRecord=$confirmResult.commandRecord}
            command=$command;stop=$stop;stopEvidence=$stopEvidence;listAfterStop=@($listAfterStop)
            stdoutText=(Read-ProbeTextHead $command.stdoutPath);stderrText=(Read-ProbeTextHead $command.stderrPath)
        }
        [void](Write-ProbeObservation ('03-'+$role) $roleResults[$role])
        if($stop.stopState -cne 'stopped'){throw "$role の停止が確認できなかった: $($stop.stopState)"}
    }

    # ---- 04: 判定と最終確認 ----
    Write-Host '=== 04-verdict: 判定と最終の ls ==='
    Release-VerificationPilotLease $lease;$lease=$null
    $listFinal=Get-ProbeSandboxList
    $before=$roleResults['replay-before'];$after=$roleResults['replay-after']
    $verdict=@{
        checkedAt=(Get-VerificationUtcNow)
        beforeExitCode=$before.command.exitCode;afterExitCode=$after.command.exitCode
        beforeNonZero=($null -ne $before.command.exitCode -and $before.command.exitCode -ne 0)
        afterZero=($after.command.exitCode -eq 0)
        transportVerified=@{'replay-before'=$before.command.transportVerified;'replay-after'=$after.command.transportVerified}
        sandboxIds=@{'replay-before'=$before.handle.id;'replay-after'=$after.handle.id}
        idsDiffer=($before.handle.id -cne $after.handle.id)
        idsDifferFromProbeVm=(@($before.handle.id,$after.handle.id) -notcontains 'f0272f46-49bb-4d67-99ba-12468c153c6b')
        stopStates=@{'replay-before'=$before.stop.stopState;'replay-after'=$after.stop.stopState}
        listFinal=@($listFinal)
        preexistingUnchanged=@(foreach($name in $script:PreexistingVms){
            $b=@($listBefore | Where-Object {$_.name -ceq $name});$f=@($listFinal | Where-Object {$_.name -ceq $name})
            @{name=$name;before=$(if($b.Count -eq 1){$b[0]}else{$null});after=$(if($f.Count -eq 1){$f[0]}else{$null});unchanged=($b.Count -eq 1 -and $f.Count -eq 1 -and $b[0].id -ceq $f[0].id -and $b[0].status -ceq $f[0].status)}})
        # 発行した sbx コマンドの痕跡（control/runtime 配下の出力ファイル名の tag）。stop は各役の1本だけであることの確認に使う。
        sbxCallTags=@(foreach($file in @([IO.Directory]::EnumerateFiles((Join-Path $runRoot 'control/runtime'),'*.out',[IO.SearchOption]::AllDirectories) | Sort-Object)){
            [IO.Path]::GetRelativePath($runRoot,$file).Replace('\','/')})
    }
    [void](Write-ProbeObservation '04-verdict' $verdict)
    Write-Host ''
    Write-Host '=== タスク8b 完了 ==='
    Write-Host ("  before: $($before.handle.name) / $($before.handle.id) / exit=$($before.command.exitCode) / stop=$($before.stop.stopState)")
    Write-Host ("  after : $($after.handle.name) / $($after.handle.id) / exit=$($after.command.exitCode) / stop=$($after.stop.stopState)")
    Write-Host ("  runRoot: $runRoot")
}catch{
    Write-Host ''
    Write-Host ("8b が中断した: "+([regex]::Replace([string]$_.Exception.Message,'\s+',' ')).Trim())
    if($null -ne $prepared){Write-Host ("  runRoot: $($prepared.runRoot)（後始末は -StopRecorded `"$($prepared.runRoot)`"）")}
    throw
}finally{
    # 作成済みで停止していないVMがあれば必ず停止を試みる（停止済みの handle への再呼び出しは何も発行しない）。
    foreach($role in $script:Roles){
        if($null -eq $prepared -or -not$handles.ContainsKey($role)){continue}
        try{$null=Stop-VerificationSandbox $handles[$role] (New-VerificationCleanupBudget $prepared 1)}catch{Write-Host ("  finally の停止に失敗: $role / "+$_.Exception.Message)}
    }
    if($null -ne $lease){try{Release-VerificationPilotLease $lease}catch{}}
}
