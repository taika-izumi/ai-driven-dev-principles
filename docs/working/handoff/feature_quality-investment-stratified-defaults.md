# Handoff: レビュー・品質投資の層別既定再設計＋反復コスト予算（Issue-0114/0103）

- **Branch**: feature/quality-investment-stratified-defaults
- **Last Updated**: 2026-08-31 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了（master へ --no-ff マージ `7afdd66`・retrospective・cycle-reset 済み。以後は `master.md` を参照）

## 作業の目的・背景

Issue-0114（品質・設計投資の限界効用の実測に基づく、レビュー・検査の既定の層別再設計）と Issue-0103（確定前レビュー反復の確定点あたりコスト・巡数の予算基準の不在）を合流させて対策設計するサイクル。

材料は Issue-0114 フォルダの委譲資料 6 ファイル（LFA#0117 の層別実測・コスト実測。約 86KB）と、Issue-0103 の検討状況に蓄積された本リポジトリ側のコスト実測。対策射程は確定前レビュー反復・変異検査・レビュー深度の既定の層別再設計＋予算基準の設計（正本の置き場・強度・単位は brainstorming で決める）。

## 関連ドキュメント

- Issue-0114: `docs/working/issues/flow/0114-quality-investment-marginal-utility-and-stratified-defaults/`（委譲資料 6 ファイル同梱）
- Issue-0103: `docs/working/issues/flow/0103-iteration-cost-budget-guideline-missing.md`
- 関連 Issue: Issue-0113（工程 2 型）/ Issue-0112（レビュー層の役割分担）/ Issue-0107（反復推奨規範の乖離。事例 10 まで）
- 関連 ADR: ADR-0107（反復基準）/ ADR-0117（4 観点化）/ ADR-0102（評価可能性）/ ADR-0119（計画逸脱既定）
- 拡張ルール: `CONTRIBUTING.md`（執行点 4 手順・過剰適合点検・評価可能性）

## 完了済みタスク

- [x] extend-guidelines → brainstorming → 設計確定（2026-08-30〜31）
- [x] ADR-0120 起草・確定前レビュー（フル 8 巡＋差分確認 1 巡＋機械検証・実質収束・設計縮小 2 回）・Proposed でコミット `55d199d`（2026-08-31 完了）
- [x] 実装計画の作成・確定前レビュー・確定（`docs/working/plans/2026-08-31-adr-0120-stratified-review-implementation.md`。1 体 4 観点兼務＝ADR-0120 新既定の先行適用 → 差分確認 1 巡 → 機械検証で実質収束。レビュー採用で ADR-0120 実装対象へ「根拠と世代」1 項目追記〈未コミット・plan Task 9 で同梱〉）（2026-08-31 完了）

## 進行中のタスク

（なし。サイクル完了）

## 未着手のタスク

（なし）

## 既知のブロッカー・懸念

- `docs/inbox/` 未整理 3 件＋`docs/conversation_log.md` は未追跡のまま（ユーザーが手動移動予定。`git add <ディレクトリ>` で巻き込まない）

## Post ラッパー消化記録

（形式は `skills/session-handoff/SKILL.md` 参照）

- 2026-08-31 ADR-0120 設計確定・spec 確定点 (c) 通過（コミット `55d199d`）: ADR=0120（Proposed でコミット） / worklog=`MakeAiInstructions-2026-08-31-01` / review=フル実施（claude-opus-5・8 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-31 セッション終了処理: ADR=なし（終了処理のみ） / worklog=`MakeAiInstructions-2026-08-31-02`（規範変更時の全記載箇所の同期漏れ 2 回の delta）
- 2026-08-31 実装計画の作成・確定・plan 確定点通過: ADR=0120（実装対象へ「根拠と世代」1 項目追記・Proposed 維持） / worklog=`MakeAiInstructions-2026-08-31-03` / review=フル実施（claude-opus-5・1 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-31 実装完了（コミット `d9b28d9`・全 9 タスク検証一致・逸脱ゼロ）・ADR-0120 Accepted 昇格: ADR=0120（Accepted。Issue-0103 close・Issue-0114 対策範囲追記） / worklog=棄却（delta なし。実装は plan 逐語どおり・昇格は既存手順どおり） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: `docs/working/handoff/master.md`（本ブランチのサイクルは完了。以後の状態は master handoff が正）
2. 最初に実行すべきコマンド/スキル: master ブランチで `start-work`
3. 留意点: 本ハンドオフは completed のまま残置する（アーカイブ機構なし）

## 重要な意思決定の履歴

（なし）
