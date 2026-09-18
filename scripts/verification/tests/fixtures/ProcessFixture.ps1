param([ValidateSet('ok','fail','output','child','orphan','arguments')][string]$Mode,[string]$PidPath,[string]$Payload)
if($Mode -eq 'arguments'){@{payload=$Payload;cwd=(Get-Location).Path;temp=$env:TEMP} | ConvertTo-Json -Compress;exit 0}
if($Mode -eq 'ok'){[Console]::Out.WriteLine('fixture-ok');exit 0}
if($Mode -eq 'fail'){[Console]::Error.WriteLine('fixture failure');exit 7}
if($Mode -eq 'output'){for($i=0;$i -lt 4096;$i++){[Console]::Out.WriteLine(('o'*256));[Console]::Error.WriteLine(('e'*256))};exit 0}
if($Mode -in @('child','orphan')){
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Process -Id $PID).Path)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    foreach($a in @('-NoProfile','-Command','Start-Sleep -Seconds 120')){$start.ArgumentList.Add($a)}
    $child=[Diagnostics.Process]::Start($start)
    [IO.File]::WriteAllText($PidPath,(@{pid=$child.Id;startTicks=$child.StartTime.ToUniversalTime().Ticks;path=$child.MainModule.FileName} | ConvertTo-Json))
    if($Mode -eq 'orphan'){exit 0}
    Start-Sleep -Seconds 120
}
