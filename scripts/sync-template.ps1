# sync-template.ps1
# template.manifest に基づいてリポジトリ直下から template/ へ完全同期する
# 使い方: pwsh scripts/sync-template.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repoRoot "template.manifest"
$templateDir = Join-Path $repoRoot "template"
$adrIndexSource = Join-Path $repoRoot "docs" "decisions" "README.md"
$adrIndexDest = Join-Path $templateDir "docs" "decisions" "README.md"

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
Write-Host "[sync-template] Syncing $($files.Count) files + ADR index..."

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

# ADRインデックスの空版を生成
if (Test-Path $adrIndexSource) {
    $destDir = Split-Path -Parent $adrIndexDest
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $lines = Get-Content $adrIndexSource
    $outputLines = @()
    $inTable = $false
    $headerDone = $false

    foreach ($line in $lines) {
        if (-not $inTable) {
            $outputLines += $line
            # テーブルヘッダー行を検出（| # | タイトル |...）
            if ($line -match '^\|\s*#\s*\|') {
                $inTable = $true
            }
        } else {
            if (-not $headerDone) {
                # セパレーター行（|---|---|...）を保持
                if ($line -match '^\|[-\s|]+\|') {
                    $outputLines += $line
                    $headerDone = $true
                }
            }
            # データ行（| [NNNN]... |）は除外
        }
    }

    $outputLines | Set-Content -Path $adrIndexDest -Encoding UTF8
    Write-Host "  ✓ docs/decisions/README.md (empty index generated)"
} else {
    Write-Warning "  ! docs/decisions/README.md not found, skipping ADR index"
}

$totalFiles = $files.Count + 1  # マニフェストのファイル数 + ADRインデックス
Write-Host "[sync-template] Done. $totalFiles files synced to template/"
