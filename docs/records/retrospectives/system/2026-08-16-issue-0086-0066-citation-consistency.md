# Retrospective: Issue-0086/0066 対策 引用突合の文言拡張

- **Subject**: Issue-0086（引用実測と見送り理由の向きの突合工程なし）と Issue-0066（引用元ゲートの無条件化検出手順なし）の同時対策
- **Branch**: feature/issue-0086-citation-consistency（merge済み: 598b279）
- **Period**: 2026-08-16 〜 2026-08-16
- **Plan**: docs/working/plans/2026-08-16-adr-0099-citation-consistency-plan.md
- **Spec**: なし（ADR-0099 が設計文書を兼ねる型。spec 確定点 (c)）
- **Related ADRs**: ADR-0099（新規・Accepted）、ADR-0092 / ADR-0079（部分修正追記）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- 設計の前提としてユーザー提起の複雑化抑制制約（新工程・新観点・新規則を作らない。対策は既存工程の文言拡張かリスク受容に限定）を置き、4 案比較で「既存観点の文言拡張＋残余リスク受容」を採用（ADR-0099 起票 `872159d`）
- spec 確定点 (c) で 3 観点フルレビュー（claude-opus-5）を実施し、Critical 2・Major 5・Minor 10（重複統合前）を全件反映。plan 確定点はレビュー見送り（写像のみのため）
- 実装 4 タスク: CONTRIBUTING 注記＋雛形改定と spec 同期 `c93c83d` / ADR-0092・0079 部分修正追記 `371c2fd` / decision-log 観点 5「引用の整合」拡張・plugin 0.1.6・dist 再生成 `fb99a24`。検証は全期待値が等号一致
- サイクル全体整合検査（改定後の観点 5 を初適用）: 実施・指摘なし。ADR-0099 Accepted 昇格・Issue-0086/0066 close `207f2dc`

## 2. 課題（対象システム固有）

本サイクルの対象システムは AI 駆動開発ガイドライン自体であり、対象システム固有の新規課題は抽出されなかった。

> 開発フロー課題の新規起票は 0 件。worklog 送りとした delta 型候補 1 件（起票なし。振り分け規則による）: ADR の見送り理由が採用案にも等しく当たる「非対称」を検査する工程がない（ADR-0099 初稿で発生、独立レビューが Critical として捕捉。worklog `MakeAiInstructions-2026-08-16-01` の friction に記録済み。worklog-extract の再発裏付けに委ねる）

## 3. 既存課題の再発・進展

- Issue-0084: --no-ff マージの手動適用が本サイクル（598b279）で 5 サイクル連続となった旨を「検討状況」へ追記
- Issue-0086 / Issue-0066: 本サイクルで対策・close（結論は ADR-0099）
- Issue-0073（計画の検証期待値の陳腐化）: 本サイクルでは発生なし（全期待値が等号一致。追記なし）
