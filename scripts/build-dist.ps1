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
$marketplaceJsonPath = Join-Path $repoRoot '.claude-plugin/marketplace.json'
$marketplaceRel = '.claude-plugin/marketplace.json'

# 相対パス算出のヘルパ（M-3: 同じ算出式が複数箇所に重複していたのを1本化）
function Get-RepoRelativePath {
    param([string]$FullName)
    return ($FullName.Substring($repoRoot.Length + 1) -replace '\\', '/')
}

# JSON の欠損プロパティを Set-StrictMode の例外ではなく $null で受ける（例外スタックを
# 生で出さず接頭辞つきの診断で止めるため）
function Get-JsonProperty {
    param($Object, [string]$Name)
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $null
}

# 不正な JSON で .NET の例外スタックを生で出さず、接頭辞つきの診断で止める（M-6 と同じ方針）。
function ConvertFrom-JsonText {
    param([string]$Text, [string]$Rel)
    try { return $Text | ConvertFrom-Json }
    catch {
        Write-Host "[build-dist] invalid JSON: $Rel ($($_.Exception.Message))"
        exit 1
    }
}

# 正本 JSON から必須の文字列値を取り出す唯一の経路。ConvertTo-JsonStringValue の
# [string] パラメータは object を "@{...}"、$null を空文字へ黙って変換するため、
# 素通りさせると構文的に妥当な JSON へ壊れた値が埋まる。-Check は生成器出力との
# 自己突合であり、壊れた値は恒久的に自己一致してしまう（ADR-0113）。
function Get-RequiredJsonString {
    param($Object, [string]$Name, [string]$Rel, [string]$Label)
    $v = Get-JsonProperty $Object $Name
    if ($null -eq $v -or $v -isnot [string] -or [string]::IsNullOrWhiteSpace($v)) {
        $what = if ($null -eq $v) { 'missing' } elseif ($v -isnot [string]) { $v.GetType().Name } else { 'empty' }
        Write-Host "[build-dist] $Label must be a non-empty string: $Rel ($what)"
        Write-Host '[build-dist] Aborted. Generated artifacts were not modified.'
        exit 1
    }
    return $v
}

# Codex 向け生成物の固定マッピング。正本 JSON に対応キーが無いため生成器内で与える。
# 値は Codex ネイティブ marketplace の実例に合わせている（確認日 2026-08-25 /
# codex-cli 0.149.0-alpha.4.3）。
$codexDisplayName          = 'AI-Driven Dev Principles'
$codexCategory             = 'Developer Tools'
$codexInstallationPolicy   = 'AVAILABLE'
$codexAuthenticationPolicy = 'ON_INSTALL'
$codexSkillsPath           = './skills/'

# 生成物を PowerShell のバージョン差（ConvertTo-Json の整形・非 ASCII エスケープの違い）へ
# 依存させないため、JSON はテンプレート組み立てで出力する。
function ConvertTo-JsonStringValue {
    param([string]$Value)
    $s = $Value -replace '\\', '\\'
    $s = $s -replace '"', '\"'
    $s = $s -replace "`r", '\r'
    $s = $s -replace "`n", '\n'
    $s = $s -replace "`t", '\t'
    return $s
}

