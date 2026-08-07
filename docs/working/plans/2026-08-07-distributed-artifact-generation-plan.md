# 配布物生成 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 配布先で解決できない出所識別子を配布物から除去する生成器を作り、既存ソースを記法規約へ適合させる。

**Architecture:** 判定と変換のロジックを共有ライブラリ `scripts/lib/strip-provenance.ps1` に置き、`scripts/build-dist.ps1`（プラグイン配布物）と `scripts/sync-template.ps1`（テンプレート配布物）の両方から使う。規約違反は生成の失敗として顕在化させ、別途の lint を設けない。

**Tech Stack:** PowerShell 7（既存スクリプト 2 本と同じ）。テストフレームワークは導入せず、既存の `skills/worklog-extract/scripts/check-store-health.py` が採る `--self-test`（正負の対照を同梱）方式に合わせる。

**Spec:** `docs/current/specs/2026-08-07-distributed-artifact-generation/`（00〜05）
**ADR:** ADR-0081（対象範囲）/ ADR-0082（配布体制）/ ADR-0083（記法規約と検査）

---

## ファイル構成

| ファイル | 区分 | 責務 |
|---|---|---|
| `scripts/lib/strip-provenance.ps1` | 新規 | 出所識別子の判定と除去。両生成器が dot-source する唯一の実装 |
| `scripts/build-dist.ps1` | 新規 | `skills/` → `dist/` の生成、`-Check`、自己検査 |
| `scripts/sync-template.ps1` | 改修 | 判定・変換ステップと `-Check` を追加。`Copy-Item` をテキスト書き出しへ置換 |
| `.claude-plugin/marketplace.json` | 改修 | 本番エントリの `source` を `./dist` へ（構造 A の場合） |
| `skills/` 配下 8 ファイル | 改修 | 記法規約への適合（36 行。R2 15・R3 15・R4 6）＋ 除去後に文が壊れる 10 行（規約適合だが要対処。Task 7 Step 4-2） |
| `docs/records/retrospectives/README.md` | 改修 | 同上（1 行。R2） |
| `docs/overview/folder-structure.md` | 改修 | R5 適合（1 行） |
| `CONTRIBUTING.md` | 改修 | 規約節の新設と 4 シナリオへの配線 |
| `skills/extend-guidelines/SKILL.md` | 改修 | 手順 6 を配布物生成の案内へ拡張 |
| `docs/records/decisions/0027-template-seed-criteria.md` | 改修 | 部分修正の注記 |

**実装順序の制約**: Task 1（構造判定）→ Task 2〜4（ライブラリと生成器）→ Task 5〜7（移行）→ Task 8（`sync-template.ps1`）→ Task 9〜10（配線と記録）→ Task 11（本番切替）→ Task 12（全体検証）。移行が `sync-template.ps1` の改修より先でないと、同期が規約違反で止まる。

---

### Task 1: 配布構造の実機判定（構造 A / B）

**Files:**
- Create: `dist/.claude-plugin/plugin.json`（暫定・最小構成）
- Create: `dist/skills/probe-skill/SKILL.md`（暫定・検証専用）
- Modify: `.claude-plugin/marketplace.json`

このタスクの結果で後続タスクのパスが決まる。**本番エントリを差し替えてはならない**（差し替えると当セッションのガイドラインスキル 18 本が 1 本になり、復旧にユーザーの再 update が要る。spec 04 参照）。

- [ ] **Step 1: 検証用の最小構成を作る**

```powershell
New-Item -ItemType Directory -Force dist/.claude-plugin, dist/skills/probe-skill | Out-Null
@'
{
  "name": "ai-driven-dev-principles-probe",
  "description": "配布構造の成立性検証用（一時）",
  "version": "0.0.1"
}
'@ | Set-Content -Encoding utf8NoBOM dist/.claude-plugin/plugin.json
@'
---
name: probe-skill
description: 配布構造の成立性を確認するための一時スキル
---

# probe-skill

このスキルが起動できれば、marketplace の source にサブディレクトリを指定できる。
'@ | Set-Content -Encoding utf8NoBOM dist/skills/probe-skill/SKILL.md
```

- [ ] **Step 2: 検証用エントリを marketplace へ追加する**

`.claude-plugin/marketplace.json` の `plugins` 配列へ 2 件目として追加する（1 件目の本番エントリは触らない）。

```json
    {
      "name": "ai-driven-dev-principles-probe",
      "description": "配布構造の成立性検証用（一時）",
      "version": "0.0.1",
      "source": "./dist",
      "author": { "name": "taika-izumi" }
    }
```

- [ ] **Step 3: ユーザーへ再読み込みとインストールを依頼する**

エージェントからは実行できない。次を依頼する:

```
/plugin marketplace update ai-driven-dev-principles
/plugin install ai-driven-dev-principles-probe@ai-driven-dev-principles
```

- [ ] **Step 4: 判定する**

`Skill` ツールで `probe-skill` を起動する。
期待（構造 A 成立）: スキルが起動し、ベースディレクトリが `<repo>/dist/skills/probe-skill` を指す。
期待（不成立）: スキルが一覧に現れない、または起動しない。

- [ ] **Step 5: 判定結果を記録し、暫定ファイルを片付ける**

成立なら構造 A、不成立なら構造 B を採用する。判定結果を `docs/working/handoff/feature_cross-repo-adr-reference.md` の「既知のブロッカー・懸念」へ 1 行書く。

検証用エントリを `marketplace.json` から削除し、`dist/skills/probe-skill/` を削除する（`dist/.claude-plugin/plugin.json` は Task 4 で正式に生成されるため、ここでは残してよい）。ユーザーへ `/plugin uninstall ai-driven-dev-principles-probe@ai-driven-dev-principles` を依頼する。

**構造 B を採用した場合**: 以降のタスクのパスを次で読み替える。開発用ソース `skills/` → `skills-src/`、生成スキル `dist/skills/` → `skills/`、プラグインルート `dist/` → リポジトリ直下、`plugin.json` の複写は不要。Task 4 の `-Check` の比較先も同様。

- [ ] **Step 6: コミット**

```bash
git add .claude-plugin/marketplace.json docs/working/handoff/feature_cross-repo-adr-reference.md
git commit -m "chore: 配布構造の成立性を実機判定（構造 A/B の確定）"
```

---

### Task 2: 共有ライブラリ — 判定関数と自己テスト

**Files:**
- Create: `scripts/lib/strip-provenance.ps1`

- [ ] **Step 1: 自己テストを先に書く（失敗する状態）**

`scripts/lib/strip-provenance.ps1` を作り、まず対照データと自己テストだけを書く。

