# タスク9: 443番限定の提案用VM2台の実機確認

## 結果と承認

2026-09-17、利用者が443番限定への訂正・修正後の新規2台再試験に「1で」と回答した承認に基づき、修正コミット352499cを新規VM2台で確認した。1台目の通信・認証・資源・転送と外側停止、2台目の異常終了後の自動停止と復旧は、必要な観測がすべて成立した。既存6台を保全し、終了時は合計8台すべてstopped。

初回失敗の訂正経緯は `2026-09-17-v3-task9-proposal-probe-first-attempt.md`。変更前後の試験・独立レビューは `docs/records/reviews/2026-09-17-task9-443-validation.md` と `2026-09-17-task9-443-independent-review.md`。既存11群、修正後の焦点試験、レビュー初回と差分再確認を終えてから実機を作成した。

## 固定条件

- sbx v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64。daemon PID25888、起動世代は2026-09-16 08:59:47 JSTのまま。
- テンプレート: `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`。
- 各VM CPU2・メモリ2GiB、同時に1台。各run全体3600秒、exec120秒、照会/stop60秒、作成/搬入240秒、出力16MiB。
- 実効許可はauth.openai.com:443、chatgpt.com:443だけ。他11ホストはポートなしdeny。専用キット・追加allowは作成していない。
- 事前にdaemon running、OAuth登録メタデータ、全既存VMの停止を確認。秘密値やホスト認証ファイルは読んでいない。

| 試験 | runId | VM名 | VM ID | 時刻（JST） |
|---|---|---|---|---|
| limitsAndTransport | af00b8c5-f7a7-4f04-ba77-d280e6ecbeb5 | iv-af00b8c5-proposal | de097a0a-3e2b-4c43-81a6-cc974af0cc9d | 作成10:14:00、外側停止確認10:16:57 |
| abnormalExitRecovery | 7b8f20eb-bab8-4891-9ea4-a2ad6cc77533 | iv-7b8f20eb-proposal | 60bd78ae-0edd-4e7e-96d7-64594567b308 | 作成10:18:20、強制終了計画10:18:28、自動停止10:19:03、復旧10:19:07 |

## 1台目の観測

| 条件・項目 | 実測 |
|---|---|
| 作成直後 | create終了0、inspect sessions=0、codexProcessCount=0。観測時点の不在であり、全過去の未起動保証ではない |
| バイナリ | Python 3.14.4、標準ライブラリ297件 |
| 固定題材の搬入 | calc.pyとtest_calc.pyのハッシュが承認値と一致。cpの再試行不要。意図的な加算の不具合を持つ題材はunittest1件が失敗し終了1、要約はstderr |
| 通信 | 規則一覧は実測の13件のポート付きallowと他11ホストのポートなしdeny。16件の認可器対照で2ホスト443番だけtrue、8443番・他11宣言先・example.comはfalse。正常拒否の終了1も受理 |
| 認証 | oauthMode、accessSentinel、modelEndpoint、requiresOpenaiAuthDisabled、authPlaceholderの5項目すべてtrue。inspectのsecretsに許可外の名前なし。値や設定全文は出力していない |
| ホストとの接続 | WorkspaceDir空、ShareSkills=false、SSHAgentSocketPath空。MCP登録0件、clipboard.imagePaste=false、ssh.agentForwardingEnabled=false、当該VMのSSH転送開始ログ0件 |
| ゲスト側否定確認 | SSHソケットなし、SSHゲートウェイへの要求は応答0バイト。HTTPプロキシ対照は403で、policy logに当該VMのexample.com拒否を記録 |
| 資源 | runtimeのCPUs=2、Memory=2g。ゲストnproc=2、MemTotal=2,036,100KiB |
| 終了対照 | 終了0/7/127、時間超過、外側からのクライアント強制終了の5種を取得。後2種の終了コードはnull、子プロセス停止を確認 |
| 出力量 | 閾値16,777,216バイト、読取り単位を含む取得値16,785,408バイトで打切り。outputExceeded=true、終了コードnull |
| 外側停止 | stop成功、同一IDでstoppedを確認。停止要求後のexec/cp/runなし |

## 2台目の観測

保持exec開始後、probe自身（PID68384）を予定どおり強制終了した（起動ツールの終了-1はこの試験の意図した結果）。保持クライアントPID62840も消失。保存済みrunRootでResumeし、当該VMの`auto-stopped runtime after last session disconnected`を確認した。

復旧操作の対象は記録済みrunId/VM IDの1件のみで、stateBefore=stopped、stopState=stopped。既に自動停止済みのVMを再起動せず確認した。再開時の自動停止ログ待ち時間は10秒であり、強制終了から自動停止までの全時間ではない。

主担当は1台目を含む既存7台の一覧と終了後一覧、および元の6台の名前・ID・状態を照合した。原本6台を名指しするprobe操作はなく、停止後の対象VMへのexec/cp/runもない。復旧関数の記録と最終一覧は一致した。

## 原文と再照合先

- 1台目: `.tmp/probe-9/af00b8c5/` のprobe-state.json、calls.jsonl、obs/00-startup〜06-proposal-stop、cli/。
- 2台目: `.tmp/probe-9/7b8f20eb/` のprobe-state.json、calls.jsonl、obs/00-startup・00-setup・07-kill・08-resume、control/配下の復旧記録。
- 主担当の照合結果: `.tmp/task9-probe-approval/retry-first-summary.json`、retry-final-summary.json、retry-final-vms.json、retry-final-daemon.json。
- 起動設定と事前確認: 同ディレクトリのproposal-probe-settings.json、retry-limitsAndTransport-*、retry-abnormalExitRecovery-*、retry-abnormal-resume.log。

上記は追跡外原文の保全先である。将来profileの証拠として使う場合は、本追跡済み記録をハッシュ固定して参照し、未確認の条件をverifiedにしない。

## 限界と残作業

今回の成功は提案用の実行条件と停止・復旧の証拠取得まで。モデルを起動して依頼・提案・再実行・recheckを往復させる試験は未実施で、認証がモデルサービスに受理されることまでは確認していない。通信の許可/拒否は認可器の評価と拒否対照であり、全ポートへの実通信試験ではない。負荷中の外側停止だけはADR-0197どおり既存の試験Cを参照し、今回は負荷なしの外側停止を取得した。daemon切断の注入、実行中の他VMの非停止は未実証のまま。

`profiles/proposal/`一式にはmodel・startupArgv・実行ファイル絶対パスの確定が必要なため、今回の証拠を保全し、次のモデル往復の条件確定と合わせて生成する。Task9全体・全体整合検査・masterへの統合は未完了。OAuth登録は保持しており、資格情報の後片付けはサイクル終了時に扱う。
