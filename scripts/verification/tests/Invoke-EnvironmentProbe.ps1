param(
    [Parameter(Mandatory)][string]$CodexPath,
    [Parameter(Mandatory)][string]$PwshPath,
    [Parameter(Mandatory)][string]$ProbeRoot,
    [switch]$IncludeAgentProbe,
    [string]$Model,
    [ValidateSet('elevated','unelevated')][string]$WindowsSandbox,
    [ValidateSet('sandbox','app-server')][string]$ExecutionPath='sandbox'
)
# タスク0の前提検査。起動失敗は保護成功にならず、証拠を残して非ゼロ終了する。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
foreach ($path in @($CodexPath,$PwshPath,$ProbeRoot)) {
    Assert-True ([IO.Path]::IsPathFullyQualified($path)) '絶対パスが必要'
}
Assert-True ([IO.File]::Exists($CodexPath)) 'Codex実行ファイルが必要'
Assert-True ([IO.File]::Exists($PwshPath)) 'PowerShell実行ファイルが必要'
Assert-True (-not (Test-Path -LiteralPath $ProbeRoot)) '既存の試験領域を再利用しない'
$ProbeRoot = [IO.Path]::GetFullPath($ProbeRoot)
for ($parent = [IO.DirectoryInfo]::new($ProbeRoot).Parent; $null -ne $parent; $parent = $parent.Parent) {
    if ($parent.Exists -and ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw '試験領域の祖先に再解析ポイントがある'
    }
}
$control = Join-Path $ProbeRoot 'control'
foreach ($directory in @('work','temp','control','source','shared','records','empty-template')) {
    [void][IO.Directory]::CreateDirectory((Join-Path $ProbeRoot $directory))
}
$result = [ordered]@{
    status='incomplete'; probeRoot=$ProbeRoot; codexVersion=$null; pwshVersion=$PSVersionTable.PSVersion.ToString()
    steps=@(); protectedBefore=@{}; protectedAfter=@{}; sandboxPassed=$false
    agentProbe=@{status='unverified'; reason='AIなしの試験後にexec構成を確認する'}
    error=$null
}
function Save-ProbeJson([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 25), [Text.UTF8Encoding]::new($false))
}
function Invoke-ProbeProcess([string]$File, [string[]]$Arguments, [string]$Name, [int]$TimeoutSeconds=30) {
    $start = [Diagnostics.ProcessStartInfo]::new($File)
    $start.WorkingDirectory = Join-Path $ProbeRoot 'work'
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.Environment['TEMP'] = Join-Path $ProbeRoot 'temp'
    $start.Environment['TMP'] = Join-Path $ProbeRoot 'temp'
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    $entry = @{name=$Name; file=$File; arguments=$Arguments; started=$false; exitCode=$null; timedOut=$false; stdout=''; stderr=''}
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    try {
        [void]$process.Start()
        $entry.started = $true
        $out = $process.StandardOutput.ReadToEndAsync()
        $err = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $entry.timedOut = $true
            $process.Kill($true)
            if (-not $process.WaitForExit(5000)) { throw '試験プロセスの停止未確認' }
        }
        $entry.stdout = $out.GetAwaiter().GetResult()
        $entry.stderr = $err.GetAwaiter().GetResult()
        $entry.exitCode = $process.ExitCode
    } catch { $entry.stderr += $_.Exception.Message }
    finally {
        $process.Dispose()
        Save-ProbeJson (Join-Path $control "$Name.json") $entry
    }
    $result.steps += $entry
    return $entry
}
function Assert-ProbeRows($Data, [bool]$Restricted) {
    Assert-Equal $Data.writes.Count $(if ($Restricted) { 7 } else { 2 }) '試行件数'
    foreach ($write in $Data.writes) {
        $allowed = $write.path -match '^(work|temp)/(parent|child)\.txt$'
        Assert-Equal $write.write $(if ($allowed) { 'allowed' } else { 'denied' }) $write.path
    }
    Assert-Equal $Data.network.connected (-not $Restricted) '通信の正負対照'
    if ($Restricted) {
        Assert-True $Data.link.created '新規リンク経由の試験を実行できた'
        Assert-Equal $Data.link.write.write 'denied' '新規リンク経由の保護'
    }
}
$listener = $null
try {
    $version = Invoke-ProbeProcess $CodexPath @('--version') 'codex-version'
    Assert-Equal $version.exitCode 0 'Codex版の取得'
    $result.codexVersion = $version.stdout.Trim()
    foreach ($command in @('exec','sandbox')) {
        $help = Invoke-ProbeProcess $CodexPath @($command,'--help') "$command-help"
        Assert-Equal $help.exitCode 0 "$command ヘルプ取得"
    }
    $git = (Get-Command git -ErrorAction Stop).Source
    $init = Invoke-ProbeProcess $git @('init','--quiet',('--template=' + (Join-Path $ProbeRoot 'empty-template'))) 'git-init'
    Assert-Equal $init.exitCode 0 '空テンプレートで試験Gitを初期化'
    foreach ($relative in @('control/sentinel.txt','source/sentinel.txt','shared/sentinel.txt','records/sentinel.txt','work/.git/sentinel.txt')) {
        $path = Join-Path $ProbeRoot $relative
        [IO.File]::WriteAllText($path, "baseline:$relative")
        $result.protectedBefore[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
    $boundary = Join-Path $control 'BoundaryProbe.ps1'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures/BoundaryProbe.ps1') -Destination $boundary
    $result.protectedBefore['control/BoundaryProbe.ps1'] = (Get-FileHash -LiteralPath $boundary).Hash
    $normalized = $ProbeRoot.Replace('\','/')
    # JSONの文字列引用はTOMLの基本文字列として使い、パスをキーのドット区切りへ展開しない。
    $permissions = 'permissions.inspection={extends=":read-only",filesystem={' +
        (($normalized + '/work' | ConvertTo-Json -Compress) + '="write",') +
        (($normalized + '/temp' | ConvertTo-Json -Compress) + '="write",') +
        (($normalized + '/control' | ConvertTo-Json -Compress) + '="read",') +
        (($normalized + '/work/.git' | ConvertTo-Json -Compress) + '="read"},network={enabled=false}}')
    Save-ProbeJson (Join-Path $control 'profile.json') @{override=$permissions; profile='inspection'}
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $argsBase = @('-NoProfile','-NonInteractive','-File',$boundary,'-ProbeRoot',$ProbeRoot,'-Port',"$port")
    $before = Invoke-ProbeProcess $PwshPath ($argsBase + '-AllowOnly') 'normal-before'
    Assert-Equal $before.exitCode 0 '通常実行の正の対照'
    $normal = $before.stdout | ConvertFrom-Json
    Assert-ProbeRows $normal $false
    Assert-Equal $normal.child.exitCode 0 '通常子プロセスの起動'
    Assert-ProbeRows ($normal.child.stdout | ConvertFrom-Json) $false
    $sandboxArgs = @('sandbox','-P','inspection','-C',(Join-Path $ProbeRoot 'work'),'-c',$permissions)
    if ($WindowsSandbox) { $sandboxArgs += @('-c', ('windows.sandbox="' + $WindowsSandbox + '"')) }
    if ($ExecutionPath -eq 'app-server') {
        Assert-True (-not [string]::IsNullOrEmpty($WindowsSandbox)) '比較用APIはWindows方式を明示する'
        $limited = Invoke-ProbeProcess $PwshPath @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'fixtures/AppServerBoundary.ps1'),'-CodexPath',$CodexPath,'-PwshPath',$PwshPath,'-ProbeRoot',$ProbeRoot,'-Permissions',$permissions,'-Port',"$port",'-WindowsSandbox',$WindowsSandbox) 'sandbox-boundary' 55
    } else {
        $limited = Invoke-ProbeProcess $CodexPath ($sandboxArgs + $PwshPath + $argsBase) 'sandbox-boundary'
    }
    # 拒否側失敗でも正の対照を取り、接続先停止による偽の拒否を排除する。
    $after = Invoke-ProbeProcess $PwshPath ($argsBase + '-AllowOnly') 'normal-after'
    Assert-Equal $after.exitCode 0 '試験後の正の対照'
    $normalAfter = $after.stdout | ConvertFrom-Json
    Assert-ProbeRows $normalAfter $false
    Assert-Equal $normalAfter.child.exitCode 0 '試験後の通常子プロセス'
    Assert-ProbeRows ($normalAfter.child.stdout | ConvertFrom-Json) $false
    Assert-Equal $limited.exitCode 0 '制限付きプロセスが実際に起動した'
    Assert-True (-not $limited.timedOut) '制限付き試験が時間内に終了'
    $data = $limited.stdout | ConvertFrom-Json
    Assert-ProbeRows $data $true
    Assert-Equal $data.child.exitCode 0 '制限付き子プロセスが実際に起動した'
    Assert-ProbeRows ($data.child.stdout | ConvertFrom-Json) $true
    $result.sandboxPassed = $true
    # execの設定読込範囲の確認前にモデルを起動しない。未確認を明示して後続を阻止する。
    if ($IncludeAgentProbe) {
        Assert-True (-not [string]::IsNullOrWhiteSpace($Model)) '実モデルの指定が必要'
        $result.agentProbe.reason = 'execの自動読込設定と別経路の制限を未確認。AI試験は未実装'
        throw $result.agentProbe.reason
    }
    $result.status = 'sandbox_passed_agent_unverified'
} catch { $result.error = $_.Exception.Message }
finally {
    if ($null -ne $listener) { $listener.Stop() }
    foreach ($relative in @($result.protectedBefore.Keys)) {
        $path = Join-Path $ProbeRoot $relative
        $result.protectedAfter[$relative] = if ([IO.File]::Exists($path)) { (Get-FileHash -LiteralPath $path).Hash } else { $null }
        if ($result.protectedAfter[$relative] -cne $result.protectedBefore[$relative]) {
            $result.status = 'protection_failed'
            $result.sandboxPassed = $false
            $result.error = "保護対象が変化: $relative"
        }
    }
    Save-ProbeJson (Join-Path $control 'environment-result.json') $result
    [Console]::Out.WriteLine((Join-Path $control 'environment-result.json'))
}
if ($result.status -eq 'sandbox_passed_agent_unverified' -and -not $IncludeAgentProbe) { exit 0 }
exit 2
