$ErrorActionPreference='Stop'
$env:GIT_CONFIG_GLOBAL='NUL';$env:GIT_CONFIG_NOSYSTEM='1'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/FakeSbxScenario.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/V3TestContext.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
# 共通CLI（Invoke-IsolatedVerification.ps1）の試験。CLI は別プロセスとして起動し、stdout・stderr・終了値・偽sbxの呼び出し記録・control の記録だけを観測する。
# 偽sbx と合成題材（fixtures/pilot-source をケース領域の独立 Git 作業ツリーへ複製して初期コミットしたもの）を使う。実VM・実デーモン・実モデルは動かさない。
# 所要を抑えるため、全ケースの CLI を同時に起動してから結果を確かめる。ケースごとにデーモンの socket を変え、Lease（socket から決まる名前付き Mutex）がケース間で競合しないようにする。
# VM 名は CLI 内で発行される runId から決まるので、VM を作るケースは stderr の最初の行（runRoot）を読んでから、その runId の VM 応答を scenario.json に書き足す
# （これ自体が「runRoot が VM 作業より前に stderr へ出る」ことの確認になる）。ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$base=Join-Path $repo '.tmp/verification-tests'
$cli=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Invoke-IsolatedVerification.ps1'))
$pwsh=(Get-Command pwsh -ErrorAction Stop).Source
$utf8=[Text.UTF8Encoding]::new($false)
$pilot=Join-Path $PSScriptRoot 'fixtures/pilot-source'
$buggyText=[IO.File]::ReadAllText((Join-Path $pilot 'source/calc.py'),$utf8)
$fixedText=[IO.File]::ReadAllText((Join-Path $pilot 'replacements/calc.py'),$utf8)
$testText=[IO.File]::ReadAllText((Join-Path $pilot 'tests/test_calc.py'),$utf8)
$stillBrokenText="def add(a, b):`n    return a * b`n"
$resultSchema=Join-Path $PSScriptRoot '../result.schema.json'
$recoverySchema=Join-Path $PSScriptRoot '../recovery-result.schema.json'
$limitationsLine='acceptedLimitations: clipboard-text-write-possible, pid-count-unbounded, daemon-disconnect-unverified'
$knownStopped=@('iv-sbx-smoke-20260909-01','iv-sbx-capability-20260914-01')
$unitOk=Get-FakeSbxResponse 'unittestOk';$unitFail=Get-FakeSbxResponse 'unittestFail'
$agentEvents='{"type":"thread.started"}'+"`n"+'{"type":"item.completed","item":{"type":"agent_message","text":"proposal written"}}'+"`n"
$count=0
$suiteWatch=[Diagnostics.Stopwatch]::StartNew()
$cases=[Collections.Generic.List[hashtable]]::new()
$launches=[Collections.Generic.List[hashtable]]::new()
$heldMutexes=[Collections.Generic.List[Threading.Mutex]]::new()

