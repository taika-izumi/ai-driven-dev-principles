# 残るsbx能力試験の調査と操作案

2026-09-10 00:44（Asia/Tokyo）。Issue-0136、先行計画 `docs/working/plans/2026-09-09-isolated-verification-v3-preflight.md` タスク3の継続調査。目的はSSH拒否等の実機操作を承認可能な形へ具体化すること。本記録は実施済み照会と未実施の操作案を区別する。全体実装計画の確定・実機試験の承認・runtimeのverifiedを意味しない。

## 引き継ぎと読み取り結果

- 既存worktreeのbranchはcodex/isolated-verification。開始時の変更は未追跡`.tmp/`だけ。Gitの所有者差異にはコマンド単位のsafe.directory指定を用い、global設定は変更していない。
- handoffは12,786バイトで40KB目安以内。既存の確定点・Accepted昇格行の必須欄は揃っている。過去のsbx導入・smokeに個別の節目行がない点は既存記録の不足として保持し、今回実施した確認へ読み替えない。
- 制限付き実行環境ではsettings storeとDocker configへのアクセス拒否を伴いdaemon statusがstoppedとなった。通常ユーザー側の読み取り再照会ではrunning。前者をホストdaemonの停止証拠にしない。
- 通常ユーザー側でrunning確認後に設定メタデータとVM一覧を照会。既存VM `iv-sbx-smoke-20260909-01` / `de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae` はstopped。他VMなし。
- `ssh.agentForwardingEnabled=true`、source=default、requires_restart=true。`ssh.agentSocketPath`は空、source=default、requires_restart=true。`clipboard.imagePaste=false`。今回広げたSSH項目抽出では`ssh.autoCreate=false`も確認した。これはSSH接続時のVM自動作成設定で、execやdaemonの自動起動を禁止する設定とは扱わない。
- 0.42.1のローカルヘルプでsettings set、daemon start/stop、execを確認。execは停止VMを先に起動すると明記され、非起動専用フラグは表示されない。起動直前のstatus確認だけでは、その直後の停止競合を防ぐ証明にならない。

設定・VM・daemonを変更するコマンドは今回実行していない。資格情報の値・ホストSSH鍵・clipboard内容は読んでいない。

## SSH拒否の設定操作案（提示時点は未承認・未実施）

対象はローカルsbx daemon全体の`ssh.agentForwardingEnabled`一項目。固定socketやDocker Desktopの設定は変更しない。影響は同daemonの全sandboxでSSHエージェントを使った署名・SSH認証ができなくなること。既存VMのディスクは保全するが、将来再開したときにも転送無効が適用される。

1. 直前に通常ユーザー側でdaemon runningと全VM stoppedを再確認。状態が変わった場合は操作を中止する。対象設定の値とsourceだけを記録する。
2. AIが次を1回実行し、設定を読み直してfalseを確認する。設定値がfalseでも、再起動前に拒否実証済みとは扱わない。

```powershell
& 'C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe' settings set ssh.agentForwardingEnabled false
```

3. AIが`sbx daemon stop`を実行してstoppedを確認する。停止失敗・状態不明なら後続しない。停止後はsettings/ls/create/execを呼ばない。
4. 過去の内部socket障害を避けるため、利用者が通常PowerShellで次を実行する。利用者作業はこの1コマンドと起動完了の返信。Codex内部からdaemon restart/startを代行しない。

```powershell
& 'C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe' daemon start -d
```

5. 通常ユーザー側でrunningを確認した後だけ設定・VM一覧を再照会し、転送false、画像読取false、既存VMが同じIDでstoppedであることを確認する。ログの全量・認証値を収集しない。

停止・再起動はdaemon共通の操作。再起動失敗の場合、設定falseと既存状態を保全して報告し、reset・状態退避・版入替え・自動復旧はしない。元に戻すには別途承認のうえ元のsource=defaultへ戻す設定操作と再起動が必要で、単にtrueを明示設定するだけでは元のsourceに戻らない。自動で転送trueへ戻さない。

この操作案の承認は設定変更・停止・通常起動・照会だけを対象とする。新規VM作成、負荷試験、モデル実行は含めない。

