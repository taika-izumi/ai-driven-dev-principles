# Handoff: プロジェクトの目的・方針の参照

- **Branch**: codex/project-purpose-context
- **Last Updated**: 2026-09-13 06:14 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装・検証完了 / masterへの取り込み方法の選択待ち

## 作業の目的・背景

必要品質を保ちながらAI費用・時間・将来負担を抑える本ガイドラインの目的を、開始・再開ごとに取りこぼした事例から、各プロジェクトの目的・方針の正本を担当の入力へ届ける仕組みを改修する。継続判断の規範案はこの後に検討する。

## 関連ドキュメント

- プロジェクトの目的・方針: 対象ルートはD:/Dev/002_AiDev/MakeAiInstructions/.worktrees/project-purpose-context。正本はdocs/overview/project-purpose.md（5350b9f版）。採用理由はADR-0130・0183、段階はロードマップ。
- 設計理由: docs/records/decisions/0190-read-project-purpose-at-start-resume-and-delegation.md。詳細仕様: docs/current/specs/2026-09-12-project-purpose-context/00-overview.mdと3ブロック。
- 調査と対話: docs/reference/stage-three-preparation-and-delegation.md。コピー元はmasterの同ファイルの未コミット変更。元も保持。
- 個別承認: 2026-09-12「OK。この案で進めていきましょう」。直前の提案と対象はADR-0190 Context・Decisionへ保存。
- レビューと対応案: docs/records/reviews/2026-09-12-project-purpose-design-r1.md、同名JSON。原所見・送信承認・実行と消費・起動補正・5論点の対応を記録。
- 最新レビュー: docs/records/reviews/2026-09-13-project-purpose-design-r2.md、同名JSON。前回7指摘解消、新規Major 1件（子のstart-work二重起動）の対応案と増設点検。
- 設計確定: docs/records/reviews/2026-09-13-project-purpose-design-r3.md、同名JSON。R2指摘解消、新規0件。実装計画: docs/working/plans/2026-09-13-project-purpose-context.md。

- 実装結果: docs/records/experiments/2026-09-13-project-purpose-validation.md、docs/records/reviews/2026-09-13-project-purpose-implementation.md、同日project-purpose-cycle-check.md。

## 完了済みタスク

- [x] 既存の目的関数・開始再開・委譲・配布経路の照合。
- [x] 作業worktree作成、ADR-0190と索引のドラフト作成。
- [x] 変更前のbuild-dist・sync-templateのCheckは両方成功（記法違反0、Up to date）。
- [x] Sol/high 2体のフルレビュー1回を完了。7指摘を5論点にまとめ、ADRと分割仕様へ修正案を反映。
- [x] Sol/high 1体の差分再確認1回を完了。前回7指摘解消、新規1指摘への修正案をADR・仕様02・03へ反映。
- [x] Sol/high 1体で起点分担1点を再確認し、解消・追加指摘なし。設計はフル1回＋差分2回で実質的な収束。

- [x] 計画4タスクを実装・検証し、0.1.29の配布物を生成。ADR-0190をAcceptedへ昇格。

## 進行中のタスク

- [ ] **現在の作業**: 取り込み方法の選択待ち。
  - 状態: 計画4タスクを完了。8題の現行・改修後比較とSol/highの実装レビュー（指摘0件）、両生成器・Check・サイズ・サイクル全体整合を確認。ADR-0190はAccepted、0.1.29の配布物を生成済み。
  - 残り: masterへローカル統合／pushとPR／ブランチ保持の選択。masterとorigin/masterはf63a7a4（公開0.1.28）。マージ慣行はbranch.master.mergeoptionsの--no-ff。取り込み・公開・実導入は未実施。
  - 検証の限界: 有限の読解・判断試験であり実運用の全経路ではない。P07等の規則入力不足は実験記録へ分離。実運用の最初の3件の観測はこれから。

## 未着手のタスク

- [ ] masterへの統合、統合した場合のretrospective。
- [ ] 公開・利用側更新（それぞれ個別の指示に従う）。
- [ ] 最初の3件の開始・再開における目的参照の効果観測。
- [ ] 継続・切替・保留の判断案の比較。ADR-0184の旧案を採用済みと扱わない。

## 既知のブロッカー・懸念

- 主担当の正本は本worktree。master側の未コミット調査・handoffは保全し、元の未追跡6項目（inbox3件含む）・既存worktrees・stashを操作しない。
- 初回比較・Claude/sbx・Issue-0136は再開しない。既存の起動許可を新しい評価へ流用しない。外部公開・利用側更新は未実施。
- 元のLoopForAlphaの目的関数原文は本セッションからアクセス拒否。本リポジトリの採用済みADR-0130・0183と現行方針を確認済み。

## 節目ごとの確認記録

- 2026-09-12 調査引継ぎと設計具体化: ADR=0190（個別承認を記録） / worklog=棄却（既存手順に沿う設計記録）
- 2026-09-12 変更前の配布検査: ADR=なし（既存検査の実行） / worklog=棄却（deltaなし）
- 2026-09-12 レビュー起動前の送信承認待ち: ADR=なし（実施承認とモデル制約を引継ぎ） / worklog=棄却（既存の送信承認規則による停止）
- 2026-09-12 初回レビューと分割仕様への修正案反映: ADR=0190（分割・5論点の具体化） / worklog=MakeAiInstructions-2026-09-12-01
- 2026-09-13 差分再確認と起点分担の修正案反映: ADR=0190（主担当・子の適用範囲） / worklog=棄却（既存手順で対応）
- 2026-09-13 spec 確定点: ADR=0190 / worklog=棄却（既存手順で対応） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-13 実装計画の作成: ADR=なし（確定仕様の写像） / worklog=棄却（既存手順で対応）

- 2026-09-13 plan 確定点: ADR=なし（確定仕様の写像） / worklog=棄却（既存手順） / review=見送り
- 2026-09-13 タスク1・現行判断の保存: ADR=0190 / worklog=棄却（承認計画どおり）
- 2026-09-13 タスク2・目的と取得手順: ADR=0190 / worklog=棄却（承認計画どおり）
- 2026-09-13 タスク3・起点と委譲の接続: ADR=0190 / worklog=棄却（重複説明の圧縮は既存規律）
- 2026-09-13 タスク4・ADR-0190 Accepted 昇格: ADR=0190 / worklog=棄却（承認計画どおり） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. docs/overview/project-purpose.md、本handoff、実装・サイクル整合の記録を読む。目的の根拠と今回の未統合状態を把握する。
2. 取り込み方法へのユーザー回答からfinishing-a-development-branchを続ける。マージ先はmaster、方式は--no-ff。元checkoutの未コミット資料を保全する。
3. マージしたら統合後の検証・retrospectiveへ。公開・実導入を済んだことにせず、旧実験やADR-0184を自動再開しない。

## 重要な意思決定の履歴

- ADR-0190: 目的・方針を開始・再開・委譲へ届ける。Accepted、実装・検証済み。
- ADR-0130・0183: 現行の目的・費用判断。目的を再定義せず今回の設計へ適用する。
- ADR-0184: 準備に限定した旧案は中断・Proposedのまま。本サイクルで復活させない。
