---
name: decision-log
description: "重要な意思決定をADR（Architecture Decision Record）として記録・管理する。設計判断、プロセス決定、スコープ決定、方針決定を構造化して記録する。意思決定を検出した瞬間に呼ぶこと。実行中の他スキルの完了を待ってはならない。"
---

# decision-log

重要な意思決定をADR（Architecture Decision Record）として記録・管理するスキル。

## いつ使うか — 検出トリガー一覧

以下のいずれかを **検出した瞬間に**、現在実行中のスキル・タスクに関わらずこのスキルを呼び出すこと。「スキルの途中だから後で」は禁止。

### 強トリガー（必ず呼ぶ）

1. **複数案からの選択** — 2つ以上の選択肢を比較し1つを選んだとき
   - 例: brainstorming で 2-3 案から採用案を決めた直後
   - 例: writing-plans で技術スタックを選定した直後
2. **方針の変更** — 当初決めた方針・設計を覆したとき
   - 例: 実装中に「設計を変更する」と判断した瞬間
3. **アーキテクチャに影響する決定** — 層構成、モジュール境界、依存関係に関する判断
4. **スコープ・優先度の判断** — 「この機能は含める/含めない」「これを優先する」と決めたとき
5. **ガイドライン・ルールの追加・変更**
6. **既存の判断の変更** — 旧ADRを Superseded に更新し、新ADRを作成する

### 弱トリガー（自己評価して必要なら呼ぶ）

- 命名規則の決定
- ライブラリ・ツールの選定
- フォーマット・スタイルの決定

### 呼ぶ必要がない場面

- 自明な選択（迷いがなかったもの）
- 既存ADRに従っただけの判断
- 一時的な実装の詳細（後で変えても影響が限定的）

**判断基準**: 強トリガーに該当したら必ず作成。弱トリガーは「将来この判断の理由を知りたくなる可能性が中程度以上」なら作成。

## ADR作成手順

### 0. 検出を報告

ユーザーに以下のように通知する:

「意思決定を検出しました（トリガー: <該当した強/弱トリガー>）。ADRドラフトを作成します。」

### 1. 次の連番を決定する

`docs/records/decisions/README.md` のテーブルを確認し、最大番号+1を採番する。
テーブルが空なら `0001` から開始する。

### 2. ADRファイルを作成する

ファイル名: `docs/records/decisions/NNNN-slug.md`（NNNNは4桁ゼロ埋め連番、slugは英語のケバブケース）

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

> **記述規律（ADR-0019）**: ADRには「下した決定」のみを記載する。仕様検討の途中で生じた**未解決の論点（未決事項）は ADR に書かない**。未決事項は課題（`docs/working/issues/`）として分離する（後述「未決事項（open questions）の扱い」）。

### 3. インデックスを更新する

`docs/records/decisions/README.md` のテーブルに新しいエントリを追加する:

```
| [NNNN](NNNN-slug.md) | タイトル | Proposed | YYYY-MM-DD |
```

### 4. コミットする

ADRファイルとインデックスを一緒にコミットする:

```bash
git add docs/records/decisions/NNNN-slug.md docs/records/decisions/README.md
git commit -m "adr: NNNN - タイトル"
```

## 未決事項（open questions）の扱い

ADRは「下した決定」だけを記録する。仕様検討の議論中に増えていく未解決の論点（「これからこれを決めないといけない」「ここに課題が潜んでいる」）は ADR ではなく**課題（issue）**として `docs/working/issues/` で管理する。

### 起票

1. 未決事項を検出したら `docs/working/issues/system|flow/NNNN-<slug>.md` を起票する（Status: open）。分類は、対象システム固有の課題なら `system/`、開発の進め方・スキル・原則・ガイドラインに関する課題なら `flow/`（議論由来の未決事項は大半が `system/`）。連番はインデックス `docs/working/issues/README.md` 全体（両セクション）の最大番号+1。フォーマットは `docs/overview/folder-structure.md` の「課題（issue）管理」を参照
2. インデックス `docs/working/issues/README.md` の対応セクションに1行追加する

### ライフサイクル

1. その論点について意思決定を下したら、通常どおり ADR を作成する
2. ADR 化したら課題を close する: 課題ファイルの Status を `closed` に変更し、Closed 日付を記入し、「結論」セクションに ADR 番号を記載する。インデックスの Status も更新する
3. **クローズ済み課題は削除せずその場に残す**（追跡可能性の維持）

### 注意

- 課題ファイル・インデックスは template には同期されない（新規プロジェクトでは空のインデックスから始まる）
- 検討が長期化・多観点化した課題はフォルダへ昇格できる（`docs/overview/folder-structure.md` 参照）

## ADR更新手順

### ステータス変更

ADRのステータスを変更する場合（Deprecated、Superseded、いったん Accepted にした決定の見直しなど）:

1. 該当ADRファイルの `Status` を更新する（Deprecated, Superseded by ADR-XXXX 等）
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. 変更理由をADRのConsequencesセクションに追記する
4. コミットする

ただし、Proposed → Accepted への初回昇格は次の「承認の昇格」に従い、Consequences への追記は不要とする。

### 承認の昇格（Proposed → Accepted、ADR-0019）

ADRは**原則 Proposed で作成する**。Accepted への昇格は、その決定が確定（議論が収束）した**チェックポイント**で行う。作成直後に即 Accepted 化しないこと。議論の途中（とくに brainstorming 中）は決定が覆りうるため、Proposed のまま据え置く。

チェックポイントの目安:

| 決定の文脈 | Accepted へ昇格するチェックポイント |
|------------|-----------------------------------|
| brainstorming 起点の決定 | 設計承認時（ユーザーが設計案を承認したタイミング） |
| 実装を伴う決定 | 実装完了・検証後 |
| 上記に当てはまらない決定（純粋なスコープ・方針決定など） | ユーザーがその決定を確定したことを確認した時 |

昇格手順:

1. 該当ADRファイルの `Status` を `Accepted` に更新する
2. `docs/records/decisions/README.md` のテーブルのステータスも更新する
3. コミットする

`start-work` の Phase 2 Post でも、確定した据え置きADRの昇格漏れがないか確認される。

## ユーザーへの確認

ADR作成後（Proposed）、ユーザーに以下を提示する:

「ADR-NNNN を作成しました（Status: Proposed）。内容を確認して以下から選んでください:
- 確定 → この決定で確定済みなら Status を Accepted に昇格します
- 保留 → まだ議論中なら Proposed のまま据え置きます（後日チェックポイントで昇格）
- 修正依頼 → 該当箇所を修正します
- 却下 → ファイルとインデックスエントリを削除します」

探索・議論の最中（brainstorming 中など）は「保留」を既定とする。

ユーザー応答に応じて確定処理を実施する:
- 確定: 「承認の昇格」の手順で Status を Accepted へ → インデックスも更新 → コミット
- 保留: Proposed のまま。確定チェックポイントで改めて昇格させる
- 却下: ADRファイル削除 → インデックスエントリ削除 → コミット（理由を commit message に残す）