```powershell
# scripts/lib/strip-provenance.ps1
# 配布対象ソースの出所識別子を判定・除去する共有ライブラリ。
# build-dist.ps1 と sync-template.ps1 が dot-source して使う唯一の実装（ADR-0083）。

Set-StrictMode -Version Latest

# --- 正規表現（spec 02「判定に用いる正規表現」と一致させること） ---
$script:ReType13    = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}'
$script:ReType4     = '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*)?-20\d\d-\d\d-\d\d(?:-\d\d)?'
$script:ReType5     = '（出所[:：][^）]*）'
$script:ReNeutral   = '^(?:X|Proj|<project>)$'
$script:ReListColon = '^\s*[-*]\s*(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}(?:\s*[/〜]\s*\d{4})*\s*[:：]'
$script:ReListHead  = '^\s*[-*]\s*(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}'

function Invoke-StripProvenanceSelfTest {
    $cases = @(
        # 判定（適合）
        @{ Kind='judge'; Line='記録先へ1行残す（ADR-0057）';                                  Expect='ok' }
        @{ Kind='judge'; Line='- ADR-0044: 記録ゲート・スキル1/2 責務境界';                    Expect='listline' }
        @{ Kind='judge'; Line='- ADR-0048/0049/0051: 読み側互換（model 材料）';               Expect='listline' }
        @{ Kind='judge'; Line='…テスト運用出所のため（出所: LoopForAlpha）';                   Expect='ok' }
        # 判定（違反）
        @{ Kind='judge'; Line='出力ファイルは ADR-0011（時系列追記型）に従い';                  Expect='R2' }
        @{ Kind='judge'; Line='- ADR-0006（意思決定の継続検出ルール）は常時適用される';          Expect='R3' }
        # プレースホルダ・中立名（対象外）
        @{ Kind='judge'; Line='- **関連**: ADR-NNNN 等（あれば）';                            Expect='none' }
        @{ Kind='judge'; Line='- 書式: `<repo>#Issue-NNNN`（例: `OtherProject#Issue-NNNN`）'; Expect='none' }
        @{ Kind='judge'; Line='{"v":2,"id":"X-2026-07-16-01","outcome":"adopted"}';           Expect='none' }
        # 種別 4（省略形を含む）
        @{ Kind='judge'; Line='（指示が 2 回。LoopForAlpha-2026-07-22-09 / -2026-08-01-03）'; Expect='ok' }
        @{ Kind='judge'; Line='2026-08-05 の走査委譲（118 件全数）で有効性を実測';              Expect='none' }
    )
    $fail = 0
    foreach ($c in $cases) {
        $actual = Get-LineVerdict -Line $c.Line -InFence:$false
        if ($actual -ne $c.Expect) {
            Write-Host "  FAIL expect=$($c.Expect) actual=$actual :: $($c.Line)"
            $fail++
        }
    }
    if ($fail -gt 0) { Write-Host "[strip-provenance] self-test: $fail case(s) failed"; return $false }
    Write-Host "[strip-provenance] self-test: all $($cases.Count) cases passed"
    return $true
}
```

- [ ] **Step 2: 自己テストを走らせて失敗を確認する**

```powershell
pwsh -NoProfile -Command ". ./scripts/lib/strip-provenance.ps1; Invoke-StripProvenanceSelfTest"
```

期待: `Get-LineVerdict` が未定義でエラー終了する。

- [ ] **Step 3: 判定関数を実装する**

```powershell
function Get-IdentifierMatch {
    param([string]$Line)
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($m in [regex]::Matches($Line, $script:ReType13)) {
        $result.Add([pscustomobject]@{ Start=$m.Index; Length=$m.Length; Text=$m.Value })
    }
    foreach ($m in [regex]::Matches($Line, $script:ReType4)) {
        $prefix = ($m.Value -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { continue }   # 中立名は対象外（spec 01）
        $result.Add([pscustomobject]@{ Start=$m.Index; Length=$m.Length; Text=$m.Value })
    }
    # `,(...)` ではなく `,@(...)` にすること。空パイプラインを `,(...)` で包むと関数の戻り値が
    # $null になり、呼び出し側の .Count が Set-StrictMode 下で PropertyNotFoundException を投げる。
    return ,@($result | Sort-Object Start)
}

function Test-InsideParen {
    param([string]$Line, [int]$Index)
    $before = $Line.Substring(0, $Index)
    return ($before.LastIndexOf('（') -gt $before.LastIndexOf('）'))
}

# 判定順序は spec 02「判定順序」と一致させること。
# 戻り値: 'none' | 'ok' | 'listline' | 'R2' | 'R3' | 'R4'
function Get-LineVerdict {
    param([string]$Line, [bool]$InFence)

    # 種別 5 は括弧そのものが識別子。ステップ 5 の内側判定のためマスクする。
    $masked = [regex]::Replace($Line, $script:ReType5, { param($m) '（' + ('x' * ($m.Value.Length - 2)) + '）' })
    $ids = Get-IdentifierMatch -Line $masked
    $hasType5 = [regex]::IsMatch($Line, $script:ReType5)

    if ($ids.Count -eq 0 -and -not $hasType5) { return 'none' }
    if ($InFence) { return 'R4' }
    if ($Line -match $script:ReListColon) { return 'listline' }
    if ($Line -match $script:ReListHead)  { return 'R3' }
    foreach ($id in $ids) {
        if (-not (Test-InsideParen -Line $masked -Index $id.Start)) { return 'R2' }
    }
    return 'ok'
}
```

- [ ] **Step 4: 自己テストを走らせて成功を確認する**

```powershell
pwsh -NoProfile -Command ". ./scripts/lib/strip-provenance.ps1; Invoke-StripProvenanceSelfTest"
```

期待: `[strip-provenance] self-test: all 11 cases passed`

- [ ] **Step 5: コミット**

```bash
git add scripts/lib/strip-provenance.ps1
git commit -m "feat: 出所識別子の判定関数と自己テストを追加（ADR-0083）"
```

---

### Task 3: 共有ライブラリ — ファイル単位の判定と変換

**Files:**
- Modify: `scripts/lib/strip-provenance.ps1`

- [ ] **Step 1: 変換の自己テストケースを追加する**

`Invoke-StripProvenanceSelfTest` の中の **`foreach ($c in $cases)` ループの直後、`if ($fail -gt 0)` の直前**へ、変換の対照を追加する（`$cases` の定義直後へ置くと `$fail` が未初期化のまま参照され、`Set-StrictMode -Version Latest` 下でエラーになる）。

```powershell
    $convert = @(
        @{ In='記録先へ1行残す（ADR-0057）。';                         Out='記録先へ1行残す。' }
        @{ In='規範（ADR-0073。条件の追加は観測が根拠）を守る';          Out='規範（条件の追加は観測が根拠）を守る' }
        @{ In='…出所のため（出所: LoopForAlpha）';                     Out='…出所のため' }
        @{ In='- **関連**: ADR-NNNN 等（あれば）';                     Out='- **関連**: ADR-NNNN 等（あれば）' }
        # バッククォートで囲まれた識別子（囲みごと消えること。空の対が残らないこと）
        @{ In=('（実測: 取り逃していた。' + [char]96 + 'LoopForAlpha-2026-07-19-05' + [char]96 + '）'); Out='（実測: 取り逃していた）' }
        @{ In=('サンプル ' + [char]96 + 'X-2026-01-01-01' + [char]96 + ' は中立名なので残す');          Out=('サンプル ' + [char]96 + 'X-2026-01-01-01' + [char]96 + ' は中立名なので残す') }
    )
    foreach ($c in $convert) {
        $actual = Remove-ProvenanceFromLine -Line $c.In
        if ($actual -ne $c.Out) {
            Write-Host "  FAIL convert expect=[$($c.Out)] actual=[$actual]"
            $fail++
        }
    }
```

あわせて末尾の合格メッセージを `all $($cases.Count + $convert.Count) cases passed` へ変える（判定 11 ＋ 変換 6 ＝ 17 ケース）。

- [ ] **Step 2: 自己テストを走らせて失敗を確認する**

```powershell
pwsh -NoProfile -Command ". ./scripts/lib/strip-provenance.ps1; Invoke-StripProvenanceSelfTest"
```

期待: `Remove-ProvenanceFromLine` が未定義でエラー終了する。

- [ ] **Step 3: 変換関数を実装する**

```powershell
function Remove-ProvenanceFromLine {
    param([string]$Line)

    # 行頭のインデントは掃除規則の対象外にする（Markdown のネストが潰れるため）
    $indent = [regex]::Match($Line, '^[ 　\t]*').Value
    $body   = $Line.Substring($indent.Length)

    # 種別 5: 括弧を中身ごと削除
    $out = [regex]::Replace($body, $script:ReType5, '')

    # 種別 1〜4: **バッククォートで囲まれた識別子は囲みごと除去する。**
    # 識別子だけを外すと空の対（`` の 2 連）が残り、後段の掃除では消せない。
    # PowerShell の単一引用符内ではバッククォートがエスケープにならないため、
    # '``(?=`)' のような書き方は「2 連＋直後にもう 1 つ」を要求してしまい意図どおり動かない
    # （実測。むしろコードフェンスの 3 連に一致する）。[char]96 で組み立てること。
    $bt = [char]96
    $pattern13 = $script:ReType13 + '(?:\s*項目[\d/]+)?'
    $out = [regex]::Replace($out, "$bt$pattern13$bt", '')
    $out = [regex]::Replace($out, "$bt$($script:ReType4)$bt", { param($m)
        $prefix = (($m.Value.Trim([char]96)) -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { return $m.Value }   # 中立名は残す
        return ''
    })

    # 続いて、囲まれていない識別子を除去する
    $out = [regex]::Replace($out, $pattern13, '')
    $out = [regex]::Replace($out, $script:ReType4, { param($m)
        $prefix = ($m.Value -split '-20')[0]
        if ($prefix -match $script:ReNeutral) { return $m.Value }   # 中立名は残す
        return ''
    })

    # 除去で生じた区切りの残骸を掃除（行頭インデントは $body に含まれないので影響しない）
    $out = [regex]::Replace($out, '（\s*[。、・/〜]?\s*', '（')
    $out = [regex]::Replace($out, '\s*[。、・/〜]?\s*）', '）')
    $out = $out -replace '（）', ''
    $out = [regex]::Replace($out, '(?<=\S)[ 　]{2,}', ' ')
    return ($indent + $out.TrimEnd())
}

function ConvertTo-LfContent {
    param([string]$Content)
    return ($Content -replace "`r`n", "`n" -replace "`r", "`n")
}

function Test-ProvenanceConvention {
    param([string]$Content, [string]$Path)
    $Content = ConvertTo-LfContent -Content $Content   # ソース側の CRLF に依存しない（ADR-0033）
    $violations = New-Object System.Collections.Generic.List[object]
    $isScript = $Path -match '\.(py|ps1)$'
    $inFence = $false
    $i = 0
    foreach ($line in ($Content -split "`n")) {
        $i++
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($isScript -and -not $line.TrimStart().StartsWith('#')) { continue }
        $v = Get-LineVerdict -Line $line -InFence:$inFence
        if ($v -in @('R2','R3','R4')) {
            $violations.Add([pscustomobject]@{ Line=$i; Rule=$v; Text=$line.Trim() })
        }
    }
    # `,@($violations)` と書かないこと。List に `@()` を掛けたものへ単項カンマを適用すると
    # 「Argument types do not match」で失敗する（実測）。`.ToArray()` が最も曖昧さがない。
    return ,$violations.ToArray()
}

function Remove-ProvenanceNotation {
    param([string]$Content, [string]$Path = '')
    $Content = ConvertTo-LfContent -Content $Content
    $isScript = $Path -match '\.(py|ps1)$'
    $out = New-Object System.Collections.Generic.List[string]
    $droppedAfter = New-Object System.Collections.Generic.HashSet[int]   # 出所リスト行を削除した直前の出力位置
    $inFence = $false
    $lines = $Content -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $isScript -and $line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; $out.Add($line); continue }
        if ($inFence -or ($isScript -and -not $line.TrimStart().StartsWith('#'))) { $out.Add($line); continue }
        if ((Get-LineVerdict -Line $line -InFence:$false) -eq 'listline') {
            [void]$droppedAfter.Add($out.Count)   # この位置の直後で 1 行落ちた
            continue
        }
        $out.Add((Remove-ProvenanceFromLine -Line $line))
    }
    # 出所リスト行を実際に削除した節に限り、空になった見出しを畳む
    # （無条件に「見出しの次が見出しなら削除」とすると、もともと見出しが連続する箇所を壊す）
    $final = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $out.Count; $i++) {
        if ($out[$i] -match '^#{2,}\s') {
            $j = $i + 1
            while ($j -lt $out.Count -and $out[$j].Trim() -eq '') { $j++ }
            $sectionLostLine = $false
            for ($k = $i + 1; $k -le $j; $k++) { if ($droppedAfter.Contains($k)) { $sectionLostLine = $true; break } }
            if ($sectionLostLine -and ($j -ge $out.Count -or $out[$j] -match '^#{2,}\s')) { $i = $j - 1; continue }
        }
        $final.Add($out[$i])
    }
    # 連続空行を 1 行へ
    $collapsed = New-Object System.Collections.Generic.List[string]
    $prevBlank = $false
    foreach ($l in $final) {
        $blank = ($l.Trim() -eq '')
        if ($blank -and $prevBlank) { continue }
        $collapsed.Add($l); $prevBlank = $blank
    }
    return ($collapsed -join "`n")
}
```

- [ ] **Step 4: 自己テストを走らせて成功を確認する**

```powershell
pwsh -NoProfile -Command ". ./scripts/lib/strip-provenance.ps1; Invoke-StripProvenanceSelfTest"
```

期待: `[strip-provenance] self-test: all 17 cases passed`

- [ ] **Step 5: コミット**

```bash
git add scripts/lib/strip-provenance.ps1
git commit -m "feat: 出所識別子の除去関数とファイル単位の判定を追加（ADR-0083）"
```

---

### Task 4: 生成器 `build-dist.ps1`

**Files:**
- Create: `scripts/build-dist.ps1`

- [ ] **Step 1: 生成器を実装する**

```powershell
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
```

- [ ] **Step 2: 現状のソースに対して実行し、規約違反で停止することを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1; "exit=$LASTEXITCODE"
```

