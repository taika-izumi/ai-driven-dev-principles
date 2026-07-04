# テンプレートフォルダと同期メカニズム 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新プロジェクトへの転用を `template/` フォルダのコピー1回で完了できるようにする

**Architecture:** `template.manifest` に対象ファイルを定義し、`scripts/sync-template.ps1` がマニフェストを読み取ってリポジトリ直下から `template/` へ完全同期（削除+再構築）する。既存の CONTRIBUTING.md、extend-guidelines SKILL.md、README.md を更新して同期ワークフローを組み込む。

**Tech Stack:** PowerShell 5.1+, Markdown

---

## ファイルマップ

| 種別 | ファイル | 責務 |
|------|---------|------|
| 新規 | `template.manifest` | テンプレート対象ファイルの定義 |
| 新規 | `scripts/sync-template.ps1` | マニフェストベースの完全同期スクリプト |
| 生成 | `template/`（フォルダ + 中身一式） | sync-template.ps1 の実行結果として生成 |
| 更新 | `CONTRIBUTING.md:82-87` | シナリオ3「Skill作成」にテンプレート判定ステップ追加 |
| 更新 | `skills/extend-guidelines/SKILL.md:32-38` | テンプレート同期案内ステップ追加 |
| 更新 | `README.md:39-44` | 「新しいプロジェクトでの使い方」簡素化 |

---

### Task 1: マニフェストファイルの作成

**Files:**
- Create: `template.manifest`

- [ ] **Step 1: template.manifest を作成する**

```
# テンプレート対象ファイル
# リポジトリ直下のパス → template/ 内に同じパスでコピーされる
#
# 空行・#始まりの行は無視される
# ADRインデックス (docs/decisions/README.md) は同期スクリプトが空版を自動生成する

.github/copilot-instructions.md
docs/principles.md
skills/decision-log/SKILL.md
skills/pre-action-review/SKILL.md
```

- [ ] **Step 2: コミットする**

```powershell
git add template.manifest
git commit -m "feat: add template.manifest for template sync"
```

---

### Task 2: 同期スクリプトの作成

**Files:**
- Create: `scripts/sync-template.ps1`

- [ ] **Step 1: scripts ディレクトリを作成し、sync-template.ps1 を作成する**

```powershell
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
```

- [ ] **Step 2: コミットする**

```powershell
git add scripts/sync-template.ps1
git commit -m "feat: add sync-template.ps1 for manifest-based template sync"
```

---

### Task 3: 同期スクリプトを実行してテンプレートを生成する

**Files:**
- Generate: `template/.github/copilot-instructions.md`
- Generate: `template/docs/principles.md`
- Generate: `template/docs/decisions/README.md`
- Generate: `template/skills/decision-log/SKILL.md`
- Generate: `template/skills/pre-action-review/SKILL.md`

- [ ] **Step 1: スクリプトを実行する**

```powershell
pwsh scripts/sync-template.ps1
```

期待される出力:
```
[sync-template] Cleaning template/ ...
[sync-template] Reading template.manifest...
[sync-template] Syncing 4 files + ADR index...
  ✓ .github/copilot-instructions.md
  ✓ docs/principles.md
  ✓ skills/decision-log/SKILL.md
  ✓ skills/pre-action-review/SKILL.md
  ✓ docs/decisions/README.md (empty index generated)
[sync-template] Done. 5 files synced to template/
```

- [ ] **Step 2: 生成されたファイルを検証する**

以下を確認する:

1. `template/` フォルダの構造がスペックのツリーと一致する:
   ```
   template/
   ├── .github/copilot-instructions.md
   ├── docs/decisions/README.md
   ├── docs/principles.md
   └── skills/
       ├── decision-log/SKILL.md
       └── pre-action-review/SKILL.md
   ```

2. 各ファイルの内容がリポジトリ直下版と一致する（ADRインデックス以外）:
   ```powershell
   # copilot-instructions.md の差分なし確認
   diff (Get-Content .github/copilot-instructions.md) (Get-Content template/.github/copilot-instructions.md)
   ```

3. ADRインデックスがエントリなしの空版になっている:
   ```powershell
   Get-Content template/docs/decisions/README.md
   ```
   期待: ヘッダー・説明・判定基準・テーブルヘッダー・セパレーター行のみ。`[0001]` や `[0002]` のデータ行なし。

- [ ] **Step 3: 冪等性を検証する**

スクリプトを再度実行し、結果が同じであることを確認する:
```powershell
pwsh scripts/sync-template.ps1
```

- [ ] **Step 4: コミットする**

```powershell
git add template/
git commit -m "feat: generate template folder via sync-template.ps1"
```

---

### Task 4: CONTRIBUTING.md の更新

**Files:**
- Modify: `CONTRIBUTING.md:82-94`

- [ ] **Step 1: シナリオ3の「手順」セクションにテンプレート判定ステップを追加する**

現在の手順（L82-87）:
```markdown
### 手順

1. 上の判定表でSkill化が適切か確認する
2. `skills/<skill-name>/SKILL.md` を作成する（YAMLフロントマター + markdown本文）
3. 対応する原則との紐付けをSkill内に記載する
4. ADRで作成理由を記録する
```

