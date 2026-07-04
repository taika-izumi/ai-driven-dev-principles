# Claude Code 対応（Layer 2 を CLAUDE.md に一本化）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Layer 2 の行動指示を単一の `CLAUDE.md`（リポジトリルート）に一本化し、GitHub Copilot CLI と Claude Code の両方で同一ガイドラインが機能する状態にする。

**Architecture:** `.github/copilot-instructions.md` を廃止し、内容を中立化してルート `CLAUDE.md` に移す。両ツールがルート `CLAUDE.md` を既定で読むため変換・生成は不要。波及して template.manifest / README / CONTRIBUTING / スキル / plugin.json の参照を更新する。

**Tech Stack:** Markdown ドキュメント、PowerShell（`scripts/sync-template.ps1`）、JSON（plugin manifest）。本リポジトリにテストフレームワークは無く、検証は `grep` による参照チェックと `sync-template.ps1` の実行・成果物確認で行う。

**関連:** ADR-0023（Proposed）、`docs/specs/2026-06-16-claude-code-support-design.md`

---

## File Structure

| ファイル | 責務 | 操作 |
|---|---|---|
| `CLAUDE.md`（ルート） | 両ツール共通の Layer 2 行動指示（単一ソース） | 作成 |
| `.github/copilot-instructions.md` | 旧 Layer 2 | 削除 |
| `template.manifest` | template 同期対象リスト | エントリ＋コメント更新 |
| `template/CLAUDE.md` / `template/.github/copilot-instructions.md` | template 配布物 | sync-template 実行で置換 |
| `README.md` | 人間向け説明・インストール手順 | Layer 2 表記・位置づけ文言更新＋Claude Code 節追加 |
| `CONTRIBUTING.md` | 拡張ルール | Layer 2 行・シナリオ更新 |
| `skills/start-work/SKILL.md` | 起点スキル | Layer 2 参照更新 |
| `skills/extend-guidelines/SKILL.md` | 拡張ゲートウェイ | description・本文・同期案内更新 |
| `.claude-plugin/plugin.json` | プラグインメタデータ | 説明文の参照更新 |

---

## Task 1: ルート CLAUDE.md を作成（中立化）し、旧 copilot-instructions.md を削除

**Files:**
- Create: `CLAUDE.md`
- Delete: `.github/copilot-instructions.md`

- [ ] **Step 1: 現行 `.github/copilot-instructions.md` の内容を確認**

Run: `Get-Content .github/copilot-instructions.md | Select-Object -First 14`
Expected: 1行目 `# Copilot Instructions`、3行目 `## 前提条件: Copilot CLI プラグインのインストール` を確認。

- [ ] **Step 2: ルートに `CLAUDE.md` を作成**

現行 `.github/copilot-instructions.md` の **15 行目以降（`## システム設定` 以降）はそのまま流用**し、先頭のタイトル＋前提条件節だけを以下に差し替える。

冒頭（1〜13行目相当）を次の内容にする:

```markdown
# プロジェクトエージェント指示

## 前提条件: ガイドラインスキルのプラグイン導入

<EXTREMELY-IMPORTANT>

本ガイドラインで指示する `start-work`, `decision-log`, `session-handoff`, `feature-block-design`, `pre-action-review`, `retrospective`, `extend-guidelines` などのスキルは、プラグイン `ai-driven-dev-principles` から提供される。本ファイルが配置されたプロジェクトで作業する前に、利用するツール（GitHub Copilot CLI または Claude Code）に当該プラグインをインストール・有効化しておくこと。

インストール手順は本リポジトリ（[taika-izumi/ai-driven-dev-principles](https://github.com/taika-izumi/ai-driven-dev-principles)）の README を参照（GitHub Copilot CLI 利用時は「Copilot CLI へのインストール」節、Claude Code 利用時は「Claude Code へのインストール」節）。

プラグイン未インストール環境では本ガイドラインの大半が機能しないため、利用者は事前に環境準備を完了させること。

</EXTREMELY-IMPORTANT>
```

その後ろに、現行ファイルの `## システム設定`（15行目）から末尾（96行目 `docs/specs/...` の項目）までを**そのまま**続ける。本文は変更しない。

- [ ] **Step 3: 旧ファイルを削除**

Run: `git rm .github/copilot-instructions.md`
Expected: `rm '.github/copilot-instructions.md'`

- [ ] **Step 4: 内容検証**

