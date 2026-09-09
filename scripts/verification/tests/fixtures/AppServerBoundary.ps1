param(
    [Parameter(Mandatory)][string]$CodexPath,
    [Parameter(Mandatory)][string]$PwshPath,
    [Parameter(Mandatory)][string]$ProbeRoot,
    [Parameter(Mandatory)][string]$Permissions,
    [Parameter(Mandatory)][int]$Port,
    [ValidateSet('elevated','unelevated')][string]$WindowsSandbox='elevated',
    [switch]$IdentityOnly
)
# 調査専用。スレッド・モデルを作らず、実機生成スキーマのcommand/execを比較する。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$start = [Diagnostics.ProcessStartInfo]::new($CodexPath)
$start.WorkingDirectory = Join-Path $ProbeRoot 'work'
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
foreach ($arg in @('app-server','--stdio','-c',$Permissions,'-c','default_permissions="inspection"','-c',('windows.sandbox="' + $WindowsSandbox + '"'),'-c','approval_policy="never"','-c','analytics.enabled=false')) {
    $start.ArgumentList.Add($arg)
}
$process = [Diagnostics.Process]::new()
$process.StartInfo = $start
$events = [Collections.Generic.List[string]]::new()
$started = $false
$stderrTask = $null
function Send-Rpc($Value) {
    $process.StandardInput.WriteLine(($Value | ConvertTo-Json -Depth 12 -Compress))
    $process.StandardInput.Flush()
}
function Receive-Rpc([int]$ExpectedId) {
    $clock = [Diagnostics.Stopwatch]::StartNew()
    while ($clock.Elapsed.TotalSeconds -lt 40) {
        $lineTask = $process.StandardOutput.ReadLineAsync()
        if (-not $lineTask.Wait(40000 - [int]$clock.ElapsedMilliseconds)) { throw 'API応答の時間超過' }
        $line = $lineTask.GetAwaiter().GetResult()
        if ($null -eq $line) { throw 'APIの標準出力が終了' }
        $events.Add($line)
        $message = $line | ConvertFrom-Json -AsHashtable
        if ($message.ContainsKey('id') -and $message.id -eq $ExpectedId) {
            if ($message.ContainsKey('error')) { throw ($message.error | ConvertTo-Json -Compress) }
            return $message.result
        }
        if ($message.ContainsKey('id') -and $message.ContainsKey('method')) {
            throw ('予定外のサーバー要求: ' + $message.method)
        }
    }
    throw 'API応答の時間超過'
}
try {
    [void]$process.Start()
    $started = $true
    $stderrTask = $process.StandardError.ReadToEndAsync()
    Send-Rpc @{id=1; method='initialize'; params=@{clientInfo=@{name='verification-probe';version='0.1'};capabilities=@{experimentalApi=$true}}}
    $null = Receive-Rpc 1
    Send-Rpc @{method='initialized';params=@{}}
    $request = @{id=2;method='command/exec';params=@{
        command=@($PwshPath,'-NoProfile','-NonInteractive','-File',(Join-Path $ProbeRoot 'control/BoundaryProbe.ps1'),'-ProbeRoot',$ProbeRoot,'-Port',"$Port")
        cwd=(Join-Path $ProbeRoot 'work');permissionProfile='inspection';timeoutMs=30000
        env=@{TEMP=(Join-Path $ProbeRoot 'temp');TMP=(Join-Path $ProbeRoot 'temp')}
    }}
    if ($IdentityOnly) { $request.params.command = @((Get-Command whoami.exe).Source, '/user') }
    [IO.File]::WriteAllText((Join-Path $ProbeRoot 'control/app-server-request.json'), ($request | ConvertTo-Json -Depth 12))
    Send-Rpc $request
    $response = Receive-Rpc 2
    [Console]::Out.Write($response.stdout)
    [Console]::Error.Write($response.stderr)
    $commandExit = $response.exitCode
} finally {
    if ($started -and -not $process.HasExited) {
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(5000)) { $process.Kill($true); [void]$process.WaitForExit(5000) }
    }
    [IO.File]::WriteAllLines((Join-Path $ProbeRoot 'control/app-server-events.jsonl'), $events, [Text.UTF8Encoding]::new($false))
    if ($null -ne $stderrTask -and $stderrTask.IsCompleted) {
        [IO.File]::WriteAllText((Join-Path $ProbeRoot 'control/app-server-stderr.txt'),$stderrTask.GetAwaiter().GetResult())
    }
    $process.Dispose()
}
exit $commandExit
