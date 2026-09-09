param([Parameter(Mandatory)][string]$ProbeRoot,[Parameter(Mandatory)][int]$Port)
$ErrorActionPreference='Stop'
$result=@{userSid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value;loopback=@{connected=$false;roundTrip=$false;error=$null};external=@{host='example.com';port=443;connected=$false;payloadSent=$false;error=$null};outsideCopyRead=@{readable=$false;markerMatched=$false;error=$null}}
$client=[Net.Sockets.TcpClient]::new()
try {
    $task=$client.ConnectAsync('127.0.0.1',$Port)
    if(-not $task.Wait(4000)){throw '接続時間超過'}
    $result.loopback.connected=$client.Connected
    $stream=$client.GetStream();$stream.ReadTimeout=4000;$stream.WriteTimeout=4000
    $stream.WriteByte(41)
    $result.loopback.roundTrip=($stream.ReadByte() -eq 42)
}catch{$result.loopback.error=$_.Exception.Message}finally{$client.Dispose()}
$external=[Net.Sockets.TcpClient]::new()
try {
    $task=$external.ConnectAsync('example.com',443)
    if(-not $task.Wait(4000)){throw '外部接続時間超過'}
    $result.external.connected=$external.Connected
}catch{$result.external.error=$_.Exception.Message}finally{$external.Dispose()}
try {
    $marker=[IO.File]::ReadAllText((Join-Path $ProbeRoot 'source/confidentiality-substitute.txt'))
    $result.outsideCopyRead.readable=$true
    $result.outsideCopyRead.markerMatched=($marker -eq 'synthetic-risk-marker')
}catch{$result.outsideCopyRead.error=$_.Exception.Message}
$result | ConvertTo-Json -Depth 8 -Compress
