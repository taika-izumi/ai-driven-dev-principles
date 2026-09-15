$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../Execution.psm1') -Force
# ケース領域は短い名前にする（Windows の MAX_PATH。Issue-0146）。Git 初期化は不要なので New-TestCase は使わない。
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
$root=Join-Path $repo ('.tmp/verification-tests/x3'+[guid]::NewGuid().ToString('N').Substring(0,6))
[void][IO.Directory]::CreateDirectory($root)
$pwsh=(Get-Command pwsh -ErrorAction Stop).Source
$fixture=Join-Path $PSScriptRoot 'fixtures/ProcessFixtureV3.ps1'
$isoUtc='^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}Z$'
$count=0
function New-Start([string]$Mode,[int]$Seconds=1,[string]$Tag=''){
    $start=[Diagnostics.ProcessStartInfo]::new($pwsh)
    $start.WorkingDirectory=$root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    foreach($a in @('-NoProfile','-File',$fixture,'-Mode',$Mode,'-Seconds',$Seconds)){$start.ArgumentList.Add($a)}
    if($Tag){$start.ArgumentList.Add('-Tag');$start.ArgumentList.Add($Tag)}
    $start
}
function New-Budget([string]$Phase='work',[int]$CommandSeconds=15,[double]$DeadlineIn=120,$CleanupIn=$null,[long]$MaxOutput=16MB){
    $now=[DateTime]::UtcNow
    @{
        startedAt=$now.ToString('o');deadlineAt=$now.AddSeconds($DeadlineIn).ToString('o')
        cleanupDeadlineAt=$(if($null -eq $CleanupIn){$null}else{$now.AddSeconds([double]$CleanupIn).ToString('o')})
        limits=@{maxOutputBytes=$MaxOutput;commandSeconds=$CommandSeconds};phase=$Phase
    }
}
function New-Paths([string]$Name){@{stdoutPath=(Join-Path $root "$Name.out");stderrPath=(Join-Path $root "$Name.err")}}
function Get-Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash}
function Test-TargetGone([string]$Marker){
    # PID再利用を StartTime で区別する（v1 試験と同じ方式）。
    $info=[IO.File]::ReadAllText($Marker) | ConvertFrom-Json
    $alive=Get-Process -Id $info.pid -ErrorAction SilentlyContinue
    ($null -eq $alive -or $alive.StartTime.ToUniversalTime().Ticks -ne $info.startTicks)
}

# 1. 反響: stdin のバイト列がそのまま stdout に現れ、終了0。非ASCII引数も制御行（ASCII化）を経て届く。ハッシュはファイル実体と一致。
$payload=[byte[]]([Text.UTF8Encoding]::new($false).GetBytes('日本語 "quote" $() `literal'+"`r`n"+'second line'+"`n")+[byte[]](0..255))
$tag='タグ "quoted" \back\slash'
$paths=New-Paths 'echo'
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo' -Tag $tag) -StdinBytes $payload -OutputPaths $paths -RunBudget (New-Budget)
Assert-True $r.started '反響: 対象が起動した';Assert-Equal $r.exitCode 0 '反響: 終了0'
Assert-True (-not$r.timedOut -and -not$r.outputExceeded) '反響: 打ち切りなし';Assert-True $r.processTreeStopped '反響: ジョブ内の全プロセスが終了'
Assert-True ($null -eq $r.refusedReason) '反響: 拒否理由なし'
Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($paths.stdoutPath))) ([Convert]::ToBase64String($payload)) '反響: stdin のバイト列が一致（制御JSONが混ざらない）'
Assert-Equal $r.stdoutBytes $payload.Length '反響: stdoutBytes';Assert-Equal $r.stdoutHash (Get-Hash $paths.stdoutPath) '反響: stdoutHash がファイル実体と一致'
Assert-Equal ([Text.UTF8Encoding]::new($false).GetString([IO.File]::ReadAllBytes($paths.stderrPath))) $tag '反響: 非ASCII引数の転送'
Assert-Equal $r.stderrBytes ([IO.FileInfo]::new($paths.stderrPath).Length) '反響: stderrBytes';Assert-Equal $r.stderrHash (Get-Hash $paths.stderrPath) '反響: stderrHash がファイル実体と一致'
Assert-True ($r.finishedAt -match $isoUtc) '反響: finishedAt は ISO 8601 UTC'
$count++

