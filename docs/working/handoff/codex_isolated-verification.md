# Handoff: 隔離検証の共通起動処理

- **Branch**: codex/isolated-verification
- **Last Updated**: 2026-09-10 00:30 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 試作限定の条件改訂を確定 / 残るSSH等の能力確認へ

## 作業の目的・背景

Claude CodeまたはCodexの主担当から共通CLIで検証を依頼する。スクリプトでファイルと履歴を渡し、子Codexが資料検索・編集・テストを行う。ホスト上の子を専用MCPへ制限する旧仕様は成立条件を確認できず保留。既存隔離基盤による代替を検討している。

作業場所は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。既存worktreeを継続使用する。主な保存点は履歴付きコピー`049d2eb`、Linux試作仕様確定`7e8d464`。masterへ未統合で、隔離環境全体は未完成。

## 関連ドキュメント

- 現行確定仕様: `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`と詳細01〜04。schemaVersion=3、提案と採否用再実行の分離。静的フル1回・差分再確認2回で確定、実装・動的実証は未完。
- 旧v2のレビュー・確定記録: `docs/records/reviews/2026-09-09-linux-pilot-spec-final.md`。現行v3のレビューに流用しない。v3自己確認は`docs/records/reviews/2026-09-09-proposal-replay-spec-selfcheck.md`。
- v3確定記録: `docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`。r1/r2の指摘と採否・修正を同ディレクトリに保存。独立確認は静的のみ、原本・VM・実モデルの動作検証ではない。
- v3先行計画: `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md`。全体計画ではなく起動能力確認の先行工程。タスク0〜2は実施、タスク3でblocked。実測は`docs/records/experiments/2026-09-09-v3-runtime-preflight.md`。
- 方針・承認範囲: ADR-0151（Linux先行）、ADR-0157（案1、0152を置換）、ADR-0158（4責務・補助設計の委任）。旧0152の分担を新構成の包括承認へ流用しない。
- コピー実装: ADR-0150、`scripts/verification/README.md`、`docs/records/reviews/2026-09-09-history-copy.md`。Windows側のv1先行部品は実装済み。
- v2計画: `docs/working/plans/2026-09-09-isolated-verification-v2.md`。ユーザーが主担当で進める選択肢1を承認。独立レビューは見送り。タスク0でblocked、後続未実装。
- タスク0記録: `docs/records/experiments/2026-09-09-linux-pilot-activation.md`。CLI 0.153.4のヘルプ・プロトコル・公式文書で全実効ツール取得経路を特定できず。証拠の所在も同記録。
- 再検討: ADR-0153（Proposed）とIssue-0136の`0136-note-agent-container-reconsideration.md`。ユーザーが本体も隔離する構成の再検討を選択。具体構成は未採用。
- 既存基盤比較: ADR-0154（Proposed）、Issue-0136の`0136-note-existing-platform-comparison.md`。Docker Sandboxes、Codex cloud、Modal、独自Docker案を比較。ローカルsbxを第一実証候補として推奨、未採用。
- 導入記録: `docs/records/experiments/2026-09-09-sbx-preflight.md`。Windows 11 x64・WHP API成功。承認後に公式0.42.1 MSIをユーザー単位で導入し、実体・版・PATH・ヘルプを確認。
- AIなし試験案: Issue-0136の`0136-note-sbx-smoke-proposal.md`。共有スキル無効化フラグの受理、固定イメージdigest、合成Git入力を準備済み。ユーザー承認済み、VMは未作成。
- 試験実施記録: `docs/records/experiments/2026-09-09-sbx-smoke.md`。Docker認証とglobal deny-all設定済み（ADR-0155）。create再試行はsbx内部socket接続失敗。VM一覧は空。
- 旧計画: `docs/working/plans/2026-09-09-isolated-verification.md`はv1の実施記録。未完了タスクをそのまま再開しない。
- 課題の入口: `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-inspection-delegation-does-not-fire-destructive-verification-row.md`。
- 同Issueフォルダの`0136-note-network-risk-assessment.md`（Windows通信・読取の限界）、`0136-note-loopforalpha-sandbox-reuse.md`（既存基盤との差分）、`0136-note-linux-python-pilot.md`（承認時の構成案）を必要な論点だけ読む。
- 元チェックアウトの保全指示: `docs/working/handoff/master.md`。他worktree・stash・未追跡物・inboxの扱いを維持する。

