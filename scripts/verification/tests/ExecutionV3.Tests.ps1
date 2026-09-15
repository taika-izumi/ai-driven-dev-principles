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

"ExecutionV3: $count cases passed"