# 2. stdin 未読: 1MiB を渡しても対象は読まずに終了7し、上限や期限を待たない。
$big=[byte[]]::new(1MB);[Array]::Fill($big,[byte]120)
$paths=New-Paths 'ignore';$watch=[Diagnostics.Stopwatch]::StartNew()
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'ignore') -StdinBytes $big -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 20 -DeadlineIn 20)
$watch.Stop()
Assert-True $r.started 'stdin未読: 起動';Assert-Equal $r.exitCode 7 'stdin未読: 非0終了を保持'
Assert-True (-not$r.timedOut -and -not$r.outputExceeded) 'stdin未読: 打ち切りなし';Assert-True $r.processTreeStopped 'stdin未読: 全停止'
Assert-True ($watch.Elapsed.TotalSeconds -lt 15) "stdin未読: 上限20秒を待たない（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
Assert-True (([IO.File]::ReadAllText($paths.stderrPath)).Contains('fixture ignores stdin')) 'stdin未読: stderr 保存'
Assert-Equal $r.stdoutBytes 0 'stdin未読: stdout なし'
$count++

# 3. 出力洪水: 合算が maxOutputBytes を超えた時点で outputExceeded=true、ジョブ停止、exitCode は採否に使わせない（null）。
$paths=New-Paths 'flood';$watch=[Diagnostics.Stopwatch]::StartNew()
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'flood') -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 20 -MaxOutput 1MB)
$watch.Stop()
Assert-True $r.started '洪水: 起動';Assert-True $r.outputExceeded '洪水: outputExceeded';Assert-True $r.processTreeStopped '洪水: processTreeStopped'
Assert-True (-not$r.timedOut) '洪水: 時間超過ではない';Assert-True ($null -eq $r.exitCode) '洪水: exitCode を持たない（切詰めて成功にしない）'
$total=$r.stdoutBytes+$r.stderrBytes
Assert-True ($total -gt 1MB) "洪水: 合算が上限を超えた時点で止まる（$total）";Assert-True ($total -le 1MB+2*65536) "洪水: 超過分は読み出し単位に収まる（$total）"
Assert-Equal ([IO.FileInfo]::new($paths.stdoutPath).Length) $r.stdoutBytes '洪水: stdout の実体と件数が一致';Assert-Equal ([IO.FileInfo]::new($paths.stderrPath).Length) $r.stderrBytes '洪水: stderr の実体と件数が一致'
Assert-True (Test-TargetGone ($paths.stdoutPath+'.started.json')) '洪水: 対象プロセスが停止'
Assert-True ($watch.Elapsed.TotalSeconds -lt 15) "洪水: 上限20秒を待たない（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
$count++

# 4. 時間超過（commandSeconds）: 1秒で打ち切り timedOut=true。
$paths=New-Paths 'timeout';$watch=[Diagnostics.Stopwatch]::StartNew()
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'sleep' -Seconds 60) -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 1)
$watch.Stop()
Assert-True $r.started '時間超過: 起動';Assert-True $r.timedOut '時間超過: timedOut';Assert-True ($null -eq $r.exitCode) '時間超過: exitCode なし'
Assert-True $r.processTreeStopped '時間超過: 全停止';Assert-True (Test-TargetGone ($paths.stdoutPath+'.started.json')) '時間超過: 対象プロセスが停止'
Assert-True ($watch.Elapsed.TotalSeconds -lt 10) "時間超過: 1秒上限で止まる（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
$count++

