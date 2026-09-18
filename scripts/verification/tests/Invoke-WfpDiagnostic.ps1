#requires -Version 7.0
param(
    [string]$ProgramPath = (Get-Process -Id $PID).Path,
    [string]$UserSid = 'S-1-5-21-837458855-1857831939-3491563441-1003',
    [ValidateRange(1,65535)][int]$RemotePort = 50000
)
# 今回のWindows通信拒否の診断用。WFPのshowだけを実行し設定・監査を変更しない。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not [IO.Path]::IsPathFullyQualified($ProgramPath) -or -not [IO.File]::Exists($ProgramPath)) {
    throw 'ProgramPathには試験で使ったPowerShellの絶対パスを指定してください'
}
$null = [Security.Principal.SecurityIdentifier]::new($UserSid)
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$outputRoot = Join-Path $repoRoot ('.tmp/wfp-diagnostics/' + [guid]::NewGuid())
[void][IO.Directory]::CreateDirectory($outputRoot)
$filterPath = Join-Path $outputRoot 'loopback-filters.xml'
$report = [ordered]@{
    status='blocked'; recordedAt=(Get-Date -Format o); outputRoot=$outputRoot
    program=$ProgramPath; userSid=$UserSid; remoteAddress='127.0.0.1'; remotePort=$RemotePort
    elevated=$false; command=@(); exitCode=$null; output=@(); error=$null
}
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $report.elevated = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $report.elevated) { throw '管理者権限が必要です。管理者として開いたPowerShell 7で実行してください。' }
    $netsh = Join-Path $env:SystemRoot 'System32/netsh.exe'
    $arguments = @('wfp','show','filters',"file=$filterPath",'protocol=6','remoteaddr=127.0.0.1',"remoteport=$RemotePort","appid=$ProgramPath","userid=$UserSid",'dir=OUT','verbose=ON')
    $report.command = @($netsh) + $arguments
    $report.output = @(& $netsh @arguments 2>&1 | ForEach-Object { "$_" })
    $report.exitCode = $LASTEXITCODE
    if ($LASTEXITCODE -ne 0 -or -not [IO.File]::Exists($filterPath)) {
        throw 'WFPの一覧を取得できませんでした。diagnostic.jsonの実出力を確認してください。'
    }
    if ((Get-Item -LiteralPath $filterPath).Length -eq 0) { throw 'WFPの出力が空です' }
    # 既存のイベントだけを読む。neteventsの有効化やcapture開始はしない。
    $optionsOutput = @(& $netsh wfp show options optionsfor=NETEVENTS 2>&1 | ForEach-Object { "$_" })
    [IO.File]::WriteAllLines((Join-Path $outputRoot 'netevents-options.txt'),$optionsOutput)
    $eventPath = Join-Path $outputRoot 'existing-netevents.xml'
    $eventOutput = @(& $netsh wfp show netevents "file=$eventPath" protocol=6 remoteaddr=127.0.0.1 "remoteport=$RemotePort" "appid=$ProgramPath" "userid=$UserSid" 2>&1 | ForEach-Object { "$_" })
    [IO.File]::WriteAllLines((Join-Path $outputRoot 'netevents-command.txt'),$eventOutput)
    $report.status = 'collected'
} catch { $report.error = $_.Exception.Message }
$reportPath = Join-Path $outputRoot 'diagnostic.json'
[IO.File]::WriteAllText($reportPath,($report | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
[Console]::Out.WriteLine($reportPath)
if ($report.error) { [Console]::Error.WriteLine($report.error) }
if ($report.status -ne 'collected') { exit 2 }