function Get-Hash([string]$Path){Get-V3TestHash $Path}
function Get-TextHash([string]$Text){[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($utf8.GetBytes($Text)))}
function Write-Json([string]$Path,$Object){Write-V3TestText $Path (ConvertTo-VerificationCanonicalJson $Object)}
function Invoke-TestGit([string]$Root,[string[]]$Arguments){
    $out=& git -c user.name=VerificationTest -c user.email=test@example.invalid -C $Root @Arguments 2>&1
    if($LASTEXITCODE -ne 0){throw "git failed: $($Arguments -join ' '): $out"}
}
function New-CliCase([string]$Label,[hashtable]$Limits=@{},[int]$ExtraFiles=0){
    # ケース領域: sbx（偽sbx一式）・state（偽の状態ディレクトリ）・src（合成題材の独立 Git 作業ツリー）・prof（runtime profile と証拠）・runs（runsRoot）。
    $root=Join-Path $base ('c7'+[guid]::NewGuid().ToString('N').Substring(0,6))
    $case=New-FakeSbxCase $root
    $leaf=[IO.Path]::GetFileName($root)
    # ケースごとの socket（Lease の Mutex 名をケース間で分ける）。初回の daemon status は scenario.json を書き足す時間を取るため2秒遅らせる（書き足し後の応答は遅延なし）。
    $statusText=(Get-FakeSbxResponse 'daemonStatusRunning' @{logs=$case.logPath.Replace('\','\\')}).text.Replace('docker_fake_sandboxd',"docker_fake_$leaf")
    $statusEntry=Add-FakeSbxResponse $case @('daemon','status','--json') -Stdout $statusText -DelaySeconds 2 -Synthetic $true -Source '00-daemon-status.json の socket 名をケースごとに変えた創作（遅延も創作）' -First
    $src=Join-Path $root 'src';[void][IO.Directory]::CreateDirectory($src)
    $template=Join-Path $root 'gt';[void][IO.Directory]::CreateDirectory($template)
    & git -C $src init --quiet "--template=$template";if($LASTEXITCODE -ne 0){throw 'git init failed'}
    [IO.File]::Copy((Join-Path $pilot 'source/calc.py'),(Join-Path $src 'calc.py'))
    for($i=0;$i -lt $ExtraFiles;$i++){Write-V3TestText (Join-Path $src ('data/f{0:D4}.txt' -f $i)) (('x'*2048)+"`n")}
    Invoke-TestGit $src @('add','-A')
    Invoke-TestGit $src @('commit','--quiet','-m','synthetic defect')
    $prof=Join-Path $root 'prof';[void][IO.Directory]::CreateDirectory($prof)
    [IO.File]::Copy((Join-Path $PSScriptRoot 'fixtures/stdlib-modules.txt'),(Join-Path $prof 'stdlib-modules.txt'))
    Write-V3TestText (Join-Path $prof 'evidence-note.txt') "fixture evidence note`n"
    $profileCtx=@{prof=$prof;evidenceSeq=0}
    $limitValues=@{totalSeconds=1800;proposalSeconds=600;replaySeconds=120;cleanupSeconds=30;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1048576;maxProposalBytes=8388608;maxWireBytes=16777216;maxOutputBytes=16777216}
    foreach($key in $Limits.Keys){$limitValues[$key]=$Limits[$key]}
    $settings=[ordered]@{
        schemaVersion=3;sbxPath=$case.sbxPath;pwshPath=$pwsh;runsRoot=(Join-Path $root 'runs');model='unit-model'
        proposalProfilePath=(Join-Path $prof 'proposal.json');replayProfilePath=(Join-Path $prof 'replay.json');pilotInputPath=(Join-Path $root 'pilot-input.json');limits=$limitValues
    }
    foreach($role in @('proposal','replay')){Write-Json (Join-Path $prof "$role.json") (New-V3TestProfile $profileCtx $role)}
    $request=[ordered]@{schemaVersion=3;caller='codex';sourceRoot=$src;objective='合成題材の add の不具合を再現し修正候補を示す';acceptanceCriteria=@('add(1, 2) が 3 を返す');extraInputPaths=@()}
    $manifest=Get-VerificationSourceManifest ([hashtable]@{schemaVersion=3;sourceRoot=$src;extraInputPaths=@()}) ([hashtable]@{runsRoot=$settings.runsRoot})
    $pilotRecord=[ordered]@{schemaVersion=3;inputId="pilot-$leaf";scope='synthetic-pilot';sourceRoot=$src;sourceManifestHash=(Get-VerificationCanonicalHash $manifest);approvalReference=[ordered]@{path='docs/records/reviews/fixture.md';version='0000000'}}
    Write-Json $settings.pilotInputPath $pilotRecord
    Write-Json (Join-Path $root 'request.json') $request
    Write-Json (Join-Path $root 'settings.json') $settings
    Write-FakeSbxScenario $case
    $ctx=@{label=$Label;root=$root;case=$case;socket="\\.\pipe\docker_fake_$leaf";statusEntry=$statusEntry;src=$src;settings=$settings;request=$request;pilotRecord=$pilotRecord
        requestPath=(Join-Path $root 'request.json');settingsPath=(Join-Path $root 'settings.json');runId=$null;runRoot=$null;names=$null}
    $script:cases.Add($ctx)
    $ctx
}
function Hold-CaseLease([hashtable]$Ctx){
    # SbxRuntime と同じ名前（ユーザー名と socket の SHA256 先頭16桁）の Mutex を試験プロセスが保持し、CLI（別プロセス）の取得を競合させる。
    $key=(Get-VerificationCanonicalHash @{user=[Environment]::UserName;socket=$Ctx.socket}).Substring(0,16)
    $mutex=[Threading.Mutex]::new($false,'Local\iv-sbx-pilot-'+$key)
    Assert-True ($mutex.WaitOne(0)) "$($Ctx.label): 試験が Lease の Mutex を保持できる"
    $script:heldMutexes.Add($mutex)
}
function Write-ScenarioAtomic([hashtable]$Case){
    # 偽sbx が呼び出しごとに読む scenario.json を、別名に書いてから置き換える（書きかけを読ませない）。
    $final=$Case.scenarioPath;$temp=$final+'.new'
    $Case.scenarioPath=$temp
    try{Write-FakeSbxScenario $Case}finally{$Case.scenarioPath=$final}
    $until=[DateTime]::UtcNow.AddSeconds(10)
    while($true){try{[IO.File]::Move($temp,$final,$true);break}catch [IO.IOException]{if([DateTime]::UtcNow -ge $until){throw};Start-Sleep -Milliseconds 20}}
}
function New-FileEntry([string]$Kind,[string]$Path,[string]$Text){[ordered]@{kind=$Kind;path=$Path;contentBase64=[Convert]::ToBase64String($utf8.GetBytes($Text))}}
function Get-InputEntries([string]$CalcText){@(@{path='calc.py';sha256=(Get-TextHash $CalcText)},@{path='.verification-tests/test_calc.py';sha256=(Get-TextHash $testText)})}
function Add-RunScenario([hashtable]$Ctx,[string]$RunRoot){
    # runId が分かった時点で、その run の VM（提案・修正前・修正後）の応答を足す。Codex・エクスポーター・unittest の応答は実測の無い創作（synthetic）。
    $runId=[IO.Path]::GetFileName($RunRoot);$Ctx.runId=$runId;$Ctx.runRoot=$RunRoot
    $prefix='iv-'+$runId.Substring(0,8)
    $Ctx.names=@{proposal="$prefix-proposal";before="$prefix-before";after="$prefix-after"}
    $case=$Ctx.case;$spec=$Ctx.spec
    $baseline=(Get-Content -LiteralPath (Join-Path $RunRoot 'control/baseline-manifest.json') -Raw | ConvertFrom-Json -AsHashtable).files
    $proposalName=[regex]::Escape($Ctx.names.proposal)
    Add-FakeSbxSandboxScenario $case $Ctx.names.proposal ([guid]::NewGuid().ToString()) -Agent 'codex' -ConfirmFiles @($baseline)
    Add-FakeSbxResponse $case @('exec','-w','/home/agent/workspace/source',$proposalName,'codex','exec','--json') -Stdout $agentEvents -DelaySeconds $spec.agentDelay -Synthetic $true -Source 'Codex の実行イベントは未観測（タスク9で実測する）' | Out-Null
    $envelope=[ordered]@{schemaVersion=3;runId=$runId;summary='add が差を返す';findings=@([ordered]@{description='calc.py の add が a - b を返す';sourcePaths=@('calc.py')});files=@((New-FileEntry 'test' 'test_calc.py' $testText),(New-FileEntry 'replacement' 'calc.py' $spec.replacement));truncated=$false}
    $limits=$Ctx.settings.limits
    Add-FakeSbxResponse $case @('exec','-w','/home/agent/proposal-exporter',$proposalName,'python3','/home/agent/proposal-exporter/proposal-export\.py','--run-id',[regex]::Escape($runId),'--max-files',[string]$limits.maxProposalFiles,'--max-file-bytes',[string]$limits.maxFileBytes,'--max-proposal-bytes',[string]$limits.maxProposalBytes) -Stdout ((ConvertTo-Json -InputObject $envelope -Depth 10 -Compress)+"`n") -Synthetic $true -Source 'proposal-export.py の出力形式に合わせて試験が組んだ Envelope（実機の出力は未観測）' | Out-Null
    if($spec.replay){
        foreach($pair in @(@('before',$buggyText,$spec.before),@('after',$spec.replacement,$spec.after))){
            $name=$Ctx.names[$pair[0]]
            Add-FakeSbxSandboxScenario $case $name ([guid]::NewGuid().ToString()) -Agent 'shell' -ConfirmFiles (Get-InputEntries $pair[1])
            Add-FakeSbxResponse $case @('exec','-w','/home/agent/workspace/source',[regex]::Escape($name),'python3','-m','unittest','discover','-s','\.verification-tests','-p','test_\*\.py','-v') -Stderr $pair[2].text -ExitCode $(if($pair[2] -eq $unitOk){0}else{1}) -Synthetic $true -Source 'unittest の出力（ストリームと形式）は 8a で実測して差し替える' | Out-Null
        }
    }
    if($null -ne $spec.edit){& $spec.edit $Ctx}
    $Ctx.statusEntry.delaySeconds=0
    Write-ScenarioAtomic $case
}
function Start-Cli([hashtable]$Ctx,[string]$Label,[string[]]$Arguments,[scriptblock]$OnRunRoot=$null){
    # CLI を別プロセスで起動し、stdout・stderr をケース領域のファイルへ受ける（ファイルなので、ジョブ外に残る偽sbxの子が継承ハンドルを持っても終了待ちが延びない）。
    $out=Join-Path $Ctx.root "$Label.out";$err=Join-Path $Ctx.root "$Label.err"
    $argLine=(@('-NoProfile','-File',$cli)+$Arguments | ForEach-Object {if($_ -match '\s'){'"'+$_+'"'}else{$_}}) -join ' '
    $process=Start-Process -FilePath $pwsh -ArgumentList $argLine -RedirectStandardOutput $out -RedirectStandardError $err -NoNewWindow -PassThru
    $null=$process.Handle
    $launch=@{ctx=$Ctx;label=$Label;process=$process;out=$out;err=$err;onRunRoot=$OnRunRoot;hooked=($null -eq $OnRunRoot);exitCode=$null;stdout=$null;stderr=$null;launchedAt=[DateTime]::UtcNow}
    $script:launches.Add($launch)
    $launch
}
function Start-Run([hashtable]$Ctx,[string]$Label='run',[scriptblock]$OnRunRoot=$null){Start-Cli $Ctx $Label @('-RequestPath',$Ctx.requestPath,'-SettingsPath',$Ctx.settingsPath) $OnRunRoot}
function Read-SharedText([string]$Path){
    if(-not[IO.File]::Exists($Path)){return ''}
    try{$stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)}catch [IO.IOException]{return ''}
    try{[IO.StreamReader]::new($stream,$utf8).ReadToEnd()}finally{$stream.Dispose()}
}
function Get-StderrLines([hashtable]$Launch){@($Launch.stderr.Split("`n") | ForEach-Object {$_.TrimEnd("`r")} | Where-Object {$_.Length -gt 0})}
function Get-ResultJson([hashtable]$Launch){
    # stdout はちょうど1行の JSON（末尾改行つき）。
    $label=$Launch.label
    Assert-True ($Launch.stdout.EndsWith("`n")) "${label}: stdout は改行で終わる"
    $lines=@($Launch.stdout.Split("`n") | Where-Object {$_.Trim().Length -gt 0})
    Assert-Equal $lines.Count 1 "${label}: stdout は JSON 1件（1行）"
    $lines[0] | ConvertFrom-Json -AsHashtable -DateKind String
}
function Assert-ResultSchema([hashtable]$Launch){
    $line=$Launch.stdout.Trim()
    Assert-True (Test-Json -Json $line -SchemaFile $script:resultSchema -ErrorAction SilentlyContinue) "$($Launch.label): stdout の結果が result.schema.json に適合"
}
function Assert-SavedResult([hashtable]$Launch,$Result){
    $saved=Join-Path ([string]$Result.runRoot) 'control/result.json'
    Assert-True ([IO.File]::Exists($saved)) "$($Launch.label): control/result.json を保存"
    Assert-Equal ([IO.File]::ReadAllText($saved,$utf8).Trim()) $Launch.stdout.Trim() "$($Launch.label): 保存した結果と stdout が同じ正規化JSON"
}
function Assert-StartDiagnostics([hashtable]$Launch,[string]$RunRootText){
    $lines=Get-StderrLines $Launch
    Assert-Equal $lines[0] "runRoot: $RunRootText" "$($Launch.label): stderr の最初の行が runRoot"
    Assert-True ($lines -ccontains 'scope: synthetic-pilot' -and $lines -ccontains $script:limitationsLine) "$($Launch.label): stderr に scope と acceptedLimitations（3件）"
    Assert-True (@($lines | Where-Object {$_ -like '*clipboard*読取・退避・復元・消去しない*'}).Count -eq 1) "$($Launch.label): stderr に clipboard の注意"
}
function Get-Calls([hashtable]$Ctx){@(Read-FakeSbxCalls $Ctx.case)}
function Get-CallTime($Call){if($Call.time -is [DateTime]){$Call.time.ToUniversalTime()}else{[DateTimeOffset]::Parse([string]$Call.time).UtcDateTime}}
function Get-CallIndex([object[]]$Calls,[scriptblock]$Predicate){for($i=0;$i -lt $Calls.Count;$i++){if(& $Predicate $Calls[$i]){return $i}};-1}
function Assert-StopsOnly([hashtable]$Ctx,[string[]]$Names,[string]$Label){
    $stops=@(Get-Calls $Ctx | Where-Object {$_.argv[0] -eq 'stop'} | ForEach-Object {[string]$_.argv[1]})
    Assert-Equal @($stops | Where-Object {$Names -cnotcontains $_}).Count 0 "${Label}: 当該名以外への stop が0件（$($stops -join ',')）"
    foreach($name in $Names){Assert-Equal @($stops | Where-Object {$_ -ceq $name}).Count 1 "${Label}: $name へ stop 1回"}
}
function Assert-NoKnownVmTouched([hashtable]$Ctx,[string]$Label){
    foreach($call in @(Get-Calls $Ctx)){foreach($name in $script:knownStopped){Assert-True (-not(@($call.argv) -ccontains $name)) "${Label}: 残置VM $name を操作しない"}}
}
function New-RecordedRunRoot([hashtable]$Ctx,[string]$Folder,[string[]]$Roles){
    # 復旧操作の対象: SbxRuntime の作成記録と同じ形の control/runtime/<role>-sandbox.json を置いた run 領域。
    $runId=[guid]::NewGuid().ToString()
    $runRoot=Join-Path (Join-Path $Ctx.root $Folder) $runId
    [void][IO.Directory]::CreateDirectory((Join-Path $runRoot 'control/runtime'))
    $names=@{}
    foreach($role in $Roles){
        $suffix=@{proposal='proposal';'replay-before'='before';'replay-after'='after'}[$role]
        $name='iv-'+$runId.Substring(0,8)+'-'+$suffix;$id=[guid]::NewGuid().ToString();$names[$role]=$name
        Write-Json (Join-Path $runRoot "control/runtime/$role-sandbox.json") ([ordered]@{schemaVersion=3;runId=$runId;role=$role;name=$name;id=$id;createdAt='2026-09-16T00:00:00.0000000Z';profileHash=('A'*64);effectiveSettingsHash=('B'*64);activationRecordPath=$null;activationRecordHash=$null})
        Add-FakeSbxSandboxScenario $Ctx.case $name $id -AlreadyPresent -InitialStatus running
    }
    $Ctx.statusEntry.delaySeconds=0
    @{runId=$runId;runRoot=$runRoot;names=$names}
}
function Write-RecoveryInput([hashtable]$Ctx,[string]$FileName,[scriptblock]$Edit){
    $recovery=[ordered]@{schemaVersion=3;sbxPath=$Ctx.settings.sbxPath;pwshPath=$Ctx.settings.pwshPath;runsRoot=$Ctx.settings.runsRoot;limits=$Ctx.settings.limits}
    if($null -ne $Edit){& $Edit $recovery}
    $path=Join-Path $Ctx.root $FileName
    Write-Json $path $recovery
    $path
}

try{
# 静的な確認: CLI は各モジュールを -Force なしで1回だけ読み込む（Lease を持つ SbxRuntime のインスタンスを分けない）。動的な確認は正常往復（Lease が提案・再実行の VM 作成で有効）。
$cliText=[IO.File]::ReadAllText($cli,$utf8)
Assert-Equal ([regex]::Matches($cliText,'(?m)^\s*Import-Module .*-Force').Count) 0 'CLI: Import-Module に -Force を付けない'
Assert-Equal ([regex]::Matches($cliText,"(?m)^\s*Import-Module \(Join-Path \`$PSScriptRoot 'SbxRuntime\.psm1'\)").Count) 1 'CLI: SbxRuntime を1回だけ読み込む'
$count++

# ---- ケースの準備と一斉起動 ----
# 1. 正常往復: 提案 ready → before 終了1・after 終了0 → candidate-supported（終了0）。
$happy=New-CliCase 'happy'
$happy.spec=@{agentDelay=0;replacement=$fixedText;replay=$true;before=$unitFail;after=$unitOk;edit=$null}
$happyRun=Start-Run $happy 'run' {param($l,$runRoot) Add-RunScenario $l.ctx $runRoot}
# 2. still-failing: 修正候補でも after が終了1 → 終了1。
$still=New-CliCase 'still'
$still.spec=@{agentDelay=0;replacement=$stillBrokenText;replay=$true;before=$unitFail;after=$unitFail;edit=$null}
$stillRun=Start-Run $still 'run' {param($l,$runRoot) Add-RunScenario $l.ctx $runRoot}
# 3. 途中失敗: 提案VMの作成後に inspect が失敗（SbxRuntime が停止を発行）し、照合の直前に control/result.json が既にある（stderr の runRoot を読んで置く）。
#    照合が例外になり、CLI は判明済みの VM 情報で失敗結果を stdout にだけ返し、既存の result.json を上書きしない。Lease は解放する。
$midway=New-CliCase 'midway'
$midway.spec=@{agentDelay=0;replacement=$fixedText;replay=$false;edit={param($c) Add-FakeSbxResponse $c.case @('inspect',[regex]::Escape($c.names.proposal),'--json') -Stderr "Error: inspect failed`n" -ExitCode 1 -Synthetic $true -Source 'inspect 失敗の応答は未観測の創作' -First | Out-Null}}
$plantedText='{"planted":"existing result"}'
$midwayRun=Start-Run $midway 'run' {param($l,$runRoot) Write-V3TestText (Join-Path $runRoot 'control/result.json') $script:plantedText;Add-RunScenario $l.ctx $runRoot}
# 4. 全体期限の到達（VM あり）: 提案VM 作成後、Codex が期限を越えて終わらない。期限後は stop・停止確認の照会だけ。stop は一覧が stopped にならず未確認のまま（創作）で、
#    CLI の finally が停止フェーズの予算（台数分＝1台）で再試行する。
$late=New-CliCase 'late' -Limits @{totalSeconds=60;proposalSeconds=60;replaySeconds=60;cleanupSeconds=10}
$late.spec=@{agentDelay=600;replacement=$fixedText;replay=$false;edit={param($c)
    $stopText=(Get-FakeSbxResponse 'stop' @{name=$c.names.proposal}).text
    Add-FakeSbxResponse $c.case @('stop',[regex]::Escape($c.names.proposal)) -Stdout $stopText -Synthetic $true -Source '一覧が stopped にならない状態遷移は未観測の創作' -First | Out-Null
}}
$lateRun=Start-Run $late 'run' {param($l,$runRoot) Add-RunScenario $l.ctx $runRoot}
# 5. 提案が ready でない（作成前の拒否: MCP 登録あり）→ 再実行は not_run（VM を作らない）。
$notReady=New-CliCase 'notready'
Add-FakeSbxResponse $notReady.case @('mcp','ls','--json') -Stdout (Get-FakeSbxResponse 'mcpLsOne').text -Synthetic $true -Source 'mcpLsOne（創作）' -First | Out-Null
$notReady.statusEntry.delaySeconds=0;Write-FakeSbxScenario $notReady.case
$notReadyRun=Start-Run $notReady
# 6. デーモン停止: Lease 取得時の daemon status が stopped → blocked（理由に利用者の通常起動）。
$daemon=New-CliCase 'daemon'
Add-FakeSbxResponse $daemon.case @('daemon','status','--json') -Stdout (Get-FakeSbxResponse 'daemonStatusStopped').text -Synthetic $true -Source 'daemonStatusStopped（創作）' -First | Out-Null
Write-FakeSbxScenario $daemon.case
$daemonRun=Start-Run $daemon
# 7. Lease 競合: 同じデーモン（socket）の Mutex を試験が保持 → blocked、VM を作らない。
$conflict=New-CliCase 'conflict'
$conflict.statusEntry.delaySeconds=0;Write-FakeSbxScenario $conflict.case
Hold-CaseLease $conflict
$conflictRun=Start-Run $conflict
# 8. 入力の拒否（VM・sbx 呼び出しなし）: 固定入力記録の不一致、重複キー、schemaVersion=1（v1 の準備に渡さない）。
$inputs=New-CliCase 'inputs'
Write-Json $inputs.settings.pilotInputPath ([ordered]@{schemaVersion=3;inputId='pilot-mismatch';scope='synthetic-pilot';sourceRoot=$inputs.src;sourceManifestHash=('0'*64);approvalReference=$inputs.pilotRecord.approvalReference})
$mismatchRun=Start-Run $inputs 'mismatch'
$dupPath=Join-Path $inputs.root 'request-dup.json'
Write-V3TestText $dupPath ((ConvertTo-VerificationCanonicalJson $inputs.request).Replace('{"acceptanceCriteria"','{"objective":"x","acceptanceCriteria"'))
$dupRun=Start-Cli $inputs 'dup' @('-RequestPath',$dupPath,'-SettingsPath',$inputs.settingsPath)
$v1Path=Join-Path $inputs.root 'request-v1.json'
$v1Request=[ordered]@{};foreach($key in $inputs.request.Keys){$v1Request[$key]=$inputs.request[$key]};$v1Request.schemaVersion=1
Write-Json $v1Path $v1Request
$v1Run=Start-Cli $inputs 'v1' @('-RequestPath',$v1Path,'-SettingsPath',$inputs.settingsPath)
# 9. 準備中に全体期限へ到達（totalSeconds=1、作業ファイル600件で準備に1秒以上かかる）: sbx を1回も呼ばず、期限後の型付き結果を照合した timed_out。
$prepLate=New-CliCase 'preplate' -Limits @{totalSeconds=1;proposalSeconds=1;replaySeconds=1} -ExtraFiles 600
$prepLateRun=Start-Run $prepLate
# 10. 復旧操作: 記録済み2台（提案・修正前）だけを止め、記録に無い running VM（修正後の名前）には触れない。縮約入力を使う。
$recover=New-CliCase 'recover'
$recorded=New-RecordedRunRoot $recover 'rr' @('proposal','replay-before')
$unrecordedName='iv-'+$recorded.runId.Substring(0,8)+'-after'
Add-FakeSbxSandboxScenario $recover.case $unrecordedName ([guid]::NewGuid().ToString()) -AlreadyPresent -InitialStatus running
Write-FakeSbxScenario $recover.case
$recoverInput=Write-RecoveryInput $recover 'recovery.json' $null
$recoverRun=Start-Cli $recover 'recover' @('-StopRecorded','-RunRoot',$recorded.runRoot,'-SettingsPath',$recoverInput)
# 11. 復旧操作: 記録0件（SettingsV3 の形の入力）→ targetCount=0・終了0。
$empty=New-CliCase 'empty'
$empty.statusEntry.delaySeconds=0;Write-FakeSbxScenario $empty.case
$emptyRunRoot=Join-Path $empty.root ('r0/'+[guid]::NewGuid().ToString());[void][IO.Directory]::CreateDirectory((Join-Path $emptyRunRoot 'control/runtime'))
$emptyRun=Start-Cli $empty 'empty' @('-StopRecorded','-RunRoot',$emptyRunRoot,'-SettingsPath',$empty.settingsPath)
# 12. 復旧操作: Lease 競合なら何もしない（stop・ls を発行しない）。
$recoverConflict=New-CliCase 'rconf'
$conflictRecorded=New-RecordedRunRoot $recoverConflict 'rr' @('proposal')
Write-FakeSbxScenario $recoverConflict.case
Hold-CaseLease $recoverConflict
$recoverConflictRun=Start-Cli $recoverConflict 'rconf' @('-StopRecorded','-RunRoot',$conflictRecorded.runRoot,'-SettingsPath',(Write-RecoveryInput $recoverConflict 'recovery.json' $null))
# 13. 復旧操作の入力は recovery-input の schema で検査する: limits 欠落・schemaVersion 欠落・schemaVersion が文字列。どれも sbx を呼ばずに終了2。
$schemaCase=New-CliCase 'rschema'
$schemaRecorded=New-RecordedRunRoot $schemaCase 'rr' @('proposal')
Write-FakeSbxScenario $schemaCase.case
$schemaRuns=@(
    (Start-Cli $schemaCase 'nolimits' @('-StopRecorded','-RunRoot',$schemaRecorded.runRoot,'-SettingsPath',(Write-RecoveryInput $schemaCase 'nolimits.json' {param($r) $r.Remove('limits')}))),
    (Start-Cli $schemaCase 'noversion' @('-StopRecorded','-RunRoot',$schemaRecorded.runRoot,'-SettingsPath',(Write-RecoveryInput $schemaCase 'noversion.json' {param($r) $r.Remove('schemaVersion')}))),
    (Start-Cli $schemaCase 'strversion' @('-StopRecorded','-RunRoot',$schemaRecorded.runRoot,'-SettingsPath',(Write-RecoveryInput $schemaCase 'strversion.json' {param($r) $r.schemaVersion='3'})))
)

# ---- 終了待ち（VM を作るケースは stderr の runRoot を読んで scenario を書き足す） ----
$waitUntil=[DateTime]::UtcNow.AddSeconds(900)
while(@($launches | Where-Object {-not$_.process.HasExited}).Count -gt 0){
    foreach($launch in $launches){
        if($launch.hooked){continue}
        $match=[regex]::Match((Read-SharedText $launch.err),'(?m)^runRoot: (.+?)\r?$')
        if($match.Success -and -not$match.Groups[1].Value.StartsWith('(')){
            & $launch.onRunRoot $launch $match.Groups[1].Value
            $launch.hooked=$true
        }
    }
    if([DateTime]::UtcNow -ge $waitUntil){throw 'ASSERT: CLI の終了待ちが上限（900秒）を越えた'}
    Start-Sleep -Milliseconds 100
}
foreach($launch in $launches){
    $launch.process.WaitForExit()
    $launch.exitCode=$launch.process.ExitCode
    $launch.stdout=Read-SharedText $launch.out
    $launch.stderr=Read-SharedText $launch.err
}
Stop-CaseFakeProcesses $cases.ToArray()

# ---- 1. 正常往復 ----
$r=Get-ResultJson $happyRun
Assert-Equal $happyRun.exitCode 0 "正常往復: 終了0（stderr: $($happyRun.stderr)）"
Assert-True ($r.status -ceq 'completed' -and $r.replayVerdict -ceq 'candidate-supported' -and $r.execution.exitCodeForCli -eq 0) "正常往復: completed・candidate-supported（$($r.status) $($r.summary)）"
Assert-True ($r.execution.proposalCreated -eq $true -and $r.execution.proposalStopped -eq $true -and $r.execution.replayCreatedCount -eq 2 -and $r.execution.replayAllStopped -eq $true) '正常往復: 提案VMと再実行VM2台を作成し停止確認'
Assert-True ($r.scope -ceq 'synthetic-pilot' -and @($r.limitations).Count -eq 3 -and @($r.unverified).Count -eq 0 -and @($r.checks).Count -eq 2) '正常往復: scope・既知の制約・checks 2件・unverified なし'
Assert-ResultSchema $happyRun
Assert-SavedResult $happyRun $r
Assert-True ($r.runRoot -ceq $happy.runRoot) '正常往復: stdout の runRoot は stderr で読んだ run'
Assert-StartDiagnostics $happyRun $happy.runRoot
$lines=Get-StderrLines $happyRun
$leaseAt=[array]::IndexOf($lines,@($lines | Where-Object {$_ -like 'pilot lease: 取得*'})[0])
Assert-True ($leaseAt -gt 0 -and $lines -ccontains 'pilot lease: 解放した') '正常往復: Lease の取得（runRoot の表示より後）と解放を stderr に表示'
Assert-True (@($lines | Where-Object {$_ -like '*lease-invalid*'}).Count -eq 0) '正常往復: CLI が取った Lease を提案・再実行の VM 作成が有効と認める（SbxRuntime のインスタンスが1つ）'
$calls=Get-Calls $happy
$order=@(
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create' -and $c.argv[3] -ceq $happy.names.proposal}),
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop' -and $c.argv[1] -ceq $happy.names.proposal}),
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create' -and $c.argv[3] -ceq $happy.names.before}),
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop' -and $c.argv[1] -ceq $happy.names.before}),
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create' -and $c.argv[3] -ceq $happy.names.after}),
    (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop' -and $c.argv[1] -ceq $happy.names.after}))
$ascending=$order[0] -ge 0
for($i=1;$i -lt $order.Count;$i++){if($order[$i] -le $order[$i-1]){$ascending=$false}}
Assert-True $ascending "正常往復: 提案 → 修正前 → 修正後の順に作成・停止（$($order -join ',')）"
Assert-StopsOnly $happy @($happy.names.proposal,$happy.names.before,$happy.names.after) '正常往復'
Assert-NoKnownVmTouched $happy '正常往復'
foreach($call in $calls){Assert-True ($call.envKeys -notcontains 'SSH_AUTH_SOCK') '正常往復: sbx CLI へ SSH_AUTH_SOCK を渡さない'}
$count++

# ---- 2. still-failing ----
$r=Get-ResultJson $stillRun
Assert-Equal $stillRun.exitCode 1 "still-failing: 終了1（stderr: $($stillRun.stderr)）"
Assert-True ($r.status -ceq 'completed' -and $r.replayVerdict -ceq 'still-failing' -and $r.execution.exitCodeForCli -eq 1) "still-failing: completed・still-failing（$($r.status) $($r.summary)）"
Assert-ResultSchema $stillRun
Assert-SavedResult $stillRun $r
Assert-StopsOnly $still @($still.names.proposal,$still.names.before,$still.names.after) 'still-failing'
$count++

# ---- 3. 途中失敗（照合の例外）: Lease の解放・作成済みVMの停止発行・既存の result.json を上書きしない ----
$r=Get-ResultJson $midwayRun
Assert-Equal $midwayRun.exitCode 2 '途中失敗: 終了2'
Assert-True ($r.status -ceq 'incomplete' -and $r.execution.failureStage -ceq 'result' -and $r.execution.exitCodeForCli -eq 2 -and $r.replayVerdict -ceq 'undetermined') "途中失敗: incomplete・failureStage=result（$($r.status) $($r.summary)）"
Assert-True ($r.execution.proposalCreated -eq $true -and $r.execution.proposalStopped -eq $true -and $r.execution.replayCreatedCount -eq 0) '途中失敗: 判明済みの VM 情報（提案VMは作成済み・停止済み、再実行VMなし）'
Assert-True ($r.runRoot -ceq $midway.runRoot -and $r.runId -ceq $midway.runId) '途中失敗: 保存しない失敗結果でも runRoot・runId は作成済みの当該 run'
Assert-ResultSchema $midwayRun
Assert-Equal ([IO.File]::ReadAllText((Join-Path $midway.runRoot 'control/result.json'),$utf8)) $plantedText '途中失敗: 既存の control/result.json を上書きしない'
$lines=Get-StderrLines $midwayRun
Assert-True (@($lines | Where-Object {$_ -like 'result: control/result.json が既にあるため保存しない*'}).Count -eq 1) '途中失敗: 保存しないことを stderr に表示'
Assert-True (@($lines | Where-Object {$_ -like 'error: result: *result already exists*'}).Count -eq 1) '途中失敗: 例外のメッセージを stderr の診断に残す'
Assert-True ($lines -ccontains 'pilot lease: 解放した') '途中失敗: Lease を解放する'
Assert-StartDiagnostics $midwayRun $midway.runRoot
$calls=Get-Calls $midway
Assert-Equal @($calls | Where-Object {$_.argv[0] -eq 'create'}).Count 1 '途中失敗: 作成は提案VMの1回だけ'
Assert-True ((Get-CallIndex $calls {param($c) $c.argv[0] -eq 'create'}) -lt (Get-CallIndex $calls {param($c) $c.argv[0] -eq 'stop'})) '途中失敗: 作成済みの提案VMへ停止を発行'
Assert-StopsOnly $midway @($midway.names.proposal) '途中失敗'
Assert-Equal @($calls | Where-Object {$_.argv[0] -eq 'exec' -and @($_.argv) -contains 'codex'}).Count 0 '途中失敗: Codex を起動しない'
$count++

# ---- 4. 全体期限の到達（VM あり）: 期限後は stop とその確認の照会だけ、停止フェーズの予算は台数分 ----
$r=Get-ResultJson $lateRun
Assert-Equal $lateRun.exitCode 2 '期限到達: 終了2'
Assert-True ($r.status -ceq 'timed_out' -and $r.execution.proposalCreated -eq $true -and $r.execution.proposalStopped -eq $false -and $r.execution.replayCreatedCount -eq 0) "期限到達: timed_out・提案VMは停止未確認（$($r.status) $($r.summary)）"
Assert-ResultSchema $lateRun
# 提案が ready でないので、期限後も再実行は not_run として照合へ進む（照合は VM を作らない）。上流の時間超過を優先した照合結果を保存する。
# 照合を経た結果であること: 固定入力と原本・基準版の再照合（sourceState・baselineState=unchanged、scope の付与）、提案VMの停止値は停止記録（最後が unverified）に基づく false。
Assert-True (@($r.unverified) -ccontains 'proposal/agent:agent-timed-out' -and $r.execution.failureStage -ceq 'proposal/agent') "期限到達: 照合結果に提案の時間超過（$(@($r.unverified) -join ' | ')）"
Assert-True ($r.sourceState -ceq 'unchanged' -and $r.baselineState -ceq 'unchanged' -and $r.scope -ceq 'synthetic-pilot' -and @($r.limitations).Count -eq 3) "期限到達: 照合を経た結果（原本・基準版の再照合と scope。$($r.sourceState)/$($r.baselineState)/$($r.scope)）"
Assert-True (@($r.unverified | Where-Object {$_ -like 'result/proposal-stop:*'}).Count -ge 1) "期限到達: 提案VMの停止未確認は停止記録の照合から（$(@($r.unverified) -join ' | ')）"
Assert-SavedResult $lateRun $r
$lines=Get-StderrLines $lateRun
$deadlineMatch=[regex]::Match(($lines -join "`n"),'(?m)^startedAt: \S+ deadlineAt: (\S+) totalSeconds: 60$')
Assert-True $deadlineMatch.Success '期限到達: stderr に startedAt・deadlineAt'
$deadlineAt=[DateTimeOffset]::Parse($deadlineMatch.Groups[1].Value).UtcDateTime
$calls=Get-Calls $late
$create=@($calls | Where-Object {$_.argv[0] -eq 'create'})
Assert-True ($create.Count -eq 1 -and (Get-CallTime $create[0]) -lt $deadlineAt) '期限到達: 前提（提案VMは期限前に作成）'
# 偽sbx の記録時刻は起動後の時刻なので、期限前に発行した呼び出しが数秒遅れて記録されうる（5秒の余裕）。
$afterDeadline=@($calls | Where-Object {(Get-CallTime $_) -gt $deadlineAt.AddSeconds(5)})
Assert-Equal @($afterDeadline | Where-Object {$_.argv[0] -notin @('daemon','ls','stop')}).Count 0 "期限到達: 期限後は作成・搬入・exec を発行しない（$(@($afterDeadline | ForEach-Object {$_.argv[0]}) -join ',')）"
$stops=@($calls | Where-Object {$_.argv[0] -eq 'stop'})
Assert-True ($stops.Count -eq 2 -and @($stops | Where-Object {$_.argv[1] -cne $late.names.proposal}).Count -eq 0 -and (Get-CallTime $stops[-1]) -gt $deadlineAt) "期限到達: 提案の停止と CLI の再試行で当該名へ stop 2回、期限後（$($stops.Count)）"
$evidence=@(Get-ChildItem -LiteralPath (Join-Path $late.runRoot 'control/runtime') -Filter 'proposal-stop-*.json' | Sort-Object Name)
Assert-Equal $evidence.Count 2 '期限到達: 停止証拠2件'
$retry=Get-Content -LiteralPath $evidence[-1].FullName -Raw | ConvertFrom-Json -AsHashtable -DateKind String
$budgetSeconds=([DateTimeOffset]::Parse([string]$retry.budget.cleanupDeadlineAt).UtcDateTime-[DateTimeOffset]::Parse([string]$retry.stopIssuedAt).UtcDateTime).TotalSeconds
Assert-True ($retry.stopState -ceq 'unverified' -and $budgetSeconds -gt 0 -and $budgetSeconds -le 10.5) "期限到達: CLI の再試行の予算は現在時刻起点の1台分（cleanupSeconds=10、stop 発行から期限まで $budgetSeconds 秒）"
Assert-True (@($lines | Where-Object {$_ -like 'stop: 停止未確認の VM 1 台*'}).Count -eq 1) '期限到達: 停止フェーズの対象台数を stderr に表示'
Assert-True (@($lines | Where-Object {$_ -like 'recovery: *-StopRecorded -RunRoot*'}).Count -eq 1) '期限到達: 停止未確認なら復旧操作の入口を stderr に表示'
Assert-True ($lines -ccontains 'pilot lease: 解放した') '期限到達: Lease を解放する'
$count++

# ---- 5. 提案が ready でない → 再実行は not_run ----
$r=Get-ResultJson $notReadyRun
Assert-Equal $notReadyRun.exitCode 2 '提案非ready: 終了2'
Assert-True ($r.status -ceq 'blocked' -and @($r.unverified) -ccontains 'proposal/sandbox:daemon-settings') "提案非ready: blocked（$($r.status) $(@($r.unverified) -join ' | ')）"
Assert-True ($r.execution.proposalCreated -eq $false -and $r.execution.replayCreatedCount -eq 0 -and $null -eq $r.execution.replayAllStopped) '提案非ready: VM を作らない'
Assert-SavedResult $notReadyRun $r
Assert-True (@(Get-StderrLines $notReadyRun | Where-Object {$_ -like 'replay: 実行しない（提案が ready でない。status=not_run）'}).Count -eq 1) '提案非ready: 再実行は not_run の型付き結果'
Assert-Equal @(Get-Calls $notReady | Where-Object {$_.argv[0] -eq 'create'}).Count 0 '提案非ready: create 0回'
$count++

# ---- 6. デーモン停止 ----
$r=Get-ResultJson $daemonRun
Assert-Equal $daemonRun.exitCode 2 'デーモン停止: 終了2'
Assert-True ($r.status -ceq 'blocked' -and $r.execution.failureStage -ceq 'lease' -and @($r.unverified | Where-Object {$_ -like 'lease:daemon-not-running:*通常端末でデーモンを起動*'}).Count -eq 1) "デーモン停止: blocked・理由に利用者の通常起動（$(@($r.unverified) -join ' | ')）"
Assert-SavedResult $daemonRun $r
$calls=Get-Calls $daemon
Assert-True ($calls.Count -ge 1 -and @($calls | Where-Object {$_.argv[0] -ne 'daemon'}).Count -eq 0) "デーモン停止: daemon status 以外を発行しない（$(@($calls | ForEach-Object {$_.argv[0]}) -join ',')）"
$count++

# ---- 7. Lease 競合 ----
$r=Get-ResultJson $conflictRun
Assert-Equal $conflictRun.exitCode 2 'Lease競合: 終了2'
Assert-True ($r.status -ceq 'blocked' -and $r.execution.failureStage -ceq 'lease' -and @($r.unverified | Where-Object {$_ -like 'lease:lease-conflict:*'}).Count -eq 1) "Lease競合: blocked（$(@($r.unverified) -join ' | ')）"
$calls=Get-Calls $conflict
Assert-True (@($calls | Where-Object {$_.argv[0] -ne 'daemon'}).Count -eq 0) 'Lease競合: VM を作らない（daemon status 以外を発行しない）'
$count++

# ---- 8. 入力の拒否 ----
$r=Get-ResultJson $mismatchRun
Assert-Equal $mismatchRun.exitCode 2 '固定入力不一致: 終了2'
Assert-True ($r.status -ceq 'blocked' -and $r.execution.failureStage -ceq 'pilot-input' -and $null -eq $r.runRoot -and $null -eq $r.runId) "固定入力不一致: blocked・run を作らない（$($r.summary)）"
Assert-ResultSchema $mismatchRun
Assert-StartDiagnostics $mismatchRun '(作成されていない)'
foreach($pair in @(@($dupRun,'重複キー','*duplicate keys*'),@($v1Run,'schemaVersion=1','*schemaVersion must be integer 3*'))){
    $r=Get-ResultJson $pair[0]
    Assert-True ($pair[0].exitCode -eq 2 -and $r.status -ceq 'blocked' -and $r.execution.failureStage -ceq 'input' -and $r.summary -like $pair[2]) "入力の拒否（$($pair[1])）: blocked・終了2（$($r.summary)）"
}
Assert-True (-not[IO.Directory]::Exists($inputs.settings.runsRoot) -or [IO.Directory]::GetFileSystemEntries($inputs.settings.runsRoot).Length -eq 0) '入力の拒否: runsRoot に run を作らない（v1 の準備にも渡さない）'
Assert-True (-not[IO.File]::Exists($inputs.case.callsPath)) '入力の拒否: sbx を呼ばない'
$count++

# ---- 9. 準備中に全体期限へ到達 ----
$r=Get-ResultJson $prepLateRun
Assert-Equal $prepLateRun.exitCode 2 '準備中の期限到達: 終了2'
# 期限後は Lease の照会も起動を拒否されるので Lease を取らずに進み、期限後の提案が VM を作らず返す timed_out と not_run の再実行を照合する。
Assert-True ($r.status -ceq 'timed_out' -and $r.execution.failureStage -ceq 'proposal/sandbox' -and @($r.unverified) -ccontains 'proposal/sandbox:deadline-reached') "準備中の期限到達: 照合を経た timed_out（$($r.summary) / $(@($r.unverified) -join ' | ')）"
Assert-True ($r.sourceState -ceq 'unchanged' -and $r.baselineState -ceq 'unchanged' -and $r.scope -ceq 'synthetic-pilot' -and $r.execution.proposalCreated -eq $false -and $null -eq $r.execution.proposalStopped -and $r.execution.replayCreatedCount -eq 0) '準備中の期限到達: 原本・基準版の再照合と scope、VM なし'
Assert-SavedResult $prepLateRun $r
Assert-ResultSchema $prepLateRun
$lines=Get-StderrLines $prepLateRun
Assert-True (@($lines | Where-Object {$_ -like 'pilot lease: 全体期限に達したため取得しない*'}).Count -eq 1 -and @($lines | Where-Object {$_ -like 'replay: 実行しない*'}).Count -eq 1) '準備中の期限到達: Lease を取らず、再実行は not_run'
Assert-True (-not[IO.File]::Exists($prepLate.case.callsPath)) '準備中の期限到達: sbx を1回も呼ばない（Lease の照会も含む）'
$count++

# ---- 10〜13. 復旧操作 ----
Assert-Equal $recoverRun.exitCode 0 "復旧: 終了0（stderr: $($recoverRun.stderr)）"
$lines=@($recoverRun.stdout.Split("`n") | Where-Object {$_.Trim().Length -gt 0})
Assert-True ($lines.Count -eq 1 -and (Test-Json -Json $lines[0] -SchemaFile $recoverySchema -ErrorAction SilentlyContinue)) '復旧: stdout は recovery-result の schema に適合する JSON 1件'
$rr=$lines[0] | ConvertFrom-Json -AsHashtable -DateKind String
Assert-True ($rr.runId -ceq $recorded.runId -and $rr.targetCount -eq 2 -and @($rr.targets | Where-Object {$_.stopState -ceq 'stopped'}).Count -eq 2 -and $rr.daemonRunning -eq $true) '復旧: 記録済み2台を stopped と確認'
Assert-StopsOnly $recover @($recorded.names['proposal'],$recorded.names['replay-before']) '復旧'
Assert-Equal @(Get-Calls $recover | Where-Object {@($_.argv) -ccontains $unrecordedName}).Count 0 '復旧: 記録外の running VM に触れない'
Assert-Equal (Get-StderrLines $recoverRun)[0] "runRoot: $($recorded.runRoot)" '復旧: stderr の最初の行が runRoot'
$count++
Assert-Equal $emptyRun.exitCode 0 "復旧（記録0件）: 終了0（stderr: $($emptyRun.stderr)）"
$rr=$emptyRun.stdout.Trim() | ConvertFrom-Json -AsHashtable -DateKind String
Assert-True ($rr.targetCount -eq 0 -and @($rr.targets).Count -eq 0 -and (Test-Json -Json $emptyRun.stdout.Trim() -SchemaFile $recoverySchema -ErrorAction SilentlyContinue)) '復旧（記録0件）: targetCount=0 を stdout に返す（SettingsV3 の形の入力を受ける）'
Assert-True (@(Get-StderrLines $emptyRun | Where-Object {$_ -like '*targetCount=0*'}).Count -eq 1) '復旧（記録0件）: targetCount=0 を stderr に表示'
$count++
Assert-True ($recoverConflictRun.exitCode -eq 2 -and $recoverConflictRun.stdout.Trim().Length -eq 0 -and $recoverConflictRun.stderr -like '*lease*') "復旧（Lease競合）: 終了2・stdout なし（stderr: $($recoverConflictRun.stderr)）"
$calls=Get-Calls $recoverConflict
Assert-True (@($calls | Where-Object {$_.argv[0] -ne 'daemon'}).Count -eq 0) "復旧（Lease競合）: 何もしない（daemon status 以外を発行しない。$(@($calls | ForEach-Object {$_.argv[0]}) -join ',')）"
$count++
foreach($launch in $schemaRuns){
    Assert-True ($launch.exitCode -eq 2 -and $launch.stdout.Trim().Length -eq 0 -and $launch.stderr -like '*recovery-input.schema.json*') "復旧（$($launch.label)）: recovery-input の schema で拒否し終了2（stderr: $($launch.stderr)）"
}
Assert-True (-not[IO.File]::Exists($schemaCase.case.callsPath)) '復旧（schema 違反）: sbx を呼ばない'
$count++

}finally{
    foreach($launch in $launches){if(-not$launch.process.HasExited){try{Stop-Process -Id $launch.process.Id -Force -ErrorAction SilentlyContinue}catch{}}}
    foreach($mutex in $heldMutexes){try{$mutex.ReleaseMutex()}catch{};$mutex.Dispose()}
    if($cases.Count -gt 0){try{Stop-CaseFakeProcesses $cases.ToArray()}catch{}}
}
foreach($ctx in $cases){Assert-Equal @(Get-CaseFakeProcesses @($ctx)).Count 0 "$($ctx.label): 当該ケースの偽sbxプロセスが残っていない"}
$count++
"CliV3: $count cases passed ($([int]$suiteWatch.Elapsed.TotalSeconds)s)"
