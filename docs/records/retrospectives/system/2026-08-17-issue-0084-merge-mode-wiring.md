# Retrospective: Issue-0084 対策（マージコミット規範の完了フロー配線）

- **Subject**: マージ方式確認と fast-forward 検出の 2 層配線（ADR-0106・plugin 0.1.9）
- **Branch**: feature/issue-0084-wire-no-ff-merge（取り込み方式: マージコミット 6333928）
- **Period**: 2026-08-17 〜 2026-08-17
- **Plan**: docs/working/plans/2026-08-17-adr-0106-merge-mode-wiring-plan.md
- **Spec**: docs/records/decisions/0106-two-layer-wiring-for-merge-mode-norm.md（spec 確定点 (c) 型。ADR が設計文書を兼用）
- **Related ADRs**: ADR-0106（新設・Accepted）、ADR-0056（部分修正注記）
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- 予防配線: `start-work` Phase 2 へ完了処理行＋独立節「完了処理のマージ方式確認」（慣行判定・既定ブランチ解決の正本）＋横断的ラッパー Pre 条項＋セッション終了処理の役割注記を新設
- 検出配線: `retrospective` Phase 0 へ取り込み方式の検証（fast-forward 検出・5 条件やり直し手順）を挿入し、template の Branch 欄を取り込み方式欄へ改定。現行仕様書 4 箇所を同期
- 本リポジトリへ `branch.master.mergeoptions "--no-ff"`＋`pull.ff true` を設定。plugin 0.1.9・執行点 4 手順・スモーク検証 13/13 合格（一時リポジトリ隔離）
- 実装中の品質レビューが ADR-0106 継承の欠陥 5 件を検出し、ADR・スキル・plan の 3 ファイル同期で補正（修正 3 巡）。ADR-0106 Accepted 昇格（サイクル全体整合検査 指摘なし）・Issue-0084 close
- 本サイクルのマージ自体が新配線の初適用（慣行判定=慣行あり→ `--no-ff`、検出=先端が第 2 親に一致し fast-forward なし）

## 2. 課題（対象システム固有）

新規起票課題なし。受容済みの軽微残余（現行仕様書 §4.1 に fast-forward 時様式なし／`master` 直書き 2 箇所〈ADR 確定文言〉／fast-forward 記載の括弧表記揺れ／慣行判定手順 1 の照会結果の永続化未規定）は、いずれも機械判定を壊さないことをレビューで実証のうえ受容判断済み（経緯は plan 末尾・レビュー反映コミット `ddf3939` `a4fdc99` `930f245` `469acc1` 参照）。

> 開発フロー課題の新規起票 0 件（既存課題への進展追記 2 件は §3）。worklog 送りとした delta 型候補 0 件（各マイルストーンで記録ゲート判定済み・全棄却）

## 3. 既存課題の再発・進展

- Issue-0098: 確定前レビュー 6 巡通過後の実装段品質レビュー（実機トレース）が閉ループ欠陥 5 件を検出した実測を「検討状況」へ追記
- Issue-0073: レビュー指摘反映による plan 検証期待値の陳腐化 1 件（再実例）を「検討状況」へ追記
