# Handoff: 検査委譲の保護改定の実装準備

- **Branch**: master
- **Last Updated**: 2026-09-08 12:47 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: Issue-0136の実装前 / 新セッションへの引き継ぎ

## 作業の目的・背景

ロードマップに沿ってIssue-0136の検査委譲を保護する。設計と判断の分担を承認済みで、設計レビューは終了。今回のユーザーはコンテキスト量を理由に新しいセッションでの実装を希望した。実装前なので、設計・試験結果・入力を保存して区切る。共通スキルはまだ編集していない。

CodexとClaude Codeを別々に確認し、16GBで重い検証はまず1件ずつ進める。新しい必須依存・環境移行・保護条件の緩和は相談事項。ループ／AI組織の開発実証開始は今回の範囲外。

## 関連ドキュメント

- 作業の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。
- 設計と判断の分担: 同Issueフォルダの `0136-note-common-protection-design.md`「承認記録」。11:39に設計・分担を承認、初回F-01の修正も追加承認。経緯は `0136-log.md`。
- 実装計画: `docs/working/plans/2026-09-08-issue-0136-inspection-protection.md`。タスク1は完了、タスク2〜4は未着手。計画の自己確認済み。
- 方針: `docs/records/decisions/0141-keep-inspection-protection-tool-independent.md`（Proposed）。実装を伴うため実装・検証完了まで昇格しない。
- 設計レビュー: `docs/records/reviews/2026-09-08-issue-0136-design-r1.md` と `2026-09-08-issue-0136-design-r2.md`。独立gpt-5.6-solの1担当4観点を2回実施。第2回は新規指摘0、前回指摘解消。
- 調査: `docs/reference/inspection-isolation-costs.md`。Codex隔離の実測、Claude読取経路、制限・負荷・起動時の注意を集約。
- 実測: `docs/records/experiments/2026-09-08-inspection-isolation.json`（Codex）、`2026-09-08-claude-readonly.json`（Claude Read限定）、`2026-09-08-inspection-dispatch-baseline.json`（現行スキルの4ケース）。3件とも同じディレクトリ。
- 比較試験の入力: `scripts/experiments/inspection-dispatch/baseline-prompt.txt` と `cases.json`。現行スキルはコミットd74fb1072b927d456dce7c643c1c29c3efa9915fの `skills/subagent-dispatch/SKILL.md`。復元方法は計画。
- 全体の起点: `docs/current/development-roadmap.md`、`docs/reference/ai-team-tooling.md`。ADR-0139・0140はProposedのまま。個別の実装・導入・公開を包括承認されたとは扱わない。

## 完了済みタスク

- Codex隔離の小規模実証と負荷測定: 試験用の親子書き込み拒否と正常処理、配布検査の成功。詳細は隔離調査と実行記録。
- Issue-0136 spec 確定点: 起動前の全操作経路の保護確認・不能時の静的限定または停止・受取確認を反映し、設計レビューを終了。
- リモート中の実装準備: Claude CLIは認証済み、Readのみ・MCPなしの試験成功。手元でのClaude画面操作は不要だった。
- 現行判断試験と計画自己確認: Claudeによる机上4ケースは3件合格・1件不合格。広い権限の検査担当を「隔離準備不要」で起動する不足が再現した。残る3件で改善効果が実証されたとは扱わない。

## 進行中のタスク

- **現在の作業**: 計画確定前レビュー・実行方式の提示後に中断。ユーザーは「新しいセッションで実装したい」と希望したが、計画レビューの実施・見送りはまだ選択していない。中断を見送り承認に読み替えない。
- 計画確定点の状態: 対象=plan、成果物の型=通常型（独立レビュー済み設計の具体化）、計画の独立レビュー0回。提示済み選択肢は「このセッションで実装〈レビュー見送り・推奨〉」「計画を1担当4観点でレビュー」「レビュー見送り・サブエージェント実装」。新セッションではその状況に合わせて未決部分だけ確認する。
- 有効な委任: 文言・参照配置・無害な試験ケース・既存機能内の引数調整。対応ツールの削減、保護緩和、新しい必須依存、利用者の環境移行、実験による既存データ変更は相談する。公開・導入の承認は別。
- Claude送信: ユーザーは通常のClaudeモデル利用であると確認し、現行スキル本文と架空4ケースの送信を明示承認済み。同じ許可を取り直さない。無関係な資料への無制限の許可に拡大しない。

## 未着手のタスク

