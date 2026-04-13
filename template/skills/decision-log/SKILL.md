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