function New-CodexMarketplaceContent {
    param($Source)
    $plugins = @(Get-JsonProperty $Source 'plugins')
    if ($plugins.Count -eq 0) {
        Write-Host "[build-dist] no plugins found in $marketplaceRel"
        exit 1
    }
    $entries = New-Object System.Collections.Generic.List[string]
    foreach ($p in $plugins) {
        $rawName = Get-JsonProperty $p 'name'
        $rawPath = Get-JsonProperty $p 'source'
        # 正本の source が object 形式（github 等）だと、暗黙の文字列変換で
        # "@{source=github; repo=o/r}" が path へ埋まり、構文的に妥当な JSON になるため
        # -Check も自己一致で通ってしまう。検出したら黙認せず停止する（ADR-0054）。
        if ([string]::IsNullOrWhiteSpace($rawName)) {
            Write-Host "[build-dist] plugin name is missing or empty in $marketplaceRel plugins[$($entries.Count)]"
            exit 1
        }
        if ($null -eq $rawPath -or $rawPath -isnot [string]) {
            $srcType = if ($null -eq $rawPath) { 'missing' } else { $rawPath.GetType().Name }
            Write-Host "[build-dist] plugin source must be a string path for the Codex marketplace: $marketplaceRel plugins[$($entries.Count)].source is $srcType"
            exit 1
        }
        $pName = ConvertTo-JsonStringValue $rawName
        $pPath = ConvertTo-JsonStringValue $rawPath
        $entries.Add(@"
    {
      "name": "$pName",
      "source": {
        "source": "local",
        "path": "$pPath"
      },
      "policy": {
        "installation": "$codexInstallationPolicy",
        "authentication": "$codexAuthenticationPolicy"
      },
      "category": "$codexCategory"
    }
"@)
    }
    $mpName = ConvertTo-JsonStringValue (Get-RequiredJsonString $Source 'name' $marketplaceRel 'name')
    $body = $entries -join ",`n"
    return @"
{
  "name": "$mpName",
  "interface": {
    "displayName": "$codexDisplayName"
  },
  "plugins": [
$body
  ]
}
"@
}

function New-CodexPluginContent {
    param($Source)
    $pName    = ConvertTo-JsonStringValue (Get-RequiredJsonString $Source 'name' $pluginRel 'name')
    $pVersion = ConvertTo-JsonStringValue (Get-RequiredJsonString $Source 'version' $pluginRel 'version')
    $pDesc    = ConvertTo-JsonStringValue (Get-RequiredJsonString $Source 'description' $pluginRel 'description')
    $pAuthor  = ConvertTo-JsonStringValue (Get-RequiredJsonString (Get-JsonProperty $Source 'author') 'name' $pluginRel 'author.name')
    return @"
{
  "name": "$pName",
  "version": "$pVersion",
  "description": "$pDesc",
  "author": {
    "name": "$pAuthor"
  },
  "skills": "$codexSkillsPath",
  "interface": {
    "displayName": "$codexDisplayName",
    "category": "$codexCategory"
  }
}
"@
}

# plugin.json が無い状態で .NET の例外スタックを生で出さないよう、先に固有メッセージで止める（M-6）
if (-not (Test-Path $pluginJsonPath)) {
    Write-Host "[build-dist] plugin.json not found: $pluginJsonPath"
    exit 1
}

if (-not (Test-Path $marketplaceJsonPath)) {
    Write-Host "[build-dist] marketplace.json not found: $marketplaceJsonPath"
    exit 1
}

# 0. version 一致検査。正本が 2 ファイルに分かれて version を二重保持しているため、
#    規約判定より前・両モード共通で突合する。-Check でも走らせないと執行点手順 2 の
#    ゲートにならない（ADR-0112）。
$pluginRawText = [System.IO.File]::ReadAllText($pluginJsonPath)
$pluginObj = ConvertFrom-JsonText -Text $pluginRawText -Rel $pluginRel
$marketplaceObj = ConvertFrom-JsonText -Text ([System.IO.File]::ReadAllText($marketplaceJsonPath)) -Rel $marketplaceRel
$srcVersion = Get-JsonProperty $pluginObj 'version'
if ($null -eq $srcVersion) {
    Write-Host "[build-dist] version not found in $pluginRel"
    exit 1
}
$marketplacePlugins = Get-JsonProperty $marketplaceObj 'plugins'
if ($null -eq $marketplacePlugins -or @($marketplacePlugins).Count -eq 0) {
    Write-Host "[build-dist] no plugins found in $marketplaceRel"
    exit 1
}
$versionMismatch = 0
$marketplacePluginIndex = 0
foreach ($p in @($marketplacePlugins)) {
    $pv = Get-JsonProperty $p 'version'
    if ($pv -ne $srcVersion) {
        $pn = Get-JsonProperty $p 'name'
        Write-Host "  ! version mismatch: $marketplaceRel plugins[$marketplacePluginIndex] ($pn) = $pv, $pluginRel = $srcVersion"
        $versionMismatch++
    }
    $marketplacePluginIndex++
}
if ($versionMismatch -gt 0) {
    Write-Host "[build-dist] Aborted. $versionMismatch version mismatch(es). Generated artifacts were not modified."
    exit 1
}

# 1. 走査対象を集める（@() で囲む。1 件・0 件のとき .Count が使えなくなるのを防ぐ）
$sources = @(Get-ChildItem -Path $srcDir -Recurse -File | Sort-Object FullName)

# 1.5 SKILL.md のサイズ計測（ADR-0121）。走査対象の収集直後・規約判定と -Check 分岐より前に置き、
#     通常実行と -Check の両モードで同じ計測が走ることを保証する。警告は非ブロック（終了コードを変えない）。
#     目安値の根拠と分割判断の手順は CONTRIBUTING.md「全シナリオ共通: SKILL.md のサイズと分割」が正本。
$skillSizeThreshold = 20000   # 目安値 20KB（1KB = 1000 バイト）
# 例外テーブル: スキル名 → 承認済みサイズ（バイト）。各行に判断根拠を必ず併記する。
# 承認済みサイズ以下は警告せず、それを超えて成長したら再警告する。引き上げは
# CONTRIBUTING.md の共通節が定める ①責務帰属型 →②references 型 →③例外登録 の判断を経てから行う。
$skillSizeExceptions = @{
    'session-handoff' = 31169   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0115）
    'decision-log'    = 26837   # 分割待ちの暫定行。根拠と追跡は起票済みの課題（Issue-0116）
}
$skillNormRef = 'CONTRIBUTING.md「全シナリオ共通: SKILL.md のサイズと分割」'
foreach ($skillDir in @(Get-ChildItem -Path $srcDir -Directory | Sort-Object Name)) {
    $skillMd = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $skillMd)) { continue }
    $skillBytes = (Get-Item $skillMd).Length
    $limit = $skillSizeThreshold
    $limitLabel = "目安値 $skillSizeThreshold"
    if ($skillSizeExceptions.ContainsKey($skillDir.Name)) {
        $limit = $skillSizeExceptions[$skillDir.Name]
        $limitLabel = "承認済みサイズ $limit"
    }
    if ($skillBytes -gt $limit) {
        $mdTotal = 0
        foreach ($md in @(Get-ChildItem -Path $skillDir.FullName -Recurse -File -Filter '*.md')) { $mdTotal += $md.Length }
        Write-Warning "[build-dist] $($skillDir.Name)/SKILL.md: $skillBytes bytes > ${limitLabel}。分割判断は ${skillNormRef}を参照してください。"
        Write-Warning "  - スキルディレクトリ配下の全 md 合計: $mdTotal bytes（参考値。出力雛形等も含む粗い値で、閾値は課さない）"
    }
}

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
$pluginContent = ConvertTo-LfContent -Content $pluginRawText
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

