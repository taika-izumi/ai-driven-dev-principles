# 機能ブロック駆動の設計＋仕様書分割（サブプロジェクトB）実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** brainstorming と writing-plans の間に挟む新スキル `feature-block-design` を導入し、原則2「関心の分離」をエージェント設計だけでなくコード・ドキュメントにも適用範囲を広げ、`copilot-instructions.md` に「分割設計」と「仕様書スナップショット規約」を常時ルールとして追加する。

**Architecture:** Layer 1（`docs/principles.md`）の原則2を拡張し、Layer 2（`copilot-instructions.md`）に「分割設計の指針」と「ドキュメント運用」セクションを追加し、Layer 3 に新スキル `skills/feature-block-design/SKILL.md` を追加する。`start-work` の Phase 2 ナビゲーションマッピングに新スキルを追加する。テンプレートと README/CONTRIBUTING を同期する。

**Tech Stack:** Markdown, YAML frontmatter（Skill定義）, PowerShell（既存の `scripts/sync-template.ps1`）

**前提:** 本タスクは `feature/feature-block-design` ブランチで作業する。spec は `docs/specs/2026-05-01-feature-block-design/` にコミット済み（commit `a34bbf1`）。

---

## File Structure（変更ファイル一覧）

| 種別 | パス | 役割 |
|------|------|------|
| 新規 | `docs/decisions/0007-introduce-feature-block-design-skill.md` | ADR: feature-block-design スキル導入 |
| 新規 | `docs/decisions/0008-adopt-spec-directory-split-and-snapshot-rule.md` | ADR: 仕様書のディレクトリ分割形式とスナップショット規約 |
| 新規 | `docs/decisions/0009-extend-principle-2-scope.md` | ADR: 原則2の適用範囲拡張 |
| 新規 | `skills/feature-block-design/SKILL.md` | 新スキル本体 |
| 修正 | `docs/principles.md` | 原則2 拡張（B2） |
| 修正 | `.github/copilot-instructions.md` | 「タスク構造」追記＋「ドキュメント運用」新設（B3） |
| 修正 | `skills/start-work/SKILL.md` | Phase 2 ナビゲーションに feature-block-design 追加 |
| 修正 | `docs/decisions/README.md` | ADR-0007〜0009 のインデックス追加 |
| 修正 | `template.manifest` | 新スキル追加 |
| 修正 | `CONTRIBUTING.md` | 新スキルのシナリオ追記 |
| 修正 | `README.md` | スキル一覧に追加 |
| 修正 | `docs/handoff/master.md` | サブプロジェクトB完了反映 |
| 自動 | `template/**` | `scripts/sync-template.ps1` 実行で再生成 |

---

### Task 1: ADR-0007 を作成する（feature-block-design スキル導入）

**Files:**
- Create: `docs/decisions/0007-introduce-feature-block-design-skill.md`
- Modify: `docs/decisions/README.md`

**依存:** なし

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0007-introduce-feature-block-design-skill.md` を以下の内容で作成する:

```markdown
# ADR-0007: 機能ブロック駆動の設計スキル（feature-block-design）の導入

- **Status**: Proposed
- **Date**: 2026-05-01

## Context

AIエージェントを活用した開発で、以下の課題が繰り返し観察されている:

1. brainstorming 時点では「全体方針」までしか確定せず、システムを疎結合な機能ブロックに分割する作業がしばしば省略される
2. その結果、生成されたシステムが大きな泥団子化・スパゲッティ化する
3. 既存の brainstorming スキルにも "design for isolation and clarity" の指針はあるが、抽象的指針のためトリガーとして弱い

AIは一般的な設計原則の知識を持っているにも関わらず、「いつ・どの粒度で・どんな形式で」分割するかの強制トリガーがないため、知識が実行に結びつかない。

## Decision

brainstorming と writing-plans の間に新スキル `feature-block-design` を挟む。

このスキルは:
- brainstorming で合意済みの全体方針を入力に
- 適用要否を判定し（主要機能 ≥ 2 または想定モジュール ≥ 3）
- 機能ブロックを抽出してユーザー承認を得て
- 各ブロックの詳細仕様を分割形式で出力する

## Alternatives Considered

