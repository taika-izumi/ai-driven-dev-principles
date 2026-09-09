# 隔離検証の共通起動処理の実装計画

> 実装担当への指示: `superpowers:executing-plans` または `superpowers:subagent-driven-development` を用いてタスク順に実装する。実装方式は計画確認後に選択する。サブエージェントを使う場合は各回の `subagent-dispatch` を適用する。

**目的:** Claude CodeとCodexの両主担当から、検証用コピー内で追加テストを作成・実行するCodexを呼び、結果を回収する。

**構成:** 共通CLIが依頼受付・コピー準備、制限付き実行、結果回収の3ブロックを呼ぶ。最初に実機の起動・設定の前提を確認し、成立した構成を実装へ組み込む。

**使用技術:** Windows 11、PowerShell 7と.NET標準機能、Git、Codex CLI 0.153.4。単体テストはPowerShellのスクリプトで実行し、追加のテストライブラリを導入しない。

**仕様:** [概要](../../current/specs/2026-09-09-isolated-verification/00-overview.md)、同ディレクトリの`01-request-and-copy.md`、`02-isolated-execution.md`、`03-result-collection.md`。

**仕様確定コミット:** `1e63e8a`。実装開始時は、この仕様と確定した本計画が実装用worktreeに揃っていることを確認する。

**状態:** 計画の確定前確認待ち。実装未着手。2026-09-09のユーザーの「1で」は仕様確定と本計画の作成への承認であり、実環境への導入・公開の承認ではない。

**中断記録:** 2026-09-09、ユーザーがコンテキスト増大を理由にセッションの区切りを希望したため、草案のまま保存する。実装方式と計画の独立レビューの要否は未選択。この保存は計画の確定・レビュー見送り・実装着手の承認を意味しない。

## 全体の制約

- 初回対象: Windows 11、PowerShell 7、Codex CLI 0.153.4。別の版は対応確認の対象とし、自動で確認済みにしない。
- 共通入口は `scripts/verification/Invoke-IsolatedVerification.ps1`。MCPサーバーや常駐サービスを初回の必須条件にしない。
- 原本・共有ツール・既存記録・制御領域は検証担当から書き込み不可。書き込み許可は当該実行の`work/`と`temp/`。
- テストコマンドの通信を禁止し、モデル・認証の通信と区別する。起動不能・拒否・未実行を検査成功へ含めない。
- 認証情報やユーザー設定を出力へ保存しない。設定から使う値を必要なものに限定する。
- 元のコードの自動修正、成果物の自動適用、既存物の削除は行わない。
- 既存の`.tmp/`、`.claude/`、inbox、他worktree・stashを保全する。試験の作成物は実行番号付きの専用領域へ置き、既存領域を再利用・一括削除しない。
- 実装開始時は`using-git-worktrees`で作業領域を確認する。既に隔離されたworktreeなら重ねて作らない。仕様コミットと本計画を含む状態から開始する。
- 重い実機検証は1件ずつ実行する。両主担当からの依頼は最後に別々に確認する。

## 承認・逸脱判断・レビューの引き継ぎ

仕様の承認範囲は概要の「決定と承認範囲」とADR-0145〜0148。包括的な判断の分担は未合意であり、既定の逸脱判断を拡張しない。

**逸脱判断の既定:** `skills/start-work/references/plan-deviation-defaults.md`（配布版0.1.24、リポジトリ側0.1.25予定版で同規範を確認）を適用する。承認済みの保護条件・成功条件・対応環境・公開範囲を広げない。実装タスクは実行テストを持ち、全文コードをそのまま書き写す方式にはしない。設計変更を要する場合は同規範に従って記録・判断する。

レビューの正本は[設計レビュー記録](../issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-isolated-verification-design-review.md)。初回4観点は静的確認に限定、差分再確認と軽微修正の機械確認を経て仕様を確定した。

