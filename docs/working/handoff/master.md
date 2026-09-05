# Handoff: レビュー推奨・費用比較の改定から次サイクルへ

- **Branch**: master
- **Last Updated**: 2026-09-06 00:11 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: codex/issue-0107-0124-review-judgmentの取り込み準備

## 作業の目的・背景

AI駆動開発ガイドラインの0.1.20で、レビュー方式・人数の固定推奨を状況判断へ改め、追加機構の採否に導入・維持費用の比較を組み込んだ。Issue-0107・0124はclosed、ADR-0124・0125はAccepted。実装は `a8a6f3e`、目的関数全体の継承不足の検討はIssue-0126（起票 `09d1073`）へ分離した。

次は、品質の最低線を満たす範囲で総費用を抑える判断原則を、必要な判断箇所へ届ける有用性を検討する。第一候補の推薦であり、対策や全面改修を採用済みとは扱わない。

## 関連ドキュメント

- 課題の正本: `docs/working/issues/README.md`
- 第一推奨: `docs/working/issues/flow/0126-quality-constrained-total-cost-objective-not-integrated.md`
- 原文: `LoopForAlpha:docs/records/reviews/2026-09-04-dev-process-review/cleanroom/00-cleanroom-input.md` §A・B（`D:/Dev/001_Trade/LoopForAlpha/` 配下）
- 完了計画・実装レビュー・検証の限界: `docs/working/plans/2026-09-05-review-judgment-and-cost-evaluation.md`
- 今回の設計: `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md`
- 決定の索引: `docs/records/decisions/README.md`（ADR-0124・0125）
- 詳細引き継ぎ: `docs/working/handoff/codex_issue-0107-0124-review-judgment.md`
- 規範・配置・運用: `AGENTS.md`、`CONTRIBUTING.md`、`docs/overview/folder-structure.md`、`docs/overview/issue-management.md`
- 語彙の基準: `docs/overview/wording-replacements.md`。PowerShellの既知事項: `docs/reference/powershell-pitfalls.md`

## 完了済みタスク

- [x] Issue-0107・0124の改定、配布0.1.20生成、独立実装レビューIR-1修正・再確認、サイクル全体整合検査。詳細は完了計画。
- [x] 目的関数の局所的な継承と不足を原文で照合し、ユーザー依頼でIssue-0126を起票。

## 進行中のタスク

- [ ] **現在の作業**: ユーザーが指示したmasterへのマージとpush。
  - 状態: 追跡ファイルの未コミット変更は引き継ぎ更新のみ。作業ブランチをリモートへ出さず、masterへ--no-ffで取り込みpushする。
  - 残り: マージ後検査・振り返りと引き継ぎ確定・origin/masterへのpush確認。

## 未着手のタスク

1. **Issue-0126（第一推奨）: 調査・適用範囲の設計。** 共通の判断原則を先に整理すると、Issue-0122の人間関与やIssue-0114のレビュー深度の判断が揃う。直近の照合結果を利用できる。初回は原文対応表と最小適用案の比較までとし、導入効果の検証なしに全スキルへ展開しない。
2. **Issue-0122**: 承認待ちの費用を減らす対策。測定上の改善余地が大きいが、事前の権限設定・差し戻し・実施判断の条件が必要。Issue-0126を大規模な先行作業に膨らませず、その成果を判断材料として用いる。
3. **Issue-0123＋0125**: 委譲先へ検証上の注意と語彙の規範を届ける。同じ接続先を扱うため、一緒に検討する余地がある。
4. **Issue-0114、0095・0073・0056**: レビュー深度と計画検証の改善。着手時に既存の残余範囲と対策済み箇所を再確認する。

これは次手の推奨であり、上記の採用・着手・同時実装を確定するものではない。その他の候補は課題索引を参照する。

## 既知のブロッカー・懸念

- `.claude/`、`docs/conversation_log.md`、inbox3件は既存未追跡。ユーザーが手動整理予定で、編集・ステージ対象外。
- 利用側で最後に確認したプラグインは0.1.19。0.1.20のソース・配布物は生成済みだが、push後の利用側更新・反映確認は別作業。
- 判断例は主要判断5回一致だが、説明の短さの安定性と、本文供給による追加便益は保証しない。詳細は完了計画。
- Git所有者差には対象リポジトリ限定の `-c safe.directory=D:/Dev/002_AiDev/MakeAiInstructions` を使用する。global設定は変更しない。
- Copilot CLIは未契約という前回申し送りがあり、利用側の3ツール全部で検証済みとは扱わない。
- LoopForAlpha側の未コミット資料整理と、改訂前退避領域の整理はユーザー管理。本リポジトリの完了処理では操作しない。

## 節目ごとの確認記録

- 2026-09-06 次セッション推奨の整理: ADR=なし（推奨のみ、着手・採用は未決） / worklog=棄却（既存課題からの引き継ぎ）

## 次セッション開始時のアクション

1. 本ファイル、Issue-0126、LoopForAlpha原文§A・Bを読む。最初に0.1.20の利用側反映状況を確認する。
2. 第一推奨はIssue-0126。start-work→extend-guidelines→brainstormingで、原文の要素の対応表と最小の適用案を検討する。具体的な採用・実装はユーザー判断。
3. 品質条件、費用の4側面、恒久と一時の扱い、価値検証の先行条件を分ける。原文固有の数値・測定方法は自動移植せず、既存手順の簡素化案も比較する。

## 重要な意思決定の履歴

- ADR-0124: 方式・人数を状況から推奨し、実施・見送りはユーザー判断（Accepted）。
- ADR-0125: 追加物の失敗根拠・代替案・導入と維持費用を既存手順で比較（Accepted）。
- Issue-0126の共通原則の採用・配置は未決。
