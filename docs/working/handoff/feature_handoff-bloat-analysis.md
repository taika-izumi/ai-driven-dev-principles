# Handoff: ハンドオフ肥大化の原因調査と対策検討

- **Branch**: feature/handoff-bloat-analysis
- **Last Updated**: 2026-08-13 21:10 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 対策検討/spec 確定済み（確定前レビュー・差分再確認まで完了）。writing-plans 未着手

## 作業の目的・背景

LoopForAlpha（本ガイドラインの利用先プロジェクト）でハンドオフファイルの肥大化が実測され、防止策（ADR-0074〜0077）が増加側を制御していないことが判明した（原因は Issue-0078〜0081）。本サイクルは対策の設計と実装を行う。設計原則は「情報を削らず、置き場を直す」（ユーザー制約: 簡略化しすぎで引継ぎ後の作業精度を落とさない）。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-08-13-handoff-bloat-control/`（00/01/02 の 3 ファイル。確定済み）
- 関連 ADR: ADR-0086 / ADR-0087 / ADR-0088 / ADR-0089（いずれも Proposed。実装完了時に Accepted 昇格）、部分修正予定: ADR-0075
- 対象課題: Issue-0078〜0081（`docs/working/issues/flow/`）。派生起票: Issue-0082
- 本サイクルの割り込み決定: ADR-0085（質問ツール全面不使用。Accepted・実装済み）

## 完了済みタスク

- [x] LoopForAlpha のハンドオフ実測調査と課題起票（2026-08-13 完了。詳細は Issue-0078〜0081 が正本）
- [x] 割り込み対応: ADR-0085（Fable 5 での構造化質問ツール全面不使用）の決定・CLAUDE.md 改定・template 同期・確定前レビューフル実施（2026-08-13 完了。コミット `a278399` / `8774342`）
- [x] 対策の brainstorming と spec 確定（2026-08-13 完了。スコープ: Issue-0078〜0081 一括＋移設先標準定義。確定前レビューフル 3 観点＋差分再確認まで実施し、指摘全件反映。コミット `c022858` / `9e0f134` / `6585556`）

## 進行中のタスク

（なし。spec 確定で区切り、ユーザーの PC 都合により 2026-08-13 にセッション終了）

## 未着手のタスク

- [ ] writing-plans: spec から実装計画を作成（配置は `docs/working/plans/`）
- [ ] 実装: `skills/session-handoff/SKILL.md`（8 変更点）・`skills/start-work/SKILL.md`（1 文）・`docs/overview/folder-structure.md`（既存行拡張）・旧 spec `2026-08-06-handoff-pruning-and-status-design.md` 書き換え・ADR-0075 注記・`README.md` スキル一覧。変更対象と完了基準 7 項目は spec `00-overview.md` §3〜4 が正本
- [ ] 完了処理: ADR-0086〜0089 の Accepted 昇格、Issue-0078〜0081 close（0078 は Issue-0050 への委譲を「結論」に明記）

## 既知のブロッカー・懸念

- master handoff の申し送りを継承（詳細は `docs/working/handoff/master.md` 参照）: 配布元は `dist/`（skills/ 編集だけでは動くスキルは変わらない・執行点 4 手順）/ スキル改定後は `/plugin marketplace update` 依頼 / inbox 3 件はユーザー手動移動予定で organize-inbox 提案不要 / push はユーザー指示待ち

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。

- 2026-08-13 LoopForAlpha ハンドオフ肥大化の原因調査完了: ADR=なし（調査のみで意思決定なし） / worklog=棄却（git 実測の定型手順のみで delta なし）
- 2026-08-13 原因 4 点を Issue-0078〜0081 として起票: ADR=なし（起票のみ。ADR-0021 の既定に従っただけ） / worklog=棄却（定型の起票作業で delta なし）
- 2026-08-13 ADR-0085 対応完了（質問ツール全面不使用への規範改定。spec 確定点 (c) 通過・提示は失念により事後実施）: ADR=0085 / worklog=`MakeAiInstructions-2026-08-13-01` / review=フル実施（claude-opus-5。指摘 16 件中 12 件採用、Issue-0082 起票）
- 2026-08-13 肥大化対策 spec 確定（spec 確定点 (b) 通過）: ADR=0086〜0089 起票（Proposed） / worklog=`MakeAiInstructions-2026-08-13-02` / review=フル実施（claude-opus-5 ×3。指摘 33 件全採用）＋差分再確認（claude-opus-5。反映 22/22・新規検出 5 件も修正済み）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ → spec `docs/current/specs/2026-08-13-handoff-bloat-control/00-overview.md`（§3 変更対象・§4 完了基準）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:writing-plans` で spec から実装計画を作成（plan 確定点で確定前レビューを提示すること）
3. 留意点: 実装対象は配布対象ソース（記法規約の執行点 4 手順必須。spec `01-relocation-standard.md` §6 に写し方の注意あり）。ADR 昇格・Issue close は実装完了時。push はユーザー指示待ち

## 重要な意思決定の履歴

- ADR-0085: 事象確認済みモデルでは構造化質問ツールを使用しない（2026-08-13。割り込み対応・Accepted。ADR-0029 を Superseded 化）
- ADR-0086〜0089: 肥大化対策の設計 4 決定（2026-08-13。Proposed。移設標準 / サイズトリガー / 節別規範 / 配置定義とスキル手順の責務境界）
