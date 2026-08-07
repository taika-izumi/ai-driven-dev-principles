# sync-template.ps1
# template.manifest に基づいてリポジトリ直下から template/ へ完全同期する
# 使い方: pwsh scripts/sync-template.ps1 [-Check] (PowerShell 5.1でも動作可)

param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "template.manifest"
$templateDir = Join-Path $repoRoot "template"
. (Join-Path $PSScriptRoot 'lib/strip-provenance.ps1')

# 空インデックス生成対象（repo固有のデータ行を除去してコピーする。ADR-0027）
$emptyIndexTargets = @(
    "docs/records/decisions/README.md",
    "docs/records/retrospectives/README.md",
    "docs/working/issues/README.md"
)

function New-EmptyIndexContent {
    param(
        [string[]]$Lines
    )

    $output = New-Object System.Collections.Generic.List[string]
    $i = 0
    $n = $Lines.Count
    $inTable = $false
    $awaitingSeparator = $false

    while ($i -lt $n) {
        $line = $Lines[$i]

        if ($inTable) {
            if ($awaitingSeparator) {
                if ($line -match '^\|[-\s|]+\|$') {
                    # セパレーター行は保持
                    $output.Add($line)
                    $awaitingSeparator = $false
                    $i++
                    continue
                } else {
                    # ヘッダー直後がセパレーターでない → テーブルとして扱わず、この行を再評価する
                    $awaitingSeparator = $false
                    $inTable = $false
                }
            } elseif ($line -match '^\|') {
                # データ行 → 除外
                $i++
                continue
            } else {
                # テーブル終了。直後の空行 + 引用ブロック（repo固有の注記）があれば併せて除外する
                $inTable = $false

                $j = $i
                while ($j -lt $n -and $Lines[$j].Trim() -eq '') {
                    $j++
                }
                if ($j -lt $n -and $Lines[$j] -match '^>') {
                    $k = $j
                    while ($k -lt $n -and $Lines[$k] -match '^>') {
                        $k++
                    }
                    $i = $k
                    continue
                }
                # 引用ブロックがなければこの行を通常処理へフォールスルーさせる（インクリメントしない）
            }
        }

        if (-not $inTable) {
            if ($line -match '^\|' -and $line -notmatch '^\|[-\s|]+\|$') {
                # テーブルヘッダー行（| ... | 形式で、セパレーターではないもの）
                $output.Add($line)
                $inTable = $true
                $awaitingSeparator = $true
                $i++
                continue
            } else {
                $output.Add($line)
                $i++
                continue
            }
        }
    }

    # 除去処理で残った連続空行を1行に折り畳む
    $collapsed = New-Object System.Collections.Generic.List[string]
    $prevBlank = $false
    foreach ($outLine in $output) {
        $isBlank = ($outLine.Trim() -eq '')
        if ($isBlank -and $prevBlank) {
            continue
        }
        $collapsed.Add($outLine)
        $prevBlank = $isBlank
    }

    return ,$collapsed.ToArray()
}

# マニフェスト読み込み
if (-not (Test-Path $manifestPath)) {
    Write-Error "[sync-template] template.manifest not found at $manifestPath"
    exit 1
}

$files = Get-Content $manifestPath |
    Where-Object { $_ -match '\S' } |
    Where-Object { $_ -notmatch '^\s*#' } |
    ForEach-Object { $_.Trim() }

Write-Host "[sync-template] Reading template.manifest..."
Write-Host "[sync-template] Syncing $($files.Count) files + $($emptyIndexTargets.Count) empty indexes..."

# 1〜2. manifest 記載ファイルと空インデックスの内容を集める
$pending = [ordered]@{}
foreach ($file in $files) {
    $sourcePath = Join-Path $repoRoot $file
    if (-not (Test-Path $sourcePath)) { Write-Warning "  ! $file not found, skipping"; continue }
    $pending[$file] = [System.IO.File]::ReadAllText($sourcePath)
}
foreach ($target in $emptyIndexTargets) {
    $sourcePath = Join-Path $repoRoot $target
    if (-not (Test-Path $sourcePath)) { Write-Warning "  ! $target not found, skipping"; continue }
    $lines = Get-Content $sourcePath
    $pending[$target] = ((New-EmptyIndexContent -Lines $lines) -join "`n") + "`n"
}

