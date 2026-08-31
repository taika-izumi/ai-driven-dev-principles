# Handoff: SKILL.md サイズ・分割規範の設計（Issue-0105）＋ merge-practice 導入文重複の解消（Issue-0111）

- **Branch**: feature/issue-0105-skill-size-norm
- **Last Updated**: 2026-08-31 19:15 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 新規開発・改修/brainstorming 前（作業意図の確定まで完了）

## 作業の目的・背景

主テーマは Issue-0105（flow）: スキルファイルにサイズの目安値・分割/移設の規約が無く、規範追加が常に既存スキルへの追記になる問題への対処。ADR-0120 実装で `skills/pre-finalization-review/SKILL.md` が 41,539B に達し、start-work の分割前サイズ（34,676B）を超過。前サイクルが予告した「分割判断の発生条件」が成立した状態。サイズ・分割の一般規範の設計と、（設計結果次第で）pre-finalization-review の分割実施を行う。

同梱テーマは Issue-0111（system）: `skills/start-work/references/merge-practice.md` 冒頭の導入文が移設条文の書き出しと重複（軽微・機能影響なし）。0105 の分割実施が配布物変更＋version bump を伴うため、同じく配布対象の 0111 を相乗りさせ、執行点 4 手順・bump を 1 回で済ませる（2026-08-31 ユーザー選択）。

## 関連ドキュメント

- 主課題: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`
- 同梱課題: `docs/working/issues/system/0111-merge-practice-duplicate-intro.md`
- 分割の先行実例: ADR-0115/0116（start-work の責務分割。34,676B → 14,456B）
- 類例規範: ADR-0087（handoff 側のサイズ実測トリガー。session-handoff スキル）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検・評価可能性・執行点 4 手順）

## 完了済みタスク

（なし）

## 進行中のタスク

- [ ] **現在の作業**: 作業意図の確定・ブランチ作成まで完了
  - 状態: feature ブランチ作成・handoff 新規作成済み
  - 残り: brainstorming（サイズ規範の設計論点の洗い出し）から着手

## 未着手のタスク

- [ ] Issue-0105: brainstorming → （必要なら feature-block-design 判定）→ 設計確定 → ADR → 実装（規範の常設先の改定＋pre-finalization-review の分割判断）
- [ ] Issue-0111: merge-practice.md 導入文の絞り込み修正（条文本体は触らない）
- [ ] 配布反映: 執行点 4 手順＋version bump（0.1.16 → 次版）を 1 回で実施

## 既知のブロッカー・懸念

- **配布元は `dist/`**（ADR-0082）。`skills/` 編集後は `scripts/build-dist.ps1` で再生成し生成物も同じコミットへ。ルート `.agents/plugins/marketplace.json` も生成物
- **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
- **確定点では 2 型分類の凍結＋確定前レビュー提示**（ADR-0080/0107/0117/0120）。本テーマは規範文の新設を含むため規範改定型（観点分離 4 体）になる見込み
- **計画作成・実装着手の直前に `skills/start-work/references/plan-deviation-defaults.md` を読む**（ADR-0119）
- inbox 未整理 3 件＋conversation_log 未追跡はユーザーが手動移動予定（organize-inbox 提案不要）。`git add` はディレクトリ巻き込み禁止・pathspec 付き（Issue-0020）

## Post ラッパー消化記録

（なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ brainstorming の続きへ
3. 留意点: 分割の先行実例は ADR-0115/0116。サイズ規範は「実測トリガー型」（ADR-0087 の handoff 規範）が類例

## 重要な意思決定の履歴

（なし）
