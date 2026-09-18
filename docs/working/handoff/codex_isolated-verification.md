# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-18 13:34 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: Codex側（2026-09-17）とClaude Code側（2026-09-18）の両主担当の往復が完了。次はTask9の記録コミット後、サイクル全体整合検査・最終レビュー・ADR-0162・0192〜0201の状態判定・統合。

## 作業の目的・背景

Claude CodeとCodexのどちらの主担当からも、共通CLIで独立コピーをsbx内Codexへ渡し、提案を通信なしの別VMで再実行して採否を判断する。主担当をClaude Codeへ切り替えても、VM内の提案担当はCodexのまま。実プロジェクトや通常運用への拡張は未承認。

- 作業場所: `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。masterへ未統合。masterからstart-workした場合も、このファイルを読んでから状況を要約する。
- 作業成果の保存点: `539e100`。その後のコミットはセッション終了用の引き継ぎ整理。履歴はgit logを確認する。
- 目的の正本: `D:/Dev/002_AiDev/MakeAiInstructions/docs/overview/project-purpose.md`（master側、今回参照版5350b9f）。このworktreeには未取り込み。

## 関連ドキュメント

- 最新の実証: `docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`（Claude Code主担当、操作案 `docs/working/plans/2026-09-18-task9-claude-code-roundtrip.md`、生データ `.tmp/c9/`）と `2026-09-17-task9-codex-roundtrip.md`（Codex主担当、生データ `.tmp/m9/`）。各同名ディレクトリの結果JSONが候補比較・採用理由・recheck・停止の正本。
- 能力証拠: `docs/records/experiments/2026-09-17-task9-codex-template-evidence.md`。profileからハッシュ固定しているため追記しない。設定は`scripts/verification/profiles/proposal/`と`profiles/replay/`。
- 仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`〜04。実装計画: `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`のTask9。
- 操作と承認: `docs/working/plans/2026-09-17-task9-codex-template-amendment.md`。承認済み6台/2モデルセッションはすべて実施済み。Claude Code側の追加実機操作へ自動で流用しない。
- 設計・判断の分担: ADR-0157/0158。補助設計は委任済み。保護の緩和、新基盤、利用者作業、認証/費用/送信、削除/公開は個別相談。主担当の切替え自体は今回の利用者指示。
- 現行条件: ADR-0199（2ホスト443番・OAuth）、ADR-0200（最小起動確認）、ADR-0201（役割別の固定テンプレート）。昇格は全体整合検査時に判定する。
- 実測の注意: `docs/reference/sbx-sandbox-runtime-facts.md`。daemon、30秒の自動停止、停止VMへのexec/cpによる再起動、テンプレートの区別、stdinの挙動を参照する。
- 実装/レビュー: `docs/records/reviews/2026-09-16-v3-implementation-tasks1-7.md`、`2026-09-17-task9-443-validation.md`、`2026-09-17-task9-443-independent-review.md`。
- 先行実機: `docs/records/experiments/2026-09-16-v3-task8a-probe.md`、`2026-09-16-v3-task8b-public-operations.md`。負荷停止の既存証拠は`2026-09-14-v3-capability-test-methods.md`（ADR-0197の限定流用）。
- 問題と解決の履歴: Issue-0150（全ポートという前提の訂正）、Issue-0151（shell画像にCodexがない）。両方closed。起動前失敗の記録も削除しない。
- 再開経路と保全: master側`docs/working/handoff/master.md`とIssue-0136。masterの61ddef3等、ADR-0163〜0191は本branchへ未取り込み。採番は両側を確認する。

## 完了済みタスク

- [x] Task1〜7の実装・全体レビュー・修正、Task8の実機検証。詳細は上記の実装レビューとTask8実験記録。
- [x] 443番限定とpolicy check正常拒否の修正、既存11群と対象試験、独立レビュー/差分再確認。保存点352499c、実測修正の正本は443-validation/independent-review。
- [x] 新Codex固定テンプレートで能力・最小起動・異常終了後復旧を確認し、proposal profileを生成。Codex CLI 0.149.1、gpt-5.6-sol/medium。保存点539e100。
- [x] Codex主担当の公開CLIでcandidate-supported。合成原本への採用後、同じ3テストでcurrent-pass。新規6台と元9台、全15台stopped。Issue-0151 closed（2026-09-17）。
- [x] Claude Code主担当の往復（2026-09-18）: 利用者承認の操作案どおり新規4台・Codex 1セッション。candidate-supported→Claude Codeが全文確認して`.tmp/c9/source/calc.py`へ採用→recheck current-pass。全19台stopped、daemon同世代。生成物は前回とSHA256一致。v3計画Task9の往復項目を完了に更新。

