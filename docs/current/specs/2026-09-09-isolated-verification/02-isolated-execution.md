# ホスト上の検証担当とLinuxコンテナの制限付き実行

## 対象と責務

- `scripts/verification/Execution.psm1`: v2実行の起動・監督・終了、既存のWindowsプロセス管理。
- `ProcessHost.ps1`: 既存のホストプロセス出力回収。コンテナ停止の代替にはしない。
- `ContainerRuntime.psm1`: 新規。コンテナとexec実行の作成・照会・停止、Docker接続を所有。
- `VerificationMcp.ps1`: 新規。実行ごとのSTDIO MCP受付と限定ツール。既存の`scripts/experiments/inspection-dispatch/limited-execution/server.ps1`の通信例を参照するが、固定試験専用の実行処理をそのまま流用しない。
- `agent-result.schema.json`: v1とv2の応答を区別する。

`Start-VerificationExecution(PreparedRunV2) -> ExecutionResultV2`。コピー準備は前段、最終の合否照合は回収側が行う。

## 起動可否の前提

ホストCodexの通常シェルだけでなく、内蔵編集・別のコード実行・画像等を通じた範囲外読み取り・外部アプリ・MCP・再委譲・フック等の全操作経路を確認する。許可するデータ操作は今回のMCPツールだけ。単なる計画表示等を残す場合も、入出力や再委譲を持たないことを確認して一覧へ記録する。

`features.shell_tool=false`は候補設定の一部であり、`unified_exec`や`code_mode_host`等を含む実効ツール集合の制限の証拠にはしない。設定・実行ファイルの版・実効ツール一覧・無害な拒否試験を対応付けた確認記録が必要。同じ版でも構成が変われば再確認する。利用可能なツールをモデルの自己申告だけで確定しない。

最初の適用確認は、ユーザーが実行範囲を承認した無害な固定入力・代用品で行う。入力リポジトリや自由な作業依頼を渡す前に、信頼する起動側がツール構成を取得・検査できることを必要とする。その取得経路が無い、または許可外のツールが残る場合はblocked。未検証の状態で自由な作業を依頼したり、保護を外して再試行したりしない。ホスト保護をOS側にも適用するが、未成立の通信制限だけに依存しない。

Codex execは明示的な引数配列と標準入力で呼ぶ。モデルと認証はホスト側。プロジェクト・ユーザーの広い設定、プラグイン・接続・フックを無条件に合成しない。親の現在のツール群を引き継いだ通常サブエージェントを代用しない。主担当の恒久設定を書き換えず、実行用設定をcontrolに作る。

この前提確認の記録はExecution.psm1が`control/execution/activation.json`へ保存し、ExecutionResultV2の既存項目effectiveConfigPathで指す。記録は`schemaVersion=1, runId, checkedAt, binaries, effectiveSettingsHash, toolInventory, evidence, verdict`を持つ。binariesはCodex・接続処理の版とSHA256、toolInventoryは起動側が観測した実効一覧、evidenceは拒否試験等の種別・対象・結果・証拠パス・SHA256。verdictはverified/blocked/unverified。モデルの申告からverifiedを作らない。

effectiveSettingsHashは`control/execution/effective-settings.json`のSHA256とする。同ファイルには、実際に適用するツール・権限・接続先・imageId・マウントの設定を保存する。認証値は保存しない。起動側が生成した設定と実機で取得した実効情報の対応を検査し、設定予定を書いただけのファイルを確認証拠にしない。

起動側は証拠の内容・設定・実行体・対象範囲との対応を確認してから記録を確定する。別の版・設定・対象範囲に対する古い証拠を流用しない。再利用する証拠も当該controlへコピーして照合し、外部パスへの可変参照だけを残さない。自由な作業依頼を解放する前にverifiedの記録を作れなければblocked。回収側でも記録と実行を照合する。これは既に要求した確認の保存先を具体化するもので、独立した常設承認台帳は設けない。

activationの欠落、verdict=blocked/unverified、設定や証拠の不一致を作業解放前に検出した場合、Execution.psm1は自由な作業依頼とrun_command受付を開始せず、作成済みの当該コンテナ・プロセスを停止して返す。既存のfailure項目に`stage=activation`とreasonを記録し、回収結果はblockedとする。startedはCodexプロセスが実際に開始したかを示すため、初期化済みならtrueのまま記録する。起動前停止を、回収時の事後判定だけで代替しない。

## コンテナ

信頼する起動側だけがDockerへ接続する。ローカルDocker接続を使用し、接続先は導入設定の確認時に固定する。子からソケットやHTTP要求を受け取る汎用代理機能は作らない。

- 実行ごとに新しいコンテナを作り、不変のimageId・runIdを記録する。名前の接頭辞だけで所有権を判定しない。
- `workRoot`を`/work`へ書き込み可能でマウントし、`workRoot/.git`を`/work/.git`へ読み取り専用で重ねる。コンテナ内ユーザーは非rootとし、Windowsバインドマウントで書き込みが成立するか実測する。成立しない場合に原本やホスト全体へ権限を広げない。
- root filesystemは読み取り専用、`/tmp`だけを実行専用tmpfsとして与える。必要な書き込み先は作業コピー内へ固定する。ホストのtempRootはコンテナへ渡さない。
- `network=none`、特権なし、ホストPID/IPC等の共有なし、Dockerソケットなし、不要capabilityなし、no-new-privileges、既定seccompを維持。memoryとmemory-swapは同値、CPU・pids・時間の上限を適用する。
- ホストのホーム・認証・プロキシ設定をコンテナの環境変数へ持ち込まない。原本・control全体をマウントしない。起動後のinspectで実効マウントと設定を確認する。
- Git・Python・テスト実行体は固定イメージ内に準備する。実行中に依存をダウンロードしない。Gitは読み取り専用管理領域でlog/show/blameを利用できることを確認する。

