# メタ・ガイドライン実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AIエージェント活用システム開発のためのメタ・ガイドライン（5原則 + copilot-instructions.md + 2スキル）を構築する

**Architecture:** 3層レイヤード方式 — Layer 1: principles.md（人間向け原則集）→ Layer 2: copilot-instructions.md（エージェント向け行動指示）→ Layer 3: skills/（ワークフロー実装）。各レイヤーは独立して編集・拡張可能。

**Tech Stack:** Markdown, GitHub Copilot Skills (SKILL.md format with YAML frontmatter)

**Spec:** `docs/specs/2026-04-12-meta-guidelines-design.md`

---

## ファイル構成

| 操作 | パス | 責務 |
|------|------|------|
| Create | `docs/principles.md` | Layer 1: 5原則 + 前文（メタ・ガイドライン原則集） |
| Create | `docs/decisions/README.md` | ADRインデックス（テーブル形式の一覧） |
| Modify | `.github/copilot-instructions.md` | Layer 2: カテゴリ分類（システム設定 + メタ・ガイドライン）に再構成 |
| Create | `skills/decision-log/SKILL.md` | Layer 3: ADR作成・更新・インデックス管理スキル |
| Create | `skills/pre-action-review/SKILL.md` | Layer 3: 操作前レビュー・リスク判定スキル |
| Create | `README.md` | プロジェクト概要と使い方 |
| Create | `docs/decisions/0001-adopt-layered-guidelines.md` | 初回ADR: レイヤード方式採用の意思決定記録 |

---

### Task 1: Layer 1 — メタ・ガイドライン原則集

**Files:**
- Create: `docs/principles.md`

- [ ] **Step 1: principles.md を作成する**

```markdown
# メタ・ガイドライン原則集

AIエージェントを活用したシステム開発全般に適用するための普遍的原則。
ツールやプラットフォームに依存せず、あらゆるAIエージェントとの協働に通用する指針を定める。

## この原則集の使い方

これらの原則は一律に適用する絶対ルールではない。
タスクのリスク・複雑さ・可逆性に応じて、適用の強度を調整する。
低リスクで可逆なタスクには高い自律性を与え、高リスクで不可逆なタスクには厳密に原則を適用する。

## 原則

### 原則1: 意思決定の追跡可能性（Traceability of Decisions）

> 「なぜそうしたか」を記録する。変更や改善の判断には過去の文脈が必要になる。

- 設計判断とその理由を記録に残す
- 「何を作ったか」だけでなく「なぜその方法を選んだか」を残す
- 常に適用する。記録の深さはタスクの重要度に応じて自然に変わる（コミットメッセージから設計文書まで）

### 原則2: 関心の分離（Separation of Concerns）

> AIエージェントを「万能な1人」ではなく「責務を持った専門家」として設計する。

- 1つの指示・スキルに複数の責務を混ぜない
- エージェント間・エージェントとプログラム間のインターフェースは構造化データで定義する
- 常に適用する。タスクの規模によらず、責務の分離は設計の基本原則

### 原則3: コンテキストの明示的管理（Explicit Context Management）

> エージェントが「何を知っているか」を前提に頼らず、明示的に制御する。

- 各タスクの開始時に必要な前提情報を注入する
- エージェントが取得した情報の信頼性を検証する手段を持つ
- 常に適用する。注入するコンテキストの量はタスクの複雑さに応じて自然に変わる

### 原則4: 重要局面での人間の関与（Human Oversight at Critical Points）

> 重要な判断や不可逆な操作の前には、人間の確認またはシミュレーションを挟む。

- 書き込み・デプロイ・削除など不可逆操作の前にチェックポイントを設ける
- 設計上の重要な分岐点（アプローチの選択など）でも人間の判断を仰ぐ
- エージェントが行き詰まった場合のフォールバック（撤退条件）を定義する
- タスクのリスク・複雑さ・可逆性に応じて適用強度を調整する。定型的で低リスクなタスクにはチェックポイント不要。高リスク・不可逆なタスクには承認必須

### 原則5: 漸進的な検証（Incremental Verification）

> 作業は小さく区切り、各ステップで正しさを確認してから次に進む。

- AIエージェントに大きなタスクを一度に任せず、検証可能な小さな単位に分割する
- 各ステップの出力を確認してから次のステップに進む
- 問題が起きた場合の影響範囲を限定できる
- タスクのリスク・複雑さに応じて適用強度を調整する。単純で低リスクなタスクは一括実行して構わない。複雑・高リスクなタスクは段階的に進める
```

