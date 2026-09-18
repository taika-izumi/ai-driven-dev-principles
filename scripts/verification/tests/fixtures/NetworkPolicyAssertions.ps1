# 実測で判明した443番限定とpolicy check終了1の回帰試験。実sbxは呼ばない。
param([string]$TestsRoot)
$ErrorActionPreference='Stop'
Import-Module (Join-Path $TestsRoot '../SbxRuntime.psm1') -Force -DisableNameChecking
Import-Module (Join-Path $TestsRoot 'TestSupport.psm1') -Force
$runtime=Get-Module SbxRuntime
$name='iv-f107bb84-proposal'
$fixture=Join-Path $TestsRoot 'fixtures/fake-sbx-responses'
$policy=Get-Content -Raw -LiteralPath (Join-Path $fixture 'proposal-policy-real.json') | ConvertFrom-Json -AsHashtable
Assert-True (Test-VerificationProposalRules (Get-VerificationNetworkRules $policy) $name) '実測のポート付き規則を受理する'
foreach($foreignScope in @('global','sandbox:iv-other-proposal')){
    $wrongPolicy=$policy | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
    $allow=@($wrongPolicy.rules | Where-Object {$_.resource_type -ceq 'network' -and $_.decision -ceq 'allow'})[0]
    $allow.scope=$foreignScope
    Assert-True (-not(Test-VerificationProposalRules (Get-VerificationNetworkRules $wrongPolicy) $name)) '対象VM以外のallowで実測規則を代用しない'
}
$targets=@(Get-VerificationProposalNetworkTargets)
Assert-Equal @($targets | Where-Object {$_.allowed}).Count 2 '許可は443番の2件だけ'
Assert-True (-not($targets | Where-Object {$_.port -eq 8443}).allowed.Contains($true)) '8443番は拒否対照'
function New-CheckResult($ExitCode){@{started=$true;refusedReason=$null;timedOut=$false;outputExceeded=$false;exitCode=$ExitCode}}
$allowed=Get-Content -Raw -LiteralPath (Join-Path $fixture 'proposal-policy-allowed-real.json')
$denied=Get-Content -Raw -LiteralPath (Join-Path $fixture 'proposal-policy-denied-real.json')
Assert-True (ConvertFrom-VerificationNetworkPolicyCheck (New-CheckResult 0) $allowed $name 'https://auth.openai.com:443').allowed '実測の許可/終了0'
Assert-True (-not(ConvertFrom-VerificationNetworkPolicyCheck (New-CheckResult 1) $denied $name 'https://auth.openai.com:8443').allowed) '実測の拒否/終了1'
foreach($case in @(
    @{result=(New-CheckResult 0);json=$denied},
    @{result=(New-CheckResult 1);json=$allowed},
    @{result=(New-CheckResult 2);json=$denied},
    @{result=(New-CheckResult $null);json=$denied},
    @{result=(New-CheckResult 1);json='{"allowed":false}'},
    @{result=(New-CheckResult 1);json='invalid'},
    @{result=(New-CheckResult 1);json=$denied.Replace('"allowed": false','"allowed": "false"')},
    @{result=(New-CheckResult 1);json=$denied.Replace('"allowed": false','"allowed": false,"allowed": false')},
    @{result=(New-CheckResult 1);json=$denied.Replace($name,'iv-other-proposal')},
    @{result=(New-CheckResult 1);json=$denied.Replace('auth.openai.com:8443','auth.openai.com:443')},
    @{result=(New-CheckResult 1);json=$denied.Replace('net:connect:tcp','net:connect:udp')}
)){
    Assert-Throws {ConvertFrom-VerificationNetworkPolicyCheck $case.result $case.json $name 'https://auth.openai.com:8443'} '*policy check*'
}
foreach($flag in @('started','refusedReason','timedOut','outputExceeded')){
    $result=New-CheckResult 1
    $result[$flag]=$(if($flag -eq 'started'){$false}elseif($flag -eq 'refusedReason'){'blocked'}else{$true})
    Assert-Throws {ConvertFrom-VerificationNetworkPolicyCheck $result $denied $name 'https://auth.openai.com:8443'} '*policy check*'
}
# 拒否判定の変更で、既存の実行不能・時間超過の分類を失わない。
foreach($case in @(
    @{result=@{started=$false;refusedReason='deadline-reached';timedOut=$false;outputExceeded=$false;exitCode=$null};status='timed_out';kind='deadline-reached'},
    @{result=@{started=$true;refusedReason=$null;timedOut=$true;outputExceeded=$false;exitCode=$null};status='blocked';kind='query-timed-out'}
)){
    $failure=$null
    try{ConvertFrom-VerificationNetworkPolicyCheck $case.result $denied $name 'https://auth.openai.com:8443' | Out-Null}catch{$failure=$_.Exception}
    Assert-True ($null -ne $failure) '実行失敗を受理しない'
    Assert-Equal $failure.Data['status'] $case.status '従来の失敗statusを保つ'
    Assert-Equal $failure.Data['reason'] $case.kind '従来の失敗reasonを保つ'
}
# probe専用呼出しも同じ実測JSON/終了コードを受理し、一般のJSON照会は終了1を受け入れない。
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $TestsRoot 'Invoke-SbxPilotProbe.ps1'),[ref]$tokens,[ref]$errors)
foreach($functionName in @('Invoke-ProbeNetworkPolicyCheck','Invoke-ProbeSbxJson','Assert-ProbeSbxOk')){
    $definition=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $functionName},$true))
    Assert-Equal $definition.Count 1 "probe関数: $functionName"
    . ([scriptblock]::Create($definition[0].Extent.Text))
}
$script:State=@{name=$name};$script:QuerySeconds=60
$script:fakeCall=New-CheckResult 1
$script:fakeCall.stdout=$denied;$script:fakeCall.stderr='';$script:fakeCall.tag='policy-check'
function Invoke-ProbeSbx { $script:fakeCall }
Assert-True (-not(Invoke-ProbeNetworkPolicyCheck 'https://auth.openai.com:8443' 'policy-check').allowed) 'probeも正常拒否を受理'
Assert-Throws {Invoke-ProbeSbxJson @('inspect',$name,'--json') 'inspect'} '*failed*'
# 製品側の専用経路の配線を確認。外部プロセスの代わりに固定応答を返すモジュールスコープを使う。
& $runtime {
    param($Result,$Json,$Name)
    $original=(Get-Item Function:Invoke-VerificationSbx).ScriptBlock
    try{
        $script:networkTestResponse=@{result=$Result;stdout=$Json;stderr=''}
        function Invoke-VerificationSbx { $script:networkTestResponse }
        $budget=@{deadlineAt=[DateTime]::UtcNow.AddMinutes(1).ToString('o');phase='work';limits=@{commandSeconds=60;maxOutputBytes=4096}}
        $client=@{maxOutputBytes=4096}
        $value=Invoke-VerificationNetworkPolicyCheck $client $Name 'https://auth.openai.com:8443' $budget
        if($value.allowed -cne $false){throw 'product rejected a valid denial'}
        $caught=$false
        try{Invoke-VerificationSbxJson $client @('inspect',$Name,'--json') $budget 'inspect' | Out-Null}catch{$caught=$true}
        if(-not$caught){throw 'generic product query accepted exit 1'}
    }finally{Set-Item Function:Invoke-VerificationSbx $original}
} (New-CheckResult 1) $denied $name
Write-Host 'NetworkPolicy assertions PASS (real response fixtures; no real sbx)'
