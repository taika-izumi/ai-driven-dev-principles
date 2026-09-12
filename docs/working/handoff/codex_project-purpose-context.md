# Handoff: プロジェクトの目的・方針の参照

- **Branch**: codex/project-purpose-context
- **Last Updated**: 2026-09-13 04:55 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 設計確定 / 実装計画の実行・確定前レビューの選択待ち

## 作業の目的・背景

必要品質を保ちながらAI費用・時間・将来負担を抑える本ガイドラインの目的を、開始・再開ごとに取りこぼした事例から、各プロジェクトの目的・方針の正本を担当の入力へ届ける仕組みを改修する。継続判断の規範案はこの後に検討する。

## 関連ドキュメント

- 目的の現行正本: docs/current/development-roadmap.md 冒頭・4.0節、AGENTS.md「作業方法の判断」。採用理由と境界はADR-0130・0183。
- 設計理由: docs/records/decisions/0190-read-project-purpose-at-start-resume-and-delegation.md。詳細仕様: docs/current/specs/2026-09-12-project-purpose-context/00-overview.mdと3ブロック。
- 調査と対話: docs/reference/stage-three-preparation-and-delegation.md。コピー元はmasterの同ファイルの未コミット変更。元も保持。
- 個別承認: 2026-09-12「OK。この案で進めていきましょう」。直前の提案と対象はADR-0190 Context・Decisionへ保存。
- レビューと対応案: docs/records/reviews/2026-09-12-project-purpose-design-r1.md、同名JSON。原所見・送信承認・実行と消費・起動補正・5論点の対応を記録。
- 最新レビュー: docs/records/reviews/2026-09-13-project-purpose-design-r2.md、同名JSON。前回7指摘解消、新規Major 1件（子のstart-work二重起動）の対応案と増設点検。
- 設計確定: docs/records/reviews/2026-09-13-project-purpose-design-r3.md、同名JSON。R2指摘解消、新規0件。実装計画: docs/working/plans/2026-09-13-project-purpose-context.md。

## 完了済みタスク

- [x] 既存の目的関数・開始再開・委譲・配布経路の照合。
- [x] 作業worktree作成、ADR-0190と索引のドラフト作成。
- [x] 変更前のbuild-dist・sync-templateのCheckは両方成功（記法違反0、Up to date）。
- [x] Sol/high 2体のフルレビュー1回を完了。7指摘を5論点にまとめ、ADRと分割仕様へ修正案を反映。
- [x] Sol/high 1体の差分再確認1回を完了。前回7指摘解消、新規1指摘への修正案をADR・仕様02・03へ反映。
- [x] Sol/high 1体で起点分担1点を再確認し、解消・追加指摘なし。設計はフル1回＋差分2回で実質的な収束。

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の確定前レビューと実行方法の選択。
  - 状態: 設計はR3で確定。4タスクの計画を作成し、仕様・期待値を照合済み。主担当による直接実装を推奨。計画は確定仕様の写像で、追加の独立レビューは未実施。
  - 対象確定点の型: plan確定点。成果物の型: 通常型（設計で規範内容をレビュー済み）。計画レビューの実施・見送りは回答待ち。前のspec確定点は下記review行へ保存。
  - 残り: 計画の選択後にexecuting-plans。提案するモデル実行は旧・新の判断比較各1回＋実装レビュー1回、Sol/high計3回。送信範囲・停止条件・有限試験の限界は計画に記載。現行スキルと目的の正本本文は未変更。

## 未着手のタスク

- [ ] 計画に沿った固定入力の作成と、会話履歴を持たない担当による判断確認。
- [ ] 目的の正本・参照経路の改修、配布整合、必要なレビューと検証。
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

## 次セッション開始時のアクション

1. 目的の現行正本、ADR-0190、本handoffを読む。本worktreeでgit statusを確認する。
2. 実装計画とユーザーの選択から続ける。設計の再承認は不要。レビューにはFable・Astraを使わず、CLI実行は既存Windows sandbox=elevatedを明示する。
3. 計画を確定したらexecuting-plansへ。設計の静的レビュー、判断比較、実運用の効果を区別する。実装・生成・検証前にADRを反映済みとしない。

## 重要な意思決定の履歴

- ADR-0190: 目的・方針を開始・再開・委譲へ届ける。Proposed、設計・改修への個別承認あり。
- ADR-0130・0183: 現行の目的・費用判断。目的を再定義せず今回の設計へ適用する。
- ADR-0184: 準備に限定した旧案は中断・Proposedのまま。本サイクルで復活させない。
