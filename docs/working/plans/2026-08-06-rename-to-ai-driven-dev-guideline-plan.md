# 体系呼称の改名（メタ・ガイドライン → AI駆動開発ガイドライン）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 本リポジトリが整備する体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改め、現行の規範文書・仕様書・プラグインメタデータから旧名称を一掃する。

**Architecture:** ADR-0078（Proposed）の決定に従う。書き換え対象は「生きた文書」（README / CLAUDE.md / CONTRIBUTING / Layer 1 原則集 / スキル本文 / `docs/current/specs/` / プラグインメタデータ）に限定し、追記型の記録（ADR / retrospective / 完了済み plan / 過去 handoff / issue）は ADR-0011 に従って書き換えない。`template/` 配下は `scripts/sync-template.ps1` の生成物なので直接編集せず、同期スクリプトの実行で反映する。

**Tech Stack:** Markdown / JSON / PowerShell（`scripts/sync-template.ps1`）。ビルドもテストランナーも存在しないドキュメント改修のため、各タスクの検証は grep による出現数の確認で行う。

---

## 前提となる実測値（2026-08-06 時点）

リポジトリ全体の「メタ・ガイドライン」出現は **103 箇所・49 ファイル**（本計画ファイル自身を除く）。内訳:

| 区分 | 箇所数 | 扱い |
|------|--------|------|
| 書き換える（生きた文書） | 37 | 本計画の Task 1〜7 で置換 |
| 書き換えない（追記型の記録。ADR-0011） | 66 | 手を触れない |

英語表記は `Meta-Guidelines` / `meta-guidelines`（ハイフン付き）のみで、スペース区切り・連結表記は存在しない。日本語の表記揺れ（中点なし `メタガイドライン`、半角中黒 `メタ･`、スペース区切りなど）は実測 0 件。

**書き換え後に旧名称が残ってよい場所**: `docs/records/decisions/` / `docs/records/retrospectives/` / `docs/working/plans/` / `docs/working/handoff/` / `docs/working/issues/`。

**単純置換ではなく文言調整が要る箇所（8 件）**: 置換すると語が重複したり不自然になるため、Task 内で旧新文字列を個別に明記している。

- `.claude-plugin/plugin.json` L3、`.claude-plugin/marketplace.json` L3・L10（「AI駆動開発の」が重複する）
- `README.md` L3、`CONTRIBUTING.md` L3・L10（一行定義を添える／修飾語が重複する）
- `docs/current/specs/2026-04-12-meta-guidelines-design.md` L1・L8、`docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md` L32（修飾語が重複する）

---

## ファイル構成

**編集する（直接）:**

| ファイル | 箇所数 | 内容 |
|----------|--------|------|
| `README.md` | 3（＋英語タイトル 1） | 体系名・一行定義・Layer 1 の説明 |
| `CLAUDE.md` | 1 | 節見出し `## メタ・ガイドライン` と一行定義の追加 |
| `CONTRIBUTING.md` | 5 | 冒頭説明・設計思想・チェックリスト |
| `docs/overview/principles.md` | 2 | 文書タイトル・原則5の記述 |
| `skills/extend-guidelines/SKILL.md` | 1 | スキル概要文 |
| `skills/retrospective/SKILL.md` | 1 | 対応する原則の記述 |
| `.claude-plugin/plugin.json` | 1（＋英語キーワード 1） | プラグイン説明・キーワード |
| `.claude-plugin/marketplace.json` | 2 | マーケットプレイス説明・プラグイン説明 |
| `docs/current/specs/` 配下 10 ファイル | 18 | 仕様書本文（ファイル名は変更しない） |

**編集しない（生成物。Task 8 の同期で反映）:**

- `template/CLAUDE.md`（1 箇所）
- `template/docs/overview/principles.md`（2 箇所）

**編集しない（追記型の記録。ADR-0011）:**

- `docs/records/decisions/` 配下すべて（ADR-0078 自身を含む。Task 9 の Status 昇格のみ行う）
- `docs/records/retrospectives/` 配下すべて
- `docs/working/plans/` 配下すべて（本計画ファイルを含む）
- `docs/working/handoff/` 配下すべて（`master.md` はマージ時に別途更新）
- `docs/working/issues/flow/0013-plan-verification-consistency-check.md`

---

## 作業前の共通注意