# 5. 残時間は min(commandSeconds, deadlineAt-now): commandSeconds が大きくても work 相の期限で打ち切る。cleanup 相は cleanupDeadlineAt で同様。
foreach($phase in @('work','cleanup')){
    $paths=New-Paths "dl-$phase";$watch=[Diagnostics.Stopwatch]::StartNew()
    $budget=$(if($phase -eq 'work'){New-Budget -CommandSeconds 60 -DeadlineIn 1}else{New-Budget -Phase cleanup -CommandSeconds 60 -DeadlineIn -30 -CleanupIn 1})
    $r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'sleep' -Seconds 60) -StdinBytes $null -OutputPaths $paths -RunBudget $budget
    $watch.Stop()
    Assert-True ($r.started -and $r.timedOut -and $r.processTreeStopped) "$phase 相の期限: 期限で打ち切り";Assert-True ($watch.Elapsed.TotalSeconds -lt 10) "$phase 相の期限: 残時間1秒で止まる（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
    $count++
}

# 6. 起動失敗（存在しない実行ファイル）: started=false、exitCode なし、ホストの理由が stderr に残る。
$start=New-Start 'echo';$start.FileName=Join-Path $root 'missing.exe';$paths=New-Paths 'missing'
$r=Invoke-VerificationProcessV3 -StartInfo $start -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget)
Assert-True (-not$r.started) '起動失敗: started=false';Assert-True ($null -eq $r.exitCode) '起動失敗: exitCode なし';Assert-Equal $r.refusedReason 'launch-failed' '起動失敗: 理由'
Assert-True ($r.stderrBytes -gt 0 -and $r.processTreeStopped) '起動失敗: stderr にホストの理由、ジョブは空'
$count++

# 6a. 起動側の失敗: 出力ファイルを開いた後の失敗（作業ディレクトリ不在でホストを起動できない）は refusedReason=host-failed で理由を stderr に残す。
#     stdout ファイルを作れない失敗（ディレクトリ不在）は理由を残せないので例外になる。
$start=New-Start 'echo';$start.WorkingDirectory=Join-Path $root 'no-such-dir';$paths=New-Paths 'hostfail'
$r=Invoke-VerificationProcessV3 -StartInfo $start -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget)
Assert-True (-not$r.started -and $null -eq $r.exitCode) '起動側失敗: started=false・exitCode なし';Assert-Equal $r.refusedReason 'host-failed' '起動側失敗: 理由'
Assert-True ($r.stderrBytes -gt 0 -and ([IO.FileInfo]::new($paths.stderrPath)).Length -eq $r.stderrBytes) '起動側失敗: 例外メッセージを stderr ファイルに残す'
Assert-True ($r.processTreeStopped -and $r.finishedAt -match $isoUtc) '起動側失敗: ジョブは空・finishedAt'
$badPaths=@{stdoutPath=(Join-Path $root 'no-such-dir/x.out');stderrPath=(Join-Path $root 'no-such-dir/x.err')}
Assert-Throws {Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths $badPaths -RunBudget (New-Budget)} '*no-such-dir*'
$count++

# 6b. 対象が先に終了しても出力パイプを握る孫が残る場合（v1 fixture の orphan）: 残存子をジョブ単位で止め、終了0を保ちつつ全停止する。
$start=[Diagnostics.ProcessStartInfo]::new($pwsh);$start.WorkingDirectory=$root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$pidPath=Join-Path $root 'orphan-pid.json'
foreach($a in @('-NoProfile','-File',(Join-Path $PSScriptRoot 'fixtures/ProcessFixture.ps1'),'-Mode','orphan','-PidPath',$pidPath)){$start.ArgumentList.Add($a)}
$paths=New-Paths 'orphan';$watch=[Diagnostics.Stopwatch]::StartNew()
$r=Invoke-VerificationProcessV3 -StartInfo $start -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 20)
$watch.Stop()
Assert-True ($r.started -and $r.exitCode -eq 0 -and -not$r.timedOut) '孫残存: 対象の終了0を保つ';Assert-True $r.processTreeStopped '孫残存: 全停止'
$info=Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json;$alive=Get-Process -Id $info.pid -ErrorAction SilentlyContinue
Assert-True ($null -eq $alive -or $alive.StartTime.ToUniversalTime().Ticks -ne $info.startTicks) '孫残存: 孫プロセスが停止'
Assert-True ($watch.Elapsed.TotalSeconds -lt 15) "孫残存: 上限20秒を待たない（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
$count++

