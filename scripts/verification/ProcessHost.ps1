param([Parameter(Mandatory)][string]$StartedPath)
# 信頼する起動側がジョブへ登録してから標準入力を送る。それまで対象を起動しない。
# 制御要求は1行目のJSON。version=3 なら続く stdinBytesLength バイトを対象のstdinへ転送してEOFを渡す。版なしは従来（stdinを渡さない）。
# 制御要求の jobHandle は、起動側が本プロセスへ複製したジョブのハンドル値（割当と所属確認の権限だけを持つ・非継承）。
# 対象は起動直後にこのジョブへ明示的に割り当ててから開始マーカーを書く（Issue-0147）。MSIX 版 pwsh の子として起動した
# 非パッケージの実行ファイル（sbx.exe・cmd.exe・ping.exe 等）はジョブを継承しないことを実測したため、継承に頼らない。
$ErrorActionPreference='Stop'
try{
    # 割当の関数は対象の起動前に用意する（コンパイル時間で起動から割当までの間を広げない）。
    if(-not('VerificationHostJob' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;
public static class VerificationHostJob {
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool IsProcessInJob(IntPtr process,IntPtr job,out bool belongs);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool CloseHandle(IntPtr handle);
  // 割当に失敗した・所属を確認できない場合は例外にする（黙って続けない）。
  public static void Assign(long job,IntPtr process){
    if(!AssignProcessToJobObject(new IntPtr(job),process)){int e=Marshal.GetLastWin32Error();throw new Win32Exception(e,"job assignment failed (AssignProcessToJobObject, error "+e+")");}
    bool belongs;if(!IsProcessInJob(process,new IntPtr(job),out belongs)){int e=Marshal.GetLastWin32Error();throw new Win32Exception(e,"job assignment failed (IsProcessInJob, error "+e+")");}
    if(!belongs)throw new InvalidOperationException("job assignment failed (target not in job)");
  }
  // 割当が済んだら直ちに閉じる。ジョブ内の本プロセスがハンドルを持ち続けると、起動側の終了で KILL_ON_JOB_CLOSE が働かない。
  public static void Close(long job){CloseHandle(new IntPtr(job));}
}
'@
    }
    $stdin=[Console]::OpenStandardInput()
    # 1行目はLFまで1バイトずつ読む。StreamReader（[Console]::In）は先読みで後続の対象stdinバイト列を取り込んでしまうため使わない。
    # 復号は [Console]::In と同じ InputEncoding で行い、版なし要求の解釈を従来と一致させる（v3の制御行は起動側がASCIIに限定する）。
    $lineBytes=[Collections.Generic.List[byte]]::new();$byte=-1
    while($true){$byte=$stdin.ReadByte();if($byte -lt 0 -or $byte -eq 10){break};$lineBytes.Add([byte]$byte)}
    if($lineBytes.Count -eq 0){throw '起動要求なし'}
    $line=[Console]::InputEncoding.GetString($lineBytes.ToArray()).TrimEnd("`r")
    $request=$line | ConvertFrom-Json
    $version3=($null -ne $request.PSObject.Properties['version'] -and $request.version -eq 3)
    # ジョブハンドルの無い要求では対象を起動しない（ジョブ外で動く対象を作らない）。
    if($null -eq $request.PSObject.Properties['jobHandle'] -or -not(($request.jobHandle -is [int]) -or ($request.jobHandle -is [long])) -or $request.jobHandle -le 0){throw 'job handle required'}
    $jobHandle=[long]$request.jobHandle
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
        # 起動直後にジョブへ割り当てる。失敗したら対象を木ごと止めて失敗終了し、開始マーカーは書かない（起動側は started=false）。
        # 割当前に対象が作った子はジョブに入らない（残る競合。Process.Start は一時停止での起動を持たない）。割当後に作られる子は継承で入る。
        try{[VerificationHostJob]::Assign($jobHandle,$process.Handle)}
        catch{
            $reason=$_.Exception.Message
            try{$process.Kill($true);[void]$process.WaitForExit(5000)}catch{}
            throw $reason
        }
        [VerificationHostJob]::Close($jobHandle)   # 失敗時は閉じない（値が別種の有効ハンドルでありうるため。終了で OS が閉じる）
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