- [ ] **Step 2: 内容を確認する**

`docs/principles.md` を開き、以下を確認する:
- 前文がセクション「この原則集の使い方」に記載されていること
- 5つの原則がすべて記載されていること
- 原則1〜3に「常に適用する」、原則4〜5に「リスクに応じて調整する」旨が記載されていること

- [ ] **Step 3: コミットする**

```bash
git add docs/principles.md
git commit -m "docs: add meta-guidelines principles document (Layer 1)

Add the 5 core principles for AI agent-based system development:
1. Traceability of Decisions
2. Separation of Concerns
3. Explicit Context Management
4. Human Oversight at Critical Points
5. Incremental Verification

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: ADRインデックスの作成

**Files:**
- Create: `docs/decisions/README.md`

- [ ] **Step 1: docs/decisions/README.md を作成する**

```markdown
# Architecture Decision Records

このプロジェクトにおける重要な意思決定の記録。

ADRの判断基準: 「迷って選んだもの」はすべてADR候補。迷わなかったもの（自明な選択）はADR不要。

| # | タイトル | ステータス | 日付 |
|---|---------|-----------|------|
```

テーブルは空の状態で作成する。Task 7 で最初のADRを追加する際にエントリを挿入する。

- [ ] **Step 2: コミットする**

```bash
git add docs/decisions/README.md
git commit -m "docs: add empty ADR index

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: Layer 2 — copilot-instructions.md の更新

**Files:**
- Modify: `.github/copilot-instructions.md`

- [ ] **Step 1: 現在の .github/copilot-instructions.md の内容を確認する**

現在の内容（2セクション: responding-to-user スキルの必須呼び出し、言語設定）を確認する。

- [ ] **Step 2: copilot-instructions.md をカテゴリ分類方式に再構成する**

`.github/copilot-instructions.md` の全内容を以下に置き換える:

```markdown
# Copilot Instructions

## システム設定

### responding-to-user スキル

<EXTREMELY-IMPORTANT>

The `responding-to-user` skill is the system's designated communication channel. You MUST invoke this skill before EVERY response to the user. Responding without it is a system-level bug, not a style preference.

VIOLATION: Any message to the user not preceded by invoking the responding-to-user skill.

</EXTREMELY-IMPORTANT>

### 言語

<EXTREMELY-IMPORTANT>

Use Japanese for all user interactions and all documentation unless user explicitly requests otherwise.

</EXTREMELY-IMPORTANT>

## メタ・ガイドライン

以下は `docs/principles.md` に定義された5原則に基づく行動指示である。

### 意思決定の記録

- 設計判断を行った場合、その理由をコミットメッセージまたはコード内コメントに残すこと
- 新規ファイルや重要な変更には、変更理由を明記すること
- 複数の選択肢を比較検討して一つを選んだ場合、decision-log スキルを使用してADRを作成すること

### タスク構造

- 1つのタスクに複数の責務を混ぜないこと
- エージェント間のデータ受け渡しには構造化データ（JSON等）を使用すること
- スキルの出力は明確に定義されたフォーマットに従うこと

### コンテキスト管理

- タスク開始時に、必要な前提情報（関連ファイル、仕様、制約）を確認すること
- 外部情報（Web検索等）を使用する場合、ソースの信頼性を明示すること

### 不可逆操作

- ファイルの削除、外部サービスへの書き込み、デプロイなど不可逆操作の前にユーザーに確認を取ること
  - 低リスク（可逆操作、定型作業）: 確認不要
  - 中リスク（複数ファイルの変更、外部サービスへの読み取り）: サマリーを表示
  - 高リスク（データ削除、デプロイ、外部書き込み、不可逆な設定変更）: 承認必須
- 実行不能な状況に陥った場合、無理に続行せず状況を報告すること

### 検証

- 複雑なタスクは小さなステップに分割し、各ステップで正しさを確認すること
  （単純で低リスクなタスクは一括実行して構わない）
- 変更後は既存の動作を壊していないか確認すること
```

