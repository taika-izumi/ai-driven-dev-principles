# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-14 23:12 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 調査・実測/残る能力試験A〜Dの実施完了、全体実装計画の作成前

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。スクリプトで原本のファイル・Git履歴を独立コピーし、sbx内Codexが調査・提案する。採否用のテストは別の通信なし環境で再実行し、外側の記録で照合する。資料本文の手動転記は不要にする。

既存worktreeは`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。保存点はv3仕様確定`b7941f3`、試作条件改訂確定`5259d22`、SSH設定操作記録`cf853d2`、能力試験の取得元特定とADR-0192`e02c32c`。masterへ未統合。2026-09-14にユーザーが本作業の再開を選択し（masterのhandoffで「2で」）、残る能力試験を実施した。

## 関連ドキュメント

- 能力試験の取得元・方式と実施結果: `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`。試験A（SSH転送拒否）・B（CPU/メモリ実効値）・C（有限負荷中の外側停止）・D（起動世代）はすべて合格。原文は `.tmp/sbx-capability-20260914/`（番号付きファイル）。個別承認はADR-0192（Proposed）。
- 継続調査・操作記録: `docs/records/experiments/2026-09-10-v3-capability-followup.md`。SSH設定false保存・停止・通常起動後の設定と既存VM照合まで完了。ADR-0162は次の全体整合チェックポイントで昇格するProposed。
- 現行仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と01〜04。schemaVersion=3、4責務。現在の試作条件は`5259d22`。実装は未着手。
- 方針と分担: ADR-0157（提案と再実行の分離）、ADR-0158（4責務と補助設計の委任）。両方Accepted。保護の追加変更・新基盤・利用者作業・認証/費用/送信・削除/公開は相談。
- 試作条件: ADR-0160（厳密pids128を外してVM割当・外側停止へ）、ADR-0161（clipboard文字列書込の限定例外）。両方Accepted。再検討のADR-0159もAccepted。
- v3レビュー確定: `docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`。条件改訂レビュー確定: `docs/records/reviews/2026-09-10-synthetic-pilot-scope-r2.md`。
- 先行計画: `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md`。タスク3の実機試験案の項目は2026-09-14に完了へ更新。全体実装計画はまだ未作成。
- 能力確認: `docs/records/experiments/2026-09-09-v3-runtime-preflight.md`。条件見直しと承認: Issue-0136の`0136-note-v3-capability-gaps.md`。
- sbx導入・起動とAIなし実証: `docs/records/experiments/2026-09-09-sbx-preflight.md`、`2026-09-09-sbx-smoke.md`。固定試験の承認範囲: Issue-0136の`0136-note-sbx-smoke-proposal.md`。
- コピー先行部品: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。v1部品とv3全体を区別する。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。master側の結論（61ddef3）で、本案件の再開経路をIssue-0136が担うと明記されている。本branchには未取り込み。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。
- 旧構成の履歴: ADR-0152は0157によりSuperseded。旧v2計画`docs/working/plans/2026-09-09-isolated-verification-v2.md`と旧Linuxレビューは参照資料だけで、実装再開しない。
- プロジェクトの目的・方針: `docs/overview/project-purpose.md`（対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容はmaster 5350b9fの同パス。本branchには未取り込み）。判断根拠はADR-0130・0183。
- 判断の分担: ADR-0158の補助設計委任（`docs/current/specs/2026-09-09-isolated-verification/00-overview.md`「判断の分担と参照」、承認時点b7941f3）。実機・設定・モデル操作は個別承認（ADR-0162、ADR-0192）。

## 完了済みタスク

- [x] 残る能力試験の未特定事項を読み取りで特定（SSH転送の実体・資源割当の外側記録・起動世代の取得元・非自動起動の代替手順）。記録は2026-09-14-v3-capability-test-methods.md、コミットe02c32c（2026-09-14 完了）。
- [x] 試験A〜Dを新規VM `iv-sbx-capability-20260914-01`（ID 0baac92d-251c-4f34-9d8f-6f14a9c238c6）で実施し全件合格。VMは停止したまま保持、削除なし。ADR-0192で個別承認を保存（2026-09-14 完了）。
- [x] SSH転送falseの保存、daemon停止、利用者の通常起動後の設定・既存VM照合を完了。`cf853d2`、ADR-0162、継続調査記録を参照。
- [x] v1のコピー・履歴・プロセス管理・結果照合を先行実装し4群の試験成功。詳細はhistory-copyレビューとscripts/verification/README.md。
- [x] sbx 0.42.1のユーザー導入・Dockerログイン・global deny-all設定。導入・smoke記録に個別承認を保存。
- [x] sbx内部socket障害を切り分け、通常PowerShell起動で回避。合成ファイルと履歴の搬入、通常ユーザーで出力、終了7、回収、原本保全、VM停止を確認。smoke記録20:21節参照。
- [x] v3の4責務・5仕様を独立レビュー3回で確定し、ADR-0157/0158を設計としてAccepted。保存点b7941f3。
- [x] 資源条件とclipboard例外を試作限定で承認・反映し、差分レビュー2回で確定。ADR-0159〜0161をAccepted。保存点5259d22。

## 進行中のタスク

- **現在の作業**: 能力試験の記録と引き継ぎの確定。
  - 状態: 試験A〜Dの結果と申し送りを実験記録へ追記済み。先行計画タスク3の該当項目を完了へ更新済み。本handoff更新後にコミットする。
  - 残り: ユーザーが次手を選ぶ。候補は (1) v3全体の実装計画の作成（writing-plans）、(2) 本セッションの終了。
  - 判断の分担: ADR-0158の補助設計委任は有効。実機・設定・モデル操作の承認はADR-0162・0192の範囲に限り、新たな操作は個別に確認する。
  - 実装計画への申し送り（記録の「試験の途中で判明した挙動」が正本）: VMは最後のセッション切断から30秒で自動停止し、cp/execは停止VMを自動起動する。SbxRuntimeはセッション保持または再起動前提の設計が必要。停止確認は自動停止と外側停止をdaemon.logで区別する。透過プロキシはTCP接続を受けてから拒否するため、接続成立を到達の証拠にしない。

## 未着手のタスク

- [ ] v3全体の実装計画（現行仕様からRequestCopyのv3、stdin/出力上限、SbxRuntime、Proposal、Replay、Result、CLIと試験）。コード・schema・否定fixture、個別承認後の最小モデル試験、両主担当の往復。activationEvidenceへの今回の証拠の対応付けを含める。
- [ ] 残る未実証: daemon停止を伴う切断・自動起動競合の注入、実行中の保護変更検知、通信・共有・その他ホスト経路（試験Aのdeny-all拒否は転送ポートの対照に限る）、認証・最小モデル試験。いずれも別承認。
- [ ] 実装完了時のサイクル全体整合検査と最終レビュー。ADR-0162・0192のAccepted昇格を含む。masterへのマージ・振り返りはまだ対象段階ではない。

## 既知のブロッカー・懸念

- sbx daemonは2026-09-14 23:00:28に利用者起動の新世代（PID 29352、v0.42.1）で稼働中。停止・再起動・resetはAIから行わない。停止中に自動起動しうる`ls`/`inspect`/`settings`は、`daemon status`（自動起動しない。今回3回確認）でrunningを確認した後だけ呼ぶ。
- 試験VM `iv-sbx-capability-20260914-01` と旧smoke VM `iv-sbx-smoke-20260909-01` はいずれもstoppedで保全。削除・再作成しない。`.tmp/sbx-capability-20260914/` の原文とスクリプト（guest-probe.sh、bounded-load.py、agent-protocol-probe.py）も保全。
- 利用者はリモート操作中の場合があり、通常PowerShellでの起動を求める手順が即時に実行できないことがある。今回は利用者側で起動が行われたが、AIから起動する案（ツール経由・タスクスケジューラ）は採用していない。
- masterの最新記録（61ddef3、13cbe7a）とADR-0163〜0191は本branchに未取り込み。ADR採番は全ブランチの最大値に合わせて0192とした。索引は0162の次に0192が並ぶ。
- 過去のsbx導入・smokeの個別節目行がhandoffにない。実験記録は存在するが今回の実施扱いで埋めない。
- sbx実体はC:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe。状態ディレクトリは同AppData配下のsandboxes/state/sandboxd（runtimeファイル・daemon.log・PIDファイル）。旧退避sandboxd-preserved-20260909-02/03は保全。
- .tmpの試験・コピー・ログ・junctionを保全。既存試験VM・取得イメージ・returned.txtも削除しない。原本や他worktreeへ試験変更を加えない。
- 外部仕様退避はC:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/配下。レビューはすべて完了済み。過去の送信承認を別資料の送信へ流用しない。
- LoopForAlphaのDocker Desktopは別接続。設定・コンテナは保全。旧Windowsのホスト上子構成は自由な実検証へ使わない。
- 元チェックアウトの他worktree、stash 6e959892b6e00600006456172237f27d7957fa01、.claude/agents、docs/conversation_log.md、inbox3件は操作しない。詳細はmaster handoff。
- プラグイン導入版は0.1.29（本セッションのスキル一覧で確認）。仕様コミットをプラグインの更新・公開と扱わない。

## 節目ごとの確認記録

- 2026-09-10 作業中断の引き継ぎ確定: ADR=なし（ユーザーの中断指示、方針変更なし） / worklog=棄却（既存の中断・保全手順内）
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
- 2026-09-10 セッション切替の引き継ぎ確定: ADR=なし（合意済み工程の中断、方針変更なし） / worklog=棄却（既存の中断・正本参照整理手順内）
- 2026-09-14 能力試験の取得元特定と実機試験A〜Dの完了: ADR=0192（実機試験の個別承認、Proposed） / worklog=`MakeAiInstructions-2026-09-14-02`

## 次セッション開始時のアクション

1. 本worktreeでstart-work。本handoffと`docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（特に「試験の途中で判明した挙動」）を読む。masterの61ddef3（Issue-0136の結論）は既読扱いでよい。
2. 次手はv3全体の実装計画の作成（writing-plans）。現行仕様00〜04、ADR-0157/0158/0160/0161/0162/0192、v1部品（scripts/verification/）を入力にし、activationEvidenceへの今回の証拠の対応付けと自動停止・自動起動への対処を含める。plan確定点で確定前レビューを提示する。
3. sbx操作は`daemon status`でrunningを確認してから行い、停止中はAIから起動しない。試験VM2台は削除しない。新たな実機・設定・モデル操作はADR-0162・0192の範囲外なら個別に確認する。

## 重要な意思決定の履歴

- ADR-0192: 残るsbx能力試験を新規VM1台で順に実施する。個別承認、試験A〜D合格。全体整合チェックポイントで昇格するProposed。
- ADR-0162: ローカルsbxのSSH転送を無効化する操作を個別承認。保存・停止・通常起動後照合済み。全体整合チェックポイントで昇格するProposed。
- ADR-0145〜0150: 検証担当の追加テスト作成、主担当2種・検証担当Codex、共通CLI、独立コピー、Git履歴提供。
- ADR-0151: Linux先行。ADR-0152のホスト上子と専用MCP構成は0157により置換済み。
- ADR-0153〜0156: 子本体隔離の再検討、既存基盤比較、deny-all設定、状態保全による起動復旧。根拠は各ADRとsmoke記録。
- ADR-0157/0158: 提案と採否用再実行の分離、準備・提案・再実行・照合の4責務と補助設計の分担。Accepted。
- ADR-0159〜0161: 保護目的の再検討、試作限定のVM資源保護とclipboard文字列書込例外。Accepted。通常運用・モデル起動の承認ではない。