# Codex 向けの 2 生成物。dist/ 配下のものは既存の wipe・stale 検出・自己検査が
# そのまま覆う。ルート直下のものは $rootGenerated で別に扱う（ADR-0112）。
$generated["dist/.codex-plugin/plugin.json"] =
    (ConvertTo-LfContent -Content (New-CodexPluginContent -Source $pluginObj)) + "`n"

$rootGenerated = [ordered]@{}
$rootGenerated['.agents/plugins/marketplace.json'] =
    (ConvertTo-LfContent -Content (New-CodexMarketplaceContent -Source $marketplaceObj)) + "`n"

# ルート生成物にも書き込み前の残存識別子検査を掛ける。ファイル単位の検査であり、
# ディレクトリ走査は伴わない。
$rootLeaks = New-Object System.Collections.Generic.List[object]
foreach ($rk in $rootGenerated.Keys) {
    foreach ($lk in (Get-ProvenanceLeak -Content $rootGenerated[$rk] -Path $rk)) {
        $rootLeaks.Add([pscustomobject]@{ Path=$rk; Line=$lk.Line; Text=$lk.Text })
    }
}

if ($rootLeaks.Count -gt 0) {
    foreach ($lk in $rootLeaks) {
        Write-Host "  ! identifier in $($lk.Path):$($lk.Line)  $($lk.Text)"
    }
}
if ($allViolations.Count -gt 0 -or $pluginLeaks.Count -gt 0 -or $rootLeaks.Count -gt 0) {
    Write-Host '[build-dist] Aborted. Generated artifacts were not modified.'
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
    # ルート直下の生成物は既知パスのホワイトリストに対するファイル単位の突合とする。
    # 「余分なファイルの不在」条件は適用しない（リポジトリルートを走査すると
    # 生成物以外の全ファイルが陳腐化と判定されるため）。
    foreach ($rk in $rootGenerated.Keys) {
        $rfull = Join-Path $repoRoot $rk
        if (-not (Test-Path $rfull)) { Write-Host "  ! missing: $rk"; $diff++; continue }
        $rbytes = [System.IO.File]::ReadAllBytes($rfull)
        if ($rbytes.Length -ge 3 -and $rbytes[0] -eq 0xEF -and $rbytes[1] -eq 0xBB -and $rbytes[2] -eq 0xBF) {
            Write-Host "  ! BOM found: $rk"; $diff++
        }
        $ractual = ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText($rfull))
        if ($ractual -ne $rootGenerated[$rk]) { Write-Host "  ! content differs: $rk"; $diff++ }
    }
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
Write-Host '[build-dist] Generating dist/ and root artifacts ...'
if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
foreach ($k in $generated.Keys) {
    $dest = Join-Path $repoRoot $k
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($dest, $generated[$k], $utf8)   # LF 固定・BOM なし（ADR-0033）
}

# ルート直下の生成物はホワイトリストのファイル単位で上書きする（wipe はしない）
foreach ($rk in $rootGenerated.Keys) {
    $rdest = Join-Path $repoRoot $rk
    $rdestDir = Split-Path -Parent $rdest
    if (-not (Test-Path $rdestDir)) { New-Item -ItemType Directory -Path $rdestDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($rdest, $rootGenerated[$rk], $utf8)
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

Write-Host "[build-dist] Done. $($generated.Count) files written to dist/, $($rootGenerated.Count) to repository root."
