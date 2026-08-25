# Codex 対応 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本ガイドライン（Layer 1 原則 / Layer 2 行動指示 / Layer 3 スキル群）を OpenAI Codex でも利用可能にし、GitHub Copilot CLI / Claude Code / Codex の 3 ツールで同一のガイドラインが機能する状態にする。

**Architecture:** Layer 2 は内容の正本をルート `AGENTS.md` へ移し、`CLAUDE.md` を `@AGENTS.md` インポートの 1 行に置き換える（3 ツールすべてが同一内容を起動時に読む）。Layer 3 は `.claude-plugin/` の 2 ファイルを正本のまま維持し、`scripts/build-dist.ps1` が Codex ネイティブの `.agents/plugins/marketplace.json`（ルート）と `dist/.codex-plugin/plugin.json` を導出生成する（マーケットプレイス定義の複写乖離を構造的に塞ぐ）。残りは README / CONTRIBUTING / スキル本文の 3 ツール中立化。

**Tech Stack:** PowerShell 7（生成器）、Markdown / JSON（成果物）、git。テストフレームワークは無く、検証は生成器の `-Check` モード・grep・実機 CLI（`codex debug prompt-input` / `claude -p`）による実測で行う。

**入力仕様:** `docs/current/specs/2026-08-25-codex-support-design.md`（確定済み）。関連 ADR: ADR-0110（スコープ・Accepted）/ ADR-0111（Layer 2・Proposed）/ ADR-0112（Layer 3・Proposed）。

---

## 実行環境の前提

- `pwsh` は PATH 上にある（PowerShell 7.6.5 で確認）。
- `codex` は PATH に無い。実行時は次で解決する（バージョン更新でハッシュ名ディレクトリが変わるため、パスをハードコードしない）:

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex --version
```

期待: `codex-cli 0.149.0-alpha.4.3`

- `claude` は PATH 上にある（2.1.241 で確認）。
- 本計画のコマンドはリポジトリルート `D:\Dev\002_AiDev\MakeAiInstructions` で実行する。

## ファイル構成（新規・変更の一覧と責務）

| ファイル | 操作 | 責務 |
|---|---|---|
| `AGENTS.md` | 新規 | Layer 2 の**内容の正本**。3 ツール共通のエージェント向け行動指示 |
| `CLAUDE.md` | 全置換 | `@AGENTS.md` の 1 行。Claude Code 向けの到達経路（ポインタ）のみを担う |
| `scripts/build-dist.ps1` | 変更 | dist 生成に加え、ルート生成物の生成と version 一致検査を担う |
| `scripts/check-claude-md-size.ps1` | 変更 | 計測対象を `AGENTS.md` へ切替（規範肥大監視の生存維持） |
| `scripts/sync-template.ps1` | 変更 | 末尾の計測呼び出しのコメント文言のみ追随 |
| `template.manifest` | 変更 | `AGENTS.md` を同期対象に追加 |
| `.claude-plugin/plugin.json` | 変更 | version 0.1.12・description の AGENTS.md 化 |
| `.claude-plugin/marketplace.json` | 変更 | version 0.1.12 |
| `.agents/plugins/marketplace.json` | 新規（生成物） | Codex ネイティブのマーケットプレイス定義。手編集しない |
| `dist/.codex-plugin/plugin.json` | 新規（生成物） | Codex 向けプラグインマニフェスト。手編集しない |
| `README.md` | 変更 | Codex インストール節・既存プロジェクト移行手順節の新設、3 ツール化 |
| `CONTRIBUTING.md` | 変更 | 設計思想 / 執行点 / シナリオ見出し・本文の追随 |
| `docs/overview/issue-management.md` | 変更 | 調整値参照の二段フォールバック化（1 箇所） |
| `docs/overview/folder-structure.md` | 変更 | 参照元名の AGENTS.md 化（1 箇所） |
| `skills/` 配下 9 ファイル | 変更 | CLAUDE.md 参照 18 箇所・ローカルスキルパス 3 箇所の中立化 |
| `docs/current/specs/2026-08-07-distributed-artifact-generation/` の 00 / 01 / 02 / 03 / 04 | 変更 | 配布物生成仕様のスナップショット同期（生成器の挙動・件数・配線表・配布構造図・参照先） |
| `docs/current/specs/2026-08-13-handoff-bloat-control/` の 01 / 02 | 変更 | `skills/session-handoff` の正本テキストを写している箇所の同期 |
| `docs/current/specs/2026-07-17-worklog-skill-pipeline/` の 00 / 04 | 変更 | `skills/worklog-skillify` の正本テキストを写している箇所の同期 |
| `docs/current/specs/2026-08-25-codex-support-design.md` | 変更 | 本サイクルの設計 spec 自身を実装内容へ同期 |
| `docs/records/decisions/0023-unify-layer2-into-claude-md.md` | 変更 | 部分修正注記（Decision 1・7） |
| `dist/` / `template/` | 生成物 | 各タスクで生成器を実行して同一コミットに含める |

## タスク間の順序制約

- **Task 2 は Task 1 の適用後にのみ実施できる**。Task 2 の挿入アンカー `Get-JsonProperty` は Task 1 が新設する関数であり、Task 2 が生成に使う `$pluginObj` / `$marketplaceObj` も Task 1 でしか定義されない。両タスクは `scripts/build-dist.ps1` の同一領域を編集するため、独立タスクとして並行・先行実行してはならない。
- **本計画の各タスクの「現 NN 行目」は、そのファイルへの本計画の編集を一切適用していない状態を基準とする**。先行タスクの挿入で実際の行番号はずれる（例: `scripts/build-dist.ps1` は Task 1 が 41 行を挿入するため、Task 2 が「現 67 行目」と呼ぶ行は Task 1 適用後には 108 行目付近になる）。**位置決めは行番号ではなく引用している置換前テキストで行うこと**。引用テキストはいずれも当該ファイル内で一意である。
- Task 3（Layer 2 切替）は **AGENTS.md 作成・CLAUDE.md ポインタ化・template.manifest 追加・計測対象切替・`template/` 再生成を 1 コミットにまとめる**。コミット前に作業ツリー上で Codex / Claude Code の再実測を行う（中間状態のコミットを作らないため）。
- Task 4・5・8 は生成器を実行し、生成物を同一コミットに含める（CONTRIBUTING「執行点」手順 3）。**生成物を伴う 5 コミット（Task 2・3・4・5・8）では、変更したのが片側でも両生成器を `-Check` で回す**（同手順 2 の「取りこぼさないよう変更範囲によらず両方を回す」）。
- **執行点手順 4（配布物の目視 5 項目）は 2 段で行う**。CONTRIBUTING「機械判定が届かない領域」は「目視は 1 回で終わらせず、生成後の配布物を読む工程を別に置くこと」と定めている（2026-08-08 の実測で、1 巡目が固有名 1 件を取り逃がし、自己参照が 3 度にわたり別の箇所で見つかったことが根拠）。**この規範は「コミット前の目視 1 回で済ませるな」という要求であり、1 回に集約する根拠にはならない**。したがって (1) 配布物の内容が実質的に変わる 2 つの生成コミット（Task 4 の skills 中立化＝`dist/skills/` の内容変更、Task 8 の description 変更＝`dist/` の両 plugin.json）では、コミット前に当該差分を目視する。(2) Task 11 Step 7 で、全体を読み直す独立工程としてもう 1 巡する。Task 2（生成物の新設）・Task 3・5（`template/` のみの変更）では、それぞれのステップに置いた個別の内容確認が目視を兼ねる。
- Task 9（仕様スナップショット同期）は Task 2・3・4・7 が終わってから行う（走査対象の実数が Task 2・3 に、`skills/` の正本テキストを写している spec の同期先が Task 3・4 の書き換え文言に、CONTRIBUTING のシナリオ見出し名が Task 7 に依存するため）。
- Task 11（検証）は Task 1〜10 の完了後に行う。
- Task 12（ADR 昇格）は Task 11 が通ってから行う。
- **既知の中間不整合（許容）**: Task 3 Step 6 で `check-claude-md-size.ps1` の警告文を「CONTRIBUTING.md「AGENTS.md を棚卸しするとき」」へ変えるが、CONTRIBUTING の当該見出しが改名されるのは Task 7 である。Task 3〜Task 6 の 4 コミットの間、警告文は存在しない見出しを案内する。この警告文は閾値超過時にしか出力されず、実測値は閾値の内側にあるため実行時に露出しない。Task 3 の「内容の異なる 2 ファイルを同居させない」制約は Layer 2 の**読み込み対象**についてのものであり、本件は対象が異なる。**この不整合を避けるために Task 3 Step 6 の 35 行目の書き換えだけを Task 7 へ遅らせることはしない**（`check-claude-md-size.ps1` の 5 箇所を 2 つのコミットに割ると、切替の全数が 1 コミットに揃わず取りこぼしを招くため）。

---

## Task 1: build-dist.ps1 に version 一致検査を追加する

**Files:**
- Modify: `scripts/build-dist.ps1`

正本 `.claude-plugin/plugin.json` の `version` と `.claude-plugin/marketplace.json` の `plugins[].version` は二重保持されており、これまで無検査だった。通常実行・`-Check` の**両モードの冒頭（規約判定より前）**で一致を検査し、不一致なら非ゼロ終了する。

- [ ] **Step 1: 現状では不一致が検出されないことを確認する（塞ぐ穴を先に見せる）**

`.claude-plugin/marketplace.json` の `"version": "0.1.11"` を `"version": "9.9.9"` へ一時的に書き換えてから:

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `[build-dist] Up to date.` と `exit=0`（version が食い違っているのに検出されない）。

- [ ] **Step 2: 検査の実装を入れる**

`scripts/build-dist.ps1` の 16-17 行目

```powershell
$pluginJsonPath = Join-Path $repoRoot '.claude-plugin/plugin.json'
$pluginRel = '.claude-plugin/plugin.json'
```

を次に置き換える:

```powershell
$pluginJsonPath = Join-Path $repoRoot '.claude-plugin/plugin.json'
$pluginRel = '.claude-plugin/plugin.json'
$marketplaceJsonPath = Join-Path $repoRoot '.claude-plugin/marketplace.json'
$marketplaceRel = '.claude-plugin/marketplace.json'
```

続いて、`Get-RepoRelativePath` 関数定義の閉じ括弧（現 23 行目）の直後へ次のヘルパを追加する:

```powershell
# JSON の欠損プロパティを Set-StrictMode の例外ではなく $null で受ける（例外スタックを
# 生で出さず接頭辞つきの診断で止めるため）
function Get-JsonProperty {
    param($Object, [string]$Name)
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $null
}
```

さらに、plugin.json 存在チェック（現 26-29 行目の `if (-not (Test-Path $pluginJsonPath)) { ... }`）の直後へ次を追加する:

```powershell
if (-not (Test-Path $marketplaceJsonPath)) {
    Write-Host "[build-dist] marketplace.json not found: $marketplaceJsonPath"
    exit 1
}

# 0. version 一致検査。正本が 2 ファイルに分かれて version を二重保持しているため、
#    規約判定より前・両モード共通で突合する。-Check でも走らせないと執行点手順 2 の
#    ゲートにならない（ADR-0112）。
$pluginObj = [System.IO.File]::ReadAllText($pluginJsonPath) | ConvertFrom-Json
$marketplaceObj = [System.IO.File]::ReadAllText($marketplaceJsonPath) | ConvertFrom-Json
$srcVersion = Get-JsonProperty $pluginObj 'version'
if ($null -eq $srcVersion) {
    Write-Host "[build-dist] version not found in $pluginRel"
    exit 1
}
$versionMismatch = 0
$pluginIndex = 0
foreach ($p in @(Get-JsonProperty $marketplaceObj 'plugins')) {
    $pv = Get-JsonProperty $p 'version'
    if ($pv -ne $srcVersion) {
        $pn = Get-JsonProperty $p 'name'
        Write-Host "  ! version mismatch: $marketplaceRel plugins[$pluginIndex] ($pn) = $pv, $pluginRel = $srcVersion"
        $versionMismatch++
    }
    $pluginIndex++
}
if ($versionMismatch -gt 0) {
    Write-Host "[build-dist] Aborted. $versionMismatch version mismatch(es). Generated artifacts were not modified."
    exit 1
}
```

- [ ] **Step 3: 不一致で非ゼロ終了することを確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `  ! version mismatch: .claude-plugin/marketplace.json plugins[0] (ai-driven-dev-principles) = 9.9.9, .claude-plugin/plugin.json = 0.1.11` と `[build-dist] Aborted. 1 version mismatch(es). Generated artifacts were not modified.`、`exit=1`。

通常実行でも同じ位置で止まることを確認する:

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "exit=$?"; git status --short dist
```

期待: 同じ診断と `exit=1`。`git status --short dist` の出力は空（`dist/` に触れていない）。

- [ ] **Step 4: 正本を復元し、一致時は従来どおり通ることを確認する**

```bash
git checkout -- .claude-plugin/marketplace.json
```

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `[build-dist] Up to date.` と `exit=0`。

- [ ] **Step 5: コミットする**

```bash
git add scripts/build-dist.ps1 && git commit -m "feat: build-dist に plugin.json と marketplace.json の version 一致検査を追加"
```

コミットメッセージ本文（`-m` を 2 つ目に足す）:

```
正本が 2 ファイルに分かれて version を二重保持しており無検査だった乖離点を、
生成器の両モード冒頭で塞ぐ（ADR-0112）。-Check でも走らせることで
CONTRIBUTING 執行点の手順 2 がゲートとして機能するようにする。
```

---

## Task 2: build-dist.ps1 の出力先を一般化し Codex 向け 2 生成物を導出する

**Files:**
- Modify: `scripts/build-dist.ps1`
- Create（生成物）: `.agents/plugins/marketplace.json`
- Create（生成物）: `dist/.codex-plugin/plugin.json`

`dist/` 配下の生成物は従来どおりディレクトリ走査（wipe・stale 検出・自己検査）で扱う。ルート直下の生成物は**既知パスのホワイトリストに対するファイル単位の生成・存在・内容比較**とし、「余分なファイルの不在」条件を適用しない（リポジトリルートを走査すると全ファイルが陳腐化判定となり、wipe に含めれば不可逆事故になるため）。

固定マッピングの値は Codex ネイティブ marketplace の実例（`openai-bundled` および superpowers 6.3.0）から採る。2026-08-25 に codex-cli 0.149.0-alpha.4.3 の実環境で確認した値:

| キー | 値 | 出所 |
|---|---|---|
| `interface.displayName`（marketplace / plugin 共通） | `AI-Driven Dev Principles` | 本プロジェクトで命名 |
| `category` | `Developer Tools` | superpowers 6.3.0 の `.codex-plugin/plugin.json` と同値 |
| `policy.installation` | `AVAILABLE` | 実環境の実例はすべてこの単一値 |
| `policy.authentication` | `ON_INSTALL` | superpowers と同値（語彙には `ON_USE` もあるが、認証を伴わないプラグインの実例が `ON_INSTALL` を採っている） |
| `skills` | `./skills/` | 仕様で固定 |

- [ ] **Step 1: 生成物がまだ無いことを確認する**

```bash
ls .agents/plugins/marketplace.json dist/.codex-plugin/plugin.json 2>&1
```

期待: 両方とも `No such file or directory`。

- [ ] **Step 2: 固定マッピングと JSON 組み立てのヘルパを追加する**

`scripts/build-dist.ps1` の `Get-JsonProperty` 関数定義の直後へ次を追加する:

```powershell
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
    $mpName = ConvertTo-JsonStringValue (Get-JsonProperty $Source 'name')
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
    $pName    = ConvertTo-JsonStringValue (Get-JsonProperty $Source 'name')
    $pVersion = ConvertTo-JsonStringValue (Get-JsonProperty $Source 'version')
    $pDesc    = ConvertTo-JsonStringValue (Get-JsonProperty $Source 'description')
    $pAuthor  = ConvertTo-JsonStringValue (Get-JsonProperty (Get-JsonProperty $Source 'author') 'name')
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
```

- [ ] **Step 3: 生成内容の組み立てへ 2 生成物を足す**

`$generated["dist/$pluginRel"] = $pluginContent` の行（本計画未適用時の 67 行目。Task 1 適用後は 108 行目付近）の直後へ次を追加する:

```powershell
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
```

- [ ] **Step 4: 中断条件へルート生成物の漏れを含める**

現 76-84 行目

```powershell
if ($pluginLeaks.Count -gt 0) {
    foreach ($lk in $pluginLeaks) {
        Write-Host "  ! identifier in ${pluginRel}:$($lk.Line)  $($lk.Text)"
    }
}
if ($allViolations.Count -gt 0 -or $pluginLeaks.Count -gt 0) {
    Write-Host '[build-dist] Aborted. dist/ was not modified.'
    exit 1
}
```

を次に置き換える:

```powershell
if ($pluginLeaks.Count -gt 0) {
    foreach ($lk in $pluginLeaks) {
        Write-Host "  ! identifier in ${pluginRel}:$($lk.Line)  $($lk.Text)"
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
```

- [ ] **Step 5: `-Check` にルート生成物のファイル単位突合を足す**

`foreach ($rel in $bomFiles) { Write-Host "  ! BOM found: $rel"; $diff++ }` の行（現 116 行目付近）の直後へ次を追加する:

```powershell
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
```

- [ ] **Step 6: 書き出しにルート生成物を足す**

現 132 行目

```powershell
Write-Host '[build-dist] Generating dist/ ...'
```

を次に置き換える:

```powershell
Write-Host '[build-dist] Generating dist/ and root artifacts ...'
```

dist の書き出しループ（現 134-139 行目の `foreach ($k in $generated.Keys) { ... }`）の直後へ次を追加する:

```powershell
# ルート直下の生成物はホワイトリストのファイル単位で上書きする（wipe はしない）
foreach ($rk in $rootGenerated.Keys) {
    $rdest = Join-Path $repoRoot $rk
    $rdestDir = Split-Path -Parent $rdest
    if (-not (Test-Path $rdestDir)) { New-Item -ItemType Directory -Path $rdestDir -Force | Out-Null }
    [System.IO.File]::WriteAllText($rdest, $rootGenerated[$rk], $utf8)
}
```

- [ ] **Step 7: 完了メッセージを新しい出力先の構成に合わせる**

現 154 行目

```powershell
Write-Host "[build-dist] Done. $($generated.Count) files written to dist/."
```

を次に置き換える:

```powershell
Write-Host "[build-dist] Done. $($generated.Count) files written to dist/, $($rootGenerated.Count) to repository root."
```

