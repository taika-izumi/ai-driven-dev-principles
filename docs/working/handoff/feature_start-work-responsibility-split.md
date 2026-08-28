# Handoff: start-work スキルの責務過多の解消

- **Branch**: feature/start-work-responsibility-split
- **Last Updated**: 2026-08-28 23:35 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了（master へ --no-ff で取り込み済み。マージコミット `5c1ac0e`。retrospective 実施済み: `docs/records/retrospectives/system/2026-08-29-start-work-responsibility-split.md`）

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
- [x] 実装完了（2026-08-28。plan Task 0〜10 全完了。検証 3 種〈diff・残存 grep・重複 grep〉全通過。plugin 0.1.13・執行点 4 手順・目視 5 点済み。コミット 1d1b0cd / 7102cb3）
- [x] サイズ・到達実測（2026-08-28。start-work 34,676B→14,456B・pre-finalization-review 30,394B・確定点到達セッション合計 44,850B・merge-practice.md 4,610B。start-work 新ポインタ表記どおり `references/merge-practice.md` の Read 解決・読了を 1 回確認＝パス解決の確認であり完了処理の発火経路の実走ではない）
- [x] サイクル全体整合検査（2026-08-28。ADR-0115/0116 実装前昇格の後追い検査。指摘 2 件〈spec Status 追従漏れ・16,772B→16,771B〉修正: 41087d1）
- [x] 実装の独立レビュー（2026-08-29。claude-opus-5・変更 32 ファイル全数走査。Critical 0・Important 1・Minor 5。採用 3 件反映: 8319204〈表記 2 件〉・6cbfa7e〈0067 除外確定の追補。ADR-0116 は改訂記録で対応〉。Minor 4〈merge-practice 導入文重複〉は plan 指定どおりの結果のため次サイクル送り）

## 進行中のタスク

（なし。サイクル完了。以後の作業状態は `docs/working/handoff/master.md` が正）

## 未着手のタスク

（なし）

## 既知のブロッカー・懸念

- docs/inbox/ に README 以外 3 件が滞留（organize-inbox 未実施。ユーザーは実装再開を優先）
- 未追跡の docs/conversation_log.md が作業ツリーに残存（本サイクルの成果物ではない。コミットに巻き込まないこと）

## Post ラッパー消化記録

- 2026-08-28 spec 確定点 (b) 通過・設計確定・ADR-0115/0116 Accepted 昇格: ADR=0115/0116 / worklog=`MakeAiInstructions-2026-08-28-01` / review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束） / cyclecheck=非該当（実装前昇格）
- 2026-08-28 plan 確定点 通過・実装計画確定: ADR=なし（新規決定なし。設計は ADR-0115/0116 で確定済み） / worklog=`MakeAiInstructions-2026-08-28-02` / review=フル実施（claude-opus-5・1 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-28 セッション終了（実装 Task 1 途中で中断）: ADR=なし（実装は計画の遂行のみ） / worklog=棄却（delta なし。実装 2 ステップは計画どおり）
- 2026-08-28 実装完了（plan Task 0〜10）＋サイクル全体整合検査: ADR=なし（計画の遂行のみ。検査指摘 2 件は追従修正） / worklog=棄却（delta なし。実装は計画どおり・検査指摘は既存検査工程が捕捉） / cyclecheck=実施（修正: 41087d1）
- 2026-08-29 実装レビュー完了・指摘反映（8319204 / 6cbfa7e）: ADR=なし（追従修正のみ。ADR-0116 本文改訂は改訂記録規定で対応済み） / worklog=`MakeAiInstructions-2026-08-29-01`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff → `git log --oneline -4`（実装コミット 1d1b0cd / 7102cb3 / 41087d1 を確認）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ superpowers:finishing-a-development-branch で完了処理（実行直前に `skills/start-work/references/merge-practice.md` の慣行判定を適用）→ マージ後 retrospective
3. 留意点: 未追跡の docs/inbox/ 3 件・docs/conversation_log.md をコミットに巻き込まない。マージ後の retrospective では本サイクルから取り込み方式欄の記録規約（ADR-0106）を適用する

## 重要な意思決定の履歴

- ADR-0115: start-work 責務過多の解消サイクルは分割の実施に集中し、SKILL.md サイズ・分割の一般規範は扱わない（2026-08-28 Accepted）
- ADR-0116: start-work のドメイン規範 2 節は責務帰属で移設し、提示規則は pre-finalization-review へ・マージ方式確認は references へ移す（2026-08-28 Accepted）