変更後:
```markdown
### 手順

1. 上の判定表でSkill化が適切か確認する
2. `skills/<skill-name>/SKILL.md` を作成する（YAMLフロントマター + markdown本文）
3. 対応する原則との紐付けをSkill内に記載する
4. テンプレート対象か判断する: 新プロジェクトで汎用的に使えるSkillなら `template.manifest` に追加する。このリポジトリの運用専用Skillなら追加しない
5. テンプレート対象の場合、`scripts/sync-template.ps1` を実行してテンプレートフォルダを同期する
6. ADRで作成理由を記録する
```

- [ ] **Step 2: チェックリストにテンプレート関連項目を追加する**

現在のチェックリスト（L89-94）:
```markdown
### チェックリスト

- `copilot-instructions.md` の記述で十分ではないか（YAGNI確認）
- Skill名が動作を端的に表しているか
- YAML frontmatter（`name`, `description`）が正しいか
- 対応する原則への参照があるか
```

変更後:
```markdown
### チェックリスト

- `copilot-instructions.md` の記述で十分ではないか（YAGNI確認）
- Skill名が動作を端的に表しているか
- YAML frontmatter（`name`, `description`）が正しいか
- 対応する原則への参照があるか
- テンプレート対象の場合、`template.manifest` に追加したか
```

- [ ] **Step 3: コミットする**

```powershell
git add CONTRIBUTING.md
git commit -m "docs: add template eligibility steps to CONTRIBUTING.md skill scenario"
```

---

### Task 5: extend-guidelines SKILL.md の更新

**Files:**
- Modify: `skills/extend-guidelines/SKILL.md:32-38`

- [ ] **Step 1: ステップ5（テンプレート同期案内）を追加する**

現在のステップ4の後（L32-38）:
```markdown
### 4. brainstorming を開始する

ユーザーの要望と CONTRIBUTING.md の拡張ルールをコンテキストとして保持したまま、brainstorming スキルを呼び出す。brainstorming では以下を念頭に置く:

- CONTRIBUTING.md の判定基準とチェックリストを設計の制約として扱う
- 既存の原則・指示・スキルとの整合性を確認する
- ADRの作成が必要かどうかを判断する（CONTRIBUTING.md「ADRを記録するとき」セクション参照）
```

末尾に追加:
```markdown

### 5. テンプレートの同期を案内する

拡張作業の完了後、以下の条件に該当する場合はテンプレートフォルダの同期が必要であることをユーザーに案内する:

- `docs/principles.md` を変更した
- `.github/copilot-instructions.md` を変更した
- テンプレート対象のSkill（`template.manifest` に記載されているもの）を変更した
- 新しいSkillを作成し、テンプレート対象と判断した

案内内容: 「テンプレートフォルダへの同期が必要です。`scripts/sync-template.ps1` を実行してください。」
```

- [ ] **Step 2: コミットする**

```powershell
git add skills/extend-guidelines/SKILL.md
git commit -m "feat: add template sync guidance to extend-guidelines skill"
```

---

### Task 6: README.md の更新

**Files:**
- Modify: `README.md:39-44`

- [ ] **Step 1: 「新しいプロジェクトでの使い方」セクションを簡素化する**

現在（L39-44）:
```markdown
## 新しいプロジェクトでの使い方

1. `.github/copilot-instructions.md` を新プロジェクトにコピーする
2. `skills/` ディレクトリを新プロジェクトにコピーする
3. プロジェクト固有の指示を `copilot-instructions.md` に追記する
4. `docs/decisions/` ディレクトリを作成し、`README.md`（ADRインデックス）を配置する
```

変更後:
```markdown
## 新しいプロジェクトでの使い方

1. `template/` フォルダの中身を新プロジェクトのルートにコピーする
2. `copilot-instructions.md` にプロジェクト固有の指示を追記する
```

- [ ] **Step 2: コミットする**

```powershell
git add README.md
git commit -m "docs: simplify project adoption steps using template folder"
```

---

### Task 7: 最終検証

- [ ] **Step 1: テンプレートフォルダの構造を最終確認する**

```powershell
Get-ChildItem -Recurse template/ | Select-Object FullName
```

期待されるファイル（5個）:
- `template/.github/copilot-instructions.md`
- `template/docs/decisions/README.md`
- `template/docs/principles.md`
- `template/skills/decision-log/SKILL.md`
- `template/skills/pre-action-review/SKILL.md`

- [ ] **Step 2: ADRインデックスの空版を確認する**

```powershell
Get-Content template/docs/decisions/README.md
```

期待: データ行（`| [0001]...`）がないこと。

- [ ] **Step 3: git status でクリーンであることを確認する**

```powershell
git --no-pager status
```

期待: `nothing to commit, working tree clean`

- [ ] **Step 4: コミット履歴を確認する**

```powershell
git --no-pager log --oneline -8
```

期待: Task 1-6 の6コミットが存在すること。