# 7. 期限到達後の新規起動拒否: work 相は deadlineAt 経過で refusedReason=deadline-reached（プロセスも出力ファイルも作らない）。cleanup 相は cleanupDeadlineAt 内なら起動できる。
$paths=New-Paths 'refused'
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -DeadlineIn -1)
Assert-True (-not$r.started) '期限後(work): 起動しない';Assert-Equal $r.refusedReason 'deadline-reached' '期限後(work): 理由'
Assert-True (-not(Test-Path -LiteralPath $paths.stdoutPath) -and -not(Test-Path -LiteralPath ($paths.stdoutPath+'.started.json'))) '期限後(work): 出力ファイルもマーカーも作らない'
Assert-True ($r.finishedAt -match $isoUtc -and $null -eq $r.exitCode) '期限後(work): finishedAt と exitCode'
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -Phase cleanup -DeadlineIn -1 -CleanupIn -1)
Assert-True (-not$r.started -and $r.refusedReason -eq 'deadline-reached') '期限後(cleanup): cleanupDeadlineAt 経過で起動しない'
$r=Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes ([Text.Encoding]::ASCII.GetBytes('cleanup')) -OutputPaths $paths -RunBudget (New-Budget -Phase cleanup -DeadlineIn -1 -CleanupIn 60)
Assert-True ($r.started -and $r.exitCode -eq 0) '期限後(cleanup): deadlineAt 経過後でも cleanupDeadlineAt 内なら起動できる'
Assert-Equal ([IO.File]::ReadAllText($paths.stdoutPath)) 'cleanup' '期限後(cleanup): stdin 転送'
Assert-Throws {Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths (New-Paths 'bad') -RunBudget (New-Budget -Phase cleanup)} '*cleanupDeadlineAt*'
Assert-Throws {Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths (New-Paths 'bad') -RunBudget (New-Budget -Phase other)} '*phase*'
Assert-Throws {Invoke-VerificationProcessV3 -StartInfo (New-Start 'echo') -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget)} '*new absolute output paths*'
$count++

# 8. 背景起動: deadlineAt 経過後も対象が生きている（期限で打ち切られない）。Stop で止めて processTreeStopped=true。
#    deadlineAt は3秒先にし（pwsh 2プロセスの起動が1秒に収まることに依存しない）、起動後に期限の経過を待ってから生存を確認する。
$paths=New-Paths 'bg-keep';$budget=New-Budget -CommandSeconds 60 -DeadlineIn 3
$h=Start-VerificationBackgroundProcess -StartInfo (New-Start 'sleep' -Seconds 120) -OutputPaths $paths -RunBudget $budget
Assert-True ($h.processId -is [int] -and $h.processId -gt 0) '背景: processId';Assert-True ($h.jobToken -is [string] -and $h.jobToken.Length -gt 0) '背景: jobToken'
Assert-Equal $h.markerPath ($paths.stdoutPath+'.started.json') '背景: markerPath';Assert-True ($h.startedAt -match $isoUtc) '背景: startedAt'
$info=[IO.File]::ReadAllText($h.markerPath) | ConvertFrom-Json;Assert-Equal $h.processId ([int]$info.pid) '背景: processId は対象（マーカー）の PID'
$deadlineUtc=[DateTimeOffset]::Parse($budget.deadlineAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::AssumeUniversal).UtcDateTime
while([DateTime]::UtcNow -le $deadlineUtc.AddMilliseconds(500)){Start-Sleep -Milliseconds 100}
Assert-True ([DateTime]::UtcNow -gt $deadlineUtc) '背景: deadlineAt を過ぎた'
$alive=Get-Process -Id $h.processId -ErrorAction SilentlyContinue
Assert-True ($null -ne $alive -and $alive.StartTime.ToUniversalTime().Ticks -eq $info.startTicks) '背景: deadlineAt 経過後も対象が生きている'
$s=Stop-VerificationBackgroundProcess -Handle $h -GraceSeconds 5
Assert-True $s.processTreeStopped '背景: Stop で processTreeStopped';Assert-True ($null -eq $s.exitCode) '背景: 打ち切った対象の exitCode なし'
Assert-True (Test-TargetGone $h.markerPath) '背景: 対象プロセスが停止'
Assert-Throws {Stop-VerificationBackgroundProcess -Handle $h -GraceSeconds 5} '*unknown background process handle*'
$count++