## 完了済みタスク

- [x] v1先行部品を実装。コピー26件・履歴23項目＋fsck・プロセス7ケース・結果15ケースの4群が成功。証拠は履歴レビュー記録と旧計画。共通CLIやv2の成功ではない。
- [x] Linux用Dockerサービス・既存イメージと、標準.NETによるGET /version接続を読み取り確認。詳細はLinux試作ノートと仕様レビューr1。コンテナは試作起動していない。
- [x] Linux仕様4件をフル1回・差分再確認1回・機械検証16項目で確定。ADR-0151・0152を実装前のAcceptedへ昇格。`7e8d464`と最終レビュー記録を参照。
- [x] v2計画草案9タスクを作成。V1〜V7の対応、参照11件、PowerShell例9ブロックの構文を自己確認。独立レビュー・動作試験は未実施。詳細はv2計画末尾。
- [x] タスク0の読み取り調査を実施しblockedと判定。実行体・コマンド6件・プロトコル155メソッド等を記録。モデル・Dockerの起動なし。詳細はタスク0記録。
- [x] 既存基盤を公式資料とローカル配置で比較。現行sbxはPATH・既定配置で未検出、旧docker-sandboxは廃止案内。比較資料に未充足条件・準備負担・最小実証案を保存。
- [x] sbx導入前確認とMSI準備。WinGetは0.39.0まで、公式0.42.1を取得・検証。OS機能変更・ログイン・VM/モデル起動なし。詳細は導入前確認記録。
- [x] ユーザーの「1で」を受けsbx 0.42.1を導入。msiexec終了0、実体・版・PATH一致、8件のCLI確認成功。導入記録の追記を参照。
- [x] 通常ターミナル起動でsbx内部接続を回避し、AIなし搬入・回収・終了コード・停止試験成功。詳細はsbx-smoke記録20:21節。
- [x] v3の4責務・5仕様を独立レビュー3回で確定。N1限定の最終確認は解消・新規指摘0件。ADR-0157/0158を設計としてAcceptedへ昇格。実装は未着手。

## 進行中のタスク

