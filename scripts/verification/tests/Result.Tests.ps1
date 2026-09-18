$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Assert-True (Test-Path -LiteralPath (Join-Path $PSScriptRoot '../Result.psm1')) '結果照合が未実装'
Import-Module (Join-Path $PSScriptRoot '../Result.psm1') -Force
function New-ResultCase([string]$Name){
    $case=New-TestCase ('result-'+$Name);$run=New-VerificationRun $case.request $case.settings
    $event=@{type='item.completed';item=@{id='item_1';type='command_execution';command='fixture-check';exit_code=0;aggregated_output='ok'}}
    $agent=@{runId=$run.runId;verdict='pass';summary='fixture passed';checks=@(@{command='fixture-check';exitCode=0;evidencePath='work/evidence.txt'});findings=@();artifacts=@('work/evidence.txt');unverified=@()}
    [IO.File]::WriteAllText((Join-Path $run.workRoot 'evidence.txt'),'ok')
    $execution=@{runId=$run.runId;started=$true;exitCode=0;timedOut=$false;processTreeStopped=$true;eventsPath=(Join-Path $run.controlRoot 'events.jsonl');stderrPath=(Join-Path $run.controlRoot 'stderr.txt');agentResultPath=(Join-Path $run.controlRoot 'agent-result.json');effectiveConfigPath=(Join-Path $run.controlRoot 'effective-config.json')}
    @{run=$run;execution=$execution;agent=$agent;event=$event}
}
function Save-ResultFixture($Case){
    [IO.File]::WriteAllText($Case.execution.eventsPath,('{"type":"thread.started","thread_id":"fixture"}'+"`n"+($Case.event | ConvertTo-Json -Depth 8 -Compress)+"`n"+'{"type":"turn.completed"}'+"`n"))
    [IO.File]::WriteAllText($Case.execution.agentResultPath,($Case.agent | ConvertTo-Json -Depth 8))
}
$cases=@('pass','fail','not-started','missing-response','bad-json','wrong-id','wrong-exit','no-events','duplicate-event','unverified','escape','junction','source-change','timeout','existing-result')
foreach($name in $cases){
    $case=New-ResultCase $name
    switch($name){
        'fail'{$case.agent.verdict='fail';$case.agent.checks[0].exitCode=1;$case.event.item.exit_code=1}
        'not-started'{$case.execution.started=$false;$case.execution.exitCode=$null}
        'wrong-id'{$case.agent.runId='wrong'}
        'wrong-exit'{$case.agent.checks[0].exitCode=7}
        'unverified'{$case.agent.unverified=@('not tested')}
        'escape'{$case.agent.artifacts=@('../outside.txt')}
        'junction'{New-Item -ItemType Junction -Path (Join-Path $case.run.workRoot 'link') -Target $case.run.sourceRoot | Out-Null;$case.agent.artifacts=@('work/link/tracked.txt')}
        'source-change'{[IO.File]::WriteAllText((Join-Path $case.run.sourceRoot 'tracked.txt'),'changed')}
        'timeout'{$case.execution.timedOut=$true;$case.execution.processTreeStopped=$false}
    }
    Save-ResultFixture $case
    switch($name){
        'missing-response'{$case.execution.agentResultPath=Join-Path $case.run.controlRoot 'absent.json'}
        'bad-json'{[IO.File]::WriteAllText($case.execution.agentResultPath,'{bad')}
        'no-events'{[IO.File]::WriteAllText($case.execution.eventsPath,'{"type":"turn.completed"}')}
        'duplicate-event'{[IO.File]::AppendAllText($case.execution.eventsPath,($case.event | ConvertTo-Json -Depth 8 -Compress)+"`n")}
        'existing-result'{[IO.File]::WriteAllText((Join-Path $case.run.controlRoot 'result.json'),'original')}
    }
    if($name -eq 'existing-result'){
        Assert-Throws {Complete-VerificationRun $case.run $case.execution} '*exists*'
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $case.run.controlRoot 'result.json'))) 'original' '既存結果を保全'
        continue
    }
    $result=Complete-VerificationRun $case.run $case.execution
    $expected=switch($name){'pass'{'completed'};'fail'{'completed'};'not-started'{'blocked'};'source-change'{'source_changed'};'timeout'{'timed_out'};default{'incomplete'}}
    Assert-Equal $result.status $expected $name
    Assert-True (Test-Json -Json ($result | ConvertTo-Json -Depth 20) -SchemaFile (Join-Path $PSScriptRoot '../result.schema.json')) '結果スキーマ'
    if($name -eq 'pass'){Assert-Equal $result.checks[0].eventId 'item_1' '実イベントと対応';Assert-Equal $result.artifacts[0].sha256 (Get-FileHash -LiteralPath (Join-Path $case.run.workRoot 'evidence.txt')).Hash '実体のハッシュ'}
    if($name -eq 'fail'){Assert-Equal $result.agentVerdict 'fail' '不合格報告を保持'}
    if($name -eq 'timeout'){Assert-True (-not$result.execution.processTreeStopped) '停止未確認を保持'}
}
"Result: $($cases.Count) scenarios passed"