## 進行中のタスク

- Task9の記録は54566c8でコミット済み。サイクル全体整合検査は2026-09-18に実施済み（修正1a0c4f5、記録 `docs/records/reviews/2026-09-18-cycle-consistency-check.md`。粒度点検でADRの分割は不要と判断）。
- ADR-0162・0192〜0201は2026-09-18にAccepted（利用者の「１で」。ブランチ全体の再レビューは行わず、タスク1〜7の最終レビューと443番修正の独立レビューを根拠とする）。
- [ ] 次にブランチの完了処理（finishing-a-development-branch、merge-practice確認）。繰り延べMinor（`.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-review-deferred.md`）の扱いを利用者に確認する。masterへの統合、retrospective、停止VM（19台）/OAuthの後片付けはまだ行っていない。
- `.tmp/m9/source`と`.tmp/c9/source`はいずれも修正後（加算）の状態。再現が必要なら`tests/fixtures/pilot-source/source/calc.py`から別の独立Gitを作る。既存の試験原本・結果は書き換えない。

## 未着手のタスク

- [ ] 最終レビューで繰り延べたMinorの扱い: `.superpowers/sdd/2026-09-14-isolated-verification-v3-implementation/final-fix-findings.md`「繰り延べ」。試験補助の重複、profile拒否が照合を通らない経路等。
- [ ] Issue-0146: パックファイルのパス長260文字問題。本サイクルは短い試験パスで回避。恒久対策は未採用。
- [ ] Issue-0147: Task8aの観測とopen状態・残る起動からジョブ割当までの子プロセスの扱いを照合する。未実証部分を完了扱いにしない。
- Issue-0148（停滞検知）と0149（VM内担当から主担当への質問）は本サイクル対象外のまま。Execution.psm1やproposal.schema.jsonの拡張を再開しない。
- daemon切断の注入、稼働中の他VMの非停止、実行中の保護変更、その他ホスト経路の包括的実証は未実施。受容済み制限・ADR-0196/0197と区別し、追加実験は別承認。

## 既知のブロッカー・懸念

- 実行中の試験/モデル/レビューなし。全19VMはstopped。一覧は`.tmp/c9/vms-final.txt`と2026-09-18実験記録。停止済みVMのexec/cpは再起動を伴うため発行しない。
- sbxは`C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe`。最終確認は2026-09-18に0.42.1（v0.43.0の更新通知は適用しない）、daemon PID25888、2026-09-16通常端末起動の世代。次回はdaemon statusから確認し、停止中にls等で自動起動しない。
- daemonのstart/restart/reset、sbx/画像の更新、既存VM/画像の削除はAIから行わない。利用者がリモート操作中の場合も、この制約を迂回しない。
- OAuthは登録済み・同一daemonの全sandbox共有（ADR-0199）。再登録を求めず、必要ならsecret lsのメタデータだけ確認する。ホスト認証ファイルや秘密値を出力しない。
- 提案はcodex固定digest b387e913...、replayはshell固定digest16a88c...。shell画像を提案へ戻さない。具体値はprofilesとADR-0201を参照。
- 両profileが参照する能力証拠と標準ライブラリ一覧はハッシュ固定。証拠mdを追記・整形すると無効になる。新結果は別記録へ書く。
- `.tmp/`・`.superpowers/sdd/`の台帳、旧試験/コピー/log/junction/returned.txtを保全。一括削除しない。既存sbx状態退避sandboxd-preserved-20260909-02/03も保全。
- master側の他worktree、stash、`.claude/agents`、会話ログ、inbox3件は操作しない。LoopForAlphaのDocker Desktopは別接続であり、設定/コンテナを変えない。詳細はmaster handoff。
- 外部レビューの退避`C:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/`も保全。完了済み送信の承認を新しい内容へ流用しない。
- 過去の導入/smokeの節目行が欠けていても、当時の実験記録を参照し、今回実施したと補記しない。プラグイン導入版は0.1.29、次回の一覧/実体で確認する。

## 節目ごとの確認記録