この構成では、コンテナ内から作業コピーは変更できる。コピー以外のホストファイルが守られることを、別々の代用品で確認する。

## MCPの外部契約

既存PowerShell 7でSTDIO接続を実装する。標準出力はMCPメッセージのみ、診断は標準エラー。initialize・通知・ping・tools/list・tools/callの扱いは実クライアントと相互確認し、未対応プロトコルを黙って受理しない。新しい常駐サービスやMCP用の追加パッケージを必須にしない。実装上必要になれば相談する。

| ツール | 入力 | 出力・境界 |
|---|---|---|
| `run_command` | `command`（空でない文字列） | `/work`を開始位置にコンテナ内シェルで実行。返値はcommandId・started・exitCode・timedOut・stdout/stderrの先頭とtruncated・未確認理由 |
| `read_output` | `commandId, stream, offset, maxBytes` | 当該実行の記録済みstdoutまたはstderrの指定範囲だけ返す。パスを引数で受け取らず、他実行や制御ファイルを読めない |

run_commandのcommand以外のキーを拒否する。子がコンテナID・実行ユーザー・マウント・Dockerフラグ・ホストパスを指定する欄は無い。commandはコンテナ内の`/bin/sh -lc`の引数としてだけ使用し、ホストのPowerShell等では評価しない。任意の検索・編集・テストはこの入口の中で行える。

commandIdは受付側が発行する一意の値。read_outputは完了したコマンドの記録だけを対象とし、streamはstdout/stderr、offsetは非負、maxBytesは1〜65536。UTF-8の分割境界と次のoffsetを返し、切り詰めを明示する。出力全体はcontrol側に保存し、子は書き換えられない。

1実行につきコマンドを直列処理する。同時要求はbusyとして返し、無制限キューを持たない。MCPの接続先はrunIdとコンテナIDを起動時に束縛した新規プロセスで、別の実行へ切り替えられない。

## 実行証拠

Docker Engineのexec作成・開始・照会を利用し、execId、ContainerID、実際の開始状態、Running、ExitCodeを記録する。Dockerクライアントの終了コードだけでコマンドの開始・終了を認定しない。Engineの応答が確認できない場合は未確認として返す。APIへの接続実装と対応版は最初のAIなし試験で確かめる。

各操作について`CommandRecord`をcontrol/execution/commandsへ保存する。キーは`runId, commandId, mcpRequestId, containerId, execId, command, started, startedAt, endedAt, exitCode, timedOut, stdoutPath, stderrPath, stdoutSha256, stderrSha256, outputComplete, failure`。パスはホストが生成し、出力ハッシュを終了後に確定する。子の自己申告をこの記録へ代入しない。

出力合計がoutputBytesPerCommandを超えた場合は受付を停止し、当該コンテナを停止する。未保存の出力があることを記録し、成功にはしない。コマンドやテスト自体が出力を偽る可能性は別問題であり、実行記録はテスト内容の妥当性を保証しない。

## 終了管理と回収への出力

ExecutionResultV2は`schemaVersion=2, runId, started, exitCode, timedOut, processTreeStopped, containerStopped, containerId, eventsPath, stderrPath, agentResultPath, effectiveConfigPath, commandRecordsPath, failure`を持つ。agentの開始状態・終了コードとコンテナの停止状態を区別する。

正常終了・時間超過・中断・接続断では、まず新規コマンドを拒否し、当該コンテナを停止して状態を照会する。その後Codex・MCP・起動側の子プロセスを停止確認する。ホストプロセスを先に失う場合も、外側の監督処理が保存済みコンテナIDで停止できるようにする。別実行のコンテナを接頭辞や時刻でまとめて停止しない。

コマンド単体の時間超過でもコンテナを停止し、その実行では次のコマンドを受けない。停止確認不能ならcontainerStopped=falseとし、自動再起動・回収成功・合格を返さない。コンテナ自動削除は行わず、停止状態とIDを保存する。不要な実行領域・コンテナの削除は対象を名指しして別に扱う。

agentの最終応答は`schemaVersion=2, runId, verdict, summary, checks, findings, artifacts, unverified`。checksは`commandId, command, exitCode`を持つ。artifactsは作業コピー内の再現テスト等の相対パス。前提が未検証ならverdict=passにしない。

## 根拠・検証

V3・V4・V5・V6の実行側を担当する。先にAIなしのMCP契約・コンテナ制限・停止・証拠を検査し、主担当からの実モデル呼び出しは個別承認後に行う。

参照: ADR-0146・0147・0149・0151・0152、[OpenAI設定](https://learn.chatgpt.com/docs/config-file/config-reference)、[MCP接続](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)、[Dockerネットワーク](https://docs.docker.com/engine/network/drivers/none/)、[Docker Engineのexec API](https://docs.docker.com/reference/api/engine/version/v1.46/)。公式仕様と現在の実機での成功は区別する。
