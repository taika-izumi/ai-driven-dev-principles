# SbxRuntimeV3.Tests.ps1 から呼ぶ、提案用probeの分岐・観測・失敗時停止の回帰確認。
# 実sbxは使わず、同じ偽sbxと専用8文字のケース領域だけを使う。
param([string]$TestsRoot,[string]$BaseRoot)
$ErrorActionPreference='Stop'
if(-not(Get-Module SbxRuntime)){Import-Module (Join-Path $TestsRoot '../SbxRuntime.psm1') -DisableNameChecking}
if(-not(Get-Module FakeSbxScenario)){Import-Module (Join-Path $TestsRoot 'fixtures/FakeSbxScenario.psm1')}
$probe=Join-Path $TestsRoot 'Invoke-SbxPilotProbe.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($probe,[ref]$tokens,[ref]$errors)
if($errors.Count){throw "probe parse failed: $($errors[0].Message)"}
foreach($name in @('Get-ProbeSteps','Get-ProbeProxyGateway','Invoke-ProbeGuestObservation','Test-ProbeGuestObservation','Test-ProbeStartupObservation','Test-ProbeProposalObservation')){
    $definition=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
    if($definition.Count -ne 1){throw "probe function missing: $name"}
    . ([scriptblock]::Create($definition[0].Extent.Text))
}
function Assert-ProbeSteps([string]$Role,[string]$Phase,[string]$Expected){
    $actual=@(Get-ProbeSteps $Role $Phase | ForEach-Object {$_.name}) -join ','
    if($actual -cne $Expected){throw "probe steps mismatch for $Role/${Phase}: $actual"}
}
Assert-ProbeSteps 'probe' '' '00-setup,01-version-stdlib,02-input-unittest,03-transport,04-flood,05-queries,06-hold,07-kill,08-resume'
Assert-ProbeSteps 'proposal' 'limitsAndTransport' '00-setup,01-version-stdlib,02-input-unittest,03-transport,04-flood,05-queries,06-proposal-stop'
Assert-ProbeSteps 'proposal' 'abnormalExitRecovery' '00-setup,07-kill,08-resume'
foreach($invalid in @(@('proposal',''),@('unknown',''))){$rejected=$false;try{@(Get-ProbeSteps $invalid[0] $invalid[1]) | Out-Null}catch{$rejected=$true};if(-not$rejected){throw 'invalid role/phase accepted'}}
$guest=@{sshSocketPresent=$false;sshGatewayResponseBytes=0;proxyControlStatus=403;nproc=2;memTotalKiB=2036100}
if(-not(Test-ProbeGuestObservation $guest)){throw 'guest protection observation rejected'}
$guest.sshSocketPresent=$true
if(Test-ProbeGuestObservation $guest){throw 'SSH socket observation accepted'}
$guest.sshSocketPresent=$false
$guest.proxyControlStatus=0
if(Test-ProbeGuestObservation $guest){throw 'missing proxy control response accepted'}
$guest.proxyControlStatus=403
foreach($badInspect in @(@{},@{proxy=''},@{proxy=':3128'},@{proxy='172.17.0.2'},@{proxy='http://172.17.0.2:3128'},@{proxy='999.17.0.2:3128'},@{proxy='172.17.0.2:99999'})){
    $rejected=$false
    try{Get-ProbeProxyGateway $badInspect | Out-Null}catch{$rejected=$true}
    if(-not$rejected){throw 'missing or malformed inspect.proxy accepted'}
}
if((Get-ProbeProxyGateway @{proxy='172.17.0.2:3128'}) -cne '172.17.0.2'){throw 'valid IPv4 proxy was rejected'}
$script:guestExecIssued=$false
function Invoke-ProbeSbx {$script:guestExecIssued=$true;throw 'guest exec should not run'}
$rejected=$false
try{Invoke-ProbeGuestObservation @{} | Out-Null}catch{$rejected=$true}
if(-not$rejected -or $script:guestExecIssued){throw 'missing proxy reached guest exec'}
$startup=@{inspectSessions=0;codexProcessCount=0;processProbeStarted=$true}
if(-not(Test-ProbeStartupObservation $startup)){throw 'startup observation rejected'}
$startup.codexProcessCount=1
if(Test-ProbeStartupObservation $startup){throw 'active codex process accepted'}
$name='iv-12345678-proposal'
$allowed=@('api.openai.com:443','openai.com:443','auth.openai.com:443','chatgpt.com:443','files.openai.com:443','registry.npmjs.org:443','api.github.com:443','github.com:443','codeload.github.com:443','archive.ubuntu.com:80','security.ubuntu.com:80','ports.ubuntu.com:80','download.docker.com:443')
$denied=@('api.openai.com','openai.com','files.openai.com','registry.npmjs.org','api.github.com','github.com','codeload.github.com','archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com','download.docker.com')
$rules=@()
foreach($hostName in $allowed){$rules+=@{scope="sandbox:$name";decision='allow';resource_type='network';resources=@($hostName);status='active'}}
foreach($hostName in $denied){$rules+=@{scope="sandbox:$name";decision='deny';resource_type='network';resources=@($hostName);status='active'}}
$checks=@(@{host='auth.openai.com';port=443;allowed=$true},@{host='auth.openai.com';port=8443;allowed=$false},@{host='chatgpt.com';port=443;allowed=$true},@{host='chatgpt.com';port=8443;allowed=$false})
foreach($hostName in $denied+@('example.com')){$checks+=@{host=$hostName;port=$(if($hostName -in @('archive.ubuntu.com','security.ubuntu.com','ports.ubuntu.com')){80}else{443});allowed=$false}}
$policy=@{rules=$rules};$inspect=@{secrets=@(@{name='mcpgateway'},@{name='openai'})}
$credentials=@{oauthMode=$true;accessSentinel=$true;modelEndpoint=$true;requiresOpenaiAuthDisabled=$true;authPlaceholder=$true}
$policyLog=@{blocked_hosts=@(@{host='example.com:80';vm_name=$name})}
if(-not(Test-ProbeProposalObservation $policy $checks $inspect $credentials $guest $policyLog $name)){throw 'valid proposal observation rejected'}
$credentials.accessSentinel=$false
if(Test-ProbeProposalObservation $policy $checks $inspect $credentials $guest $policyLog $name){throw 'wrong sentinel accepted'}
Write-Host 'ProbeV3 decision and observation assertions PASS'

