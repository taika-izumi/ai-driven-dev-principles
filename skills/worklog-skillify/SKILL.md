---
name: worklog-skillify
description: "worklog-extract で採用された候補から、writing-skills 委譲で新規スキル作成または既存スキル拡張を行う。スコープ（汎用/プロジェクト固有/固有ルール）で成果物の配置先を振り分け、汎用パスを本 repo 以外で実行しようとした場合は警告する。ユーザーまたは worklog-extract から起動。"
---

# worklog-skillify

`worklog-extract` で採用された候補（Issue 草案＋根拠エントリ参照＋確定 scope）から、`writing-skills` へ委譲して新規スキル作成または既存スキル拡張を行う。薄いオーケストレーション層に留める。

## いつ使うか

- `worklog-extract` の採用候補を受けて起動（主用途）
- ユーザーが手動で起動（採用済み Issue から個別にスキル化する場合）

## 実行環境ガード

スキル冒頭で実行環境が本 repo（ai-driven-dev-principles）かを判定する:

- 判定マーカー: `git remote -v` の URL に `ai-driven-dev-principles` を含む、または `.claude-plugin/plugin.json` の `name` が `ai-driven-dev-principles`
- **汎用（プラグイン配信）パス かつ 本 repo でない**場合のみガード発火
- 固有パス（プロジェクトローカルスキル / CLAUDE.md 追記）はガード不要でそのまま進む

**ガード発火時の対応**（ユーザー確認）:

1. この場のプロジェクトローカルスキル（`.claude/skills/`）として作成する
2. 配信元 repo（ai-driven-dev-principles）へ移動して実行する
3. 中止する

## スコープ3分岐（振り分け）

`worklog-extract` が確定した scope に応じて成果物の配置先を決める:

| scope | 配置先 |
|-------|--------|
| **汎用**（複数プロジェクトで再現・ドメイン非依存） | 本 repo のプラグイン配信スキル `skills/<name>/` |
| **プロジェクト固有だが価値あり** | そのプロジェクトのローカルスキル `.claude/skills/<name>/` |
| **固有ルールでスキル化不要** | そのプロジェクトの `CLAUDE.md` に追記 |

## 手順

1. **実行環境ガード判定** → 必要なら警告＋ユーザー確認（上記 3 分岐）
2. **スコープで振り分け先決定**（上表）
3. **出所点検**（汎用スコープ、および本 repo（ai-driven-dev-principles）で実行し CLAUDE.md 追記へ振り分ける場合。本 repo の CLAUDE.md は template 経由で配布されるため）: 根拠エントリの出所プロジェクト数・モデル世代を数える。単一プロジェクトまたは単一モデル世代に偏る場合、CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」の是正パターン（適用例への降格 / 発動条件ゲート / 根拠と世代＋退役経路 / 見送り・スコープ降格）の適用をユーザーへ提示する（ADR-0079）
4. **writing-skills へ委譲**してスキルを作成/拡張する。`references/skill-authoring-techniques.md` を併用し、description 最適化と定量 eval ループを回す（**Skill Creator は実行時ロードしない**。ADR-0046 の設計時借用）
5. **汎用パスは既存フローへ橋渡し**: 「Issue → `extend-guidelines` → スキル作成」の本 repo 既存フローに合流させる
6. **台帳追記**: 作成/拡張完了後、`processed.jsonl` へ確定結果を追記する
   - `skillified`（新規スキル作成）または `merged`（既存スキルへ統合）を追記
   - 対応する `adopted` エントリの状態を確定させる（追記専用 JSONL のため後続レコードで遷移を表現）
   - 読み側（`worklog-extract`）は同一 id の最新レコードの `outcome` を採用する

## 対応する原則

- **原則2（関心の分離）**: 本スキルは薄いオーケストレーション層。実際のスキル authoring は `writing-skills` へ委譲する
- **原則4（人間の関与）**: 実行環境ガード発火時と汎用パス橋渡しの節目で人間が確認する

## 関連 ADR

- ADR-0044（スコープ3分岐・skill3 橋渡し）
- ADR-0045（台帳ライフサイクル・`adopted` 状態と遷移）
- ADR-0046（writing-skills 既定・Skill Creator 設計時借用・実行環境ガード）
- ADR-0079（出所点検）