- **現在の作業**: v3起動条件の不足について次手を判断する。
  - 状態: 03への退避と通常ターミナルでのsbx起動をユーザーが承認・実行。内部イメージ照会と固定VM作成に成功。合成搬入・履歴参照・出力回収・終了7・原本保全・VM停止を確認。sbx-smoke実施記録20:21節参照。
  - 残り: 通常起動・所有者調整をv3仕様へ反映。クリップボード等、pidsの強制、デーモン停止競合、認証・実Codexは起動前に実証が必要。旧v2計画をそのまま再開しない。
  - 状態補足: ユーザーが選択したN1限定再確認で解消・新規指摘0件。追加修正なしで実質的な収束と判定し、詳細仕様を確定。設計承認の再質問は不要。実装計画と起動前能力確認は後続。
  - 最新の状態: 実機ヘルプとsettings list --allを読み取り確認。clipboard文字列書込拒否とpids外側強制を確認できずblocked。SSH転送設定はtrue、変更なし。Issue-0136の0136-note-v3-capability-gaps.mdを参照。
  - 最新の採用: ユーザーが試作限定の意味を確認して推奨案を承認。ADR-0160/0161により厳密pids128を外し、VM割当・外側停止を維持、clipboard文字列書込は例外受容。00〜03仕様へ反映。通常運用・実モデル・設定変更は未承認。
  - 残り: 条件改訂の差分再確認2回で3指摘解消・新規指摘0件を確認し確定。次はSSH拒否・有限負荷中停止・切断競合等の実機試験具体化。確定記録は2026-09-10-synthetic-pilot-scope-r2.md。2条件と補完契約の承認を再質問しない。
  - 条件改訂の確定: ADR-0160/0161を設計としてAccepted、再検討方針0159も確定。元v3のレビューと今回の差分2回を区別。改訂前はC:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/20260910-pilot-scope-r1/に保全。設定・VM・モデル変更なし。
  - 改訂前退避: C:/Users/d12an/.ai-dev-review-snapshots/MakeAiInstructions/20260909-v3-spec-r2/（r1も保全）。5仕様とhash一致を確認。N1の最終確認結果はr3記録参照。
  - 維持する要求: Linux先行、リポジトリと履歴の探索、主担当2種・検証担当Codex、本文転記不要。旧仕様の子の配置と専用接続は再検討中。過去の仕様レビューの完了と新構成の未確定を区別する。
  - 承認済み: 主担当方式とv2計画レビュー見送り、既存基盤比較、sbx 0.42.1ユーザー導入、Dockerログイン、全体deny-all。承認時の回答は各ADR・導入記録・試験記録に保存。
  - 承認済み試験: `0136-note-sbx-smoke-proposal.md`の固定digest・合成入力・VM名`iv-sbx-smoke-20260909-01`・CPU2/2GiB・共有なし・作成/搬入/回収/停止。再開だけを理由に承認を取り直さない。
  - 未承認: OpenAI認証・実モデル起動・実プロジェクト送信・別イメージ/別基盤への変更・保護緩和・全体reset/削除/版入替え・公開。旧仕様の包括的実装を再開しない。
  - ADR-0153〜0155: 選択と適用の根拠を保存しProposedで引継ぐ。構成再検討と全体実証が未完了。次の確定チェックポイントで昇格要否・サイクル整合を確認する。

## 未着手のタスク

- [ ] 方針判断後のタスク0再開または仕様・計画改訂。全実効ツール取得の未確認を残してタスク1以降へ進まない。
- [ ] 専用MCP接続・ContainerRuntime・v2入出力と回収の実装、非rootマウント・通信・停止の実証、両主担当からの検査→回収→修正→再検証の往復、全体レビュー。
- [ ] 実装完了時のサイクル全体整合検査。設計時昇格のADR-0145〜0148・0151・0152の後追いを含む。マージ・振り返りはまだ対象段階に達していない。

## 既知のブロッカー・懸念

- ホストの全実効ツールを列挙・制限する方法は未確定。features.shell_tool=falseだけを成立根拠にしない。プロトコル定義の調査結果は仕様レビューr2。取得・制限不能ならblocked。
- Windowsの旧構成はループバック通信とコピー外の読取を許したため、実エージェントの自由な検証に使わない。Issue-0136のリスク評価ノートを参照。
- 既存Dockerイメージ内のGit等の実体、非rootの書き込み、exec証拠・停止は未実証。Dockerクライアント終了をコンテナ停止の代わりにしない。
- `.tmp/`の試験・コピー・ログ・junctionを保全する。共有一時領域の一括削除はしない。外部のレビュー退避先は各レビュー記録にある。既存LoopForAlphaのコンテナ等は変更していない。
- Claude送信承認は各回に固定した資料が対象。実施済みレビューの送信を繰り返さず、未送信の候補資料を承認済みにしない。全レビューの実行は終了済み。
- 導入済みプラグイン0.1.24とリポジトリ予定版0.1.25を区別する。ローカルの仕様・コードの保存をプラグインへの反映と扱わない。
- sbx 0.42.1は`C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe`。通常ターミナルで起動したdaemonは維持。VM1台はstopped、deny有効。Codexからdaemonを再起動せず状態を確認する。sbx-smoke実施記録20:21節参照。
- 旧状態はstate/sandboxd-preserved-20260909-02と03、新状態はstate/sandboxdに保持。イメージ・試験VM・ログ・回収ファイルも保全。削除や自動巻き戻しはしない。実施記録20:21節参照。
- LoopForAlpha用Docker Desktopは別接続。最終確認時はdesktop-linuxのパイプ不存在・関連プロセス未検出。sbx内部socket障害との直接関係は確認できず。再設定・再起動は行っていない（sbx-smoke追加確認節）。

