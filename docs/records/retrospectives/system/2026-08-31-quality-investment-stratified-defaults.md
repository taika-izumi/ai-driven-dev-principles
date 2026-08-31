# Retrospective: レビュー・品質投資の層別既定再設計＋反復コスト予算（ADR-0120）

- **Subject**: Issue-0114（品質投資の限界効用と層別再設計）と Issue-0103（反復コスト予算基準の不在）を合流させた対策サイクル。確定前レビューの初回体数の 2 型層別と通算巡数の分布外検知を規範化
- **Branch**: feature/quality-investment-stratified-defaults（取り込み方式: マージコミット 7afdd66）
- **Period**: 2026-08-30 〜 2026-08-31
- **Plan**: docs/working/plans/2026-08-31-adr-0120-stratified-review-implementation.md
- **Spec**: なし（ADR-0120 が設計文書を兼ねる型。spec 確定点 (c)）
- **Related ADRs**: ADR-0120（部分修正・注記の書き戻し先: ADR-0067/0080/0107/0117）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- 設計: Issue-0114/0103 を合流し ADR-0120 を Proposed で確定（`55d199d`。確定前レビュー: フル 8 巡＋差分確認 1 巡＋機械検証・実質収束・設計縮小 2 回）
- 実装計画確定（plan 確定点。初回 1 体 4 観点兼務フル 1 巡〈ADR-0120 新既定の先行適用・Critical 2 / Major 2 / Minor 6 を検出〉＋差分確認 1 巡＋機械検証・実質収束。レビュー採用により ADR-0120 実装対象へ「根拠と世代」1 項目を還流追記）
- 実装: 2 型分類・通算巡数の分布外検知（通常型 4 巡・規範改定型 8 巡）・初回体数の型別既定を `skills/pre-finalization-review/` へ、独立項目「成果物の型」を `skills/session-handoff/` へ。spec 2026-08-05 同期・ADR 4 本へ部分修正/注記・plugin 0.1.16（`d9b28d9`。逸脱記録 0 件・全検証 grep 一致・執行点 4 手順クリーン）
- サイクル全体整合検査（5 観点・指摘なし）→ ADR-0120 Accepted 昇格・Issue-0103 close・Issue-0114 対策範囲追記（`1785cc1`）→ master へ --no-ff マージ（`7afdd66`）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。このファイルには**対象システム固有**の課題のみを記載し、開発フロー/ガイドライン課題は `flow/<同名>.md` に記載してここにはポインタを残す。

（本サイクルの system 固有課題の新規はなし。生成器・両 -Check・配布物目視すべてクリーン。R2 判定の機序特定は既存 Issue-0072 の進展として第 3 節へ）

> 開発フロー課題の新規起票は 0 件。worklog 送りとした delta 型候補 4 件（起票なし。振り分け規則による。ADR-0056）: (1) 配布規約 R2 判定の計画段階前倒し・(2) grep 期待値の既存出現実測＝worklog `MakeAiInstructions-2026-08-31-03` 記録済み、(3) 設計 ADR の実装対象列挙に配布物向け「根拠と世代」視点が無い・(4) handoff ブロッカーの陳腐化残存＝worklog `MakeAiInstructions-2026-08-31-04` / `-05` に記録（Phase 3 総ざらいで記録）。

## 3. 既存課題の再発・進展

- Issue-0072: 進展。plan 確定前レビューのレビュアーが生成器実装の直接実行で機序を実測特定——`Test-InsideParen` の `String.LastIndexOf(string)` がカルチャ依存比較で `(`≡`（`・`)`≡`）` と照合（`scripts/lib/strip-provenance.ps1:37`）。入れ子全角括弧で識別子が括弧外判定になる第 2 機序も最小再現で分離（「検討状況」へ追記）
- Issue-0107: 事例 11 を追記。plan 反復第 2 巡で 2 段型がフル巡推奨 → ユーザー相談で差分確認巡を選択し、軽量側が適切だった実測（ADR-0120 稼働前夜の最後の乖離事例）
- Issue-0105: pre-finalization-review SKILL.md が 34,193B → 41,539B（+21.5%。ADR-0120 実装 8 編集）。「検討状況」へ追記