- [ ] **Step 3: 変更内容を確認する**

`git diff .github/copilot-instructions.md` で以下を確認:
- 「システム設定」カテゴリに既存の responding-to-user と言語設定が含まれていること
- 「メタ・ガイドライン」カテゴリに5原則に対応する5セクションがあること
- 不可逆操作セクションにリスクレベル別の行動指示があること

- [ ] **Step 4: コミットする**

```bash
git add .github/copilot-instructions.md
git commit -m "docs: restructure copilot-instructions.md with category layout (Layer 2)

Reorganize into two categories:
- System Settings: responding-to-user skill, language
- Meta-Guidelines: decision recording, task structure, context
  management, irreversible operations, verification

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: Layer 3 — decision-log スキル

**Files:**
- Create: `skills/decision-log/SKILL.md`

- [ ] **Step 1: skills/decision-log/SKILL.md を作成する**

```markdown
---
name: decision-log
description: "重要な意思決定をADR（Architecture Decision Record）として記録・管理する。設計判断、プロセス決定、スコープ決定、方針決定など、「迷って選んだもの」をすべて構造化して記録する。"
---

# decision-log

重要な意思決定をADR（Architecture Decision Record）として記録・管理するスキル。

## いつ使うか

以下のいずれかに該当する場合にこのスキルを呼び出す:

1. **設計・アーキテクチャの決定時** — 例: 「レイヤード方式を採用する」「マイクロサービスではなくモノリスで始める」
2. **プロセス・ワークフローの決定時** — 例: 「情報収集と分析を別セッションに分ける」「コードレビューはAI自動レビュー＋人間の最終確認」
3. **スコープ・優先度の決定時** — 例: 「MVPでは通知機能を含めない」「セキュリティ強化を機能追加より優先する」
4. **方針・ルールの決定時** — 例: 「外部APIの情報は必ずキャッシュ経由」「エージェント3回連続エラーで人間にエスカレーション」
5. **既存の判断の変更時** — 旧ADRを Superseded に更新し、新ADRを作成する

**判断基準**: 「迷って選んだもの」はすべてADR候補。迷わなかったもの（自明な選択）はADR不要。

## ADR作成手順

### 1. 次の連番を決定する

`docs/decisions/README.md` のテーブルを確認し、最大番号+1を採番する。
テーブルが空なら `0001` から開始する。

### 2. ADRファイルを作成する

ファイル名: `docs/decisions/NNNN-slug.md`（NNNNは4桁ゼロ埋め連番、slugは英語のケバブケース）

以下のフォーマットで作成する:

```
# ADR-NNNN: タイトル

- **Status**: Proposed
- **Date**: YYYY-MM-DD

## Context

（この判断に至った背景・状況を記述する）

## Considered Alternatives

（検討した他の選択肢を列挙し、それぞれの簡潔な評価を記述する）

## Decision

（何を決めたか、なぜこの選択肢を選んだかを記述する）

## Consequences

（この判断の結果起きることを記述する。良い影響・悪い影響の両方を含める）
```

### 3. インデックスを更新する

`docs/decisions/README.md` のテーブルに新しいエントリを追加する:

