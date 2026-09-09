$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Assert-True (Test-Path -LiteralPath (Join-Path $PSScriptRoot '../Execution.psm1')) 'プロセス管理が未実装'
Import-Module (Join-Path $PSScriptRoot '../Execution.psm1') -Force
$case=New-TestCase 'execution'
foreach($mode in @('ok','fail','output','child','missing','orphan','arguments')){
    $start=[Diagnostics.ProcessStartInfo]::new($case.settings.pwshPath)
    $start.WorkingDirectory=$case.root;$start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $pidPath=Join-Path $case.root 'child-pid.json'
    foreach($a in @('-NoProfile','-File',(Join-Path $PSScriptRoot 'fixtures/ProcessFixture.ps1'),'-Mode',$(if($mode -eq 'missing'){'ok'}else{$mode}),'-PidPath',$pidPath)){$start.ArgumentList.Add($a)}
    $payload='日本語 "quote" $() `literal'+"`n"+'second line'
    if($mode -eq 'arguments'){$start.ArgumentList.Add('-Payload');$start.ArgumentList.Add($payload);$start.Environment['TEMP']=$case.runsRoot}
    if($mode -eq 'missing'){$start.FileName=Join-Path $case.root 'missing.exe'}
    $out=Join-Path $case.root "$mode.out";$err=Join-Path $case.root "$mode.err"
    $result=& (Get-Module Execution) {param($s,$o,$e,$timeout) Invoke-VerificationProcess -StartInfo $s -EventsPath $o -ErrorPath $e -TimeoutSeconds $timeout} $start $out $err $(if($mode -eq 'child'){3}else{15})
    if($mode -eq 'missing'){Assert-True (-not$result.started) '対象の起動失敗を区別';continue}
    Assert-True $result.started '対象が起動した'
    Assert-True $result.processTreeStopped 'ジョブ内の全プロセスが終了'
    switch($mode){
        'ok'{Assert-Equal $result.exitCode 0 '正常終了';Assert-Equal ([IO.File]::ReadAllText($out).Trim()) 'fixture-ok' 'stdoutの実内容'}
        'fail'{Assert-Equal $result.exitCode 7 '非ゼロを保持';Assert-True ([IO.File]::ReadAllText($err).Contains('fixture failure')) 'stderr保存'}
        'output'{Assert-Equal $result.exitCode 0 '大量出力でも完了';Assert-Equal ([IO.File]::ReadAllText($out).Split("`n",[StringSplitOptions]::RemoveEmptyEntries).Count) 4096 'stdout全行';Assert-Equal ([IO.File]::ReadAllText($err).Split("`n",[StringSplitOptions]::RemoveEmptyEntries).Count) 4096 'stderr全行'}
        'child'{Assert-True $result.timedOut '時間超過';$info=Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json;$alive=Get-Process -Id $info.pid -ErrorAction SilentlyContinue;Assert-True ($null -eq $alive -or $alive.StartTime.ToUniversalTime().Ticks -ne $info.startTicks) '実子プロセスが停止、PID再利用を区別'}
        'orphan'{Assert-Equal $result.exitCode 0 '親の正常終了';$info=Get-Content -LiteralPath $pidPath -Raw | ConvertFrom-Json;$alive=Get-Process -Id $info.pid -ErrorAction SilentlyContinue;Assert-True ($null -eq $alive -or $alive.StartTime.ToUniversalTime().Ticks -ne $info.startTicks) '親が先に終了しても子が残らない'}
        'arguments'{$body=[IO.File]::ReadAllText($out) | ConvertFrom-Json;Assert-Equal $body.payload $payload '引用符と改行をそのまま渡す';Assert-Equal $body.cwd $case.root '指定cwd';Assert-Equal $body.temp $case.runsRoot '指定環境'}
    }
}
'Execution: 7 scenarios passed'