- **コミットはパス指定で行う**（Issue-0020）。`docs/inbox/` に untracked ファイルが 3 件、`docs/conversation_log.md` が 1 件あり、ユーザーが手動移動予定のため巻き込んではならない。`git add <ディレクトリ>` を使わず、必ずファイルパスを列挙する
- コミット前に毎回 `git status --short` でステージ内容を確認する
- 複数行のコミットメッセージが必要なときは `git commit -F <絶対パスの一時ファイル>` を使う（Issue-0015）。本計画のコミットはすべて1行メッセージなので `-m` で足りる
- 作業ブランチは `feature/rename-to-ai-driven-dev-guideline`（checkout 済み）

---

### Task 1: README.md の書き換えと一行定義の追加

**Files:**
- Modify: `README.md`（L1, L3, L7, L17）

- [ ] **Step 1: 現状を確認する**

Run:
```powershell
Select-String -Path README.md -Pattern 'メタ・ガイドライン|Meta-Guidelines' -Encoding utf8
```
Expected: 4 行ヒット（L1 英語タイトル / L3 / L7 / L17）

- [ ] **Step 2: 英語タイトルを置換する**

`README.md` L1:

旧:
```markdown
# AI Agent Meta-Guidelines
```
新:
```markdown
# AI-Driven Development Guidelines
```

- [ ] **Step 3: 冒頭の体系名に一行定義を添える**

`README.md` L3。ADR-0078 の「初出箇所には一行定義を添える」に対応する箇所。

旧:
```markdown
AIエージェントを活用したシステム開発のためのメタ・ガイドライン。
```
新:
```markdown
AI駆動開発ガイドライン — AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系。
```

- [ ] **Step 4: 概要文を置換する**

`README.md` L7:

旧:
```markdown
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot CLI / Claude Code で実践するための仕組みを提供する。
```
新:
```markdown
このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（AI駆動開発ガイドライン）と、それを GitHub Copilot CLI / Claude Code で実践するための仕組みを提供する。
```

- [ ] **Step 5: レイヤー表の Layer 1 の説明を置換する**

`README.md` L17:

旧:
```markdown
| Layer 1 | [`docs/overview/principles.md`](docs/overview/principles.md) | ツール非依存のメタ・ガイドライン原則集 |
```
新:
```markdown
| Layer 1 | [`docs/overview/principles.md`](docs/overview/principles.md) | ツール非依存の AI駆動開発ガイドライン原則集 |
```

- [ ] **Step 6: 旧名称が消えたことを確認する**

Run:
```powershell
Select-String -Path README.md -Pattern 'メタ・ガイドライン|Meta-Guidelines' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path README.md -Pattern 'AI駆動開発ガイドライン|AI-Driven Development Guidelines' -Encoding utf8
```
Expected: 4 行ヒット（L1, L3, L7, L17）

- [ ] **Step 7: コミットする**

```powershell
git add README.md
git status --short
git commit -m "docs: rename 体系呼称 to AI駆動開発ガイドライン in README (ADR-0078)"
```

---

### Task 2: CLAUDE.md の節見出し改名と一行定義の追加

**Files:**
- Modify: `CLAUDE.md`（L48-50 付近）

`CLAUDE.md` は `template.manifest` の同期対象なので、Task 8 で `template/CLAUDE.md` へ反映される。ここでは `template/CLAUDE.md` を直接編集しないこと。

- [ ] **Step 1: 現状を確認する**

Run:
```powershell
Select-String -Path CLAUDE.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 1 行ヒット（L48 の節見出し `## メタ・ガイドライン`）

- [ ] **Step 2: 節見出しを改名し、直後に一行定義を挿入する**

`CLAUDE.md` L48-50。ADR-0078 の「初出箇所には一行定義を添える」に対応する箇所。

旧:
```markdown
## メタ・ガイドライン

以下は `docs/overview/principles.md` に定義された5原則に基づく行動指示である。
```
新:
```markdown
## AI駆動開発ガイドライン

AI駆動開発ガイドラインとは、AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系を指す。以下は `docs/overview/principles.md` に定義された5原則に基づく行動指示である。
```

- [ ] **Step 3: 旧名称が消えたことを確認する**

Run:
```powershell
Select-String -Path CLAUDE.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path CLAUDE.md -Pattern '^## AI駆動開発ガイドライン$' -Encoding utf8
```
Expected: 1 行ヒット

- [ ] **Step 4: コミットする**

```powershell
git add CLAUDE.md
git status --short
git commit -m "docs: rename 節見出し to AI駆動開発ガイドライン in CLAUDE.md (ADR-0078)"
```

---

### Task 3: CONTRIBUTING.md の書き換え

**Files:**
- Modify: `CONTRIBUTING.md`（L3, L10, L78, L311, L324）

- [ ] **Step 1: 現状を確認する**