# 9. 背景起動した対象が自ら終了していれば Stop は exitCode を返す。期限到達後は起動しない。
$paths=New-Paths 'bg-exit'
$h=Start-VerificationBackgroundProcess -StartInfo (New-Start 'sleep' -Seconds 1) -OutputPaths $paths -RunBudget (New-Budget)
$wait=[DateTime]::UtcNow.AddSeconds(15);while(-not(Test-Path -LiteralPath ($h.markerPath+'.exit.json')) -and [DateTime]::UtcNow -lt $wait){Start-Sleep -Milliseconds 50}
$s=Stop-VerificationBackgroundProcess -Handle $h -GraceSeconds 5
Assert-Equal $s.exitCode 0 '背景(自然終了): exitCode';Assert-True $s.processTreeStopped '背景(自然終了): processTreeStopped'
$paths=New-Paths 'bg-late'
Assert-Throws {Start-VerificationBackgroundProcess -StartInfo (New-Start 'sleep' -Seconds 120) -OutputPaths $paths -RunBudget (New-Budget -DeadlineIn -1)} 'deadline-reached'
Assert-True (-not(Test-Path -LiteralPath ($paths.stdoutPath+'.started.json'))) '背景(期限後): 起動しない'
$count++

# 10〜13. 非パッケージの実在 exe（System32 の ping.exe・cmd.exe）を対象にする（Issue-0147）。
#     MSIX 版 pwsh の ProcessHost が起動した非パッケージの子は、明示割当しないとジョブに入らず、ジョブ停止が届かない。
#     判定は PID と StartTime（CreationDate）で行い、名前では探さない。試験が起動したプロセスは、残っていれば判定の前に試験自身が止める。
$sys32=Join-Path $env:SystemRoot 'System32';$pingPath=Join-Path $sys32 'ping.exe'
function New-Native([string]$File,[string[]]$Argv){
    $start=[Diagnostics.ProcessStartInfo]::new((Join-Path $sys32 $File))
    $start.WorkingDirectory=$root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    foreach($a in $Argv){$start.ArgumentList.Add($a)}
    $start
}
function Get-LiveProcess([int]$Id,[long]$Ticks){
    # PID と開始時刻の両方が一致する生存プロセス（なければ null）。
    $p=Get-Process -Id $Id -ErrorAction SilentlyContinue
    if($null -eq $p){return $null}
    try{$startTicks=$p.StartTime.ToUniversalTime().Ticks}catch{return $null}
    if($startTicks -eq $Ticks){$p}else{$null}
}
function Get-ChildProcess([int]$ParentId,[long]$ParentTicks){
    # 親 PID が一致し、親の開始以後に作られた生存プロセス（PID 再利用された別の親の子を除く）。戻り値は @{pid;startTicks}（発見時の開始時刻で固定する）。
    $notBefore=[DateTime]::new($ParentTicks,[DateTimeKind]::Utc).AddMilliseconds(-1)
    foreach($c in @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ParentId" | Where-Object {$_.CreationDate.ToUniversalTime() -ge $notBefore})){
        $p=Get-Process -Id $c.ProcessId -ErrorAction SilentlyContinue
        if($null -eq $p){continue}
        try{@{pid=[int]$p.Id;startTicks=$p.StartTime.ToUniversalTime().Ticks}}catch{}
    }
}
function Stop-Leftover([object[]]$Records){
    # 試験が起動したプロセス（@{pid;startTicks}）だけを、開始時刻を再確認してから止める。止めた（=残っていた）件数を返す。
    # cmd.exe の子の conhost.exe はコンソールの生成時に作られてジョブに入らないが、利用者が居なくなると自ら終わる。その終了を最大2秒待ってから数える
    # （ジョブ停止が届かなかった対象は 60 秒の ping なので、2 秒の猶予で見逃さない）。
    $stopped=0;$settle=[DateTime]::UtcNow.AddSeconds(2)
    while([DateTime]::UtcNow -lt $settle -and @($Records | Where-Object {$null -ne $_ -and $null -ne (Get-LiveProcess $_.pid $_.startTicks)}).Count -gt 0){Start-Sleep -Milliseconds 100}
    foreach($record in @($Records | Where-Object {$null -ne $_})){
        $live=Get-LiveProcess $record.pid $record.startTicks
        if($null -ne $live){try{$live.Kill();[void]$live.WaitForExit(5000)}catch{};$stopped++}
    }
    $stopped
}
function Get-MarkerTarget([string]$Marker){
    $info=[IO.File]::ReadAllText($Marker) | ConvertFrom-Json
    @{pid=[int]$info.pid;startTicks=[long]$info.startTicks}
}

