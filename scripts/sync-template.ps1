# sync-template.ps1
# template.manifest に基づいてリポジトリ直下から template/ へ完全同期する
# 使い方: pwsh scripts/sync-template.ps1 (PowerShell 5.1でも動作可)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "template.manifest"
$templateDir = Join-Path $repoRoot "template"

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

Write-Host "[sync-template] Cleaning template/ ..."
if (Test-Path $templateDir) {
    Remove-Item -Recurse -Force $templateDir
}

Write-Host "[sync-template] Reading template.manifest..."
Write-Host "[sync-template] Syncing $($files.Count) files + $($emptyIndexTargets.Count) empty indexes..."

foreach ($file in $files) {
    $sourcePath = Join-Path $repoRoot $file
    $destPath = Join-Path $templateDir $file

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "  ! $file not found, skipping"
        continue
    }

    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "  ✓ $file"
}

# 空インデックスの生成（ADR-0027）
foreach ($target in $emptyIndexTargets) {
    $sourcePath = Join-Path $repoRoot $target
    $destPath = Join-Path $templateDir $target

    if (-not (Test-Path $sourcePath)) {
        Write-Warning "  ! $target not found, skipping empty index generation"
        continue
    }

    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $lines = Get-Content $sourcePath
    $outputLines = New-EmptyIndexContent -Lines $lines

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($destPath, $outputLines, $utf8NoBom)
    Write-Host "  ✓ $target (empty index generated)"
}

$totalFiles = $files.Count + $emptyIndexTargets.Count
Write-Host "[sync-template] Done. $totalFiles files synced to template/"