Run:
```powershell
Select-String -Path CONTRIBUTING.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 5 行ヒット（L3, L10, L78, L311, L324）

- [ ] **Step 2: 冒頭説明に一行定義を添えて置換する**

`CONTRIBUTING.md` L3:

旧:
```markdown
このドキュメントは、このリポジトリのメタ・ガイドラインを拡張・変更する際のルールと手順をまとめたものである。
```
新:
```markdown
このドキュメントは、このリポジトリの AI駆動開発ガイドライン（AIエージェントと協働して開発を進めるための、原則・行動指示・スキルの体系）を拡張・変更する際のルールと手順をまとめたものである。
```

- [ ] **Step 3: 設計思想の説明を置換する**

`CONTRIBUTING.md` L10。「AIエージェントを活用したシステム開発のための」は新名称と意味が重複するため落とす。

旧:
```markdown
このリポジトリは、AIエージェントを活用したシステム開発のためのメタ・ガイドラインを3層のレイヤード方式で管理している。
```
新:
```markdown
このリポジトリは、AI駆動開発ガイドラインを3層のレイヤード方式で管理している。
```

- [ ] **Step 4: CLAUDE.md のカテゴリ構成の記述を置換する**

`CONTRIBUTING.md` L78。Task 2 で改名した節見出しへの参照。

旧:
```markdown
- カテゴリ構成（システム設定 / メタ・ガイドライン）を維持する
```
新:
```markdown
- カテゴリ構成（システム設定 / AI駆動開発ガイドライン）を維持する
```

- [ ] **Step 5: 対策先リポジトリの記述を置換する（2 箇所）**

`CONTRIBUTING.md` L311:

旧:
```markdown
1. `docs/working/issues/README.md` の open 課題（または `docs/records/retrospectives/system|flow/` の該当ファイル）から未対策の課題を確認する。開発フロー/ガイドライン課題（`flow/`）の場合、対策はこのメタ・ガイドラインrepo（ai-driven-dev-principles）側で行う
```
新:
```markdown
1. `docs/working/issues/README.md` の open 課題（または `docs/records/retrospectives/system|flow/` の該当ファイル）から未対策の課題を確認する。開発フロー/ガイドライン課題（`flow/`）の場合、対策はこの AI駆動開発ガイドライン repo（ai-driven-dev-principles）側で行う
```

`CONTRIBUTING.md` L324:

旧:
```markdown
- 対策対象がフロー/ガイドライン課題（`flow/`）の場合、対策をメタ・ガイドラインrepo側に向けているか（個別システムrepoの改善として埋もれさせていないか。ADR-0021）
```
新:
```markdown
- 対策対象がフロー/ガイドライン課題（`flow/`）の場合、対策を AI駆動開発ガイドライン repo 側に向けているか（個別システムrepoの改善として埋もれさせていないか。ADR-0021）
```

- [ ] **Step 6: 旧名称が消えたことを確認する**

Run:
```powershell
Select-String -Path CONTRIBUTING.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path CONTRIBUTING.md -Pattern 'AI駆動開発ガイドライン' -Encoding utf8
```
Expected: 5 行ヒット

- [ ] **Step 7: コミットする**

```powershell
git add CONTRIBUTING.md
git status --short
git commit -m "docs: rename 体系呼称 to AI駆動開発ガイドライン in CONTRIBUTING (ADR-0078)"
```

---

### Task 4: Layer 1 原則集とスキル本文の書き換え

**Files:**
- Modify: `docs/overview/principles.md`（L1, L59）
- Modify: `skills/extend-guidelines/SKILL.md`（L8）
- Modify: `skills/retrospective/SKILL.md`（L128）

`docs/overview/principles.md` は `template.manifest` の同期対象なので、Task 8 で `template/docs/overview/principles.md` へ反映される。`template/` 配下を直接編集しないこと。

- [ ] **Step 1: 現状を確認する**

Run:
```powershell
Select-String -Path docs/overview/principles.md,skills/extend-guidelines/SKILL.md,skills/retrospective/SKILL.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 4 行ヒット（principles.md L1・L59 / extend-guidelines L8 / retrospective L128）

- [ ] **Step 2: 原則集のタイトルを置換する**

`docs/overview/principles.md` L1:

旧:
```markdown
# メタ・ガイドライン原則集
```
新:
```markdown
# AI駆動開発ガイドライン原則集
```

- [ ] **Step 3: 原則5の記述を置換する**

`docs/overview/principles.md` L59:

旧:
```markdown
- ステップ単位の検証だけでなく、サブプロジェクト1サイクル完了時には振り返りを実施し、フロー・ガイドライン自体の検証結果をメタ・ガイドラインへ反映する（`retrospective` スキル）
```
新:
```markdown
- ステップ単位の検証だけでなく、サブプロジェクト1サイクル完了時には振り返りを実施し、フロー・ガイドライン自体の検証結果を AI駆動開発ガイドラインへ反映する（`retrospective` スキル）
```

- [ ] **Step 4: extend-guidelines スキルの概要文を置換する**

`skills/extend-guidelines/SKILL.md` L8:

旧:
```markdown
メタ・ガイドラインの拡張作業を自動的にガイドするゲートウェイスキル。
```
新:
```markdown
AI駆動開発ガイドラインの拡張作業を自動的にガイドするゲートウェイスキル。
```

- [ ] **Step 5: retrospective スキルの原則5の記述を置換する**

`skills/retrospective/SKILL.md` L128:

旧:
```markdown
- **原則5（漸進的検証）**: サイクル単位の課題抽出でメタ・ガイドライン自体の検証ループを回す
```
新:
```markdown
- **原則5（漸進的検証）**: サイクル単位の課題抽出で AI駆動開発ガイドライン自体の検証ループを回す
```

- [ ] **Step 6: 旧名称が消えたことを確認する**

Run:
```powershell
Select-String -Path docs/overview/principles.md,skills/extend-guidelines/SKILL.md,skills/retrospective/SKILL.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path docs/overview/principles.md,skills/extend-guidelines/SKILL.md,skills/retrospective/SKILL.md -Pattern 'AI駆動開発ガイドライン' -Encoding utf8
```
Expected: 4 行ヒット

- [ ] **Step 7: コミットする**

```powershell
git add docs/overview/principles.md skills/extend-guidelines/SKILL.md skills/retrospective/SKILL.md
git status --short
git commit -m "docs: rename 体系呼称 to AI駆動開発ガイドライン in principles/skills (ADR-0078)"
```

---

### Task 5: プラグインメタデータの書き換え

**Files:**
- Modify: `.claude-plugin/plugin.json`（L3, L14）
- Modify: `.claude-plugin/marketplace.json`（L3, L10）

3 箇所とも「AI駆動開発**の**メタ・ガイドライン」という形なので、素朴に置換すると「AI駆動開発のAI駆動開発ガイドライン」になる。下記の新文字列どおりに書き換えること。

- [ ] **Step 1: 現状を確認する**

Run:
```powershell
Select-String -Path .claude-plugin/plugin.json,.claude-plugin/marketplace.json -Pattern 'メタ・ガイドライン|meta-guidelines' -Encoding utf8
```
Expected: 4 行ヒット（plugin.json L3・L14 / marketplace.json L3・L10）

- [ ] **Step 2: plugin.json の説明文を置換する**

`.claude-plugin/plugin.json` L3:

旧:
```json
  "description": "AI駆動開発のメタ・ガイドラインを実装するスキル群（start-work, decision-log, session-handoff, feature-block-design, retrospective ほか）。本リポジトリの CLAUDE.md と組み合わせて使用する。",
```
新:
```json
  "description": "AI駆動開発ガイドラインを実装するスキル群（start-work, decision-log, session-handoff, feature-block-design, retrospective ほか）。本リポジトリの CLAUDE.md と組み合わせて使用する。",
```

- [ ] **Step 3: plugin.json のキーワードを置換する**

`.claude-plugin/plugin.json` L14:

旧:
```json
    "meta-guidelines",
```
新:
```json
    "ai-driven-dev-guidelines",
```

- [ ] **Step 4: marketplace.json のマーケットプレイス説明を置換する**

`.claude-plugin/marketplace.json` L3:

旧:
```json
  "description": "AI駆動開発のメタ・ガイドライン スキル群を配信するマーケットプレイス（単一プラグイン）",
```
新:
```json
  "description": "AI駆動開発ガイドラインのスキル群を配信するマーケットプレイス（単一プラグイン）",
```

- [ ] **Step 5: marketplace.json のプラグイン説明を置換する**

`.claude-plugin/marketplace.json` L10:

旧:
```json
      "description": "AI駆動開発のメタ・ガイドラインを実装するスキル群",
```
新:
```json
      "description": "AI駆動開発ガイドラインを実装するスキル群",
```

- [ ] **Step 6: JSON として妥当であることを確認する**

Run:
```powershell
Get-Content .claude-plugin/plugin.json -Raw | ConvertFrom-Json | Out-Null; Get-Content .claude-plugin/marketplace.json -Raw | ConvertFrom-Json | Out-Null; "JSON OK"
```
Expected: `JSON OK`（パースエラーが出ないこと）

