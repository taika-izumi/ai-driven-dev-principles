# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-10 00:57 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ユーザー指示で中断 / SSH設定操作完了、残る能力試験の調査前

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。スクリプトで原本のファイル・Git履歴を独立コピーし、sbx内Codexが調査・提案する。採否用のテストは別の通信なし環境で再実行し、外側の記録で照合する。資料本文の手動転記は不要にする。

既存worktreeは`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。保存点はv3仕様確定`b7941f3`、試作条件改訂確定`5259d22`、SSH設定操作記録`cf853d2`。masterへ未統合。中断は完了・承認撤回・自動再開の許可ではない。

## 関連ドキュメント

- 継続調査・操作記録: `docs/records/experiments/2026-09-10-v3-capability-followup.md`。SSH設定false保存・停止・通常起動後の設定と既存VM照合まで完了。動的拒否は未実証。ADR-0162は次の全体整合チェックポイントで昇格するProposed。
- 現行仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と01〜04。schemaVersion=3、4責務。現在の試作条件は`5259d22`。実装・動的実証は未完。
- 方針と分担: ADR-0157（提案と再実行の分離）、ADR-0158（4責務と補助設計の委任）。両方Accepted。保護の追加変更・新基盤・利用者作業・認証/費用/送信・削除/公開は相談。
- 試作条件: ADR-0160（厳密pids128を外してVM割当・外側停止へ）、ADR-0161（clipboard文字列書込の限定例外）。両方Accepted。再検討のADR-0159もAccepted。
- v3レビュー確定: `docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`。静的フル1回＋差分2回。r1/r2の指摘・対応・退避も同ディレクトリの記録を参照。
- 条件改訂レビュー確定: `docs/records/reviews/2026-09-10-synthetic-pilot-scope-r2.md`。差分2回、3指摘解消・新規指摘0件。入力hash束縛、CPU2/2048MiB固定、pilot共通排他を含む。
- 先行計画: `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md`。読み取り確認と条件見直しまで実施。全体実装計画はまだ未作成。残る実機試験を具体化する。
- 能力確認: `docs/records/experiments/2026-09-09-v3-runtime-preflight.md`。SSH転送既定true、clipboard画像読取false、自動起動の注意を確認。設定は変更していない。
- 条件見直しと承認: Issue-0136の`0136-note-v3-capability-gaps.md`。旧pids/clipboardのblockedから、ユーザー承認の試作条件へ変更した経緯を保持。
- sbx導入・起動とAIなし実証: `docs/records/experiments/2026-09-09-sbx-preflight.md`、`2026-09-09-sbx-smoke.md`。通常ターミナル起動で内部接続を回避し、搬入・履歴・終了7・回収・停止に成功。
- 固定試験の承認範囲: Issue-0136の`0136-note-sbx-smoke-proposal.md`。固定digest、合成入力、VM名、資源、共有なし、作成/搬入/回収/停止。試験は実施済み。
- コピー先行部品: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。v1部品とv3全体を区別する。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。本handoffのIssue-0136のノートはすべてこのフォルダ内。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。
- 旧構成の履歴: ADR-0152は0157によりSuperseded。旧v2計画`docs/working/plans/2026-09-09-isolated-verification-v2.md`と旧Linuxレビューは参照資料だけで、実装再開しない。

## 完了済みタスク

- [x] SSH転送falseの保存、daemon停止、利用者の通常起動後の設定・既存VM照合を完了。`cf853d2`、ADR-0162、継続調査記録を参照。動的拒否は未実証。
- [x] v1のコピー・履歴・プロセス管理・結果照合を先行実装し4群の試験成功。詳細はhistory-copyレビューとscripts/verification/README.md。
- [x] sbx 0.42.1のユーザー導入・Dockerログイン・global deny-all設定。導入・smoke記録に個別承認を保存。
- [x] sbx内部socket障害を切り分け、通常PowerShell起動で回避。合成ファイルと履歴の搬入、通常ユーザーで出力、終了7、回収、原本保全、VM停止を確認。smoke記録20:21節参照。
- [x] v3の4責務・5仕様を独立レビュー3回で確定し、ADR-0157/0158を設計としてAccepted。保存点b7941f3。
- [x] 資源条件とclipboard例外を試作限定で承認・反映し、差分レビュー2回で確定。ADR-0159〜0161をAccepted。保存点5259d22。

## 進行中のタスク

- **現在の作業**: 残る能力試験の具体化。
  - 中断: ユーザーが「作業は一旦中断」と指示し、ガイドラインの相談へ移行。残る調査は未着手のまま保持し、明示的な再開指示まで進めない。
  - 状態: 利用者の通常起動後、daemon running、転送false/source=override、画像読取false、既存VM同一ID/stoppedを確認。承認された設定操作は完了。動的拒否は未実証。
  - 次の具体作業: 継続調査記録のSSH代用ソケット、非自動起動の接続方法、外側資源・起動世代の取得元を特定し、対象とスクリプトを固定して実機試験を提示する。設定変更の承認は取り直さない。
  - 続く作業: CPU/メモリの実効値、有限負荷中の外側停止、切断/自動起動競合、未信頼回収、Mutex競合と対象hash拒否の試験を計画化する。
  - 全体実装: 現行仕様からRequestCopyのv3、stdin/出力上限、SbxRuntime、Proposal、Replay、Result、CLIと試験の計画を作る。実装は未着手。v1の既存実装・試験は維持。
  - 承認済み: 提案/再実行の分離、4責務、補助設計の分担、試作限定の資源条件とclipboard例外、それらのレビュー採否。詳細はADR-0157〜0161。再開だけを理由に再質問しない。
  - 試作の限度: 名指しした小さな合成題材だけ、CPU2・2048MiB・同時1VM・時間/出力上限・外側停止。clipboard文字列書込の可能性は開始/結果に明示し、画像読取は禁止。
  - 利用者に説明済みの負担: 試作中・直後はclipboardをそのまま貼り付けず、使う前に信頼できる元からコピーし直す。自動読取・復元・消去はしない。通常運用へ自動拡張しない。
  - 未承認: ADR-0162以外のホスト設定変更、新たな実機/負荷試験の具体操作、OpenAI認証・モデル/費用/送信、実プロジェクト、別基盤/別イメージ、追加の保護緩和、reset/削除/版入替え、公開。
  - 既存の固定smoke承認は撤回されていないが、試験は完了済みで同名VMも存在する。同名を上書き・再作成せず、新しい試験は対象と操作を具体化する。
  - ADR-0153〜0156は既にコミット済みのProposed。選択・操作の根拠は各本文と実験記録にある。次の整合チェックポイントで残る状態を確認し、未保存ドラフトと混同しない。

## 未着手のタスク

- [ ] 残る能力試験の具体化・必要な操作承認・実証。未確認のruntimeをverifiedにしない。
- [ ] v3全体の実装計画、コード・schema・否定fixture、個別承認後の最小モデル試験、両主担当の往復。
- [ ] 実装完了時のサイクル全体整合検査と最終レビュー。設計時昇格の関連ADRの後追いも含む。masterへのマージ・振り返りはまだ対象段階ではない。

## 既知のブロッカー・懸念

- 最新照会2026-09-10 00:53: 通常ユーザー側でdaemon running、既存smokeは同一ID/stoppedの1台。通常起動後の設定・VM照合まで完了。
- 非自動起動の実行方法・SSH代用ソケットの実在方式は未特定。事前status確認だけでは停止競合を防げない。`2026-09-10-v3-capability-followup.md`参照。
- 過去のsbx導入・smokeの個別節目行がhandoffにない。実験記録は存在するが今回の実施扱いで埋めない。既存の確定点・昇格行の必須フィールドは確認済み。
- sbx実体はC:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe。通常ターミナル起動が有効だった。Codexから自動起動・再起動せず、停止中のsettings/ls/execの自動起動副作用に注意。
- SSH転送は通常起動後の照会でもfalse/source=override。動的拒否は未確認。画像clipboard読取はfalse。旧pids128・文字列書込遮断条件は再導入しない。
- .tmpの試験・コピー・ログ・junctionを保全。既存試験VM・取得イメージ・returned.txtも削除しない。原本や他worktreeへ試験変更を加えない。
- sbx状態の旧退避はC:/Users/d12an/AppData/Local/DockerSandboxes/sandboxes/state/sandboxd-preserved-20260909-02と03。新状態は同親のsandboxd。自動巻き戻し・削除はしない。
- 外部仕様退避はC:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/配下。各r1/r2記録に名前を保存。レビューはすべて完了済み。過去の送信承認を別資料の送信へ流用しない。
- LoopForAlphaのDocker Desktopは別接続。設定・コンテナは保全。旧Windowsのホスト上子構成はループバック・コピー外読取の制限が未成立なので自由な実検証へ使わない。
- 元チェックアウトの他worktree、stash 6e959892b6e00600006456172237f27d7957fa01、.claude/agents、docs/conversation_log.md、inbox3件は操作しない。詳細はmaster handoff。
- プラグイン導入版0.1.24とリポジトリ予定版0.1.25は別。今回の仕様コミットをプラグインの更新・公開と扱わない。

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

## 次セッション開始時のアクション

1. ユーザーの再開指示後、指定の既存worktreeでstart-work。本handoffと`docs/records/experiments/2026-09-10-v3-capability-followup.md`を読む。SSH設定操作と通常起動後照合は完了済み。
2. 残る試験方法の未特定事項を調査し、実機操作を具体化してから提示する。再照会は通常ユーザー側でrunning確認後に行い、停止中に自動起動する照会をしない。
3. ADR-0157/0158/0160/0161の承認と保全条件を継承。仕様・試作条件・レビューは再承認不要。設定変更・実機/モデル操作は対象を具体化して確認。旧v2の後続は実行しない。

## 重要な意思決定の履歴

- ADR-0162: ローカルsbxのSSH転送を無効化する操作を個別承認。保存・停止・通常起動後照合済み。全体整合チェックポイントで昇格するProposed。
- ADR-0145〜0150: 検証担当の追加テスト作成、主担当2種・検証担当Codex、共通CLI、独立コピー、Git履歴提供。
- ADR-0151: Linux先行。ADR-0152のホスト上子と専用MCP構成は0157により置換済み。
- ADR-0153〜0156: 子本体隔離の再検討、既存基盤比較、deny-all設定、状態保全による起動復旧。根拠は各ADRとsmoke記録。
- ADR-0157/0158: 提案と採否用再実行の分離、準備・提案・再実行・照合の4責務と補助設計の分担。Accepted。
- ADR-0159〜0161: 保護目的の再検討、試作限定のVM資源保護とclipboard文字列書込例外。Accepted。通常運用・モデル起動の承認ではない。
