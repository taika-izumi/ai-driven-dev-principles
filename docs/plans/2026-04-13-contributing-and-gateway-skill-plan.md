# CONTRIBUTING.md & extend-guidelines Skill 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新セッションのAIエージェントが設計思想と拡張ルールを自律的に把握できる仕組みを構築する

**Architecture:** CONTRIBUTING.md（単一ソース）+ extend-guidelines Skill（ゲートウェイ）の2層構成。Skillが CONTRIBUTING.md を読み込み、brainstorming skill へ自動接続する。

**Tech Stack:** Markdown, Copilot Skills (YAML frontmatter + Markdown)

---

### Task 1: CONTRIBUTING.md を作成する

**Files:**
- Create: `CONTRIBUTING.md`

**依存:** なし

- [ ] **Step 1: CONTRIBUTING.md を作成する**

以下の内容で `CONTRIBUTING.md` を作成する:

```markdown
# ガイドライン拡張の手引き

このドキュメントは、このリポジトリのメタ・ガイドラインを拡張・変更する際のルールと手順をまとめたものである。
拡張作業を行う前に、まずこのドキュメント全体を読み、設計思想を把握すること。

> **推奨:** 拡張作業には `extend-guidelines` スキルを使用すること。このスキルは本ドキュメントの読み込みからbrainstormingまでを自動的にガイドする。

## 設計思想

このリポジトリは、AIエージェントを活用したシステム開発のためのメタ・ガイドラインを3層のレイヤード方式で管理している。

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | `docs/principles.md` | ツール非依存の普遍的原則 |
| Layer 2 | `.github/copilot-instructions.md` | Copilot固有の行動指示 |
| Layer 3 | `skills/` | 自動化されたワークフロー |

核心的な設計原則:

- **各層は独立して拡張可能** — 原則を追加しても、即座に全層へ反映する必要はない。必要になった時点で下位層へ展開する
- **リスクスケーリング** — 原則1-3（追跡可能性・関心の分離・コンテキスト管理）は常時適用。原則4-5（人間の関与・漸進的検証）はリスクに応じてスケールする
- **具体性の勾配** — Layer 1は抽象的・汎用的。Layer 3に向かうほど具体的・自動化される

拡張したい場合は、以下のシナリオから該当するものを読むこと。

## シナリオ: 原則を追加・変更するとき

### 判定基準

以下のいずれかに該当する場合、新しい原則の追加を検討する:

- 複数のプロジェクトで繰り返し同じ失敗パターンまたは成功パターンが観察された
- 既存の5原則でカバーできない新しい関心事が生まれた
- 「ルール」ではなく「なぜそうすべきか」を説明できるレベルの抽象度がある

### 手順

1. ADRを作成して追加理由を記録する（`decision-log` スキルを使用）
2. `docs/principles.md` に原則を追加する
3. 前文のリスクスケーリング注記を更新する必要があるか確認する
4. 必要に応じてLayer 2・3への反映を検討する（即座の全層対応は不要）

### チェックリスト

- 既存原則と重複・矛盾していないか
- ツール非依存の表現になっているか（Layer 1の要件）
- リスクスケーリングの分類（常時適用 or リスク比例）を決めたか

## シナリオ: copilot-instructions.md を更新するとき

### レイヤー対応規則

- Layer 2はLayer 1の原則を **Copilot固有の行動指示に変換したもの** である
- 各原則 → `copilot-instructions.md` の対応セクションへ1:1でマッピングされている
- 新しい原則を追加した場合、対応するセクションの追加を検討する

### 判定基準

以下に該当するものを `copilot-instructions.md` に記述する:

- セッション横断で **常に** 適用したい行動規範
- Copilot特有の設定（言語、応答スタイル等）
- Skill化するほど複雑ではないが、毎回伝えたい指示

### 注意事項

- **他プロジェクトへの流用前提** で書くこと。プロジェクト固有の参照（ファイルパス等）を含めない
- カテゴリ構成（システム設定 / メタ・ガイドライン）を維持する
- 記述言語は日本語で統一する（plugin注入部分は除く）

## シナリオ: Skillを新規作成するとき

### Skill化の判定

| 観点 | copilot-instructions.md に書く | Skill にする |
|------|-------------------------------|-------------|
| 複雑さ | 数行で表現できる | 手順・分岐・テンプレートがある |
| 発動条件 | 常時適用 | 特定の状況でのみ必要 |
| 自律性 | 判断基準の提示 | ワークフローの自動化 |
| 例 | 「変更前にログを残せ」 | ADR作成の完全な手順とテンプレート |

### 手順

1. 上の判定表でSkill化が適切か確認する
2. `skills/<skill-name>/SKILL.md` を作成する（YAMLフロントマター + markdown本文）
3. 対応する原則との紐付けをSkill内に記載する
4. ADRで作成理由を記録する

### チェックリスト

- `copilot-instructions.md` の記述で十分ではないか（YAGNI確認）
- Skill名が動作を端的に表しているか
- YAML frontmatter（`name`, `description`）が正しいか
- 対応する原則への参照があるか

## シナリオ: ADRを記録するとき

### 判定基準

以下のいずれかに該当する場合、ADRを作成する:

- 原則の追加・変更・削除
- アーキテクチャ（層構成）に影響する変更
- 既存の方針を覆す判断をしたとき
- 複数の選択肢を検討し、選択理由を残す価値があるとき

### 手順

`decision-log` スキルに従うこと。フォーマット・採番・コミット手順はすべてスキル内に定義されている。
```

