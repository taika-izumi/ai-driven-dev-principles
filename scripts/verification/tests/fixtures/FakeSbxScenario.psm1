# 偽sbx一式（fake-sbx.cmd・FakeSbx.ps1・scenario.json・偽の状態ディレクトリ）をケース領域へ複製し、記録済み応答から scenario.json を組み立てる試験補助。
# SbxRuntimeV3 だけでなく Proposal/Replay/CLI の v3 試験も同じ組み立てを使う想定。実VM・実デーモンは一切動かさない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$script:Utf8=[Text.UTF8Encoding]::new($false)
$script:ResponseIndex=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fake-sbx-responses/index.json') -Raw | ConvertFrom-Json -AsHashtable
$script:LogLines=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fake-state/daemon-log-lines.json') -Raw | ConvertFrom-Json -AsHashtable
$script:RuntimeTemplate=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fake-state/runtime.template.json'),$script:Utf8)
# 実機に残置されている停止中の試験VM2台（計画の共通制約で保全対象）。一覧に常に載せ、当該名への操作が無いことを試験で確かめる。
$script:KnownStoppedSandboxes=@(
    @{name='iv-sbx-smoke-20260909-01';id='de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae';agent='shell'},
    @{name='iv-sbx-capability-20260914-01';id='0baac92d-251c-4f34-9d8f-6f14a9c238c6';agent='shell'})
$script:TemplateDigest='docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476'