- 不採用のR5（sourceRootの再解析ポイント検査の重複追加）は既存条項とV1で覆う。実装でsourceRootを除外する欠陥が出たら、前提が覆った証拠として扱う。
- R1/R4の「特定CLIフラグが必須」という断定は不採用。名前付き権限プロファイルを実測する。プロファイルで成立しなかった場合は、その結果をもって設計判断へ戻る。
- 独立レビュー未実証分: 新しいexec構成の権限・通信・自動読込設定・リンク・終了管理・両主担当の実経路。タスク0・2・4が担当する。
- 各タスク完了時、変更と計画を照合し、必要な`逸脱記録:`を当該タスク末尾へ書く。委譲しない実装では`逸脱照合: 一致 / 差分あり`を報告する。

## タスクと完了基準の対応

| タスク | 成果 | 仕様の基準 |
|---|---|---|
| 0 | 実機前提の試験と停止条件 | V4・V5・V6の前提 |
| 1 | 依頼の検査とコピー準備 | V1・V2 |
| 2 | 権限制限・プロセス管理・JSONL保存 | V3・V4・V5 |
| 3 | 結果照合・CLI結合・呼び出し説明 | V1・V5・V7 |
| 4 | 両主担当からの実証と完了検証 | V3・V4・V5・V6・V7 |

## 共通の実行準備とテスト規約

以下の変数を**実装用worktreeのルートに移動してから**設定する。計画内のコマンドはこのPowerShell 7セッションで実行する。ユーザーの通常チェックアウトを相対パスから推測しない。

```powershell
$RepoRoot = (Get-Location).Path
if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot 'AGENTS.md'))) {
    throw '実装用worktreeのルートで実行してください'
}
$PwshPath = (Get-Command pwsh -ErrorAction Stop).Source
$GitPath = (Get-Command git -ErrorAction Stop).Source
$CodexPath = (Get-Command codex -ErrorAction Stop).Source
```

テスト補助は`tests/TestSupport.psm1`に置く。`Assert-True(Value, Because)`、`Assert-Equal(Actual, Expected, Because)`、`Assert-Throws(Action, MessagePattern)`、`New-TestCase(Name)`を定義する。例外は握りつぶさずテストプロセスの非ゼロ終了へ伝える。

```powershell
function Assert-True([bool]$Value, [string]$Because) {
    if (-not $Value) { throw "ASSERT: $Because" }
}
function Assert-Equal($Actual, $Expected, [string]$Because) {
    if ($Actual -cne $Expected) { throw "ASSERT: $Because; actual=$Actual expected=$Expected" }
}
function Assert-Throws([scriptblock]$Action, [string]$MessagePattern) {
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_ }
    if ($null -eq $failure -or $failure.Exception.Message -notlike $MessagePattern) {
        throw "ASSERT: expected exception $MessagePattern"
    }
}
```

`New-TestCase`は実装用worktreeの`.tmp/verification-tests/<UUID>-<Name>/`に、`source/`と`runs/`を新規作成する。ルートはTestSupport.psm1自身の`$PSScriptRoot`から3階層上として解決し、呼出元の現在ディレクトリや暗黙のグローバル変数に依存しない。戻り値は`root, sourceRoot, runsRoot, request, settings`。request/settingsは下記の形とし、実行ファイルはGet-Commandで絶対パスを得る。`source/`は空のテンプレートでGit初期化し、`tracked.txt`（内容`baseline`）だけをステージする。実リポジトリへステージしない。追加・変更・削除の試験は、この関数が当該試験で作ったファイルだけを操作する。

テストごとに依頼と設定を次の形で作る。`unit-test`はAIを起動しない単体試験専用のモデル値で、実機のAI試験では導入設定の実在モデルを使う。

```powershell
$case = New-TestCase 'copy'
$request = @{
    schemaVersion = 1; caller = 'codex'; sourceRoot = $case.sourceRoot
    objective = 'コピーされたファイルを検証する'
    acceptanceCriteria = @('入力とコピーの内容が一致する'); extraInputPaths = @()
}
$settings = @{
    codexPath = $CodexPath; pwshPath = $PwshPath; runsRoot = $case.runsRoot
    model = 'unit-test'; timeoutSeconds = 30
}
```

## タスク0: 起動と保護の前提を先に確認する

**作成するファイル:**

- `scripts/verification/tests/TestSupport.psm1`
- `scripts/verification/tests/Invoke-EnvironmentProbe.ps1`
- `scripts/verification/tests/fixtures/BoundaryProbe.ps1`
- `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-common-cli-runtime.md`