- **2スキル分離（feature-block-decomposition + spec-partitioning）**: 関心分離は綺麗だが、実運用ではほぼ常にセットで使うためハンドオフが過剰。
- **スキルを増やさず原則拡張＋既存スキル強化のみ**: トリガーが弱く、既存問題（知識があっても実行されない）を再生産する懸念が大きい。

## Consequences

- brainstorming 直後にもう1段の合意プロセスが入るため、小タスクではオーバーヘッドになる → 適用要否判定で回避
- brainstorming との責務境界をスキル内に明示する必要がある → スキルに明文化
- writing-plans が「ブロック単位の詳細仕様」を入力にできるようになり、plan 自体もブロック単位で分割しやすくなる

## Related

- spec: `docs/specs/2026-05-01-feature-block-design/00-overview.md`
- spec: `docs/specs/2026-05-01-feature-block-design/01-skill-feature-block-design.md`
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` の表末尾に以下の行を追加する:

```markdown
| [0007](0007-introduce-feature-block-design-skill.md) | 機能ブロック駆動の設計スキル（feature-block-design）の導入 | Proposed | 2026-05-01 |
```

- [ ] **Step 3: コミット**

```bash
git add docs/decisions/0007-introduce-feature-block-design-skill.md docs/decisions/README.md
git commit -m "adr: propose 0007 introduce feature-block-design skill

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 2: ADR-0008 を作成する（仕様書のディレクトリ分割形式とスナップショット規約）

**Files:**
- Create: `docs/decisions/0008-adopt-spec-directory-split-and-snapshot-rule.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 1（ADRインデックスの並び維持のため）

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0008-adopt-spec-directory-split-and-snapshot-rule.md`:

```markdown
# ADR-0008: 仕様書のディレクトリ分割形式とスナップショット規約の採用

- **Status**: Proposed
- **Date**: 2026-05-01

## Context

中規模以上のシステムを単一仕様書ファイルで管理すると、以下の問題が起きる:

1. AI も人間も全体把握のために全文を読まされる
2. AI が特定機能を編集する際、不要な詳細までコンテキストに載る
3. 改修時に「変更差分仕様書」を別ファイルとして追記してしまい、現時点のシステム全容を1つで説明するドキュメントが消失する

## Decision

中規模以上のシステムでは、仕様書を以下のディレクトリ分割形式で配置する:

```
docs/specs/YYYY-MM-DD-<topic>/
├── 00-overview.md       # 概要、機能一覧、ブロック関係、主要処理フロー
├── 01-<block>.md        # ブロック1の詳細
├── 02-<block>.md        # ブロック2の詳細
└── ...
```

あわせて以下のスナップショット規約を採用する:

- 仕様書は常に「現時点のシステム全容のスナップショット」として維持する
- 改修時は既存仕様書を**書き換えで更新**する。差分のみの別ファイルを作らない
- 「なぜ変更したか」は ADR に書き、仕様書には「今どうなっているか」のみを書く

## Alternatives Considered

- **単一ファイル + セクション規約**: 既存形式を維持できるが、AI の編集時コンテキスト効率が改善しない
- **規模に応じてAIが選択**: 判断のぶれが大きく、改修時の整合性確保が難しい

## Consequences

- 既存の単一ファイル仕様書（`docs/specs/2026-04-25-record-strengthening-design.md` 等）は過去資産として残置。新規仕様書のみ本形式を適用
- ADR と仕様書の責務分離が明確になる（ADR: なぜ / 仕様書: 何）
- 改修時に「全体を書き換える」負荷が増えるが、AI による自動更新で吸収可能

## Related

- spec: `docs/specs/2026-05-01-feature-block-design/00-overview.md`
- ADR-0007: 関連スキル導入
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` の表末尾に以下を追加:

```markdown
| [0008](0008-adopt-spec-directory-split-and-snapshot-rule.md) | 仕様書のディレクトリ分割形式とスナップショット規約の採用 | Proposed | 2026-05-01 |
```

- [ ] **Step 3: コミット**

```bash
git add docs/decisions/0008-adopt-spec-directory-split-and-snapshot-rule.md docs/decisions/README.md
git commit -m "adr: propose 0008 spec directory split and snapshot rule

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 3: ADR-0009 を作成する（原則2の適用範囲拡張）

**Files:**
- Create: `docs/decisions/0009-extend-principle-2-scope.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 2