期待: `Convention violations: 36` と各違反行が表示され、`Aborted. dist/ was not modified.` で `exit=1`。

内訳は R2 15（`subagent-dispatch` 10・`pre-finalization-review` 3・`retrospective` 1・`store-format` 1）＋ R3 15 ＋ R4 6。`build-dist.ps1` の走査対象は `skills/` 配下のみなので、全体 37 行のうち `docs/records/retrospectives/README.md:21` の 1 行はここには現れない（Task 8 の `sync-template.ps1` 側で検出される）。`folder-structure.md:149` の R5 違反も位置規約では検出されない。

- [ ] **Step 3: コミット**

```bash
git add scripts/build-dist.ps1
git commit -m "feat: 配布物生成器 build-dist.ps1 を追加（ADR-0082）"
```

---

### Task 5: 移行 — R3 違反 15 行（出所リスト行をコロン形へ）

**Files:**
- Modify: `skills/worklog-extract/SKILL.md:63-66`
- Modify: `skills/worklog-record/SKILL.md:85-90`
- Modify: `skills/worklog-skillify/SKILL.md:58-61`
- Modify: `skills/retrospective/SKILL.md:53`

- [ ] **Step 1: 括弧形の出所リスト行をコロン形へ書き換える**

対象 14 行は `- ADR-NNNN（説明）` の形。`- ADR-NNNN: 説明` へ変える。括弧内にコロンがある場合は内側のコロンを避けて書き直す。