# 10. 非パッケージの対象（ping.exe）の時間超過: ジョブ停止が対象に届き、対象 PID が消える。
$paths=New-Paths 'n-ping';$watch=[Diagnostics.Stopwatch]::StartNew()
$r=Invoke-VerificationProcessV3 -StartInfo (New-Native 'ping.exe' @('-n','60','127.0.0.1')) -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 1)
$watch.Stop()
$target=Get-MarkerTarget ($paths.stdoutPath+'.started.json')
$left=Stop-Leftover @($target)
Assert-Equal $left 0 '非パッケージ時間超過: 対象（ping.exe）がジョブ停止で消える'
Assert-True ($r.started -and $r.timedOut -and $null -eq $r.exitCode) '非パッケージ時間超過: started・timedOut・exitCode なし'
Assert-True $r.processTreeStopped '非パッケージ時間超過: processTreeStopped'
Assert-True ($watch.Elapsed.TotalSeconds -lt 15) "非パッケージ時間超過: 上限1秒で止まる（実測 $([int]$watch.Elapsed.TotalSeconds) 秒）"
$count++

# 11. 非パッケージの対象が非パッケージの孫を持つ（cmd.exe /c ping.exe）時間超過: 対象と孫の両方が消える。
#     孫は対象の終了後も親 PID を保つので、対象の開始以後に作られた子が1件も生存していないことで判定する。
$paths=New-Paths 'n-cmd'
$r=Invoke-VerificationProcessV3 -StartInfo (New-Native 'cmd.exe' @('/d','/c',(Join-Path $sys32 'ping.exe'),'-n','60','127.0.0.1')) -StdinBytes $null -OutputPaths $paths -RunBudget (New-Budget -CommandSeconds 2)
$target=Get-MarkerTarget ($paths.stdoutPath+'.started.json')
$left=Stop-Leftover (@(Get-ChildProcess $target.pid $target.startTicks)+@($target))
Assert-Equal $left 0 '非パッケージ孫: 対象（cmd.exe）と孫（ping.exe）がジョブ停止で消える'
Assert-True ($r.started -and $r.timedOut -and $r.processTreeStopped) '非パッケージ孫: started・timedOut・processTreeStopped'
$count++

