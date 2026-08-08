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
$pluginJsonPath = Join-Path $repoRoot '.claude-plugin/plugin.json'
$pluginRel = '.claude-plugin/plugin.json'

# 相対パス算出のヘルパ（M-3: 同じ算出式が複数箇所に重複していたのを1本化）
function Get-RepoRelativePath {
    param([string]$FullName)
    return ($FullName.Substring($repoRoot.Length + 1) -replace '\\', '/')
}

# plugin.json が無い状態で .NET の例外スタックを生で出さないよう、先に固有メッセージで止める（M-6）
if (-not (Test-Path $pluginJsonPath)) {
    Write-Host "[build-dist] plugin.json not found: $pluginJsonPath"
    exit 1
}

# 1. 走査対象を集める（@() で囲む。1 件・0 件のとき .Count が使えなくなるのを防ぐ）
$sources = @(Get-ChildItem -Path $srcDir -Recurse -File | Sort-Object FullName)

# 2. 規約判定と変換を1ループで行う（M-4: 判定用・変換用でファイルを2回読んでいたのを解消）。
#    ここで組み立てる $generated / $removedInfo は、違反が見つかった場合は使わずに捨てる
#    （書き込みは後段でのみ行うため、この時点では dist/ に一切触れていない＝不変が保たれる）。
Write-Host "[build-dist] Scanning $($sources.Count) source files..."
$allViolations = New-Object System.Collections.Generic.List[object]
$generated = [ordered]@{}
$removedInfo = New-Object System.Collections.Generic.List[object]

foreach ($f in $sources) {
    $rel = Get-RepoRelativePath -FullName $f.FullName
    $content = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($v in (Test-ProvenanceConvention -Content $content -Path $rel)) {
        $allViolations.Add([pscustomobject]@{ Path=$rel; Line=$v.Line; Rule=$v.Rule; Text=$v.Text })
    }
    $converted = Remove-ProvenanceNotation -Content $content -Path $rel
    # 除去数を数えて per-file で出す（spec 02「標準出力」の形。差分確認の手掛かりになる）
    $before = 0; $after = 0
    foreach ($l in ((ConvertTo-LfContent -Content $content) -split "`n")) { $before += (Get-IdentifierMatch -Line $l).Count }
    foreach ($l in ($converted -split "`n"))                             { $after  += (Get-IdentifierMatch -Line $l).Count }
    $removed = $before - $after
    $generated["dist/$rel"] = $converted
    if ($removed -gt 0) { $removedInfo.Add([pscustomobject]@{ Path=$rel; Removed=$removed }) }
}

# plugin.json も LF 正規化の対象に入れる（I-2）。CRLF のまま複写される問題を解消する。
# plugin.json は Remove-ProvenanceNotation を通さず「複写」するため、書き込み前検査には
# Test-ProvenanceConvention ではなく Get-ProvenanceLeak を使う（I-5）。
# Test-ProvenanceConvention は全角括弧内の識別子を 'ok'（＝変換で除去される前提）として扱うが、
# plugin.json は変換されない複写物であるため、括弧内の種別 1〜4 がこの判定では素通りし、
# dist/ 全削除・書き出し後の自己検査まで検出が遅れて git 管理下の dist/ が汚れた状態で残る
# 問題があった（実証済み）。「規約適合か」ではなく「識別子が残っているか」を問う必要がある。
$pluginContent = ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText($pluginJsonPath))
$pluginLeaks = Get-ProvenanceLeak -Content $pluginContent -Path $pluginRel
$generated["dist/$pluginRel"] = $pluginContent