```
違反: - ADR-0044（記録ゲート・スキル1/2 責務境界・scope 暫定タグ）
適合: - ADR-0044: 記録ゲート・スキル1/2 責務境界・scope 暫定タグ

違反: - ADR-0048/0049/0051（読み側互換: model 材料・v 版数判別・friction 読み替え）
適合: - ADR-0048/0049/0051: 読み側互換（model 材料・v 版数判別・friction 読み替え）
```

- [ ] **Step 2: `retrospective/SKILL.md:53` は手順文として書き直す**

行頭が識別子だが中身は手順文であるため、コロン形にせず本文へ移す。

```
違反: - ADR-0006（意思決定の継続検出ルール）は本スキル中も常時適用される。ただし…
適合: - 意思決定の継続検出ルール（ADR-0006）は本スキル中も常時適用される。ただし…
```

- [ ] **Step 3: R3 違反が消えたことを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1 2>&1 | Select-String '  R3'
```

期待: 出力なし（R3 違反 0 件）。他の違反は残っているため全体はまだ `exit=1`。

- [ ] **Step 4: コミット**

```bash
git add skills/worklog-extract/SKILL.md skills/worklog-record/SKILL.md skills/worklog-skillify/SKILL.md skills/retrospective/SKILL.md
git commit -m "refactor: 出所リスト行をコロン形へ統一（R3・ADR-0083）"
```

---

### Task 6: 移行 — R2 違反 16 行（識別子を括弧内へ移す）

**Files:**
- Modify: `skills/subagent-dispatch/SKILL.md:35-38,46-50,56`
- Modify: `skills/pre-finalization-review/SKILL.md:43,53,54`
- Modify: `skills/retrospective/SKILL.md:54`（＋ Step 4-2 で 53・136 行目）
- Modify: `skills/worklog-record/references/store-format.md:88`
- Modify: `docs/records/retrospectives/README.md:21`

- [ ] **Step 1: 本文中の識別子を括弧内へ移す**

意味を保ったまま語順を変える。括弧の中身が主語・目的語になっている場合は、それを本文へ出して識別子を括弧へ入れる。

```
違反: - 出力ファイルは ADR-0011（時系列追記型）に従い、一度書いたら原則上書き禁止
適合: - 出力ファイルは時系列追記型（ADR-0011）に従い、一度書いたら原則上書き禁止

違反: ADR-0008 のスナップショット規約（spec / handoff 用）は適用しない。
適合: スナップショット規約（ADR-0008。spec / handoff 用）は適用しない。
```

- [ ] **Step 2: 表のセル冒頭にある識別子を末尾の括弧へ集める**

`subagent-dispatch/SKILL.md` の根拠列 9 行が該当する。散文を主文として前に出す。worklog id の省略形（`-2026-08-01-03`）も種別 4 の識別子なので同じ括弧へ入れる。

```
違反: | … | Issue-0033 項目2。原則4（不可逆操作前の人間関与）の委譲先への伝播 |
適合: | … | 原則4（不可逆操作前の人間関与）の委譲先への伝播（Issue-0033 項目2） |

違反: | … | `LoopForAlpha-2026-07-22-09`（黙って従えば品質が下がる指示が 2 回）、`-2026-08-01-03` / `-2026-08-03-02`（計画の欠陥 6 件 / 4 件を実態優先の報告が検出）。世代: claude-opus-4-7〜claude-opus-5[1m] |
適合: | … | 黙って従えば品質が下がる指示が 2 回。計画の欠陥 6 件 / 4 件を実態優先の報告が検出。世代: claude-opus-4-7〜claude-opus-5[1m]（出所: LoopForAlpha-2026-07-22-09 / -2026-08-01-03 / -2026-08-03-02） |
```

- [ ] **Step 3: プロジェクト名を `（出所: …）` へ移す**

`pre-finalization-review/SKILL.md:53` と `subagent-dispatch/SKILL.md:47` が該当する。

```
違反: 根拠 8 件全件が単一プロジェクト（LoopForAlpha）のテスト運用出所のため、拘束的規範ではなく適用例
適合: 根拠 8 件全件が単一プロジェクトのテスト運用出所のため、拘束的規範ではなく適用例（出所: LoopForAlpha-2026-08-01-03 / LoopForAlpha）

違反: 7 件はすべて LoopForAlpha 由来）。観測世代: claude-opus-4-8 / claude-fable-5 / claude-opus-5 の 3 世代
適合: 7 件はすべて単一プロジェクト由来）。観測世代: claude-opus-4-8 / claude-fable-5 / claude-opus-5 の 3 世代（出所: LoopForAlpha）
```

- [ ] **Step 4: 根拠が消える 3 行へ散文を補う**

変換後に根拠列が空になる、または出所が読み取れなくなる 3 行（`subagent-dispatch/SKILL.md:36,37,50`）へ、参照先 Issue の「根拠エントリ」節の実データから散文を補う。**補完内容はユーザー確認を経ること**（推測で書かない）。

```
違反: | 長時間かつ書き込みを伴う作業を委譲するとき | … | Issue-0033 項目4 |
適合: | 長時間かつ書き込みを伴う作業を委譲するとき | … | 本項目を含むクラスタ（中央ストア 10 件）由来。全件が単一プロジェクト出所。世代: claude-opus-4-7〜claude-opus-5[1m]（出所: Issue-0033 項目4 / LoopForAlpha） |
```

- [ ] **Step 4-2: Task 5 のレビューが積み残した `retrospective/SKILL.md` の 2 行を処理する**

53 行目は Task 5 で「手順文として本文へ移す」書き換えを受けたが、移した結果むき出しになった用語が配布先で解決できない。配布物に ADR は含まれず、配布される CLAUDE.md の該当節見出しは「意思決定の即時記録（継続適用）」で語が一致しないため、読み手が参照先へ辿れない。節見出しと語を揃える。

```
現状: - 意思決定の継続検出ルール（ADR-0006）は本スキル中も常時適用される。ただし…
適合: - 意思決定の即時記録（継続適用）のルール（ADR-0006）は本スキル中も常時適用される。ただし…
```

136 行目は 1 行に 2 識別子・コロン 2 個の変則形で、Task 5 の統一から漏れている。機能上は先頭の識別子で `listline` 判定になり配布物からは消えるが、後続の書き手へ「2 件を 1 行に詰めてよい」という誤ったお手本を残す。

```
現状: - ADR-0010: 振り返りフェーズ導入 / ADR-0011: 保管規約（時系列追記型）
適合: - ADR-0010〜0011: 振り返りフェーズ導入・保管規約（時系列追記型）
```

54 行目（Step 1 の R2 対象）と同じ節・隣接行のため、同一コミットで処理する。

- [ ] **Step 5: R2 違反が消えたことを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1 2>&1 | Select-String '  R2'
```