- 2026-09-18 ADR-0162・0192〜0201 Accepted 昇格: ADR=0162・0192〜0201 / worklog=棄却（既存の昇格手順内） / cyclecheck=実施（修正: 1a0c4f5。昇格時にADR-0194 Consequencesの同種引用も訂正）
- 2026-09-18 サイクル全体整合検査: ADR=なし（既存ADRの仕様への書き戻しと引用元の訂正） / worklog=棄却（既存の検査手順内） / cyclecheck=実施（修正: 1a0c4f5）
- 2026-09-18 Claude Code主担当の往復完了: ADR=なし（承認済み操作案の実行、設計変更なし） / worklog=MakeAiInstructions-2026-09-18-01
- 2026-09-17 セッション終了・Claude Codeへの引き継ぎ確定: ADR=なし（既存Task9の残試験への主担当切替と中断） / worklog=棄却（既存の終了・再開経路確認手順、先行記録2026-09-15-03）
- 2026-09-17 Codex側往復完了・Issue-0151 close: ADR=0201 / worklog=棄却（既存の承認・実機検証手順内、539e100）
- 2026-09-17 443番限定の訂正 spec 確定点・修正検証: ADR=0199 / worklog=棄却（既存手順内） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・1回・実質的な収束）
- 2026-09-17 タスク9(a-2)完了・改訂ADR-0199のspec 確定点: ADR=0199 / worklog=棄却（既存の検証・修正・承認手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回・実質的な収束）
- 2026-09-16 タスク9(a) の構成確定と ADR-0199 コミット・spec 確定点: ADR=0199（Proposed。昇格はサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-16-04` / review=フル実施（claude-sonnet-5・1 回）＋差分再確認（claude-sonnet-5・1 回・提示後確定（実質的な収束に至らず））
- 2026-09-09 spec 確定点: ADR=0151・0152 / worklog=棄却（既存の機械検証と確定手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回）＋機械検証（1回・提示後確定（実質的な収束に至らず））
- 2026-09-09 ADR-0151・0152 Accepted 昇格: ADR=0151・0152 / worklog=棄却（既存の昇格手順） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 履歴レビュー完了・ADR-0150 Accepted 昇格: ADR=0150 / worklog=棄却（既存のレビュー照合・修正・検証手順の範囲） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 v2 plan 確定点: ADR=なし（既存計画の主担当実行を選択） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 v3 spec 確定点: ADR=0157・0158 / worklog=棄却（既存の独立レビュー・指摘照合手順内） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-09 ADR-0157/0158 Accepted 昇格: ADR=0157・0158 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-10 試作条件改訂 spec 確定点: ADR=0160・0161 / worklog=棄却（既存の独立照合・修正手順内） / review=差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-10 ADR-0159〜0161 Accepted 昇格: ADR=0159〜0161 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-15 v3実装計画の plan 確定点: ADR=0193改訂・0196・0197（Proposed。昇格は実装完了時のサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-15-02` / review=フル実施（claude-opus-5・4 回）＋差分再確認（claude-opus-5・5 回・提示後確定（実質的な収束に至らず））

## 次セッション開始時のアクション

1. masterからstart-workした場合も、先に本worktreeのこのhandoffと`docs/records/experiments/2026-09-18-task9-claude-code-roundtrip.md`を読む。両主担当の往復は完了済みで、繰り返さない。
2. Task9の記録が未コミットならコミットし、サイクル全体整合検査（decision-logの`references/cycle-consistency-check.md`）→最終レビュー→ADR-0162・0192〜0201の状態判定へ進む。
3. 作業はこのworktreeで行う。移動できなければ絶対パスとgit -Cを使い、masterへ成果物をコピーしない。既存19台と証拠を保全する。

## 重要な意思決定の履歴

- ADR-0157/0158: 提案/再実行の分離、4責務と補助設計の委任。Accepted。保護緩和・認証/費用/送信・削除/公開の個別相談は維持。
- ADR-0160/0161、0193〜0198: VM資源/外側停止・clipboard例外・保持/復旧・MCP登録0・未実証制限・負荷停止の限定流用・期限後照合。各正本と実装計画を参照。
- ADR-0199: OAuthセンチネル、モデル通信は2ホスト443番。全ポートという過去説明は訂正済み（Issue-0150 closed）。
- ADR-0200/0201: 最小起動確認を先に行い、提案だけCodex収録済み固定テンプレートを使用。画像変更案への利用者承認と実証は完了。
- 2026-09-18: ADR-0162・0192〜0201をAccepted昇格（全体整合検査1a0c4f5の後）。