- 計画タスク2: `skills/subagent-dispatch/SKILL.md` の改定と `references/inspection-isolation.md` の新設、改定後の判断試験。
- 計画タスク3: Codex・Claude Codeそれぞれの検査担当全体の実経路を確認する。狭い検証コマンドだけでは、担当が直接操作できる経路を塞いだことにならない。ClaudeのRead限定成功は実行あり検査の保護の証拠ではない。
- 計画タスク4: 実装レビュー・生成検査・条件を満たした時点での配布準備。Issueはopen、ADR-0141はProposed。未確認を残したまま両ツール対応完了と報告しない。
- ロードマップの次候補はIssue-0138→0124。Issue-0123・0137は本件の保護に必要な範囲で照合し、編集先の重なりだけで全面対応へ広げない。段階2の組織運用の先行調査は未実施。
- 以前の保留はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。Issue-0114は後続候補、0130の原因調査は後回し。その他の申し送りはIssue索引とロードマップを正本とする。

## 既知のブロッカー・懸念

- ユーザーはリモート操作中でClaude画面の操作不可。既存CLIは使えたが、新たな認証や対話承認が必要な操作は該当部分だけ保留する。設定変更・移行を無断で行わない。
- 実装用ブランチ・worktreeは未作成。現在master。既存未追跡物 `.claude/`、`.tmp/`、`docs/conversation_log.md`、inbox3件を保全し、一括ステージ・削除しない。inboxは手動整理予定。
- `.tmp/inspection-probe-20260908/`、`.tmp/inspection-probe-host-20260908/`、`.tmp/claude-readonly-probe-20260908/` は試験用として残す。次セッションだけを理由に成功済みの試験を再実行しない。Claude判断試験の必要入力はGit管理側から復元可能。
- 過去の重複草案stash `6e959892b6e00600006456172237f27d7957fa01` と `codex/issue-0122-delegated-decisions` のworktreeは保全対象。古い草案を適用しない。今回それらは操作していない。
- `.opencode/skills/` は過去申し送りで0.1.23相当とされていた。現在の利用環境は再確認していない。配布物0.1.24の生成と利用環境への導入を区別する。今回push・導入は行っていない。

## 節目ごとの確認記録

- 2026-09-08 セッション終了・実装前の引き継ぎ: ADR=なし（通常の中断、承認済み設計は維持） / worklog=棄却（既存の引き継ぎ手順で対応）
- 2026-09-08 現行判断試験と計画自己確認: ADR=なし（承認済み設計の検証準備） / worklog=棄却（計画済みの試験）
- 2026-09-08 リモート中の実装準備: ADR=なし（承認済み設計の準備） / worklog=棄却（既存CLIでの確認と承認境界への対応）
- 2026-09-08 Issue-0136 spec 確定点: ADR=0141（実装前・Proposed） / worklog=棄却（承認済み修正と再レビュー） / review=フル実施（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-08 Codex隔離の小規模実証と負荷測定: ADR=なし（方式の採用未確定、調査のみ） / worklog=MakeAiInstructions-2026-09-08-02
- 2026-09-08 既存worklog利用方針・ADR-0138 Accepted 昇格: ADR=0138 / worklog=棄却（既存の記録手順の利用方針） / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-08 plan 確定点・ADR-0136/0137 Accepted 昇格: ADR=0136・0137 / worklog=棄却（既存の時間・費用判断） / review=フル実施（gpt-5.6-terra・1回・提示後確定（実質的な収束に至らず）） / cyclecheck=非該当（対象文書の変更なし）
- 2026-09-07 Issue-0131対処見送り・ADR-0135 Accepted 昇格: ADR=0135 / worklog=棄却（既存の費用比較規範の適用） / cyclecheck=非該当（対象文書の変更なし）

## 次セッション開始時のアクション

1. `start-work` → 本handoff、実装計画、設計ノート「承認記録」、第2回レビューを読む。新セッションでの実装がユーザー意図。計画レビューと実行方式の未決部分だけ確認し、設計・入力送信の承認は取り直さない。
2. 計画タスク1は実施済み。基線JSONと保存した入力を読み、共通改定のタスク2から準備する。実装前に現在のブランチ・作業領域を確認し、plan-deviation-defaultsとwriting-skillsの検証手順を適用する。
3. 16GB・重い検証は直列を維持。Codexのコマンド隔離、Claudeの静的確認、両ツールの実行あり検査の保護を混同しない。公開・導入・新依存は別判断。既存未追跡物・stash・他worktreeを保全する。

## 重要な意思決定の履歴

- ADR-0141: 共通保護条件とツール別の対応実証。設計・F-01修正承認済み。実装検証前のためProposed。設計保存コミットd74fb10。
- ADR-0139・0140: 公式基盤の再利用と整備順序の草案。Proposedのまま。ロードマップ保存コミットeb3e4b1。
- ADR-0135・0138: 以前の課題の保留・事例蓄積方針。詳細は各ADRとIssueを参照。
