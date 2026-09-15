# AIを呼ばないプロセス管理部分。権限制限付きCodexの起動設定は未確定のため含めない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not('VerificationJob' -as [type])){
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;
public sealed class VerificationJob : IDisposable {
  [StructLayout(LayoutKind.Sequential)] struct Basic { public long ProcessTime,JobTime;public uint Flags;public UIntPtr MinWS,MaxWS;public uint Limit;public UIntPtr Affinity;public uint Priority,Scheduling; }
  [StructLayout(LayoutKind.Sequential)] struct IO { public ulong R,W,O,RB,WB,OB; }
  [StructLayout(LayoutKind.Sequential)] struct Extended {public Basic Basic;public IO IO;public UIntPtr ProcessMemory,JobMemory,PeakProcess,PeakJob;}
  [StructLayout(LayoutKind.Sequential)] struct Accounting {public long User,Kernel,PeriodUser,PeriodKernel;public uint Faults,Total,Active,Terminated;}
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr security,string name);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job,int kind,IntPtr data,uint length);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool QueryInformationJobObject(IntPtr job,int kind,out Accounting data,uint length,IntPtr returned);
  [DllImport("kernel32.dll",EntryPoint="QueryInformationJobObject",SetLastError=true)] static extern bool QueryJobList(IntPtr job,int kind,IntPtr data,uint length,IntPtr returned);
  [DllImport("kernel32.dll",SetLastError=true)] static extern IntPtr OpenProcess(uint rights,bool inherit,uint pid);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool IsProcessInJob(IntPtr process,IntPtr job,out bool belongs);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateProcess(IntPtr process,uint code);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetExitCodeProcess(IntPtr process,out uint code);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job,IntPtr process);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool TerminateJobObject(IntPtr job,uint code);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
  [DllImport("kernel32.dll",SetLastError=true)] static extern bool DuplicateHandle(IntPtr sourceProcess,IntPtr source,IntPtr targetProcess,out IntPtr target,uint access,bool inherit,uint options);
  [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
  IntPtr job;
  public VerificationJob(){
    job=CreateJobObject(IntPtr.Zero,null);if(job==IntPtr.Zero)throw new Win32Exception();
    var info=new Extended();info.Basic.Flags=0x2000;
    int size=Marshal.SizeOf<Extended>();IntPtr buffer=Marshal.AllocHGlobal(size);
    try{Marshal.StructureToPtr(info,buffer,false);if(!SetInformationJobObject(job,9,buffer,(uint)size))throw new Win32Exception();}
    catch{Dispose();throw;}finally{Marshal.FreeHGlobal(buffer);}
  }
  public void Assign(IntPtr process){if(!AssignProcessToJobObject(job,process))throw new Win32Exception();}
  // ProcessHost が対象を明示的にこのジョブへ割り当てられるよう、ホストのプロセスへハンドルを複製して値を返す（Issue-0147）。
  // 権限は割当（JOB_OBJECT_ASSIGN_PROCESS）と所属確認（JOB_OBJECT_QUERY）だけ、非継承（対象へ渡らない）。ホストは割当後に閉じる。
  public long GrantAssign(IntPtr hostProcess){
    IntPtr copy;if(!DuplicateHandle(GetCurrentProcess(),job,hostProcess,out copy,0x0001|0x0004,false,0))throw new Win32Exception();
    return copy.ToInt64();
  }
  public uint Active(){Accounting a;if(!QueryInformationJobObject(job,1,out a,(uint)Marshal.SizeOf<Accounting>(),IntPtr.Zero))throw new Win32Exception();return a.Active;}
  public void Stop(){if(!TerminateJobObject(job,124))throw new Win32Exception();}
  public void StopExcept(int keepPid){
    // 収集役は残してパイプを最後まで読む。PID再利用時はジョブ所属を再確認する。
    uint count=Active();int size=checked(8+IntPtr.Size*((int)count+64));
    IntPtr buffer=Marshal.AllocHGlobal(size);
    try {
      if(!QueryJobList(job,3,buffer,(uint)size,IntPtr.Zero))throw new Win32Exception();
      int length=Marshal.ReadInt32(buffer,4);
      for(int i=0;i<length;i++){
        uint pid=checked((uint)Marshal.ReadIntPtr(buffer,8+i*IntPtr.Size).ToInt64());
        if(pid==(uint)keepPid)continue;
        IntPtr process=OpenProcess(0x1001,false,pid);if(process==IntPtr.Zero)continue;
        try{
          bool belongs;if(!IsProcessInJob(process,job,out belongs))throw new Win32Exception(Marshal.GetLastWin32Error(),"IsProcessInJob");
          if(belongs&&!TerminateProcess(process,124)){
            int error=Marshal.GetLastWin32Error();uint code;
            // 列挙と停止の間で既に終了したプロセスを、停止失敗と取り違えない。
            if(!GetExitCodeProcess(process,out code)||code==259)throw new Win32Exception(error,"TerminateProcess");
          }
        }
        finally{CloseHandle(process);}
      }
    }finally{Marshal.FreeHGlobal(buffer);}
  }
  public void Dispose(){if(job!=IntPtr.Zero){CloseHandle(job);job=IntPtr.Zero;}}
}
'@
}
function Invoke-VerificationProcess {
    param([Diagnostics.ProcessStartInfo]$StartInfo,[string]$EventsPath,[string]$ErrorPath,[int]$TimeoutSeconds)
    if($TimeoutSeconds -le 0 -or $StartInfo.UseShellExecute -or $StartInfo.Arguments){throw 'explicit argv, no shell, positive timeout required'}
    foreach($path in @($EventsPath,$ErrorPath)){if(-not[IO.Path]::IsPathFullyQualified($path) -or (Test-Path -LiteralPath $path)){throw 'new absolute output paths required'}}
    $marker=$EventsPath+'.started.json'
    if((Test-Path -LiteralPath $marker) -or (Test-Path -LiteralPath ($marker+'.exit.json'))){throw 'existing process marker rejected'}
    $result=@{started=$false;exitCode=$null;timedOut=$false;processTreeStopped=$false}
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh -ErrorAction Stop).Source)
    $start.WorkingDirectory=$StartInfo.WorkingDirectory
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.Environment.Clear();foreach($key in $StartInfo.Environment.Keys){$start.Environment[$key]=$StartInfo.Environment[$key]}
    foreach($a in @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'ProcessHost.ps1'),'-StartedPath',$marker)){$start.ArgumentList.Add($a)}
    $job=[VerificationJob]::new();$process=[Diagnostics.Process]::new();$process.StartInfo=$start
    $hostStarted=$false;$outFile=$null;$errFile=$null;$outTask=$null;$errTask=$null
    try{
        $outFile=[IO.File]::Open($EventsPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $errFile=[IO.File]::Open($ErrorPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        [void]$process.Start();$hostStarted=$true
        $job.Assign($process.Handle)
        $outTask=$process.StandardOutput.BaseStream.CopyToAsync($outFile)
        $errTask=$process.StandardError.BaseStream.CopyToAsync($errFile)
        # jobHandle: ホストが対象を明示的にジョブへ割り当てるためのハンドル値（Issue-0147。非パッケージの対象はジョブを継承しない）。
        $request=@{file=$StartInfo.FileName;cwd=$StartInfo.WorkingDirectory;args=@($StartInfo.ArgumentList);jobHandle=$job.GrantAssign($process.Handle)}
        $process.StandardInput.WriteLine(($request | ConvertTo-Json -Depth 8 -Compress));$process.StandardInput.Close()
        $timer=[Diagnostics.Stopwatch]::StartNew();$targetExit=$null
        while(-not$process.HasExited -and $timer.Elapsed.TotalSeconds -lt $TimeoutSeconds){
            if([IO.File]::Exists($marker+'.exit.json')){try{$targetExit=[IO.File]::ReadAllText($marker+'.exit.json') | ConvertFrom-Json -ErrorAction Stop;break}catch{}}
            [void]$process.WaitForExit(25)
        }
        if($null -ne $targetExit){
            $result.exitCode=$targetExit.exitCode
            $drainDeadline=[DateTime]::UtcNow.AddSeconds(5)
            while(-not$process.HasExited -and [DateTime]::UtcNow -lt $drainDeadline){
                if($job.Active() -gt 1){$job.StopExcept($process.Id)}
                [void]$process.WaitForExit(25)
            }
            if(-not$process.HasExited){$result.timedOut=$true;$job.Stop();[void]$process.WaitForExit(5000)}
        }
        elseif($process.HasExited){$result.exitCode=$process.ExitCode}
        else{$result.timedOut=$true;$job.Stop();[void]$process.WaitForExit(5000);if($process.HasExited){$result.exitCode=$process.ExitCode}}
        # 親が正常終了しても残った子はジョブ単位で停止する。
        if($job.Active() -gt 0){$job.Stop()}
        $deadline=[DateTime]::UtcNow.AddSeconds(5)
        while($job.Active() -gt 0 -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 25}
        $result.processTreeStopped=($job.Active() -eq 0)
        $result.started=[IO.File]::Exists($marker)
        if(-not$result.started){$result.exitCode=$null}
    }catch{
        if($hostStarted -and -not$process.HasExited){$process.Kill($true);[void]$process.WaitForExit(5000)}
        $result.started=[IO.File]::Exists($marker)
        $result.processTreeStopped=($job.Active() -eq 0)
        if($errFile){$bytes=[Text.Encoding]::UTF8.GetBytes($_.Exception.Message);$errFile.Write($bytes,0,$bytes.Length)}
    }finally{
        $job.Dispose()
        foreach($task in @($outTask,$errTask)){if($null -ne $task){if(-not$task.Wait(5000)){$result.processTreeStopped=$false}}}
        if($outFile){$outFile.Dispose()};if($errFile){$errFile.Dispose()};$process.Dispose()
    }
    return $result
}
# ---- v3: 対象stdinへのバイト転送・合算出力上限・RunBudget（残時間）・背景起動。v1の Invoke-VerificationProcess は変更しない。 ----
Import-Module (Join-Path $PSScriptRoot 'RequestCopy.psm1')   # Get-VerificationUtcNow（ISO 8601 UTC）を共用する
$script:BackgroundProcesses=@{}   # jobToken -> 背景起動の保持情報。ジョブ（VerificationJob）を保持し、Stop で Dispose する。
$script:BackgroundStartSeconds=30   # 背景起動の開始マーカー待ちの上限（固定。期限や CLI 入力・子からは変えない）
function Get-VerificationBudgetTime([hashtable]$Budget,[string]$Key,[bool]$Required) {
    if(-not$Budget.ContainsKey($Key) -or $null -eq $Budget[$Key]){if($Required){throw "RunBudget.$Key required"};return $null}
    $value=$Budget[$Key]
    if($value -isnot [string] -or $value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?Z$'){throw "RunBudget.$Key must be ISO 8601 UTC"}
    [DateTimeOffset]::Parse($value,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
}
function Get-VerificationRemainingSeconds([hashtable]$RunBudget) {
    # 相ごとの期限と当該コマンドの上限の小さい方。期限到達後は 0 以下を返し、呼出し側が新規起動を拒否する。
    if($null -eq $RunBudget){throw 'RunBudget required'}
    foreach($key in @('phase','limits')){if(-not$RunBudget.ContainsKey($key) -or $null -eq $RunBudget[$key]){throw "RunBudget.$key required"}}
    $limits=$RunBudget.limits
    foreach($key in @('maxOutputBytes','commandSeconds')){
        if(-not$limits.ContainsKey($key) -or -not(($limits[$key] -is [int]) -or ($limits[$key] -is [long])) -or $limits[$key] -le 0){throw "RunBudget.limits.$key must be a positive integer"}
    }
    $deadline=switch($RunBudget.phase){
        'work'{[void](Get-VerificationBudgetTime $RunBudget 'cleanupDeadlineAt' $false);Get-VerificationBudgetTime $RunBudget 'deadlineAt' $true}
        'cleanup'{Get-VerificationBudgetTime $RunBudget 'cleanupDeadlineAt' $true}
        default{throw 'RunBudget.phase must be work or cleanup'}
    }
    [Math]::Min([double]$limits.commandSeconds,($deadline-[DateTime]::UtcNow).TotalSeconds)
}
function Test-VerificationProcessInput([Diagnostics.ProcessStartInfo]$StartInfo,[hashtable]$OutputPaths) {
    if($null -eq $StartInfo -or $StartInfo.UseShellExecute -or $StartInfo.Arguments){throw 'explicit argv, no shell required'}
    if($null -eq $OutputPaths){throw 'OutputPaths required'}
    foreach($key in @('stdoutPath','stderrPath')){
        if(-not$OutputPaths.ContainsKey($key) -or $OutputPaths[$key] -isnot [string]){throw "OutputPaths.$key required"}
        $path=$OutputPaths[$key]
        if(-not[IO.Path]::IsPathFullyQualified($path) -or (Test-Path -LiteralPath $path)){throw 'new absolute output paths required'}
    }
    if($OutputPaths.stdoutPath -eq $OutputPaths.stderrPath){throw 'stdout and stderr paths must differ'}
    $marker=$OutputPaths.stdoutPath+'.started.json'
    if((Test-Path -LiteralPath $marker) -or (Test-Path -LiteralPath ($marker+'.exit.json'))){throw 'existing process marker rejected'}
    $marker
}
function New-VerificationHostProcess([Diagnostics.ProcessStartInfo]$StartInfo,[string]$Marker) {
    # ProcessHost.ps1 を起動側の環境辞書だけで起動する。制御要求の送信は呼出し側が行う。
    $start=[Diagnostics.ProcessStartInfo]::new((Get-Command pwsh -ErrorAction Stop).Source)
    $start.WorkingDirectory=$StartInfo.WorkingDirectory
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    $start.Environment.Clear();foreach($key in $StartInfo.Environment.Keys){$start.Environment[$key]=$StartInfo.Environment[$key]}
    foreach($a in @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'ProcessHost.ps1'),'-StartedPath',$Marker)){$start.ArgumentList.Add($a)}
    $process=[Diagnostics.Process]::new();$process.StartInfo=$start
    $process
}
function Get-VerificationControlBytes([Diagnostics.ProcessStartInfo]$StartInfo,[byte[]]$StdinBytes,[long]$JobHandle) {
    # 制御行（version=3）はASCIIに限定し（非ASCIIはエスケープ）、ホスト側の復号エンコーディングに依存しない。制御行の直後に対象stdinのバイト列を続ける。
    # JobHandle はホストへ複製したジョブのハンドル値（VerificationJob.GrantAssign）。ホストは対象を起動直後にこのジョブへ明示的に割り当てる（Issue-0147）。
    $request=@{version=3;file=$StartInfo.FileName;cwd=$StartInfo.WorkingDirectory;args=@($StartInfo.ArgumentList);stdinBytesLength=$StdinBytes.Length;jobHandle=$JobHandle}
    $line=[Text.Encoding]::ASCII.GetBytes(($request | ConvertTo-Json -Depth 8 -Compress -EscapeHandling EscapeNonAscii)+"`n")
    $bytes=[byte[]]::new($line.Length+$StdinBytes.Length)
    [Buffer]::BlockCopy($line,0,$bytes,0,$line.Length);[Buffer]::BlockCopy($StdinBytes,0,$bytes,$line.Length,$StdinBytes.Length)
    ,$bytes
}
function Read-VerificationTargetExit([string]$Marker,[double]$RetrySeconds=0) {
    # ホストの WriteAllText と競合した読取り（共有違反・空・不完全 JSON）は失敗として null を返す。
    # RetrySeconds を与えると、ファイルが在るのに読めない間だけその秒数まで読み直す（一度きりの読取りで取りこぼさない）。
    $path=$Marker+'.exit.json';$until=[DateTime]::UtcNow.AddSeconds($RetrySeconds)
    while($true){
        if(-not[IO.File]::Exists($path)){return $null}
        try{return ([IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop).exitCode}catch{}
        if([DateTime]::UtcNow -ge $until){return $null}
        Start-Sleep -Milliseconds 25
    }
}
function Read-VerificationStartMarker([string]$Marker) {
    # 開始マーカー（@{pid;startTicks}）を読む。未作成・書込み中（共有違反・空・不完全 JSON）は null を返し、呼出し側が開始待ち上限まで読み直す。
    if(-not[IO.File]::Exists($Marker)){return $null}
    try{
        $info=[IO.File]::ReadAllText($Marker) | ConvertFrom-Json -ErrorAction Stop
        if($null -eq $info -or $null -eq $info.PSObject.Properties['pid'] -or $null -eq $info.PSObject.Properties['startTicks']){return $null}
        return @{pid=[int]$info.pid;startTicks=[long]$info.startTicks}
    }catch{return $null}
}
function Invoke-VerificationProcessV3 {
    param([Diagnostics.ProcessStartInfo]$StartInfo,[byte[]]$StdinBytes,[hashtable]$OutputPaths,[hashtable]$RunBudget)
    if($null -eq $StdinBytes){$StdinBytes=[byte[]]::new(0)}
    $marker=Test-VerificationProcessInput $StartInfo $OutputPaths
    $remaining=Get-VerificationRemainingSeconds $RunBudget
    $result=@{started=$false;exitCode=$null;timedOut=$false;outputExceeded=$false;processTreeStopped=$false;stdoutBytes=0L;stderrBytes=0L;stdoutHash=$null;stderrHash=$null;finishedAt=$null;refusedReason=$null}
    if($remaining -le 0){$result.refusedReason='deadline-reached';$result.finishedAt=Get-VerificationUtcNow;return $result}
    $maxOutput=[long]$RunBudget.limits.maxOutputBytes
    $job=[VerificationJob]::new();$process=New-VerificationHostProcess $StartInfo $marker
    $hostStarted=$false;$outFile=$null;$errFile=$null;$stdinTask=$null;$pumps=@()
    try{
        $outFile=[IO.File]::Open($OutputPaths.stdoutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $errFile=[IO.File]::Open($OutputPaths.stderrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        [void]$process.Start();$hostStarted=$true
        $job.Assign($process.Handle)
        # 出力は容量監視つきで自分で汲み出す（無制限 CopyToAsync を上限付きとは扱わない）。
        $pumps=@(@{stream=$process.StandardOutput.BaseStream;file=$outFile;key='stdoutBytes';buffer=[byte[]]::new(65536);task=$null;eof=$false},
                 @{stream=$process.StandardError.BaseStream;file=$errFile;key='stderrBytes';buffer=[byte[]]::new(65536);task=$null;eof=$false})
        foreach($pump in $pumps){$pump.task=$pump.stream.ReadAsync($pump.buffer,0,$pump.buffer.Length)}
        # stdinの送信も非同期にする（ホストが読まずに終了すると書込みは失敗するが、その失敗で起動側を止めない）。
        $control=Get-VerificationControlBytes $StartInfo $StdinBytes ($job.GrantAssign($process.Handle))
        $stdinTask=$process.StandardInput.BaseStream.WriteAsync($control,0,$control.Length)
        $exitTask=$process.WaitForExitAsync()
        $deadlineUtc=[DateTime]::UtcNow.AddSeconds($remaining);$total=0L;$targetExit=$null;$drainDeadline=$null
        while($true){
            $pumped=$false
            foreach($pump in $pumps){
                if($pump.eof -or -not$pump.task.IsCompleted){continue}
                $count=$pump.task.GetAwaiter().GetResult()
                if($count -le 0){$pump.eof=$true;continue}
                $pump.file.Write($pump.buffer,0,$count);$result[$pump.key]+=$count;$total+=$count;$pumped=$true
                if($total -gt $maxOutput){$result.outputExceeded=$true;break}
                $pump.task=$pump.stream.ReadAsync($pump.buffer,0,$pump.buffer.Length)
            }
            if($result.outputExceeded){break}
            if($pumped){continue}
            if($null -eq $targetExit){
                $targetExit=Read-VerificationTargetExit $marker
                # 対象の終了後、パイプを握る残存子はジョブ単位で止め（収集役は残す）、ホストの終了と出力のEOFを短時間だけ待つ。
                if($null -ne $targetExit){$drainDeadline=[DateTime]::UtcNow.AddSeconds(5)}
            }
            if($process.HasExited -and @($pumps | Where-Object {-not$_.eof}).Count -eq 0){break}
            if($null -ne $drainDeadline){
                if([DateTime]::UtcNow -ge $drainDeadline){$result.timedOut=$true;break}
                if($job.Active() -gt 1){$job.StopExcept($process.Id)}
            }elseif([DateTime]::UtcNow -ge $deadlineUtc){$result.timedOut=$true;break}
            # 未完了の読み出しとホストの終了だけを待つ（完了済みを含めると即返って空回りする）。
            $waits=[Threading.Tasks.Task[]]@(@($pumps | Where-Object {-not$_.eof} | ForEach-Object {$_.task})+@($exitTask | Where-Object {-not$_.IsCompleted}))
            if($waits.Length -gt 0){[void][Threading.Tasks.Task]::WaitAny($waits,25)}else{Start-Sleep -Milliseconds 25}
        }
        if($null -eq $targetExit){$targetExit=Read-VerificationTargetExit $marker}   # 終了記録の書込み中に読んだ場合の再読
        if($result.timedOut -or $result.outputExceeded){$job.Stop();[void]$process.WaitForExit(5000)}
        elseif($null -ne $targetExit){$result.exitCode=[int]$targetExit}
        # 親が正常終了しても残った子はジョブ単位で停止する。
        if($job.Active() -gt 0){$job.Stop()}
        $stopDeadline=[DateTime]::UtcNow.AddSeconds(5)
        while($job.Active() -gt 0 -and [DateTime]::UtcNow -lt $stopDeadline){Start-Sleep -Milliseconds 25}
        $result.processTreeStopped=($job.Active() -eq 0)
        $result.started=[IO.File]::Exists($marker)
        if(-not$result.started){$result.exitCode=$null;$result.refusedReason='launch-failed'}
        # 打ち切った実行の exitCode は採否に使わせない（切詰めて成功にしない）。
        if($result.timedOut -or $result.outputExceeded){$result.exitCode=$null}
    }catch{
        # 起動側の失敗は refusedReason=host-failed で返し、理由を stderr ファイルへ残す。stderr ファイルを開く前の失敗は理由を残せないので再送出する。
        if($hostStarted -and -not$process.HasExited){$process.Kill($true);[void]$process.WaitForExit(5000)}
        $result.started=$false;$result.exitCode=$null;$result.refusedReason='host-failed'
        $result.processTreeStopped=($job.Active() -eq 0)
        if($null -eq $errFile){throw}
        $bytes=[Text.Encoding]::UTF8.GetBytes($_.Exception.Message);$errFile.Write($bytes,0,$bytes.Length);$result.stderrBytes+=$bytes.Length
    }finally{
        $job.Dispose()
        # 停止後にパイプへ残った分（高々パイプバッファ分）を上限内で汲み切る。読み切れなければ停止済みと扱わない。
        $drainEnd=[DateTime]::UtcNow.AddSeconds(5)
        foreach($pump in $pumps){
            while(-not$pump.eof -and -not$result.outputExceeded){
                try{
                    if(-not$pump.task.Wait([Math]::Max(1,[int]($drainEnd-[DateTime]::UtcNow).TotalMilliseconds))){$result.processTreeStopped=$false;break}
                    $count=$pump.task.GetAwaiter().GetResult()
                }catch{$count=0}   # 停止後のパイプ切断は読み終わりとして扱う
                if($count -le 0){$pump.eof=$true;break}
                $pump.file.Write($pump.buffer,0,$count);$result[$pump.key]+=$count
                if(($result.stdoutBytes+$result.stderrBytes) -gt $maxOutput){$result.outputExceeded=$true;$result.exitCode=$null;break}
                $pump.task=$pump.stream.ReadAsync($pump.buffer,0,$pump.buffer.Length)
            }
        }
        if($null -ne $stdinTask){try{[void]$stdinTask.Wait(1000)}catch{}}
        try{$process.StandardInput.Close()}catch{}
        if($outFile){$outFile.Dispose()};if($errFile){$errFile.Dispose()};$process.Dispose()
        foreach($pair in @(@('stdoutPath','stdoutHash'),@('stderrPath','stderrHash'))){
            if(Test-Path -LiteralPath $OutputPaths[$pair[0]]){$result[$pair[1]]=(Get-FileHash -LiteralPath $OutputPaths[$pair[0]] -Algorithm SHA256).Hash}
        }
        $result.finishedAt=Get-VerificationUtcNow
    }
    return $result
}
function Start-VerificationBackgroundProcess {
    # 開始マーカー確認後に待たずに戻る。RunBudget は起動可否にだけ使い、起動後の対象を deadlineAt/cleanupDeadlineAt で打ち切らない
    # （セッション保持が全体期限で切れると sbx の自動停止猶予と stop が競合するため。ADR-0193）。出力の容量上限も適用しない。
    # ジョブは module 内の辞書に保持し、Stop-VerificationBackgroundProcess が Dispose する。呼び出し側のプロセスが終了すればジョブハンドルが閉じ、
    # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE により対象の木が止まる。モジュールの除去時も保持中のジョブを Dispose する（下記 OnRemove）。
    param([Diagnostics.ProcessStartInfo]$StartInfo,[hashtable]$OutputPaths,[hashtable]$RunBudget)
    $marker=Test-VerificationProcessInput $StartInfo $OutputPaths
    # RunBudget は「期限到達後は起動しない」の判定にだけ使う。残時間を開始待ちの上限に流用しない（残時間が短いと起動済みの対象を期限由来の値で止めてしまう）。
    if((Get-VerificationRemainingSeconds $RunBudget) -le 0){$failure=[InvalidOperationException]::new('deadline-reached');$failure.Data['refusedReason']='deadline-reached';throw $failure}
    $job=[VerificationJob]::new();$process=New-VerificationHostProcess $StartInfo $marker
    $entry=@{job=$job;process=$process;marker=$marker;outFile=$null;errFile=$null;outTask=$null;errTask=$null;stdinTask=$null}
    $hostStarted=$false
    try{
        $entry.outFile=[IO.File]::Open($OutputPaths.stdoutPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $entry.errFile=[IO.File]::Open($OutputPaths.stderrPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        [void]$process.Start();$hostStarted=$true
        $job.Assign($process.Handle)
        $entry.outTask=$process.StandardOutput.BaseStream.CopyToAsync($entry.outFile)
        $entry.errTask=$process.StandardError.BaseStream.CopyToAsync($entry.errFile)
        $control=Get-VerificationControlBytes $StartInfo ([byte[]]::new(0)) ($job.GrantAssign($process.Handle))
        $entry.stdinTask=$process.StandardInput.BaseStream.WriteAsync($control,0,$control.Length)
        $startDeadline=[DateTime]::UtcNow.AddSeconds($script:BackgroundStartSeconds)
        # 開始マーカーはホストの書込みと競合して読めないことがあるため、読めるまで開始待ちの上限内で読み直す。
        # ホストが終了していてマーカーが無ければ待たない（対象を起動できなかった・ジョブ割当に失敗した）。
        $info=$null
        while([DateTime]::UtcNow -lt $startDeadline){
            $info=Read-VerificationStartMarker $marker
            if($null -ne $info){break}
            if($process.HasExited){if(-not[IO.File]::Exists($marker)){break};Start-Sleep -Milliseconds 25}else{[void]$process.WaitForExit(25)}
        }
        if($null -eq $info){throw 'background process not started'}
        $token=[guid]::NewGuid().ToString('N')
        $script:BackgroundProcesses[$token]=$entry
        return @{processId=[int]$info.pid;jobToken=$token;markerPath=$marker;startedAt=Get-VerificationUtcNow}
    }catch{
        if($hostStarted -and -not$process.HasExited){$process.Kill($true);[void]$process.WaitForExit(5000)}
        $job.Dispose();Close-VerificationBackgroundEntry $entry 1
        throw
    }
}
function Close-VerificationBackgroundEntry([hashtable]$Entry,[int]$WaitSeconds) {
    # 出力の複写を待ってファイルとプロセスを解放する。ジョブの Dispose は呼び出し側が行う。戻り値は複写が終わったか。
    $finished=$true
    foreach($task in @($Entry.outTask,$Entry.errTask)){if($null -ne $task){try{if(-not$task.Wait($WaitSeconds*1000)){$finished=$false}}catch{$finished=$false}}}
    if($null -ne $Entry.stdinTask){try{[void]$Entry.stdinTask.Wait(1000)}catch{}}
    try{$Entry.process.StandardInput.Close()}catch{}
    if($Entry.outFile){$Entry.outFile.Dispose()};if($Entry.errFile){$Entry.errFile.Dispose()};$Entry.process.Dispose()
    $finished
}
function Stop-VerificationBackgroundProcess {
    # ジョブ（対象の木）を止め、GraceSeconds 内に全プロセスの終了と出力の複写完了を確認する。exitCode は対象が自ら終了していた場合だけ持つ。
    param([hashtable]$Handle,[int]$GraceSeconds)
    if($GraceSeconds -le 0){throw 'positive GraceSeconds required'}
    if($null -eq $Handle -or -not$Handle.ContainsKey('jobToken') -or -not$script:BackgroundProcesses.ContainsKey($Handle.jobToken)){throw 'unknown background process handle'}
    $entry=$script:BackgroundProcesses[$Handle.jobToken];$script:BackgroundProcesses.Remove($Handle.jobToken)
    $result=@{exitCode=$null;processTreeStopped=$false}
    try{
        # 停止前に在る終了記録だけを採る（停止後に書かれた記録は打ち切りの結果でありうる）。書込み中で読めなければ短時間だけ読み直す。
        $targetExit=Read-VerificationTargetExit $entry.marker 2
        if($null -ne $targetExit){$result.exitCode=[int]$targetExit}
        if($entry.job.Active() -gt 0){$entry.job.Stop()}
        $deadline=[DateTime]::UtcNow.AddSeconds($GraceSeconds)
        while($entry.job.Active() -gt 0 -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 25}
        $result.processTreeStopped=($entry.job.Active() -eq 0)
    }finally{
        $entry.job.Dispose()
        if(-not(Close-VerificationBackgroundEntry $entry $GraceSeconds)){$result.processTreeStopped=$false}
    }
    return $result
}
$ExecutionContext.SessionState.Module.OnRemove={
    # モジュール除去時に保持中の背景ジョブを解放する（ハンドルが閉じれば対象の木は KILL_ON_JOB_CLOSE で止まる）。
    foreach($entry in @($script:BackgroundProcesses.Values)){try{$entry.job.Dispose();[void](Close-VerificationBackgroundEntry $entry 1)}catch{}}
    $script:BackgroundProcesses.Clear()
}
Export-ModuleMember -Function Invoke-VerificationProcess,Invoke-VerificationProcessV3,Start-VerificationBackgroundProcess,Stop-VerificationBackgroundProcess