- [ ] **Step 7: 旧名称が消えたこと、重複表現がないことを確認する**

Run:
```powershell
Select-String -Path .claude-plugin/plugin.json,.claude-plugin/marketplace.json -Pattern 'メタ・ガイドライン|meta-guidelines' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path .claude-plugin/plugin.json,.claude-plugin/marketplace.json -Pattern 'AI駆動開発のAI駆動開発' -Encoding utf8
```
Expected: 出力なし（0 行。重複表現の混入検知）

- [ ] **Step 8: コミットする**

```powershell
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git status --short
git commit -m "chore: rename 体系呼称 to AI駆動開発ガイドライン in plugin metadata (ADR-0078)"
```

---

### Task 6: 仕様書の書き換え（文言調整が要る 3 箇所）

**Files:**
- Modify: `docs/current/specs/2026-04-12-meta-guidelines-design.md`（L1, L8）
- Modify: `docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md`（L32）

ファイル名は変更しない（ADR 等からの参照を壊さないため。ADR-0078 の Consequences に明記）。

- [ ] **Step 1: 設計仕様書のタイトルを置換する**

`docs/current/specs/2026-04-12-meta-guidelines-design.md` L1。「AIエージェント活用システム開発のための」は新名称と意味が重複するため落とす。

旧:
```markdown
# 設計仕様書: AIエージェント活用システム開発のためのメタ・ガイドライン
```
新:
```markdown
# 設計仕様書: AI駆動開発ガイドライン
```

- [ ] **Step 2: 同ファイルの概要文を置換する**

`docs/current/specs/2026-04-12-meta-guidelines-design.md` L8。「AIエージェントを活用した」は新名称と重複するため落とす。

旧:
```markdown
AIエージェントを活用したシステム開発全般に適用できるメタ・ガイドライン（普遍的原則）を策定し、それを GitHub Copilot の `copilot-instructions.md` および Skills として実践するためのプロジェクト。
```
新:
```markdown
システム開発全般に適用できる AI駆動開発ガイドライン（普遍的原則）を策定し、それを GitHub Copilot の `copilot-instructions.md` および Skills として実践するためのプロジェクト。
```

- [ ] **Step 3: CONTRIBUTING 設計仕様書のリポジトリ目的を置換する**

`docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md` L32。「AIエージェント開発の」は新名称と重複するため落とす。

旧:
```markdown
- リポジトリの目的：AIエージェント開発のメタ・ガイドラインを管理
```
新:
```markdown
- リポジトリの目的：AI駆動開発ガイドラインを管理
```

- [ ] **Step 4: この 3 箇所が置換されたことを確認する**

Run:
```powershell
Select-String -Path docs/current/specs/2026-04-12-meta-guidelines-design.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 4 行ヒット（L38, L53, L66, L127。これらは Task 7 で置換する）

Run:
```powershell
Select-String -Path docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 1 行ヒット（L75。これは Task 7 で置換する）

- [ ] **Step 5: コミットしない**

Task 7 と同じ commit にまとめるため、ここではコミットしない。Task 7 の最終ステップでまとめてコミットする。

---

### Task 7: 仕様書の書き換え（単純置換 15 箇所）

