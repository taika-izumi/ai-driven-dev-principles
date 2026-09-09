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
  IntPtr job;
  public VerificationJob(){
    job=CreateJobObject(IntPtr.Zero,null);if(job==IntPtr.Zero)throw new Win32Exception();
    var info=new Extended();info.Basic.Flags=0x2000;
    int size=Marshal.SizeOf<Extended>();IntPtr buffer=Marshal.AllocHGlobal(size);
    try{Marshal.StructureToPtr(info,buffer,false);if(!SetInformationJobObject(job,9,buffer,(uint)size))throw new Win32Exception();}
    catch{Dispose();throw;}finally{Marshal.FreeHGlobal(buffer);}
  }
  public void Assign(IntPtr process){if(!AssignProcessToJobObject(job,process))throw new Win32Exception();}
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
        $request=@{file=$StartInfo.FileName;cwd=$StartInfo.WorkingDirectory;args=@($StartInfo.ArgumentList)}
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
Export-ModuleMember -Function Invoke-VerificationProcess
