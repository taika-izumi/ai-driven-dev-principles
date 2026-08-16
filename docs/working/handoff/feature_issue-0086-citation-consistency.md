# Handoff: Issue-0086/0066 対策 引用突合工程の導入

- **Branch**: feature/issue-0086-citation-consistency
- **Last Updated**: 2026-08-16 12:30 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装完了・ADR-0099 Accepted 昇格済み（`207f2dc`）。残りは master への統合（--no-ff）と retrospective

## 作業の目的・背景

Issue-0086（決定の見送り理由と引用実測の主張の向きを突合する工程がない）と Issue-0066（過剰適合点検の観点 3 に、引用元の条件付き規範を無条件化する型を検出する手順がない）を同時スコープで対策する。両課題は「引用元の文書と、それを引いた側の記述との突合」という同一領域にあり、Issue-0086 は「主張の向きの一致」、Issue-0066 は「条件節（ゲート）の保存」の軸を扱う（同時対策の判断は Issue-0066 の留意に基づくユーザー決定。2026-08-16）。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0086-adr-rationale-vs-cited-evidence-check.md` / `docs/working/issues/flow/0066-overfitting-check-misses-dropped-gates.md`
- 関連ADR: ADR-0079（過剰適合点検）、ADR-0092（サイクル全体整合検査の観点 5）、ADR-0093（Issue-0086 の発生元）、ADR-0080（Issue-0066 の発生元）
- 拡張ルール: `CONTRIBUTING.md`
- 前サイクルまでの経緯: `docs/working/handoff/master.md`

## 完了済みタスク

- [x] 対策の設計（2026-08-16 完了。方針: 新工程を作らず既存検査観点の文言拡張＋残余リスク受容。設計文書は ADR-0099 が兼ねる。spec 確定点 (c) で 3 観点フルレビューを実施し指摘 13 件（統合後）を全件反映、コミット `872159d`）

## 進行中のタスク

- [ ] **現在の作業**: サイクルの仕上げ
  - 状態: 実装 4 タスク完了・全検証一致・ADR-0099 Accepted・Issue-0086/0066 close 済み（`207f2dc`）
  - 残り: master への --no-ff マージ（ユーザー確認）→ retrospective → cycle-reset → 配布反映（`/plugin marketplace update`。0.1.6）の依頼

## 未着手のタスク

- [ ] master への統合と retrospective（マージ方式はユーザー確認。Issue-0084 の 5 サイクル目の手動適用になる点に留意）

## 既知のブロッカー・懸念

- 母体の申し送り（配布元 dist 切替、執行点 4 手順、確定前レビュー・cyclecheck 運用、Issue 運用規範ほか）は `docs/working/handoff/master.md` の「既知のブロッカー・懸念」を参照
- Issue-0066 の留意: 観点の追加ではなく既存観点 3 の問いの書き換えで足りるかを先に検討。対処設計時は ADR-0079 の点検を自分自身に適用（実測が少数サイクルに偏る）

## Post ラッパー消化記録

- 2026-08-16 ADR-0099 設計確定・spec 確定点 (c) 通過: ADR=0099 / worklog=`MakeAiInstructions-2026-08-16-01` / review=フル実施（claude-opus-5）
- 2026-08-16 実装計画作成・plan 確定点通過: ADR=なし（ADR-0099 の写像のみで新規決定なし） / worklog=棄却（delta なし） / review=見送り
- 2026-08-16 実装完了・ADR-0099 Accepted 昇格（`207f2dc`）: ADR=0099 / worklog=棄却（delta なし。計画どおりの編集のみ） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff、`docs/working/issues/flow/0086-*.md` / `0066-*.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ extend-guidelines の続き
3. 留意点: master 直接作業禁止。確定点で確定前レビューを提示し `review=` を記録（ADR-0080）

## 重要な意思決定の履歴

- ADR-0099: 引用元との突合（条件保存・主張の向き）は新工程を設けず既存検査観点の文言拡張で行い、残余リスクを受容する（2026-08-16。Accepted）
