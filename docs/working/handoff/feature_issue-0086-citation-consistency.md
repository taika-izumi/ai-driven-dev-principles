# Handoff: Issue-0086/0066 対策 引用突合工程の導入

- **Branch**: feature/issue-0086-citation-consistency
- **Last Updated**: 2026-08-16 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: 完了（master へ --no-ff マージ済み `598b279`。retrospective 実施済み: `docs/records/retrospectives/system/2026-08-16-issue-0086-0066-citation-consistency.md`）

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

（なし。完了）

## 未着手のタスク

（なし。残る後始末は `master.md` の「次セッション開始時のアクション」参照）

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