## 残る試験の方法と判定

以下は後続試験の材料であり、実行許可ではない。現行仕様00〜04とADR-0157/0158/0160/0161の条件を縮小しない。

| 試験 | 具体化した方法 | 必要な証拠・不合格条件 | 実行までに残る事項 |
|---|---|---|---|
| SSH転送拒否 | 転送false・新daemon起動世代を外側で記録。鍵を持たない専用の代用エージェントを試験用ソケットで待受け、ゲストのagentとrootの両方から固定のSSH agent照会を試す | 代用品へホスト側から接続可能という対照、ゲスト側から到達不能、ホスト側受付0件。空の鍵一覧は接続できた可能性があるので不合格。環境変数が空だけでも合格にしない | Windowsでsbxが利用する代用ソケットの対応方式、ゲストの実転送入口を特定する。実鍵のssh-add一覧や署名は使わない。方式未特定ならblocked |
| CPU・メモリ実効値 | 新規VMをCPU2・memory2gで作り、外側の当該VM割当記録とゲストCPU・メモリ観測を対応付ける | 外側割当が2 CPU/2048MiB。ゲストMemTotalは予約領域で減るため2048MiBとの完全一致を要求しない。ゲスト値だけで外側強制としない | VM割当を照会する実在の取得元と起動世代の取得元を特定する |
| 有限負荷中の外側停止 | 案: ゲスト内に最大2 CPU worker、合計256MiBまでの明示的確保、自己終了20秒。開始5秒後に外側から当該IDをstop。ログは合計1MiB以下、外側停止確認は30秒以内 | 負荷開始を確認してから停止し、同一IDのstoppedを外側で観測。負荷開始前の失敗を停止成功に数えない。停止未確認・予想外のホスト応答低下で後続を中止 | 固定スクリプトとhash、対象VM、監視・停止コマンドを準備して個別承認。fork bomb・資源枯渇試験は含めない |
| 時間・出力・stdin上限 | VMなしでv3プロセス入出力を実装し、有限な出力超過・stdinを消費しない子・非0終了をテスト。その後VMで停止まで接続 | 出力超過を切詰め成功にしない。stdin詰まりでもdeadlineとcleanupを超えない | v3実装・動作テストの計画が必要 |
| 切断・自動起動競合 | 事前status確認の後、exec送信前に停止が起きる位置を固定して試す。CLI異常終了時は外側停止担当が記録済みIDだけを処理する | daemon起動世代が変わらず、停止後に自動起動しない。確認不能なら不適合。チェックと操作の間の競合を単なる再照会で解決済みにしない | 非自動起動の接続手段と切断注入の方法は未特定。daemon停止を伴う試験は追加承認。既存daemonで無計画に競合を起こさない |
| 実行中の保護変更検知 | まず疑似接続先でpolicy/mount/resource/daemon世代が途中変更された応答を返し、後続中止と停止対象IDを照合 | 旧activationEvidenceや古いcheckedAtだけで続行しない | 実機の監視取得元・観測間隔・見逃す競合を特定。実機の保護緩和は別承認 |
| 未信頼回収 | VMなしのEnvelope fixtureで重複キー、絶対/親パス、予約名、大小文字重複、リンク祖先、過大wire/base64、途中切断を試す | 拒否時にaccepted外の書込0件、既存のsentinel hash不変。提案Pythonをホストで実行しない。sbx cpで未信頼tar等を展開しない | 受信器・fixture実装後に実VMからの固定出力へ接続 |
| Mutex競合 | 異なるrunId/runsRootの2プロセスが同じユーザー/daemonのMutexを取得。所有者終了も注入し、次回取得時に一覧確認を要求 | 2件目は待たずblocked、create呼出0件。放棄後も稼働VMがあれば新規作成しない | SbxRuntime実装とVMなしテスト。実機競合では同時2VMを作らない |
| 対象hash拒否 | 固定合成入力の内容・manifest・idを1点ずつ変異し、通常経路/recheckと作成前再確認を通す | hash不一致はcreate呼出0件。scopeだけ正しくても拒否。CLIに承認入力記録を自己生成させない | RequestCopy/CLIのv3実装と固定fixture |
| 通信・共有・その他ホスト経路 | replayで外向き/host/他VMの各到達試験とpolicy・mountの実効値を対応付ける。代用品だけで試す | deny規則の表示だけでは動的拒否を証明しない。到達先が最初から不在でも合格にしない。画像読取false、文字列書込例外を明示 | 接続可能な対照・固定宛先・送信内容を特定し個別承認。同時1VMと他VM稼働の対照が衝突する場合、無断で2VMに増やさず相談 |

