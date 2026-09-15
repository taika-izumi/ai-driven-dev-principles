# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-15 13:55 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 新規開発/v3全体の実装計画を確定（plan確定点通過・コミット済み）、実装着手前

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。スクリプトで原本のファイル・Git履歴を独立コピーし、sbx内Codexが調査・提案する。採否用のテストは別の通信なし環境で再実行し、外側の記録で照合する。資料本文の手動転記は不要にする。

既存worktreeは`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。保存点はv3仕様確定`b7941f3`、試作条件改訂確定`5259d22`、SSH設定操作記録`cf853d2`、能力試験の取得元特定とADR-0192`e02c32c`。masterへ未統合。2026-09-14にユーザーが本作業の再開を選択し（masterのhandoffで「2で」）、残る能力試験を実施した。

## 関連ドキュメント

- 能力試験の取得元・方式と実施結果: `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`。試験A（SSH転送拒否）・B（CPU/メモリ実効値）・C（有限負荷中の外側停止）・D（起動世代）はすべて合格。原文は `.tmp/sbx-capability-20260914/`（番号付きファイル）。個別承認はADR-0192（Proposed）。
- 継続調査・操作記録: `docs/records/experiments/2026-09-10-v3-capability-followup.md`。SSH設定false保存・停止・通常起動後の設定と既存VM照合まで完了。ADR-0162は次の全体整合チェックポイントで昇格するProposed。
- 現行仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と01〜04。schemaVersion=3、4責務。試作条件は`5259d22`に、2026-09-15のADR-0196（acceptedLimitations 3件目）を作業ツリーで追記（未コミット）。実装は未着手。
- 方針と分担: ADR-0157（提案と再実行の分離）、ADR-0158（4責務と補助設計の委任）。両方Accepted。保護の追加変更・新基盤・利用者作業・認証/費用/送信・削除/公開は相談。
- 試作条件: ADR-0160（厳密pids128を外してVM割当・外側停止へ）、ADR-0161（clipboard文字列書込の限定例外）。両方Accepted。再検討のADR-0159もAccepted。
- v3レビュー確定: `docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`。条件改訂レビュー確定: `docs/records/reviews/2026-09-10-synthetic-pilot-scope-r2.md`。
- v3全体の実装計画: `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`（草案bd3beca、第1回反映47109dc、第2〜9回反映と確定は本handoffと同じコミット）。レビューの採否と相談事項4〜7は同計画「確定前の確認状況」節が正本。sbxの実測挙動の整理は `docs/reference/sbx-sandbox-runtime-facts.md`（67923c6）。
- 先行計画: `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md`。タスク3の実機試験案の項目は2026-09-14に完了へ更新。
- 能力確認: `docs/records/experiments/2026-09-09-v3-runtime-preflight.md`。条件見直しと承認: Issue-0136の`0136-note-v3-capability-gaps.md`。
- sbx導入・起動とAIなし実証: `docs/records/experiments/2026-09-09-sbx-preflight.md`、`2026-09-09-sbx-smoke.md`。固定試験の承認範囲: Issue-0136の`0136-note-sbx-smoke-proposal.md`。
- コピー先行部品: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。v1部品とv3全体を区別する。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。master側の結論（61ddef3）で、本案件の再開経路をIssue-0136が担うと明記されている。本branchには未取り込み。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。
- 旧構成の履歴: ADR-0152は0157によりSuperseded。旧v2計画`docs/working/plans/2026-09-09-isolated-verification-v2.md`と旧Linuxレビューは参照資料だけで、実装再開しない。
- プロジェクトの目的・方針: `docs/overview/project-purpose.md`（対象ルートD:/Dev/002_AiDev/MakeAiInstructions、参照内容はmaster 5350b9fの同パス。本branchには未取り込み）。判断根拠はADR-0130・0183。
- 判断の分担: ADR-0158の補助設計委任（`docs/current/specs/2026-09-09-isolated-verification/00-overview.md`「判断の分担と参照」、承認時点b7941f3）。実機・設定・モデル操作は個別承認（ADR-0162、ADR-0192）。

## 完了済みタスク

- [x] v3全体の実装計画の草案作成（bd3beca）と第1回確定前レビュー反映。相談事項1〜3をADR-0193〜0195（Proposed）に記録（47109dc、2026-09-15 完了）。
- [x] 実装計画の確定前レビュー反復（フル4回＋差分5回、いずれも新規 claude-opus-5）と相談事項4〜7の確定（ADR-0193改訂・0196・0197）。第9回反映後に「このまま確定」で plan 確定点を通過。不採用は第5回 m-F の1件（2026-09-15 完了）。
- [x] 残る能力試験の未特定事項を読み取りで特定（SSH転送の実体・資源割当の外側記録・起動世代の取得元・非自動起動の代替手順）。記録は2026-09-14-v3-capability-test-methods.md、コミットe02c32c（2026-09-14 完了）。
- [x] 試験A〜Dを新規VM `iv-sbx-capability-20260914-01`（ID 0baac92d-251c-4f34-9d8f-6f14a9c238c6）で実施し全件合格。VMは停止したまま保持、削除なし。ADR-0192で個別承認を保存（2026-09-14 完了）。
- [x] SSH転送falseの保存、daemon停止、利用者の通常起動後の設定・既存VM照合を完了。`cf853d2`、ADR-0162、継続調査記録を参照。
- [x] v1のコピー・履歴・プロセス管理・結果照合を先行実装し4群の試験成功。詳細はhistory-copyレビューとscripts/verification/README.md。
- [x] sbx 0.42.1のユーザー導入・Dockerログイン・global deny-all設定。導入・smoke記録に個別承認を保存。
- [x] sbx内部socket障害を切り分け、通常PowerShell起動で回避。合成ファイルと履歴の搬入、通常ユーザーで出力、終了7、回収、原本保全、VM停止を確認。smoke記録20:21節参照。
- [x] v3の4責務・5仕様を独立レビュー3回で確定し、ADR-0157/0158を設計としてAccepted。保存点b7941f3。
- [x] 資源条件とclipboard例外を試作限定で承認・反映し、差分レビュー2回で確定。ADR-0159〜0161をAccepted。保存点5259d22。

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の確定を終え、実装着手の判断待ち。
  - 状態: 計画は `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md` で確定（plan 確定点、通常型、フル4回＋差分5回、提示後確定〈実質的な収束に至らず〉）。改訂前退避は `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-15-v3-plan-before-r3/`〜`-r9/`。第6回以降の指摘はすべて反映の追随漏れで、反映時は受け側の契約（引数型・偽sbx・試験文・承認区切り・対応表・ADR本文）まで追随させ grep で確認する（worklog 2026-09-15-02）。
  - 残り: 利用者が実装着手（タスク1〜7。実行スキルは `subagent-driven-development` 既定、実行直前に `plan-deviation-defaults.md` を適用）を指示したら着手する。タスク8・9は個別承認の提示を経る。
  - 判断の分担: ADR-0158の補助設計委任は有効。実機・設定・モデル操作の承認はADR-0162・0192の範囲に限り、計画のタスク8・9は個別承認を別に得る。

## 未着手のタスク

- [ ] v3全体の実装計画の実行（タスク1〜7、個別承認後にタスク8・9）。計画確定後に着手する。
- [ ] 残る未実証: daemon停止を伴う切断・自動起動競合の注入、実行中の保護変更検知、通信・共有・その他ホスト経路（試験Aのdeny-all拒否は転送ポートの対照に限る）、認証・最小モデル試験。いずれも別承認。
- [ ] 実装完了時のサイクル全体整合検査と最終レビュー。ADR-0162・0192のAccepted昇格を含む。masterへのマージ・振り返りはまだ対象段階ではない。

## 既知のブロッカー・懸念

- sbx daemonは2026-09-14 23:00:28に利用者起動の新世代（PID 29352、v0.42.1）で稼働していたが、2026-09-15のPC強制再起動後の状態は未確認（停止している見込み）。停止・再起動・resetはAIから行わない。停止中に自動起動しうる`ls`/`inspect`/`settings`は、`daemon status`（自動起動しない。今回3回確認）でrunningを確認した後だけ呼ぶ。
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
- 2026-09-15 実装計画の草案とレビュー2回の反映・再起動からの復旧: ADR=0193〜0195（相談1〜3、Proposed） / worklog=`MakeAiInstructions-2026-09-15-01`
- 2026-09-15 v3実装計画の plan 確定点: ADR=0193改訂・0196・0197（Proposed。昇格は実装完了時のサイクル全体整合検査で） / worklog=`MakeAiInstructions-2026-09-15-02` / review=フル実施（claude-opus-5・4 回）＋差分再確認（claude-opus-5・5 回・提示後確定（実質的な収束に至らず））

## 次セッション開始時のアクション

1. 本worktreeでstart-work。本handoffと確定済みの実装計画 `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md`（共通制約・承認の境界・タスク1〜9・確定前の確認状況）を読む。
2. 利用者の指示で実装に着手する。実行直前に `start-work` の `references/plan-deviation-defaults.md` を読み、`subagent-driven-development`（タスク別の仕様適合レビューつき）で進める。タスク8・9は承認区切り表の内容を提示して個別承認を得る。確定なら plan 確定点の行を記録し、計画・ADR-0193改訂・ADR-0196・0197・仕様00/02/03・handoff を同じコミットに入れる。回答に従い、確定なら plan 確定点の行を記録して計画・ADR-0193改訂・ADR-0196・仕様02/03・handoff を同じコミットに入れる。
3. sbx操作は`daemon status`でrunningを確認してから行い、停止中はAIから起動しない。試験VM2台は削除しない。新たな実機・設定・モデル操作はADR-0162・0192の範囲外なら個別に確認する。

## 重要な意思決定の履歴

- ADR-0193〜0195: 実行中はセッション保持でsbxの自動停止を避ける／CLI異常終了後に記録済みVMを停止する／登録MCPサーバー0件を「MCPなし」の条件とする。2026-09-15のユーザー選択、Proposed。0193は同日に停止順序を改訂（改訂記録あり）。
- ADR-0196: 試作の間はデーモン切断の検知を未確認の制限として認める（acceptedLimitations 3件目）。2026-09-15のユーザー選択、Proposed。仕様02・03を更新済み。
- ADR-0197: 提案用実行設定の証拠は提案用VMで取り直し、負荷中の外側停止だけ既存記録を使う。2026-09-15のユーザー選択（案1の懸念を説明のうえ案3）、Proposed。
- ADR-0192: 残るsbx能力試験を新規VM1台で順に実施する。個別承認、試験A〜D合格。全体整合チェックポイントで昇格するProposed。
- ADR-0162: ローカルsbxのSSH転送を無効化する操作を個別承認。保存・停止・通常起動後照合済み。全体整合チェックポイントで昇格するProposed。
- ADR-0145〜0150: 検証担当の追加テスト作成、主担当2種・検証担当Codex、共通CLI、独立コピー、Git履歴提供。
- ADR-0151: Linux先行。ADR-0152のホスト上子と専用MCP構成は0157により置換済み。
- ADR-0153〜0156: 子本体隔離の再検討、既存基盤比較、deny-all設定、状態保全による起動復旧。根拠は各ADRとsmoke記録。
- ADR-0157/0158: 提案と採否用再実行の分離、準備・提案・再実行・照合の4責務と補助設計の分担。Accepted。
- ADR-0159〜0161: 保護目的の再検討、試作限定のVM資源保護とclipboard文字列書込例外。Accepted。通常運用・モデル起動の承認ではない。
