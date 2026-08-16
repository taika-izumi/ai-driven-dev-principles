# Handoff: Issue-0096 評価可能性の義務化の CONTRIBUTING 規範化

- **Branch**: feature/issue-0096-evaluability-brake
- **Last Updated**: 2026-08-17 01:30 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 課題対策/完了処理（実装・検証・Accepted 昇格・Issue close 済み。残りはマージ判断）

## 作業の目的・背景

ADR-0101 決定 3 で確定した「評価可能性の義務化（弱い形）」を CONTRIBUTING へ規範化する（Issue-0096 の実装）。配置・文言・発火経路は ADR-0102 で決定（spec 確定点 (c) フルレビュー 3 観点実施・指摘反映済み）。

## 関連ドキュメント

- 課題: `docs/working/issues/flow/0096-generalize-evaluability-brake-for-extensions.md`
- 決定: ADR-0102（配置・文言・発火フック。設計文書を兼ねる）/ 上流: ADR-0101 決定 3
- 監査記録（数値の正本）: `docs/records/audits/2026-08-16-guideline-process-audit/ledger.md`

## 完了済みタスク

- [x] ADR-0102 ドラフト作成・3 観点フルレビュー（claude-opus-5）・指摘反映・コミット `069cdac`（2026-08-16）
- [x] 実装: CONTRIBUTING 新節＋チェックリスト 7 行＋記述規律 1 行 / decision-log ポインタ / ADR-0101 誤記修正 92→95 / 執行点 4 手順・version 0.1.7（`5b73537`）（2026-08-16）
- [x] ADR-0102 Accepted 昇格・Issue-0096 close（`70b86dc`。サイクル全体整合検査 指摘なし）（2026-08-16）
- [x] 確定前レビューの反復（第 2〜4 巡。ユーザー指示）: `2812ba5` / `5a8c5a3` / `a550321` で指摘反映、第 4 巡で Critical/Major 0 の収束判定。Issue-0098 起票（反復の発動基準・`45be3cd`）と反復実測の記録（2026-08-16）

## 進行中のタスク

- [ ] **現在の作業**: サイクル完了処理
  - 状態: 実装・検証・昇格・close 済み
  - 残り: master への --no-ff マージ（ユーザー判断）→ retrospective → cycle-reset → push 判断

## 未着手のタスク

- [ ] マージ（--no-ff）・retrospective・handoff finalize

## 既知のブロッカー・懸念

- `skills/` に触れるため執行点 4 手順＋plugin version bump が必要（ADR-0102 Consequences）
- inbox 残置 3 件＋ conversation_log.md はユーザー手動移動予定。`git add` で巻き込まない（Issue-0020）

## Post ラッパー消化記録

- 2026-08-16 ADR-0102 設計確定・spec 確定点 (c) 通過: ADR=0102 / worklog=棄却（指摘の検出は pre-finalization-review 既存スキルで実施済み・追加 delta なし） / review=フル実施（claude-opus-5）
- 2026-08-16 Issue-0096 実装完了・ADR-0102 Accepted 昇格: ADR=0102（新規なし） / worklog=棄却（既存スキル・規範の手順どおりで delta なし） / cyclecheck=実施（指摘なし）
- 2026-08-16 確定前レビュー反復（第 2〜4 巡）完了・収束: ADR=0102 改訂（新規なし。Issue-0098 起票） / worklog=棄却（反復の実測は Issue-0098 検討状況へ記録済み） / review=フル実施（claude-opus-5。計 4 巡・第 4 巡で Critical/Major 0） / cyclecheck=実施（修正: `2812ba5`〜`a550321` はレビュー指摘由来。再点検・逐語一致・生成器 -Check 通過を各コミットで確認）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: ADR-0102（実装内容の正本）と本 handoff の「進行中のタスク」
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: 配布対象ソース（skills/）変更のため執行点 4 手順（`CONTRIBUTING.md`）と version bump（ADR-0090）を忘れない

## 重要な意思決定の履歴

- ADR-0102: 評価可能性の義務化（弱い形）は CONTRIBUTING「全シナリオ共通」新節と発火フックの配線で規範化する（2026-08-16 Proposed）