**Files:**
- Modify: `docs/current/specs/2026-04-12-meta-guidelines-design.md`（L38, L53, L66, L127）
- Modify: `docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md`（L75）
- Modify: `docs/current/specs/2026-05-01-feature-block-design/00-overview.md`（L32）
- Modify: `docs/current/specs/2026-05-01-feature-block-design/03-instructions-update.md`（L13, L15, L24）
- Modify: `docs/current/specs/2026-05-01-retrospective-design.md`（L160）
- Modify: `docs/current/specs/2026-06-15-naming-clarity-discipline-design.md`（L39）
- Modify: `docs/current/specs/2026-06-16-choice-with-recommendation-design.md`（L42）
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md`（L82）
- Modify: `docs/current/specs/2026-07-04-project-folder-structure/04-layer-docs-updates.md`（L55）
- Modify: `docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md`（L19）

> **順序依存: Task 6 を必ず先に完了させること。** `2026-04-12-meta-guidelines-design.md` と `2026-04-13-contributing-and-gateway-skill-design.md` には修飾語の重複が起きる箇所（前者 L1・L8、後者 L32）が含まれており、Task 6 でそれらを処理して初めて残りが単純置換になる。Task 6 未完了のまま本タスクで `replace_all` すると、「AIエージェント活用システム開発のための AI駆動開発ガイドライン」のような重複表現が生じる。

いずれも文字列「メタ・ガイドライン」を「AI駆動開発ガイドライン」へ置き換えるだけでよい（前後の語との重複が起きない箇所）。各ファイルで `replace_all` を使ってよい。置換後の各行は以下のとおり:

- [ ] **Step 1: `2026-04-12-meta-guidelines-design.md` の残り 4 箇所を置換する**

L38:
```markdown
| Layer 1 | `docs/principles.md` | 人間 | ツール非依存の AI駆動開発ガイドライン原則集。判断の拠り所、「なぜ」の記録 |
```
L53（コードブロック内のディレクトリツリー）:
```
│   ├── principles.md              # Layer 1: AI駆動開発ガイドライン原則集
```
L66:
```markdown
## Layer 1: AI駆動開発ガイドライン原則集
```
L127:
```markdown
**カテゴリ2: AI駆動開発ガイドライン** — 5原則に1対1で対応する行動指示
```

- [ ] **Step 2: `2026-04-13-contributing-and-gateway-skill-design.md` L75 を置換する**

```markdown
- カテゴリ構成（システム設定 / AI駆動開発ガイドライン）を維持
```

- [ ] **Step 3: `2026-05-01-feature-block-design/00-overview.md` L32 を置換する**

```markdown
AIエージェントが、ソフトウェア工学の知見（高凝集・疎結合、単一責任など）を**確実に・機械的に・繰り返し**適用してシステムを設計・開発できる仕組みを、本リポジトリの AI駆動開発ガイドライン側に組み込む。
```

- [ ] **Step 4: `2026-05-01-feature-block-design/03-instructions-update.md` の 3 箇所を置換する**

L13:
```markdown
### 1. AI駆動開発ガイドライン側「タスク構造」セクションへの追記
```
L15（Task 2 で改名した CLAUDE.md の節見出しへの参照）:
```markdown
現状の `## AI駆動開発ガイドライン` 内 `### タスク構造` の末尾に、以下を追加する:
```
L24（同上）:
```markdown
`## AI駆動開発ガイドライン` 配下に新セクション `### ドキュメント運用` を新設し、以下を記載する:
```

- [ ] **Step 5: `2026-05-01-retrospective-design.md` L160 を置換する**

```markdown
- **原則5（漸進的検証）**: サイクル単位の課題抽出で AI駆動開発ガイドライン自体の検証ループを回す
```

- [ ] **Step 6: `2026-06-15-naming-clarity-discipline-design.md` L39 を置換する**

```markdown
`.github/copilot-instructions.md` の「AI駆動開発ガイドライン > コンテキスト管理」セクションに、以下2点の行動規範を追加する:
```

- [ ] **Step 7: `2026-06-16-choice-with-recommendation-design.md` L42 を置換する**

```markdown
「AI駆動開発ガイドライン」配下、原則4由来の「不可逆操作」セクションの隣に、新サブセクション「ユーザーへの質問と意思決定要求」を追加する:
```

- [ ] **Step 8: `2026-07-04-project-folder-structure/01-folder-structure-definition.md` L82 を置換する**

```markdown
- template 対象（他プロジェクトへ配布される）なので、本リポジトリ固有の事情（AI駆動開発ガイドライン開発の文脈）を書かない
```

- [ ] **Step 9: `2026-07-04-project-folder-structure/04-layer-docs-updates.md` L55 を置換する**

```markdown
- CLAUDE.md のカテゴリ構成（システム設定 / AI駆動開発ガイドライン）と日本語統一を維持
```

- [ ] **Step 10: `2026-07-17-worklog-skill-pipeline/00-overview.md` L19 を置換する**

```markdown
AI駆動開発ガイドライン運用で得られる「スキル化・ルール化する価値のある作業ノウハウ」を、複数プロジェクト横断で捕捉・抽出・スキル化する仕組みが存在しなかった。既存の retrospective はサイクル終端の課題抽出用であり、頻発・重要な作業手順やルールの継続的抽出には使えていない。
```

- [ ] **Step 11: 仕様書全体から旧名称が消えたことを確認する**

Run:
```powershell
Get-ChildItem -Path docs/current/specs -Recurse -File | Select-String -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
(Get-ChildItem -Path docs/current/specs -Recurse -File | Select-String -Pattern 'AI駆動開発ガイドライン' -Encoding utf8 | Measure-Object).Count
```
Expected: `18`（Task 6 の 3 箇所 + Task 7 の 15 箇所）

- [ ] **Step 12: Task 6 とまとめてコミットする**

```powershell
git add docs/current/specs/2026-04-12-meta-guidelines-design.md `
        docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md `
        docs/current/specs/2026-05-01-feature-block-design/00-overview.md `
        docs/current/specs/2026-05-01-feature-block-design/03-instructions-update.md `
        docs/current/specs/2026-05-01-retrospective-design.md `
        docs/current/specs/2026-06-15-naming-clarity-discipline-design.md `
        docs/current/specs/2026-06-16-choice-with-recommendation-design.md `
        docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md `
        docs/current/specs/2026-07-04-project-folder-structure/04-layer-docs-updates.md `
        docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md
git status --short
git commit -m "docs: rename 体系呼称 to AI駆動開発ガイドライン in specs (ADR-0078)"
```