```
| [NNNN](NNNN-slug.md) | タイトル | Proposed | YYYY-MM-DD |
```

### 4. コミットする

ADRファイルとインデックスを一緒にコミットする:

```bash
git add docs/decisions/NNNN-slug.md docs/decisions/README.md
git commit -m "adr: NNNN - タイトル"
```

## ADR更新手順

### ステータス変更

ADRのステータスを変更する場合:

1. 該当ADRファイルの `Status` を更新する（Accepted, Deprecated, Superseded by ADR-XXXX）
2. `docs/decisions/README.md` のテーブルのステータスも更新する
3. 変更理由をADRのConsequencesセクションに追記する
4. コミットする

### 承認（Proposed → Accepted）

ユーザーがADRの内容を確認し承認した場合、Status を `Accepted` に変更する。

## ユーザーへの確認

ADR作成後、ユーザーに以下を確認する:
「ADR-NNNN を作成しました。内容を確認して、承認（Accepted）してよいか教えてください。」
```

- [ ] **Step 2: スキルファイルの構造を確認する**

`skills/decision-log/SKILL.md` を開き、以下を確認:
- YAML frontmatter に `name` と `description` が含まれていること
- ADRフォーマットのテンプレートが記載されていること
- 作成手順・更新手順が具体的に記載されていること
- 作成トリガーの5パターンが記載されていること

- [ ] **Step 3: コミットする**

```bash
git add skills/decision-log/SKILL.md
git commit -m "feat: add decision-log skill (Layer 3)

Implements ADR creation, update, and index management workflow.
Uses Nygard format with Considered Alternatives section.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: Layer 3 — pre-action-review スキル

**Files:**
- Create: `skills/pre-action-review/SKILL.md`

- [ ] **Step 1: skills/pre-action-review/SKILL.md を作成する**

```markdown
---
name: pre-action-review
description: "不可逆操作や重要な変更の前に、実行内容のサマリーとリスク評価をユーザーに提示する。リスクレベルに応じてログのみ・サマリー表示・承認必須を切り替える。"
---

# pre-action-review

不可逆操作や重要な変更の前に、実行内容のリスクを評価し、適切なレベルの確認をユーザーに提示するスキル。

## いつ使うか

以下の操作を実行する前にこのスキルを呼び出す:

- ファイルの削除
- 外部サービスへの書き込み
- デプロイ操作
- 不可逆な設定変更
- 大規模なファイル変更（多数のファイルを一度に変更する場合）
- 設計上の重要な分岐点で判断を行う場合

## リスク評価基準

操作を以下の3段階で評価する:

### 低リスク（Low）
- 可逆操作（git で元に戻せる変更、ローカルファイルの編集）
- 定型作業（フォーマット整形、リネーム、コメント修正）
- **対応**: ログのみ。操作を記録するが、ユーザーへの確認は不要

### 中リスク（Medium）
- 複数ファイルにまたがる変更
- 外部サービスへの読み取りアクセス
- 既存の動作に影響しうる変更
- **対応**: サマリー表示。以下の情報をユーザーに提示する
  - 何をしようとしているか
  - 影響を受けるファイル・サービスの一覧
  - 予想される影響

### 高リスク（High）
- データの削除（ファイル削除、データベースのレコード削除）
- デプロイ操作
- 外部サービスへの書き込み
- 不可逆な設定変更（環境変数の変更、クラウドリソースの作成・削除）
- **対応**: 承認必須。以下の情報をユーザーに提示し、明示的な承認を得る
  - 何をしようとしているか
  - 影響範囲の詳細
  - リスクの説明
  - ロールバック可能かどうか

## レビュー提示フォーマット

リスク評価をユーザーに提示する際は、以下の構造で伝える:

```
**操作前レビュー**
- 操作: （実行しようとしている操作の説明）
- リスク: Low / Medium / High
- 影響範囲: （影響を受けるファイル、サービス、データの一覧）
- 理由: （なぜこの操作が必要か）
```

高リスクの場合は追加で:
```
- ロールバック: （元に戻す手段があるか）
- 承認してよいですか？
```

## フォールバック

タスクの実行中に以下の状況に陥った場合、無理に続行せず撤退する:

- 同じエラーが3回以上繰り返される
- 予期しない副作用が発生した
- 必要な情報やアクセス権が不足している

撤退する場合は以下の情報をユーザーに報告する:
- 何をしようとしていたか
- 何が起きたか
- どこまで完了しているか
- 推奨される次のアクション
```

