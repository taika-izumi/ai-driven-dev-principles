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
$script:ProposalDeniedHosts=@('api.openai.com','openai.com','files.openai.com','registry.npmjs.org','api.github.com','github.com','codeload.github.com','archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com','download.docker.com')
$script:ProposalAllowedHosts=@('auth.openai.com','chatgpt.com')

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
    @{text=(Expand-FakeTemplate $text $Values);synthetic=[bool]$item.synthetic;source=[string]$item.source;exitCode=$(if($item.ContainsKey('exitCode')){[int]$item.exitCode}else{0})}
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
    Add-FakeSbxResponse $case @('daemon','status','--json') -Stdout $status.text -Synthetic $status.synthetic -Source $status.source | Out-Null
    $clipboard=Get-FakeSbxResponse 'settingsClipboardFalse'
    Add-FakeSbxResponse $case @('settings','get','--json','clipboard\.imagePaste') -Stdout $clipboard.text -Synthetic $clipboard.synthetic -Source $clipboard.source | Out-Null
    $mcp=Get-FakeSbxResponse 'mcpLsEmpty'
    Add-FakeSbxResponse $case @('mcp','ls','--json') -Stdout $mcp.text -Synthetic $mcp.synthetic -Source $mcp.source | Out-Null
    $case
}
function Add-FakeSbxResponse([hashtable]$Case,[string[]]$ArgvPatterns,[string]$Stdout='',[string]$Stderr='',[int]$ExitCode=0,[hashtable]$Requires=$null,[hashtable]$Sets=$null,[double]$DelaySeconds=0,[bool]$Synthetic=$false,[object[]]$AppendFile=@(),[object[]]$WriteFile=@(),[string]$Source='',[switch]$First){
    # synthetic は実測原文に無い創作応答の印。実測由来は Source に .tmp/sbx-capability-20260914/ のファイル番号を書く（scenario.json に残る。偽sbxは読まない）。
    $entry=@{argv=@($ArgvPatterns);stdout=$Stdout;stderr=$Stderr;exitCode=$ExitCode;delaySeconds=$DelaySeconds;synthetic=$Synthetic;source=$Source;requires=$Requires;sets=$Sets;appendFile=@($AppendFile);writeFile=@($WriteFile)}
    if($First){$Case.entries.Insert(0,$entry)}else{$Case.entries.Add($entry)}
    $entry
}
function New-FakeRuntimeFileText([string]$Name,[string]$Id,[string]$Agent='shell',[string]$Digest=$script:TemplateDigest,[hashtable]$Overrides=@{}){
    $values=@{id=$Id;name=$Name;agent=$Agent;digest=$Digest;cpus='2';memory='2g';shareSkills='false';workspaceDir='';sshAgentSocketPath=''}
    foreach($key in $Overrides.Keys){$values[$key]=$Overrides[$key]}
    Expand-FakeTemplate $script:RuntimeTemplate $values
}
function Add-FakeSbxSandboxScenario([hashtable]$Case,[string]$Name,[string]$Id,[string]$Agent='shell',[string]$Digest=$script:TemplateDigest,[object[]]$ConfirmFiles=@(),[switch]$AlreadyPresent,[string]$InitialStatus='running',[double]$CreateDelaySeconds=0){
    # 1台分の既定応答: create（状態遷移・runtime ファイル・daemon.log 行）→ inspect / policy → 保持 exec → cp / chown → Confirm → stop。
    # -AlreadyPresent は run が作ったのではなく最初から一覧にあるVM（復旧操作の対象など）。
    # -CreateDelaySeconds は create の状態遷移を済ませてから応答を遅らせる（デーモン側では作成済みだがクライアントが時間超過する経路。遅延は synthetic）。
    $Case.sandboxes.Add(@{name=$Name;id=$Id;agent=$Agent;runCreated=(-not$AlreadyPresent);initialStatus=$InitialStatus})
    $runtimePath=Join-Path $Case.runtimesDir ($Name+'.json')
    if($AlreadyPresent){[IO.File]::WriteAllText($runtimePath,(New-FakeRuntimeFileText $Name $Id $Agent $Digest),$script:Utf8)}
    $create=Get-FakeSbxResponse 'createSuccess' @{name=$Name;agent=$Agent;digest=$Digest}
    $createPattern=@('create',[regex]::Escape($Agent),'--name',[regex]::Escape($Name),'--cpus','2','--memory','2g','--no-share-skills')
    if($Agent -ceq 'codex'){foreach($hostName in $script:ProposalDeniedHosts){$createPattern+=@('--deny-network',[regex]::Escape($hostName))}}
    else{$createPattern+=@('--deny-network','\*')}
    $createPattern+=@('--template',[regex]::Escape($Digest))
    Add-FakeSbxResponse $Case $createPattern -Stdout $create.text -Synthetic ($create.synthetic -or $CreateDelaySeconds -gt 0) -Source ($create.source+' / 22-runtime-file.json / 20-daemonlog-new-runtime-network.txt') `
        -DelaySeconds $CreateDelaySeconds `
        -Sets @{"vm:$Name"='running';"present:$Name"='1'} `
        -WriteFile @(@{path=$runtimePath;text=(New-FakeRuntimeFileText $Name $Id $Agent $Digest)}) `
        -AppendFile @(@{path=$Case.logPath;text=(New-FakeSbxLogLine 'createdRuntime' $Name)}) | Out-Null
    $inspect=Get-FakeSbxResponse 'inspect' @{name=$Name;agent=$Agent;digest=$Digest;imageDigest=$Digest.Substring($Digest.IndexOf('@')+1)}
    $inspectText=$inspect.text
    if($Agent -ceq 'codex'){$inspectText=$inspectText.Replace('"secrets": [','"secrets": [{"name":"openai","source":"host"},')}
    Add-FakeSbxResponse $Case @('inspect',[regex]::Escape($Name),'--json') -Stdout $inspectText -Synthetic ($inspect.synthetic -or $Agent -ceq 'codex') -Source $inspect.source | Out-Null
    $policy=Get-FakeSbxResponse 'policyLs' @{name=$Name}
    if($Agent -ceq 'codex'){
        $rules=@()
        foreach($hostName in $script:ProposalAllowedHosts){$rules+=@{scope="sandbox:$Name";resource_type='network';decision='allow';resources=@($hostName);status='active'}}
        foreach($hostName in $script:ProposalDeniedHosts){
            $kitResource=$(if($hostName -in @('archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com')){"$($hostName):80"}else{$hostName})
            $rules+=@{scope="sandbox:$Name";resource_type='network';decision='allow';resources=@($kitResource);status='active'}
            $rules+=@{scope="sandbox:$Name";resource_type='network';decision='deny';resources=@($hostName);status='active'}
        }
        Add-FakeSbxResponse $Case @('policy','ls',[regex]::Escape($Name),'--json') -Stdout (ConvertTo-Json -InputObject @{rules=$rules} -Depth 6) -Synthetic $true -Source 'ADR-0199 の未実測proposal規則を模した応答' | Out-Null
        $checks=@()
        foreach($hostName in $script:ProposalAllowedHosts){foreach($port in @(443,8443)){$checks+=@{host=$hostName;port=$port;allowed=$true}}}
        foreach($hostName in $script:ProposalDeniedHosts+@('example.com')){$checks+=@{host=$hostName;port=$(if($hostName -in @('archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com')){80}else{443});allowed=$false}}
        foreach($check in $checks){
            $scheme=$(if($check.port -eq 80){'http'}else{'https'})
            Add-FakeSbxResponse $Case @('policy','check','network','--sandbox',[regex]::Escape($Name),[regex]::Escape("$($scheme)://$($check.host):$($check.port)"),'--json') -Stdout (ConvertTo-Json -InputObject @{allowed=$check.allowed} -Compress) -Synthetic $true -Source 'ADR-0199 の未実測policy checkを模した応答' | Out-Null
        }
    }else{Add-FakeSbxResponse $Case @('policy','ls',[regex]::Escape($Name),'--json') -Stdout $policy.text -Synthetic $policy.synthetic -Source $policy.source | Out-Null}
    $log=Get-FakeSbxResponse 'policyLog' @{name=$Name}
    Add-FakeSbxResponse $Case @('policy','log',[regex]::Escape($Name),'--json') -Stdout $log.text -Synthetic $log.synthetic -Source $log.source | Out-Null
    # 以下4種は実測原文が無い創作応答（保持 exec の無出力、cp・chown の無出力、Confirm の sha256sum 行）。タスク8a の実機対照で確かめる。
    # セッション保持の exec は終わらない（停止側の保持ジョブ停止で止める）。
    Add-FakeSbxResponse $Case @('exec',[regex]::Escape($Name),'sh','-c','sleep \d+') -DelaySeconds 3600 -Synthetic $true -Source 'keep-alive exec の出力は未記録' | Out-Null
    Add-FakeSbxResponse $Case @('cp','.+',([regex]::Escape($Name)+':.+')) -Synthetic $true -Source 'cp の出力は未記録' | Out-Null
    Add-FakeSbxResponse $Case @('exec','-u','root',[regex]::Escape($Name),'chown','-R','agent:agent','.+') -Synthetic $true -Source 'chown の出力は未記録' | Out-Null
    $lines=[Text.StringBuilder]::new()
    foreach($file in $ConfirmFiles){[void]$lines.Append(([string]$file.sha256).ToLowerInvariant()+'  ./'+[string]$file.path+"`n")}
    Add-FakeSbxResponse $Case @('exec','-w','.+',[regex]::Escape($Name),'sh','-c','cd \S+ && find \. -type f -print0 \| sort -z \| xargs -0 sha256sum') -Stdout $lines.ToString() -Synthetic $true -Source 'sha256sum の行形式は GNU coreutils の既定形式に合わせた創作' | Out-Null
    $stop=Get-FakeSbxResponse 'stop' @{name=$Name}
    Add-FakeSbxResponse $Case @('stop',[regex]::Escape($Name)) -Stdout $stop.text -Synthetic $stop.synthetic -Source ($stop.source+' / 44-daemonlog-stop.txt') -Sets @{"vm:$Name"='stopped'} -AppendFile @(@{path=$Case.logPath;text=(New-FakeSbxLogLine 'stoppedContainer' $Name)}) | Out-Null
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
        $entries+=@{argv=@('ls','--json');stdout=(New-FakeSbxLsJson (@($listed)+$always));stderr='';exitCode=0;delaySeconds=0;synthetic=$false;source='11-vms-after-create.json / 42-vms-after-stop.json の形式（名前・id は試験の値）';requires=$requires;sets=$null;appendFile=@();writeFile=@()}
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
    # 偽sbx（背景の保持 exec を含む）の追記と重なりうるので、共有 ReadWrite で開き、共有違反は短時間だけ開き直す。書込み途中の最終行（改行なし）は読まない。
    if(-not(Test-Path -LiteralPath $Case.callsPath)){return}
    $deadline=[DateTime]::UtcNow.AddSeconds(10);$text=$null
    while($null -eq $text){
        try{
            $stream=[IO.File]::Open($Case.callsPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
            try{$text=[IO.StreamReader]::new($stream,$script:Utf8).ReadToEnd()}finally{$stream.Dispose()}
        }catch [IO.IOException]{if([DateTime]::UtcNow -ge $deadline){throw};Start-Sleep -Milliseconds 20}
    }
    $complete=$text.Substring(0,$text.LastIndexOf("`n")+1)
    @($complete.Split("`n") | Where-Object {$_.Trim().Length -gt 0} | ForEach-Object {$_ | ConvertFrom-Json -AsHashtable})
}
function Get-FakeSbxCaseDirectory($Item){
    # 偽sbxのケース（New-FakeSbxCase の戻り）か、それを case キーに持つ試験側の文脈のどちらでも受ける。
    if($Item.ContainsKey('sbxDir')){return [string]$Item.sbxDir}
    [string]$Item.case.sbxDir
}
function Get-CaseFakeProcesses([object[]]$Ctxs){
    # 指定ケースの偽sbx一式（ケースごとに一意なディレクトリ）をコマンドラインに持つプロセス。名前では選ばない。
    $dirs=@($Ctxs | ForEach-Object {Get-FakeSbxCaseDirectory $_})
    @(Get-CimInstance Win32_Process | Where-Object {$line=$_.CommandLine;$null -ne $line -and @($dirs | Where-Object {$line.IndexOf($_,[StringComparison]::OrdinalIgnoreCase) -ge 0}).Count -gt 0} | ForEach-Object {@{processId=[int]$_.ProcessId;createdAt=$_.CreationDate}})
}
function Stop-CaseFakeProcesses([object[]]$Ctxs){
    # 実測（タスク3 修正ラウンド1、Issue-0147 修正後）: ジョブへ明示割当された cmd.exe（fake-sbx.cmd）は止まるが、cmd.exe が起動する MSIX 版 pwsh（FakeSbx.ps1 の本体）は
    # ジョブを継承せず、時間超過・保持停止のジョブ停止が届かない（遅延中の偽sbxが残る）。試験が起動した当該ケースのプロセスだけを PID と起動時刻を照合して止める。
    # SbxRuntimeV3 と Proposal/Replay/CLI の v3 試験で共用するため、試験スクリプトからこのモジュールへ移した（挙動は同じ）。
    foreach($item in @(Get-CaseFakeProcesses $Ctxs)){
        $process=Get-Process -Id $item.processId -ErrorAction SilentlyContinue
        if($null -eq $process){continue}
        $same=$false;try{$same=[Math]::Abs(($process.StartTime-$item.createdAt).TotalSeconds) -lt 1}catch{}
        if($same){Stop-Process -Id $item.processId -Force -ErrorAction SilentlyContinue}
    }
    $until=[DateTime]::UtcNow.AddSeconds(5)
    while(@(Get-CaseFakeProcesses $Ctxs).Count -gt 0 -and [DateTime]::UtcNow -lt $until){Start-Sleep -Milliseconds 200}
}
Export-ModuleMember -Function Get-FakeSbxTemplateDigest,Get-FakeSbxResponse,New-FakeSbxLogLine,New-FakeSbxCase,Add-FakeSbxResponse,New-FakeRuntimeFileText,Add-FakeSbxSandboxScenario,Write-FakeSbxScenario,Set-FakeSbxState,Add-FakeDaemonLogLine,Read-FakeSbxCalls,Get-CaseFakeProcesses,Stop-CaseFakeProcesses
