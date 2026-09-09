# Linux隔離検証 v2 実装計画

> **実装担当へ:** `superpowers:executing-plans` を使い、主担当がチェックボックス単位で進める。2026-09-09、選択肢1へのユーザー回答「１で」で選択。既存worktreeを使用する。

**目的:** Claude CodeとCodexの主担当から、ホスト上の子Codexが専用MCP接続でLinuxコンテナ内を検証し、実行証拠と再現テストを回収・再利用できる共通CLIを作る。

**構成:** 依頼・コピー、制限付き実行、結果回収の3責務を維持する。既存v1のコピーと履歴、Windowsプロセス管理を必要な部分だけ再利用し、v2の版検査・コンテナ・MCP・証拠照合を追加する。ホストの操作経路を確認できない構成では自由な依頼を起動しない。

**技術:** Windows、PowerShell 7、Git、ホストCodex、ローカルのLinux用Docker、固定イメージ内のPython・Git・テスト実行体。新規の必須パッケージや常駐サービスは追加しない。

**仕様:** `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`、`01-request-and-copy.md`、`02-isolated-execution.md`、`03-result-collection.md`（`7e8d464`で確定）。

**状態:** 主担当でタスク0から進める選択を受領。計画の独立レビューは見送り。タスク0の読み取り調査はblockedで終了し、後続実装は停止。動的試験の個別承認は未取得。全実効ツールの取得経路と実MCPイベント形式を既知としてコード化しない。構成や具体化の変更が必要なら、その証拠を添えて本計画を更新し、必要な判断へ戻す。

**作成理由:** 旧`2026-09-09-isolated-verification.md`はv1先行部品の実施記録であり、確定したLinux仕様の実装へ直接再開できないため。旧計画と既存Windows部品は保全する。

## 共通制約と承認の境界