- [ ] **Step 2: スキルファイルの構造を確認する**

`skills/pre-action-review/SKILL.md` を開き、以下を確認:
- YAML frontmatter に `name` と `description` が含まれていること
- リスク評価基準（Low / Medium / High）が具体例付きで記載されていること
- レビュー提示フォーマットが記載されていること
- フォールバック条件が記載されていること

- [ ] **Step 3: コミットする**

```bash
git add skills/pre-action-review/SKILL.md
git commit -m "feat: add pre-action-review skill (Layer 3)

Implements risk-based review workflow with three levels:
- Low: log only
- Medium: summary display
- High: approval required

Includes fallback conditions for stuck tasks.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: README.md の作成

**Files:**
- Create: `README.md`

- [ ] **Step 1: README.md を作成する**

```markdown
# AI Agent Meta-Guidelines

AIエージェントを活用したシステム開発のためのメタ・ガイドライン。

## 概要

このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot で実践するための仕組みを提供する。

対象とする「システム」には、通常のソフトウェア（Webアプリ、API、CLIなど）だけでなく、AIエージェントによる情報収集・分析・意思決定を含むワークフロー型システムも含む。

## 構造

3層のレイヤード方式で構成される:

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | [`docs/principles.md`](docs/principles.md) | ツール非依存のメタ・ガイドライン原則集 |
| Layer 2 | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Copilot向け行動指示 |
| Layer 3 | [`skills/`](skills/) | ワークフローを実装するスキル群 |

## 5つの原則

1. **意思決定の追跡可能性** — 「なぜそうしたか」を記録する
2. **関心の分離** — エージェントを「万能な1人」ではなく「責務を持った専門家」として設計する
3. **コンテキストの明示的管理** — エージェントが「何を知っているか」を明示的に制御する
4. **重要局面での人間の関与** — 重要な判断や不可逆操作の前に人間の確認を挟む
5. **漸進的な検証** — 作業を小さく区切り、各ステップで正しさを確認する

詳細は [`docs/principles.md`](docs/principles.md) を参照。

## スキル

| スキル | 説明 |
|--------|------|
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |

## 新しいプロジェクトでの使い方

1. `.github/copilot-instructions.md` を新プロジェクトにコピーする
2. `skills/` ディレクトリを新プロジェクトにコピーする
3. プロジェクト固有の指示を `copilot-instructions.md` に追記する
4. `docs/decisions/` ディレクトリを作成し、`README.md`（ADRインデックス）を配置する

## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `docs/principles.md` に新しい原則を追記する
3. `copilot-instructions.md` に対応する行動指示を追加する
4. 必要ならスキルを作成する
5. ADRに「なぜこの原則を追加したか」を記録する
```

- [ ] **Step 2: コミットする**

```bash
git add README.md
git commit -m "docs: add project README

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 7: 初回ADR — レイヤード方式の採用

decision-log スキルのフォーマットを実際に使用して最初のADRを作成する（ドッグフーディング）。

**Files:**
- Create: `docs/decisions/0001-adopt-layered-guidelines.md`
- Modify: `docs/decisions/README.md`

- [ ] **Step 1: ADRファイルを作成する**

