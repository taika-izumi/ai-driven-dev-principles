# Handoff: 確認工程の費用と粒度の改善検討

- **Branch**: master
- **Last Updated**: 2026-09-10 01:56 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: Issue-0140の設計確定 / 実装未着手

## 作業の目的・背景

2026-09-10、ユーザーがIssue-0140の調査・改善案作成を選択。既存実測と現行手順を照合し、事実追記と利用条件変更を区別する限定改定案を提示する。以下の隔離検証は中断を維持。

前サイクルのClaude標準サブエージェントの保護検証を受け、検証担当が安全に追加テストを作成・実行する構成を設計した。前サイクルの実測・振り返りはADR-0144と`docs/records/retrospectives/system/2026-09-09-claude-native-subagent-interactive.md`を参照。

仕様確定（`1e63e8a`）後の作業は専用worktreeへ移った。AIなし部品を先行実装したが、通信・機密性の条件は未達。最新状態は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md`が正本。本ファイルの過去の計画草案・実装未着手の記載から再開しない。

## 関連ドキュメント

- 今回の設計・承認基準: `docs/working/issues/flow/0140-confirmation-cost-outgrows-work-in-small-norm-updates.md`「2026-09-10 限定改定の設計案」「判断の分担（承認基準）」。2026-09-10のユーザー回答で承認済み。ADR-0164（Proposed）。


- **最新の継続先**: `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md`。コードと更新済み計画は同worktree内。masterへの統合は未実施。

- 今回の要求と個別承認: ADR-0145（Accepted）。検証担当の追加テスト作成・実行を含む。実環境への導入や公開の承認は含めない。
- 初回の担当構成と承認条件: ADR-0146（Accepted）。両主担当から共通の検証担当Codexを呼ぶ。
- Spec: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`とブロック詳細3件。構成詳細はADR-0147・0148（Accepted）。
- Plan: `docs/working/plans/2026-09-09-isolated-verification.md`（草案として保存・確定前確認待ち）。5タスク。保存コミットを実装方法やレビュー見送りの承認と扱わない。
- レビュー結果と確定した採否: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-isolated-verification-design-review.md`。静的4観点、差分再確認、軽微修正の機械確認を経て仕様を確定。実装の動的検証は未完。
- 直近サイクルの振り返り: `docs/records/retrospectives/system/2026-09-09-claude-native-subagent-interactive.md` と同名の flow 記録（起票を見送った現行方針前提の課題2件を含む）。
- 直近サイクルの決定と実測: ADR-0144（Accepted）、ADR-0143（部分修正注記つき Accepted）、`docs/records/experiments/2026-09-09-claude-native-subagent-interactive.json`、`docs/reference/inspection-isolation-costs.md` 第10節。
- 継続中の課題: Issue-0136（別OS・別版と外向きツールの実効性が未確認で open。入口は同フォルダの `0136-note-claude-native-followup.md` と `0136-log.md`）、Issue-0141、Issue-0142。
- 後続の課題候補: `docs/current/development-roadmap.md`、`docs/working/issues/README.md`。

## 完了済みタスク

- [x] Issue-0140の実測・実差分・現行レビュー規範を照合し、比較案3件を同Issueへ保存（2026-09-10）。

- 過去サイクルは `docs/records/retrospectives/` の記録とgit履歴を参照。
- [x] 検証担当の自律範囲を確認し、ADR-0145のドラフトを作成（2026-09-09）。
- [x] Claudeから依頼する条件でCodexを初回の検証担当に選び、公式資料・実機ヘルプを確認してADR-0146のドラフトを作成（2026-09-09）。
- [x] 両主担当から共通処理を呼ぶ構成の承認を反映し、詳細仕様4ファイルとADR-0147を作成（2026-09-09）。
- [x] 送信承認を得てRead限定Claudeのレビューを実施。対象4件・参照10件、指摘6件を照合し、仕様とADR-0148へ修正案を反映（2026-09-09）。
- [x] 新規Read限定Claudeで差分再確認を実施。設計骨格の新規指摘0件、軽微1件を反映して機械確認。原本配下・原本外のGit探索先の対照も確認（2026-09-09）。
- [x] ユーザーが採否案を含む仕様を確定し、ADR-0145〜0148を設計承認時のAcceptedへ昇格（2026-09-09）。実装前のためサイクル全体整合検査は実装完了時に行う。
- [x] 実装計画を5タスクで作成し、V1〜V7への対応、参照、PowerShell16ブロックの構文を確認（2026-09-09）。コードの動作確認は未実施。

## 進行中のタスク

- **現在の作業**: Issue-0140の詳細設計を確認する。
  - 状態: フルレビュー1回後、指摘3件の採否と文言明確化をユーザーが確定。設計・分担はIssue-0140、結果は`docs/records/reviews/2026-09-10-issue-0140-design-r1.md`。ADR-0164は実装・検証までProposed。
  - 残り: 確定文案のスキルへの適用と配布生成・検証。今回の依頼範囲は設計確定まで。実装へ進む場合、設計・分担の承認は取り直さない。
- **中断中の別作業**: 専用worktreeでの隔離検証。
  - 状態: 計画確定・主担当実装・計画レビュー見送りは選択済み。AIなし3群を検証し、限定利用の条件が未達と判明した。最新の根拠は上記継続先を参照。
  - 残り: ユーザーが指摘したLoopForAlphaの既存Docker基盤について、再利用差分の確認から再開するか判断する。Docker採用・共通化・他リポジトリ変更は未決定。

## 未着手のタスク

- Issue-0136 の残る未確認: 別OS・別版（環境準備が要る）、外向きツール（Artifact・SendMessage）と状態変更系ツール（EnterWorktree・ExitWorktree・TaskStop）の実効性、固定検査の接続を子だけに渡す構成の対話セッションでの実行（前サイクル領域への書き込みが入るため退避が必要）。
- Issue-0141（静的確認の免除条項に判定基準が無い）、Issue-0142（分担の相談事項が規範の既決事項と重なる）、Issue-0139（規範の表の増え方）。着手はユーザー判断。Issue-0140は調査・改善案作成済みで、対策実装は未着手。
- 配布予定版0.1.25の公開判断。公開元は最後の確認時0.1.24で、ローカルには規範更新が入っている。
- Issue-0135 のファイルサイズが 17.1KB で目安の 10KB を超えている。フォルダ昇格の提案対象（判断はユーザー）。

## 既知のブロッカー・懸念

- 新しいexec構成の権限制限・通信拒否・実行中に作成するリンク・両主担当からの実起動は未確認。レビューでの既存資料照合やGitの対照試験を、それらの成功に読み替えない。
- Claude標準の子の定義と検索制限は、前サイクルの`docs/records/retrospectives/system/2026-09-09-claude-native-subagent-interactive.md`課題#1を参照。今回のレビューは別のRead限定CLI起動で実施した。
- プラグイン導入版とリポジトリ版は別。導入済みは0.1.24、リポジトリは0.1.25。ローカルの本文を直接読み、マージだけで導入済み本文が更新されたと判断しない。
- 未追跡物を保全する: `.tmp/`（前サイクルの `issue-0136-claude-native-20260908` と直近サイクルの `issue-0136-interactive-20260909`。代用品・変異の証拠・改訂前退避・ハッシュ記録）、`.claude/agents/` の試験用定義3件、`docs/conversation_log.md`、inbox3件。inboxは滞留のままで手動整理予定。一括ステージ・削除しない。削除は名指しでユーザー承認を得てから行う。
- 今回の`.tmp/isolated-verification-review-20260909-01/`・`02/`と外部の改訂前退避を保全する。ログ・送信承認・退避先はレビュー記録に記載。レビュー用CLIは終了済み。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01` は操作しない。古い草案を適用しない。
- 子プロセスの起動などAI側から承認を求められない操作がある（Issue-0135）。子の書き込みに承認プロンプトが出ないことも実測済み。重い検証は1件ずつ、ユーザー実行を前提に組む。
- ADR-0139・0140はProposed。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。

