param(
    [Parameter(Mandatory)][string]$ProbeRoot,
    [Parameter(Mandatory)][int]$Port,
    [switch]$AllowOnly,
    [switch]$Child,
    [switch]$PauseForWfp
)
# 新規試験領域の代用品だけに書き込む。許可失敗と拒否成功を混同しない。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$suffix = if ($Child) { 'child' } else { 'parent' }
function Test-ProbeWrite([string]$RelativePath) {
    $path = Join-Path $ProbeRoot $RelativePath
    try {
        [IO.File]::WriteAllText($path, 'probe', [Text.UTF8Encoding]::new($false))
        @{path=$RelativePath; write='allowed'; error=$null}
    } catch {
        @{path=$RelativePath; write='denied'; error=$_.Exception.GetType().FullName}
    }
}
$writes = @(
    Test-ProbeWrite "work/$suffix.txt"
    Test-ProbeWrite "temp/$suffix.txt"
)
$link = @{created=$false; error=$null; write=$null}
if (-not $AllowOnly) {
    foreach ($relative in @('control/sentinel.txt','source/sentinel.txt','shared/sentinel.txt','records/sentinel.txt','work/.git/sentinel.txt')) {
        $writes += Test-ProbeWrite $relative
    }
    $linkPath = Join-Path $ProbeRoot "work/link-$suffix"
    try {
        New-Item -ItemType Junction -Path $linkPath -Target (Join-Path $ProbeRoot 'source') -ErrorAction Stop | Out-Null
        $link.created = $true
        $link.write = Test-ProbeWrite "work/link-$suffix/sentinel.txt"
    } catch { $link.error = $_.Exception.GetType().FullName }
}
if ($PauseForWfp) {
    $ready = Join-Path $ProbeRoot "work/wfp-ready-$suffix.json"
    [IO.File]::WriteAllText($ready, (@{pid=$PID;sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value;port=$Port} | ConvertTo-Json -Compress))
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    while (-not [IO.File]::Exists((Join-Path $ProbeRoot "work/wfp-release-$suffix"))) {
        if ([DateTime]::UtcNow -gt $deadline) { throw 'WFP採取待ちが時間超過' }
        Start-Sleep -Milliseconds 100
    }
}
$client = [Net.Sockets.TcpClient]::new()
$network = @{connected=$false; error=$null}
try {
    $connect = $client.ConnectAsync('127.0.0.1', $Port)
    if (-not $connect.Wait(3000)) { throw 'connection timeout' }
    $network.connected = $client.Connected
} catch { $network.error = $_.Exception.Message }
finally { $client.Dispose() }
$result = @{process=$suffix; writes=$writes; link=$link; network=$network; child=$null; userSid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value}
if (-not $Child) {
    $start = [Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($arg in @('-NoProfile','-NonInteractive','-File',$PSCommandPath,'-ProbeRoot',$ProbeRoot,'-Port',"$Port",'-Child')) {
        $start.ArgumentList.Add($arg)
    }
    if ($AllowOnly) { $start.ArgumentList.Add('-AllowOnly') }
    if ($PauseForWfp) { $start.ArgumentList.Add('-PauseForWfp') }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        [void]$process.Start()
        $out = $process.StandardOutput.ReadToEndAsync()
        $err = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(15000)) { $process.Kill($true); throw '子試験が時間超過' }
        $result.child = @{exitCode=$process.ExitCode; stdout=$out.GetAwaiter().GetResult(); stderr=$err.GetAwaiter().GetResult()}
    } finally { $process.Dispose() }
}
$result | ConvertTo-Json -Depth 12 -Compress