function Get-FakeSbxTemplateDigest(){$script:TemplateDigest}
function Expand-FakeTemplate([string]$Text,[hashtable]$Values){
    foreach($key in $Values.Keys){$Text=$Text.Replace('{{'+$key+'}}',[string]$Values[$key])}
    $Text
}
function Get-FakeSbxResponse([string]$Name,[hashtable]$Values=@{}){
    # 応答テンプレートを読み、{{...}} を埋めて本文と synthetic フラグを返す。
    if(-not$script:ResponseIndex.ContainsKey($Name)){throw "unknown fake response: $Name"}
    $item=$script:ResponseIndex[$Name]
    $text=[IO.File]::ReadAllText((Join-Path $PSScriptRoot ('fake-sbx-responses/'+$item.file)),$script:Utf8)
    @{text=(Expand-FakeTemplate $text $Values);synthetic=[bool]$item.synthetic}
}
function New-FakeSbxLogLine([string]$Kind,[string]$Name,[string]$Time='{{now}}'){
    if(-not$script:LogLines.ContainsKey($Kind)){throw "unknown daemon.log line kind: $Kind"}
    (Expand-FakeTemplate ([string]$script:LogLines[$Kind].text) @{time=$Time;name=$Name})+"`n"
}
function New-FakeSbxCase([string]$Root){
    # ケース領域: <Root>/sbx（偽sbx一式）、<Root>/state（偽の状態ディレクトリ）。sandboxd.pid は試験プロセス自身の PID。
    $sbxDir=Join-Path $Root 'sbx';$stateRoot=Join-Path $Root 'state'
    [void][IO.Directory]::CreateDirectory($sbxDir);[void][IO.Directory]::CreateDirectory((Join-Path $stateRoot 'runtimes'))
    [IO.File]::Copy((Join-Path $PSScriptRoot 'FakeSbx.ps1'),(Join-Path $sbxDir 'FakeSbx.ps1'),$true)
    $pwsh=(Get-Command pwsh -ErrorAction Stop).Source
    $cmd=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fake-sbx.cmd'),$script:Utf8).Replace('__PWSH__',$pwsh).Replace("`r`n","`n").Replace("`n","`r`n")
    $sbxPath=Join-Path $sbxDir 'fake-sbx.cmd'
    [IO.File]::WriteAllText($sbxPath,$cmd,$script:Utf8)
    $logPath=Join-Path $stateRoot 'daemon.log';$pidPath=Join-Path $stateRoot 'sandboxd.pid'
    $self=Get-Process -Id $PID
    [IO.File]::WriteAllText($logPath,(New-FakeSbxLogLine 'starting' '' ([DateTimeOffset]::new($self.StartTime).ToString('o'))),$script:Utf8)
    [IO.File]::WriteAllText($pidPath,[string]$PID,$script:Utf8)
    $case=@{
        root=$Root;sbxDir=$sbxDir;sbxPath=$sbxPath;stateRoot=$stateRoot;logPath=$logPath;pidPath=$pidPath;runtimesDir=(Join-Path $stateRoot 'runtimes')
        scenarioPath=(Join-Path $sbxDir 'scenario.json');callsPath=(Join-Path $sbxDir 'calls.jsonl');statePath=(Join-Path $sbxDir 'state.json')
        entries=[Collections.Generic.List[hashtable]]::new();sandboxes=[Collections.Generic.List[hashtable]]::new()
    }
    # デーモン単位の既定応答（running・clipboard 画像読取 false・MCP 登録なし）。試験は -First で上書きする。
    $status=Get-FakeSbxResponse 'daemonStatusRunning' @{logs=$logPath.Replace('\','\\')}
    Add-FakeSbxResponse $case @('daemon','status','--json') -Stdout $status.text -Synthetic $status.synthetic | Out-Null
    $clipboard=Get-FakeSbxResponse 'settingsClipboardFalse'
    Add-FakeSbxResponse $case @('settings','get','--json','clipboard\.imagePaste') -Stdout $clipboard.text -Synthetic $clipboard.synthetic | Out-Null
    $mcp=Get-FakeSbxResponse 'mcpLsEmpty'
    Add-FakeSbxResponse $case @('mcp','ls','--json') -Stdout $mcp.text -Synthetic $mcp.synthetic | Out-Null
    $case
}
function Add-FakeSbxResponse([hashtable]$Case,[string[]]$ArgvPatterns,[string]$Stdout='',[string]$Stderr='',[int]$ExitCode=0,[hashtable]$Requires=$null,[hashtable]$Sets=$null,[double]$DelaySeconds=0,[bool]$Synthetic=$false,[object[]]$AppendFile=@(),[object[]]$WriteFile=@(),[switch]$First){
    $entry=@{argv=@($ArgvPatterns);stdout=$Stdout;stderr=$Stderr;exitCode=$ExitCode;delaySeconds=$DelaySeconds;synthetic=$Synthetic;requires=$Requires;sets=$Sets;appendFile=@($AppendFile);writeFile=@($WriteFile)}
    if($First){$Case.entries.Insert(0,$entry)}else{$Case.entries.Add($entry)}
    $entry
}
function New-FakeRuntimeFileText([string]$Name,[string]$Id,[string]$Agent='shell',[string]$Digest=$script:TemplateDigest,[hashtable]$Overrides=@{}){
    $values=@{id=$Id;name=$Name;agent=$Agent;digest=$Digest;cpus='2';memory='2g';shareSkills='false';workspaceDir='';sshAgentSocketPath=''}
    foreach($key in $Overrides.Keys){$values[$key]=$Overrides[$key]}
    Expand-FakeTemplate $script:RuntimeTemplate $values
}
function Add-FakeSbxSandboxScenario([hashtable]$Case,[string]$Name,[string]$Id,[string]$Agent='shell',[string]$Digest=$script:TemplateDigest,[object[]]$ConfirmFiles=@(),[switch]$AlreadyPresent,[string]$InitialStatus='running'){
    # 1台分の既定応答: create（状態遷移・runtime ファイル・daemon.log 行）→ inspect / policy → 保持 exec → cp / chown → Confirm → stop。
    # -AlreadyPresent は run が作ったのではなく最初から一覧にあるVM（復旧操作の対象など）。
    $Case.sandboxes.Add(@{name=$Name;id=$Id;agent=$Agent;runCreated=(-not$AlreadyPresent);initialStatus=$InitialStatus})
    $runtimePath=Join-Path $Case.runtimesDir ($Name+'.json')
    if($AlreadyPresent){[IO.File]::WriteAllText($runtimePath,(New-FakeRuntimeFileText $Name $Id $Agent $Digest),$script:Utf8)}
    $create=Get-FakeSbxResponse 'createSuccess' @{name=$Name;agent=$Agent;digest=$Digest}
    Add-FakeSbxResponse $Case @('create',[regex]::Escape($Agent),'--name',[regex]::Escape($Name),'--cpus','2','--memory','2g','--no-share-skills','--deny-network','\*','--template',[regex]::Escape($Digest)) -Stdout $create.text -Synthetic $create.synthetic `
        -Sets @{"vm:$Name"='running';"present:$Name"='1'} `
        -WriteFile @(@{path=$runtimePath;text=(New-FakeRuntimeFileText $Name $Id $Agent $Digest)}) `
        -AppendFile @(@{path=$Case.logPath;text=(New-FakeSbxLogLine 'createdRuntime' $Name)}) | Out-Null
    $inspect=Get-FakeSbxResponse 'inspect' @{name=$Name;agent=$Agent;digest=$Digest;imageDigest=$Digest.Substring($Digest.IndexOf('@')+1)}
    Add-FakeSbxResponse $Case @('inspect',[regex]::Escape($Name),'--json') -Stdout $inspect.text -Synthetic $inspect.synthetic | Out-Null
    $policy=Get-FakeSbxResponse 'policyLs' @{name=$Name}
    Add-FakeSbxResponse $Case @('policy','ls',[regex]::Escape($Name),'--json') -Stdout $policy.text -Synthetic $policy.synthetic | Out-Null
    $log=Get-FakeSbxResponse 'policyLog' @{name=$Name}
    Add-FakeSbxResponse $Case @('policy','log',[regex]::Escape($Name),'--json') -Stdout $log.text -Synthetic $log.synthetic | Out-Null
    # セッション保持の exec は終わらない（停止側のジョブ停止で消える）。
    Add-FakeSbxResponse $Case @('exec',[regex]::Escape($Name),'sh','-c','sleep \d+') -DelaySeconds 3600 | Out-Null
    Add-FakeSbxResponse $Case @('cp','.+',[regex]::Escape($Name)+':.+') | Out-Null
    Add-FakeSbxResponse $Case @('exec','-u','root',[regex]::Escape($Name),'chown','-R','agent:agent','.+') | Out-Null
    $lines=[Text.StringBuilder]::new()
    foreach($file in $ConfirmFiles){[void]$lines.Append(([string]$file.sha256).ToLowerInvariant()+'  ./'+[string]$file.path+"`n")}
    Add-FakeSbxResponse $Case @('exec','-w','.+',[regex]::Escape($Name),'sh','-c','cd \S+ && find \. -type f -print0 \| sort -z \| xargs -0 sha256sum') -Stdout $lines.ToString() | Out-Null
    $stop=Get-FakeSbxResponse 'stop' @{name=$Name}
    Add-FakeSbxResponse $Case @('stop',[regex]::Escape($Name)) -Stdout $stop.text -Synthetic $stop.synthetic -Sets @{"vm:$Name"='stopped'} -AppendFile @(@{path=$Case.logPath;text=(New-FakeSbxLogLine 'stoppedContainer' $Name)}) | Out-Null
}
function New-FakeSbxLsJson([object[]]$Sandboxes){
    # 11-vms-after-create.json の形式（name・id・agent・status）。status は state.json の値へ実行時に置き換わる。
    $items=@(foreach($s in $Sandboxes){[ordered]@{name=$s.name;id=$s.id;agent=$s.agent;status=('{{state:vm:'+$s.name+'|'+$s.initialStatus+'}}')}})
    ([ordered]@{sandboxes=$items} | ConvertTo-Json -Depth 5)+"`n"
}
function Get-FakeSbxLsEntries([hashtable]$Case){
    # run が作るVMの存否の全組合せ（present:<name> の有無）ごとに ls --json の応答を1件ずつ作る。常在VM（残置2台・-AlreadyPresent）は常に載せる。
    $always=@(foreach($k in $script:KnownStoppedSandboxes){@{name=$k.name;id=$k.id;agent=$k.agent;initialStatus='stopped'}})+@($Case.sandboxes | Where-Object {-not$_.runCreated})
    $created=@($Case.sandboxes | Where-Object {$_.runCreated})
    $entries=@()
    for($mask=0;$mask -lt [Math]::Pow(2,$created.Count);$mask++){
        $requires=@{};$listed=@()
        for($i=0;$i -lt $created.Count;$i++){
            $present=(($mask -shr $i) -band 1) -eq 1
            $requires['present:'+$created[$i].name]=$(if($present){'1'}else{''})
            if($present){$listed+=$created[$i]}
        }
        $entries+=@{argv=@('ls','--json');stdout=(New-FakeSbxLsJson (@($listed)+$always));stderr='';exitCode=0;delaySeconds=0;synthetic=$false;requires=$requires;sets=$null;appendFile=@();writeFile=@()}
    }
    $entries
}
function Write-FakeSbxScenario([hashtable]$Case){
    $all=@($Case.entries)+@(Get-FakeSbxLsEntries $Case)
    [IO.File]::WriteAllText($Case.scenarioPath,(ConvertTo-Json -InputObject $all -Depth 8),$script:Utf8)
}
function Set-FakeSbxState([hashtable]$Case,[hashtable]$Values){
    $state=@{}
    if(Test-Path -LiteralPath $Case.statePath){$loaded=Get-Content -LiteralPath $Case.statePath -Raw | ConvertFrom-Json -AsHashtable;foreach($k in $loaded.Keys){$state[$k]=[string]$loaded[$k]}}
    foreach($k in $Values.Keys){$state[$k]=[string]$Values[$k]}
    [IO.File]::WriteAllText($Case.statePath,($state | ConvertTo-Json -Compress),$script:Utf8)
}
function Add-FakeDaemonLogLine([hashtable]$Case,[string]$Kind,[string]$Name,[string]$Time='{{now}}'){
    if($Time -eq '{{now}}'){$Time=[DateTimeOffset]::Now.ToString('o')}
    $stream=[IO.File]::Open($Case.logPath,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::ReadWrite)
    try{$bytes=$script:Utf8.GetBytes((New-FakeSbxLogLine $Kind $Name $Time));$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
}
function Read-FakeSbxCalls([hashtable]$Case){
    # 1行1件の hashtable を列挙して返す（呼出し側は @() で受ける）。
    if(-not(Test-Path -LiteralPath $Case.callsPath)){return}
    @([IO.File]::ReadAllLines($Case.callsPath,$script:Utf8) | Where-Object {$_.Trim().Length -gt 0} | ForEach-Object {$_ | ConvertFrom-Json -AsHashtable})
}
Export-ModuleMember -Function Get-FakeSbxTemplateDigest,Get-FakeSbxResponse,New-FakeSbxLogLine,New-FakeSbxCase,Add-FakeSbxResponse,New-FakeRuntimeFileText,Add-FakeSbxSandboxScenario,Write-FakeSbxScenario,Set-FakeSbxState,Add-FakeDaemonLogLine,Read-FakeSbxCalls