## 節目ごとの確認記録

- 2026-09-10 Issue-0140 spec 確定点: ADR=0164 / worklog=棄却（既存の設計確定手順内） / review=フル実施（claude-sonnet-5・1回・提示後確定（実質的な収束に至らず））

- 2026-09-10 Issue-0140のレビュー受領と文言明確化: ADR=0164（承認済み条件不変） / worklog=棄却（既存の前提照合・委任内修正手順内）

- 2026-09-10 Issue-0140の限定改定設計案作成: ADR=0164（方針選択済み・詳細確認待ち） / worklog=棄却（既存の設計・対照例照合手順内）

- 2026-09-10 Issue-0140の調査と比較案作成: ADR=なし（候補提示のみ、採用未決） / worklog=棄却（既存の原記録・差分照合手順内）


- 2026-09-09 専用worktreeへの再開先の案内: ADR=なし（実装の統合ではなく参照の更新） / worklog=MakeAiInstructions-2026-09-09-07

（直近サイクル分は `docs/records/retrospectives/` とgit履歴を参照）

- 2026-09-09 セッション終了（直近サイクルの振り返り完了とリセット）: ADR=なし（起票のみで対策の決定なし） / worklog=`MakeAiInstructions-2026-09-09-04`
- 2026-09-09 検証担当の自律範囲の選択: ADR=0145 / worklog=棄却（通常の要求確認でdeltaなし）
- 2026-09-09 初回の検証担当と依頼元の選択: ADR=0146 / worklog=棄却（通常の要求確認でdeltaなし）
- 2026-09-09 共通起動方針の承認反映と詳細仕様の作成: ADR=0146/0147 / worklog=棄却（通常の設計具体化でdeltaなし）
- 2026-09-09 独立の静的レビュー受領と修正案反映: ADR=0148 / worklog=MakeAiInstructions-2026-09-09-05
- 2026-09-09 差分再確認とD1の機械確認: ADR=なし（既存責務の参照を明記） / worklog=棄却（通常の指摘対応でdeltaなし）
- 2026-09-09 spec 確定点・ADR-0145〜0148 Accepted 昇格: ADR=0145〜0148 / worklog=棄却（deltaなし） / review=差分再確認（claude-sonnet-5・1回）＋機械検証（1回・提示後確定） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 実装計画案の作成と自己確認: ADR=なし（承認済み仕様をタスク化） / worklog=棄却（deltaなし）
- 2026-09-09 セッション中断と引き継ぎ確定: ADR=なし（ユーザーの中断指示） / worklog=棄却（新たなdeltaなし。起動時の問題はMakeAiInstructions-2026-09-09-05に記録済み）