Run: `Select-String -Path CLAUDE.md -Pattern 'Copilot Instructions','Copilot CLI プラグインのインストール'`
Expected: 一致なし（タイトル・旧前提条件節が残っていない）。

Run: `Select-String -Path CLAUDE.md -Pattern 'start-work スキルを呼ぶこと'`
Expected: 1件一致（本文が引き継がれている）。

- [ ] **Step 5: Commit**

```powershell
git add CLAUDE.md .github/copilot-instructions.md
git commit -m "feat: move Layer 2 instructions to root CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: template.manifest を更新（エントリ差し替え＋コメント中立化）

**Files:**
- Modify: `template.manifest`

- [ ] **Step 1: エントリを差し替え**

`template.manifest` の `10` 行目を変更する:

変更前:
```
.github/copilot-instructions.md
```
変更後:
```
CLAUDE.md
```

- [ ] **Step 2: コメントを中立化**

`template.manifest` の `8` 行目を変更する:

変更前:
```
# （スキル本体は Copilot CLI プラグイン ai-driven-dev-principles から提供されるため）
```
変更後:
```
# （スキル本体は GitHub Copilot CLI / Claude Code プラグイン ai-driven-dev-principles から提供されるため）
```

- [ ] **Step 3: 検証**

Run: `Select-String -Path template.manifest -Pattern 'copilot-instructions'`
Expected: 一致なし。

Run: `Select-String -Path template.manifest -Pattern '^CLAUDE\.md$'`
Expected: 1件一致。

- [ ] **Step 4: Commit**

```powershell
git add template.manifest
git commit -m "chore: point template.manifest at CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: sync-template.ps1 を実行し template/ を再生成

**Files:**
- Run: `scripts/sync-template.ps1`
- Result: `template/CLAUDE.md`（生成）、`template/.github/copilot-instructions.md`（消滅）

- [ ] **Step 1: 同期スクリプトを実行**

Run: `pwsh scripts/sync-template.ps1`
Expected: `✓ CLAUDE.md` が出力され、エラーなく `Done.` で終了。

> 補足: `sync-template.ps1` は manifest 駆動の単純コピーのため、生成ロジックの追加は不要。Task 2 の manifest 更新だけで CLAUDE.md が同期される。

- [ ] **Step 2: 成果物を検証**

Run: `Test-Path template/CLAUDE.md; Test-Path template/.github/copilot-instructions.md`
Expected: `True` と `False`。

Run: `Select-String -Path template/CLAUDE.md -Pattern 'Copilot Instructions'`
Expected: 一致なし（中立化済みの内容がコピーされている）。

- [ ] **Step 3: Commit**

```powershell
git add template/
git commit -m "chore: sync template/ to CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: README を更新（Layer 2 表記・位置づけ文言＋Claude Code 節）

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 概要の位置づけ文言を両ツール対応に**

`README.md` 7 行目を変更する:

変更前:
```
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot で実践するための仕組みを提供する。
```
変更後:
```
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot CLI / Claude Code で実践するための仕組みを提供する。
```

- [ ] **Step 2: 構造表の Layer 2 行を更新**

`README.md` 18 行目を変更する:

変更前:
```
| Layer 2 | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Copilot向け行動指示 |
```
変更後:
```
| Layer 2 | [`CLAUDE.md`](CLAUDE.md) | エージェント向け行動指示（GitHub Copilot CLI / Claude Code 共通） |
```

- [ ] **Step 3: 「Copilot CLI へのインストール」節の直後に Claude Code 節を追加**

`README.md` の「## Copilot CLI へのインストール」節（現 43〜89 行目）の**末尾**（次の `## 新しいプロジェクトでの使い方` の直前）に、次の節を挿入する:

```markdown
## Claude Code へのインストール

Claude Code でも同じスキル群をプラグインとして利用できる。本リポジトリには Claude Code ネイティブのプラグイン定義（`.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json`）が含まれており、追加変換なしでインストールできる。

### A. GitHub 経由でインストール

Claude Code 上で以下を実行する:

```sh
/plugin marketplace add taika-izumi/ai-driven-dev-principles
/plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

### B. ローカルパスからインストール（開発時）

本リポジトリを clone 済みのマシンでは、ローカルパスをマーケットプレイスとして登録できる:

```sh
/plugin marketplace add <このリポジトリの絶対パス>
/plugin install ai-driven-dev-principles@ai-driven-dev-principles
```