期待: 出力なし（`skills/` 配下の R2 違反 0 件。`docs/records/retrospectives/README.md` は Task 8 で `sync-template.ps1` 側が検査する）。

Step 4-2 の 2 行は次で確認する（53 行目は `ok`＝本文として残る、136 行目は `listline`＝行ごと削除される）。

```powershell
. ./scripts/lib/strip-provenance.ps1
$lines = (ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText("$PWD/skills/retrospective/SKILL.md"))) -split "`n"
Get-LineVerdict -Line $lines[52] -InFence:$false    # 期待: ok
Get-LineVerdict -Line $lines[135] -InFence:$false   # 期待: listline
```

- [ ] **Step 6: コミット**

```bash
git add skills/subagent-dispatch/SKILL.md skills/pre-finalization-review/SKILL.md skills/retrospective/SKILL.md skills/worklog-record/references/store-format.md docs/records/retrospectives/README.md
git commit -m "refactor: 本文中の出所識別子を括弧内へ移し、根拠の散文を補完（R2・ADR-0083）"
```

---

### Task 7: 移行 — R4 違反 6 行（コードフェンス内）と R5 違反 1 行

**Files:**
- Modify: `skills/session-handoff/SKILL.md:60,63`
- Modify: `skills/worklog-record/SKILL.md:69`
- Modify: `skills/worklog-record/references/store-format.md:93-95`
- Modify: `docs/overview/folder-structure.md:149`
- Step 4-2 の対象（除去後に文が壊れる行。2026-08-08 の実測で 3 行 → 10 行へ拡大）: `skills/pre-finalization-review/SKILL.md:24,32`・`skills/retrospective/SKILL.md:21`・`skills/retrospective/template.md:25`・`skills/worklog-record/SKILL.md:12`・`skills/worklog-record/references/store-format.md:20,80,86`・`skills/worklog-skillify/SKILL.md:44`・`skills/worklog-extract/SKILL.md:49`

- [ ] **Step 1: ハンドオフ書式テンプレートから識別子を除く**

`session-handoff/SKILL.md:60,63` はフェンス内の書式テンプレートで、配布先の実ファイルへ複写される。識別子を落とし、必要なら説明をフェンス外の解説文（括弧内）へ移す。

```
違反（フェンス内）: マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。
適合（フェンス内）: マイルストーンごとに Post ラッパーの消し込み結果を1行残す。
```

- [ ] **Step 2: worklog サンプルの実データを中立名へ差し替える**

`worklog-record/SKILL.md:69` は 4 箇所を直す。`"context"` の文中の識別子、`"applied_rules"` の値、`"id"`、`"project"`。

```
違反: {"v":2,"id":"MakeAiInstructions-2026-07-17-01",…,"project":"MakeAiInstructions",…,"context":"… ADR-0036 の運用チェックを実行","applied_rules":["ADR-0036"]}
適合: {"v":2,"id":"X-2026-07-17-01",…,"project":"X",…,"context":"… 構造化質問ツールの運用チェックを実行","applied_rules":["<適用したルールの ID>"]}
```

- [ ] **Step 3: 台帳レコード例のプロジェクト名を中立名へ差し替える**

`store-format.md:93-95` の 3 行。`MakeAiInstructions-2026-07-16-01` → `X-2026-07-16-01`、`LoopForAlpha-2026-07-18-03` → `X-2026-07-18-03`。中立名 `X` は許可リストに含まれるため識別子と判定されなくなる。

- [ ] **Step 4: 記法の例示をプレースホルダ化する（R5）**

```
違反: - 書式: `<repo>#Issue-NNNN`（例: `LoopForAlpha#Issue-0069`）
適合: - 書式: `<repo>#Issue-NNNN`（例: `OtherProject#Issue-NNNN`）
```

- [ ] **Step 4-2: 除去後に文が壊れる行を書き換える（規約適合だが要対処）**

R1 は識別子を括弧内に置くことを許すが、**括弧内でその識別子が文の構成要素になっている**場合、除去すると日本語が壊れる。規約違反ではないため生成器は止まらず、配布物の品質だけが落ちる。

**この検出は機械だけでは完結しない**（2026-08-08 の実測で判明。当初計画は正規表現 1 本で全件拾える前提だったが、次の 2 方向で破れた）:

- **誤爆**: 行全体へ `'[ 　]{2,}|[はがをにでとへも][ 　]'` を掛けると、元から存在する正常な表現（`（例: …）で書くこと` など）に大量に当たる。実測で 60 件超がヒットし、終了条件「該当 0 件」は達成不能だった
- **取りこぼし**: 文法的には壊れないが意味が失われる型（`（ADR-0083 の追補）` → `（追補）`）は、どの正規表現でも拾えない

したがって**機械的な事前絞り込み＋全数読解**の 2 段で行う。

**(1) 事前絞り込み**: 除去で「新たに生じた」不審な並びだけを拾う。同じ並びが元の行にも同数あれば、それは除去が作ったものではない（この差分比較が誤爆を消す）。

```powershell
. ./scripts/lib/strip-provenance.ps1
$root = (Get-Location).Path
$patterns = @(
    '（[はがをにでとへもの、。・/〜\s]', '[はがをにでとへもの]）', '）[はがをにでとへもの]',
    '（\s*）', '[^\s]  +[^\s]', '[。、]\s*[はがをにでとへもの]', '[はがをにでとへもの][ 　]', '[（。、][ 　]'
)
Get-ChildItem skills -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($root.Length + 1) -replace '\\', '/'
  $i = 0; $inFence = $false; $isScript = $rel -match '\.(py|ps1)$'
  foreach ($l in ((ConvertTo-LfContent -Content ([System.IO.File]::ReadAllText($_.FullName))) -split "`n")) {
    $i++
    if (-not $isScript -and $l.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
    if ($inFence -or ($isScript -and -not $l.TrimStart().StartsWith('#'))) { continue }
    if ((Get-LineVerdict -Line $l -InFence:$false) -ne 'ok') { continue }
    $o = Remove-ProvenanceFromLine -Line $l
    foreach ($p in $patterns) {
      if (([regex]::Matches($o, $p)).Count -gt ([regex]::Matches($l, $p)).Count) { "HIT $rel`:$i"; break }
    }
  }
}
```

2026-08-08 の実測では `'ok'` 行 **112** のうち **9 行**がヒットする（`pre-finalization-review/SKILL.md:24,32`・`retrospective/SKILL.md:21`・`retrospective/template.md:25`・`worklog-record/SKILL.md:12`・`worklog-record/references/store-format.md:20,80,86`・`worklog-skillify/SKILL.md:44`）。

**(2) 全数読解**: ヒットしなかった行にも意味の欠落型が潜むため、`'ok'` 行 **112 行すべて**について変換前後の対を出力し、1 行ずつ読んで「配布先の読み手が読める日本語か」を判定する。実測では `worklog-extract/SKILL.md:49`（`（ADR-0083 の追補）` → `（追補）`）が (1) では拾えず読解でのみ検出された。

対処は、括弧内の識別子を文から外し、出所として末尾へ寄せる。

```
違反: （実測。同じ罠は `scripts/sync-template.ps1` が ADR-0033 で解決済み）
適合: （実測。同じ罠は `scripts/sync-template.ps1` で解決済み（ADR-0033））