Write-Host "[build-dist] Convention violations: $($allViolations.Count)"
if ($allViolations.Count -gt 0) {
    foreach ($v in $allViolations) {
        Write-Host "  ! $($v.Path):$($v.Line)  $($v.Rule)"
        Write-Host "      $($v.Text)"
    }
}
if ($pluginLeaks.Count -gt 0) {
    foreach ($lk in $pluginLeaks) {
        Write-Host "  ! identifier in ${pluginRel}:$($lk.Line)  $($lk.Text)"
    }
}
if ($allViolations.Count -gt 0 -or $pluginLeaks.Count -gt 0) {
    Write-Host '[build-dist] Aborted. dist/ was not modified.'
    exit 1
}

# M-10: ファイル別の除去数（✓ 行）は、違反ゼロを確認した直後・-Check の早期分岐より前に出す。
# spec 02 は「Generating 行より前に並び、書き込みを行わない -Check でも表示される」と定めている。
foreach ($info in $removedInfo) { Write-Host "  ✓ $($info.Path) ($($info.Removed) identifiers removed)" }

# 3. -Check: 既存 dist/ と突合する
if ($Check) {
    $existing = @{}
    $bomFiles = New-Object System.Collections.Generic.List[string]
    if (Test-Path $distDir) {
        foreach ($f in (Get-ChildItem -Path $distDir -Recurse -File)) {
            $rel = Get-RepoRelativePath -FullName $f.FullName
            # M-8: ReadAllText は BOM を剥がしてしまうため、BOM の有無はバイト列で別途検出する
            $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                $bomFiles.Add($rel)
            }
            # I-1: $generated は LF 正規化済みのため、比較対象も正規化してから突合する。
            # 正規化しないと CRLF チェックアウト環境（core.autocrlf=true）で全ファイルが
            # 「陳腐化」と誤検出される（実証済み）。
            $existing[$rel] = ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText($f.FullName))
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
    foreach ($rel in $bomFiles) { Write-Host "  ! BOM found: $rel"; $diff++ }
    # Rec 1: 突合だけでは「ソースと dist/ が両方漏れを含む」場合に一致してしまい exit=0 を返す。
    # -Check は書き込みを行わないため、既定モードの書き出し後自己検査（後段の Step 5）が走らない。
    # ここで再生成した内容（$generated）そのものへ残存識別子検査を掛け、-Check 単独実行でも
    # 「配布物に実在識別子 0 件」を担保する。
    foreach ($k in $generated.Keys) {
        foreach ($lk in (Get-ProvenanceLeak -Content $generated[$k] -Path $k)) {
            Write-Host "  ! identifier remains: ${k}:$($lk.Line)  $($lk.Text)"; $diff++
        }
    }
    if ($diff -gt 0) { Write-Host "[build-dist] Out of date: $diff difference(s). Run build-dist.ps1."; exit 1 }
    Write-Host '[build-dist] Up to date.'
    exit 0
}

# 4. 書き出し（完全削除してから作り直す）
Write-Host '[build-dist] Generating dist/ ...'
if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
foreach ($k in $generated.Keys) {
    $dest = Join-Path $repoRoot $k
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($dest, $generated[$k], $utf8)   # LF 固定・BOM なし（ADR-0033）
}

# 5. 自己検査（I-3/M-2: ライブラリの Get-ProvenanceLeak を使う。判定と同じ適用範囲・同じ
#    プレースホルダ判別に加え、種別 5 もここで検出する。従来はライブラリのロジックを
#    build-dist.ps1 側へ逐語コピーしており、片方だけ直すと乖離する問題があった）
$leak = 0
foreach ($f in (Get-ChildItem -Path $distDir -Recurse -File)) {
    $rel = Get-RepoRelativePath -FullName $f.FullName
    $content = [System.IO.File]::ReadAllText($f.FullName)
    foreach ($lk in (Get-ProvenanceLeak -Content $content -Path $rel)) {
        Write-Host "  ! identifier remains: ${rel}:$($lk.Line)  $($lk.Text)"; $leak++
    }
}
if ($leak -gt 0) { Write-Host "[build-dist] Self-check failed: $leak identifier(s) remain in dist/."; exit 1 }

Write-Host "[build-dist] Done. $($generated.Count) files written to dist/."