**入力:** `-CodexPath`、`-PwshPath`、`-ProbeRoot`（存在しない絶対パス）。AIを呼ぶ試験は別の明示スイッチ`-IncludeAgentProbe`と実在モデルの`-Model`を要する。単にこのスクリプトを実行しただけではAIを起動しない。

**出力:** 試験ごとの許可・拒否・未実行、実行ファイルの版、実効指定、作成物を`ProbeRoot/control/environment-result.json`へ保存する。失敗・未確認なら後続タスクへ進まない。

- [ ] 試験領域を新規作成し、work・temp・control・原本代用品・共有ツール代用品・既存記録代用品を別々に配置する。各保護代用品の内容とSHA256を先に保存する。
- [ ] `codex --version`、`codex exec --help`、`codex sandbox --help`の現在の出力を保存する。版が0.153.4でない場合はその版の確認として分離する。
- [ ] `BoundaryProbe.ps1`に以下の試行関数を書き、work/tempの新規作成と、control・原本・共有ツール・既存記録・work/.gitの代用品への上書きを別々に記録する。`.git`は試験用workで新規に初期化する。

```powershell
function Test-ProbeWrite([string]$Path) {
    try {
        [IO.File]::WriteAllText($Path, 'probe', [Text.UTF8Encoding]::new($false))
        return @{ path=$Path; write='allowed'; error=$null }
    } catch {
        return @{ path=$Path; write='denied'; error=$_.Exception.GetType().FullName }
    }
}
```

- [ ] `permissions.inspection`を`extends=":read-only"`から作り、work/tempだけwrite、control・work/.gitはread、network.enabled=falseを指定する。`codex sandbox -P inspection -C <work> -c <プロファイル>`から絶対パスのPowerShellで試験を呼ぶ。引数は`ProcessStartInfo.ArgumentList`へ個別に追加し、文字列のシェルへ展開しない。
- [ ] コマンドが動いたことと、拒否がポリシーによることを区別する。期待値はwork/tempで成功、保護代用品で拒否かつハッシュ不変。子PowerShellでも許可先成功・保護先拒否の両方を確認する。
- [ ] 通信はループバックの使い捨てTCP待受を親側で起動し、通常実行が接続成功する対照を前後に取る。その間の制限付き実行で接続が拒否されることを確認する。待受を停止して接続失敗を作る試験は採用しない。

```powershell
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
$listener.Start()
try {
    $port = $listener.LocalEndpoint.Port
    $client = [Net.Sockets.TcpClient]::new()
    try { $client.Connect('127.0.0.1', $port) } finally { $client.Dispose() }
    # listenerを存続させた状態で、同じ接続を制限付きの試験プロセスへ渡す。
    # 試験プロセスの実行後にも、上記の通常接続をもう一度行う。
} finally { $listener.Stop() }
```

- [ ] 新規のjunction経由でも保護代用品に書けないことを確認する。リンクの作成が環境上できない場合は拒否成功に数えず、その試験を未実行とする。
- [ ] AIなしの試験が成立してから、`-IncludeAgentProbe`を明示し、採用するexec引数・モデル・認証で無害なファイル作成とReadを1回試す。起動時の自動読込設定、利用可能ツール、MCP・フック・Web等の別経路を確認する。無効化指定の存在だけで成功にしない。
- [ ] `exec --json`で`item.completed/command_execution`とcommand・exit_code等が取れること、同じ構成で内蔵編集も制限されることを確認する。範囲外へ書き込めたらその経路を起動不可として記録し、保護を緩めず設計判断へ戻る。
- [ ] 具体的な設定キーと起動引数、確認できた範囲、失敗をruntimeノートへ残す。ヘルプに載らない設定や、プロジェクト設定の無効化方法を推測で確定しない。

**確認コマンド:**

```powershell
$probeRoot = Join-Path $RepoRoot ('.tmp/verification-probes/' + [guid]::NewGuid())
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/verification/tests/Invoke-EnvironmentProbe.ps1') `
    -CodexPath $CodexPath -PwshPath $PwshPath -ProbeRoot $probeRoot
