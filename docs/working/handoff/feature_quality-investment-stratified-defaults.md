# Handoff: レビュー・品質投資の層別既定再設計＋反復コスト予算（Issue-0114/0103）

- **Branch**: feature/quality-investment-stratified-defaults
- **Last Updated**: 2026-08-31 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ガイドライン拡張/設計確定（ADR-0120 コミット済み）。次は writing-plans

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

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の作成（superpowers:writing-plans）
  - 状態: 未着手。設計は ADR-0120 で確定済み（実装対象一覧は同 ADR Consequences が正）
  - 残り: 計画作成直前に `skills/start-work/references/plan-deviation-defaults.md` を読む（ADR-0119）→ writing-plans → plan 確定点で確定前レビュー提示 → 実装

## 未着手のタスク

- [ ] 実装（skills/pre-finalization-review・session-handoff・spec 2026-08-05・ADR 注記 4 本。執行点 4 手順・version bump 0.1.15→次版）
- [ ] Accepted 昇格時: Issue-0103 close・Issue-0114 検討状況追記

## 既知のブロッカー・懸念

- master ハンドオフ（`docs/working/handoff/master.md`）の未コミット更新（push 記録）が作業ツリーに残っている。次のコミット時に pathspec 指定で同時にコミットする
- `docs/inbox/` 未整理 3 件＋`docs/conversation_log.md` は未追跡のまま（ユーザーが手動移動予定。`git add <ディレクトリ>` で巻き込まない）

## Post ラッパー消化記録

（形式は `skills/session-handoff/SKILL.md` 参照）

- 2026-08-31 ADR-0120 設計確定・spec 確定点 (c) 通過（コミット `55d199d`）: ADR=0120（Proposed でコミット） / worklog=`MakeAiInstructions-2026-08-31-01` / review=フル実施（claude-opus-5・8 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-31 セッション終了処理: ADR=なし（終了処理のみ） / worklog=`MakeAiInstructions-2026-08-31-02`（規範変更時の全記載箇所の同期漏れ 2 回の delta）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ → ADR-0120（設計の正本。実装対象一覧は Consequences）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:writing-plans` で実装計画作成（出力先は `docs/working/plans/`。**着手直前に `skills/start-work/references/plan-deviation-defaults.md` を読み、計画へ宣言欄を置く**〈ADR-0119〉）
3. 留意点: plan 確定点で確定前レビュー提示（当該 plan は ADR-0120 の写像＝現行規範では推奨判定が偽の見込み。ADR-0120 設計の自己適用も判断材料に）・配布対象変更時は執行点 4 手順＋version bump（現行 0.1.15）・規範文の変更時は同内容の全記載箇所を先に grep 列挙（worklog `-02` の教訓）

## 重要な意思決定の履歴

（なし）
