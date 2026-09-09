param([Parameter(Mandatory)][string]$StartedPath)
# 信頼する起動側がジョブへ登録してから標準入力を送る。それまで対象を起動しない。
$ErrorActionPreference='Stop'
try{
    $line=[Console]::In.ReadLine()
    if($null -eq $line){throw '起動要求なし'}
    $request=$line | ConvertFrom-Json
    $start=[Diagnostics.ProcessStartInfo]::new($request.file)
    $start.WorkingDirectory=$request.cwd;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($arg in $request.args){$start.ArgumentList.Add($arg)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$start
    try{
        [void]$process.Start()
        [IO.File]::WriteAllText($StartedPath,(@{pid=$process.Id;startTicks=$process.StartTime.ToUniversalTime().Ticks} | ConvertTo-Json -Compress))
        $out=$process.StandardOutput.BaseStream.CopyToAsync([Console]::OpenStandardOutput())
        $err=$process.StandardError.BaseStream.CopyToAsync([Console]::OpenStandardError())
        $process.WaitForExit()
        [IO.File]::WriteAllText(($StartedPath+'.exit.json'),(@{exitCode=$process.ExitCode} | ConvertTo-Json -Compress))
        [void]$out.GetAwaiter().GetResult();[void]$err.GetAwaiter().GetResult()
        $exitCode=$process.ExitCode
    }finally{$process.Dispose()}
    exit $exitCode
}catch{[Console]::Error.WriteLine($_.Exception.Message);exit 127}