if ($LASTEXITCODE -ne 0) { throw '事前試験が成立していない' }
```

**完了条件:** 許可側と拒否側の正負対照、別経路の確認、採用するexec構成の最小AI試験が記録されている。`sandbox`単体の成功だけでは完了しない。起動が依頼元の制限に拒否される場合は、実際に拒否された操作と利用者の必要作業を示して停止する。

**コミット:** 上記4ファイルだけをステージし、`test: 隔離検証の起動条件と保護境界を確認する試験を追加`。

## タスク1: 依頼の検査とコピー準備

**作成:** `scripts/verification/RequestCopy.psm1`、`scripts/verification/request.schema.json`、`scripts/verification/tests/RequestCopy.Tests.ps1`。

**公開インターフェース:** `New-VerificationRun -Request <hashtable> -Settings <hashtable> -> PreparedRun`。型と全キーは仕様01をそのまま使う。失敗は例外の`Data['status']`に`blocked`または`source_changed`、作成後なら`Data['runRoot']`に絶対パスを保持し、タスク3のCLIで結果へ変換する。

- [ ] 先に入力の未知キーとコピー内容の試験を書き、モジュール未実装による失敗を確認する。

```powershell
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
$case = New-TestCase 'request-copy'
$request = $case.request
$settings = $case.settings
$request['unexpected'] = '拒否対象'
Assert-Throws { New-VerificationRun -Request $request -Settings $settings } '*unknown*'
$request.Remove('unexpected')
[IO.File]::WriteAllText((Join-Path $case.sourceRoot '未追跡 file.txt'), 'new')
$run = New-VerificationRun -Request $request -Settings $settings
Assert-Equal ([IO.File]::ReadAllText((Join-Path $run.workRoot '未追跡 file.txt'))) 'new' '未追跡をコピーする'
Assert-Equal $run.sourceRoot $case.sourceRoot '原本の場所を保持する'
```

- [ ] `request.schema.json`は全6キーをrequired、additionalProperties=falseとし、仕様01の型・列挙・空文字/空配列の条件を実装する。設定の5キーも未知キーを拒否する。実行ファイルの実在と絶対パス、正の整数timeoutSecondsを確認する。
- [ ] Git列挙は`ls-files -z --cached --others --exclude-standard`のNUL区切りをそのまま分割する。改行区切りへ変換しない。未コミットの作業ツリー内容を読み、存在しない追跡ファイルは削除として記録する。
- [ ] 実在パスと祖先を検査し、sourceRootを含む再解析ポイントを拒否する。文字列の単純な前方一致ではなく、絶対パスとディレクトリ区切りを使って包含を判定する。`repo-other`を`repo`配下にしない。
- [ ] runsRoot・.git・起動設定の除外を適用する。extraInputPathsは原本内の相対パスだけを許し、除外した入力を一覧へ記録する。コピー中の元ファイル変更・追加・削除を前後の一覧とハッシュで検出し、採用しない。
- [ ] UUIDごとにwork/temp/controlを作成し、ファイルのバイト列をコピーする。既存の実行領域は再利用しない。コピー後、空のテンプレートでworkにGit初期化を行い、最上位と.gitのパスを照合する。読取制限はタスク2が行う。
- [ ] 以下の入力をそれぞれ独立したケースで試験し、期待値を確認する。

| 入力・操作 | 期待値 |
|---|---|
| 不正JSON、未知キー、空の成功条件 | 起動前のblocked |
| `extraInputPaths=['../outside.txt']`、絶対パス | blocked、原本外を読まない |
| sourceRootまたは入力中のjunction | blocked、リンクを辿らない |
| runsRoot=sourceRootまたはその祖先 | blocked |
| runsRootが原本の子 | runsRootを入力から除外し、通常入力だけコピー |
| tracked.txtの未コミット変更 | index内容ではなく現在の内容をコピー |
| 当該試験で作成・追跡したファイルの削除 | workに作らず、削除状態をmanifestへ記録 |
| コピー途中に当該試験の入力を書き換える | source_changed、実行へ渡さない |
| 空白・日本語のファイル名 | 内容と相対パスが一致 |
| 原本配下/原本外のwork | Gitの最上位と.gitがwork内に一致 |

- [ ] `RequestCopy.Tests.ps1`を成功まで修正する。実装都合でコピーの対象を縮めて試験を緑にしない。

```powershell
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/verification/tests/RequestCopy.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'RequestCopy tests failed' }
```

**コミット:** このタスクの3ファイルと必要なTestSupport更新だけをステージし、`feat: 検証依頼を検査して独立したコピーを作成`。

## タスク2: 制限付き実行とプロセス終了管理

**作成:** `scripts/verification/Execution.psm1`、`scripts/verification/agent-result.schema.json`、`scripts/verification/tests/Execution.Tests.ps1`、`scripts/verification/tests/fixtures/ProcessFixture.ps1`。

**公開:** `Start-VerificationExecution -PreparedRun <hashtable> -> ExecutionResult`。全キーは仕様02に一致させる。

**内部関数:** `New-ExecutionStartInfo -PreparedRun`が`ProcessStartInfo`を返し、`Invoke-VerificationProcess -StartInfo -EventsPath -ErrorPath -TimeoutSeconds`が`started, exitCode, timedOut, processTreeStopped`を返す。低水準の関数はテストからモジュールスコープで呼ぶが、共通CLIの外部引数には公開しない。

- [ ] 引数と作業ディレクトリ、TEMP/TMPの試験を先に書く。依頼に引用符・改行・バッククォートを含めてもプロセスの引数列が変わらないことを確認する。

```powershell
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../Execution.psm1') -Force
$case = New-TestCase 'execution'
$run = New-VerificationRun -Request $case.request -Settings $case.settings
$startInfo = & (Get-Module Execution) { param($r) New-ExecutionStartInfo -PreparedRun $r } $run
Assert-Equal $startInfo.WorkingDirectory $run.workRoot 'cwdはコピーだけ'
Assert-Equal $startInfo.Environment['TEMP'] $run.tempRoot 'TEMPを限定'
Assert-Equal $startInfo.Environment['TMP'] $run.tempRoot 'TMPを限定'
Assert-True (-not $startInfo.UseShellExecute) '文字列のシェルに渡さない'
Assert-True $startInfo.CreateNoWindow '別ウィンドウを表示しない'
```

- [ ] タスク0で確認済みの設定を組み込む。-CはworkRoot、プロファイルはwork/tempがwrite、control・work/.gitがread、network.enabled=false。TOMLのパスを文字列としてエスケープし、依頼から設定キー・追加のCLI引数を受け取らない。
- [ ] 自動読込設定を無効または保護された入力へ分離する方法はタスク0の実測に従う。ユーザー設定・認証を変更せず、一般ソースを除外したことにして保護を成立させない。除外一覧をcontrolへ保存する。
- [ ] 依頼・成功条件・原本とコピーの位置・禁止範囲を標準入力へ渡す。実行ログと最終応答はcontrolに起動側が保存する。JSONLは途中イベントを含めて全保存し、stderrと並行して読み取る。
- [ ] `agent-result.schema.json`は仕様02の全キーをrequired、additionalProperties=falseにする。verdictの3値、checksのcommand/exitCode/evidencePath、findings/artifacts/unverifiedの配列を定義する。構造化出力の各objectは追加プロパティを拒否する。
- [ ] ProcessFixtureに、短い正常終了、標準出力と標準エラーの大量出力、明示的な終了コード7、試験用子PowerShellを起動して待機する4ケースを作る。fixtureの書き込みは当該テスト領域に限る。

```powershell
# ProcessFixture.ps1の正常/非ゼロ終了ケース
param([ValidateSet('ok','fail','output','child')][string]$Mode)
if ($Mode -eq 'ok') { [Console]::Out.WriteLine('{"fixture":"ok"}'); exit 0 }
if ($Mode -eq 'fail') { [Console]::Error.WriteLine('fixture failure'); exit 7 }
if ($Mode -eq 'output') {
    for ($i=0; $i -lt 4096; $i++) {
        [Console]::Out.WriteLine(('o' * 256))
        [Console]::Error.WriteLine(('e' * 256))
    }
    exit 0
}
```

- [ ] `child`ケースでは、同じPowerShell実行ファイルで`Start-Sleep -Seconds 120`を子として起動し、そのPIDを当該試験領域へ記録する。親も待機する。ProcessStartInfoを使い、共有プロセス名では終了しない。
- [ ] 上記fixtureを呼ぶStartInfoで低水準関数を検査する。正常0、非ゼロ7、両ストリームの全保存、時間超過時の親子停止を確認する。単なるPIDの不存在は再利用と区別し、起動時刻と実行ファイルも対応付ける。
- [ ] 停止確認が取れない場合はprocessTreeStopped=falseとし、同じCLI呼出で再起動しない。権限を緩める自動再試行を実装しない。実効条件を増やす必要が出た場合は設計判断へ戻る。

```powershell
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/verification/tests/Execution.Tests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Execution tests failed' }
```

**完了条件:** AIなしの上記全ケースが合格し、タスク0で確認したプロファイル生成と起動処理が一致する。モデルを使う全体の動作はタスク4で別に確認する。

**コミット:** タスクの4ファイルをステージし、`feat: 制限付きCodexの起動と結果保存を実装`。

## タスク3: 結果の照合と共通CLIの結合

**作成:** `scripts/verification/Result.psm1`、`scripts/verification/result.schema.json`、`scripts/verification/Invoke-IsolatedVerification.ps1`、`scripts/verification/README.md`、`scripts/verification/tests/Result.Tests.ps1`、`scripts/verification/tests/Cli.Tests.ps1`、`scripts/verification/tests/Run-UnitTests.ps1`。

**公開:** `Complete-VerificationRun -PreparedRun <hashtable> -ExecutionResult <hashtable> -> VerificationResult`。仕様03の全キーと終了コードを保持する。CLIは`-RequestPath -SettingsPath`だけを入口とし、モジュール順序を固定する。

- [ ] 先に正常な実行イベントと応答をテスト領域へ保存し、対応する結果を確認する試験を書く。タスク1の`New-VerificationRun`で作ったrunを使い、原本の基準値も実在させる。

```powershell
Import-Module (Join-Path $PSScriptRoot 'TestSupport.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../RequestCopy.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../Result.psm1') -Force
$case = New-TestCase 'result'
$run = New-VerificationRun -Request $case.request -Settings $case.settings
$event = @{
    type='item.completed'
    item=@{ id='item_1'; type='command_execution'; command='fixture-check'; exit_code=0; aggregated_output='ok' }
}
$agent = @{
    runId=$run.runId; verdict='pass'; summary='fixture passed'
    checks=@(@{command='fixture-check';exitCode=0;evidencePath='work/evidence.txt'})
    findings=@(); artifacts=@('work/evidence.txt'); unverified=@()
}
[IO.File]::WriteAllText((Join-Path $run.workRoot 'evidence.txt'), 'ok')
$eventsPath = Join-Path $run.controlRoot 'events.jsonl'
$eventLines = @(
    '{"type":"thread.started","thread_id":"test-thread"}',
    ($event | ConvertTo-Json -Depth 5 -Compress),
    '{"type":"turn.completed"}'
)
[IO.File]::WriteAllText($eventsPath, ($eventLines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
$agentPath = Join-Path $run.controlRoot 'agent-result.json'
[IO.File]::WriteAllText($agentPath, ($agent | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
$execution = @{
    runId=$run.runId;started=$true;exitCode=0;timedOut=$false;processTreeStopped=$true
    eventsPath=$eventsPath;stderrPath=(Join-Path $run.controlRoot 'stderr.txt')
    agentResultPath=$agentPath;effectiveConfigPath=(Join-Path $run.controlRoot 'effective-config.json')
}
$result = Complete-VerificationRun -PreparedRun $run -ExecutionResult $execution
Assert-Equal $result.status 'completed' '応答と記録が一致する'
Assert-Equal $result.checks[0].eventId 'item_1' '実イベントを対応付ける'
```

- [ ] JSONL全体から開始・終了・失敗とcommand_executionの完了イベントを読む。最終応答、runId、終了状態、checksのcommandとexitCode、実ファイルの存在・ハッシュを照合する。任意コードを結果から実行しない。
- [ ] 同じcommandの複数実行など一意に対応できない場合はincompleteとする。意図した不合格の検出を成功条件とする場合は、非ゼロ終了だけで判定を覆さない。実出力の意味を一般的に証明できると主張しない。
- [ ] 原本の選択規則をタスク1と共有し、追加・変更・削除でsource_changedを返す。原本が読めない場合も合格にせず、sourceState=unreadableでincompleteとする。新しい読み取りの結果を使い、検証担当の自己申告へ依存しない。
- [ ] 各ケースを新しいrunで実行し、以下の値を確認する。同じrunのresult.jsonを上書きして試験しない。

| ケース | 期待値 |
|---|---|
| 起動していない、認証エラー、環境不一致 | blocked、終了コード2 |
| 終了コード0でも応答欠落・不正JSON・別runId | incomplete、終了コード2 |
| 実行イベントなしでpass、矛盾する実終了コード | incomplete、終了コード2 |
| 実行・証拠が一致する不合格報告 | completedかつagentVerdict=fail、終了コード1 |
| 結果の参照先が原本外・実行領域外・junction | incomplete、外側の成果物を採用しない |
| 原本の追加・削除・変更 | source_changed、終了コード2 |
| 時間超過、停止未確認 | timed_out、processTreeStoppedを保持、終了コード2 |
| 既存result.jsonあり | 上書き拒否、既存バイト列不変 |

- [ ] CLIでJSON解析・タスク1〜3の呼出と例外変換を行う。受付前の不正JSONではrunを作らず、runId/runRootはnull、status=blocked、agentVerdict=null、sourceState=unreadableとして全キーを持つJSONを返す。作成後の失敗では例外DataのrunRootを返し、作成物の所在を失わない。
- [ ] CLIのstdoutが結果JSON1件だけであることを、stderrに説明があるケースでも検査する。completed/pass→0、completed/fail→1、それ以外→2の終了コードを実プロセスから読む。
- [ ] READMEに依存、導入設定の5キー、両主担当で同じ呼出を使うこと、起動拒否時の扱い、モデル利用の費用、保存物と名指し削除、未対応のGit履歴依存検査を説明する。常時読み込むAGENTS.mdや配布スキルを変更しない。

```powershell
# READMEに載せる共通呼び出しの形。各パスは主担当が作成・確認した絶対パスを使う。
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/verification/Invoke-IsolatedVerification.ps1') `
    -RequestPath $RequestPath -SettingsPath $SettingsPath
```

- [ ] Run-UnitTests.ps1はRequestCopy/Execution/Result/Cliの4スクリプトを別PowerShellで順に実行する。どれか非ゼロなら全体を非ゼロで終える。各スクリプトの作成物の場所を報告する。

```powershell
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/verification/tests/Run-UnitTests.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Unit tests failed' }
```

**コミット:** タスクの7ファイルをステージし、`feat: 検証結果を照合して共通CLIへ結合`。

## タスク4: 両主担当からの実証と完了確認

**作成:** `scripts/verification/tests/Invoke-IntegrationTests.ps1`、runtimeノートへの実測追記。**更新:** READMEの確認済み範囲、実装計画の各チェック、handoffと課題の進捗記録。

**入力:** 導入設定ファイルと使い捨て試験領域。AIの実行モデルは既存の選択または利用者が指定したものを設定へ明示する。単体テスト用の`unit-test`で実AIを起動しない。実機テストの対象と送信内容はこの使い捨て題材に限定する。

- [ ] 小さな加算関数を持つGit原本を新規作成する。未コミットの内容をコピー対象とし、検証担当へ加算の成功条件からテストを作るよう依頼する。

```powershell
function Get-VerificationSum {
    param([int]$Left, [int]$Right)
    $Left + $Right
}
```

- [ ] 正常ケースでCodexが新しいテストファイルを作成し、実際に実行したことを確認する。用意済みのテストだけを起動した試験ではV3の代わりにしない。
- [ ] 別の使い捨て原本で加算を減算へ変え、同じ成功条件を渡す。`2,3`に対して期待値5・実際値-1のような実質的な不合格を検出することを確認する。起動不能や無条件throwを欠陥検出に数えない。各原本は試験後にハッシュ不変を確認する。
- [ ] 両ケースで原本・共有ツール・既存記録・control・.gitの保護代用品、許可側work/temp、子PowerShell、実行中の新規リンクを確認する。結果を指示したというだけでは成功にせず、実呼出・実エラー・前後ハッシュを残す。
- [ ] 実CodexでJSONLとchecksを一意に対応付けられることを確認する。コマンドの自動ラップ等で仕様どおりに照合できない場合、偽の合格を作る文字列補正を足さず設計判断へ戻る。
- [ ] 長時間の試験用子プロセスを持つ実行で時間超過を起こし、起動した親子の停止を確認する。停止確認を取れない結果が成功へ変換されないことも確認する。
- [ ] Claude Codeの実セッションから1件、Codexの実セッションから1件、同じ共通CLIへ依頼して結果を回収する。callerの文字列だけを書き換えた2回のシェル実行ではV6を満たさない。両方の開始・呼出・回収記録を保存する。
- [ ] 片方の実セッションや承認操作が利用できなければ、その側を未実行として停止する。利用者が行う必要のある操作を、準備済みの依頼・設定・コマンドとともに具体的に示す。通常利用への導入済みと報告しない。
- [ ] V1〜V7の証拠表をruntimeノートへ記録する。結果本文、実行ログ、対象ハッシュ、版、原本との関係が復元できるパスを示す。`.tmp`の一括ステージはしない。
- [ ] 既存の配布検査を読み取りモードで実行する。

```powershell
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/build-dist.ps1') -Check
if ($LASTEXITCODE -ne 0) { throw 'build-dist check failed' }
& $PwshPath -NoProfile -File (Join-Path $RepoRoot 'scripts/sync-template.ps1') -Check
if ($LASTEXITCODE -ne 0) { throw 'sync-template check failed' }
```

- [ ] scripts/verificationの本体、テスト、README、仕様の対応を最終レビューする。検査担当へ実行を委譲する場合、今回実装した機構を確認前に自分自身の保護の根拠として使わない。
- [ ] `decision-log`のサイクル全体整合検査を実施する。ADR-0145〜0148は実装前にAcceptedへ昇格したため、実装完了時の後追い検査を省略しない。Issue-0136全体には他の未確認が残るため、本タスクだけで自動closeしない。
- [ ] 最終差分と作成物を確認し、対象ファイルだけをコミットする。`finishing-a-development-branch`へ接続し、統合方法の判断を行う。公開・プラグイン配布・ユーザー環境の導入は別承認として残す。

**完了条件:** V1〜V7が実証され、例外・未対応範囲と利用者の操作をREADMEへ反映している。未達がある場合は、達成済み範囲と止まった理由を報告し、対応済みへ変更しない。

## 計画の自己照合

- 仕様の3ブロックと本体8ファイルをタスク1〜3へ割り当てた。テスト・補助・実測ノートは実装本体と分けて数える。
- V1〜V7は冒頭の対応表と各タスクの期待値に割り当てた。Git探索先の既存確認は再利用するが、新しい関数の出力もタスク1で確認する。
- read-onlyのreview結果を、execの動的な保護試験の合格へ読み替えない。事前試験0と両依頼元の実証4を別に残した。
- 通信の負の試験は正の対照と組にし、接続先停止による偽の拒否を除く。明示的な欠陥の検出と起動不能を区別した。
- 列挙件数の固定期待値は、本体8ファイル・単体試験4スクリプト・両主担当2件に限定し、個別テスト追加で変わるassert数を固定しない。

## 計画の確定前レビュー

未実施。上流仕様は静的4観点確認と差分再確認を経て確定したが、本計画の順序、試験コード、前提試験から後続タスクへの接続はまだ独立に確認していない。計画の選択時に実施の要否と方式を確認する。

成果物の型は通常型。READMEの運用範囲は承認済み仕様を写すもので、未レビューの新規な共通規範を加えていない。計画自身の試験手順は規範改定型の判定に含めない。ここまでに実施した自己確認は、V1〜V7のタスク対応、参照先、掲載PowerShell16ブロックの構文解析のみであり、実行テストの成功ではない。

推奨する次手は、計画確定後にこのセッションでタスク0から順に実装すること。主な不確実性は実機の保護条件にあり、追加の静的レビューより先に正負対照を取れるためである。独立レビューを選ぶ場合は新規1担当で4観点を確認する。費用は未実測だが、計画約34KBと仕様等を読む1担当1回分を見込む。動的な実証は保護の成立を確認した範囲に限り、未実装のコードを実行済みと扱わない。