```markdown
# ADR-0001: レイヤード方式のガイドライン構成を採用

- **Status**: Accepted
- **Date**: 2026-04-12

## Context

AIエージェントを活用したシステム開発のためのメタ・ガイドラインを策定するにあたり、ガイドラインの構成方式を決定する必要があった。ガイドラインには「普遍的な原則」と「GitHub Copilot固有の実行指示」と「自動化されたワークフロー」が含まれ、これらをどのように整理するかが課題であった。

## Considered Alternatives

- **レイヤード方式（3層分離）**: 原則（principles.md）→ 実行指示（copilot-instructions.md）→ スキル（skills/）に分離。各レイヤー独立で編集・拡張可能
- **プラグイン特化方式**: すべてをCopilotプラグインとしてパッケージ化。npm/gitでインストール可能だが、原則がコードに埋もれて読みにくい
- **ドキュメント中心方式**: 1つのcopilot-instructions.mdに統合。シンプルだが肥大化リスクが高い

## Decision

レイヤード方式を採用する。

理由:
- 「なぜ（原則）」と「どうやる（実装）」が明確に分離され、拡張性が高い
- 小さく始めて育てる方針に最もフィットする（原則追加 → 指示追記 → スキル化の段階的成長）
- 「関心の分離」というメタ・ガイドライン自体が、ガイドラインの構造にも反映される
- copilot-instructions.md内はカテゴリ分類方式（システム設定 + メタ・ガイドライン）を採用

## Consequences

- 良い影響: 各レイヤーを独立して編集・拡張できる。原則の追加が低コスト。ツール非依存の原則を他のAIエージェント環境にも転用可能
- 悪い影響: ファイル数がやや多い（3層 + ADR + specs）。principles.mdとcopilot-instructions.mdの同期を手動で行う必要がある
```

- [ ] **Step 2: インデックスを更新する**

`docs/decisions/README.md` のテーブルに以下の行を追加する:

```markdown
| [0001](0001-adopt-layered-guidelines.md) | レイヤード方式のガイドライン構成を採用 | Accepted | 2026-04-12 |
```

- [ ] **Step 3: コミットする**

```bash
git add docs/decisions/0001-adopt-layered-guidelines.md docs/decisions/README.md
git commit -m "adr: 0001 - レイヤード方式のガイドライン構成を採用

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 8: 実装計画のコミット

**Files:**
- Add: `docs/plans/2026-04-12-meta-guidelines-plan.md`

- [ ] **Step 1: コミットする**

```bash
git add docs/plans/2026-04-12-meta-guidelines-plan.md
git commit -m "docs: add implementation plan

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 9: 全体の最終確認

- [ ] **Step 1: ファイル構成を確認する**

プロジェクトのディレクトリ構成が以下と一致することを確認する:

```
Playground_MakeAiInstructions/
├── docs/
│   ├── principles.md
│   ├── decisions/
│   │   ├── README.md
│   │   └── 0001-adopt-layered-guidelines.md
│   ├── specs/
│   │   └── 2026-04-12-meta-guidelines-design.md
│   └── plans/
│       └── 2026-04-12-meta-guidelines-plan.md
├── .github/
│   └── copilot-instructions.md
├── skills/
│   ├── decision-log/
│   │   └── SKILL.md
│   └── pre-action-review/
│       └── SKILL.md
└── README.md
```

- [ ] **Step 2: 各レイヤーの整合性を確認する**

以下を確認する:
- `docs/principles.md` の5原則と `.github/copilot-instructions.md` のメタ・ガイドラインセクションが1対1で対応していること
- `skills/decision-log/SKILL.md` のADRフォーマットと `docs/decisions/0001-adopt-layered-guidelines.md` の実際のフォーマットが一致していること
- `docs/decisions/README.md` のインデックスに0001のエントリがあること
- `README.md` のスキル一覧と `skills/` ディレクトリの内容が一致していること

- [ ] **Step 3: git log を確認する**

```bash
git --no-pager log --oneline
```

7〜8個のコミットが時系列順に並んでいることを確認する。