違反: ## スコープ（ADR-0021 を維持）
適合: ## スコープ（ADR-0021 の範囲を維持する）  ← 除去後: 「## スコープ」
```

**終了条件**: 書き換え後に (1) を再実行して**ヒット 0 件**、かつ (2) の読解で**破綻 0 件**。読解の母数（112 行）と判定結果を報告に残すこと。

- [ ] **Step 5: 違反 0 件で生成が通ることを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1; "exit=$LASTEXITCODE"
```

期待: `Convention violations: 0`、`Done. N files written to dist/.`、`exit=0`。

- [ ] **Step 6: 生成物に識別子が残っていないことを確認する**

```powershell
Get-ChildItem dist -Recurse -File -Exclude *.py,*.ps1 | Select-String -Pattern '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}','(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*)?-20\d\d-\d\d-\d\d(?:-\d\d)?' | Measure-Object | Select-Object -ExpandProperty Count
```

期待: `0`。

**`-Exclude *.py,*.ps1` は必須**。スクリプトのコード部分は規約の適用対象外（spec 00 スコープ外・01 適用範囲）であり、`check-store-health.py` の docstring とコード行にある識別子 3 件は移行後も恒久的に `dist/` に残る。除外しないとこの確認は必ず失敗し、スコープ外のはずのコード修正へ誘導してしまう。種別 4 の正規表現も合わせて確認する（完了基準 4 は「02 が定める正規表現」による判定を求めている）。

- [ ] **Step 7: コミット**

```bash
git add skills/session-handoff/SKILL.md skills/worklog-record/SKILL.md skills/worklog-record/references/store-format.md docs/overview/folder-structure.md dist
git commit -m "refactor: フェンス内の識別子と記法例を規約適合へ（R4/R5・ADR-0083）"
```

---

### Task 8: `sync-template.ps1` の改修

**Files:**
- Modify: `scripts/sync-template.ps1`

- [ ] **Step 1: `-Check` パラメータとライブラリの読み込みを追加する**

ファイル先頭（`Set-StrictMode` の前）へ:

```powershell
param([switch]$Check)
```

`$templateDir` の定義の後へ:

```powershell
. (Join-Path $PSScriptRoot 'lib/strip-provenance.ps1')
```

- [ ] **Step 2: 処理順を「読む → 判定 → 削除 → 書き出す」へ組み替える**

現行の `Remove-Item -Recurse -Force $templateDir`（112-115 行付近）を削除ステップとして後ろへ移し、その前に全対象の内容をメモリへ集めて判定する。

```powershell
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
```

- [ ] **Step 3: `-Check` モードを追加する**

変換後の内容を作った直後へ:

```powershell
if ($Check) {
    $existing = @{}
    if (Test-Path $templateDir) {
        foreach ($f in (Get-ChildItem -Path $templateDir -Recurse -File)) {
            $rel = $f.FullName.Substring($templateDir.Length + 1) -replace '\\', '/'
            $existing[$rel] = [System.IO.File]::ReadAllText($f.FullName)
        }
    }
    $diff = 0
    foreach ($k in $generated.Keys) {
        if (-not $existing.ContainsKey($k)) { Write-Host "  ! missing in template/: $k"; $diff++; continue }
        if ($existing[$k] -ne $generated[$k]) { Write-Host "  ! content differs: $k"; $diff++ }
    }
    foreach ($k in $existing.Keys) { if (-not $generated.Contains($k)) { Write-Host "  ! stale file: $k"; $diff++ } }
    if ($diff -gt 0) { Write-Host "[sync-template] Out of date: $diff difference(s)."; exit 1 }
    Write-Host '[sync-template] Up to date.'
    exit 0
}
```

- [ ] **Step 4: 書き出しを `Copy-Item` からテキスト書き出しへ置き換える**

現行の `Copy-Item -Path $sourcePath -Destination $destPath -Force`（130 行付近）を含むループを、次で置き換える。

```powershell
Write-Host "[sync-template] Cleaning template/ ..."
if (Test-Path $templateDir) { Remove-Item -Recurse -Force $templateDir }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($k in $generated.Keys) {
    $destPath = Join-Path $templateDir $k
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($destPath, $generated[$k], $utf8NoBom)
    Write-Host "  ✓ $k"
}
```

- [ ] **Step 5: `template/` の自己検査を追加する**

`check-claude-md-size.ps1` の呼び出しの直前へ:

```powershell
$leak = 0
foreach ($f in (Get-ChildItem -Path $templateDir -Recurse -File)) {
    $rel = $f.FullName.Substring($templateDir.Length + 1) -replace '\\', '/'
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $inFence = $false; $i = 0
    foreach ($line in ($content -split "`n")) {
        $i++
        if ($line.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        if ((Get-IdentifierMatch -Line $line).Count -gt 0) { Write-Host "  ! identifier remains: ${rel}:${i}"; $leak++ }
    }
}
if ($leak -gt 0) { Write-Host "[sync-template] Self-check failed: $leak identifier(s) remain."; exit 1 }
```

- [ ] **Step 6: 実行して違反 0 件で通ることを確認する**

```powershell
pwsh -NoProfile -File scripts/sync-template.ps1; "exit=$LASTEXITCODE"
```

期待: 違反の出力なし、7 ファイルが同期され、`exit=0`。

- [ ] **Step 7: 生成物に識別子が残っていないことを確認する**

```powershell
Get-ChildItem template -Recurse -File | Select-String -Pattern '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}' | Measure-Object | Select-Object -ExpandProperty Count
```

期待: `0`。改修前の同じコマンドの出力は **18**（`Select-String | Measure-Object` は一致した**行数**を数える）。出現回数で数えると 20（`folder-structure.md` 8 ＋ `retrospectives/README.md` 12）で、spec 03 の表はこちらの単位を使っている。単位の取り違えに注意すること。

- [ ] **Step 8: `-Check` が陳腐化を検出することを確認する**

```powershell
"`n<!-- probe -->" | Add-Content -NoNewline docs/inbox/README.md
pwsh -NoProfile -File scripts/sync-template.ps1 -Check; "exit=$LASTEXITCODE"
git checkout -- docs/inbox/README.md
```

期待: `content differs: docs/inbox/README.md` が出て `exit=1`。

- [ ] **Step 9: コミット**

```bash
git add scripts/sync-template.ps1 template
git commit -m "feat: sync-template.ps1 へ判定・変換・-Check を組み込む（ADR-0083）"
```

---

### Task 9: `CONTRIBUTING.md` への規約節の新設と配線

**Files:**
- Modify: `CONTRIBUTING.md`
- Modify: `skills/extend-guidelines/SKILL.md`
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md`（R3 本文の精緻化。Step 1 参照）

