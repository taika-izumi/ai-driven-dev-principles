param([Parameter(Mandatory)][string]$Manifest)
$ErrorActionPreference = 'Stop'
# この実証専用のstdio MCP接続。任意コマンド・パス・権限指定は受け取らない。
$config = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
$root = [IO.Path]::GetFullPath($config.fixtureRoot).Replace('\','/')
$run = "$root/run"
$probe = "$root/controller/probe.ps1"
$profile = 'permissions.inspection={extends=":read-only",filesystem={"' + $run + '"="write","' + $run + '/session-log.json"="read"},network={enabled=false}}'
$tool = @{
    name='run_inspection'
    description='試験用コピーでPester正常系・変異・復元、保護代用品への親子書き込み拒否、既存記録保全を確認する。実物の変更と削除は行わない。'
    inputSchema=@{type='object';properties=@{};additionalProperties=$false}
}
while ($null -ne ($line = [Console]::ReadLine())) {
    $request = $null
    try {
        $request = $line | ConvertFrom-Json -AsHashtable
        if (-not $request.ContainsKey('id')) { continue }
        $response = @{jsonrpc='2.0';id=$request.id}
        switch ($request.method) {
            'initialize' { $response.result=@{protocolVersion='2025-03-26';capabilities=@{tools=@{}};serverInfo=@{name='inspection-probe-only';version='0.0.1'}} }
            'ping' { $response.result=@{} }
            'tools/list' { $response.result=@{tools=@($tool)} }
            'tools/call' {
                if ($request.params.name -ne 'run_inspection' -or ($request.params.arguments -and $request.params.arguments.Count -ne 0)) { throw '固定検査以外の操作・引数は受け付けません' }
                if ((Get-FileHash -LiteralPath $probe -Algorithm SHA256).Hash -ne $config.probeSha256) { throw '試験スクリプトが承認済みのコピーと不一致' }
                $start = [Diagnostics.ProcessStartInfo]::new()
                $start.FileName = $config.codex
                $start.WorkingDirectory = $run
                $start.UseShellExecute = $false
                $start.CreateNoWindow = $true
                $start.RedirectStandardOutput = $true
                $start.RedirectStandardError = $true
                # PesterのTestDriveも許可領域内へ収め、ユーザー共通TEMPは許可しない。
                $tempCreatedNow = -not [IO.Directory]::Exists("$run/temp")
                $resultCreatedNow = -not [IO.File]::Exists("$root/controller/last-result.json")
                [void][IO.Directory]::CreateDirectory("$run/temp")
                $start.Environment['TEMP'] = "$run/temp"
                $start.Environment['TMP'] = "$run/temp"
                foreach ($arg in @('sandbox','-C',$run,'-P','inspection','-c',$profile,$config.pwsh,'-NoProfile','-NonInteractive','-File',$probe,'-FixtureRoot',$root)) { [void]$start.ArgumentList.Add($arg) }
                $process = [Diagnostics.Process]::new()
                $process.StartInfo = $start
                [void]$process.Start()
                $stdout = $process.StandardOutput.ReadToEndAsync()
                $stderr = $process.StandardError.ReadToEndAsync()
                $process.WaitForExit()
                $result = @{exitCode=$process.ExitCode;stdout=$stdout.GetAwaiter().GetResult();stderr=$stderr.GetAwaiter().GetResult();connectionArtifacts=@(@{path="$run/temp";createdNow=$tempCreatedNow;role='試験専用TEMP'},@{path="$root/controller/last-result.json";createdNow=$resultCreatedNow;role='接続の結果記録'})}
                [IO.File]::WriteAllText("$root/controller/last-result.json",($result | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
                $response.result=@{isError=($result.exitCode -ne 0);content=@(@{type='text';text=($result | ConvertTo-Json -Depth 8 -Compress)})}
                $process.Dispose()
            }
            default { $response.error=@{code=-32601;message='Unsupported method'} }
        }
    } catch {
        $errorCode = if ($null -eq $request) { -32700 } else { -32602 }
        $response=@{jsonrpc='2.0';id=$request.id;error=@{code=$errorCode;message=$_.Exception.Message}}
    }
    [Console]::WriteLine(($response | ConvertTo-Json -Depth 15 -Compress))
}
