# 原本を変更せず、選択対象版を固定して独立Gitのコピーを準備する。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Throw-VerificationFailure([string]$Message,[string]$Status='blocked') {
    $ex=[InvalidOperationException]::new($Message);$ex.Data['status']=$Status;throw $ex
}
function Test-VerificationContainment([string]$Root,[string]$Path) {
    $r=[IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Root))
    $p=[IO.Path]::GetFullPath($Path)
    $p.Equals($r,[StringComparison]::OrdinalIgnoreCase) -or $p.StartsWith($r+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
function Resolve-VerificationPath([string]$Path) {
    if(-not[IO.Path]::IsPathFullyQualified($Path)){Throw-VerificationFailure 'absolute path required'}
    $resolved=[IO.Path]::GetFullPath($Path)
    $part=$resolved
    while($part){
        if(Test-Path -LiteralPath $part){
            $item=Get-Item -LiteralPath $part -Force
            if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){Throw-VerificationFailure "reparse point rejected: $part"}
        }
        $part=[IO.Path]::GetDirectoryName($part)
    }
    return $resolved
}
function Invoke-VerificationGit([string]$Root,[string[]]$Arguments) {
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Command git -ErrorAction Stop).Source)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.StandardOutputEncoding=[Text.UTF8Encoding]::new($false)
    # 親シェルのGit探索先を継承しない。対象Gitの設定・フックは書き換えない。
    foreach($key in @($start.Environment.Keys)){if($key -like 'GIT_*'){[void]$start.Environment.Remove($key)}}
    foreach($a in (@('-c',"safe.directory=$($Root.Replace('\','/'))",'-c','core.fsmonitor=false','-C',$Root)+$Arguments)){$start.ArgumentList.Add($a)}
    $p=[Diagnostics.Process]::new();$p.StartInfo=$start
    try{
        [void]$p.Start();$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
        if(-not$p.WaitForExit(30000)){$p.Kill($true);Throw-VerificationFailure 'git timed out'}
        @{exitCode=$p.ExitCode;stdout=$o.GetAwaiter().GetResult();stderr=$e.GetAwaiter().GetResult()}
    }finally{$p.Dispose()}
}
function Get-VerificationExclusion([string]$Relative,[string]$Full,[string]$RunsRoot) {
    if(Test-VerificationContainment $RunsRoot $Full){return 'run_output'}
    $first=($Relative.Replace('\','/').Split('/'))[0]
    if($first -eq '.git'){return 'git_metadata'}
    if($first -in @('.codex','.claude','.agents','.mcp.json')){return 'startup_config'}
    return $null
}
function Get-VerificationSourceManifest([hashtable]$Request,[hashtable]$Settings) {
    $root=Resolve-VerificationPath $Request.sourceRoot
    $runs=Resolve-VerificationPath $Settings.runsRoot
    $list=Invoke-VerificationGit $root @('ls-files','-z','--cached','--others','--exclude-standard')
    if($list.exitCode -ne 0){Throw-VerificationFailure ('git input enumeration failed: '+$list.stderr)}
    $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($name in $list.stdout.Split([char]0,[StringSplitOptions]::RemoveEmptyEntries)){[void]$names.Add($name.Replace('\','/'))}
    foreach($extra in $Request.extraInputPaths){
        if($extra -isnot [string] -or [string]::IsNullOrWhiteSpace($extra) -or [IO.Path]::IsPathRooted($extra) -or $extra.Contains(':') -or ($extra.Replace('\','/').Split('/') -contains '..')){Throw-VerificationFailure 'extra input must be a source-relative path'}
        $full=Resolve-VerificationPath (Join-Path $root $extra)
        if(-not(Test-VerificationContainment $root $full)){Throw-VerificationFailure 'extra input outside source'}
        if(-not(Test-Path -LiteralPath $full)){Throw-VerificationFailure 'extra input missing'}
        $pending=[Collections.Generic.Queue[string]]::new();$pending.Enqueue($full)
        while($pending.Count){
            $itemPath=Resolve-VerificationPath $pending.Dequeue()
            $relative=[IO.Path]::GetRelativePath($root,$itemPath).Replace('\','/')
            if(Get-VerificationExclusion $relative $itemPath $runs){[void]$names.Add($relative);continue}
            $item=Get-Item -LiteralPath $itemPath -Force
            if($item.PSIsContainer){foreach($child in [IO.Directory]::EnumerateFileSystemEntries($itemPath)){$pending.Enqueue($child)}}else{[void]$names.Add($relative)}
        }
    }
    $ordered=[string[]]@($names);[Array]::Sort($ordered,[StringComparer]::Ordinal)
    $files=[Collections.Generic.List[object]]::new();$excluded=[Collections.Generic.List[object]]::new()
    foreach($name in $ordered){
        if([IO.Path]::IsPathRooted($name) -or $name.Contains(':') -or ($name.Split('/') -contains '..')){Throw-VerificationFailure 'invalid enumerated path'}
        $full=[IO.Path]::GetFullPath((Join-Path $root $name))
        if(-not(Test-VerificationContainment $root $full)){Throw-VerificationFailure 'enumerated path outside source'}
        # 入力のリンクは除外規則より先に検出する。
        $null=Resolve-VerificationPath $full
        $reason=Get-VerificationExclusion $name $full $runs
        if($reason){$excluded.Add(@{path=$name;reason=$reason});continue}
        if([IO.Directory]::Exists($full)){Throw-VerificationFailure "directory input unsupported (including submodule): $name"}
        if([IO.File]::Exists($full)){
            $hash=(Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
            $files.Add(@{path=$name;size=(Get-Item -LiteralPath $full).Length;sha256=$hash;deleted=$false})
        }else{$files.Add(@{path=$name;size=0;sha256=$null;deleted=$true})}
    }
    $head=Invoke-VerificationGit $root @('rev-parse','--verify','HEAD')
    @{files=@($files.ToArray());head=$(if($head.exitCode -eq 0){$head.stdout.Trim()}else{$null});total=$files.Count;exclusions=@($excluded.ToArray())}
}
function Test-VerificationManifestEqual($Left,$Right) {
    if($Left.head -cne $Right.head -or $Left.files.Count -ne $Right.files.Count){return $false}
    for($i=0;$i -lt $Left.files.Count;$i++){
        foreach($key in @('path','size','sha256','deleted')){if($Left.files[$i][$key] -cne $Right.files[$i][$key]){return $false}}
    }
    return $true
}
function Copy-VerificationFile([string]$Source,[string]$Destination) {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Destination))
    [IO.File]::Copy($Source,$Destination,$false)
}
function New-VerificationRun([hashtable]$Request,[hashtable]$Settings) {
    $runRoot=$null
    try{
        foreach($key in $Request.Keys){if($key -notin @('schemaVersion','caller','sourceRoot','objective','acceptanceCriteria','extraInputPaths')){Throw-VerificationFailure "unknown request key: $key"}}
        $json=$Request | ConvertTo-Json -Depth 15
        if(-not(Test-Json -Json $json -SchemaFile (Join-Path $PSScriptRoot 'request.schema.json') -ErrorAction SilentlyContinue)){Throw-VerificationFailure 'invalid request schema'}
        if($Request.schemaVersion -is [string]){Throw-VerificationFailure 'schemaVersion must be integer'}
        foreach($key in $Settings.Keys){if($key -notin @('codexPath','pwshPath','runsRoot','model','timeoutSeconds')){Throw-VerificationFailure "unknown settings key: $key"}}
        foreach($key in @('codexPath','pwshPath','runsRoot','model','timeoutSeconds')){if(-not$Settings.ContainsKey($key)){Throw-VerificationFailure "missing settings key: $key"}}
        if($Settings.model -isnot [string] -or [string]::IsNullOrWhiteSpace($Settings.model)){Throw-VerificationFailure 'model required'}
        if($Settings.timeoutSeconds -isnot [int] -and $Settings.timeoutSeconds -isnot [long]){Throw-VerificationFailure 'timeoutSeconds must be integer'}
        if($Settings.timeoutSeconds -le 0){Throw-VerificationFailure 'positive timeout required'}
        foreach($key in @('codexPath','pwshPath')){if($Settings[$key] -isnot [string]){Throw-VerificationFailure 'executable path must be string'};$path=Resolve-VerificationPath $Settings[$key];if(-not[IO.File]::Exists($path)){Throw-VerificationFailure 'executable missing'}}
        $source=Resolve-VerificationPath $Request.sourceRoot
        $runs=Resolve-VerificationPath $Settings.runsRoot
        if(-not[IO.Directory]::Exists($source)){Throw-VerificationFailure 'source missing'}
        if(Test-VerificationContainment $runs $source){Throw-VerificationFailure 'runsRoot must not contain sourceRoot'}
        $top=Invoke-VerificationGit $source @('rev-parse','--show-toplevel')
        if($top.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($top.stdout.Trim()).Equals($source,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure 'sourceRoot must be Git worktree root'}
        $before=Get-VerificationSourceManifest $Request $Settings
        $runId=[guid]::NewGuid().ToString();$runRoot=Join-Path $runs $runId
        if(Test-Path -LiteralPath $runRoot){Throw-VerificationFailure 'run already exists'}
        [void][IO.Directory]::CreateDirectory($runs)
        New-Item -ItemType Directory -Path $runRoot -ErrorAction Stop | Out-Null
        foreach($part in @('work','temp','control','control/empty-template')){[void][IO.Directory]::CreateDirectory((Join-Path $runRoot $part))}
        $work=Join-Path $runRoot 'work';$control=Join-Path $runRoot 'control'
        foreach($file in $before.files){
            if($file.deleted){continue}
            $src=Resolve-VerificationPath (Join-Path $source $file.path)
            $dst=Join-Path $work $file.path
            try{Copy-VerificationFile $src $dst}catch{Throw-VerificationFailure "copy failed: $($file.path)" 'source_changed'}
            if((Get-FileHash -LiteralPath $dst).Hash -cne $file.sha256){Throw-VerificationFailure 'input changed during copy' 'source_changed'}
        }
        $after=Get-VerificationSourceManifest $Request $Settings
        if(-not(Test-VerificationManifestEqual $before $after)){Throw-VerificationFailure 'source changed during copy' 'source_changed'}
        $init=Invoke-VerificationGit $work @('init','--quiet',('--template='+(Join-Path $control 'empty-template')))
        if($init.exitCode -ne 0){Throw-VerificationFailure 'copy Git initialization failed'}
        foreach($check in @(@{args=@('rev-parse','--show-toplevel');expected=$work},@{args=@('rev-parse','--absolute-git-dir');expected=(Join-Path $work '.git')})){
            $actual=Invoke-VerificationGit $work $check.args
            if($actual.exitCode -ne 0 -or -not([IO.Path]::GetFullPath($actual.stdout.Trim()).Equals($check.expected,[StringComparison]::OrdinalIgnoreCase))){Throw-VerificationFailure 'copy Git points outside copy'}
        }
        $prepared=@{runId=$runId;sourceRoot=$source;runRoot=$runRoot;workRoot=$work;tempRoot=(Join-Path $runRoot 'temp');controlRoot=$control;request=$Request;settings=$Settings;sourceManifest=$before}
        [IO.File]::WriteAllText((Join-Path $control 'source-manifest.json'),($before | ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($false))
        return $prepared
    }catch{
        if(-not$_.Exception.Data.Contains('status')){$_.Exception.Data['status']='blocked'}
        if($runRoot){$_.Exception.Data['runRoot']=$runRoot}
        throw
    }
}
Export-ModuleMember -Function New-VerificationRun,Get-VerificationSourceManifest,Test-VerificationManifestEqual,Resolve-VerificationPath,Test-VerificationContainment
