# 検証担当の申告を実イベントと成果物へ結び付け、根拠の欠けた合格を返さない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')
function Get-VerificationArtifact([hashtable]$Run,[string]$Relative) {
    if([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or $Relative.Contains(':') -or ($Relative.Replace('\','/').Split('/') -contains '..')){throw 'invalid artifact relative path'}
    $path=Resolve-VerificationPath (Join-Path $Run.runRoot $Relative)
    if(-not(Test-VerificationContainment $Run.runRoot $path) -or -not[IO.File]::Exists($path)){throw 'artifact missing or outside run'}
    @{path=$Relative;size=(Get-Item -LiteralPath $path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
}
function Complete-VerificationRun([hashtable]$PreparedRun,[hashtable]$ExecutionResult) {
    $control=Resolve-VerificationPath $PreparedRun.controlRoot
    if(-not(Test-VerificationContainment $PreparedRun.runRoot $control)){throw 'control outside run'}
    $destination=Join-Path $control 'result.json'
    if(Test-Path -LiteralPath $destination){throw 'result already exists'}
    $result=[ordered]@{schemaVersion=1;runId=$PreparedRun.runId;status='incomplete';summary='';sourceState='unreadable';agentVerdict=$null;checks=@();findings=@();artifacts=@();unverified=@();execution=$ExecutionResult;runRoot=$PreparedRun.runRoot}
    try{
        $now=Get-VerificationSourceManifest $PreparedRun.request $PreparedRun.settings
        $result.sourceState=if(Test-VerificationManifestEqual $PreparedRun.sourceManifest $now){'unchanged'}else{'changed'}
    }catch{$result.unverified+=('source unreadable: '+$_.Exception.Message)}
    if($ExecutionResult.timedOut){$result.status='timed_out';$result.summary='execution timed out'}
    elseif(-not$ExecutionResult.started){$result.status='blocked';$result.summary='execution did not start'}
    elseif($result.sourceState -eq 'changed'){$result.status='source_changed';$result.summary='source changed since preparation'}
    elseif($result.sourceState -eq 'unreadable'){$result.summary='source state could not be checked'}
    else{
        try{
            if($ExecutionResult.runId -cne $PreparedRun.runId){throw 'execution runId mismatch'}
            if(-not$ExecutionResult.processTreeStopped){throw 'process tree stop unverified'}
            if($ExecutionResult.exitCode -ne 0){throw 'agent process did not exit successfully'}
            foreach($key in @('eventsPath','agentResultPath')){
                $path=Resolve-VerificationPath $ExecutionResult[$key]
                if(-not(Test-VerificationContainment $control $path) -or -not[IO.File]::Exists($path)){throw "missing control output: $key"}
            }
            $agentJson=[IO.File]::ReadAllText($ExecutionResult.agentResultPath)
            if(-not(Test-Json -Json $agentJson -SchemaFile (Join-Path $PSScriptRoot 'agent-result.schema.json') -ErrorAction SilentlyContinue)){throw 'invalid agent response'}
            $agent=$agentJson | ConvertFrom-Json -AsHashtable
            if($agent.runId -cne $PreparedRun.runId){throw 'agent runId mismatch'}
            $result.agentVerdict=$agent.verdict
            $result.findings=@($agent.findings)
            if($agent.verdict -eq 'incomplete' -or $agent.unverified.Count -gt 0){$result.unverified+=@($agent.unverified);throw 'agent reports unverified checks'}
            $events=[Collections.Generic.List[object]]::new()
            foreach($line in [IO.File]::ReadLines($ExecutionResult.eventsPath)){
                if([string]::IsNullOrWhiteSpace($line)){continue}
                $events.Add(($line | ConvertFrom-Json -AsHashtable -ErrorAction Stop))
            }
            if(@($events | Where-Object type -EQ 'thread.started').Count -ne 1 -or @($events | Where-Object type -EQ 'turn.completed').Count -ne 1 -or @($events | Where-Object type -In @('turn.failed','error')).Count -gt 0){throw 'missing or failed execution events'}
            $commands=@($events | Where-Object {$_.type -eq 'item.completed' -and $_.ContainsKey('item') -and $_.item.type -eq 'command_execution'})
            if($agent.checks.Count -eq 0){throw 'no executed checks reported'}
            $checks=[Collections.Generic.List[object]]::new();$artifacts=[Collections.Generic.List[object]]::new()
            foreach($check in $agent.checks){
                $matches=@($commands | Where-Object {$_.item.command -ceq $check.command})
                if($matches.Count -ne 1){throw 'command event is missing or ambiguous'}
                $item=$matches[0].item
                if(-not$item.ContainsKey('exit_code') -or $item.exit_code -cne $check.exitCode -or -not$item.ContainsKey('id')){throw 'command exit code or id mismatch'}
                $null=Get-VerificationArtifact $PreparedRun $check.evidencePath
                $checks.Add(@{command=$check.command;exitCode=$check.exitCode;evidencePath=$check.evidencePath;eventId=$item.id})
            }
            foreach($path in $agent.artifacts){$artifacts.Add((Get-VerificationArtifact $PreparedRun $path))}
            $result.checks=@($checks.ToArray());$result.artifacts=@($artifacts.ToArray())
            $result.status='completed';$result.summary=$agent.summary
        }catch{$result.status='incomplete';$result.summary=$_.Exception.Message;$result.unverified+=@($_.Exception.Message)}
    }
    if(-not$ExecutionResult.processTreeStopped){$result.unverified+=@('process tree stop unverified')}
    $json=$result | ConvertTo-Json -Depth 25
    if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'result.schema.json') -ErrorAction SilentlyContinue)){throw 'result does not satisfy schema'}
    $stream=[IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($json);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    return $result
}
Export-ModuleMember -Function Complete-VerificationRun