- [ ] **Step 1: ADRファイルを作成する**

`docs/decisions/0009-extend-principle-2-scope.md`:

```markdown
# ADR-0009: 原則2「関心の分離」の適用範囲拡張

- **Status**: Proposed
- **Date**: 2026-05-01

## Context

現状の原則2「関心の分離（Separation of Concerns）」は冒頭が「AIエージェントを『万能な1人』ではなく『責務を持った専門家』として設計する」となっており、エージェント設計に限定されている。

しかし Separation of Concerns はソフトウェア工学における普遍的概念であり、エージェントが生成するコード・ドキュメント・仕様書にも等しく適用すべきである。サブプロジェクトBで導入する `feature-block-design` スキルおよび関連ルールには、この拡張版が上位概念として必要。

## Decision

原則2の冒頭引用を以下に変更する:

> 責務を1つに絞り、関心の分離を守る。これはエージェント設計だけでなく、エージェントが生成するコード・ドキュメント・仕様書にも等しく適用する。

あわせて箇条書きに以下を追加する:

> AI が生成するコード・モジュール・仕様書も、責務単位で分割し、疎結合になるよう構造化する

## Alternatives Considered

- **新章「コード・ドキュメントの分割」を立てる**: 原則2と内容が重複し、原則間の境界が曖昧になる。原則総数も増える
- **原則を変更せず copilot-instructions.md だけで対応**: 上位概念の根拠が層をまたいで欠落し、ガイドラインの一貫性が失われる

## Consequences

- 原則の番号は不変なので、既存 ADR や README からのリンク切れは発生しない
- copilot-instructions.md の記述（B3）と template/（B4）を同期する必要がある（同一サブプロジェクトで対応）

## Related

- spec: `docs/specs/2026-05-01-feature-block-design/02-principle-extension.md`
```

- [ ] **Step 2: ADRインデックスを更新する**

`docs/decisions/README.md` の表末尾に以下を追加:

```markdown
| [0009](0009-extend-principle-2-scope.md) | 原則2「関心の分離」の適用範囲拡張 | Proposed | 2026-05-01 |
```

- [ ] **Step 3: コミット**

```bash
git add docs/decisions/0009-extend-principle-2-scope.md docs/decisions/README.md
git commit -m "adr: propose 0009 extend principle 2 scope

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 4: 原則2を拡張する（B2 実装）

**Files:**
- Modify: `docs/principles.md`（原則2セクション）

**依存:** Task 3

- [ ] **Step 1: 現状を確認する**

```bash
# Get-Content docs\principles.md | Select-String -Pattern "原則2" -Context 0,15
```

期待: 現状の原則2セクションが表示される。

- [ ] **Step 2: 原則2の冒頭引用と箇条書きを更新する**

`docs/principles.md` の以下の部分を:

```markdown
### 原則2: 関心の分離（Separation of Concerns）

> 「AIエージェントを「万能な1人」ではなく「責務を持った専門家」として設計する。」

- 1つの指示・スキルに複数の責務を混ぜない
- エージェント間・エージェントとプログラム間のインターフェースは構造化データで定義する
- 常に適用する。タスクの規模によらず、責務の分離は設計の基本原則
```

以下に置き換える:

```markdown
### 原則2: 関心の分離（Separation of Concerns）

> 責務を1つに絞り、関心の分離を守る。これはエージェント設計だけでなく、エージェントが生成するコード・ドキュメント・仕様書にも等しく適用する。

- 1つの指示・スキルに複数の責務を混ぜない
- エージェント間・エージェントとプログラム間のインターフェースは構造化データで定義する
- AI が生成するコード・モジュール・仕様書も、責務単位で分割し、疎結合になるよう構造化する
- 常に適用する。タスクの規模によらず、責務の分離は設計の基本原則
```

- [ ] **Step 3: 整合性を確認する**

```bash
git --no-pager diff docs/principles.md
```

期待: 原則2セクションのみが上記の通り変更されている。他原則と前文（「## この原則集の使い方」等）に変更がない。

- [ ] **Step 4: コミット**

```bash
git add docs/principles.md
git commit -m "docs(principles): extend principle 2 scope to code and docs