- [ ] **Step 8: 生成して内容を確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "exit=$?"
```

期待: `[build-dist] Done. 20 files written to dist/, 1 to repository root.` と `exit=0`。

```bash
cat .agents/plugins/marketplace.json
```

期待（完全一致）:

```json
{
  "name": "ai-driven-dev-principles",
  "interface": {
    "displayName": "AI-Driven Dev Principles"
  },
  "plugins": [
    {
      "name": "ai-driven-dev-principles",
      "source": {
        "source": "local",
        "path": "./dist"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
```

```bash
cat dist/.codex-plugin/plugin.json
```

期待（`description` は正本 `.claude-plugin/plugin.json` の現在値の複写。Task 8 で正本を更新するまでは CLAUDE.md 表記のままでよい）:

```json
{
  "name": "ai-driven-dev-principles",
  "version": "0.1.11",
  "description": "AI駆動開発ガイドラインを実装するスキル群（start-work, decision-log, session-handoff, feature-block-design, retrospective ほか）。導入先プロジェクトの CLAUDE.md と組み合わせて使用する。",
  "author": {
    "name": "taika-izumi"
  },
  "skills": "./skills/",
  "interface": {
    "displayName": "AI-Driven Dev Principles",
    "category": "Developer Tools"
  }
}
```

改行が LF・BOM 無しであることを確認する:

```bash
file .agents/plugins/marketplace.json dist/.codex-plugin/plugin.json
```

期待: いずれの行にも `with CRLF line terminators` と `with BOM` が現れないこと。

- [ ] **Step 9: 両生成器の `-Check` が一致を返すことを確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
```

期待: `[build-dist] Up to date.` と `[sync-template] Up to date.`、両方とも `=0`。

**変更したのが片側でも両生成器を回す**（CONTRIBUTING「執行点」手順 2 の「取りこぼさないよう変更範囲によらず両方を回す」）。以降の生成コミットでも同じ扱いとする。

- [ ] **Step 10: ルート生成物の陳腐化・欠損が検出されることを確認する**

```bash
printf 'x' >> .agents/plugins/marketplace.json && pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `  ! content differs: .agents/plugins/marketplace.json` と `exit=1`。

```bash
rm .agents/plugins/marketplace.json && pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `  ! missing: .agents/plugins/marketplace.json` と `exit=1`。

- [ ] **Step 11: ルート側に「余分なファイルの不在」条件が適用されていないことを確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1 && printf 'scratch\n' > .agents/plugins/EXTRA.txt && pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"; rm -f .agents/plugins/EXTRA.txt; ls .agents/plugins/
```

期待: `[build-dist] Up to date.` と `exit=0`（生成物以外のファイルが同じディレクトリにあっても陳腐化と判定しない）。末尾の `ls` が `marketplace.json` の 1 件のみを返すこと。

**削除を同じコマンド列に連ねているのは意図的である**——このステップ自身が示すとおり生成器は `.agents/` 配下の余分なファイルを一切報告しない。削除を別ブロックに分けて飛ばすと Step 12・13 も `-Check` も通ってしまい、Step 14 の `git add .agents` がスクラッチファイルをリポジトリルート直下の Codex マーケットプレイス定義ディレクトリへ入れる。Task 11 Step 4 のパス限定 `git status` はコミット済みなので空を返し、Task 11 Step 7 の目視は `dist/` と `template/` しか見ないため、以降のどの検証でも捕捉されない。

- [ ] **Step 12: dist の wipe がルート生成物を消さないことを確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1 && test -f .agents/plugins/marketplace.json && echo "root artifact survived"
```

期待: `root artifact survived`。

- [ ] **Step 13: 正本の異常入力でガードが働くことを確認する**

`.claude-plugin/` の正本を一時的に書き換えて 7 通りを確かめ、いずれも診断を出して非ゼロ終了することを確認する。各確認のあと `git checkout -- <書き換えたファイル>` で復元する。

（4・5 は ADR-0113 により追加＝Task 1 のコード品質レビューで検出した診断品質の穴を本タスクで塞いだことの検証。6・7 は ADR-0113 の追加決定により追加＝Task 2 のコード品質レビューで検出した型・欠損ガードの非対称を塞いだことの検証で、書き換え対象は `.claude-plugin/plugin.json` を含む。）

1. `plugins[0].source` を文字列 `"./dist"` からオブジェクト `{"source":"github","repo":"taika-izumi/ai-driven-dev-principles"}` へ変える

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "exit=$?"
```

期待: `[build-dist] plugin source must be a string path for the Codex marketplace: .claude-plugin/marketplace.json plugins[0].source is PSCustomObject` と `exit=1`。**ガードが無いと、この入力は `"path": "@{source=github; repo=taika-izumi/ai-driven-dev-principles}"` という壊れた値を無診断で出力し、`-Check` も自己一致で `exit=0` を返す**（Codex 側でのみ解決不能になる）。

2. `plugins` を空配列 `[]` にする

期待: `[build-dist] no plugins found in .claude-plugin/marketplace.json` と `exit=1`。

3. `plugins[0].name` を空文字列にする

期待: `[build-dist] plugin name is missing or empty in .claude-plugin/marketplace.json plugins[0]` と `exit=1`。

4. `plugins` キーを丸ごと削除する（`{"name": "ai-driven-dev-principles"}` のみにする）

期待: `[build-dist] no plugins found in .claude-plugin/marketplace.json` と `exit=1`。**ADR-0113 の差分 2 を入れる前は、`@($null)` が 1 回反復するため実在しない `plugins[0] () = ` の「version 不一致」として報告されていた。**

5. JSON として不正にする（例: 末尾の `}` を削る）

期待: `[build-dist] invalid JSON: .claude-plugin/marketplace.json (...)` の形の 1 行と `exit=1`。**ADR-0113 の差分 1 を入れる前は、`[build-dist]` 接頭辞のない ParserError の生スタックが出ていた。**

6. `.claude-plugin/plugin.json` の `description` をオブジェクトへ変える

期待: `[build-dist] description must be a non-empty string: .claude-plugin/plugin.json (PSCustomObject)` と `[build-dist] Aborted. Generated artifacts were not modified.`、`exit=1`。**ADR-0113 の追加決定を入れる前は、`"description": "@{ja=説明; en=desc}"` という壊れた値を無診断で出荷して `exit=0` を返し、`-Check` も自己一致で通り続けていた。**

7. `.claude-plugin/plugin.json` から `name` キーを削除する／`.claude-plugin/marketplace.json` から `name` キーを削除する

期待: それぞれ `[build-dist] name must be a non-empty string: .claude-plugin/plugin.json (missing)` / `... .claude-plugin/marketplace.json (missing)` と `exit=1`。

7 通りとも復元後、`pwsh -NoProfile scripts/build-dist.ps1 -Check` が `[build-dist] Up to date.` と `exit=0` を返すことを確認する。各ケースで `dist/` とルート生成物が書き換わっていないことをハッシュで確認する。

- [ ] **Step 14: コミットする**

```bash
git add scripts/build-dist.ps1 .agents dist && git commit -m "feat: build-dist が Codex 向け 2 生成物を導出する"
```

コミットメッセージ本文:

```
.agents/plugins/marketplace.json（ルート）と dist/.codex-plugin/plugin.json を
.claude-plugin/ の 2 正本から導出生成する（ADR-0112）。ルート直下の生成物は
既知パスのホワイトリストに対するファイル単位の生成・突合とし、wipe・stale 検出・
ディレクトリ走査の自己検査は従来どおり dist/ に限定する。

正本の source が object 形式のときに壊れた path を無診断で出力し -Check も通って
しまう経路があるため、文字列であることのガードを置く。plugins の 0 件・name の
空も同様に停止させる（検出したら黙認せず止める規律。ADR-0054）。
```

---

## Task 3: Layer 2 を AGENTS.md 正本へ切り替える（1 コミット）

**Files:**
- Rename: `CLAUDE.md` → `AGENTS.md`（`git mv`。内容の履歴を残すため新規作成＋削除にしない）
- Create: `CLAUDE.md`（`@AGENTS.md` の 1 行）
- Modify: `template.manifest`
- Modify: `scripts/check-claude-md-size.ps1`
- Modify: `scripts/sync-template.ps1`
- Generated: `template/AGENTS.md`・`template/CLAUDE.md`

**このタスクは中間状態をコミットしない。** Copilot CLI は `AGENTS.md` と `CLAUDE.md` の両方を読むため、内容の異なる 2 ファイルが同時に存在する状態を履歴に残さない。再実測（Step 7・8）は作業ツリー上のファイルに対して行えばよく、コミットは要らない。

**実行中セッションへの影響**: 本タスクを実行している Claude Code セッションは、起動時に読み込んだ旧 `CLAUDE.md` の内容を保持し続ける。`@AGENTS.md` の展開はセッション起動時に行われるため、切替の効果は次回セッションから現れる。Step 8 の `claude -p` は別プロセスとして起動するため、この影響を受けずに確認できる。

- [ ] **Step 1: CLAUDE.md を AGENTS.md へ改名する**

```bash
git mv CLAUDE.md AGENTS.md && ls AGENTS.md CLAUDE.md 2>&1
```

期待: `AGENTS.md` が存在し、`CLAUDE.md` は `No such file or directory`。

- [ ] **Step 2: AGENTS.md の前提条件節を 3 ツール化する**

`AGENTS.md` の 7 行目

```
本ガイドラインで指示する `start-work`, `decision-log`, `session-handoff`, `feature-block-design`, `pre-action-review`, `retrospective`, `extend-guidelines` などのスキルは、プラグイン `ai-driven-dev-principles` から提供される。本ファイルが配置されたプロジェクトで作業する前に、利用するツール（GitHub Copilot CLI または Claude Code）に当該プラグインをインストール・有効化しておくこと。
```

を次に置き換える:

```
本ガイドラインで指示する `start-work`, `decision-log`, `session-handoff`, `feature-block-design`, `pre-action-review`, `retrospective`, `extend-guidelines` などのスキルは、プラグイン `ai-driven-dev-principles` から提供される。本ファイルが配置されたプロジェクトで作業する前に、利用するツール（GitHub Copilot CLI / Claude Code / OpenAI Codex のいずれか）に当該プラグインをインストール・有効化しておくこと。
```

9 行目

```
インストール手順はガイドライン配信元リポジトリ（[taika-izumi/ai-driven-dev-principles](https://github.com/taika-izumi/ai-driven-dev-principles)）の README を参照（GitHub Copilot CLI 利用時は「Copilot CLI へのインストール」節、Claude Code 利用時は「Claude Code へのインストール」節）。
```

を次に置き換える:

```
インストール手順はガイドライン配信元リポジトリ（[taika-izumi/ai-driven-dev-principles](https://github.com/taika-izumi/ai-driven-dev-principles)）の README を参照（GitHub Copilot CLI 利用時は「Copilot CLI へのインストール」節、Claude Code 利用時は「Claude Code へのインストール」節、OpenAI Codex 利用時は「Codex へのインストール」節）。
```

- [ ] **Step 3: 構造化質問ツールの例示から「2 ツールのみ前提」の読みを外す**

`AGENTS.md` の 76 行目

```
- 質問・意思決定要求はすべてテキストのみのターンで行い、説明に続けて番号付き選択肢を提示すること。構造化された質問ツール（GitHub Copilot CLI の ask_user、Claude Code の AskUserQuestion 等）は、モデル・ツール・環境設定を問わず使用しないこと
```

を次に置き換える:

```
- 質問・意思決定要求はすべてテキストのみのターンで行い、説明に続けて番号付き選択肢を提示すること。構造化された質問ツール（GitHub Copilot CLI の ask_user、Claude Code の AskUserQuestion など、選択肢を UI 部品として提示するツール全般）は、モデル・ツール・環境設定を問わず使用しないこと
```

この変更は規範の適用条件を変えない（元の文が既に「モデル・ツール・環境設定を問わず」と定めている）。例示が 2 ツールに閉じていた表現を開くだけであり、ADR は起こさない。

- [ ] **Step 4: CLAUDE.md をポインタとして作り直す**

`CLAUDE.md` を新規作成し、内容を次の 1 行のみとする（末尾に改行 1 個）:

```
@AGENTS.md
```

```bash
printf '@AGENTS.md\n' > CLAUDE.md && cat -A CLAUDE.md
```

期待: `@AGENTS.md$` の 1 行のみ（`^M` が付かないこと）。

- [ ] **Step 5: template.manifest へ AGENTS.md を追加する**

`template.manifest` の

```
# ADR-0016 により、skills/ 関連エントリは template から除外している
# （スキル本体は GitHub Copilot CLI / Claude Code プラグイン ai-driven-dev-principles から提供されるため）

CLAUDE.md
```

を次に置き換える:

```
# ADR-0016 により、skills/ 関連エントリは template から除外している
# （スキル本体は GitHub Copilot CLI / Claude Code / OpenAI Codex プラグイン ai-driven-dev-principles から提供されるため）
#
# AGENTS.md が Layer 2 の内容正本であり、CLAUDE.md は @AGENTS.md インポートの
# ポインタ 1 行である（ADR-0111）。両方を同期対象に含める

AGENTS.md
CLAUDE.md
```

- [ ] **Step 6: 計測対象を AGENTS.md へ切り替える（ハードコード 5 箇所）**

`scripts/check-claude-md-size.ps1` の次の 5 箇所を書き換える（ファイル名 `check-claude-md-size.ps1` そのものは改名しない）。

2 行目:

```powershell
# CLAUDE.md（常時指示）の規模を計測し、閾値超過時に棚卸しを促す警告を出す（ADR-0040）
```

→

```powershell
# AGENTS.md（常時指示）の規模を計測し、閾値超過時に棚卸しを促す警告を出す（ADR-0040）
```

17 行目:

```powershell
$targetPath = Join-Path $repoRoot "CLAUDE.md"
```

→

```powershell
$targetPath = Join-Path $repoRoot "AGENTS.md"
```

20 行目:

```powershell
    Write-Warning "[check-claude-md-size] CLAUDE.md not found at $targetPath"
```

→

```powershell
    Write-Warning "[check-claude-md-size] AGENTS.md not found at $targetPath"
```

29 行目:

```powershell
Write-Host "[check-claude-md-size] CLAUDE.md: $bytes bytes (threshold $maxBytes), $bulletCount bullets (threshold $maxBullets), $lineCount lines"
```

→

```powershell
Write-Host "[check-claude-md-size] AGENTS.md: $bytes bytes (threshold $maxBytes), $bulletCount bullets (threshold $maxBullets), $lineCount lines"
```

35 行目:

```powershell
    Write-Warning "[check-claude-md-size] 閾値を超過しています。CONTRIBUTING.md「CLAUDE.md を棚卸しするとき」の実施を検討してください。"
```

→

```powershell
    Write-Warning "[check-claude-md-size] 閾値を超過しています。CONTRIBUTING.md「AGENTS.md を棚卸しするとき」の実施を検討してください。"
```

`scripts/sync-template.ps1` の末尾（235 行目付近）:

```powershell
# CLAUDE.md 規模計測（ADR-0040。警告のみで同期はブロックしない）
```

→

```powershell
# AGENTS.md 規模計測（ADR-0040。警告のみで同期はブロックしない）
```

計測が生きていることを確認する:

```bash
pwsh -NoProfile scripts/check-claude-md-size.ps1
```

期待: `[check-claude-md-size] AGENTS.md: 8069 bytes (threshold 12000), 25 bullets (threshold 45), 92 lines`、`exit=0`、警告行なし。バイト数は Step 2・3 の文言追加により切替前の 7,915 バイトから約 150 バイト増える（8,000 台前半で閾値 12000 の内側であればよい）。`AGENTS.md not found` が出たら Step 1 の改名か本ステップの書き換えが漏れている。

**5 箇所すべてが書き換わったことを実測で確認する**（Task 11 Step 6 (a) の網羅性 grep でも同じ漏れを捕捉できるが、そこは実装の最後であり、ここで確定させたほうが手戻りが小さい）:

```bash
grep -n "CLAUDE" scripts/check-claude-md-size.ps1 scripts/sync-template.ps1
```

期待: 出力が空（大文字 `CLAUDE` が 2 スクリプトのどこにも残っていない。スクリプト名 `check-claude-md-size.ps1` は小文字のため一致しない）。空でなければ 5 箇所のいずれかが未書き換えである。

- [ ] **Step 7: Codex 側の注入を作業ツリーで再実測する**

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex debug prompt-input | Out-File -Encoding utf8 "$env:TEMP\codex-prompt-input.json"
@(Select-String -Path "$env:TEMP\codex-prompt-input.json" -Pattern 'プロジェクトエージェント指示').Count
@(Select-String -Path "$env:TEMP\codex-prompt-input.json" -Pattern '意思決定の即時記録').Count
@(Select-String -Path "$env:TEMP\codex-prompt-input.json" -SimpleMatch -Pattern '@AGENTS.md').Count
```

期待: 最初の 2 つが 1 以上（AGENTS.md 本文が注入されている）、3 つ目が 0（ポインタ化した CLAUDE.md は注入されない）。

- [ ] **Step 8: Claude Code 側のインポート展開を作業ツリーで再実測する**

```bash
claude -p "このプロジェクトのエージェント指示の冒頭見出しを、説明を付けずに1行だけそのまま出力して。"
```

期待: 出力に `# プロジェクトエージェント指示` が含まれる（`CLAUDE.md` の `@AGENTS.md` が展開され、AGENTS.md 本文がモデルへ届いている）。

`claude -p` が非対話で実行できない環境だった場合は、その旨を handoff の「既知のブロッカー・懸念」へ記録し、spec の検証 7（次セッションの `/context` によるユーザー確認）へ委ねる。**Step 7 が通っていない場合はコミットへ進まない**（Codex 側は本サイクルの主目的であり、代替の確認手段が無い）。

- [ ] **Step 9: template を再生成する**

```bash
pwsh -NoProfile scripts/sync-template.ps1; echo "exit=$?"
```

期待: `[sync-template] Done. 9 files synced to template/` と `exit=0`、末尾に `[check-claude-md-size] AGENTS.md: ...` の計測行。

```bash
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
ls template/AGENTS.md template/CLAUDE.md && cat template/CLAUDE.md
```

期待: 両 `-Check` とも `=0`（変更したのが片側でも両生成器を回す。CONTRIBUTING「執行点」手順 2）。`template/AGENTS.md` と `template/CLAUDE.md` の両方が存在し、`template/CLAUDE.md` は `@AGENTS.md` の 1 行。

- [ ] **Step 10: 1 コミットで確定する**

```bash
git add AGENTS.md CLAUDE.md template.manifest scripts/check-claude-md-size.ps1 scripts/sync-template.ps1 template && git commit -m "feat: Layer 2 の内容正本を AGENTS.md へ移し CLAUDE.md をポインタ化"
```

コミットメッセージ本文:

```
Codex は AGENTS.md を読み CLAUDE.md を読まないため、内容の正本を AGENTS.md へ移し、
CLAUDE.md は公式サポートされた @AGENTS.md インポートの 1 行にする（ADR-0111）。
3 ツールすべてが同一内容を起動時に読む状態になる。

ポインタ化した CLAUDE.md を測り続けると規範肥大監視が無音化するため、
check-claude-md-size.ps1 の計測対象も AGENTS.md へ切り替える（ADR-0040）。

内容の異なる 2 ファイルが同居する区間を履歴に作らないため、改名・ポインタ化・
manifest 追加・計測対象切替・template 再生成を 1 コミットにまとめている。
コミット前に作業ツリーで codex debug prompt-input と claude -p による再実測を実施済み。
```

---

## Task 4: skills 配下の参照を中立化する

**Files:**
- Modify: `skills/decision-log/SKILL.md`（1 箇所）
- Modify: `skills/extend-guidelines/SKILL.md`（2 箇所）
- Modify: `skills/retrospective/SKILL.md`（1 箇所）
- Modify: `skills/session-handoff/SKILL.md`（4 箇所）
- Modify: `skills/start-work/SKILL.md`（3 箇所）
- Modify: `skills/worklog-extract/SKILL.md`（1 箇所＋ローカルスキルパス 1 箇所）
- Modify: `skills/worklog-record/SKILL.md`（1 箇所）
- Modify: `skills/worklog-skillify/SKILL.md`（4 箇所＋ローカルスキルパス 2 箇所）
- Modify: `skills/worklog-skillify/references/skill-authoring-techniques.md`（1 箇所）
- Generated: `dist/`

参照は 2 種類に分ける。

- **二段フォールバック型（7 箇所）**: プロジェクト側の調整値を読む参照。プラグイン（全配布先へ即時反映）と template（手動同期）の反映時期がずれるため、AGENTS.md に調整値が無い移行途中のプロジェクトで CLAUDE.md 側の値を読み飛ばさないようにする。**ファイルの有無ではなく調整値の記載の有無で探索する**
- **AGENTS.md 化（11 箇所）**: Layer 2 ファイルそのものを指す参照。単純に名前を差し替える。ただしこのうち 1 箇所（`skills/worklog-skillify/SKILL.md` のスコープ 3 分岐表）は Layer 2 への**書き込み**点であり、ADR-0114 により二段フォールバックを添える

- [ ] **Step 1: 現状の件数を実測しておく**

```bash
grep -o "CLAUDE\.md" -r skills/ | wc -l
grep -rn "\.claude/skills" skills/ | wc -l
```

期待: 前者 `18`、後者 `3`。

- [ ] **Step 2: 二段フォールバック型 6 箇所を書き換える（同一文言）**

次の 6 箇所は、いずれも `プロジェクトの CLAUDE.md に調整値があればそれを優先` という同一の句を含む。この句を `プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先` へ置き換える（ADR-0114 により「当該調整値の」を含む形へ改めた。目的語の前方参照を避け、ファイルの不在との読み違いを塞ぐ）（`優先する` と語尾が続く箇所は語尾を保つ）。

- `skills/decision-log/SKILL.md:158`
- `skills/retrospective/SKILL.md:90`
- `skills/session-handoff/SKILL.md:163`
- `skills/session-handoff/SKILL.md:180`
- `skills/session-handoff/SKILL.md:219`
- `skills/worklog-extract/SKILL.md:37`

```bash
grep -c "プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先" -r skills/ | grep -v ":0"
```

期待: **4 行**が列挙され、件数の合計が 6 になる（`grep -c` はファイル 1 件につき 1 行を返すため、6 箇所を含む 4 ファイル分の行が出る）。具体的には `skills/decision-log/SKILL.md:1` / `skills/retrospective/SKILL.md:1` / `skills/session-handoff/SKILL.md:3` / `skills/worklog-extract/SKILL.md:1`。

- [ ] **Step 3: 二段フォールバック型の残り 1 箇所（書き込み側）を書き換える**

`skills/session-handoff/SKILL.md:113`

```
字数はすべて全角換算の**デフォルト値**である。プロジェクトが調整する場合は自プロジェクトの CLAUDE.md に調整値を明記し、調整値を優先する。
```

を次に置き換える（この箇所は「読む」ではなく「書く」指示のため、二段フォールバックを読み側の但し書きとして添える）:

```
字数はすべて全角換算の**デフォルト値**である。プロジェクトが調整する場合は自プロジェクトの AGENTS.md に調整値を明記し、調整値を優先する（AGENTS.md に調整値の記載が無い場合は CLAUDE.md の調整値を読む）。
```

- [ ] **Step 4: AGENTS.md 化 11 箇所を書き換える**

`skills/extend-guidelines/SKILL.md:3`（フロントマターの description）

```
description: "ガイドラインの拡張（原則追加・Skillの新規作成/改定・CLAUDE.md更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
```

→

```
description: "ガイドラインの拡張（原則追加・Skillの新規作成/改定・AGENTS.md更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
```

`skills/extend-guidelines/SKILL.md:24`

```
- CLAUDE.md を更新したい
```

→

```
- AGENTS.md を更新したい
```

`skills/start-work/SKILL.md:16`: 文中の `` （`CLAUDE.md` でも宣言されている） `` を `` （`AGENTS.md` でも宣言されている） `` へ（全角括弧まで含めた形が実ファイルの表記。インラインコード表記のパディング空白をアンカーに含めないこと）。

`skills/start-work/SKILL.md:117` と `skills/start-work/SKILL.md:121`: いずれも `CLAUDE.md「ユーザーへの質問と意思決定要求」` を `AGENTS.md「ユーザーへの質問と意思決定要求」` へ。

`skills/worklog-record/SKILL.md:29`

```
- (a) 既存スキル・原則・CLAUDE.md で既に実施している作業では**ない**
```

→

```
- (a) 既存スキル・原則・AGENTS.md で既に実施している作業では**ない**
```

`skills/worklog-skillify/SKILL.md:21`

```
- 固有パス（プロジェクトローカルスキル / CLAUDE.md 追記）はガード不要でそのまま進む
```

→

```
- 固有パス（プロジェクトローカルスキル / AGENTS.md 追記）はガード不要でそのまま進む
```

`skills/worklog-skillify/SKILL.md:37`（表のセル）

```
| **固有ルールでスキル化不要** | そのプロジェクトの `CLAUDE.md` に追記 |
```

→

```
| **固有ルールでスキル化不要** | そのプロジェクトの `AGENTS.md` に追記（`AGENTS.md` が無いプロジェクトでは `CLAUDE.md` に追記する） |
```

`skills/worklog-skillify/SKILL.md:43`（同一行に 2 箇所）: `CLAUDE.md 追記へ振り分ける場合` → `AGENTS.md 追記へ振り分ける場合`、`配信元の CLAUDE.md は template 経由で配布されるため` → `配信元の AGENTS.md は template 経由で配布されるため`。

`skills/worklog-skillify/references/skill-authoring-techniques.md:32`

```
4. 完成したスキルを規定の配置先（プラグイン配信 / プロジェクトローカル / CLAUDE.md 追記）へ確定
```

→

```
4. 完成したスキルを規定の配置先（プラグイン配信 / プロジェクトローカル / AGENTS.md 追記）へ確定
```

`skills/worklog-skillify/SKILL.md:19` の判定マーカー `` `.claude-plugin/plugin.json` `` は**変更しない**（実在パスの参照であり中立化の対象外）。

- [ ] **Step 5: ローカルスキル配置先 3 箇所をツール中立化する**

`skills/worklog-extract/SKILL.md:31`

```
5. **既存スキル重複排除**: superpowers ＋ ai-driven-dev-principles ＋ プロジェクトローカル（`.claude/skills/`）の description と突合し、既存済みは除外（あいまい層）
```

→

```
5. **既存スキル重複排除**: superpowers ＋ ai-driven-dev-principles ＋ プロジェクトローカル（利用ツールのスキル配置先。Claude Code は `.claude/skills/`、Codex は `.agents/skills/` など）の description と突合し、既存済みは除外（あいまい層）
```

`skills/worklog-skillify/SKILL.md:25`

```
1. この場のプロジェクトローカルスキル（`.claude/skills/`）として作成する
```

→

```
1. この場のプロジェクトローカルスキル（利用ツールのスキル配置先。Claude Code は `.claude/skills/`、Codex は `.agents/skills/` など）として作成する
```

`skills/worklog-skillify/SKILL.md:36`（表のセル）

```
| **プロジェクト固有だが価値あり** | そのプロジェクトのローカルスキル `.claude/skills/<name>/` |
```

→

```
| **プロジェクト固有だが価値あり** | そのプロジェクトのローカルスキル（利用ツールのスキル配置先。Claude Code は `.claude/skills/<name>/`、Codex は `.agents/skills/<name>/` など） |
```

- [ ] **Step 6: 書き換え結果を実測で確認する**

```bash
grep -rn "CLAUDE\.md" skills/ | grep -v "当該調整値の記載が無ければ CLAUDE.md" | grep -v "CLAUDE.md の調整値を読む" | grep -v 'CLAUDE.md` に追記する'
```

期待: 出力が空（Layer 2 を素で指す `CLAUDE.md` が skills 配下に残っていない）。

```bash
grep -o "AGENTS\.md" -r skills/ | wc -l
```

期待: `20`（二段フォールバック 7 箇所のうち Step 3 の 1 箇所だけが `AGENTS.md` を 2 回含むため 8、AGENTS.md 化が 11、うち書き込み先 1 箇所が ADR-0114 により `AGENTS.md` を 2 回含むため +1）。

- [ ] **Step 7: dist を再生成して規約適合を確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "exit=$?"
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
```

期待: 1 回目が `[build-dist] Convention violations: 0` を経て `Done. 20 files written to dist/, 1 to repository root.`、2 回目が `[build-dist] Up to date.`、3 回目が `[sync-template] Up to date.`。いずれも `=0`（変更したのが片側でも両生成器を回す。CONTRIBUTING「執行点」手順 2）。

**コミット前に配布物の差分を目視する**（同手順 4 の 1 巡目。Task 11 Step 7 が独立工程としての 2 巡目を担う）。本コミットは `dist/skills/` の内容を書き換える。

機械で拾えるのは 5 項目のうち 2 つだけである。**配布物側**では、自己参照と、半角括弧つき識別子が除去された後に残る空括弧を探す:

```bash
git diff -- dist/skills | grep -E "^\+" | grep -E "\(\)|（）|本リポジトリ|本 repo"
```

**ソース側**では、半角括弧つきの出所識別子そのものを探す:

```bash
git diff -- skills | grep -E "^\+" | grep -E "\((ADR|Issue)-[0-9]{4}"
```

期待: いずれも出力が空。

**配布物側で `(ADR-NNNN)` を探しても意味がない**——`Test-InsideParen` が `LastIndexOf` をカルチャ依存比較で使うため半角 `(` を全角 `（` と同一視し、`(ADR-0111)` は規約違反にならず「除去対象」と判定される。生成器は識別子だけを外して `()` を残したまま `dist/` へ出荷する（`Convention violations: 0` / `exit=0` のまま通る）。CONTRIBUTING「機械判定が届かない領域」の 2 行目がこの型を明記している。したがって配布物で観測できるのは `()` の残骸であり、識別子そのものはソース側でしか捕まえられない。

`grep` に `-n` を付けないこと（`git diff` を通した後のストリーム内連番が出るだけで、差分行番号でもファイル行番号でもない）。

**残る 3 項目（括弧内に識別子以外の語が同居した行・書式例の実在の固有名・スクリプトの表示メッセージ）は機械では見ていない**。本コミットで追加した二段フォールバック表現と配置先併記の行を実際に読み、全角括弧が閉じていること・識別子を除去しても意味が壊れないことを目で確かめる。

- [ ] **Step 8: コミットする**

```bash
git add skills dist && git commit -m "chore: skills の Layer 2 参照と ローカルスキルパスを 3 ツール中立化"
```

コミットメッセージ本文:

```
Layer 2 を指す参照 18 箇所のうち、プロジェクト側の調整値を読む 7 箇所は
「AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）」の二段フォールバックにする
（ADR-0111）。プラグインの即時反映と template の手動同期で反映時期がずれるため、
当該調整値の記載の有無で探索しないと移行途中のプロジェクトが壊れる。残る 11 箇所は
AGENTS.md へ差し替える。

ローカルスキルの配置先 3 箇所は Claude Code / Codex の併記へ改める。

コード品質レビューを受けて、探索対象を「当該調整値の記載」と明示し、唯一の Layer 2
書き込み点にも同じ二段フォールバックを適用し、ツール配置先の列挙を開いた（ADR-0114）。
未移行プロジェクトで新規 AGENTS.md へ書くと Claude Code がインポート行の無いまま
読まず、規範が無言で不発になる経路を塞ぐ。
```

---

## Task 5: docs/overview の参照を中立化する

**Files:**
- Modify: `docs/overview/issue-management.md`（44 行目）
- Modify: `docs/overview/folder-structure.md`（80 行目）
- Generated: `template/`

- [ ] **Step 1: issue-management.md の調整値参照を二段フォールバックにする**

`docs/overview/issue-management.md:44` の

```
目安値 **10KB**（単位は 1KB = 1000 バイト。プロジェクトの CLAUDE.md に調整値があればそれを優先）を超えていたらフォルダ昇格を提案する
```

を次に置き換える:

```
目安値 **10KB**（単位は 1KB = 1000 バイト。プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先）を超えていたらフォルダ昇格を提案する
```

- [ ] **Step 2: folder-structure.md の参照元名を差し替える**

`docs/overview/folder-structure.md:80` の

```
本節は `CLAUDE.md`（ドキュメント運用）から参照される。
```

を次に置き換える:

```
本節は `AGENTS.md`（ドキュメント運用）から参照される。
```

この箇所は「どのファイルから参照されているか」の宣言であり、調整値の探索ではないため二段フォールバックにしない。

- [ ] **Step 3: template を再生成して確認する**

```bash
pwsh -NoProfile scripts/sync-template.ps1; echo "exit=$?"
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
grep -n "AGENTS" template/docs/overview/issue-management.md template/docs/overview/folder-structure.md
```

期待: 3 つとも `=0`（変更したのが片側でも両生成器を回す。CONTRIBUTING「執行点」手順 2）。grep が `template/docs/overview/issue-management.md:44` と `template/docs/overview/folder-structure.md:80` の 2 行を返す。

- [ ] **Step 4: コミットする**

```bash
git add docs/overview template && git commit -m "chore: docs/overview の Layer 2 参照を AGENTS.md 基準へ更新"
```

---

## Task 6: README を 3 ツール対応に更新する

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 概要と Layer 2 表を 3 ツール化する**

7 行目

```
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（AI駆動開発ガイドライン）と、それを GitHub Copilot CLI / Claude Code で実践するための仕組みを提供する。
```

→

```
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（AI駆動開発ガイドライン）と、それを GitHub Copilot CLI / Claude Code / OpenAI Codex で実践するための仕組みを提供する。
```

18 行目

```
| Layer 2 | [`CLAUDE.md`](CLAUDE.md) | エージェント向け行動指示（GitHub Copilot CLI / Claude Code 共通） |
```

→

```
| Layer 2 | [`AGENTS.md`](AGENTS.md) | エージェント向け行動指示（GitHub Copilot CLI / Claude Code / OpenAI Codex 共通）。[`CLAUDE.md`](CLAUDE.md) は `@AGENTS.md` インポートのポインタ |
```

- [ ] **Step 2: Layer 2 注記ブロック（123 行目）を差し替える**

```
> **Layer 2 について**: GitHub Copilot CLI と Claude Code はいずれもリポジトリルートの `CLAUDE.md` を行動指示として読み込む。本リポジトリの Layer 2 はこの単一ファイルに統一されている（ADR-0023）。
```

→

```
> **Layer 2 について**: Layer 2 の**内容の正本**はリポジトリルートの `AGENTS.md` である（ADR-0111）。Codex と GitHub Copilot CLI は `AGENTS.md` を直接読み、Claude Code は `CLAUDE.md` に置いた `@AGENTS.md` インポート 1 行を経由して同じ内容を読む。内容を持つファイルは 1 つであり、`CLAUDE.md` はツール到達経路にすぎない。
```

- [ ] **Step 3: 「Codex へのインストール」節を「Claude Code へのインストール」節の直後（現 121 行目と 123 行目の間）へ挿入する**

挿入する内容は次の 4 連バッククォートで囲んだ範囲（内側の 3 連バッククォートはそのまま README へ書く）:

````markdown
## Codex へのインストール

OpenAI Codex（Codex CLI / ChatGPT デスクトップアプリ同梱ランタイム）でも同じスキル群をプラグインとして利用できる。本リポジトリには Codex ネイティブのマーケットプレイス定義（`.agents/plugins/marketplace.json`）とプラグインマニフェスト（`dist/.codex-plugin/plugin.json`）が含まれる。いずれも `scripts/build-dist.ps1` の生成物であり、手編集しないこと。

以下は Codex CLI 0.149.0-alpha.4.3（2026-08-25 確認）で動作を確認した手順である。インストールのサブコマンドは公式ドキュメントに記載のある `plugin install` ではなく `plugin add` である（実装がドキュメントに先行している）。

### A. GitHub 経由でインストール

```sh
codex plugin marketplace add taika-izumi/ai-driven-dev-principles
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

### B. ローカルパスからインストール（開発時）

本リポジトリを clone 済みのマシンでは、ローカルパスをマーケットプレイスとして登録できる:

```sh
codex plugin marketplace add <このリポジトリの絶対パス>
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

### 更新

GitHub 経由で登録している場合は、スナップショットを更新してから再インストールする:

```sh
codex plugin marketplace upgrade ai-driven-dev-principles
codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
```

ローカルパス登録の場合は `marketplace upgrade`（Git 登録のスナップショット更新用）の対象外のため、`codex plugin add` の再実行だけで反映される。登録の確認は `codex plugin marketplace list`、インストール済みプラグインの削除は `codex plugin remove ai-driven-dev-principles`。

### superpowers の導入

本ガイドラインのスキルは superpowers のスキル（brainstorming / writing-plans など）へ委譲する。Codex でも次の手順で導入できる（superpowers 6.3.0 で確認）:

```sh
codex plugin marketplace add obra/superpowers-marketplace
codex plugin add superpowers@superpowers-marketplace
```

> **注意**: 本リポジトリは `.claude-plugin/marketplace.json`（Claude Code / Copilot CLI 用）と `.agents/plugins/marketplace.json`（Codex 用）を併置している。Codex は両者が同居する場合ネイティブ側を優先し legacy 側を無視するため、二重登録は起きない（2026-08-25 実測）。
````

- [ ] **Step 4: 「新しいプロジェクトでの使い方」を 3 ツール化し、固有指示の追記先を AGENTS.md にする**

129 行目

```
新規プロジェクトで本ガイドラインを使うには、GitHub Copilot CLI / Claude Code プラグイン `ai-driven-dev-principles` をインストールしておく必要がある（ADR-0016）。スキル群（`start-work`, `decision-log` 等）はプラグイン経由でのみツールに認識されるため、template をコピーしただけでは機能しない。
```

→

```
新規プロジェクトで本ガイドラインを使うには、GitHub Copilot CLI / Claude Code / OpenAI Codex のいずれかにプラグイン `ai-driven-dev-principles` をインストールしておく必要がある（ADR-0016）。スキル群（`start-work`, `decision-log` 等）はプラグイン経由でのみツールに認識されるため、template をコピーしただけでは機能しない。
```

133 行目

```
1. **このリポジトリをプラグインとして 1 度インストール**（上記「Copilot CLI へのインストール」または「Claude Code へのインストール」節を参照）
```

→

```
1. **このリポジトリをプラグインとして 1 度インストール**（上記「Copilot CLI へのインストール」「Claude Code へのインストール」「Codex へのインストール」のうち、利用するツールの節を参照）
```

135 行目

```
3. `CLAUDE.md` にプロジェクト固有の指示を追記する
```

→

```
3. `AGENTS.md` にプロジェクト固有の指示を追記する（`CLAUDE.md` は `@AGENTS.md` の 1 行のままにする）
```

140 行目（「注意」小節の 2 つ目の箇条）

```
- スキルのバージョンアップは `/plugin update` でプラグインを更新すれば全プロジェクトに反映される
```

→

```
- スキルのバージョンアップは、利用ツールのプラグイン更新コマンド（Claude Code は `/plugin marketplace update`、Copilot CLI は `copilot plugin update`、Codex は `codex plugin marketplace upgrade` ＋ `codex plugin add`）を実行すれば全プロジェクトに反映される
```

- [ ] **Step 5: 既存プロジェクトの移行手順を独立節として追加する**

「新しいプロジェクトでの使い方」節の「注意」小節の直後（「成長サイクル」節の直前）へ次を挿入する:

```markdown
## 既存プロジェクトを AGENTS.md 構成へ移行する

以前の template をコピーしたプロジェクトは、Layer 2 の内容を `CLAUDE.md` に持っている。新しい template をそのまま再コピーすると `CLAUDE.md` が `@AGENTS.md` の 1 行で上書きされ、そこへ書き足していたプロジェクト固有の指示が消える。**必ず次の順序で移行すること。**

1. **現 `CLAUDE.md` の内容を `AGENTS.md` へ退避する**: 共通部（ガイドライン本体）は新しい `template/AGENTS.md` で置き換えてよいが、プロジェクト固有の追記は `AGENTS.md` 側へ移し替える
2. **`CLAUDE.md` をポインタ 1 行にする**: 内容を `@AGENTS.md` の 1 行だけにする（`template/CLAUDE.md` をコピーしてもよい）
3. **確認する**: 利用ツールを起動し、Layer 2 の指示が読み込まれていること（Claude Code なら `/context`、Codex なら `codex debug prompt-input`）を確かめる

手順 1 を飛ばして手順 2 から始めると固有指示が失われる。復旧は git 履歴からになる。
```

- [ ] **Step 6: 変更を確認する**

```bash
grep -n "Codex" README.md | head -20
grep -n "CLAUDE\.md" README.md
```

期待: 前者に「Codex へのインストール」節が現れる。後者に残るのは、ポインタである旨・移行手順・既存 2 ツール節の説明といった**意図的な言及のみ**（Layer 2 の内容正本として `CLAUDE.md` を指す記述が無いこと）。

- [ ] **Step 7: コミットする**

```bash
git add README.md && git commit -m "docs: README に Codex インストール節と既存プロジェクト移行手順を追加"
```

コミットメッセージ本文:

```
Codex の手順は codex-cli 0.149.0-alpha.4.3 で実測したコマンド（plugin add /
marketplace upgrade）を確認日つきで記載する。公式ドキュメントの plugin install は
実装に存在しない。

移行手順を独立節にしたのは、template 再コピーで CLAUDE.md が @AGENTS.md の 1 行に
上書きされ、そこへ書き足していた固有指示が消える経路があるため（ADR-0111）。
```

---

## Task 7: CONTRIBUTING を追随させる

**Files:**
- Modify: `CONTRIBUTING.md`

CONTRIBUTING.md 中の `CLAUDE.md` は 21 箇所ある。うち **3 箇所（sync-template 実行条件の列挙）は `AGENTS.md` を追加**し、**残り 18 箇所は `AGENTS.md` へ差し替える**。スクリプト名 `check-claude-md-size.ps1` は小文字ハイフン表記のため、`CLAUDE.md` の置換対象にならない（4 箇所すべて変更しない）。

- [ ] **Step 1: 現状の件数を実測しておく**

```bash
grep -o "CLAUDE\.md" CONTRIBUTING.md | wc -l
grep -c "check-claude-md-size" CONTRIBUTING.md
```

期待: `21` と `4`。

- [ ] **Step 2: sync-template 実行条件の列挙 3 箇所へ AGENTS.md を追加する**

402 行目・435 行目・473 行目はいずれも次の同一文を含む:

```
同一サイクルで `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` のいずれか、または空インデックス生成対象
```

3 箇所とも次に置き換える:

```
同一サイクルで `AGENTS.md` / `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` のいずれか、または空インデックス生成対象
```

- [ ] **Step 3: 残る 18 箇所の `CLAUDE.md` を `AGENTS.md` へ差し替える**

対象は次のとおり（Step 2 で処理した 3 箇所と、`check-claude-md-size.ps1` の 4 箇所は含まない）:

- 15 行目（設計思想の Layer 2 行。下記 Step 4 でさらに追記する）
- 36 行目（過剰適合の点検の適用対象定義。同一行に 2 箇所）
- 54 行目（是正パターンのゲート規範。同一行に 3 箇所）
- 231 行目（シナリオ見出し「シナリオ: CLAUDE.md を更新するとき」→「シナリオ: AGENTS.md を更新するとき」）
- 236・241・249・253・254・256 行目（同シナリオ本文。256 行目は参照先の見出し名も「AGENTS.md を棚卸しするとき」になる）
- 265 行目（シナリオ見出し「シナリオ: CLAUDE.md を棚卸しするとき」→「シナリオ: AGENTS.md を棚卸しするとき」）
- 269・279 行目（同シナリオ本文）
- 304 行目（Skill 化の判定表のヘッダセル `| 観点 | CLAUDE.md に書く | Skill にする |` → `| 観点 | AGENTS.md に書く | Skill にする |`）
- 322 行目（Skill シナリオのチェックリスト `` - `CLAUDE.md` の記述で十分ではないか（YAGNI確認） `` → `` - `AGENTS.md` の記述で十分ではないか（YAGNI確認） ``）

- [ ] **Step 4: 設計思想の Layer 2 行にポインタの説明を足す**

15 行目（Step 3 の差し替え後）

```
| Layer 2 | `AGENTS.md` | エージェント向け行動指示（GitHub Copilot CLI / Claude Code 共通） |
```

を次に置き換える:

```
| Layer 2 | `AGENTS.md` | エージェント向け行動指示（GitHub Copilot CLI / Claude Code / OpenAI Codex 共通）。`CLAUDE.md` は `@AGENTS.md` インポートのポインタ 1 行 |
```

- [ ] **Step 5: 執行点の 3 手順を新しい出力先・入力元へ追随させる**

194 行目

```
1. **変更した側の生成器を実行する**: `skills/` を変更したなら `scripts/build-dist.ps1`、`template.manifest` 記載ファイル・空インデックス生成対象を変更したなら `scripts/sync-template.ps1`（両方を変更したなら両方）。規約違反があれば非ゼロ終了する
```

→

```
1. **変更した側の生成器を実行する**: `skills/` または `.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json` を変更したなら `scripts/build-dist.ps1`、`template.manifest` 記載ファイル・空インデックス生成対象を変更したなら `scripts/sync-template.ps1`（両方を変更したなら両方）。規約違反、または 2 つの `.claude-plugin/` ファイル間の version 不一致があれば非ゼロ終了する
```

195 行目

```
2. **両者を `-Check` で実行する**: それぞれ自分の出力先しか見ない（`build-dist.ps1` は `dist/`、`sync-template.ps1` は `template/`）。取りこぼさないよう変更範囲によらず両方を回す
```

→

```
2. **両者を `-Check` で実行する**: それぞれ自分の出力先しか見ない（`build-dist.ps1` は `dist/` とルートの `.agents/plugins/marketplace.json`、`sync-template.ps1` は `template/`）。取りこぼさないよう変更範囲によらず両方を回す
```

196 行目

```
3. **生成された `dist/` と `template/` を同じコミットに含める**: どちらも git 管理下にあり、ソースだけコミットすると次の `-Check` が落ちる状態を作り込む
```

→

```
3. **生成された `dist/`・`template/`・`.agents/plugins/marketplace.json` を同じコミットに含める**: いずれも git 管理下にあり、ソースだけコミットすると次の `-Check` が落ちる状態を作り込む
```

- [ ] **Step 6: 書き換え結果を実測で確認する**

```bash
grep -o "CLAUDE\.md" CONTRIBUTING.md | wc -l
grep -n "CLAUDE\.md" CONTRIBUTING.md
grep -c "check-claude-md-size" CONTRIBUTING.md
grep -n "^## シナリオ: AGENTS.md" CONTRIBUTING.md
```

期待: 1 つ目が `4`（sync-template 実行条件 3 箇所＋Layer 2 行のポインタ説明 1 箇所）、2 つ目がその 4 行のみ、3 つ目が `4`（不変）、4 つ目が「更新するとき」「棚卸しするとき」の 2 見出し。

- [ ] **Step 7: コミットする**

```bash
git add CONTRIBUTING.md && git commit -m "docs: CONTRIBUTING を AGENTS.md 正本と新しい生成物構成へ追随"
```

---

## Task 8: プラグイン正本の version を 0.1.12 へ上げ description を更新する

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Generated: `dist/`（`.agents/plugins/marketplace.json` は version キーを持たないため本タスクでは 1 バイトも変わらない。`git add .agents` は no-op になるが、取りこぼし防止のため add 対象には残す）

本サイクルは dist の内容を改定するため、ADR-0090 の bump 必須条件に該当する。

- [ ] **Step 1: 正本 2 ファイルを更新する**

`.claude-plugin/plugin.json`

```json
  "description": "AI駆動開発ガイドラインを実装するスキル群（start-work, decision-log, session-handoff, feature-block-design, retrospective ほか）。導入先プロジェクトの CLAUDE.md と組み合わせて使用する。",
  "version": "0.1.11",
```

→

```json
  "description": "AI駆動開発ガイドラインを実装するスキル群（start-work, decision-log, session-handoff, feature-block-design, retrospective ほか）。導入先プロジェクトの AGENTS.md と組み合わせて使用する。",
  "version": "0.1.12",
```

`.claude-plugin/marketplace.json` の `plugins[0].version` を `"0.1.11"` から `"0.1.12"` へ変更する。

- [ ] **Step 2: 片側だけ上げた状態が検出されることを確認する（Task 1 の検査の実地確認）**

`.claude-plugin/marketplace.json` の version だけを一時的に `"0.1.11"` へ戻してから:

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "exit=$?"
```

期待: `  ! version mismatch: .claude-plugin/marketplace.json plugins[0] (ai-driven-dev-principles) = 0.1.11, .claude-plugin/plugin.json = 0.1.12` と `exit=1`。

確認できたら `"0.1.12"` へ戻す。

- [ ] **Step 3: 生成物へ波及させる**

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "exit=$?"
grep -n "version" dist/.claude-plugin/plugin.json dist/.codex-plugin/plugin.json
grep -n "AGENTS" dist/.codex-plugin/plugin.json
```

期待: 生成が `exit=0`。両 plugin.json の version が `0.1.12`。`dist/.codex-plugin/plugin.json` の description に `AGENTS.md` が現れる。

```bash
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
```

期待: `[build-dist] Up to date.` と `[sync-template] Up to date.`、両方とも `=0`（変更したのが片側でも両生成器を回す。CONTRIBUTING「執行点」手順 2）。

**コミット前に配布物の差分を目視する**（同手順 4 の 1 巡目）。本コミットは `dist/` の 2 つの plugin.json の description と version を書き換える:

```bash
git diff -- dist/.claude-plugin dist/.codex-plugin
```

期待: 差分が `version` と `description` の 2 種類のみで、description の文面が `AGENTS.md` を含み、出所識別子・自己参照・絶対パスを含まないこと。

- [ ] **Step 4: コミットする**

```bash
git add .claude-plugin dist .agents && git commit -m "chore: プラグイン version を 0.1.12 へ上げ description を AGENTS.md 基準へ更新"
```

コミットメッセージ本文:

```
本サイクルは dist の内容を改定するため bump 必須条件に該当する（ADR-0090）。
description の「導入先プロジェクトの CLAUDE.md と組み合わせて使用する」は
Layer 2 の内容正本が AGENTS.md へ移ったことに合わせて改める（ADR-0111）。
```

---

## Task 9: 仕様スナップショットを同期する

**Files:**
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/00-overview.md`
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/01-provenance-notation-convention.md`
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/02-distribution-generator.md`
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/03-template-sync-integration.md`
- Modify: `docs/current/specs/2026-08-07-distributed-artifact-generation/04-plugin-distribution-layout.md`
- Modify: `docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md`
- Modify: `docs/current/specs/2026-08-13-handoff-bloat-control/02-volume-norms.md`
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md`
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md`
- Modify: `docs/current/specs/2026-08-25-codex-support-design.md`（本サイクルの設計 spec 自身）

仕様書は「今どうなっているか」のスナップショットとして**書き換えで**更新する（差分ファイルを作らない）。同期対象の判定基準は「本サイクルの変更が直接無効化する記述であること」に統一する。

- [ ] **Step 1: 02 の「対象ファイル」「責務」を更新する**

10 行目の責務

```
配布対象ソースを走査し、記法規約（ブロック 01）への適合を判定する。適合していれば出所識別子を除去した配布物を生成し、違反していれば違反箇所と違反した規約 ID を出力して非ゼロ終了する。生成物がソースから再生成した結果と一致するかも判定する。
```

→

```
配布対象ソースを走査し、記法規約（ブロック 01）への適合を判定する。適合していれば出所識別子を除去した配布物を生成し、違反していれば違反箇所と違反した規約 ID を出力して非ゼロ終了する。生成物がソースから再生成した結果と一致するかも判定する。あわせてプラグイン定義の正本 2 ファイル（`.claude-plugin/plugin.json` / `.claude-plugin/marketplace.json`）の version 一致を検査し、Codex 向けマニフェスト 2 生成物を正本から導出する。
```

- [ ] **Step 2: 02 の「インターフェース」へ version 一致検査とルート生成物の扱いを追記する**

まずモード表（20-21 行目）を新しい終了条件・出力先へ合わせる。

```
| 既定（引数なし） | 規約を判定し、適合していれば `dist/` を再生成する | 0 = 生成成功 / 1 = 規約違反（`dist/` は変更しない） |
| `-Check` | 規約を判定し、ソースから再生成した内容と既存 `dist/` を比較する。書き込みはしない | 0 = 一致 / 1 = 規約違反または不一致 |
```

→

```
| 既定（引数なし） | version 一致と規約を判定し、適合していれば `dist/` とルート生成物を再生成する | 0 = 生成成功 / 1 = version 不一致・規約違反・正本 JSON の不正（生成物は変更しない） |
| `-Check` | version 一致と規約を判定し、ソースから再生成した内容と既存の生成物を比較する。書き込みはしない | 0 = 一致 / 1 = version 不一致・規約違反・正本 JSON の不正・生成物との不一致 |
```

続いて 23 行目の `-Check` の一致判定の導入文と 4 条件の直後（29 行目の空行の位置）へ次を追加する:

```markdown
上記 4 条件は `dist/` に対する判定である。**ルート直下の生成物（`.agents/plugins/marketplace.json`）は既知パスのホワイトリストに対するファイル単位の判定**とし、条件 1（内容一致）・条件 3（BOM の不在）・条件 4（残存識別子）のみを適用する。**条件 2（余分なファイルの不在）はルート側に適用しない**——リポジトリルートを出力先ルートとして走査すると生成物以外の全ファイルが陳腐化と判定され、wipe に含めれば不可逆な削除事故になるため。

また通常実行・`-Check` の**両モードの冒頭（規約判定より前）**で、`.claude-plugin/plugin.json` の `version` と `.claude-plugin/marketplace.json` の `plugins[].version`（全件）の一致を検査し、不一致なら非ゼロ終了する。version は 2 ファイルに二重保持されており、`-Check` 側でも走らせないと CONTRIBUTING「執行点」手順 2 のゲートにならない。

Codex 向けマーケットプレイスの生成は `plugins[].source` が**文字列パスであること**を前提とする。オブジェクト形式（`{"source":"github", …}`）は未対応であり、暗黙の文字列変換で壊れた `path` を持つ構文的に妥当な JSON が出力され `-Check` も自己一致で通ってしまうため、生成時に型を判定して非ゼロ終了する。`plugins` が 0 件のとき、`plugins[].name` が空のときも同様に停止する。
```

- [ ] **Step 3: 02 の「標準出力」の例を実際の出力へ合わせる**

51-57 行目の出力例（50・58 行目はコードフェンス）

```
[build-dist] Scanning 18 source files...
[build-dist] Convention violations: 0
  ✓ skills/start-work/SKILL.md (21 identifiers removed)
  ✓ skills/session-handoff/SKILL.md (17 identifiers removed)
  ...
[build-dist] Generating dist/ ...
[build-dist] Done. 19 files written to dist/.
```

を次に置き換える:

```
[build-dist] Scanning 18 source files...
[build-dist] Convention violations: 0
  ✓ skills/start-work/SKILL.md (21 identifiers removed)
  ✓ skills/session-handoff/SKILL.md (17 identifiers removed)
  ...
[build-dist] Generating dist/ and root artifacts ...
[build-dist] Done. 20 files written to dist/, 1 to repository root.
```

60 行目の

```
`✓` 行（ファイル別の除去数）は生成内容の組み立て時に出力するため、`Generating` 行より前に並び、書き込みを行わない `-Check` でも表示される。`Done.` の件数は `plugin.json` を含む書き出しファイルの総数である。
```

を次に置き換える:

```
`✓` 行（ファイル別の除去数）は生成内容の組み立て時に出力するため、`Generating` 行より前に並び、書き込みを行わない `-Check` でも表示される。`Done.` の件数は 2 系統に分けて出す。`dist/` 側は `.claude-plugin/plugin.json` と `.codex-plugin/plugin.json` を含む書き出しファイルの総数、ルート側はホワイトリストの生成物件数である。
```

さらに規約違反時の出力例（65-70 行目。62 行目は導入文、64・71 行目はコードフェンス）の末尾行

```
[build-dist] Aborted. dist/ was not modified.
```

を、Task 2 Step 4 で変更した実際の文言に合わせる:

```
[build-dist] Aborted. Generated artifacts were not modified.
```

- [ ] **Step 4: 02 の「走査対象の決定」の実数を更新する**

77-80 行目

```
配布対象ソースは計 26 ファイルで、走査は生成器ごとに分担する。

- `scripts/build-dist.ps1`（本ブロック）: `skills/` 配下の全ファイル（18）
- `scripts/sync-template.ps1`（ブロック 03）: `template.manifest` に記載されたファイル（5）と空インデックス生成対象 3 ファイル（判定は空インデックス化後の内容）
```

を次に置き換える:

```
配布対象ソースは計 27 ファイルで、走査は生成器ごとに分担する。

- `scripts/build-dist.ps1`（本ブロック）: `skills/` 配下の全ファイル（18）
- `scripts/sync-template.ps1`（ブロック 03）: `template.manifest` に記載されたファイル（6）と空インデックス生成対象 3 ファイル（判定は空インデックス化後の内容）

このほか `build-dist.ps1` は `.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` を読むが、これらは走査対象ではなく**生成の入力（正本）**である。
```

- [ ] **Step 5: 02 の「`dist/` の構成と書き出し」を新しい生成物構成へ更新する**

「### 5. `dist/` の構成と書き出し」の見出しを「### 5. 生成物の構成と書き出し」に改め、132-137 行目の表と後続の段落

```
| 出力 | 生成元 |
|---|---|
| `dist/skills/**` | `skills/**` を変換したもの |
| `dist/.claude-plugin/plugin.json` | リポジトリ直下の `.claude-plugin/plugin.json` を LF へ正規化して複写する |

`plugin.json` を生成器の責務に含めないと、2 回目の実行でプラグイン定義が失われ、`/plugin marketplace update` 時に全スキルが消える。
```

を次に置き換える:

```
| 出力 | 生成元 |
|---|---|
| `dist/skills/**` | `skills/**` を変換したもの |
| `dist/.claude-plugin/plugin.json` | リポジトリ直下の `.claude-plugin/plugin.json` を LF へ正規化して複写する |
| `dist/.codex-plugin/plugin.json` | 同 `plugin.json` から `name` / `version` / `description` / `author` を複写し、`skills` は `./skills/` 固定、`interface` は `displayName` と `category` の 2 キーのみを生成器内の固定マッピングで付与する |
| `.agents/plugins/marketplace.json`（リポジトリルート） | `.claude-plugin/marketplace.json` から `name` と `plugins[].name` を複写し、`source` を `{"source":"local","path":"<正本の source>"}` へ変換、`interface.displayName` / `policy.installation` / `policy.authentication` / `category` を生成器内の固定マッピングで付与する |

`plugin.json` を生成器の責務に含めないと、2 回目の実行でプラグイン定義が失われ、`/plugin marketplace update` 時に全スキルが消える。

`dist/` は生成のたびに完全削除して作り直すが、**ルート直下の生成物は wipe の対象にしない**（ホワイトリストのパスをファイル単位で上書きする）。リポジトリルートの削除は不可逆事故になるため。

Codex 向けマニフェストの `interface` は資産参照キー（`composerIcon` / `logo` / `screenshots` など）を生成しない。`dist/` に実体が無く、必須である根拠も無いため最小構成とする。

JSON は `ConvertTo-Json` ではなくテンプレート組み立てで出力する（整形規則と非 ASCII のエスケープが PowerShell のバージョンで変わり、`-Check` が環境依存で落ちるのを避けるため）。
```

- [ ] **Step 6: 02 の「自己検査」にルート生成物の扱いを追記する**

「### 6. 自己検査」の末尾へ次の段落を追加する:

```markdown
**ディレクトリ走査を伴う自己検査は `dist/` に限定する。** ルート直下の生成物に対しては、書き込み前に生成内容（メモリ上の文字列）へ `Get-ProvenanceLeak` を掛けるファイル単位の検査を行う。ルートを再帰走査すると配布物ではないリポジトリ内の全ファイルが検査対象になってしまうため。
```

- [ ] **Step 7: 03 の「対象ファイル」と同期対象数を更新する**

6 行目

```
- `template.manifest` — 変更しない（同期対象の定義は現状のまま）
```

→

```
- `template.manifest` — `AGENTS.md` を同期対象に追加した（Layer 2 の内容正本が `AGENTS.md` へ移り、`CLAUDE.md` は `@AGENTS.md` インポートのポインタ 1 行になったため。ADR-0111）
```

29 行目

```
| 1 | `template.manifest` を読み、コメント行・空行を除いてファイル一覧を得る（現在 5 ファイル: `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/overview/issue-management.md` / `docs/inbox/README.md`） |
```

→

```
| 1 | `template.manifest` を読み、コメント行・空行を除いてファイル一覧を得る（現在 6 ファイル: `AGENTS.md` / `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/overview/issue-management.md` / `docs/inbox/README.md`） |
```

31 行目の `全 8 ファイル分の内容` を `全 9 ファイル分の内容` へ。

35 行目

```
| 7 | `scripts/check-claude-md-size.ps1` を呼び、CLAUDE.md の規模を計測する（警告のみ。同期はブロックしない） |
```

→

```
| 7 | `scripts/check-claude-md-size.ps1` を呼び、AGENTS.md の規模を計測する（警告のみ。同期はブロックしない） |
```

- [ ] **Step 8: 03 の「影響を受けるファイル」表と制約を更新する**

73 行目

```
| `CLAUDE.md` / `docs/overview/principles.md` / `docs/inbox/README.md` | 0 | （対象外） | 0 |
```

→

```
| `AGENTS.md` / `CLAUDE.md` / `docs/overview/principles.md` / `docs/inbox/README.md` | 0 | （対象外） | 0 |
```

93 行目

```
- `check-claude-md-size.ps1` の呼び出しは末尾のまま維持する（警告のみで同期をブロックしない性質も変えない）
```

→

```
- `check-claude-md-size.ps1` の呼び出しは末尾のまま維持する（警告のみで同期をブロックしない性質も変えない）。計測対象は `AGENTS.md` である（`CLAUDE.md` はポインタ 1 行であり、測り続けると規範肥大監視が無音化する）
```

- [ ] **Step 9: 01 の配布対象ソース件数とシナリオ配線表を同期する**

`01-provenance-notation-convention.md` の 46 行目

```
1. `template.manifest` に記載されているファイル（現在 5 ファイル）
```

を次に置き換える（Task 3 Step 5 が manifest へ `AGENTS.md` を追加して 6 ファイルになる。同じ数値を 02 は Step 4 で、03 は Step 7 で更新しており、01 だけが取り残される）:

```
1. `template.manifest` に記載されているファイル（現在 6 ファイル）
```

続いて 161 行目（配線表のデータ行）

```
  | CLAUDE.md を棚卸しするとき | `CLAUDE.md`（manifest 記載）と、規範の退避先 `skills/` |
```

を次に置き換える（Task 7 Step 3 で CONTRIBUTING の見出しが改名され、Task 3 Step 5 で manifest の内容正本が AGENTS.md へ移るため、見出し名とファイル名の両方が追随する）:

```
  | AGENTS.md を棚卸しするとき | `AGENTS.md`（manifest 記載）と、規範の退避先 `skills/` |
```

169 行目

```
  「CLAUDE.md を更新するとき」はチェックリスト節を持たず、手順に `sync-template.ps1` の実行が既にあるため配線済みとみなす。
```

を次に置き換える:

```
  「AGENTS.md を更新するとき」はチェックリスト節を持たず、手順に `sync-template.ps1` の実行が既にあるため配線済みとみなす。
```

- [ ] **Step 10: 04 の配布構造図とプラグイン宣言元の記述を同期する**

`04-plugin-distribution-layout.md` の配布構造の図（33-39 行目）

```
skills/                           開発用ソース（人が編集する。識別子あり）
dist/
  .claude-plugin/plugin.json      生成物（リポジトリ直下から複写）
  skills/                         生成物（識別子なし）
.claude-plugin/marketplace.json   本番エントリの source を "./dist" にする
```

を次に置き換える:

```
skills/                             開発用ソース（人が編集する。識別子あり）
dist/
  .claude-plugin/plugin.json        生成物（リポジトリ直下から複写）
  .codex-plugin/plugin.json         生成物（同 plugin.json から導出）
  skills/                           生成物（識別子なし）
.claude-plugin/marketplace.json     正本。本番エントリの source を "./dist" にする
.agents/plugins/marketplace.json    生成物（上記 marketplace.json から導出。Codex 用）
```

41 行目

```
配布物が `dist/` に限られ、`docs/` や `CONTRIBUTING.md` は配布先へ複製されない。
```

を次に置き換える（生成物はルートにも 1 件あるが、**配布先へ複製される**のは従来どおり `dist/` に限られる。ルートの marketplace 定義はマーケットプレイスの登録側が読むものであって配布物ではない）:

```
配布先へ複製されるのは `dist/` に限られ、`docs/` や `CONTRIBUTING.md` は配布先へ複製されない。ルートの `.agents/plugins/marketplace.json` はマーケットプレイス登録側が読む定義であり、配布物には含まれない。
```

88 行目を次のとおり 2 箇所直す。Layer 2 がプラグインのスキル群を前提条件として宣言している主体が AGENTS.md へ移ること、およびスキル本数が実測 13 本（`ls -d skills/*/ | wc -l` = 13。spec 検証 2 も 13 スキルを前提にしている）であることに合わせる。本数は本サイクル以前からの古い値だが、**同一行を編集するついでに直す**（編集中の行に既知の誤りを残さない）。

```
**本番エントリを最小構成で上書きしてはならない理由**: `CLAUDE.md` は当該プラグインのスキル群を作業の前提条件として宣言している。本番エントリを最小構成に差し替えると、`start-work` / `decision-log` / `session-handoff` を含む 17 本が当セッションから失われる。
```

→

```
**本番エントリを最小構成で上書きしてはならない理由**: `AGENTS.md` は当該プラグインのスキル群を作業の前提条件として宣言している。本番エントリを最小構成に差し替えると、`start-work` / `decision-log` / `session-handoff` を含む 13 本が当セッションから失われる。
```

- [ ] **Step 11: 00 のスコープ外リストの参照先を同期する**

`00-overview.md` の 128 行目

```
- **`template/CLAUDE.md` のプラグイン名 `ai-driven-dev-principles` とインストール元リポジトリ `taika-izumi/ai-driven-dev-principles`** — 配布先が環境を準備するために必要な情報であり、本リポジトリ固有であること自体が正しい（ADR-0081）
```

を次に置き換える（Task 3 適用後の `template/CLAUDE.md` は `@AGENTS.md` の 1 行のみになり、当該情報は `template/AGENTS.md` へ移るため）:

```
- **`template/AGENTS.md` のプラグイン名 `ai-driven-dev-principles` とインストール元リポジトリ `taika-izumi/ai-driven-dev-principles`** — 配布先が環境を準備するために必要な情報であり、本リポジトリ固有であること自体が正しい（ADR-0081）
```

なお `docs/current/specs/2026-08-07-overfitting-check-for-extensions-design.md:53` にも CONTRIBUTING 54 行目と逐語同一の文（`CLAUDE.md` を 3 回含む）が残っているが、**本サイクルの同期対象に含めない**。これは別サブプロジェクトの設計 spec であり、本サイクルの変更が直接無効化する記述ではない（過剰適合の是正パターンの説明として自己完結している）。同型のもの——本サイクルが直接触らない `CLAUDE.md` 参照を持つ spec——は `docs/current/specs/` 配下に計 15 ファイルある（実測: `grep -rl "CLAUDE\.md" docs/current/specs | wc -l` が 24、うち Task 9 の同期対象が 9 ファイル。**実施時に数え直すこと**——同期対象を増減させれば母数も動く）。判断の記録として Task 12 の handoff 更新で母数つきの 1 行を残す。

- [ ] **Step 12: 本サイクルが正本を書き換える他 spec 4 ファイルを同期する**

Task 4 が `skills/` の正本テキストを書き換えるため、それを逐語ないし準逐語で写している次の spec も現状と食い違う。Step 9〜11 と同じ基準（本サイクルの変更が直接無効化する記述）に該当するため同期する。

`docs/current/specs/2026-08-13-handoff-bloat-control/01-relocation-standard.md:29` の `プロジェクトの CLAUDE.md に調整値があればそれを優先` を、Task 4 Step 2 と同じ `プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先` へ。

`docs/current/specs/2026-08-13-handoff-bloat-control/02-volume-norms.md:3`

```
数値はすべて**デフォルト値**である。プロジェクトが調整する場合は自プロジェクトの CLAUDE.md に調整値を明記し、スキルはそれを優先する。字数は全角換算の文字数。
```

→（Task 4 Step 3 の書き込み側の表現に合わせる）

```
数値はすべて**デフォルト値**である。プロジェクトが調整する場合は自プロジェクトの AGENTS.md に調整値を明記し、スキルはそれを優先する（AGENTS.md に調整値の記載が無い場合は CLAUDE.md の調整値を読む）。字数は全角換算の文字数。
```

`docs/current/specs/2026-07-17-worklog-skill-pipeline/04-skill3-skillify.md` の 4 箇所を、Task 4 Step 4・Step 5 と同じ扱いにする。

- 17 行目: `プロジェクトローカルスキル `.claude/skills/`／CLAUDE.md 追記` → `プロジェクトローカルスキル（利用ツールのスキル配置先。Claude Code は `.claude/skills/`、Codex は `.agents/skills/` など）／AGENTS.md 追記`
- 27 行目: `そのプロジェクトのローカルスキル（`.claude/skills/`）` → `そのプロジェクトのローカルスキル（利用ツールのスキル配置先。Claude Code は `.claude/skills/`、Codex は `.agents/skills/` など）`
- 28 行目: `そのプロジェクトの CLAUDE.md` → `そのプロジェクトの AGENTS.md`
- 30 行目: `本 repo で実行し CLAUDE.md 追記へ振り分ける場合` → `本 repo で実行し AGENTS.md 追記へ振り分ける場合`

`docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md:80`（同ディレクトリの概要側にも 3 分岐が写されている）

```
2. スコープ3分岐で振り分け先を決定（汎用→プラグイン配信スキル／固有→プロジェクトローカル／固有ルール→CLAUDE.md）
```

→

```
2. スコープ3分岐で振り分け先を決定（汎用→プラグイン配信スキル／固有→プロジェクトローカル／固有ルール→AGENTS.md）
```

- [ ] **Step 13: 上流の設計 spec を実装内容へ同期する**

`docs/current/specs/2026-08-25-codex-support-design.md` は本サイクルの設計スナップショットである。実装で確定した次の 3 点が現状の記述に無いため追記する（仕様書は「今どうなっているか」を書くスナップショット運用であり、確定済みでも実装後の実体に合わせる）。**ADR-0112 の改訂は不要**（Decision の置き換えではなく実装の頑健化であり、Consequences が述べる責務拡大の枠内）。

1. スコープ §2（生成器の中断条件）: version 一致検査を述べた箇条の直後へ次を足す

```
- あわせて正本 `.claude-plugin/marketplace.json` の `plugins[].source` が文字列であること・`plugins` が 1 件以上あること・`plugins[].name` が空でないことを生成時に検査し、いずれも満たさなければ非ゼロ終了する（オブジェクト形式の `source` は暗黙の文字列変換で壊れた `path` を持つ構文的に妥当な JSON を生み、`-Check` も自己一致で通ってしまうため）
```

2. 「影響を受けるファイル一覧」の生成器 spec の行（85 行目）**と、スコープ §2 の「生成器の正本仕様のスナップショット同期」の箇条（56 行目）の両方**: 対象を `02` / `03` の 2 ファイルから、本サイクルで同期する全ファイルへ広げる（`00-overview.md` / `01-provenance-notation-convention.md` / `04-plugin-distribution-layout.md`、および `2026-08-13-handoff-bloat-control/01・02` と `2026-07-17-worklog-skill-pipeline/00・04`）。片方だけ広げると同一 spec 内でスコープと影響一覧が食い違う。**「完了条件」の「生成器 spec（02/03）のスナップショットが実装後の挙動と一致している」は変更しない**（下限として読めば充足されるため。この非対称は意図的で、完了条件は満たすべき最低ラインを述べ、スコープと影響一覧は実際に触る範囲を述べる）

3. 「影響を受けるファイル一覧」の `AGENTS.md` の行: 変更内容を「旧 CLAUDE.md 内容＋前提条件節の 3 ツール化」から「旧 CLAUDE.md 内容＋前提条件節の 3 ツール化＋構造化質問ツール例示の中立化」へ広げる（Task 3 Step 3 の編集が現状の記述の範囲外にあるため）

- [ ] **Step 14: spec の記述が実装と一致することを確認する**

```bash
pwsh -NoProfile scripts/build-dist.ps1 2>&1 | tail -2
pwsh -NoProfile scripts/sync-template.ps1 2>&1 | tail -3
find skills -type f | wc -l
find dist -type f | wc -l
find template -type f | wc -l
grep -c "^[^#]" template.manifest
```

期待: build-dist の末尾が `[build-dist] Done. 20 files written to dist/, 1 to repository root.`、sync-template に `Done. 9 files synced to template/` と `[check-claude-md-size] AGENTS.md: ...`、skills が `18`、dist が `20`、template が `9`、manifest のエントリ行が `6`（変更前は `5`。`grep -c "^[^#]"` は空行を数えない）。

あわせて、spec ディレクトリ内に旧文言が残っていないことを確認する:

```bash
D=docs/current/specs/2026-08-07-distributed-artifact-generation
grep -rn "dist/ was not modified" $D
grep -rn "現在 5 ファイル\|（5）\|計 26 ファイル\|17 本" $D
grep -rn "CLAUDE\.md" $D
grep -rn "CLAUDE\.md\|\.claude/skills" docs/current/specs/2026-08-13-handoff-bloat-control docs/current/specs/2026-07-17-worklog-skill-pipeline
```

期待:

1. 1 つ目は空（Step 3 で更新済み）
2. 2 つ目も空（Step 4・9・10 で更新した数値。同種の数値取り残しを機械検出する）
3. 3 つ目に残ってよいのは `03-template-sync-integration.md` の **4 行**だけ——6 行目（Step 7 が書いた対象ファイル注記の「`CLAUDE.md` は `@AGENTS.md` インポートのポインタ 1 行になったため」）、29 行目と 73 行目の manifest 一覧（ポインタも同期対象なので列挙に残す）、93 行目のポインタ注記。00・01・02・04 の行が出たら Step 1〜11 のいずれかが漏れている
4. 4 つ目に残ってよいのは **4 行**——`handoff-bloat-control/01:29` の二段フォールバック表現に含まれる `CLAUDE.md`、`02:3` の但し書きに含まれる `CLAUDE.md`、そして `worklog-skill-pipeline/04` の 17・27 行目に残る `.claude/skills` の配置先併記。`worklog-skill-pipeline` から `CLAUDE.md` の行が出た場合は `00-overview.md:80` か `04` の 28・30 行目が未適用である

- [ ] **Step 15: コミットする**

```bash
git add docs/current/specs && git commit -m "spec: 仕様スナップショットを Codex 対応後の実装へ同期"
```

コミットメッセージ本文:

```
配布物生成 spec は 02（生成器）と 03（template 同期）に加え、01 の件数と
シナリオ配線表・04 の配布構造図とプラグイン宣言元・00 のスコープ外リストの
参照先も同期する。skills の正本テキストを写している handoff-bloat-control 01/02 と
worklog-skill-pipeline 00/04 も同じ基準（本サイクルの変更が直接無効化する記述）で同期する。

本サイクルの設計 spec 自身も、実装で確定した生成器の中断条件・同期対象の広がり・
AGENTS.md の変更範囲を反映する。仕様書はスナップショット運用のため書き換えで更新する。
```

---

## Task 10: ADR-0023 へ部分修正注記を追記する

**Files:**
- Modify: `docs/records/decisions/0023-unify-layer2-into-claude-md.md`

ADR-0023 のステータスは Accepted のまま維持する。書式は decision-log「ステータス変更」の部分修正の型（`- **部分修正（ADR-XXXX）**:`）に従う。

- [ ] **Step 1: Consequences 節の冒頭へ注記を追加する**

`## Consequences` 見出しの直後（`### 良い影響` 見出しの直前）へ次を挿入する:

```markdown
- **部分修正（ADR-0111）**: Decision 1「Layer 2 ファイルは1つに統一する」は「Layer 2 の**内容の正本**は1つに統一する」へ改められた（物理ファイルはツール到達経路として複数置いてよく、内容を持つのは正本のみ）。Copilot CLI の二重読み込みを避ける目的は、ポインタ 1 行しか余分に読ませないことで達成される。あわせて Decision 7「AGENTS.md は Claude Code がネイティブに読まないため採用しない」の不採用理由は、`CLAUDE.md` 内の `@path` インポートが公式サポートされていることの確認により失効し、採用へ転換した。この転換により Considered Alternatives 案 2（AGENTS.md 単一ソース＋`@AGENTS.md` インポート）の否定評価も前提失効により覆っている。ADR-0111 以降の Layer 2 の内容正本はルート `AGENTS.md` である
```

- [ ] **Step 2: 書式と配置を確認する**

```bash
grep -n "部分修正（ADR-0111）" docs/records/decisions/0023-unify-layer2-into-claude-md.md
grep -n "^- \*\*Status\*\*\|^## Consequences\|^### 良い影響" docs/records/decisions/0023-unify-layer2-into-claude-md.md
```

期待: 注記が `## Consequences` と `### 良い影響` の間の行番号に入っており、Status 行は `Accepted` のまま。

- [ ] **Step 3: コミットする**

```bash
git add docs/records/decisions/0023-unify-layer2-into-claude-md.md && git commit -m "adr: 0023 に部分修正注記（Decision 1 / Decision 7）を追記"
```

---

## Task 11: 検証を実施する

**Files:** 変更なし（不整合が見つかった場合のみ該当ファイルを修正して追加コミット）

spec の検証 1〜5・8・9 を実施する。検証 6・7・10 はユーザー確認事項であり、結果を handoff へ引き継ぐ。

- [ ] **Step 1: 検証 1 — Codex の Layer 2 注入**

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex debug prompt-input | Out-File -Encoding utf8 "$env:TEMP\codex-verify.json"
@(Select-String -Path "$env:TEMP\codex-verify.json" -Pattern 'プロジェクトエージェント指示').Count
@(Select-String -Path "$env:TEMP\codex-verify.json" -Pattern 'INSTRUCTIONS').Count
```

期待: 1 つ目・2 つ目とも 1 以上（AGENTS.md が `<INSTRUCTIONS>` として注入されている）。

- [ ] **Step 2: 検証 2・3 — Codex への Layer 3 インストールと native 優先**

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex plugin marketplace add "D:\Dev\002_AiDev\MakeAiInstructions"
& $codex plugin marketplace list
& $codex plugin add ai-driven-dev-principles@ai-driven-dev-principles
& $codex plugin list
```

期待: `marketplace list` に `ai-driven-dev-principles` の行があり、その ROOT がリポジトリルートであること。`plugin add` が `installed, enabled 0.1.12` を返すこと。

**native が優先されていることの確認**（検証 3）: spec 検証 3 は「`codex plugin list` が表示する manifest パスが `.agents/plugins/marketplace.json` であること」を求めている。**キャッシュに `.codex-plugin/plugin.json` があることは native 優先の証拠にならない**——native / legacy いずれの経路でも `source` は同じ `./dist` を指し、`dist/` には `.claude-plugin/plugin.json` と `.codex-plugin/plugin.json` の両方が入るため、どちらが採用されても両ファイルがキャッシュに現れる。判定は marketplace の解決パスで行う。

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex plugin marketplace list
& $codex plugin list
```

`codex plugin list` は**マーケットプレイスごとに、採用した manifest の絶対パスを見出しの直下に 1 行で表示する**（2026-08-25 に codex-cli 0.149.0-alpha.4.3 で実測。native のみを持つ `openai-bundled` は `…\.agents\plugins\marketplace.json`、legacy のみを持つ `superpowers-marketplace` は `…\.claude-plugin\marketplace.json` と表示される）。出力はこの形になる:

```
Marketplace `ai-driven-dev-principles`
<マーケットプレイス ROOT>\.agents\plugins\marketplace.json

PLUGIN                                             STATUS              VERSION  PATH
ai-driven-dev-principles@ai-driven-dev-principles  installed, enabled  0.1.12   <ROOT>\dist
```

期待: `Marketplace \`ai-driven-dev-principles\`` の直下の行が `.agents\plugins\marketplace.json` で**終わる**こと（`.claude-plugin\marketplace.json` ではないこと）。

**判定は末尾のファイル名だけで行う**。パスの接頭辞は登録形態によって変わる——git 登録のマーケットプレイスは `~/.codex/.tmp/marketplaces/<名前>/` へスナップショットされ、バンドル分は `~/.codex/.tmp/bundled-marketplaces/` 配下を指す（2026-08-25 実測）。ローカル絶対パス登録がリポジトリルートを直接指すかスナップショットを作るかは未実測であり、どちらでも末尾での判定は成立する。

**マニフェストの中身の値で判別してはならない**——`interface.displayName` や `category` は `.agents/plugins/marketplace.json` と `dist/.codex-plugin/plugin.json` の両方に入る。native / legacy いずれの marketplace が採用されても `source` は同じ `./dist` を指すため、`dist/` 経由で現れる値は採用経路を区別しない（この Step の冒頭でキャッシュ検査を退けたのと同じ理由である）。判別できるのは上の manifest パス表示だけである。

**検証 3 を未確認のまま引き継いではならない**——spec の完了条件が繰り延べを許しているのは検証 6・7・10 の 3 件のみで、検証 3 は「通る」側にある。manifest パスの表示が得られない場合は、実装完了と判定せず原因究明を続けるか、spec 完了条件の側へ条件付きの繰り延べを明記する改訂をユーザーへ提起する。

スキル配置の裏取り（検証 2 の一部）:

```powershell
$cache = Join-Path $env:USERPROFILE ".codex\plugins\cache\ai-driven-dev-principles"
(Get-ChildItem (Join-Path $cache "*\*\skills\*") -Directory).Count
```

期待: `13`。**末尾のワイルドカードを落として `"*\*\skills"` としてはならない**——それは `skills` ディレクトリ自体を数えるため必ず `1` を返し、スキル本数の裏取りにならない（2026-08-25 実測）。

- [ ] **Step 3: 検証 4 — スキル一覧が警告なく全件列挙されること**

```powershell
$codex = (Get-ChildItem "$env:LOCALAPPDATA\OpenAI\Codex\bin" -Recurse -Filter codex.exe -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
& $codex debug prompt-input | Out-File -Encoding utf8 "$env:TEMP\codex-skills.json"
$t = Get-Content "$env:TEMP\codex-skills.json" -Raw
@('start-work','decision-log','session-handoff','pre-finalization-review','worklog-skillify') | Where-Object { $t -match $_ } | Measure-Object | Select-Object -ExpandProperty Count
@('truncat','budget','exceed') | Where-Object { $t -match $_ } | Measure-Object | Select-Object -ExpandProperty Count
```

期待: 1 つ目が `5`（本プラグインのスキルが一覧に載っている）、2 つ目が `0`（予算超過の警告が出ていない）。

**`Select-String` の `.Count` を使ってはならない**——`codex debug prompt-input` はスキル一覧を含む `<skills_instructions>` 全体を 1 本の JSON 文字列（＝1 行）に載せるため、`Select-String` は複数パターンが当たっても行数 1 しか返さない。上のように文字列全体へパターンごとに `-match` を掛けること。

2 つ目が `0` でない場合は description の短縮を課題として起票する（本サイクルでは修正しない）。

- [ ] **Step 4: 検証 5 — 生成器と執行点**

```bash
pwsh -NoProfile scripts/build-dist.ps1; echo "build=$?"
pwsh -NoProfile scripts/sync-template.ps1; echo "sync=$?"
pwsh -NoProfile scripts/build-dist.ps1 -Check; echo "build-check=$?"
pwsh -NoProfile scripts/sync-template.ps1 -Check; echo "sync-check=$?"
git status --short -- dist template .agents .claude-plugin
```

期待: 4 つとも `=0`。`git status --short` は**生成物のパスに限定して**空であること（生成物がすべてコミット済み）。

**`git status --short` を引数なしで実行して「空」を期待してはならない**——本リポジトリには本サイクル以前からの未コミット変更（`docs/inbox/` の未整理メモ 3 件、`docs/conversation_log.md`、`docs/working/issues/flow/0107-*` の変更、本計画ファイル自身）が存在し、常に非空になる。取りこぼし検出という目的はパス限定で果たせる。

version 一致検査の動作は Task 8 Step 2 で確認済み。

- [ ] **Step 5: 検証 8 — サイズ監視の生存確認**

```bash
pwsh -NoProfile scripts/check-claude-md-size.ps1; echo "exit=$?"
```

期待: `[check-claude-md-size] AGENTS.md: 8069 bytes (threshold 12000), 25 bullets (threshold 45), 92 lines` と `exit=0`、警告行が出ないこと。バイト数は Task 3 Step 2・3 の文言追加により切替前の 7,915 バイトから約 150 バイト増える。**判定は「先頭ラベルが `AGENTS.md` であること・閾値 12000 と 45 の内側であること・警告行が出ないこと」で行い、バイト数の一致は求めない**（以降のタスクで AGENTS.md を編集すれば当然変わるため）。

- [ ] **Step 6: 検証 9 — 網羅性チェック**

生きたファイル（README・CONTRIBUTING・AGENTS.md・skills・scripts・docs/overview・plugin.json・template.manifest）に残留参照が無いことを確認する。

3 本の grep はいずれも spec 検証 9 が挙げる生きたファイル集合（README・CONTRIBUTING・AGENTS.md・skills・scripts・docs/overview・plugin.json・template.manifest）を同じ範囲で走査する。以下ではこの集合を `$LIVE` として定義する。

```bash
LIVE="README.md CONTRIBUTING.md AGENTS.md template.manifest .claude-plugin/ docs/overview/ skills/ scripts/"
```

**(a) Layer 2 を指す残留参照**

```bash
grep -rn "CLAUDE\.md" $LIVE
```

**除外フィルタを付けてはならない**。`grep -rn` は出力行の先頭にファイルパスを付けるため、`grep -v "check-claude-md-size"` も `grep -v "check-claude-md-size\.ps1"` も**同じく `scripts/check-claude-md-size.ps1` の全行を落とす**（落とす主体はメッセージ接頭辞ではなくパス接頭辞であり、両形式の挙動は同一）。まさに Task 3 Step 6 が書き換える 20・35 行目の漏れがそこで盲点になる（この 2 行は通常実行で発火しないため、他のどの検証でも捕捉されない）。そして除外はそもそも不要である——検索語 `CLAUDE\.md` は大文字小文字を区別し、小文字ハイフン表記のスクリプト名 `check-claude-md-size.ps1` には一致しないため、除外が無くても偽陽性は 1 件も出ない。この形にすることで Task 3 Step 6 の確認と二重に効く。

期待: **21 行**が出力され、そのすべてが次の**意図的な言及**に収まること（当初の見積りは 20 行だったが、ADR-0114 が `skills/worklog-skillify/SKILL.md:37` へ書き込み側の二段フォールバックを追加したため 1 行増えた）。それ以外が出たら該当箇所を修正して追加コミットする。

| 分類 | 行数 | 箇所 |
|---|---|---|
| ポインタである旨の説明 | 3 | README の Layer 2 表・Layer 2 注記、CONTRIBUTING の Layer 2 行 |
| 既存プロジェクト移行手順の節 | 3 | README |
| 「新しいプロジェクトでの使い方」手順 3 | 1 | README（`CLAUDE.md` は `@AGENTS.md` の 1 行のままにする、の部分） |
| 二段フォールバック表現（読み側） | 8 | skills 7 箇所（`session-handoff` が 4——113・163・180・219 行目。うち 113 行目は Step 3 の書き込み側の但し書き）・`docs/overview/issue-management.md` 1 箇所 |
| 二段フォールバック表現（書き込み側。ADR-0114） | 1 | `skills/worklog-skillify/SKILL.md:37` |
| sync-template 実行条件の列挙 | 3 | CONTRIBUTING |
| template.manifest のエントリとコメント | 2 | `template.manifest` |

`scripts/` からは 1 行も出ないこと（出たら Task 3 Step 6 の 5 箇所のいずれかが未書き換え）。

**(b) ローカルスキル配置先の残留参照**

```bash
grep -rn "\.claude/skills" $LIVE
```

期待: 出力に現れるのは配置先併記の 3 箇所のみ（いずれも `.agents/skills/` の併記を伴う）。

**(c)「2 ツールのみ前提」の記述**

```bash
grep -rn "Copilot CLI / Claude Code\|Copilot CLI または Claude Code\|Copilot CLI と Claude Code" $LIVE | grep -v "Claude Code / OpenAI Codex"
```

期待: 出力が空。

**後段フィルタ `grep -v "Claude Code / OpenAI Codex"` を省いてはならない**——検索語 `Copilot CLI / Claude Code` は、本計画が Task 3・6・7 で書き込む正しい 3 ツール表記 `GitHub Copilot CLI / Claude Code / OpenAI Codex` の**部分文字列**である。フィルタが無いと、計画を完全に正しく実施した状態でも 6 件（`README.md` 3 件・`CONTRIBUTING.md` 1 件・`AGENTS.md` 1 件・`template.manifest` 1 件）がヒットし、期待値「出力が空」は原理的に成立しない。フィルタ無しの形で実行すると、正しい 3 ツール表記を grep に合わせて壊す是正へ誘導される。

既存 2 ツール専用のインストール節見出し（「Copilot CLI へのインストール」「Claude Code へのインストール」）は各ツール向けの手順であり、本 grep の検索語に該当しない。

- [ ] **Step 7: 配布物の目視 5 項目**

CONTRIBUTING「機械判定が届かない領域」の 5 項目を、生成後の `dist/skills/` と `template/` に対して実施する。**これは 2 巡目にあたる独立工程である**（1 巡目は Task 4 Step 7 と Task 8 Step 3 のコミット前目視）。同節が「目視は 1 回で終わらせず、生成後の配布物を読む工程を別に置くこと」と定めているのは、1 巡目が取り逃がす実測があるためである。

**ここでは差分ではなく配布物そのものを通読する**（同節の実測は「配布物を通読するレビューで検出された」ことを根拠にしている）。対象は 1 巡目が覆った Task 4・Task 8 の差分に加え、1 巡目のコミット前目視を置いていない Task 2（`dist/.codex-plugin/plugin.json` の新設）・Task 3（`template/AGENTS.md` の新設）・Task 5（`template/docs/overview/issue-management.md` への入れ子全角括弧の追加）の生成結果も含める。とくに Task 5 が加える `（プロジェクトの AGENTS.md（当該調整値の記載が無ければ CLAUDE.md）に調整値があればそれを優先）` は、目視 5 項目の 1 番目（括弧内に識別子以外の語が同居した行）の検査対象にあたる。

```bash
git diff master...HEAD --stat -- dist template
```

読む対象:

1. **括弧内に識別子以外の語が同居した行**: 本サイクルで追加した括弧内テキスト（二段フォールバック表現・配置先併記）に識別子が混じっていないか
2. **半角括弧**: 追加テキストで `(` `)` を使っていないか
3. **書式例の実在の固有名**: 追加テキストに絶対パス・プロジェクト名が入っていないか
4. **自己参照**: 追加テキストに `本リポジトリ` / `本 repo` が入っていないか（`template/AGENTS.md` の「本ファイル」は配布先自身を指すため適合）
5. **スクリプトの docstring・表示メッセージ**: `scripts/` は配布対象ソースではないため対象外。`dist/skills/worklog-extract/scripts/` 配下は本サイクルで変更していない

```bash
grep -rn "本リポジトリ\|本 repo" dist/ template/
grep -rnE "\((ADR|Issue)-[0-9]{4}" dist/ template/
```

期待: いずれも出力が空。

- [ ] **Step 8: 検証 6・7・10 をユーザー確認事項として整理する**

次の 3 件は本セッションで完結しない。結果を handoff の「既知のブロッカー・懸念」または「未着手のタスク」へ書き出す。

- **検証 6**（既存 2 ツールの Layer 3 退行確認）: Claude Code で `/plugin marketplace update ai-driven-dev-principles` 後、Copilot CLI で `copilot plugin update ai-driven-dev-principles` 後に、それぞれ 13 スキルが認識されること
- **検証 7**（既存 2 ツールの Layer 2 退行確認）: Claude Code の `/context` で `CLAUDE.md` 経由の `@AGENTS.md` 展開を最終確認。Copilot CLI で AGENTS.md ＋ポインタ CLAUDE.md の同居で指示が読み込まれること。Copilot CLI が利用不能な場合は「未確認」と明記し完了条件外とする
- **検証 10**（GitHub 経由の native 登録）: リリース後に `codex plugin marketplace add taika-izumi/ai-driven-dev-principles` で native manifest が解決されること

- [ ] **Step 9: 検証で修正が生じた場合のみコミットする**

```bash
git status --short -- dist template .agents .claude-plugin README.md CONTRIBUTING.md AGENTS.md CLAUDE.md template.manifest docs/overview skills scripts docs/current/specs docs/records/decisions
```

出力が空なら追加コミット不要。修正した場合は**修正した具体パスを明示列挙して**コミットする:

```bash
git add <修正したファイル> <再生成された生成物> && git commit -m "fix: 検証で検出した残留参照を是正"
```

**`git add -A` を使ってはならない**——本リポジトリには本サイクルと無関係な未コミットファイル（`docs/inbox/` の未整理メモ 3 件、`docs/conversation_log.md`、`docs/working/issues/flow/0107-*` の変更、本計画ファイル自身）があり、`-A` はそれらを「残留参照の是正」というコミットメッセージのもとに巻き込む。

---

## Task 12: ADR を昇格し handoff を更新する

**Files:**
- Modify: `docs/records/decisions/0111-agents-md-as-layer2-source-of-truth.md`
- Modify: `docs/records/decisions/0112-codex-native-marketplace-generated.md`
- Modify: `docs/records/decisions/README.md`（台帳の Status 列）
- Modify: `docs/working/handoff/feature_codex-support.md`

- [ ] **Step 1: ADR-0111・ADR-0112 を Accepted へ昇格する**

両 ADR の `- **Status**: Proposed` を `- **Status**: Accepted` へ変更する。手順は `decision-log` の「承認の昇格」に従い、**サイクル全体整合検査と粒度の点検を含める**。

```bash
grep -n "Status" docs/records/decisions/0111-agents-md-as-layer2-source-of-truth.md docs/records/decisions/0112-codex-native-marketplace-generated.md
grep -n "0111\|0112" docs/records/decisions/README.md
```

期待: 両 ADR が `Accepted`。台帳の該当行の Status 列も追随していること。

- [ ] **Step 2: サイクル全体整合検査を実施する**

`decision-log` の「サイクル全体整合検査」に従い、本サイクルで作成・改訂した ADR（0110・0111・0112 と部分修正した 0023）の間に矛盾が無いことを点検する。結果は handoff の消化記録へ `cyclecheck=` として記す。

- [ ] **Step 3: handoff を更新する**

`session-handoff` の **update** を呼ぶ。反映内容:

- 完了済みタスクへ Task 1〜12 の到達を記す
- 「進行中のタスク」を実装完了後の状態（ユーザー確認事項の残り）へ書き換える
- 「既知のブロッカー・懸念」へ検証 6・7・10 の未確認事項を移す
- 「既知のブロッカー・懸念」へ、Task 9 で本サイクルの対象外と判断した件を**母数つきで 1 行**残す: `docs/current/specs/` 配下に、本サイクルが直接触らない `CLAUDE.md` 参照を持つ spec が 15 ファイル残る（代表例は `2026-08-07-overfitting-check-for-extensions-design.md:53`。いずれも本サイクルの変更が直接無効化する記述ではないため同期していない）。1 件だけを名指しして残りを見落としとして固定化しない
- Task 11 Step 2 で native 優先の判定ができなかった場合は、その旨も「既知のブロッカー・懸念」へ残す（ただし検証 3 は spec 完了条件が繰り延べを許していないため、未確認のまま実装完了と判定しない）
- 「Post ラッパー消化記録」へ、plan 確定点の行（`review=`）と実装完了・ADR 昇格の行（`cyclecheck=` を含む）を追記する

- [ ] **Step 4: コミットする**

```bash
git add docs/records/decisions docs/working/handoff && git commit -m "adr: 0111 / 0112 を Accepted へ昇格し handoff を更新"
```

---

## 完了条件（spec からの写像）

実装完了の判定は spec「完了条件」に従う。対応表:

| spec の完了条件 | 対応タスク |
|---|---|
| ルート `AGENTS.md` が Layer 2 の内容正本として存在し、`CLAUDE.md` が `@AGENTS.md` の 1 行である | Task 3 |
| `.agents/plugins/marketplace.json` と `dist/.codex-plugin/plugin.json` が生成器から導出され、両 `-Check` が通る | Task 2・Task 11 Step 4 |
| `.claude-plugin/` 2 ファイルの version が 0.1.12 で一致し、生成物へ波及している | Task 8 |
| `check-claude-md-size.ps1` の計測対象が AGENTS.md である | Task 3 Step 6・Task 11 Step 5 |
| README に Codex インストール節（本ガイドライン＋superpowers・更新手順込み）と既存プロジェクト移行手順の節がある | Task 6 |
| 検証 1〜5・8・9 が通る（6・7・10 はユーザー確認事項として handoff に引き継ぐ） | Task 11 |
| ADR-0111・0112 が Accepted に昇格し、ADR-0023 に部分修正注記（Decision 1・7）が付いている | Task 10・Task 12 |
| 生成器 spec（02/03）のスナップショットが実装後の挙動と一致している | Task 9 |