## 節目ごとの確認記録

- 2026-09-09 spec 確定点: ADR=0151・0152 / worklog=棄却（既存の機械検証と確定手順） / review=フル実施（claude-sonnet-5・1回）＋差分再確認（claude-sonnet-5・1回）＋機械検証（1回・提示後確定（実質的な収束に至らず））
- 2026-09-09 ADR-0151・0152 Accepted 昇格: ADR=0151・0152 / worklog=棄却（既存の昇格手順） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 履歴レビュー完了・ADR-0150 Accepted 昇格: ADR=0150 / worklog=棄却（既存のレビュー照合・修正・検証手順の範囲） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 plan 確定点: ADR=なし（既存仕様と工程の選択、設計変更なし） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 先行範囲の確認・ADR-0149 Accepted 昇格: ADR=0149 / worklog=棄却（既存の確認手順内） / cyclecheck=実施（修正: Issue-0136）
- 2026-09-09 セッション終了の引き継ぎ確定: ADR=なし（ユーザーの中断指示、方針変更なし） / worklog=棄却（通常の中断処理で新たなdeltaなし）
- 2026-09-09 v2計画草案の作成・自己確認: ADR=なし（確定仕様のタスク化、方針変更なし） / worklog=棄却（既存の計画・自己確認手順内）
- 2026-09-09 v2 plan 確定点: ADR=なし（既存計画の主担当実行を選択） / worklog=棄却（deltaなし） / review=見送り
- 2026-09-09 タスク0の読み取り調査blocked: ADR=なし（既定の停止条件を適用） / worklog=棄却（計画どおりの調査・停止）
- 2026-09-09 子Codex本体の隔離構成の再検討へ移行: ADR=0153 / worklog=棄却（通常の構成再検討、deltaなし）
- 2026-09-09 既存隔離基盤の比較: ADR=0154 / worklog=棄却（既存の一次資料調査と環境照合）
- 2026-09-09 sbx導入前確認・配布物検証: ADR=なし（比較案に沿う前提確認） / worklog=棄却（既存の実体確認と署名検証）
- 2026-09-09 sbx導入・CLI確認: ADR=なし（承認されたパッケージ導入） / worklog=棄却（既存の導入・実体検証手順）
- 2026-09-09 共有スキル引数確認・AIなし試験の具体化: ADR=なし（既存試験案の具体化、採用未確定） / worklog=棄却（既存の対照確認手順内）
- 2026-09-09 Docker認証・VM作成前提で停止: ADR=なし（全体設定は未決） / worklog=棄却（既存の前提確認・承認範囲検査）
- 2026-09-09 sbx deny-all設定・内部接続失敗の切り分け: ADR=0155 / worklog=棄却（既存のログ・実体・対照検査内）
- 2026-09-09 新セッション向け引き継ぎ確定: ADR=0153〜0155（再検討・実証未完でProposed） / worklog=棄却（既存の中断・承認範囲整理）
- 2026-09-09 ソケット対照検証・sbx再起動失敗: ADR=なし（障害切り分け、退避案は未採用） / worklog=棄却（既存の仮説・対照検証手順内）
- 2026-09-09 承認後の状態退避・内部接続障害再発: ADR=0156 / worklog=棄却（既存の保全・対照検証・停止手順内）
- 2026-09-09 保存先差の独立再現・通常ターミナル比較準備: ADR=なし（切り分けのみ、構成変更なし） / worklog=棄却（既存の最小再現・対照検証手順内）
- 2026-09-09 通常ターミナルの対照成功: ADR=なし（原因調査の実測、運用方法は未確定） / worklog=棄却（既存の対照検証手順内）
- 2026-09-09 通常起動で内部接続復旧・AIなし試験成功: ADR=0156（追加の個別承認を追記） / worklog=棄却（既存の実体・対照検証手順内）
- 2026-09-09 sbx構成案と旧保護条件の差分整理: ADR=なし（2案は未採用） / worklog=棄却（既存の設計比較手順内）
- 2026-09-09 案1の基本方針承認・機能分割案作成: ADR=0157（0152を置換、詳細設計中） / worklog=棄却（既存の意思決定・機能分割手順内）
- 2026-09-09 4責務承認・v3詳細仕様草案と自己確認: ADR=0158・0157（詳細確定時に昇格整合を確認） / worklog=棄却（既存の設計・整合検証手順内）
- 2026-09-09 v3 spec 確定点: ADR=0157・0158 / worklog=棄却（既存の独立レビュー・指摘照合手順内） / review=フル実施（gpt-5.6-sol・1回）＋差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-09 ADR-0157/0158 Accepted 昇格: ADR=0157・0158 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）
- 2026-09-09 v3実装前の能力読み取り確認blocked: ADR=なし（確定仕様の起動前停止条件を適用） / worklog=棄却（既存の前提実在・実体照合手順内）
- 2026-09-09 資源保護・clipboard条件の再検討案: ADR=0159（再検討のみ承認、変更案未採用） / worklog=棄却（既存の保護目的・代替案比較手順内）
- 2026-09-10 試作限定の2条件採用・仕様反映: ADR=0160・0161 / worklog=棄却（既存の個別承認・仕様照合手順内）
- 2026-09-10 試作条件改訂 spec 確定点: ADR=0160・0161 / worklog=棄却（既存の独立照合・修正手順内） / review=差分再確認（gpt-5.6-sol・2回・実質的な収束）
- 2026-09-10 ADR-0159〜0161 Accepted 昇格: ADR=0159〜0161 / worklog=棄却（既存の設計確定手順内） / cyclecheck=非該当（実装前昇格）