Aligns with ADR-0009.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 5: copilot-instructions.md を更新する（B3 実装）

**Files:**
- Modify: `.github/copilot-instructions.md`（「タスク構造」末尾追記＋「ドキュメント運用」新設）

**依存:** Task 4

- [ ] **Step 1: 「タスク構造」セクションに2項目追記する**

`.github/copilot-instructions.md` の `### タスク構造` セクションを:

```markdown
### タスク構造

- 1つのタスクに複数の責務を混ぜないこと
- エージェント間のデータ受け渡しには構造化データ（JSON等）を使用すること
- スキルの出力は明確に定義されたフォーマットに従うこと
```

以下に置き換える:

```markdown
### タスク構造

- 1つのタスクに複数の責務を混ぜないこと
- エージェント間のデータ受け渡しには構造化データ（JSON等）を使用すること
- スキルの出力は明確に定義されたフォーマットに従うこと
- AI が生成するコード・モジュール・仕様書は、**高凝集・疎結合**および**単一責任**といった一般的な設計原則に従って分割すること。ただしプロジェクトのパラダイム・規模・制約に応じて、適切な粒度を判断すること
- 中規模以上のシステム（主要機能が2つ以上、または想定モジュール/コンポーネントが3つ以上）を設計する際は、brainstorming と writing-plans の間に `feature-block-design` スキルを使うこと
```

- [ ] **Step 2: 「検証」セクションの後に「ドキュメント運用」セクションを新設する**

`.github/copilot-instructions.md` の `### 検証` セクション末尾の直後に、以下を追加する:

```markdown

### ドキュメント運用

- 仕様書は、それを読むだけで現時点のシステム全容が分かるスナップショットとして維持すること
- 既存仕様書を改修する場合は、変更差分のみの別ファイルを作らず、既存仕様書を**書き換えで更新**すること
- 「なぜ変更したか」は ADR に記録し、仕様書には「今どうなっているか」のみを書くこと
- 中規模以上のシステムでは、仕様書は `docs/specs/YYYY-MM-DD-<topic>/` 配下にディレクトリ分割形式（`00-overview.md` + `NN-<block>.md`）で配置すること
```

- [ ] **Step 3: 整合性を確認する**

```bash
git --no-pager diff .github/copilot-instructions.md
```

期待: 「タスク構造」末尾に2項目追加と、「検証」末尾の直後に「ドキュメント運用」セクションが追加されている。「## システム設定」配下と他既存セクションに変更がない。

- [ ] **Step 4: コミット**