## 次セッション開始時のアクション

直近はIssue-0140の「2026-09-10 限定改定の設計案」、ADR-0164とユーザー回答から再開する。以下は隔離検証を明示再開する場合だけの手順。Issue-0140への着手を隔離検証の再開指示と扱わない。

1. `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md`を最初に読む。こちらが現在の作業の正本である。
2. 専用worktreeとcodex/isolated-verificationブランチを確認し、同worktree内のIssue-0136の再利用検討ノートに従って再開判断を行う。
3. 本masterへ実装をマージしたり、古い計画選択を再質問したりしない。Docker採用・公開・導入・削除・LoopForAlphaの変更は未承認。

## 重要な意思決定の履歴

- ADR-0145: 検証担当が隔離範囲内で追加テストを作成・実行できる構成を目指す（2026-09-09、Accepted）。
- ADR-0146: 開発の主担当を維持し、Claude CodeとCodexから共通の検証担当を呼ぶ（2026-09-09、Accepted）。
- ADR-0147: 検証の共通入口をCLIに置き、準備・実行・回収の責務を分ける（2026-09-09、Accepted）。
- ADR-0148: 検証用コピーに独立したGit管理領域を作る（2026-09-09、Accepted）。
- ADR-0143: Claude標準サブエージェントの保護は書き込み系ツールの除去で成立させ権限モードに依存しない（2026-09-08、Accepted。ADR-0144 で部分修正）
- ADR-0144: Claude標準サブエージェントの書き込み系ツールの除去は許可リスト方式で行い拒否リスト方式を用いない（2026-09-09、Accepted）