- [ ] **Step 2: 作成した内容を確認する**

`CONTRIBUTING.md` を開き、以下を確認する:
- 5つのセクション（設計思想 + 4シナリオ）がすべて含まれている
- マークダウンのフォーマットが正しい
- 仕様書のすべての要件がカバーされている

- [ ] **Step 3: コミットする**

```bash
git add CONTRIBUTING.md
git commit -m "docs: add CONTRIBUTING.md for guideline extension rules"
```

---

### Task 2: extend-guidelines Skill を作成する

**Files:**
- Create: `skills/extend-guidelines/SKILL.md`

**依存:** Task 1（CONTRIBUTING.md が存在すること）

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p skills/extend-guidelines
```

- [ ] **Step 2: SKILL.md を作成する**

以下の内容で `skills/extend-guidelines/SKILL.md` を作成する:

```markdown
---
name: extend-guidelines
description: "ガイドラインの拡張（原則追加・Skill作成・copilot-instructions更新）を行う際のゲートウェイ。CONTRIBUTING.mdを読み込み、brainstormingへ接続する。"
---

# extend-guidelines

メタ・ガイドラインの拡張作業を自動的にガイドするゲートウェイスキル。

## 手順

### 1. CONTRIBUTING.md を読み込む

まず、リポジトリルートの `CONTRIBUTING.md` を読み込み、設計思想と拡張ルールを把握すること。

このファイルが見つからない場合は、ユーザーに以下を報告して作業を中断する:
「`CONTRIBUTING.md` が見つかりません。拡張ルールの参照元が存在しないため、作業を開始できません。」

### 2. 拡張内容をヒアリングする

ユーザーに「何を拡張したいか」を確認する。以下の選択肢を提示すること:

- 原則を追加・変更したい
- copilot-instructions.md を更新したい
- 新しいSkillを作成したい

### 3. 該当シナリオを確認する

CONTRIBUTING.md の該当シナリオセクションを読み、判定基準・手順・チェックリストを確認する。
ユーザーの要望が判定基準に合致するか検証し、合致しない場合はその旨を伝える。

### 4. brainstorming を開始する

ユーザーの要望と CONTRIBUTING.md の拡張ルールをコンテキストとして保持したまま、brainstorming スキルを呼び出す。brainstorming では以下を念頭に置く:

- CONTRIBUTING.md の判定基準とチェックリストを設計の制約として扱う
- 既存の原則・指示・スキルとの整合性を確認する
- ADRの作成が必要かどうかを判断する（CONTRIBUTING.md「ADRを記録するとき」セクション参照）
```

- [ ] **Step 3: 作成した内容を確認する**

`skills/extend-guidelines/SKILL.md` を開き、以下を確認する:
- YAML frontmatter（name, description）が正しい
- 4段階のフローがすべて含まれている
- CONTRIBUTING.md へのパス参照が正しい
- brainstorming skill への遷移指示がある
- フォールバック（CONTRIBUTING.md が見つからない場合）がある

- [ ] **Step 4: コミットする**

```bash
git add skills/extend-guidelines/SKILL.md
git commit -m "feat: add extend-guidelines gateway skill (Layer 3)"
```

---

### Task 3: README.md を更新する

**Files:**
- Modify: `README.md`

**依存:** Task 1, Task 2

- [ ] **Step 1: スキルテーブルに extend-guidelines を追加する**

`README.md` のスキルテーブル（現在2行）に以下の行を追加する:

```markdown
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |
```

- [ ] **Step 2: 成長サイクルセクションを更新する**

現在の「成長サイクル」セクションの内容を、CONTRIBUTING.md と extend-guidelines Skill の存在を反映して更新する。具体的には:

現在:
```markdown
## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `docs/principles.md` に新しい原則を追記する
3. `copilot-instructions.md` に対応する行動指示を追加する
4. 必要ならスキルを作成する
5. ADRに「なぜこの原則を追加したか」を記録する
```

変更後:
```markdown
## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `extend-guidelines` スキルを実行し、拡張作業を開始する
3. スキルのガイドに従い、原則・行動指示・スキルを追加する