```bash
git add .github/copilot-instructions.md
git commit -m "docs(instructions): add granularity rule and doc snapshot policy

- Add high-cohesion/loose-coupling principle citation in task structure
- Add feature-block-design invocation rule for medium+ systems
- New section: ドキュメント運用 (spec snapshot rule)

Aligns with ADR-0007, ADR-0008.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 6: feature-block-design スキル本体を作成する（B1 実装）

**Files:**
- Create: `skills/feature-block-design/SKILL.md`

**依存:** Task 5

- [ ] **Step 1: スキルディレクトリとファイルを作成する**

`skills/feature-block-design/SKILL.md` を以下の内容で作成する:

````markdown
---
name: feature-block-design
description: "brainstorming で合意した全体方針を、疎結合な機能ブロックに分割し、各ブロックの詳細仕様をディレクトリ分割形式（docs/specs/YYYY-MM-DD-<topic>/）で作成または更新する。brainstorming と writing-plans の間で発動する。"
---

# feature-block-design

brainstorming で合意済みの「何を作るか / どう変更するか」を入力に、システムを疎結合な機能ブロックに分割し、分割仕様書を作成・更新するスキル。

## いつ使うか

brainstorming スキルが完了した直後で、writing-plans に進む前。
ただし以下の**適用要否判定**に該当しなければ writing-plans へ直行する。

### 適用要否判定（しきい値）

以下のいずれかに該当する場合のみ後続フェーズへ進む:

- brainstorming 出力に「主要機能（ユーザー価値を直接提供する機能）」が **2 つ以上** 含まれる
- 想定モジュール / コンポーネント / サービスが **3 つ以上** ある

該当しない場合は、判定理由をユーザーに提示して writing-plans への直行を推奨し、本スキルを終了する。

## brainstorming との責務境界

| スキル | 責務 |
|--------|------|
| brainstorming | **何を作るか / なぜ作るか / どんな方針で作るか**の合意 |
| feature-block-design（本スキル） | **その方針をどんな機能ブロックに分割し、各ブロックがどんな責務・インターフェース・データを持つか**を確定し、分割仕様書として出力する |
| writing-plans | 上記を入力に、**実装をどんなタスクに分け、どの順で進めるか**の plan を作る |

## 重要な前提

- 仕様書は常に「現時点のシステム全容のスナップショット」として維持する
- 差分のみを記載した別ファイル（変更差分仕様書）を作ってはならない
- 「なぜ変更したか」は ADR に書き、仕様書には「今どうなっているか」のみを書く
- 機能ブロックは**高凝集・疎結合・単一責任**を満たすように切り出す。ただしプロジェクトのパラダイム・規模・制約に応じて適切な粒度を判断する

## 出力ディレクトリ構造

```
docs/specs/YYYY-MM-DD-<topic>/
├── 00-overview.md       # 概要、機能一覧、ブロック関係、主要処理フロー、設計上の意思決定、スコープ外、完了基準
├── 01-<block-slug>.md   # ブロック1の詳細
├── 02-<block-slug>.md   # ブロック2の詳細
└── ...
```

- ブロック番号はゼロ埋め2桁の連番
- ブロックスラッグは英小文字とハイフン

## 手順

### Phase 0: 適用要否判定

上記の「適用要否判定」を実施する。該当しなければスキル終了。

### Phase 1: モード判定

該当 topic の仕様書ディレクトリ `docs/specs/*-<topic>/` の有無で分岐:

- **存在しない** → 新規モード
- **存在する** → 修正モード（既存ディレクトリを入力に含める）

### Phase 2: 機能ブロック抽出

#### 粒度ガイドライン（1ブロックの基準）

- 単独で説明・テスト可能な責務単位
- 他ブロックとの依存はインターフェース（関数シグネチャ、API、メッセージ等）経由のみ
- 1ブロックの内部詳細を変更しても、他ブロックの実装に影響を与えない
- ブロック数の目安: 2〜7個。超過する場合は階層化を検討し、ユーザーに確認する

#### 抽出時の自己問いかけ

- このブロックは「何をするか」を1文で説明できるか
- 他ブロックを知らずにこのブロックを実装・テストできるか
- ブロック間の依存方向は循環していないか

抽出結果（ブロック名、責務一行サマリ、依存関係）をユーザーに提示して**承認を得る**。
この承認は ADR 候補（アーキテクチャ決定）。横断ラッパー経由で `decision-log` を呼ぶ。

### Phase 3: `00-overview.md` の作成 / 更新

以下の構成で書く:

1. このドキュメントの読み方（含まれるファイルの一覧）
2. 背景・動機
3. 全体アーキテクチャ（機能ブロック一覧表 + ブロック間関係図）
4. 主要な処理フロー
5. 設計上の主要な意思決定（ADR への参照）
6. スコープ外（YAGNI）
7. 完了基準

**修正モードの厳守事項**:

- 既存内容を**全置換的に**更新する。新セクション追記による継ぎ接ぎを禁止
- 「変更前」「変更後」「差分」のような節を作らない。常に最新スナップショットのみを書く
- 変更理由・経緯は ADR にのみ書く。仕様書からは ADR を参照リンクで指す

### Phase 4: 各ブロック詳細の作成 / 更新

ブロック数だけ繰り返す。ファイル名は `NN-<block-slug>.md`。

各ファイルの構成:

1. 対象ファイル（実装が触る予定のファイル / モジュールパス）
2. 責務（1〜3 文）
3. インターフェース（公開関数 / API / 入出力データ形式）
4. サブ機能 / 内部構成
5. データモデル（必要な場合）
6. このブロック固有の制約・前提
7. 関連 ADR

修正モードでは Phase 3 同様、既存記述の整合性を保ちながら**書き換え**で更新する。

### Phase 5: 整合性セルフレビュー

以下を機械的にチェックし、不整合があれば該当フェーズに戻る:

- `00-overview.md` の機能ブロック一覧表のブロック数 = `NN-<block>.md` ファイル数
- 各 `NN-<block>.md` の「対象ファイル」が他ブロックと衝突していないか
- ブロック間インターフェースの呼出側と被呼出側の記述が一致するか
- 「変更前 / 変更後 / 差分」を示す節が混入していないか（スナップショット規約違反の検出）

### Phase 6: 横断ラッパー処理

`start-work` の横断ラッパーが自動適用する:

- ADR 候補（機能ブロック構造の選択など）を `decision-log` 経由で記録
- handoff を update（マイルストーン到達）

その後 writing-plans へ遷移する。

## 対応する原則

- 原則1（追跡可能性）: ブロック分割時の ADR 候補検出、handoff 更新
- 原則2（関心の分離）: 機能ブロックを独立した責務として切り出す。本スキル自身が原則2拡張版の体現
- 原則3（コンテキスト管理）: 分割仕様書により、AI が必要なファイルだけコンテキストに載せられる
- 原則4（人間の関与）: ブロック構造の承認ゲート、適用要否判定理由の提示
- 原則5（漸進的検証）: ブロック単位での詳細化により、後続の writing-plans / 実装が小さな単位で進められる
````

- [ ] **Step 2: ファイル作成を確認する**

```bash
git --no-pager status
```

期待: `skills/feature-block-design/SKILL.md` が untracked として表示される。

- [ ] **Step 3: コミット**

```bash
git add skills/feature-block-design/SKILL.md
git commit -m "feat: add feature-block-design skill

New skill bridging brainstorming and writing-plans:
- Auto-decides applicability (>=2 features or >=3 modules)
- Extracts feature blocks with cohesion/coupling guidelines
- Outputs split spec docs (00-overview.md + NN-block.md)
- Enforces snapshot rule (no diff-only spec files)

Aligns with ADR-0007, ADR-0008.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 7: start-work スキルのナビゲーションマッピングを更新する

**Files:**
- Modify: `skills/start-work/SKILL.md`（Phase 2 のマッピング表）

**依存:** Task 6

- [ ] **Step 1: マッピング表に新スキルを追加する**

`skills/start-work/SKILL.md` の Phase 2 マッピング表を以下のように修正する。

変更前:

```markdown
| 作業意図 | 推奨スキル | フォールバック |
|----------|----------|--------------|
| 新規開発・機能追加・改修 | superpowers:brainstorming | インライン簡易ヒアリング |
| 既存仕様からの計画作成 | superpowers:writing-plans | インライン簡易plan作成 |
```

変更後（`brainstorming` 行の直後、`writing-plans` 行の直前に1行追加）:

```markdown
| 作業意図 | 推奨スキル | フォールバック |
|----------|----------|--------------|
| 新規開発・機能追加・改修 | superpowers:brainstorming | インライン簡易ヒアリング |
| brainstorming 完了後・計画作成前の機能ブロック分割 | feature-block-design（適用要否を内部判定） | スキップして writing-plans へ |
| 既存仕様からの計画作成 | superpowers:writing-plans | インライン簡易plan作成 |
```

- [ ] **Step 2: 整合性を確認する**

```bash
git --no-pager diff skills/start-work/SKILL.md
```

期待: マッピング表に1行追加されただけ。他箇所に変更がない。

- [ ] **Step 3: コミット**

```bash
git add skills/start-work/SKILL.md
git commit -m "feat(start-work): add feature-block-design to phase 2 navigation

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 8: template.manifest を更新する

**Files:**
- Modify: `template.manifest`

**依存:** Task 7

- [ ] **Step 1: 新スキルを manifest に追加する**

`template.manifest` の末尾に以下の行を追加する:

```
skills/feature-block-design/SKILL.md
```

最終的な manifest は以下のようになる:

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
skills/start-work/SKILL.md
skills/session-handoff/SKILL.md
skills/feature-block-design/SKILL.md
```

- [ ] **Step 2: 確認する**

```bash
Get-Content template.manifest
```

期待: 末尾に `skills/feature-block-design/SKILL.md` が追加されている。

---

### Task 9: テンプレートを同期する

**Files:**
- Modify: `template/**`（自動生成）

**依存:** Task 8

- [ ] **Step 1: 同期スクリプトを実行する**

```bash
pwsh scripts/sync-template.ps1
```

期待出力例: `[sync-template] Done.` 等のエラーなしの完了メッセージ。

- [ ] **Step 2: 同期結果を確認する**

```bash
git --no-pager status
git --no-pager diff --stat template/
```

期待: 以下のファイル変更があること
- `template/.github/copilot-instructions.md`（B3 反映）
- `template/docs/principles.md`（B2 反映）
- `template/skills/feature-block-design/SKILL.md`（新規）

- [ ] **Step 3: 同期スクリプトを再実行して冪等性を確認する**

```bash
pwsh scripts/sync-template.ps1
git --no-pager status
```

期待: 2回目の実行後も `git status` の差分が変わらない（冪等）。

- [ ] **Step 4: コミット（Task 8 と合わせて）**

```bash
git add template.manifest template/
git commit -m "chore: sync template with feature-block-design and updated principles/instructions

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 10: README.md のスキル一覧に新スキルを追加する

**Files:**
- Modify: `README.md`（スキル表）

**依存:** Task 9

- [ ] **Step 1: スキル表に新スキルの行を追加する**

`README.md` の `## スキル` セクションの表を以下のように修正する。

変更前の該当行:

```markdown
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する |
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
```

変更後（間に1行追加）:

```markdown
| [`session-handoff`](skills/session-handoff/) | セッション間の作業引き継ぎファイル（ハンドオフ）を読む・作成する・更新する・確定する |
| [`feature-block-design`](skills/feature-block-design/) | brainstorming と writing-plans の間で、システムを機能ブロックに分割し分割仕様書を作成・更新する |
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
```

- [ ] **Step 2: 確認する**

```bash
git --no-pager diff README.md
```

期待: スキル表に1行追加のみ。他箇所に変更がない。

- [ ] **Step 3: コミット**

```bash
git add README.md
git commit -m "docs: list feature-block-design in README skill table

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 11: CONTRIBUTING.md にシナリオを追加する

**Files:**
- Modify: `CONTRIBUTING.md`

**依存:** Task 10

- [ ] **Step 1: シナリオセクションを末尾に追加する**

`CONTRIBUTING.md` の末尾（最後のシナリオの後）に以下を追加する:

```markdown

## シナリオ: 機能ブロック駆動の設計スキル（feature-block-design）を変更するとき

### 背景

`feature-block-design` は brainstorming と writing-plans の間に挟まる中間スキルで、システムを疎結合な機能ブロックに分割し、分割仕様書（`docs/specs/YYYY-MM-DD-<topic>/` 配下のディレクトリ分割形式）を作成・更新する役割を担う。

### 判定基準

以下に該当する場合に `feature-block-design` の変更を検討する:

- 適用要否判定のしきい値を見直す必要がある（実運用で過剰適用 / 適用漏れが目立つ）
- 機能ブロックの粒度ガイドラインを更新する必要がある
- 出力ディレクトリ構造を変更する必要がある
- brainstorming や writing-plans との責務境界を再定義する必要がある

### 手順

1. ADRを作成して変更理由を記録する（重要な変更の場合）
2. `skills/feature-block-design/SKILL.md` を更新する
3. brainstorming / writing-plans / start-work との責務重複を確認する
4. テンプレート対象なので `scripts/sync-template.ps1` を実行する

### チェックリスト

- 適用要否判定のしきい値が明示されているか
- スナップショット規約（差分仕様書を作らない）が守られる手順になっているか
- brainstorming スキルの "design for isolation and clarity" 指針と責務重複していないか
- 粒度ガイドラインがパラダイムを問わず適用可能な抽象度になっているか
```

- [ ] **Step 2: 確認する**

```bash
git --no-pager diff CONTRIBUTING.md
```

期待: 末尾に新シナリオセクションが追加されただけ。

- [ ] **Step 3: コミット**

```bash
git add CONTRIBUTING.md
git commit -m "docs(contributing): add scenario for modifying feature-block-design skill

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 12: ADR-0007〜0009 を Accepted 化する

**Files:**
- Modify: `docs/decisions/0007-introduce-feature-block-design-skill.md`
- Modify: `docs/decisions/0008-adopt-spec-directory-split-and-snapshot-rule.md`
- Modify: `docs/decisions/0009-extend-principle-2-scope.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 11（実装が一通り完了したことを確認したうえで Accepted にする）

- [ ] **Step 1: 3 つの ADR の Status を Proposed → Accepted に変更する**

各 ADR ファイルの先頭付近の `- **Status**: Proposed` を `- **Status**: Accepted` に置換する。

- [ ] **Step 2: ADR インデックスのステータス列も更新する**

`docs/decisions/README.md` の表で、0007 / 0008 / 0009 のステータス列を `Proposed` → `Accepted` に置換する。

- [ ] **Step 3: 確認する**

```bash
git --no-pager diff docs/decisions/
```

期待: 4ファイル（ADR 3本 + README）の Status / ステータス列のみが変更されている。

- [ ] **Step 4: コミット**

```bash
git add docs/decisions/
git commit -m "adr: accept 0007, 0008, 0009

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 13: ハンドオフを更新する（サブプロジェクトB完了反映）

**Files:**
- Modify: `docs/handoff/master.md`

**依存:** Task 12

- [ ] **Step 1: ハンドオフを更新する**

`docs/handoff/master.md` を以下の方針で書き換える（スナップショット規約のため、書き換えで更新）:

- `Last Updated`: 完了時の日付・時刻（Asia/Tokyo）
- `Status`: `paused`
- `Current Phase`: `サブプロジェクトA完了 / サブプロジェクトB完了 / サブプロジェクトC未着手（未定）`
- `## 完了済みタスク` にサブプロジェクトBの完了サマリ（追加した ADR-0007/0008/0009、新スキル `feature-block-design`、原則2拡張、copilot-instructions.md 追記、テンプレート同期、`feature/feature-block-design` を master に `--no-ff` マージ済み・push 済み）を追記する
- `## 進行中のタスク`: なし
- `## 未着手のタスク`: 次サブプロジェクトの提案（未定。別セッションで brainstorming）
- `## 既知のブロッカー・懸念`: 既存の `docs/conversation_log.md` / `docs/images/` の untracked 状態が残っているのは前回と同じ
- `## 次セッション開始時のアクション`: 「`start-work` を呼ぶ → ハンドオフを read → 次サブプロジェクトの brainstorming」を明記
- `## 重要な意思決定の履歴`: ADR-0007 / 0008 / 0009 を追加

- [ ] **Step 2: 確認する**

```bash
git --no-pager diff docs/handoff/master.md
```

期待: 上記の方針に沿った書き換えになっている。差分追記ではなく書き換えになっていること。

- [ ] **Step 3: コミット**

```bash
git add docs/handoff/master.md
git commit -m "chore: update handoff for sub-project B completion

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

### Task 14: master へマージし push する

**依存:** Task 13

- [ ] **Step 1: master にチェックアウトして最新化する**

```bash
git checkout master
git pull --ff-only origin master
```

- [ ] **Step 2: feature ブランチを `--no-ff` でマージする**

```bash
git merge --no-ff feature/feature-block-design -m "Merge branch 'feature/feature-block-design'

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

- [ ] **Step 3: master を push する**

```bash
git push origin master
```

期待: push が成功する。

- [ ] **Step 4: feature ブランチを削除する（任意）**

ユーザー確認の上、不要なら以下を実行:

```bash
git branch -d feature/feature-block-design
git push origin --delete feature/feature-block-design
```

不可逆操作なのでユーザー承認を得てから実行する。

---

## 完了基準

- 全 14 タスクの全ステップにチェックが入っている
- `docs/decisions/README.md` に ADR-0007 / 0008 / 0009 が Accepted で並んでいる
- `skills/feature-block-design/SKILL.md` が存在する
- `docs/principles.md` の原則2が拡張版になっている
- `.github/copilot-instructions.md` に「タスク構造」追記と「ドキュメント運用」セクションがある
- `template/` の同期が完全（再実行で差分ゼロ）
- README.md のスキル表に `feature-block-design` がある
- CONTRIBUTING.md にシナリオがある
- master ブランチに `--no-ff` マージ済み、origin に push 済み
- `docs/handoff/master.md` が「サブプロジェクトB完了」を反映している