function Invoke-FakeProposalProbe([bool]$ActiveAgent,[bool]$InvalidProxy=$false){
    $root=$null
    do{$root=Join-Path $BaseRoot ('p9'+[guid]::NewGuid().ToString('N').Substring(0,6))}while([IO.Directory]::Exists($root))
    $case=New-FakeSbxCase $root
    $runId=[guid]::NewGuid().ToString();$vm='iv-'+$runId.Substring(0,8)+'-proposal';$id=[guid]::NewGuid().ToString()
    Add-FakeSbxSandboxScenario $case $vm $id -Agent 'codex'
    if($InvalidProxy){
        $inspectEntry=@($case.entries | Where-Object {$_.argv[0] -eq 'inspect' -and $_.argv[1] -eq [regex]::Escape($vm)})[0]
        $inspectValue=$inspectEntry.stdout | ConvertFrom-Json -AsHashtable
        [void]$inspectValue.Remove('proxy')
        $inspectEntry.stdout=ConvertTo-Json -InputObject $inspectValue -Depth 8;$inspectEntry.synthetic=$true
    }
    Add-FakeSbxResponse $case @('exec',[regex]::Escape($vm),'python3','-c','.*codexProcessCount.*') -Stdout $(if($ActiveAgent){'{"codexProcessCount":1}'}else{'{"codexProcessCount":0}'}) -Synthetic $true -Source 'agent起動観測の偽応答' | Out-Null
    Write-FakeSbxScenario $case
    $runRoot=Join-Path $root 'run'
    [void][IO.Directory]::CreateDirectory((Join-Path $runRoot 'obs'))
    [void][IO.Directory]::CreateDirectory((Join-Path $runRoot 'control/runtime'))
    $limits=@{totalSeconds=600;proposalSeconds=60;replaySeconds=30;cleanupSeconds=30;cpus=2;memoryMiB=2048;maxProposalFiles=100;maxFileBytes=1MB;maxProposalBytes=8MB;maxWireBytes=16MB;maxOutputBytes=16MB}
    $pwsh=(Get-Command pwsh).Source
    $state=@{schemaVersion=3;runId=$runId;runRoot=$runRoot;settingsPath='fixture-resume';sbxPath=$case.sbxPath;limits=$limits;role='proposal';proposalPhase='limitsAndTransport';name=$vm
        id=$null;createdAt=$null;deadlineAt=[DateTime]::UtcNow.AddMinutes(10).ToString('o');daemon=$null;logPath=$null;stateRoot=$null;keepAlive=$null;sandboxRecordPath=$null;kill=$null;completed=@();callSequence=0
        recoveryInput=@{schemaVersion=3;sbxPath=$case.sbxPath;pwshPath=$pwsh;runsRoot=$root;limits=$limits}}
    [IO.File]::WriteAllText((Join-Path $runRoot 'probe-state.json'),($state | ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($false))
    & $pwsh -NoProfile -File $probe -Resume $runRoot 2>&1 | Out-File -LiteralPath (Join-Path $root 'probe.out')
    if($LASTEXITCODE -eq 0){throw 'expected synthetic probe failure'}
    $startupPath=Join-Path $runRoot 'obs/00-startup.json';$stopPath=Join-Path $runRoot 'obs/proposal-error-stop.json'
    if(-not[IO.File]::Exists($startupPath) -or -not[IO.File]::Exists($stopPath)){throw 'probe observations missing'}
    $startup=Get-Content -LiteralPath $startupPath -Raw | ConvertFrom-Json -AsHashtable
    $stop=Get-Content -LiteralPath $stopPath -Raw | ConvertFrom-Json -AsHashtable
    if($startup.codexProcessCount -ne $(if($ActiveAgent){1}else{0}) -or $startup.inspectSessions -ne 0 -or $stop.stopState -cne 'stopped' -or $stop.id -cne $id){throw 'probe startup or stop observation mismatch'}
    if(($ActiveAgent -or $InvalidProxy) -and [IO.File]::Exists((Join-Path $runRoot 'obs/00-setup.json'))){throw 'invalid startup advanced to setup'}
    $calls=@(Read-FakeSbxCalls $case)
    if(@($calls | Where-Object {$_.argv[0] -eq 'stop' -and $_.argv[1] -eq $vm}).Count -ne 1){throw 'proposal VM was not stopped exactly once'}
    $before=$calls.Count
    & $pwsh -NoProfile -File $probe -Resume $runRoot 2>&1 | Out-File -LiteralPath (Join-Path $root 'resume.out')
    if($LASTEXITCODE -eq 0 -or @(Read-FakeSbxCalls $case).Count -ne $before){throw 'failed proposal resumed or issued sbx calls'}
    $case
}
$cases=@((Invoke-FakeProposalProbe $false),(Invoke-FakeProposalProbe $true),(Invoke-FakeProposalProbe $false $true))
Write-Host 'ProbeV3 fake startup and failure-stop assertions PASS'
$cases