詳細な拡張ルールと判定基準は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。
```

- [ ] **Step 3: 更新内容を確認する**

`README.md` を開き、以下を確認する:
- スキルテーブルに3行（decision-log, pre-action-review, extend-guidelines）が存在する
- 成長サイクルが更新され、CONTRIBUTING.md へのリンクがある
- 既存の内容が壊れていない

- [ ] **Step 4: コミットする**

```bash
git add README.md
git commit -m "docs: update README with extend-guidelines skill and CONTRIBUTING.md link"
```

---

### Task 4: ADR を作成する

**Files:**
- Create: `docs/decisions/0002-add-contributing-and-gateway-skill.md`
- Modify: `docs/decisions/README.md`

**依存:** Task 1, Task 2, Task 3

- [ ] **Step 1: ADR ファイルを作成する**

以下の内容で `docs/decisions/0002-add-contributing-and-gateway-skill.md` を作成する:

```markdown
# ADR-0002: コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加

- **Status**: Proposed
- **Date**: 2026-04-13

## Context

新しいセッションのAIエージェントは会話履歴を持たないため、このリポジトリの設計思想（3層アーキテクチャ、リスクスケーリング、独立拡張性）や拡張ルール（原則追加の基準、Skill化の判定基準等）を把握できない。README.mdの「成長サイクル」セクションは手順の概要のみで、判断基準が不足していた。

## Considered Alternatives

1. **README.mdに詳細な拡張ガイドを追記する** — README.mdが肥大化し、プロジェクト概要としての役割が薄れる
2. **copilot-instructions.mdにCONTRIBUTING.mdへの参照を追加する** — copilot-instructions.mdの他プロジェクトへの流用性が損なわれる
3. **CONTRIBUTING.md + ゲートウェイSkillの2層構成** — 情報の単一ソース（CONTRIBUTING.md）とSkillによる自動ガイドで、発見性と流用性の両立を実現する

## Decision

選択肢3を採用する。CONTRIBUTING.mdをシナリオ駆動型（やりたいことベースで逆引き）で構成し、extend-guidelinesスキルをゲートウェイとしてCONTRIBUTING.mdの読み込みからbrainstormingへの接続を自動化する。

## Consequences

- 新セッションのエージェントがextend-guidelinesスキルを実行するだけで、設計思想の把握から拡張作業の開始まで自動的にガイドされる
- CONTRIBUTING.mdが拡張ルールの単一ソースとなり、情報の二重管理を回避できる
- copilot-instructions.mdの流用性は維持される（プロジェクト固有の参照を含まない）
- CONTRIBUTING.md自体のメンテナンスが必要になる（新しいシナリオの追加等）
```

- [ ] **Step 2: ADR インデックスを更新する**

`docs/decisions/README.md` のテーブルに以下の行を追加する:

```markdown
| [0002](0002-add-contributing-and-gateway-skill.md) | コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加 | Proposed | 2026-04-13 |
```

- [ ] **Step 3: コミットする**

```bash
git add docs/decisions/0002-add-contributing-and-gateway-skill.md docs/decisions/README.md
git commit -m "adr: 0002 - コンテキスト継続性のためのCONTRIBUTING.mdとゲートウェイSkillの追加"
```

---

### Task 5: 実装計画をコミットする

**Files:**
- 既存: `docs/plans/2026-04-13-contributing-and-gateway-skill-plan.md`（このファイル）

**依存:** なし（他タスクと並行可能）

- [ ] **Step 1: コミットする**

```bash
git add docs/plans/2026-04-13-contributing-and-gateway-skill-plan.md
git commit -m "docs: add implementation plan for CONTRIBUTING.md and gateway skill"
```

---

### Task 6: 最終検証

**依存:** Task 1, 2, 3, 4, 5

- [ ] **Step 1: ディレクトリ構造を確認する**

```bash
find . -type f -not -path './.git/*' | sort
```

以下のファイルが新規追加されていること:
- `CONTRIBUTING.md`
- `skills/extend-guidelines/SKILL.md`
- `docs/decisions/0002-add-contributing-and-gateway-skill.md`
- `docs/plans/2026-04-13-contributing-and-gateway-skill-plan.md`
- `docs/specs/2026-04-13-contributing-and-gateway-skill-design.md`

以下のファイルが更新されていること:
- `README.md`
- `docs/decisions/README.md`

- [ ] **Step 2: Git状態を確認する**

```bash
git status
git log --oneline -10
```

ワーキングツリーがクリーンであること。Task 1-5のコミットがすべて存在すること。

- [ ] **Step 3: CONTRIBUTING.md と SKILL.md の整合性を確認する**

CONTRIBUTING.md の全シナリオが、extend-guidelines Skill のフロー（ステップ2の選択肢）でカバーされていることを確認する。
