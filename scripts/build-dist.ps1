# scripts/build-dist.ps1
# skills/ から出所識別子を除去した配布物を dist/ へ生成する（ADR-0082 / ADR-0083）。
# 使い方: pwsh scripts/build-dist.ps1 [-Check]

param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/strip-provenance.ps1')

$srcDir  = Join-Path $repoRoot 'skills'
$distDir = Join-Path $repoRoot 'dist'
$utf8    = New-Object System.Text.UTF8Encoding($false)

# 1. 走査対象を集める（@() で囲む。1 件・0 件のとき .Count が使えなくなるのを防ぐ）
$sources = @(Get-ChildItem -Path $srcDir -Recurse -File | Sort-Object FullName)

# 2. 規約判定（全件先に判定し、違反があれば書き込む前に停止する）
Write-Host "[build-dist] Scanning $($sources.Count) source files..."
$allViolations = New-Object System.Collections.Generic.List[object]
foreach ($f in $sources) {
    $rel = $f.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
    $content = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($v in (Test-ProvenanceConvention -Content $content -Path $rel)) {
        $allViolations.Add([pscustomobject]@{ Path=$rel; Line=$v.Line; Rule=$v.Rule; Text=$v.Text })
    }
}
Write-Host "[build-dist] Convention violations: $($allViolations.Count)"
if ($allViolations.Count -gt 0) {
    foreach ($v in $allViolations) {
        Write-Host "  ! $($v.Path):$($v.Line)  $($v.Rule)"
        Write-Host "      $($v.Text)"
    }
    Write-Host '[build-dist] Aborted. dist/ was not modified.'
    exit 1
}

# 3. 生成物の内容を組み立てる（ファイル相対パス → 内容）
$generated = [ordered]@{}
$removedTotal = 0
foreach ($f in $sources) {
    $rel = $f.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $converted = Remove-ProvenanceNotation -Content $content -Path $rel
    # 除去数を数えて per-file で出す（spec 02「標準出力」の形。差分確認の手掛かりになる）
    $before = 0; $after = 0
    foreach ($l in ((ConvertTo-LfContent -Content $content) -split "`n")) { $before += (Get-IdentifierMatch -Line $l).Count }
    foreach ($l in ($converted -split "`n"))                             { $after  += (Get-IdentifierMatch -Line $l).Count }
    $removed = $before - $after; $removedTotal += $removed
    $generated["dist/$rel"] = $converted
    if ($removed -gt 0) { Write-Host "  ✓ $rel ($removed identifiers removed)" }
}
# プラグイン定義を複写する（dist/ は毎回作り直すため、生成器が書き出す責務を持つ）
$pluginJson = Join-Path $repoRoot '.claude-plugin/plugin.json'
$generated['dist/.claude-plugin/plugin.json'] = [System.IO.File]::ReadAllText($pluginJson)

# 4. -Check: 既存 dist/ と突合する
if ($Check) {
    $existing = @{}
    if (Test-Path $distDir) {
        foreach ($f in (Get-ChildItem -Path $distDir -Recurse -File)) {
            $rel = $f.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
            $existing[$rel] = [System.IO.File]::ReadAllText($f.FullName)
        }
    }
    $diff = 0
    foreach ($k in $generated.Keys) {
        if (-not $existing.ContainsKey($k)) { Write-Host "  ! missing in dist/: $k"; $diff++ ; continue }
        if ($existing[$k] -ne $generated[$k]) { Write-Host "  ! content differs: $k"; $diff++ }
    }
    foreach ($k in $existing.Keys) {
        if (-not $generated.Contains($k)) { Write-Host "  ! stale file in dist/: $k"; $diff++ }
    }
    if ($diff -gt 0) { Write-Host "[build-dist] Out of date: $diff difference(s). Run build-dist.ps1."; exit 1 }
    Write-Host '[build-dist] Up to date.'
    exit 0
}

# 5. 書き出し（完全削除してから作り直す）
Write-Host '[build-dist] Generating dist/ ...'
if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
foreach ($k in $generated.Keys) {
    $dest = Join-Path $repoRoot $k
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($dest, $generated[$k], $utf8)   # LF 固定・BOM なし（ADR-0033）
}

# 6. 自己検査（判定と同じ適用範囲・同じプレースホルダ判別を使う）
$leak = 0
foreach ($f in (Get-ChildItem -Path $distDir -Recurse -File)) {
    $rel = $f.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $isScript = $rel -match '\.(py|ps1)$'
    $inFence = $false; $i = 0
    foreach ($line in ($content -split "`n")) {
        $i++
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($inFence -or ($isScript -and -not $line.TrimStart().StartsWith('#'))) { continue }
        if ((Get-IdentifierMatch -Line $line).Count -gt 0) {
            Write-Host "  ! identifier remains: ${rel}:${i}  $($line.Trim())"; $leak++
        }
    }
}
if ($leak -gt 0) { Write-Host "[build-dist] Self-check failed: $leak identifier(s) remain in dist/."; exit 1 }

Write-Host "[build-dist] Done. $($generated.Count) files written to dist/."