`skills/` を編集した場合は `/plugin marketplace update ai-driven-dev-principles` で反映する。

> **Layer 2 について**: GitHub Copilot CLI と Claude Code はいずれもリポジトリルートの `CLAUDE.md` を行動指示として読み込む。本リポジトリの Layer 2 はこの単一ファイルに統一されている（ADR-0023）。
```

- [ ] **Step 4: 「新しいプロジェクトでの使い方」の前提条件・手順を更新**

`README.md` の「### 前提条件」（現 93〜95 行目付近）と「### 手順」（現 97〜102 行目付近）で、`copilot-instructions.md` への参照を `CLAUDE.md` に、`Copilot CLI プラグイン` を `GitHub Copilot CLI / Claude Code プラグイン` に更新する。

具体的には現「### 手順」3項目目:
```
3. `copilot-instructions.md` にプロジェクト固有の指示を追記する
```
を:
```
3. `CLAUDE.md` にプロジェクト固有の指示を追記する
```
に変更する。前提条件文の「Copilot CLI プラグイン」も「GitHub Copilot CLI / Claude Code プラグイン」に更新する。

- [ ] **Step 5: 検証**

Run: `Select-String -Path README.md -Pattern 'copilot-instructions'`
Expected: 一致なし。

Run: `Select-String -Path README.md -Pattern 'Claude Code へのインストール'`
Expected: 1件一致。

- [ ] **Step 6: Commit**

```powershell
git add README.md
git commit -m "docs: update README for CLAUDE.md and Claude Code install (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: CONTRIBUTING.md を更新（Layer 2 行・シナリオ）

**Files:**
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: 設計思想の Layer 2 行を更新**

`CONTRIBUTING.md` 15 行目を変更する:

変更前:
```
| Layer 2 | `.github/copilot-instructions.md` | Copilot固有の行動指示 |
```
変更後:
```
| Layer 2 | `CLAUDE.md` | エージェント向け行動指示（GitHub Copilot CLI / Claude Code 共通） |
```

- [ ] **Step 2: シナリオ見出しと本文を更新**

`CONTRIBUTING.md` の「## シナリオ: copilot-instructions.md を更新するとき」（49 行目）を:
```
## シナリオ: CLAUDE.md を更新するとき
```
に変更する。

同セクション内（53〜69 行目）の参照・表現を以下のとおり更新する:
- 53 行目「Layer 2はLayer 1の原則を **Copilot固有の行動指示に変換したもの** である」→「Layer 2はLayer 1の原則を **エージェント向けの行動指示に変換したもの** である」
- 54 行目「各原則 → `copilot-instructions.md` の対応セクションへ」→「各原則 → `CLAUDE.md` の対応セクションへ」
- 59 行目「以下に該当するものを `copilot-instructions.md` に記述する:」→「以下に該当するものを `CLAUDE.md` に記述する:」
- 62 行目「Copilot特有の設定（言語、応答スタイル等）」→「エージェント共通の設定（言語、応答スタイル等）」

`CONTRIBUTING.md` 75 行目の表ヘッダー「copilot-instructions.md に書く」→「CLAUDE.md に書く」、93 行目「`copilot-instructions.md` の記述で十分ではないか（YAGNI確認）」→「`CLAUDE.md` の記述で十分ではないか（YAGNI確認）」も更新する。

- [ ] **Step 3: 検証**

Run: `Select-String -Path CONTRIBUTING.md -Pattern 'copilot-instructions','Copilot固有'`
Expected: 一致なし。

- [ ] **Step 4: Commit**