`git status --short` の出力で、ステージ済み（左列が `M`）のファイルが上記 10 件だけであること、`docs/inbox/` や `docs/conversation_log.md` が含まれていないことを確認すること。

---

### Task 8: template/ への同期

**Files:**
- Modify（生成）: `template/CLAUDE.md`
- Modify（生成）: `template/docs/overview/principles.md`

`template.manifest` の対象は `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` の 4 件。このうち Task 2・Task 4 で前 2 件を変更したため同期が必要。

- [ ] **Step 1: 同期前に template 側の旧名称を確認する**

Run:
```powershell
Get-ChildItem -Path template -Recurse -File | Select-String -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 3 行ヒット（`template/CLAUDE.md` L48 / `template/docs/overview/principles.md` L1・L59）

- [ ] **Step 2: 同期スクリプトを実行する**

Run:
```powershell
pwsh scripts/sync-template.ps1
```
Expected: `[sync-template] Done. 7 files synced to template/` が出力される（manifest 4 件 + 空インデックス 3 件）。末尾で `check-claude-md-size.ps1` による CLAUDE.md 規模計測が走るが、警告が出ても同期はブロックされない（ADR-0040）

- [ ] **Step 3: 同期結果を実体の読み直しで確認する**

Run:
```powershell
Get-ChildItem -Path template -Recurse -File | Select-String -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

Run:
```powershell
Select-String -Path template/CLAUDE.md,template/docs/overview/principles.md -Pattern 'AI駆動開発ガイドライン' -Encoding utf8
```
Expected: 4 行ヒット（`template/CLAUDE.md` の節見出しと一行定義で 2 行、`template/docs/overview/principles.md` で 2 行）

- [ ] **Step 4: ソースと生成物が一致していることを確認する**

Run:
```powershell
if ((Get-FileHash CLAUDE.md).Hash -eq (Get-FileHash template/CLAUDE.md).Hash) { "CLAUDE.md OK" } else { "CLAUDE.md MISMATCH" }
if ((Get-FileHash docs/overview/principles.md).Hash -eq (Get-FileHash template/docs/overview/principles.md).Hash) { "principles.md OK" } else { "principles.md MISMATCH" }
```
Expected: `CLAUDE.md OK` と `principles.md OK`

- [ ] **Step 5: コミットする**

```powershell
git add template
git status --short
git commit -m "chore: sync template after 体系呼称 rename (ADR-0078)"
```

`template/` 配下に untracked の想定外ファイルが無いことを `git status --short` で確認すること。同期スクリプトは `template/` を一度削除して作り直すため、差分が manifest 対象 2 ファイルのみであることを確認する。

---

### Task 9: 全体検証と ADR-0078 の Accepted 昇格

**Files:**
- Modify: `docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md`（Status 行）
- Modify: `docs/records/decisions/README.md`（L86 の Status セル）

- [ ] **Step 1: 書き換え対象スコープに旧名称が残っていないことを確認する**

