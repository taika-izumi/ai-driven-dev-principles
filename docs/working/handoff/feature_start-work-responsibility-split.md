# Handoff: start-work スキルの責務過多の解消

- **Branch**: feature/start-work-responsibility-split
- **Last Updated**: 2026-08-28 04:15 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ガイドライン拡張/実装中（plan Task 1 の途中で中断）

## 作業の目的・背景

start-work スキルが責務過多ではないかという指摘を受け、分析の結果、妥当と判定した（2026-08-28）。SKILL.md は 34.7KB で全 13 スキル中最大。本来のオーケストレーション責務（Phase -1〜2・横断的ラッパー・終了処理）に加え、「確定前レビューの提示規則」（バイト実測で本文の約 49%）と「完了処理のマージ方式確認」（約 12%）というドメイン規範の正本を抱えており、毎セッション冒頭で全文が読まれるため確定点に到達しないセッションでもコンテキスト費用を払っている。Issue-0105 が同じ偏りを実測済み。

本サイクルでは、責務の分割単位と正本の移設先（pre-finalization-review 側へ移すか、references/ への遅延読み込みか等）を brainstorming で設計し、改修を実施する。制約: 条文複写の禁止（正本ごと移して参照を張り替える。Issue-0093 で統合した二重定義を再導入しない）。分割後の責務境界を将来の追記者が迷わない形で明文化することも設計項目。

## 関連ドキュメント

- Issue-0105: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`（SKILL.md サイズ・分割規範が無い。open）
- Issue-0101: `docs/working/issues/flow/0101-start-work-spec-figure-drift.md`（旧設計仕様書の図示乖離。open）
- Issue-0093: `docs/working/issues/flow/0093-integrate-22-duplicated-norm-records.md`（二重定義 22 行の統合。closed。複写禁止の根拠）
- 監査記録: `docs/records/audits/2026-08-16-guideline-process-audit/report.md`（クラスタ一覧 1-6）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検＝ADR-0079、新設の評価可能性＝ADR-0102、執行点 4 手順）

## 完了済みタスク

- [x] 責務過多の指摘の妥当性分析（2026-08-28。バイト実測: 提示規則≈49% / マージ方式確認≈12%）
- [x] brainstorming（設計 4 節をユーザー承認）・ADR-0115/0116 ドラフト作成（Proposed・未コミット）・feature-block-design 非該当判定（2026-08-28）
- [x] spec 作成・確定前レビュー第 1 巡（フル 3 観点・claude-opus-5・指摘 19 件中 18 採用 1 不採用）・改訂 v2 適用（2026-08-28）
- [x] spec 確定（2026-08-28。v4・反復通算フル 2 巡＋差分確認 1 巡＋機械検証 1 回・実質収束。ADR-0115/0116 Accepted 昇格）
- [x] 実装計画確定（2026-08-28。plan v3・反復通算フル 1 巡＋差分確認 1 巡＋機械検証 1 回・実質収束。ADR 全数走査 7 件・検証 4 本の期待値 21 箇所実測突合済み）

## 進行中のタスク

- [ ] **現在の作業**: 実装（plan の Task 0〜10。executing-plans でインライン実行中）
  - 状態: Task 0 完了（移設 2 節を `~/.ai-dev-review-snapshots/2026-08-28-start-work-responsibility-split/impl-base/` へ退避。4,270B / 16,771B で期待値一致・ベースライン grep 一致）。Task 1 は Step 1-1 完了＝`skills/start-work/references/merge-practice.md` 作成済み（**未追跡・未コミット**）。**Step 1-2（許容差分 2 箇所の置換: 「本節」→「本ファイル」・L87 相当の start-work 構造参照のファイル跨ぎ化）は未適用**
  - 残り: plan の Task 1 Step 1-2 から再開 → Task 2〜10 → 実装完了時に ADR-0115/0116 のサイクル全体整合検査（実装前昇格の後追い検査）。実装中は skills/ をコミットしない（Task 10 で dist・version bump と同一コミット）

## 未着手のタスク

- [ ] 分割設計の確定（spec 確定点で確定前レビュー提示）
- [ ] 実装計画の作成（plan 確定点で確定前レビュー提示）
- [ ] 改修の実施（執行点 4 手順・plugin version bump 対象）

## 既知のブロッカー・懸念

- 条文複写の禁止: 提示規則・マージ方式確認を移す場合は正本ごと移し、start-work 側はポインタのみにする（Issue-0093 の統合を再導入しない）
- 参照配線の張り替え範囲: session-handoff・pre-finalization-review・decision-log・AGENTS.md が start-work の節を参照しており、移設時は全参照の更新が必要
- 配布対象ソースに触れるため執行点 4 手順・plugin version bump（現行 0.1.12）・過剰適合点検＋新設の評価可能性が必須

## Post ラッパー消化記録

- 2026-08-28 spec 確定点 (b) 通過・設計確定・ADR-0115/0116 Accepted 昇格: ADR=0115/0116 / worklog=`MakeAiInstructions-2026-08-28-01` / review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束） / cyclecheck=非該当（実装前昇格）
- 2026-08-28 plan 確定点 通過・実装計画確定: ADR=なし（新規決定なし。設計は ADR-0115/0116 で確定済み） / worklog=`MakeAiInstructions-2026-08-28-02` / review=フル実施（claude-opus-5・1 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-28 セッション終了（実装 Task 1 途中で中断）: ADR=なし（実装は計画の遂行のみ） / worklog=棄却（delta なし。実装 2 ステップは計画どおり）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff → plan `docs/working/plans/2026-08-28-start-work-responsibility-split-implementation.md`（Task 1 Step 1-2 から再開）。`skills/start-work/references/merge-practice.md` が未追跡で存在する（Step 1-1 済み・Step 1-2 未適用）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ 継続 Yes → superpowers:executing-plans で plan の Task 1 Step 1-2 から続行
3. 留意点: 実装中は skills/ をコミットしない（Task 10 で version bump・dist 再生成と同一コミット。執行点 4 手順）。移設前の 2 節の原文は `~/.ai-dev-review-snapshots/2026-08-28-start-work-responsibility-split/impl-base/` に退避済み（喪失時は `git show HEAD:skills/start-work/SKILL.md`）。各編集は plan の「前」引用文と実体の一致を確認してから適用する

## 重要な意思決定の履歴

- ADR-0115: start-work 責務過多の解消サイクルは分割の実施に集中し、SKILL.md サイズ・分割の一般規範は扱わない（2026-08-28 Accepted）
- ADR-0116: start-work のドメイン規範 2 節は責務帰属で移設し、提示規則は pre-finalization-review へ・マージ方式確認は references へ移す（2026-08-28 Accepted）