## 次セッション開始時のアクション

1. 既存worktreeでstart-workを実行し、本handoff、`docs/records/experiments/2026-09-09-sbx-smoke.md`、Issue-0136の`0136-note-sbx-smoke-proposal.md`を読む。旧仕様00〜03とv2計画は必要箇所だけ参照する。
2. 2026-09-10-synthetic-pilot-scope-r2記録を読み、SSH拒否等の残る能力試験を具体化する。2条件の試作限定採用と補完契約は確定。設定変更・実機操作・実モデル起動は別に具体化し、旧v2計画は実行しない。
3. 承認済み範囲と実体に変更がなければ固定試験の許可を再質問しない。構成変更・モデル起動等は別判断。`.tmp/`・他worktree・stashを保全する。別セッション開始はユーザーが指示する。

## 重要な意思決定の履歴

- ADR-0145〜0149: 自律テスト作成、主担当2種・検証担当Codex、共通CLIと3責務、独立Git、AIなし部品の先行。
- ADR-0150: ファイルとGit履歴をスクリプトで独立コピーへ渡す。
- ADR-0151・0152: Linux試作を先行し、ホスト上の子の操作を専用MCP接続でコンテナ内へ限定する。設計としてAcceptedで、動的実証は後続。
- ADR-0153〜0155: 子本体の隔離再検討、既存基盤の比較先行、sbx全体ネットワークdeny-all。個別承認の根拠は各本文に保存。
- ADR-0156: 旧sbx状態領域を保全して起動復旧を試す。操作承認・実施済み、全体の実証は未完。
- ADR-0157: 案1の基本方針を採用し、提案作成と採否用再実行を分離。旧ADR-0152を置換。詳細仕様確定時のAccepted、実装は未完。
- ADR-0158: 準備・提案・再実行・照合の4責務と補助設計の分担。ADR-0147を部分変更。詳細仕様確定時のAccepted。