Run:
```powershell
Get-ChildItem -Path README.md,CLAUDE.md,CONTRIBUTING.md,docs/overview,docs/current/specs,skills,template,.claude-plugin -Recurse -File | Select-String -Pattern 'メタ・ガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

- [ ] **Step 2: 英語表記の旧名称も残っていないことを確認する**

Run:
```powershell
Get-ChildItem -Path README.md,CLAUDE.md,CONTRIBUTING.md,docs/overview,docs/current/specs,skills,template,.claude-plugin -Recurse -File | Select-String -Pattern 'meta-guidelines' -Encoding utf8
```
Expected: 出力なし（0 行）

- [ ] **Step 3: 置換ミスによる重複表現が無いことを確認する**

Run:
```powershell
Get-ChildItem -Path README.md,CLAUDE.md,CONTRIBUTING.md,docs/overview,docs/current/specs,skills,template,.claude-plugin -Recurse -File | Select-String -Pattern 'AI駆動開発のAI駆動開発|AI駆動開発ガイドラインガイドライン' -Encoding utf8
```
Expected: 出力なし（0 行）

- [ ] **Step 4: 書き換えない対象に触れていないことを確認する**

出現数の比較ではなく、変更されたファイルの一覧そのものを突合する（追記型の記録を1ファイルも触っていないことを直接示せるため）。

Run:
```powershell
git diff --name-only master...HEAD | Sort-Object
```
Expected: 以下の 24 ファイルのみ（集合として一致すればよく、`Sort-Object` の出力順とは一致しなくてよい）。うち末尾 4 件は本タスク以前のコミット由来（ADR-0078 と handoff は `8967b55`、本計画ファイルと ADR-0078 への範囲追記は writing-plans 完了時のコミット）:

```
.claude-plugin/marketplace.json
.claude-plugin/plugin.json
CLAUDE.md
CONTRIBUTING.md
README.md
docs/current/specs/2026-04-12-meta-guidelines-design.md
docs/current/specs/2026-04-13-contributing-and-gateway-skill-design.md
docs/current/specs/2026-05-01-feature-block-design/00-overview.md
docs/current/specs/2026-05-01-feature-block-design/03-instructions-update.md
docs/current/specs/2026-05-01-retrospective-design.md
docs/current/specs/2026-06-15-naming-clarity-discipline-design.md
docs/current/specs/2026-06-16-choice-with-recommendation-design.md
docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md
docs/current/specs/2026-07-04-project-folder-structure/04-layer-docs-updates.md
docs/current/specs/2026-07-17-worklog-skill-pipeline/00-overview.md
docs/overview/principles.md
skills/extend-guidelines/SKILL.md
skills/retrospective/SKILL.md
template/CLAUDE.md
template/docs/overview/principles.md
docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md
docs/records/decisions/README.md
docs/working/handoff/feature_rename-to-ai-driven-dev-guideline.md
docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md
```

`docs/records/retrospectives/` / `docs/working/issues/` 配下のファイルや、`docs/records/decisions/` の 0078 以外の ADR がこの一覧に現れた場合は、追記型の記録（ADR-0011）を誤って書き換えている。その場合は当該変更を戻すこと。

なお本 Step の時点では Step 5 の Status 変更がまだ未コミットのため、`0078-...md` と `decisions/README.md` は「範囲追記のみが入った状態」で一覧に現れる。ファイル集合は Step 7 のコミット前後で変わらない。

- [ ] **Step 5: ADR-0078 を Accepted へ昇格する**

昇格前に粒度を点検する（ADR-0059 / ADR-0060）。ADR-0078 のタイトル「体系の呼称を『メタ・ガイドライン』から『AI駆動開発ガイドライン』へ改める」が本文の全決定（名称の選定、一行定義の付与、書き換え範囲の確定）に答えているかを突合し、答えていない決定があれば分割を提案してから昇格する。

`docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md` L3:

旧:
```markdown
- **Status**: Proposed
```
新:
```markdown
- **Status**: Accepted
```

`docs/records/decisions/README.md` L86:

旧:
```markdown
| [0078](0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md) | 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める | Proposed | 2026-08-06 |
```
新:
```markdown
| [0078](0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md) | 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める | Accepted | 2026-08-06 |
```

- [ ] **Step 6: 昇格結果を実体の読み直しで確認する**

Run:
```powershell
Select-String -Path docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md -Pattern '^- \*\*Status\*\*:' -Encoding utf8
Select-String -Path docs/records/decisions/README.md -Pattern '\| \[0078\]' -Encoding utf8
```
Expected: 両方とも `Accepted` を含む行が返る

- [ ] **Step 7: コミットする**

```powershell
git add docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md docs/records/decisions/README.md
git status --short
git commit -m "adr: 0078 - Accepted へ昇格（体系呼称の改名が完了）"
```

本計画ファイルは writing-plans 完了時に既にコミット済みなので、ここでは add しない。

---

## 完了後の作業（本計画のスコープ外・start-work の Post ラッパーで処理）

1. `session-handoff` の update（Post ラッパー消化記録への1行追記を含む）
2. `worklog-record`（記録ゲートの自己判定）
3. `superpowers:finishing-a-development-branch` で master へのマージを実施
4. マージ時に `docs/working/handoff/master.md` L10 の背景説明にある旧名称 1 箇所を新名称へ更新する（master 側の生きた文書のため）
5. マージ直後に `retrospective` スキルを起動する（CLAUDE.md の規定）
6. プラグイン説明文（`plugin.json` / `marketplace.json`）を変更したため、反映には `/plugin marketplace update ai-driven-dev-principles` の実行がユーザー側で必要になる可能性がある（ADR-0055）