# 12. 非パッケージの背景起動（cmd.exe /c ping.exe）→ Stop: 対象 PID と孫 PID が消え processTreeStopped=true。
$paths=New-Paths 'n-bg'
$h=Start-VerificationBackgroundProcess -StartInfo (New-Native 'cmd.exe' @('/d','/c',(Join-Path $sys32 'ping.exe'),'-n','60','127.0.0.1')) -OutputPaths $paths -RunBudget (New-Budget)
$target=Get-MarkerTarget $h.markerPath;$targetAlive=($null -ne (Get-LiveProcess $target.pid $target.startTicks))
# 孫（ping.exe）の出現を待つ。cmd.exe の子には conhost.exe も含まれうるため、件数でなく ping.exe の実行ファイルパスが一致する子の有無で待つ（探索は親 PID で行う）。
$grand=@();$wait=[DateTime]::UtcNow.AddSeconds(10)
while([DateTime]::UtcNow -lt $wait){
    $grand=@(Get-ChildProcess $target.pid $target.startTicks)
    if(@($grand | Where-Object {(Get-Process -Id $_.pid -ErrorAction SilentlyContinue).Path -eq $pingPath}).Count -gt 0){break}
    Start-Sleep -Milliseconds 100
}
$grandStarted=(@($grand | Where-Object {(Get-Process -Id $_.pid -ErrorAction SilentlyContinue).Path -eq $pingPath}).Count -gt 0)
$s=Stop-VerificationBackgroundProcess -Handle $h -GraceSeconds 5
$left=Stop-Leftover (@($grand)+@($target))
Assert-True ($targetAlive -and $grandStarted) '非パッケージ背景: 対象と孫が起動していた'
Assert-Equal $left 0 '非パッケージ背景: Stop で対象（cmd.exe）と孫（ping.exe）が消える'
Assert-True $s.processTreeStopped '非パッケージ背景: processTreeStopped';Assert-True ($null -eq $s.exitCode) '非パッケージ背景: 打ち切った対象の exitCode なし'
$count++

# 13. ホストのジョブ割当が失敗したら黙って続けない: 対象を止め、開始マーカーを書かず、理由を stderr に残して失敗終了する。
#     ジョブハンドルの無い要求は対象を起動しない。起動側は必ずハンドルを渡すので、ProcessHost を直接起動して確かめる。
function Invoke-HostDirect([string]$Name,[hashtable]$Request){
    $marker=Join-Path $root "$Name.started.json"
    $start=[Diagnostics.ProcessStartInfo]::new($pwsh);$start.WorkingDirectory=$root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardInput=$true;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($a in @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot '../ProcessHost.ps1'),'-StartedPath',$marker)){$start.ArgumentList.Add($a)}
    $hostProcess=[Diagnostics.Process]::Start($start)
    $hostTicks=$hostProcess.StartTime.ToUniversalTime().Ticks
    $outTask=$hostProcess.StandardOutput.ReadToEndAsync();$errTask=$hostProcess.StandardError.ReadToEndAsync()
    $line=[Text.Encoding]::ASCII.GetBytes(($Request | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii)+"`n")
    $hostProcess.StandardInput.BaseStream.Write($line,0,$line.Length);$hostProcess.StandardInput.Close()
    $exited=$hostProcess.WaitForExit(20000)
    # 残存の数え上げと停止をホストの停止より先に行う（ホストを木ごと止めると残存が数えられなくなる）。
    $left=Stop-Leftover @(Get-ChildProcess $hostProcess.Id $hostTicks)
    if(-not$exited){try{$hostProcess.Kill($true);[void]$hostProcess.WaitForExit(5000)}catch{}}
    $result=@{exited=$exited;exitCode=$(if($exited){$hostProcess.ExitCode}else{$null});marker=[IO.File]::Exists($marker);left=$left
              stderr=$(if($errTask.Wait(5000)){$errTask.Result}else{''})}
    $hostProcess.Dispose()
    $result
}
#     正の値だがホスト内で有効なジョブハンドルではない値を渡し、対象の起動後の割当失敗の経路を通す。
$r=Invoke-HostDirect 'h-bad' @{version=3;file=$pingPath;cwd=$root;args=@('-n','60','127.0.0.1');stdinBytesLength=0;jobHandle=2147483644}
Assert-Equal $r.left 0 '割当失敗: 対象を止めてから終了する（ホストの開始以後の子が残らない）'
Assert-True ($r.exited -and $r.exitCode -ne 0) "割当失敗: ホストは失敗終了する（exit=$($r.exitCode)）"
Assert-True (-not$r.marker) '割当失敗: 開始マーカーを書かない（起動側は started=false とする）'
Assert-True ($r.stderr -like '*job assignment failed*') "割当失敗: 理由を stderr に残す（$($r.stderr.Trim())）"
$r=Invoke-HostDirect 'h-none' @{version=3;file=$pingPath;cwd=$root;args=@('-n','60','127.0.0.1');stdinBytesLength=0}
Assert-True ($r.exited -and $r.exitCode -ne 0 -and -not$r.marker -and $r.left -eq 0) 'ジョブハンドルなし: 対象を起動せず失敗終了する'
Assert-True ($r.stderr -like '*job handle required*') "ジョブハンドルなし: 理由を stderr に残す（$($r.stderr.Trim())）"
$count++

