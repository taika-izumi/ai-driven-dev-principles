param([Parameter(Mandatory)][string]$StartedPath)
# 信頼する起動側がジョブへ登録してから標準入力を送る。それまで対象を起動しない。
# 制御要求は1行目のJSON。version=3 なら続く stdinBytesLength バイトを対象のstdinへ転送してEOFを渡す。版なしは従来（stdinを渡さない）。
$ErrorActionPreference='Stop'
try{
    $stdin=[Console]::OpenStandardInput()
    # 1行目はLFまで1バイトずつ読む。StreamReader（[Console]::In）は先読みで後続の対象stdinバイト列を取り込んでしまうため使わない。
    # 復号は [Console]::In と同じ InputEncoding で行い、版なし要求の解釈を従来と一致させる（v3の制御行は起動側がASCIIに限定する）。
    $lineBytes=[Collections.Generic.List[byte]]::new();$byte=-1
    while($true){$byte=$stdin.ReadByte();if($byte -lt 0 -or $byte -eq 10){break};$lineBytes.Add([byte]$byte)}
    if($lineBytes.Count -eq 0){throw '起動要求なし'}
    $line=[Console]::InputEncoding.GetString($lineBytes.ToArray()).TrimEnd("`r")
    $request=$line | ConvertFrom-Json
    $version3=($null -ne $request.PSObject.Properties['version'] -and $request.version -eq 3)
    $stdinBytes=[byte[]]::new(0)
    if($version3){
        # 対象stdinの全バイトを先に受け取る（上限は起動側の転送容量）。制御JSONは対象へ渡さない。
        $length=[int]$request.stdinBytesLength;$stdinBytes=[byte[]]::new($length);$read=0
        while($read -lt $length){$n=$stdin.Read($stdinBytes,$read,$length-$read);if($n -le 0){throw '対象stdinのバイト列が不足'};$read+=$n}
    }
    $start=[Diagnostics.ProcessStartInfo]::new($request.file)
    $start.WorkingDirectory=$request.cwd;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true;$start.RedirectStandardInput=$version3
    foreach($arg in $request.args){$start.ArgumentList.Add($arg)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$start
    try{
        [void]$process.Start()
        [IO.File]::WriteAllText($StartedPath,(@{pid=$process.Id;startTicks=$process.StartTime.ToUniversalTime().Ticks} | ConvertTo-Json -Compress))
        $out=$process.StandardOutput.BaseStream.CopyToAsync([Console]::OpenStandardOutput())
        $err=$process.StandardError.BaseStream.CopyToAsync([Console]::OpenStandardError())
        if($version3){
            # 転送は非同期にし、対象がstdinを読まずに終了しても待ち続けない。書き終えた時点でEOF（Close）を渡す。
            $targetStdin=$process.StandardInput.BaseStream
            $write=$targetStdin.WriteAsync($stdinBytes,0,$stdinBytes.Length);$closed=$false
            while(-not$process.HasExited){
                if(-not$closed -and $write.IsCompleted){try{$targetStdin.Close()}catch{};$closed=$true}
                [void]$process.WaitForExit(25)
            }
            if(-not$closed){try{[void]$write.Wait(1000)}catch{};try{$targetStdin.Close()}catch{}}
        }else{$process.WaitForExit()}
        [IO.File]::WriteAllText(($StartedPath+'.exit.json'),(@{exitCode=$process.ExitCode} | ConvertTo-Json -Compress))
        [void]$out.GetAwaiter().GetResult();[void]$err.GetAwaiter().GetResult()
        $exitCode=$process.ExitCode
    }finally{$process.Dispose()}
    exit $exitCode
}catch{[Console]::Error.WriteLine($_.Exception.Message);exit 127}