```powershell
git add CONTRIBUTING.md
git commit -m "docs: update CONTRIBUTING Layer 2 references to CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: スキル（start-work / extend-guidelines）を更新

**Files:**
- Modify: `skills/start-work/SKILL.md`
- Modify: `skills/extend-guidelines/SKILL.md`

- [ ] **Step 1: start-work の参照を更新**

`skills/start-work/SKILL.md` 16 行目を変更する:

変更前:
```
このスキルから始まる全ての作業期間中、以下のルールが常時適用される（`copilot-instructions.md` でも宣言されている）:
```
変更後:
```
このスキルから始まる全ての作業期間中、以下のルールが常時適用される（`CLAUDE.md` でも宣言されている）:
```

- [ ] **Step 2: extend-guidelines の description を更新**

`skills/extend-guidelines/SKILL.md` 3 行目を変更する:

変更前:
```
description: "ガイドラインの拡張（原則追加・Skill作成・copilot-instructions更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
```
変更後:
```
description: "ガイドラインの拡張（原則追加・Skill作成・CLAUDE.md更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
```

- [ ] **Step 3: extend-guidelines 本文を更新**

`skills/extend-guidelines/SKILL.md` 24 行目「- copilot-instructions.md を更新したい」→「- CLAUDE.md を更新したい」。

`skills/extend-guidelines/SKILL.md` 45 行目「- `.github/copilot-instructions.md` を変更した」→「- `CLAUDE.md` を変更した」。

- [ ] **Step 4: 検証**

Run: `Select-String -Path skills/start-work/SKILL.md,skills/extend-guidelines/SKILL.md -Pattern 'copilot-instructions'`
Expected: 一致なし。

- [ ] **Step 5: Commit**

```powershell
git add skills/start-work/SKILL.md skills/extend-guidelines/SKILL.md
git commit -m "docs: update skills to reference CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 7: .claude-plugin/plugin.json の説明文を更新

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: 説明文の参照を更新**

`.claude-plugin/plugin.json` 3 行目の `description` を変更する:

変更前（末尾）:
```
本リポジトリの copilot-instructions.md と組み合わせて使用する。
```
変更後（末尾）:
```
本リポジトリの CLAUDE.md と組み合わせて使用する。
```

- [ ] **Step 2: JSON の妥当性を検証**

Run: `Get-Content .claude-plugin/plugin.json -Raw | ConvertFrom-Json | Out-Null; "valid"`
Expected: `valid`（JSON パース成功）。

Run: `Select-String -Path .claude-plugin/plugin.json -Pattern 'copilot-instructions'`
Expected: 一致なし。

- [ ] **Step 3: Commit**

```powershell
git add .claude-plugin/plugin.json
git commit -m "chore: update plugin.json description to CLAUDE.md (ADR-0023)`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 8: 最終網羅検証と ADR-0023 の Accepted 昇格

**Files:**
- Modify: `docs/decisions/0023-unify-layer2-into-claude-md.md`
- Modify: `docs/decisions/README.md`

- [ ] **Step 1: 生きたファイルに残留参照がないか網羅チェック**

Run:
```powershell
git ls-files | Where-Object { $_ -notmatch '^docs/(decisions|specs|plans|retrospectives|handoff)/' -and $_ -ne 'docs/conversation_log.md' } | ForEach-Object { Select-String -Path $_ -Pattern 'copilot-instructions' -ErrorAction SilentlyContinue }
```
Expected: 出力なし（歴史的記録を除く生きたファイルに `copilot-instructions` 参照が残っていない）。

- [ ] **Step 2: ルート CLAUDE.md の存在と旧ファイル不在を確認**

Run: `Test-Path CLAUDE.md; Test-Path .github/copilot-instructions.md`
Expected: `True` と `False`。

- [ ] **Step 3: （可能なら）Copilot CLI / Claude Code での読み込み動作確認**

実環境があれば、ルート `CLAUDE.md` が Layer 2 として読み込まれることを確認する。公式ドキュメント記載済みのため、実行できない場合はスキップしてよい（spec の検証項目に明記）。

- [ ] **Step 4: ADR-0023 を Accepted に昇格**

`docs/decisions/0023-unify-layer2-into-claude-md.md` の `Status` を `Proposed` から `Accepted` に変更する。

`docs/decisions/README.md` の 0023 行のステータスを `Proposed` → `Accepted` に変更する。

- [ ] **Step 5: Commit**

```powershell
git add docs/decisions/0023-unify-layer2-into-claude-md.md docs/decisions/README.md
git commit -m "adr: promote ADR-0023 to Accepted`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Self-Review メモ

- **Spec coverage**: spec の対象7項目（Layer 2 移設 / 中立化 / template.manifest / README / CONTRIBUTING / スキル / plugin.json / sync 確認）はそれぞれ Task 1〜8 に対応。
- **検証**: 各タスクに `Select-String` ベースの確認を配置。Task 8 で生きたファイル全体の残留参照ゼロを最終確認。
- **歴史的記録の除外**: Task 8 の網羅チェックは `docs/decisions|specs|plans|retrospectives|handoff` と `conversation_log.md` を除外（書き換えない方針）。