- [ ] **Step 1: 規約節を新設する**

`CONTRIBUTING.md` の「全シナリオ共通: 過剰適合の点検」節の直後へ、新しい節「全シナリオ共通: 配布対象ソースの記法規約」を追加する。内容は spec `01-provenance-notation-convention.md` の「出所識別子の定義」「プレースホルダの判別」「適用範囲」「規約（R1〜R5）」「R3 が必要な理由（実例）」を写す。

**R3 については規約文だけでは書き方を誤る**ことが Task 5 のレビューで実測された。次を明示する（あわせて spec 01 の R3 本文も同じ精度へ改める）:

- 複数の識別子を連結するときは、2 件目以降は 4 桁のみを書く（`- ADR-0084/0085: 説明` は可、`- ADR-0084/ADR-0085: 説明` と `- ADR-0084 / Issue-0033: 説明` は R3 違反になる）
- 説明を省いた `- ADR-0084` だけの行は R3 違反になる
- 区切りは半角コロン＋半角スペース 1 個で統一する（全角コロンやスペース無しは検査を通ってしまうため、規約側で書式を指定する）
- **出所リスト行は出所の索引であり、規範文・手順文を書く場所ではない**（配布物では行ごと削除されるため、手順文を書くと配布先で消える。実例として `retrospective/SKILL.md` の「意思決定の継続検出ルールは常時適用」の行が、行頭に識別子を置いたために削除対象になりかけた）

節末に執行点を書く:

```markdown
**執行点**: 配布対象ソースを変更したら、コミット前に `scripts/build-dist.ps1` と `scripts/sync-template.ps1` を実行する。規約違反があればいずれかが非ゼロ終了するため、修正しない限りコミットできる状態にならない。あわせて両者を `-Check` で実行し、生成漏れが無いことを確認する。
```

- [ ] **Step 2: 既存 4 シナリオのチェックリストへ確認項目を追加する**

次の 4 節のチェックリスト末尾へ、同じ 1 行を追加する（計 4 行）。

- 「シナリオ: Skillを新規作成・改定するとき」
- 「シナリオ: ワークフロー起点スキル（start-work）を変更するとき」
- 「シナリオ: 機能ブロック駆動の設計スキル（feature-block-design）を変更するとき」
- 「シナリオ: 振り返りスキル（retrospective）を変更するとき」

```markdown
- 配布対象ソースの記法規約に適合しているか（「全シナリオ共通: 配布対象ソースの記法規約」/ ADR-0083。`scripts/build-dist.ps1` が違反 0 件で通ることで確認する）
```

- [ ] **Step 3: `extend-guidelines` の手順 6 を拡張する**

現行は「テンプレートの同期を案内する」で `sync-template.ps1` のみを案内している。`skills/` の変更でも生成が必要になるため、次へ書き換える。

```markdown
### 6. 配布物の生成を案内する

拡張作業の完了後、配布対象ソース（`template.manifest` 記載ファイル / `skills/` 配下 / 空インデックス生成対象 3 ファイル）を変更した場合は、コミット前に次の実行が必要であることをユーザーに案内する。

- `scripts/build-dist.ps1` — プラグイン配布物の生成（`skills/` を変更した場合）
- `scripts/sync-template.ps1` — テンプレート配布物の生成（それ以外を変更した場合）

いずれも記法規約（ADR-0083）に違反があれば非ゼロ終了する。違反は修正してから再実行する。
```

- [ ] **Step 4: 配線が入ったことを確認する**

```powershell
Select-String -Path CONTRIBUTING.md -Pattern '配布対象ソースの記法規約' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path skills/extend-guidelines/SKILL.md -Pattern 'build-dist.ps1' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path CONTRIBUTING.md -Pattern '2 件目以降は 4 桁のみ' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path docs/current/specs/2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md -Pattern '2 件目以降は 4 桁のみ' | Measure-Object | Select-Object -ExpandProperty Count
```

期待: 1 本目は 5 以上（節見出し 1 ＋ チェックリスト 4）、2 本目は 1 以上、3・4 本目は 1 以上（R3 の書き方の精緻化が CONTRIBUTING と spec 01 の両方に入っていること）。

- [ ] **Step 5: `extend-guidelines` の変更を配布物へ反映する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1; "exit=$LASTEXITCODE"
```

期待: `exit=0`。

- [ ] **Step 6: コミット**

```bash
git add CONTRIBUTING.md skills/extend-guidelines/SKILL.md dist
git commit -m "docs: 配布対象ソースの記法規約を CONTRIBUTING へ新設し 4 シナリオへ配線（ADR-0083）"
```

---

### Task 10: ADR-0027 への部分修正注記

**Files:**
- Modify: `docs/records/decisions/0027-template-seed-criteria.md`

- [ ] **Step 1: Consequences の末尾へ注記を追加する**

Status は `Accepted` のまま変えない（`decision-log` の台帳監査における「部分修正あり（本体現役・状態変更なし）」の扱い）。

```markdown
- **部分修正（2026-08-07・ADR-0083）**: 本 ADR の「説明文は保持し、インデックス行のみ除去する」は、出所識別子については適用されなくなった。`sync-template.ps1` は保持した説明文からも出所識別子を除去する。空インデックス生成そのものの規約は変わらない。
```

- [ ] **Step 2: 注記が入ったことを確認する**

```powershell
Select-String -Path docs/records/decisions/0027-template-seed-criteria.md -Pattern '部分修正（2026-08-07' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path docs/records/decisions/0027-template-seed-criteria.md -Pattern '^- \*\*Status\*\*: Accepted' | Measure-Object | Select-Object -ExpandProperty Count
```

期待: どちらも `1`。

- [ ] **Step 3: コミット**

```bash
git add docs/records/decisions/0027-template-seed-criteria.md
git commit -m "docs: ADR-0027 へ ADR-0083 による部分修正の注記を追加"
```

---

### Task 11: プラグイン本番エントリの切り替え（構造 A の場合のみ）

**Files:**
- Modify: `.claude-plugin/marketplace.json`

構造 B を採用した場合、このタスクは不要（Step 1 だけを「該当なし」として飛ばす）。

- [ ] **Step 1: 本番エントリの `source` を変更する**

```json
      "source": "./dist"
```

- [ ] **Step 2: ユーザーへ再読み込みを依頼し、スキルが揃うことを確認する**

依頼: `/plugin marketplace update ai-driven-dev-principles`

確認: `Skill` ツールで `start-work` を起動し、ベースディレクトリが `<repo>/dist/skills/start-work` を指し、本文に出所識別子が含まれないこと。

**インストール記録の確認を省略しないこと。** Task 1 の実測で、同一マーケットプレイスから別のプラグインをインストールしたとき、既存プラグインのインストール記録が `installed_plugins.json` から消える事象が起きた（ガイドラインスキル 12 本が一覧から消失）。次で記録を確認する。

```powershell
python -c "import json,io; d=json.load(io.open(r'C:/Users/d12an/.claude/plugins/installed_plugins.json',encoding='utf-8')); [print(k) for k in d['plugins']]"
```

期待: `ai-driven-dev-principles@ai-driven-dev-principles` が含まれる。消えていたらユーザーへ `/plugin install ai-driven-dev-principles@ai-driven-dev-principles` を依頼して復旧する（Task 1 でこの手順により復旧を確認済み）。

- [ ] **Step 3: コミット**

```bash
git add .claude-plugin/marketplace.json
git commit -m "chore: プラグインの配布元を dist/ へ切り替える（ADR-0082）"
```

---

### Task 12: 全体検証

**Files:** なし（検証のみ）

- [ ] **Step 1: 両生成器が違反 0 件で通ることを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1; "build exit=$LASTEXITCODE"
pwsh -NoProfile -File scripts/sync-template.ps1; "sync exit=$LASTEXITCODE"
```

