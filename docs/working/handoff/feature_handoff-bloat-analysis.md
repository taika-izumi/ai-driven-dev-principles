# Handoff: ハンドオフ肥大化の原因調査と対策検討

- **Branch**: feature/handoff-bloat-analysis
- **Last Updated**: 2026-08-14 19:52 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 対策実装/plan 確定済み（確定前レビューフル 3 観点・指摘反映済み）。subagent-driven-development で実装中

## 作業の目的・背景

LoopForAlpha（本ガイドラインの利用先プロジェクト）でハンドオフファイルの肥大化が実測され、防止策（ADR-0074〜0077）が増加側を制御していないことが判明した（原因は Issue-0078〜0081）。本サイクルは対策の設計と実装を行う。設計原則は「情報を削らず、置き場を直す」（ユーザー制約: 簡略化しすぎで引継ぎ後の作業精度を落とさない）。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-08-13-handoff-bloat-control/`（00/01/02 の 3 ファイル。確定済み。00 は plan の Task 6 Step 3 で現状化予定）
- Plan: `docs/working/plans/2026-08-14-handoff-bloat-control-plan.md`（確定済み。8 タスク・4 コミット）
- 関連 ADR: ADR-0086 / ADR-0087 / ADR-0088 / ADR-0089（いずれも Proposed。実装完了時に Accepted 昇格）、部分修正予定: ADR-0075
- 対象課題: Issue-0078〜0081（`docs/working/issues/flow/`）。派生起票: Issue-0082
- 本サイクルの割り込み決定: ADR-0085（質問ツール全面不使用。Accepted・実装済み）

## 完了済みタスク

- [x] LoopForAlpha のハンドオフ実測調査と課題起票（2026-08-13 完了。詳細は Issue-0078〜0081 が正本）
- [x] 割り込み対応: ADR-0085（Fable 5 での構造化質問ツール全面不使用）の決定・CLAUDE.md 改定・template 同期・確定前レビューフル実施（2026-08-13 完了。コミット `a278399` / `8774342`）
- [x] 対策の brainstorming と spec 確定（2026-08-13 完了。スコープ: Issue-0078〜0081 一括＋移設先標準定義。確定前レビューフル 3 観点＋差分再確認まで実施し、指摘全件反映。コミット `c022858` / `9e0f134` / `6585556`）

## 進行中のタスク

- [ ] **現在の作業**: plan の実装（subagent-driven-development・Task 1 から）
  - 状態: plan 確定・コミット済み。実装未着手
  - 残り: plan の Task 1〜8（詳細は plan が正本。レビュー反映で ADR-0080 注記・旧 spec (v)(vi)・spec 00 現状化が追加済み）

## 未着手のタスク

（plan の Task 1〜8 に集約。完了処理（ADR 昇格・Issue close）は plan Task 8）

## 既知のブロッカー・懸念

- master handoff の申し送りを継承（詳細は `docs/working/handoff/master.md` 参照）: 配布元は `dist/`（skills/ 編集だけでは動くスキルは変わらない・執行点 4 手順）/ スキル改定後は `/plugin marketplace update` 依頼 / inbox 3 件はユーザー手動移動予定で organize-inbox 提案不要 / push はユーザー指示待ち

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。

- 2026-08-13 LoopForAlpha ハンドオフ肥大化の原因調査完了: ADR=なし（調査のみで意思決定なし） / worklog=棄却（git 実測の定型手順のみで delta なし）
- 2026-08-13 原因 4 点を Issue-0078〜0081 として起票: ADR=なし（起票のみ。ADR-0021 の既定に従っただけ） / worklog=棄却（定型の起票作業で delta なし）
- 2026-08-13 ADR-0085 対応完了（質問ツール全面不使用への規範改定。spec 確定点 (c) 通過・提示は失念により事後実施）: ADR=0085 / worklog=`MakeAiInstructions-2026-08-13-01` / review=フル実施（claude-opus-5。指摘 16 件中 12 件採用、Issue-0082 起票）
- 2026-08-13 肥大化対策 spec 確定（spec 確定点 (b) 通過）: ADR=0086〜0089 起票（Proposed） / worklog=`MakeAiInstructions-2026-08-13-02` / review=フル実施（claude-opus-5 ×3。指摘 33 件全採用）＋差分再確認（claude-opus-5。反映 22/22・新規検出 5 件も修正済み）
- 2026-08-14 実装計画確定（plan 確定点通過）: ADR=なし（設計判断は ADR-0086〜0089 で確定済み。plan は spec の写像） / worklog=`MakeAiInstructions-2026-08-14-01` / review=フル実施（claude-opus-5 ×3。統合後 12 指摘全採用。ADR-0080 注記・旧 spec (v)(vi)・spec 00 現状化を plan へ追加）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ → plan `docs/working/plans/2026-08-14-handoff-bloat-control-plan.md`（チェックボックスで進捗確認）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:subagent-driven-development` で plan の未完了タスクから実装を再開
3. 留意点: 実装対象は配布対象ソース（記法規約の執行点 4 手順必須。plan 冒頭に記法規約の要点あり）。ADR 昇格・Issue close は plan Task 8。push はユーザー指示待ち

## 重要な意思決定の履歴

- ADR-0085: 事象確認済みモデルでは構造化質問ツールを使用しない（2026-08-13。割り込み対応・Accepted。ADR-0029 を Superseded 化）
- ADR-0086〜0089: 肥大化対策の設計 4 決定（2026-08-13。Proposed。移設標準 / サイズトリガー / 節別規範 / 配置定義とスキル手順の責務境界）
