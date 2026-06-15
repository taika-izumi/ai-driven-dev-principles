# AIの言葉遣いの明確性規範 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AI が対話・成果物ドキュメントで使う用語を説明的にする行動規範を `copilot-instructions.md` に追加する。

**Architecture:** Layer 2（`.github/copilot-instructions.md`）の「コンテキスト管理」セクションに行動規範を2点追加し、`scripts/sync-template.ps1` で `template/` へ同期する。原則本体（Layer 1）と Skill は変更しない。

**Tech Stack:** Markdown、PowerShell（同期スクリプト）、Git

**関連ドキュメント:** Spec `docs/specs/2026-06-15-naming-clarity-discipline-design.md` / ADR-0022

---

### Task 1: copilot-instructions.md に行動規範を追加

**Files:**
- Modify: `.github/copilot-instructions.md`（「### コンテキスト管理」セクション）

- [ ] **Step 1: 規範2点を追記する**

`.github/copilot-instructions.md` の「### コンテキスト管理」セクションを、現状:

```markdown
### コンテキスト管理

- タスク開始時に、必要な前提情報（関連ファイル、仕様、制約）を確認すること
- 外部情報（Web検索等）を使用する場合、ソースの信頼性を明示すること
```

から以下に書き換える:

```markdown
### コンテキスト管理

- タスク開始時に、必要な前提情報（関連ファイル、仕様、制約）を確認すること
- 外部情報（Web検索等）を使用する場合、ソースの信頼性を明示すること
- 対話・成果物ドキュメント（ハンドオフ/仕様書/ADR等）で用語を使うときは、文章だけを読んで意味が推測できる説明的な表現を用いること。「Aモード」「Primary/Secondary」のような、その場限りで定義のない略号・記号的呼称は使わないこと
- 初出のプロジェクト固有用語には簡潔な説明を添えること
```

- [ ] **Step 2: 変更を目視確認する**

Run: `git --no-pager diff .github/copilot-instructions.md`
Expected: 「コンテキスト管理」セクションに2行追加されている。既存2行は維持。他セクションに変更なし。

---

### Task 2: テンプレートへ同期する

**Files:**
- Modify: `template/.github/copilot-instructions.md`（スクリプトが自動生成）

- [ ] **Step 1: 同期スクリプトを実行する**

Run: `pwsh scripts/sync-template.ps1`
Expected: 各ファイルに `✓` が出力され、`[sync-template] Done. 4 files synced to template/` で終了する。

- [ ] **Step 2: テンプレート側に規範が反映されたか確認する**

Run: `git --no-pager diff template/.github/copilot-instructions.md`
Expected: `.github/copilot-instructions.md` と同じ2行が「コンテキスト管理」セクションに追加されている。

- [ ] **Step 3: 意図しない差分が無いか確認する**

Run: `git status --short`
Expected: 変更は `.github/copilot-instructions.md` と `template/.github/copilot-instructions.md` の2ファイルのみ（`docs/decisions/README.md` の空版同期で template 側 ADR インデックスに差分が出る場合は、本サイクルで ADR-0022 を追加済みのため許容。差分内容を確認すること）。

---

### Task 3: ADR-0022 を Accepted へ昇格しコミット

**Files:**
- Modify: `docs/decisions/0022-naming-clarity-discipline.md`
- Modify: `docs/decisions/README.md`

- [ ] **Step 1: ADR-0022 の Status を Accepted に更新する**

`docs/decisions/0022-naming-clarity-discipline.md` の `- **Status**: Proposed` を `- **Status**: Accepted` に変更する。

- [ ] **Step 2: ADR インデックスの Status を更新する**

`docs/decisions/README.md` の 0022 行のステータスを `Proposed` から `Accepted` に変更する。

- [ ] **Step 3: テンプレートを再同期する（ADRインデックス空版の更新）**

Run: `pwsh scripts/sync-template.ps1`
Expected: 正常終了。`template/docs/decisions/README.md` の空版が最新ヘッダーで再生成される。

- [ ] **Step 4: 変更をコミットする**

```bash
git add .github/copilot-instructions.md template/ docs/decisions/0022-naming-clarity-discipline.md docs/decisions/README.md
git commit -m "feat: add naming clarity discipline to copilot-instructions (ADR-0022 Accepted)"
```

- [ ] **Step 5: コミット内容を確認する**

Run: `git --no-pager show --stat HEAD`
Expected: 上記4ファイル（＋template配下）が含まれる。

---

## スコープ外（本計画で扱わない）

- 問題A（プロジェクト固有用語集の仕組み）の設計・実装。別サイクル。
- `docs/principles.md` の変更。
- 新規 Skill の作成。