期待: どちらも `exit=0`、`Convention violations: 0`。

- [ ] **Step 2: 両生成物に識別子が残っていないことを確認する**

```powershell
$re = @('(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*#)?(?:ADR|Issue)-\d{4}',
        '(?<![A-Za-z0-9])(?:[A-Za-z][A-Za-z0-9]*)?-20\d\d-\d\d-\d\d(?:-\d\d)?')
(Get-ChildItem dist -Recurse -File -Exclude *.py,*.ps1 | Select-String -Pattern $re | Measure-Object).Count
(Get-ChildItem template -Recurse -File | Select-String -Pattern $re | Measure-Object).Count
```

期待: どちらも `0`。`dist/` 側でスクリプトを除外する理由は Task 7 Step 6 と同じ（コード部分は規約の適用対象外で、`check-store-health.py` に識別子 3 件が恒久的に残る）。`template/` にスクリプトは含まれないため除外は不要。

- [ ] **Step 3: `-Check` が同期済みの状態で成功することを確認する**

```powershell
pwsh -NoProfile -File scripts/build-dist.ps1 -Check; "build check=$LASTEXITCODE"
pwsh -NoProfile -File scripts/sync-template.ps1 -Check; "sync check=$LASTEXITCODE"
```

期待: どちらも `Up to date.` と `exit=0`。

- [ ] **Step 3-2: `build-dist.ps1 -Check` が生成漏れを検出することを確認する**

完了基準 2 は「**両生成物それぞれについて**」失敗経路を求めている。`sync-template.ps1` 側は Task 8 Step 8 で確認済みなので、ここで `build-dist.ps1` 側を確認する。

```powershell
$victim = (Get-ChildItem dist/skills -Recurse -File | Select-Object -First 1).FullName
$backup = "$env:TEMP/dist-check-probe.bak"
Move-Item $victim $backup
pwsh -NoProfile -File scripts/build-dist.ps1 -Check; "check=$LASTEXITCODE"
Move-Item $backup $victim
```

期待: `! missing in dist/: …` が出て `check=1`。復元後に `-Check` が `exit=0` へ戻ることも確認する。

- [ ] **Step 4: ライブラリの自己テストが通ることを確認する**

```powershell
pwsh -NoProfile -Command ". ./scripts/lib/strip-provenance.ps1; Invoke-StripProvenanceSelfTest"
```

期待: `all 17 cases passed`。

- [ ] **Step 5: 配布物の書式例が壊れていないことを目視で確認する**

```powershell
Select-String -Path dist/skills/session-handoff/SKILL.md -Pattern 'review=' -Context 0,2
Select-String -Path template/docs/overview/folder-structure.md -Pattern 'Issue-NNNN'
Select-String -Path dist/skills/worklog-record/references/store-format.md -Pattern '"id": *"X-'
Select-String -Path template/docs/overview/folder-structure.md -Pattern '# Issue-NNNN: <タイトル>'
```

期待: ハンドオフ書式から `review=` の記入規則が読み取れる。`Issue-NNNN` のプレースホルダが残っている。台帳レコード例が中立名で残っている。課題ファイルのひな形が壊れていない。

- [ ] **Step 5-2: 根拠列が出所を伝えることを確認する（spec 05 検証 4）**

過剰適合点検が「要是正」と判定した唯一の項目の実効性を確かめる。

```powershell
Select-String -Path dist/skills/subagent-dispatch/SKILL.md -Pattern '^\| ' -Context 0,0 | Select-Object -Last 15
```

期待: A 群 4 行・B 群 5 行の計 9 行すべてで、根拠列が空でなく出所が伝わる内容になっている。とくに補完対象の 3 行（ソースの 36・37・50 行に対応）に、件数・出所プロジェクト数・観測世代が残っていること。空セルが 1 つでもあれば Task 6 Step 4 の補完が不足している。

- [ ] **Step 6: 改行コードを確認する**

```powershell
$bad = Get-ChildItem dist,template -Recurse -File | Where-Object { (Get-Content $_.FullName -Raw) -match "`r" }
$bad.Count
```

期待: `0`（LF 固定。ADR-0033）。

- [ ] **Step 7: ADR を Accepted へ昇格する**

`decision-log` の「承認の昇格」に従う。粒度を点検（各 ADR のタイトルが本文の全決定に答えているか）してから、ADR-0081 / 0082 / 0083 の Status を `Accepted` へ変え、`docs/records/decisions/README.md` のステータスも更新する。

- [ ] **Step 8: Issue-0067 を close する**

`docs/working/issues/system/0067-*.md` の Status を `closed` にし、Closed 日付を入れ、「結論」へ ADR-0081 / 0082 / 0083 を記載する。`docs/working/issues/README.md` の該当行も更新する。

- [ ] **Step 9: インデックス変更を配布物へ反映してコミット**

```powershell
pwsh -NoProfile -File scripts/sync-template.ps1
```

```bash
git add docs/records/decisions docs/working/issues template
git commit -m "chore: ADR-0081/0082/0083 を Accepted へ昇格し Issue-0067 を close"
```

---

## 自己レビュー結果

**1. spec 網羅**: 5 ブロックすべてに対応タスクがある。01 → Task 9、02 → Task 2/3/4、03 → Task 8、04 → Task 1/11、05 → Task 5/6/7。完了基準 7 項目はいずれも Task 12 または個別タスクの検証ステップで判定される（基準 1 → Task 4、基準 2 → Task 8 Step 8・Task 12 Step 3、基準 3 → Task 12 Step 1、基準 4 → Task 12 Step 2、基準 5 → Task 1・Task 11、基準 6 → Task 9 Step 4、基準 7 → Task 10 Step 2）。

**2. プレースホルダ**: 「TBD」「後で」等は無い。移行タスク（5〜7）は行番号と変換の型を示し、検証を生成器の通過で担保している。Task 6 Step 4 の散文補完のみユーザー確認を条件としており、これは spec 05 の制約に由来する意図的な人間ゲートである。

**3. 型の整合**: `Test-ProvenanceConvention` / `Remove-ProvenanceNotation` / `Get-LineVerdict` / `Get-IdentifierMatch` / `Remove-ProvenanceFromLine` / `Invoke-StripProvenanceSelfTest` の 6 関数を Task 2/3 で定義し、Task 4/8 で同名で呼んでいる。自己テストの件数は Task 2 で 11、Task 3 で +6 して 17 とし、Task 12 Step 4 の期待値と一致させた。

**4. 順序**: Task 1（構造判定）が最初、移行（5〜7）が `sync-template.ps1` 改修（8）より前、`extend-guidelines` 改定（9）の後に配布物再生成を挟んでいる。