実VM候補名は`iv-sbx-capability-20260910-01`、固定イメージ候補は既存smokeと同じ`docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`。新たな取得や別イメージへ自動変更せず、同名が既にあれば中止する。作成する場合の上限はCPU2/2048MiB・同時1VM・workspaceなし・共有skillsなし・deny-network '*'。停止後はVMとログを残す。今回、この候補の作成コマンドは実行していない。

次の実装計画には、各fixtureの編集内容と期待値、採用する接続方法、停止対象の外側記録を落とし込む。SSH設定だけ成立しても残る未確認を飛ばして全体profileをverifiedにしない。

## 根拠と信頼性

- 導入済みsbx 0.42.1のローカルヘルプと通常ユーザー側の関連設定メタデータ・VM一覧が当該PCの一次証拠。出力は本タスクのツール履歴にあり、上記に非秘密項目を記録した。
- [Docker公式の資格情報設定](https://docs.docker.com/ai/sandboxes/configuration/credentials/): 転送の既定有効、clientのSSH_AUTH_SOCK、固定socket設定、変更後のdaemon再起動を説明。提供元の一次資料。公開資料は更新されるため導入版メタデータと対応付けた。
- [Docker公式のトラブルシュート](https://docs.docker.com/ai/sandboxes/troubleshooting/): 鍵一覧が空でもagentへ到達している場合があることを説明。空一覧を転送拒否としない判定の根拠。
- 通常ターミナル起動を再利用する理由は`docs/records/experiments/2026-09-09-sbx-smoke.md`の内部socket障害と成功記録。今回新しい基盤へ変更する判断はしていない。

## 2026-09-10 00:49以降: 個別承認と設定変更・停止

ユーザーが直前の選択肢1に「1で」と回答。上記設定操作案の設定変更・停止・利用者の通常起動・再照会を承認した（ADR-0162）。新規VM・負荷・モデル試験への承認ではない。

通常ユーザー側でdaemon running、VMが既存の同一IDの1台のみでstopped、転送true/source=defaultを確認後、settings setを1回実行した。終了0。続くsettings listの読み直しでssh.agentForwardingEnabled=false/source=override/requires_restart=trueを確認した。

daemon runningと既存VMの同一ID/stoppedを再確認してdaemon stopを1回実行。終了0、`Daemon stopped successfully`。続くdaemon statusも終了0でstopped/not connected。停止後はsettings/ls/create/execを実行していない。

現在は利用者の通常PowerShellによる`daemon start -d`待ち。設定保存は確認済み、再起動後の反映とSSH拒否の動的実証は未確認。既存VMの作成・起動・exec・削除、認証・policy・clipboard・固定socket設定の変更は行っていない。停止後の既存VM再照会は自動起動回避のため起動後へ残した。

## 2026-09-10 00:53: 通常起動後の照合

ユーザーの「起動しました」を受け、通常ユーザー側でdaemon statusのrunningを確認後、設定とVM一覧を再照会した。すべて終了0。SSH転送はfalse/source=override、画像clipboard読取はfalse/source=default、固定SSH socketは空/source=default。既存VMは同じID de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae、stoppedの1台だけだった。

承認された設定保存・停止・通常起動・再照会は完了。転送拒否の動的実証、daemon起動世代の機械的な取得方法、残る能力試験は未完。設定照会をactivationEvidenceのverifiedへ読み替えない。ADR-0162は個別承認と設定操作結果を保存し、サイクル全体整合検査を伴う次の確定チェックポイントで昇格を処理する。