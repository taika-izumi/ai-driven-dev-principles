# Handoff: Claude Code標準サブエージェントの追加検証

- **Branch**: master
- **Last Updated**: 2026-09-08 22:35 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: Claude標準サブエージェントの追加検証 / 実測と反映を確定（d98b47b）、未確認分を次セッションへ

## 作業の目的・背景

直近サイクルでは検査委譲の共通保護手順と限定構成の実証を完了し、11cf3edでmasterへ統合した。配布予定版0.1.25はローカルのみで、公開・導入は未実施。

本セッションでClaude Code 2.1.263の標準サブエージェント機能（Agent/Taskツールから子の担当を起動する仕組み）を実測し、確定した範囲をd98b47bで反映した。子の許可リストから書き込み可能な内蔵ツールを外す構成で保護が成立すること、権限モードは保護の代わりにならないこと、固定検査1操作だけを渡せば実行を伴う検査も成立すること、再委譲は既定で成立することを確認した（ADR-0143）。未確認分はIssue-0136にopenで残る。

## 関連ドキュメント

- 実測の記録: `docs/records/experiments/2026-09-08-claude-native-subagent.json`（run別の実ツール一覧・結果・ハッシュ照合・限界）。生ログは `.tmp/issue-0136-claude-native-20260908/records/`（未追跡・保全対象）。
- 今回の決定: ADR-0143（Accepted）。規範は `skills/subagent-dispatch/references/inspection-isolation.md` のツール別の表と確認例、参照知識は `docs/reference/inspection-isolation-costs.md` 第10節。
- 追加検証の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-claude-native-followup.md`。依頼文・確認済みと未確認・着手順・制約。
- Issue本体・ログ・判断の分担: 同フォルダのIssue-0136本体、`0136-log.md`、`0136-note-common-protection-design.md`「承認記録」。Issueはopen。
- 実証と限界: `docs/reference/inspection-isolation-costs.md` 第8・9節。過去の限定構成の実装計画は `docs/working/plans/2026-09-08-issue-0136-inspection-protection.md`。
- 振り返り: `docs/records/retrospectives/system/2026-09-08-issue-0136-inspection-protection.md` と同名のflow記録。新規起票0件、既存Issue-0052・0123へ追記済み。
- 決定: ADR-0141・0142（Accepted、限定した実証済み範囲）。既存の判断を標準サブエージェントの実証済みへ読み替えない。
- 後続の課題: `docs/current/development-roadmap.md`、`docs/working/issues/README.md`。

## 完了済みタスク

- 過去サイクルは上記の振り返り記録とgit履歴（実装e906534・8a15d6d、統合11cf3ed）を参照。

## 進行中のタスク

- **現在の作業**: 標準サブエージェントの実測と、確定範囲の反映（ADR-0143・規範・参照知識・Issue・実験記録）はd98b47bで完了。確定前レビュー（フル実施・claude-sonnet-5・1回）も終了し、反復は継続していない。
- 残り: 未確認分の追加検証（下記「未着手のタスク」）。実施するかはユーザー判断。
- 有効な許可: Issue-0136の追加検証。局所文言・無害な試験・既存引数の具体化は委任範囲。新必須依存・環境移行・保護緩和・既存データ変更は相談。push・公開・導入は未承認。

## 未着手のタスク

- 対話セッション（autoモード）で子を起動したときの実挙動。`--print` 実行では `--permission-mode auto` が反映されず default になったため未測定。試験用の定義 `.claude/agents/issue0136-static.md`（tools: Read、未追跡）を残してあり、次セッション起動時には読み込まれる。
- エージェント定義ファイルのfrontmatterによる接続の限定公開（`mcpServers`）と拒否リスト（`disallowedTools`）。起動引数のJSONでは `mcpServers` が拒否された。
- 親が `bypassPermissions` の場合、別OS・別版での確認。
- 配布本文への反映要否の判断。直前の公開状況を確認し、未公開なら同じ予定版0.1.25を使用できるか判断する（現時点で公開元は0.1.24）。
- Issue-0052・0123の恒久対策は未着手。今回の事例追記を対策着手や規範変更の承認へ広げない。

## 既知のブロッカー・懸念

- プラグイン導入版とリポジトリ版は別。追加検証メモに従いローカルの保護手順を読み、マージだけで導入済み本文が更新されたと判断しない。
- 未追跡の `.tmp/`、`docs/conversation_log.md`、inbox3件を保全。inboxは手動整理予定。一括ステージ・削除しない。
- 今回作成した未追跡物: `.tmp/issue-0136-claude-native-20260908/`（代用品・生ログ・レビュー記録・実行スクリプト）と `.claude/agents/issue0136-static.md`。いずれも次の検証の材料として残す。削除は名指しでユーザー承認を得てから行う。代用品はrun-dで書き換わった1件を復元済み（SHA256が基準と一致）。
- 他のissue-0122 worktreeとstash `6e959892b6e00600006456172237f27d7957fa01` は操作しない。古い草案を適用しない。
- リモート操作・Claude認証の状況は新セッションで確認する。重い検証は1件ずつ。既存成功試験をセッション切替だけでやり直さない。
- ADR-0139・0140はProposed。ロードマップ全体の実装・公開は未承認。保留事項はADR-0135／Issue-0131、ADR-0138／Issue-0132を参照。

## 節目ごとの確認記録

- 2026-09-08 振り返り終了後の引き継ぎ確定: ADR=なし（承認済み事例追記と次作業への引き継ぎ） / worklog=棄却（既存Issueへの記録と既存終了手順）
- 2026-09-08 標準サブエージェント追加検証の反映・spec 確定点・ADR-0143 Accepted 昇格: ADR=0143 / worklog=`MakeAiInstructions-2026-09-08-03` / review=フル実施（claude-sonnet-5・1 回・実質的な収束） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. start-workで本handoffとADR-0143・`docs/records/experiments/2026-09-08-claude-native-subagent.json` を読む。確定済みの結論を測り直さない。
2. 未確認分を進める場合は、対話セッションでの実挙動から始める（`.claude/agents/issue0136-static.md` が読み込まれているかをAgentツールで確認し、書き込み可能なツールを持たない子から測る）。実効構成を確認できるまで実行ありの子を起動しない。
3. 結果は確認した構成に限定して記録する。既存物を保全し、公開・導入は別承認。前サイクルの振り返りは終了済みで、再実施しない。本サイクルの振り返りはmasterへの直接作業のため、ユーザーが区切りを指示した時点で判断する。

## 重要な意思決定の履歴

- 既存の限定構成の決定はADR-0141・0142。追加検証の依頼はIssue-0136のログと追加検証メモを参照。
- ADR-0143: Claude標準サブエージェントの保護は書き込み系ツールの除去で成立させ権限モードに依存しない（2026-09-08、Accepted）