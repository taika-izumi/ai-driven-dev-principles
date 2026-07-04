# 選択肢＋推奨提示規範 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AIがユーザーに質問・意思決定を求めるとき選択肢と推奨を提示する規範を、Layer 1 原則4 とLayer 2 CLAUDE.md に追加する。

**Architecture:** ツール非依存の行動規範。Layer 1 に抽象的な一文、Layer 2 に具体的なサブセクションを置き、抽象→具体の勾配を保つ。既存スキルは改修しない。

**Tech Stack:** Markdown ガイドライン、PowerShell テンプレート同期スクリプト（`scripts/sync-template.ps1`）。

---

### Task 1: Layer 1 原則4 に一文追加

**Files:**
- Modify: `docs/principles.md`（原則4 の箇条書き）

- [ ] **Step 1: 原則4 に一文を追加**

`docs/principles.md` の原則4「重要局面での人間の関与」の箇条書きで、次の行:

```
- 設計上の重要な分岐点（アプローチの選択など）でも人間の判断を仰ぐ
```

の直後に、次の一行を挿入する:

```
- 人間の判断を仰ぐ際は、可能な限り選択肢を提示し、推奨する選択肢とその理由を明示する
```

ツール名（ask_user 等）は含めないこと（Layer 1 はツール非依存）。

- [ ] **Step 2: 検証**

Run: `Select-String -Path docs/principles.md -Pattern "推奨する選択肢とその理由を明示"`
Expected: 1行ヒットする。原則4 の箇条書き内にあること。

- [ ] **Step 3: Commit**

```bash
git add docs/principles.md
git commit -m "docs: 原則4 に選択肢と推奨の提示を追加

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: Layer 2 CLAUDE.md にサブセクション追加

**Files:**
- Modify: `CLAUDE.md`（「不可逆操作」と「検証」の間）

- [ ] **Step 1: 新サブセクションを挿入**

`CLAUDE.md` の「### 不可逆操作」セクションの末尾（「- 実行不能な状況に陥った場合、無理に続行せず状況を報告すること」の行の直後）と「### 検証」の間に、次のサブセクションを挿入する:

```
### ユーザーへの質問と意思決定要求

- ユーザーに質問する、または意思決定を求めるときは、原則として選択肢を提示し、推奨する選択肢を「（推奨）」として先頭に置き、推奨理由を一言添えること
- 構造化された質問ツール（GitHub Copilot CLI の ask_user、Claude Code の AskUserQuestion 等）が利用できる場合はそれを使い、無ければテキストで選択肢を列挙すること
- 本質的に自由記述が必要な質問（目的・背景の説明を求める等、選択肢を自然に列挙できないもの）に限り、例外として自由記述を許すこと
```

- [ ] **Step 2: 検証**

Run: `Select-String -Path CLAUDE.md -Pattern "ユーザーへの質問と意思決定要求"`
Expected: 1行ヒット。サブセクションが「不可逆操作」と「検証」の間にあること。

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md に質問・意思決定時の選択肢提示規範を追加

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: テンプレート同期

**Files:**
- Modify: `template/CLAUDE.md`, `template/docs/principles.md`（スクリプトが生成）

- [ ] **Step 1: 同期スクリプトを実行**

Run: `pwsh scripts/sync-template.ps1`
Expected: エラーなく完了。`template/CLAUDE.md` と `template/docs/principles.md` が更新される。

- [ ] **Step 2: ルートとテンプレートの一致を検証**

Run: `Compare-Object (Get-Content CLAUDE.md) (Get-Content template/CLAUDE.md)`
Expected: 差分なし（出力なし）。

Run: `Compare-Object (Get-Content docs/principles.md) (Get-Content template/docs/principles.md)`
Expected: 差分なし（出力なし）。

- [ ] **Step 3: 冪等性確認（再実行で差分が出ないこと）**

Run: `pwsh scripts/sync-template.ps1; git status --short template/`
Expected: 2回目実行後、`git status` に未ステージのtemplate変更が新たに出ないこと（1回目の変更のみ）。

- [ ] **Step 4: Commit**

```bash
git add template/
git commit -m "chore: テンプレートへ選択肢提示規範を同期

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: 最終検証と ADR-0024 昇格

**Files:**
- Modify: `docs/decisions/0024-choice-with-recommendation-norm.md`, `docs/decisions/README.md`

- [ ] **Step 1: 生きたファイルの整合確認**

Run: `Select-String -Path docs/principles.md,CLAUDE.md,template/docs/principles.md,template/CLAUDE.md -Pattern "選択肢"`
Expected: 原則4・CLAUDE.mdサブセクション・各templateに規範が一貫して存在し、矛盾や重複がないこと。

- [ ] **Step 2: ADR-0024 を Accepted へ昇格**

`docs/decisions/0024-choice-with-recommendation-norm.md` の `- **Status**: Proposed` を `- **Status**: Accepted` に変更する。
`docs/decisions/README.md` の 0024 行のステータスを `Proposed` → `Accepted` に変更する。

- [ ] **Step 3: Commit**

```bash
git add docs/decisions/0024-choice-with-recommendation-norm.md docs/decisions/README.md
git commit -m "adr: 0024 を Accepted へ昇格

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