# 14. 開始マーカー・終了記録の読取りがホストの書込みと競合しても例外にせず読み直す（共有違反・空・不完全 JSON）。
#     モジュール内の読取り補助を直接呼ぶ。共有違反は別プロセス（pwsh）がファイルを排他で開いて作り、一定時間後に解放する。
$execution=Get-Module Execution
$mk=Join-Path $root 'rd.started.json'
[IO.File]::WriteAllText($mk,'')
Assert-True ($null -eq (& $execution {param($p) Read-VerificationStartMarker $p} $mk)) '読取り競合: 空のマーカーは null（例外にしない）'
[IO.File]::WriteAllText($mk,'{"pid":12')
Assert-True ($null -eq (& $execution {param($p) Read-VerificationStartMarker $p} $mk)) '読取り競合: 不完全 JSON のマーカーは null'
$lock=[IO.File]::Open($mk,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try{Assert-True ($null -eq (& $execution {param($p) Read-VerificationStartMarker $p} $mk)) '読取り競合: 共有違反のマーカーは null'}finally{$lock.Dispose()}
[IO.File]::WriteAllText($mk,'{"pid":1234,"startTicks":5678}')
$info=& $execution {param($p) Read-VerificationStartMarker $p} $mk
Assert-True ($null -ne $info -and $info.pid -eq 1234 -and $info.startTicks -eq 5678) '読取り競合: 書き終えたマーカーは読める'
[IO.File]::WriteAllText($mk+'.exit.json','{"exitCode":5}')
$signal=Join-Path $root 'rd.locked'
$holder=[Diagnostics.ProcessStartInfo]::new($pwsh);$holder.UseShellExecute=$false;$holder.CreateNoWindow=$true
$holderScript="`$f=[IO.File]::Open('$($mk+'.exit.json')','Open','ReadWrite','None');[IO.File]::WriteAllText('$signal','x');Start-Sleep -Milliseconds 1500;`$f.Dispose()"
foreach($a in @('-NoProfile','-NonInteractive','-Command',$holderScript)){$holder.ArgumentList.Add($a)}
$holderProcess=[Diagnostics.Process]::Start($holder);$holderRecord=@{pid=$holderProcess.Id;startTicks=$holderProcess.StartTime.ToUniversalTime().Ticks}
try{
    $wait=[DateTime]::UtcNow.AddSeconds(15);while(-not[IO.File]::Exists($signal) -and [DateTime]::UtcNow -lt $wait){Start-Sleep -Milliseconds 25}
    Assert-True ([IO.File]::Exists($signal)) '読取り競合: 別プロセスが終了記録を排他で開いた'
    Assert-True ($null -eq (& $execution {param($p) Read-VerificationTargetExit $p} $mk)) '読取り競合: 再試行なしの終了記録読取りは共有違反で null（例外にしない）'
    $watch=[Diagnostics.Stopwatch]::StartNew()
    $exit=& $execution {param($p) Read-VerificationTargetExit $p 10} $mk
    $watch.Stop()
    Assert-Equal $exit 5 "読取り競合: 在るのに読めない間は読み直し、解放後に読める（実測 $([int]$watch.Elapsed.TotalMilliseconds) ms）"
}finally{
    [void]$holderProcess.WaitForExit(10000);[void](Stop-Leftover @($holderRecord));$holderProcess.Dispose()
}
$count++

"ExecutionV3: $count cases passed"