# 3. 全件判定（違反があれば template/ を触らずに停止する）
$violations = New-Object System.Collections.Generic.List[object]
foreach ($k in $pending.Keys) {
    foreach ($v in (Test-ProvenanceConvention -Content $pending[$k] -Path $k)) {
        $violations.Add([pscustomobject]@{ Path=$k; Line=$v.Line; Rule=$v.Rule; Text=$v.Text })
    }
}
if ($violations.Count -gt 0) {
    Write-Host "[sync-template] Convention violations: $($violations.Count)"
    foreach ($v in $violations) { Write-Host "  ! $($v.Path):$($v.Line)  $($v.Rule)"; Write-Host "      $($v.Text)" }
    Write-Host '[sync-template] Aborted. template/ was not modified.'
    exit 1
}

# 4. 変換を適用した最終内容を作る
$generated = [ordered]@{}
foreach ($k in $pending.Keys) { $generated[$k] = (Remove-ProvenanceNotation -Content $pending[$k] -Path $k) }

if ($Check) {
    $existing = @{}
    $bomFiles = New-Object System.Collections.Generic.List[string]
    if (Test-Path $templateDir) {
        foreach ($f in (Get-ChildItem -Path $templateDir -Recurse -File)) {
            $rel = $f.FullName.Substring($templateDir.Length + 1) -replace '\\', '/'
            $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                $bomFiles.Add($rel)
            }
            $existing[$rel] = ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText($f.FullName))
        }
    }
    $diff = 0
    foreach ($k in $generated.Keys) {
        if (-not $existing.ContainsKey($k)) { Write-Host "  ! missing in template/: $k"; $diff++; continue }
        if ($existing[$k] -ne $generated[$k]) { Write-Host "  ! content differs: $k"; $diff++ }
    }
    foreach ($k in $existing.Keys) { if (-not $generated.Contains($k)) { Write-Host "  ! stale file: $k"; $diff++ } }
    foreach ($rel in $bomFiles) { Write-Host "  ! BOM found: $rel"; $diff++ }
    foreach ($k in $generated.Keys) {
        foreach ($lk in (Get-ProvenanceLeak -Content $generated[$k] -Path $k)) {
            Write-Host "  ! identifier remains: ${k}:$($lk.Line)  $($lk.Text)"; $diff++
        }
    }
    if ($diff -gt 0) { Write-Host "[sync-template] Out of date: $diff difference(s)."; exit 1 }
    Write-Host '[sync-template] Up to date.'
    exit 0
}

Write-Host "[sync-template] Cleaning template/ ..."
if (Test-Path $templateDir) { Remove-Item -Recurse -Force $templateDir }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($k in $generated.Keys) {
    $destPath = Join-Path $templateDir $k
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($destPath, $generated[$k], $utf8NoBom)
    Write-Host "  ✓ $k"
}

$totalFiles = $generated.Count
Write-Host "[sync-template] Done. $totalFiles files synced to template/"

# template/ の自己検査（ADR-0083。build-dist.ps1 の自己検査と同じ形）
$leak = 0
foreach ($f in (Get-ChildItem -Path $templateDir -Recurse -File)) {
    $rel = $f.FullName.Substring($templateDir.Length + 1) -replace '\\', '/'
    $content = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($lk in (Get-ProvenanceLeak -Content $content -Path $rel)) {
        Write-Host "  ! identifier remains: ${rel}:$($lk.Line)  $($lk.Text)"; $leak++
    }
}
if ($leak -gt 0) { Write-Host "[sync-template] Self-check failed: $leak identifier(s) remain in template/."; exit 1 }

# CLAUDE.md 規模計測（ADR-0040。警告のみで同期はブロックしない）
& (Join-Path $PSScriptRoot "check-claude-md-size.ps1")