- 作業場所は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`、ブランチは`codex/isolated-verification`。作成時HEADは`234999a`。未追跡`.tmp/`・既存junction・他worktree・stashを保全し、一括ステージ・削除しない。
- Linux共通CLIはschemaVersion=2のみ受理。v1公開部品の既存呼び出しを保持する。RequestCopyとResultがそれぞれ版の分岐を所有する。
- コンテナは実行ごとに新規作成。不変imageId、非root、`/work`のみホスト側への書き込み可、`/work/.git`は読み取り専用、root filesystemは読み取り専用、`/tmp`は実行専用tmpfs。
- `network=none`、特権なし、ホストPID/IPC共有なし、Dockerソケットなし、不要capabilityなし、no-new-privileges、既定seccomp。memoryとmemory-swapは同値。原本・control・ホストtempRoot・ホーム・認証情報をマウントしない。
- 操作は直列。commandTimeoutSecondsは全体timeoutSeconds以下。Git各処理の上限は30秒。read_outputのmaxBytesは1〜65536、offsetは非負、streamはstdout/stderr。
- 小さな試作設定は全体600秒、1操作60秒、1024MiB、CPU1、pids128、1操作出力合計16MiB。正常対照で妥当性を確かめる。ホストコピーの容量強制上限は無いことを実行承認へ含める。
- モデル自己申告、設定値の受理、Dockerクライアント終了だけを保護・実行・停止の証拠にしない。未確認・失敗・未保存の出力を合格へ変換しない。
- 原本へ自動適用しない。子のcommandはコンテナの`/bin/sh -lc`へ引数として渡し、ホストで評価しない。成果物をホストで実行・importしない。
- 失敗領域と停止コンテナは診断用に残す。コンテナや実行領域の削除、導入・公開・masterへの統合はこの計画の承認へ含めない。

### 判断の分担・逸脱判断の既定

ADR-0152の承認は詳細仕様作成まで。本依頼はv2計画作成からの再開であり、実装方式・実モデルやコンテナの起動・新しい外部送信への包括承認ではない。構成、必須依存、検証担当、保護条件、既存LoopForAlphaの変更は相談する。

逸脱判断は`ai-driven-dev-principles`導入版0.1.24の`skills/start-work/references/plan-deviation-defaults.md`に従う。計画確定時に基準を固定する。局所仕様変更の追加委任は現在ない。実行による安全網を作る通常の実装計画で、コード全文の書き写し方式ではない。タスク別レビューを置かない方式で設計変更へ至ったら独立レビューへ切り替える。各タスク末尾に必要な`逸脱記録:`を残し、レビューを置かない場合は差分との自己照合結果を報告する。

仕様レビューからの引き継ぎは`docs/records/reviews/2026-09-09-linux-pilot-spec-r2.md`のR2・R3、および`2026-09-09-linux-pilot-spec-final.md`。再検証追加後の原本再照合を省略しない。effective-settings.jsonのパス項目を増やさず固定パスを検査する。不採用指摘の再提案は実装後の実体で以前の理由が覆る証拠を必要とする。

### 実行承認を求める具体的な区切り

| 区切り | 提示する対象 | 承認に含めないもの |
|---|---|---|
| タスク0の固定試験 | 実行体・版・設定・代用品・送信する固定文面・取得する証拠・停止手順 | リポジトリ本文、自由な依頼、通常利用 |
| タスク7のAIなし実機試験 | ローカル接続先、不変imageId、実行領域、資源上限、代用品、起動・停止対象 | イメージ取得・ビルド、既存サービス変更、自動削除 |
| タスク8の実モデル往復 | 主担当別の題材と参照履歴、モデル、送信範囲、最大時間、コンテナ設定、結果の保存先 | 任意の別リポジトリ、通常導入・公開 |

イメージが不足すれば、内容と新しいイメージ名を提示して準備の承認を別に得る。既存イメージへ上書きしない。重い試験は1件ずつ。ユーザー側の実行が必要なら、確定したコマンド・入力ファイルと結果保存先を用意し、本文転記は求めない。

## ファイルと責務

以下は特記しない限り`scripts/verification/`からの相対パス。

| ファイル | 操作・責務 | タスク |
|---|---|---|
| `RequestCopy.psm1`、`request.schema.json` | 変更。v1保持、v2検査・コピー・再検証 | 1、6 |
| `Execution.psm1`、`ProcessHost.ps1` | 変更。依頼stdin、activation、起動監督、停止 | 4 |
| `ContainerRuntime.psm1` | 新規。固定Docker接続、create/inspect/exec/stop | 2 |
| `VerificationMcp.ps1` | 新規。STDIO契約、2ツール、実行束縛 | 3 |
| `Result.psm1`、`agent-result.schema.json`、`result.schema.json` | 変更。v1保持、v2の独立照合・失敗応答 | 5 |
| `Invoke-IsolatedVerification.ps1` | 新規。JSON入力、3責務の結合、終了コード | 6 |
| `tests/*V2.Tests.ps1`、`tests/fixtures/` | 新規。AIなしの契約・偽造・停止試験 | 1〜6 |
| `tests/Invoke-LinuxPilotProbe.ps1` | 新規。名指しの実コンテナで対照試験 | 7 |
| `tests/Run-IndependentTests.ps1`、`README.md` | 変更。AIなし試験の列挙、実装状態・呼び出し説明 | 6、8 |

プロトコル調査と固定試験の記録先は`docs/records/experiments/2026-09-09-linux-pilot-activation.md`。作成日が変われば日付を実日にし、本計画の参照も更新する。実ログは新規の試験領域に保存し、記録には版・ハッシュ・コマンド・結果を残す。認証値は保存しない。

## タスク0: 全操作経路を取得・制限できるかを先に判定する

**依存:** なし。**出力:** 根拠付きの成立／blocked判定と、対象CLI版の取得方法・設定・イベントfixture。仕様02「起動可否の前提」に対応。

- [x] 既存の仕様レビューr2と`.tmp/codex-protocol-linux-pilot/`を読む。`ThreadStartResponse`、`TurnStartParams`、`McpServerStatusUpdatedNotification`に全内蔵ツール一覧を確認できなかった範囲と、CLI全体を調べ尽くしたわけではない点を記録する。
- [x] `openai-docs`を用い、実機CLIのヘルプ・導入物・生成済みプロトコルを優先して調査する。モデルなしの読み取りコマンド例は次のとおり。出力と終了コードを保存し、ユーザー設定の秘密値を表示しない。

```powershell
Get-Command codex | Select-Object Source,CommandType
codex --version
codex exec --help
codex app-server --help
```

- [ ] 内蔵シェル、unified_exec、コード実行、編集、ファイル・画像読取、外部アプリ、他MCP、フック、再委譲、プラグインとプロジェクト設定について、生成された実効ツール集合を起動側が観測する経路を特定する。単なる設定一覧やdynamicToolsを全実効一覧に置き換えない。観測時点が自由な依頼の解放前であることを確認する。
- [ ] 観測経路が特定できた場合だけ、固定文面・代用品・設定・停止手順をファイル化して実行承認を求める。確認可能なホストOS側の保護範囲も含める。仕様に合う観測経路が無ければblockedを記録して方針判断へ戻り、タスク1以降へ進まない。
- [ ] 承認後、許可MCPの無害な操作が成功し、その他の経路が拒否される対照を実行する。モデルが呼ばなかっただけのケースは拒否成功に数えない。全一覧、実効設定、実行体、証拠を対応付ける。1項目でも観測不能ならunverifiedまたはblockedで止める。
- [ ] 同じ承認範囲内でMCPのinitialize・tools/list・tools/call・通知を取得できる固定試験を行い、対象CLIの生イベントと期待する正規化結果を保存する。コンテナをまだ使わない固定応答MCPは、実Docker実行の証拠に数えない。
- [ ] `tests/fixtures/codex-mcp-v2/`へ秘密を含まない生イベントと期待値を保存する。実記録からツール名・入力command・出力commandId・イベント参照の場所を確定する。実効一覧が確認できてもイベント対応が不能なら、その版の回収はincompleteとなることを記録し、全体成立とはしない。
- [ ] 記録と本計画に実測したargv・設定・抽出規則・確認範囲を反映する。新構成や依存が必要ならADRドラフトと相談へ戻る。変更実体を読み直し、この後の実装の進め方を確定してから個別ファイルをコミットする。

**期待値:** 設定候補を見つけたことではなく、全一覧・制限・拒否対照・取得時点を証拠で特定できること。未成立を報告することもタスク0の正当な結末だが、v2実装完了ではない。

**2026-09-09の実施結果:** blocked。CLI 0.153.4の6コマンド、生成済みプロトコルの155メソッド・6ファイル、公式文書を照合したが、全実効ツールの起動前取得経路は特定できなかった。固定試験・実MCPイベント取得は未実施。記録は`docs/records/experiments/2026-09-09-linux-pilot-activation.md`。取得不能時の予定どおり方針判断へ戻る。逸脱照合: 一致。

## タスク1: v1互換を保ってv2依頼と設定を検査する

**依存:** タスク0の成立と後続実装の承認。**対象:** `RequestCopy.psm1`、`request.schema.json`、新規`tests/RequestCopyV2.Tests.ps1`。

**インターフェース:** 公開`New-VerificationRun([hashtable]$Request,[hashtable]$Settings)`を保持。内部`New-LegacyVerificationRun`、`New-LinuxVerificationRun`を同じ2引数で追加。PreparedRunV2のキーは仕様01を正とする。再検証入力の最終受理はタスク6で完成させ、それまではrecheck付き依頼を明示的にblockedとし無視しない。

- [ ] v1既存テスト4群を実行し、今回の基準結果として保存する。失敗があればv2変更へ混ぜず原因を確認する。
- [ ] v2の正常例と、未知キー・型違い・版混在・空目的・不正caller・相対パス・無い実行体・可変イメージタグ・非正の資源・commandTimeout超過の拒否を先にテスト化する。例えば正常依頼から未知キーを1個追加して拒否を確認する。

```powershell
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
$case = New-TestCase 'v2-unknown-request'
$request = $case.request.Clone()
$request.schemaVersion = 2
$request.unexpected = 'reject'
Assert-Throws { New-VerificationRun $request $case.settings } '*unknown request key*'
```

- [ ] `pwsh -NoProfile -File scripts/verification/tests/RequestCopyV2.Tests.ps1`で、正常v2が既存実装では受理されないことを確認する。拒否ケースだけの成功を実装済みとしない。
- [ ] v1本体を内部関数へ移し、厳密な版検査を公開入口に置く。共通6キーと設定5キーだけを明示的に選ぶ。変換の中心は次の形とする。

```powershell
$legacyRequest = @{}
foreach ($key in @('schemaVersion','caller','sourceRoot','objective','acceptanceCriteria','extraInputPaths')) {
    $legacyRequest[$key] = $Request[$key]
}
$legacyRequest.schemaVersion = 1
$legacySettings = @{}
foreach ($key in @('codexPath','pwshPath','runsRoot','model','timeoutSeconds')) {
    $legacySettings[$key] = $Settings[$key]
}
$prepared = New-LegacyVerificationRun $legacyRequest $legacySettings
$prepared.schemaVersion = 2
$prepared.request = $Request
$prepared.settings = $Settings
$prepared.recheckManifest = @()
```

- [ ] JSON schemaをv1/v2のoneOfとし、v1分岐の契約を変えない。v2設定は仕様01の必須キーとlimitsの未知キー・型・正値を検査。空白目的やimageIdなどJSON schemaだけでは不足する条件を入口で検査する。
- [ ] 導入設定の除外を準備前に成立させる。CLIは設定ファイルがコピー対象にならない配置を確認してからNew-VerificationRunを呼ぶ。設定の秘密値を通常の依頼やmanifestへ複写しない。
- [ ] v2正常コピーで元のRequestV2・SettingsV2、同一runId、ファイルと履歴、manifestの一致を確認する。原本内外のrunsRoot、同一コミットへのブランチ切替、コピー中の変更を含める。再照合ではv1変換ではなく低水準manifest関数に必要な入力を渡す。
- [ ] v1のRequestCopy・History・Execution・Resultと新規群が成功したら、差分と期待値を読み直し、対象3ファイルを個別にコミットする。

## タスク2: Dockerの実行・停止をEngineの証拠で管理する

**依存:** タスク1。**対象:** 新規`ContainerRuntime.psm1`、`tests/ContainerRuntimeV2.Tests.ps1`、`tests/fixtures/DockerEngineV2.psm1`。

**インターフェース:** `New-VerificationContainer([hashtable]$Run) -> hashtable`（runId、containerId、imageId、inspectの証拠パス）、`Invoke-VerificationContainerCommand([hashtable]$Run,[hashtable]$Container,[string]$CommandId,[string]$McpRequestId,[string]$Command) -> CommandRecord`、`Stop-VerificationContainer([hashtable]$Run,[hashtable]$Container) -> hashtable`（containerId、containerStopped、failure）。いずれもDocker接続を子から受け取らない。

- [ ] Docker通信を記録済み応答へ差し替えるモジュール内の試験fixtureを作る。プロダクトのCLIに任意接続先や任意scriptblockを公開しない。Engine未開始、execId不一致、終了照会不能、マウント違い、停止照会不能を正常応答と対にして先に失敗させる。
- [ ] createの要求生成を実装する。imageId、user、mount、資源上限等は仕様02とSettingsV2から固定生成。inspectの実値を照合し、不一致なら停止へ進む。実コンテナの作成はタスク7まで行わない。
- [ ] execの作成・開始・inspectを実装し、`ContainerID`とexecIdの一致、開始・Running・ExitCodeを確認する。commandを渡す引数列は次とし、ホスト文字列評価を使用しない。

```powershell
$execBody = @{
    AttachStdout = $true
    AttachStderr = $true
    Tty = $false
    WorkingDir = '/work'
    Cmd = @('/bin/sh','-lc',$Command)
}
```

- [ ] STDOUT/STDERRを別ファイルへ保存し、ストリームの分割読取、非TTYのフレーム、UTF-8、出力上限と切断をfixtureで確認する。API対応版・接続はタスク0の資料と後続の実機応答で照合し、未対応ならblocked。推測した成功応答を作らない。
- [ ] 出力合計超過・操作時間超過で受付停止と対象コンテナ停止を要求する。CommandRecordの全キーを仕様02どおり保存し、終了後にハッシュを確定する。未保存データがあればoutputComplete=false。
- [ ] 停止は保存した正確なcontainerIdにだけ行い、inspectで非稼働を確認する。同じ接頭辞の別コンテナへstopを発行しない。停止照会が失敗するfixtureのcontainerStoppedはfalse。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/ContainerRuntimeV2.Tests.ps1`で全ケース成功を確認し、要求履歴も読み直して対象ファイルをコミットする。fixture成功を実マウント・通信・停止の実証に数えない。

## タスク3: 実行ごとのMCP接続を2ツールに限定する

**依存:** タスク2、タスク0のプロトコル記録。**対象:** 新規`VerificationMcp.ps1`、`tests/McpV2.Tests.ps1`、`tests/fixtures/McpV2Client.ps1`。既存`../experiments/inspection-dispatch/limited-execution/server.ps1`は通信例の参照のみ。

**インターフェース:** STDIO MCPの`run_command({command})`と`read_output({commandId,stream,offset,maxBytes})`。起動側から渡す当該実行のcontrol内設定でrunId・containerIdを固定する。JSON引数で別実行へ切替える操作は作らない。

- [ ] 実記録で特定したプロトコル版についてinitialize・通知・ping・tools/list・tools/callをfixtureクライアントで往復させる。未対応版、未知ツール、不正JSON、不正キーを先に拒否テストへ入れる。STDOUTへ診断文が出る場合も失敗とする。
- [ ] run_commandの空文字、余分なcontainerId・user・hostPath、別runIdの読取、未完了commandId、負offset、maxBytes=0/65537を拒否する。固定したパラメータ検査例は次のとおり。

```powershell
if ($arguments.Count -ne 1 -or -not $arguments.ContainsKey('command') -or
    $arguments.command -isnot [string] -or [string]::IsNullOrWhiteSpace($arguments.command)) {
    throw 'invalid run_command arguments'
}
$commandId = [guid]::NewGuid().ToString()
```

- [ ] commandIdをホストで発行し、MCP request idとコンテナ処理へ渡す。返値には実started・exitCode・timedOut・出力先頭・truncated・未確認理由を載せる。子の入力をCommandRecordのホスト証拠へ代入しない。
- [ ] 受付は初期状態で閉じ、Executionの確認完了後だけ開く。停止要求後は再開しない。同時要求をbusyで返せるよう、コマンド実行待ちの間も受付状態を扱う。同期処理の後で2件目を普通に実行する実装はbusy契約を満たさない。
- [ ] read_outputは受付が管理する完了済みcommandIdから記録済みパスを選ぶ。UTF-8の途中で切れた読取は文字境界を明示し、次offsetを返す。範囲外ファイル・書換えられたリンクを拒否する。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/McpV2.Tests.ps1`で、2ツールのみ列挙、並行要求busy、接続断による停止通知、STDOUTのJSON専用、マルチバイト分割を確認する。差分と実メッセージを読み直してコミットする。

## タスク4: activation確認、依頼の解放、外側の停止監督を接続する

**依存:** タスク0〜3。**対象:** `Execution.psm1`、`ProcessHost.ps1`、新規`tests/ExecutionV2.Tests.ps1`、`tests/fixtures/StdinFixture.ps1`、`tests/fixtures/ActivationV2.psm1`。

**インターフェース:** 新規公開`Start-VerificationExecution([hashtable]$PreparedRun) -> ExecutionResultV2`。既存`Invoke-VerificationProcess`に任意の`[string]$InputText`を末尾追加し、旧4引数の利用を維持する。ExecutionResultV2の全キーは仕様02。ProcessHostはstdinを子へ転送するが、コンテナ管理は所有しない。

- [ ] 現行ProcessHostは起動要求をstdinで受ける一方、対象プロセスのstdinをリダイレクトしていない。依頼テキストが完全一致で子へ届く試験を先に追加し、引用符・改行・日本語・`$()`を含めてもホストで評価されないことを確認する。
- [ ] ProcessHost用の起動要求へinputTextを追加し、対象のRedirectStandardInputを有効にして文字列を送って閉じる。既存の要求にinputTextが無い場合も旧動作を保持する。ProcessHostの標準出力はイベント回収へつながるため、依頼文や診断を混ぜない。

```powershell
$start.RedirectStandardInput = $true
# ProcessHost内で子プロセスを開始した直後に行う。
if ($request.PSObject.Properties.Name -contains 'inputText') {
    $process.StandardInput.Write([string]$request.inputText)
}
$process.StandardInput.Close()
```

- [ ] タスク0で実測した実効設定生成・取得・検査を組み込む。activation.jsonは`schemaVersion=1,runId,checkedAt,binaries,effectiveSettingsHash,toolInventory,evidence,verdict`、設定は固定の`control/execution/effective-settings.json`。コピーした証拠を当該control内で再ハッシュし、古い版・設定・対象への証拠を拒否する。
- [ ] 作業解放前の判定と、確認後の自由依頼・run_command受付開始を順序付ける。拒否fixtureでは自由依頼の送信回数とコマンド受付成功回数がともに0、failure.stage=activationとなることを確認する。初期化で子を開始済みならstarted=trueを保持する。
- [ ] 外側の監督処理にcontainerIdを保存してから子・MCPを起動し、正常終了・時間超過・中断・接続断で受付停止→当該コンテナ停止照会→当該プロセス群停止確認を行う。既存Invoke-VerificationProcessのホストジョブだけでコンテナ停止を代替しない。
- [ ] 原本本文を含まない短い依頼をstdinへ渡し、仕様・資料・Git履歴をコンテナ内で探索するようにする。recheck時はコピー先を示す。ユーザー／プロジェクト設定・他MCP・フックを混入させない。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/ExecutionV2.Tests.ps1`と既存Execution.Tests.ps1を実行。stdin往復、activation全拒否ケース、起動失敗、全体・単体timeout、出力上限、停止未確認、別実行継続をfixtureで確認し、コミットする。

## タスク5: v2の実イベント・Engine証拠・成果物を独立に照合する

**依存:** タスク4。**対象:** `Result.psm1`、`agent-result.schema.json`、`result.schema.json`、新規`tests/ResultV2.Tests.ps1`、`tests/fixtures/ResultV2.psm1`。

**インターフェース:** 公開`Complete-VerificationRun([hashtable]$PreparedRun,[hashtable]$ExecutionResult)`を保持。内部`Complete-LegacyVerificationRun`、`Complete-LinuxVerificationRun`を追加。内部`Get-LinuxWorkArtifact([hashtable]$Run,[string]$Relative)`はworkRoot相対専用。新規公開`New-VerificationFailureResult([string]$Status,[string]$Stage,[string]$Reason,[hashtable]$Context) -> VerificationResultV2`は準備未成立用でContextに確定した値だけ渡す。

- [ ] タスク0の生MCPイベントとタスク2のEngine fixtureから正常1件を作る。`New-ResultV2Case([string]$Name)`がrun・execution・agentと証拠一式を返し、`Save-ResultV2Case([hashtable]$Case)`が変更した応答を保存する試験専用関数をResultV2.psm1へ定義する。
- [ ] 正常caseを1条件ずつ壊すテストを先に作り、架空commandIdがcompletedにならないことを確認する。

```powershell
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'fixtures/ResultV2.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../Result.psm1') -Force
$case = New-ResultV2Case 'fabricated-command'
$case.agent.checks[0].commandId = 'never-executed'
Save-ResultV2Case $case
$result = Complete-VerificationRun $case.run $case.execution
Assert-Equal $result.status 'incomplete' '架空の実行を完了にしない'
```

- [ ] v1/v2分岐と混在拒否を実装する。v1イベントcommand_executionへv2データを変換しない。タスク0で実測したMCP抽出器を固定し、未知形式はincompleteへ落とす。
- [ ] activation、実効設定、実行体、証拠ハッシュ、runId、停止状態を照合する。checksを実MCP入力・commandId・CommandRecord・execId・実exitCodeへ一意に結ぶ。同一文字列の別commandIdは別実行として扱い、read_outputを実行件数に加えない。
- [ ] CommandRecordの出力は当該control/execution内の生成済み通常ファイルだけを照合する。成果物はworkRoot相対で、絶対パス、`..`、`.git`、制御領域、リンク、欠落、ハッシュ不一致を拒否する。v1のGet-VerificationArtifactの包含先を書き換えて流用しない。
- [ ] 複数問題をすべて収集してから優先状態を決める。判定の中心は次の順序とし、原本再照合は失敗時も可能な範囲で行う。

```powershell
if ($ExecutionResult.timedOut) { $status = 'timed_out' }
elseif (-not $ExecutionResult.started -or $activationFailedBeforeRelease) { $status = 'blocked' }
elseif ($sourceState -eq 'changed') { $status = 'source_changed' }
elseif ($problems.Count -gt 0) { $status = 'incomplete' }
else { $status = 'completed' }
```

ここでactivationFailedBeforeReleaseはfailure.stage=activationの照合結果、sourceStateは原本manifestの再比較結果、problemsは全照合の未解決理由の配列。これらをこの関数内で生成する。事後のactivation欠落はproblemsへ入れ、起動前blockedと偽らない。

- [ ] 失敗応答は未確定項目をnullにし、checks/artifactsは空配列。存在するrunRootのみ保存先とし、CreateNewでresult.jsonを一度だけ書く。保存失敗は返却JSONのunverifiedへ残す。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/ResultV2.Tests.ps1`と既存Result.Tests.ps1を実行。正常pass/fail、応答欠落・不正JSON・未知キー・別runId、架空/重複ID、MCP入力違い、exec未開始、出力欠落、停止未確認、activation古版/改変/事後欠落、原本更新、既存結果保全、失敗時nullを確認してコミットする。

## タスク6: 再検証入力と共通CLIを結合する

**依存:** タスク5。**対象:** `RequestCopy.psm1`、新規`Invoke-IsolatedVerification.ps1`、`tests/RecheckV2.Tests.ps1`、`tests/CliV2.Tests.ps1`、`tests/fixtures/VerificationCliV2.psm1`、`tests/Run-IndependentTests.ps1`、`README.md`。

**インターフェース:** CLIは`-RequestPath <absolute> -SettingsPath <absolute>`、stdoutにVerificationResultV2のJSON1件、stderrに診断、終了コード0/1/2。recheckはpreviousResultPathとartifactPathsのみ。タスク5の失敗応答関数を使い、不正PreparedRunを通常回収へ渡さない。

- [ ] 停止確認済みcompleted/fail結果のartifactを次実行へコピーできる正常対照を作る。範囲外のpreviousResultPath、runId違い、未停止、未成立、未掲載パス、改変、リンク、既存`.verification-recheck/<previousRunId>`衝突をそれぞれ拒否するテストを先に作る。
- [ ] 前回結果を現在のrunsRoot内で解決し、選択artifactのサイズ・SHA256・停止を照合する。原本由来と再検証由来をmanifestで区別し、再検証ファイルのコピー前後照合と、その後の原本全体の再照合を行う。元の結果とartifactは変更しない。
- [ ] CLI入口でファイル参照・版・設定配置を検査し、診断をstdoutへ漏らさない。結果の終了コードを次のように決める。

```powershell
$exitCode = if ($result.status -eq 'completed' -and $result.agentVerdict -eq 'pass') { 0 }
elseif ($result.status -eq 'completed' -and $result.agentVerdict -eq 'fail') { 1 }
else { 2 }
[Console]::Out.WriteLine(($result | ConvertTo-Json -Depth 40 -Compress))
exit $exitCode
```

- [ ] CLI結合試験では3責務の試験用モジュールを隔離したfixtureディレクトリへ配置し、実モデルやDockerへ接続しない。プロダクトに保護を飛ばす環境変数や公開テストスイッチを足さない。正常pass/fail、不正入力、準備途中失敗、起動失敗、source_changed、timeout、回収保存失敗を子プロセスから確認する。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/RecheckV2.Tests.ps1`と`CliV2.Tests.ps1`を実行。再検証準備中の原本変更をsource_changedにし、元結果を上書きせず新runIdを生成すること、stdoutがJSON1件で終了コードが合うことを確認する。
- [ ] AIなしランナーへ新規7群（RequestCopyV2、ContainerRuntimeV2、McpV2、ExecutionV2、ResultV2、RecheckV2、CliV2）を明示追加する。既存4群と合わせて11群。実機・実モデル用スクリプトは含めない。
- [ ] READMEにv1部品とv2の未実証範囲を分け、実行前のactivation条件・失敗保持・JSON終了コード・再検証例を仕様から写す。全文転記や恒久MCP登録を通常操作へ追加しない。11群の実行結果と差分を確認してコミットする。

## タスク7: AIなしで実マウント・通信拒否・Engine証拠・停止を実証する

**依存:** タスク6、名指しした実コンテナ試験の承認。**対象:** 新規`tests/Invoke-LinuxPilotProbe.ps1`、`tests/fixtures/linux-pilot/`、`docs/records/experiments/2026-09-09-linux-pilot-runtime.md`。

- [ ] 試験スクリプトを作り、設定入力を検査し、承認用にimageId・接続先・対象ディレクトリ・資源・コマンド・停止方法を出力できるようにする。実行時は新規UUID領域だけを使う。既存イメージのGit/Python/テスト実行体が不足なら停止して準備案を提示する。
- [ ] 承認後、正常対照として非rootの`id`、`/work`への書き込み、読み取り専用`.git`を使ったlog/show/blame、Pythonテストを実行する。Linux内でgit所有者検査が必要なら当該コピーだけの設定で確認し、広いsafe.directoryやホスト設定変更をしない。

```sh
id
python -c 'from pathlib import Path; Path("/work/write-ok.txt").write_text("ok")'
git log -1 --oneline
git show HEAD:tracked.txt
git blame tracked.txt
```

- [ ] 原本・Git・control・ホスト機密の別々の代用品へ変更／読取を試み、失敗と代用品ハッシュ保全を確認する。コンテナroot filesystem・Git管理領域への変更拒否、ホストサービスと外部への通信拒否を確認する。通信先の正常対照は信頼する起動側で確認し、到達先の不在を隔離成功に数えない。
- [ ] Engineでexec開始・終了を照会し、記録のcontainerId・execId・commandId・出力ハッシュを読み直す。Dockerクライアントの終了をその代わりにしない。出力上限と単体timeoutには小さな専用設定を用いる。
- [ ] 2つの当該試験用コンテナを作り、片方の時間超過・接続断・ホスト子終了を試験する。対象のみ停止し別実行が動作を継続することをinspectと対照コマンドで確認する。停止照会不能なら未確認のまま返し、成功へ進まない。
- [ ] 代用品・原本・既存記録の事後ハッシュ、停止ID、全コマンドの結果を記録する。試験対象のコンテナとディレクトリを残し、自動削除しない。実証できた設定範囲をREADMEへ反映し、記録と試験コードをコミットする。

## タスク8: 両主担当の実セッションから欠陥検出・修正・再検証を往復する

**依存:** タスク7、タスク0で確認済みの同一構成、主担当ごとの実モデル・送信承認。**対象:** `tests/fixtures/linux-pilot/`、`README.md`、`docs/records/experiments/2026-09-09-linux-pilot-roundtrip.md`、必要に応じ現行仕様の実装状態。

- [ ] 小さなPython題材の履歴に、空配列の平均を0とする合格条件と実装を用意する。欠陥版は空配列で例外となる。修正は主担当の通常工程で行い、子の追加テストを回収する。

```python
# 欠陥版。合格条件は空配列に0を返すこと。
def mean(values):
    return sum(values) / len(values)
```

- [ ] タスク0の確認記録と現在の版・設定・接続処理ハッシュを再照合する。異なれば旧activation証拠を流用せず該当確認へ戻る。
- [ ] Claude Codeの実セッションからCLIへ依頼し、子が途中で資料・履歴を探索し、追加テストで欠陥を検出することを確認する。completed/failと実テスト失敗の証拠を必要とし、起動失敗を欠陥検出に数えない。
- [ ] 主担当が再現テストを採用し原本を修正する。前回resultのartifactPathsをrecheckへ指定し、新runIdで同じテストを実行してcompleted/passを確認する。人にJSONやファイル本文を転記させない。
- [ ] Codexの実セッションでも新しい題材領域で同じ往復を1件行う。caller文字列の変更だけで2主担当の実証に数えない。最小で主担当2種×初回・再検証の4検証実行となるが、自動の再試行や追加送信は行わない。
- [ ] 元の合格条件、実セッション、前後runId、コピーmanifest、前回artifactハッシュ、実行check、停止、原本保全を対応付けて記録する。再現テスト未実行・改変・入力不足は成功にしない。
- [ ] v1/v2のAIなし11群を最終実装に対して実行し、V1〜V7の実証所在を確認する。最終レビューを行い、ADR-0145〜0148・0151・0152を含め実装完了時のサイクル全体整合検査へ接続する。Issue-0136全体の未解決範囲を勝手にcloseしない。
- [ ] READMEと現行仕様の実装状態を実証に合わせる。配布検査はリポジトリの既存手順・対象ファイルを確認して実施し、プラグイン導入済み0.1.24と予定版0.1.25を区別する。`verification-before-completion`後、`finishing-a-development-branch`へ接続し、統合方法の判断を受ける。マージ後はretrospectiveを実施する。

## 完了基準と検証期待値の対応

| 仕様 | 所有タスク | 正常対照と失敗対照 |
|---|---|---|
| V1 | 1、6 | 正常v2コピー／未知キー・リンク・範囲外・再検証改変・衝突拒否 |
| V2 | 1、6、7、8 | 現在ファイルと履歴保持、途中探索／原本ファイル・HEAD・headRef・参照更新検出 |
| V3 | 3〜5、8 | 実欠陥fail→同じ再現テストpass／未開始・架空証拠は不成立 |
| V4 | 0、2、4、7 | 作業コピー書込成功／ホスト操作経路・Git・機密代用品・通信の拒否 |
| V5 | 2〜7 | 正常停止／起動失敗・不正応答・時間超過・原本更新・別実行継続 |
| V6 | 6、8 | 実主担当2種の往復／caller文字列だけでは未実証 |
| V7 | 1、5〜8 | 原本・記録保全、配布整合／別run・偽造・改変・上書き拒否 |

計画検証では、この表と各タスクの編集内容・試験内容を照合する。v1既存4群を保持し、新規7群を追加した後のランナー期待値は11群。タスク0・7・8の動的試験はこの数に含めない。既存の26件・23項目・7ケース・15ケースは過去実測であり、v2テスト件数や今回の再実行結果として固定しない。

コード例は局所の契約・実装の中心を示す。実MCPイベントや実効一覧のフィールドはタスク0の証拠を得る前に創作しない。未確認項目の解消を飛ばして、この草案を無条件の連続実行指示として使わない。

## 確定前の確認状況

仕様はフル1回・差分再確認1回・機械検証で確定済み。本計画はその写像であり通常型。独立レビューは未実施。計画特有の未確認範囲は、タスク0の成立判断から後続へ進む条件、ProcessHostのstdin変更、MCP直列受付とbusy、停止監督と結果照合の境界。

初回レビュー案は新規1担当が4観点（敵対的・実装整合性・仕様適合・前提実在）を兼務。独立レビューを選ぶ場合も、未確認の動的試験は無断実行しない。レビューで実測不能な箇所は未確認として残す。仕様にない実装方法の追加を伴う修正は、承認範囲と逸脱基準に照らして判断する。

2026-09-09の自己確認: タスク0〜8の9件、V1〜V7の対応7行、既存参照11件の実在、PowerShell例9ブロックの構文エラー0件を確認。試験群の期待値は既存4＋新規7＝11に照合済み。これらは文書の確認であり、例示コードの動作・実効ツール取得・Docker隔離の実証ではない。その後、ユーザーが選択肢1へ「１で」と回答し、主担当でタスク0から進める方式を選択。独立レビューは見送り。
