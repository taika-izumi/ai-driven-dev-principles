param([Parameter(Mandatory)][string]$CodexPath,[Parameter(Mandatory)][string]$PwshPath)
# 合成データの1バイト往復と公開example.comへのTCP接続だけを観測する。外部へ本文を送らない。
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$root=Join-Path $repo ('.tmp/network-risk/' + [guid]::NewGuid())
foreach($part in @('work','temp','control','source')){[void][IO.Directory]::CreateDirectory((Join-Path $root $part))}
[IO.File]::WriteAllText((Join-Path $root 'source/confidentiality-substitute.txt'),'synthetic-risk-marker')
Add-Type -TypeDefinition @'
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;
public sealed class RiskEcho : IDisposable {
  TcpListener listener; Task worker;
  public int Port { get; private set; }
  public RiskEcho() {
    listener=new TcpListener(IPAddress.Loopback,0);listener.Start();Port=((IPEndPoint)listener.LocalEndpoint).Port;
    worker=Task.Run(async () => {try {while(true) {using(var client=await listener.AcceptTcpClientAsync()) {var s=client.GetStream();s.ReadTimeout=4000;int b=s.ReadByte();if(b==41)s.WriteByte(42);}}}catch(SocketException){}catch(ObjectDisposedException){} });
  }
  public void Dispose(){listener.Stop();worker.Wait(5000);}
}
'@
$server=[RiskEcho]::new()
$evidence=[ordered]@{root=$root;port=$server.Port;before=$null;restricted=$null;after=$null}
try{
    $clientScript=Join-Path $PSScriptRoot 'fixtures/NetworkRiskClient.ps1'
    $before=& $PwshPath -NoProfile -File $clientScript -ProbeRoot $root -Port $server.Port
    if($LASTEXITCODE -ne 0){throw '正の対照の起動失敗'}
    $evidence.before=$before | ConvertFrom-Json
    $normalized=$root.Replace('\','/')
    $profile='permissions.inspection={extends=":read-only",filesystem={"'+$normalized+'/work"="write","'+$normalized+'/temp"="write"},network={enabled=false}}'
    $limited=& $PwshPath -NoProfile -File (Join-Path $PSScriptRoot 'fixtures/AppServerBoundary.ps1') -CodexPath $CodexPath -PwshPath $PwshPath -ProbeRoot $root -Permissions $profile -Port $server.Port -WindowsSandbox elevated -RiskOnly
    if($LASTEXITCODE -ne 0){throw '制限付きリスク試験の起動失敗'}
    $evidence.restricted=$limited | ConvertFrom-Json
    $after=& $PwshPath -NoProfile -File $clientScript -ProbeRoot $root -Port $server.Port
    if($LASTEXITCODE -ne 0){throw '後の正の対照の起動失敗'}
    $evidence.after=$after | ConvertFrom-Json
}finally{
    $server.Dispose()
    [IO.File]::WriteAllText((Join-Path $root 'control/network-risk.json'),($evidence | ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
    [Console]::WriteLine((Join-Path $root 'control/network-risk.json'))
}
