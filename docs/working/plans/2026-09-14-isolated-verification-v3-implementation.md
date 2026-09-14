# 隔離検証 v3（提案と通信なし再実行）実装計画

> **実装担当へ:** `superpowers:subagent-driven-development`（推奨）または `superpowers:executing-plans` でタスク単位に進める。各ステップは `- [ ]` で追跡する。VMを作る操作（タスク8・9）は本計画の作成承認に含まれず、区切りごとの個別承認が必要。

**目的:** Claude CodeまたはCodexの主担当が共通CLI 1本で、独立コピー上のsbx内Codexに再現テストと修正候補を提案させ、別の通信なしVMで採否用の再実行を取り、外側の記録で照合した結果を受け取れるようにする。

**構成:** 準備（01）→提案（02）→再実行（04）→照合（03）の4責務を `scripts/verification/` の既存v1部品の上に足す。v1の公開契約と4試験群は保持し、v3はschemaVersion=3だけを受理する。VMを使う部分は `SbxRuntime.psm1` に閉じ、他ブロックはその公開操作だけを呼ぶ。VMなしで検査できる契約・拒否・停止の試験を先に揃え、実VM・実モデルは個別承認の区切りで行う。

**技術:** Windows 11、PowerShell 7、Git、sbx 0.42.1（利用者が通常端末で起動したデーモン）、固定テンプレート `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`（Python 3・unittest）。ホスト側の Python 3 は合成題材の事前確認にだけ任意で使う。新規パッケージ・常駐サービスは追加しない。

**仕様:** `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`、`01-request-and-copy.md`、`02-isolated-execution.md`、`03-result-collection.md`、`04-offline-replay.md`（`5259d22` で確定した試作条件を含む現行版）。

**実測の前提:** `docs/reference/sbx-sandbox-runtime-facts.md`（自動停止30秒・cp/execの自動起動・透過プロキシ・SSH中継の実体・外側記録の所在）と `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（試験A〜D合格）。

## 共通制約と承認の境界

- 作業場所は `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`、ブランチ `codex/isolated-verification`。作成時HEADは `3385d24`。未追跡 `.tmp/`・他worktree・stash・試験VM2台（`iv-sbx-smoke-20260909-01`、`iv-sbx-capability-20260914-01`）を保全し、削除・再作成しない。
- v3は schemaVersion=3 のみ受理。v1公開関数（`New-VerificationRun` 2引数、`Complete-VerificationRun` 2引数、`Invoke-VerificationProcess`）の挙動と既存4試験群（RequestCopy・History・Execution・Result）を保持する。未実装v2は受理しない。
- synthetic-pilot固定: `cpus=2`、`memoryMiB=2048`、同時1VM、`scope=synthetic-pilot`、`acceptedLimitations=["clipboard-text-write-possible","pid-count-unbounded"]`。初期上限は全体1800秒・提案600秒・各再実行120秒・停止猶予30秒・100ファイル・1ファイル1MiB・合計8MiB・転送16MiB・1コマンド出力合計16MiB。pidsキーは未知キーとして拒否する。
- 原本・baseline・control・ホストホーム・資格情報をVMへ渡さない。VMにはproposal-input（提案用）と replay-inputs/before|after（再実行用）だけを `sbx cp` で搬入する。共有skills・workspace・追加MCPサーバーを与えない。
- sbx CLIは常に外側で固定argvを組み立てて起動する。子からホストコマンド・sbxフラグ・接続先を受け取らない。sbx CLIの環境は明示した最小辞書とし、`SSH_AUTH_SOCK` を渡さない。
- デーモンの起動・再起動・reset・設定変更はランナーの責務外。停止中なら「利用者が通常端末で起動する必要がある」と返してblocked。`sbx daemon status --json` だけは停止中でも呼んでよい（自動起動しないことを実測済み）。`ls`・`inspect`・`settings`・`cp`・`exec` は running 確認後だけ呼ぶ。
- VMは最後のセッション切断から30秒で自動停止し、`cp`・`exec` は停止VMを自動起動する。SbxRuntimeはVM作成直後から停止までセッション保持用のexecを1本保つ（タスク2の背景起動操作を使う。ADR-0193）。run途中の自動停止・自動再起動は daemon.log の行で検知し、当該runを `incomplete` にする。停止確認は `ls --json` の同一ID・stopped、stop発行後の時刻の `stopped runtime container` 行、操作前後のデーモン世代不変で行う。
- 接続成立（TCPハンドシェイク）を到達の証拠にしない。通信・SSHの拒否はプロトコル応答・policy log・daemon.logで判定する（試験Aの方式）。
- 全体 deadline 到達後は新しいVM作成・搬入・実行を開始しない。停止処理（保持セッションの停止・`stop`・`ls` による停止確認）だけは `cleanupDeadlineAt = deadlineAt + cleanupSeconds` まで許す。
- モデル自己申告、設定値の受理、sbx CLIの終了だけを保護・実行・停止の証拠にしない。原本へ自動適用しない。回収物をホストでimport・実行しない。
- 失敗領域・停止VMは診断用に残す。VMの名前はrunごとに一意（下記）にし、残置VMと衝突させない。VM削除（`sbx rm`）・イメージ変更・導入・公開・masterへの統合は本計画の承認に含めない。

### 判断の分担・逸脱判断の既定

判断の分担はADR-0158の補助設計委任（`00-overview.md`「判断の分担と参照」、承認時点 `b7941f3`）。補助機能の仕様・内部構造・対策方法は委任範囲。保護の追加緩和、新たな必須基盤・利用者作業、認証・利用費・送信範囲、削除・公開は相談する。実機・設定・モデル操作の承認はADR-0162・ADR-0192の範囲に限り、本計画のタスク8・9は個別承認を別に得る。

逸脱判断は `ai-driven-dev-principles` 導入版 **0.1.29** の `skills/start-work/references/plan-deviation-defaults.md` に従う。計画確定時に基準を固定する。委任された局所仕様変更（補助設計）は既定の型分類で扱い、保護条件・外部契約（Request/Settings/Result/ProposalEnvelopeのschema、固定argv）に触れるものは「設計の変更」側へ倒す。動作テストを安全網とする通常の実装計画で、コード全文の書き写し方式ではない。タスク別の仕様適合レビューを置く工程（subagent-driven-development）を既定とし、置かない場合は設計変更で独立レビューへ切り替える。各タスク末尾に必要な `逸脱記録:` を残す。

確定前レビューからの引き継ぎ一覧: 初回フル実施（1体4観点兼務、claude-opus-5、2026-09-14）の指摘17件の採否は本計画末尾「確定前の確認状況」に記す。不採用の指摘は現時点でなし。仕様レビュー（`docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`、`2026-09-10-synthetic-pilot-scope-r2.md`）の不採用指摘を再提案する場合は、実装後の実体で以前の理由が覆る証拠を要する。

本計画が仕様に対して加える実体合わせの調整（設計の変更ではない）: (a) 共通の正規化・ハッシュ・新規作成書込・重複キー検査の補助関数を `RequestCopy.psm1` から公開する（新モジュールを増やさない）。(b) 固定入力記録のschemaを `pilot-input.schema.json`、activationEvidenceのschemaを `activation-evidence.schema.json` として置く。(c) デーモン世代の取得元は `daemon status --json` の `logs` パス（running時に実測済み）から状態ディレクトリを導き、PIDファイル・`daemon.log` の起動行・OSプロセスのStartTimeを対応付ける。

本計画が仕様に足す設計（設計の変更として扱い、確定はADRで記録する）: (d) セッション保持のexec（30秒自動停止への対処。02「停止中の自動再起動防止」の実現手段。既存Executionの同期契約の外側に背景起動を足す）。(e) CLI異常終了時の停止経路（記録済みIDだけを止める復旧操作。ADR-0194）。

### 相談事項（3件とも2026-09-15に確定。ADR-0193・0194・0195）

1. **セッション保持exec（(d)）**: 確定済み（2026-09-15、ユーザーが選択肢1を選択。ADR-0193、Proposed）。代替案（再起動前提方式・製品設定の調査）は同ADRに記録。実VM試験（タスク8）に約30分の連続保持の確認を含める。
2. **V5「CLI切断時の停止」「対象外VMの継続」の扱い**: 確定済み（2026-09-15、ユーザーが選択肢1を選択。ADR-0194、Proposed）。`finally` の停止に加え、control/runtime の記録済みIDだけを停止する復旧操作 `Stop-VerificationRecordedSandboxes`（CLI入口 `-StopRecorded`）を設け、タスク8でCLI強制終了後の自動停止と復旧操作を実機で確認する。
3. **MCPゲートウェイ**: 確定済み（2026-09-15、ユーザーが選択肢1を選択。ADR-0195、Proposed）。仕様02の「MCP登録なし」は登録済みMCPサーバー0件で判定し、製品が常設するゲートウェイと `mcpgateway` secret（プロキシ管理のセンチネルトークン）は製品挙動として activationRecord と結果に明記する。利用者の資格情報の露出判定は別に行う。

### 実行承認を求める具体的な区切り

| 区切り | 提示する対象 | 承認に含めないもの |
|---|---|---|
| タスク8のAIなし実VM試験 | 使うVM名・固定argv・搬入する合成題材（内容とhash）・実行コマンド・停止手順・transport対照（0/7/127/時間超過/切断）・取得する証拠・所要見込み | モデル起動、認証、既存VMの操作、削除、イメージ変更 |
| タスク9の最小モデル往復 | 認証の渡し方（sbxの資格情報プロキシの実測結果を先に提示）・モデル・送信範囲・最大時間・題材・保存先 | 任意の別リポジトリ、通常導入・公開、clipboard操作 |

重い試験は1件ずつ。利用者の作業が必要なら（デーモン起動）、確定したコマンドと結果保存先を用意し、本文転記は求めない。

## ファイルと責務

特記しない限り `scripts/verification/` からの相対パス。

| ファイル | 操作・責務 | タスク |
|---|---|---|
| `RequestCopy.psm1`、`request.schema.json`、`settings.schema.json`、`pilot-input.schema.json` | 変更・新規。v1保持、v3の検査・固定入力照合・run配置・baseline/proposal-input・recheck。正規化JSON/ハッシュ/新規作成書込/重複キー検査の公開 | 1 |
| `Execution.psm1`、`ProcessHost.ps1` | 変更。`Invoke-VerificationProcessV3`（対象stdinへのバイト転送・合算出力上限・RunBudget）と背景起動の `Start-VerificationBackgroundProcess`/`Stop-VerificationBackgroundProcess` | 2 |
| `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-evidence.schema.json`、`activation-record.schema.json` | 新規。実行設定検査、pilot排他、VM作成・搬入・照合・実行・停止、activationRecord、デーモン世代、記録済みIDの復旧停止 | 3 |
| `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py` | 新規。提案VMの起動・依頼・固定エクスポーター・未信頼Envelopeの検査・accepted生成・停止 | 4 |
| `Replay.psm1`、`replay-record.schema.json` | 新規。before/after/recheck入力の生成と差分照合、標準ライブラリ検査、新規VMでの再実行、外側記録、未実行結果 | 5 |
| `Result.psm1`、`result.schema.json` | 変更。v1保持、v3の3入力照合、失敗結果、観測分類、CreateNew保存 | 6 |
| `Invoke-IsolatedVerification.ps1`、`README.md`、`tests/Run-IndependentTests.ps1` | 新規・変更。JSON入力、4責務の結合、pilot排他、deadline監督、終了コード、診断表示 | 7 |
| `tests/*V3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`、`tests/fixtures/ProcessFixtureV3.ps1`、`tests/fixtures/pilot-source/` | 新規。VMなしの契約・偽造・停止試験。偽sbxは記録済み応答を返す固定スクリプト | 1〜7 |
| `tests/Invoke-SbxPilotProbe.ps1` | 新規。個別承認後に実VMで再実行・停止・transport対照を取る | 8 |
| `docs/records/experiments/`（実VM・実モデルの記録） | 新規。タスク8・9の証拠 | 8・9 |

**偽sbx**: `fake-sbx.cmd` は同ディレクトリの `FakeSbx.ps1` を、複製時に埋め込んだ pwsh の絶対パス（`(Get-Command pwsh).Source` を試験側が書き込む）で `-NoProfile` 起動する。PATH に依存しない（SbxRuntime が渡す環境辞書の PATH は sbx の親ディレクトリだけのため）。`FakeSbx.ps1` は同ディレクトリの `scenario.json` の配列から「argv 要素に対する正規表現パターン列の全一致」で応答（stdout/stderr/exitCode/遅延秒）を選び、呼び出しを `calls.jsonl` へ追記する。before/after は VM 名の役割接尾辞（下記）で区別する。未定義の argv は終了3で `unexpected sbx call` を返す。試験ケースごとに偽sbx一式をケース領域へ複製して `settings.sbxPath` に指定する。任意 scriptblock や接続先をプロダクトの CLI へ公開しない。

**偽sbxの応答の出所**: 正常応答（`daemon status --json`、`ls --json`、`create`、`cp`、`exec` の 0/137、`stop`、`inspect --json`、`policy ls --json`、`policy log --json`、`settings get --json`）は `.tmp/sbx-capability-20260914/` の実測出力に合わせる。エラー応答（create の 500、exec の 127、デーモン停止時の接続失敗、切断）は実測が無いため「創作した応答」として `scenario.json` に `synthetic: true` を付け、タスク8の実機対照で形式を確認して差し替える。Envelope（提案の書式）は本仕様の契約であり、この規則の対象外。

**VM名の規則**: `iv-<runIdの先頭8桁>-<role>`（role は `proposal`/`before`/`after`。例 `iv-0baac92d-before`）。runId は UUID なので run ごとに一意で、残置VMと衝突しない。同名が `ls --json` にあれば当該 run を blocked にする（衝突は UUID 衝突か同一 run の再実行を意味する）。

## タスク1: v1互換を保ってv3の依頼・設定・固定入力を検査し、基準版と提案用コピーを準備する

**依存:** なし。**対象:** `RequestCopy.psm1`、`request.schema.json`（v1/v3を `if/then` で分岐）、新規 `settings.schema.json`、`pilot-input.schema.json`、`tests/RequestCopyV3.Tests.ps1`。

**インターフェース:** `New-VerificationRun([hashtable]$Request,[hashtable]$Settings,[string]$StartedAt)` は schemaVersion で分岐し、1は既存本体を抽出した `New-LegacyVerificationRun`（`$StartedAt` を無視）、3は `New-ProposalReplayRun` を呼ぶ（戻り値 PreparedRunV3、失敗は例外 `Data['status']`/`['stage']`/`['runRoot']`）。公開追加: `ConvertTo-VerificationCanonicalJson($Object) -> string`（キー辞書順・UTF-8・空白なし）、`Get-VerificationCanonicalHash($Object) -> string`（SHA256大文字16進）、`Write-VerificationNewFile([string]$Path,[string]$Content)`（CreateNew・BOMなし）、`Get-VerificationUtcNow() -> string`（ISO8601 UTC）、`Test-VerificationJsonDuplicateKeys([string]$Json) -> bool`（生JSONの重複キー検出。CLIが入力ファイルに適用し、本モジュールの試験は生JSON文字列で行う）。

- [ ] 既存 `New-VerificationRun` 本体を `New-LegacyVerificationRun` へ抽出し、公開関数は分岐だけにする（第3引数は省略可）。既存4試験群を実行して成功数が変わらないことを確認する（`Run-IndependentTests.ps1` が「4 suites passed」）。
- [ ] `settings.schema.json`（必須: schemaVersion=3、sbxPath、pwshPath、runsRoot、model、proposalProfilePath、replayProfilePath、pilotInputPath、limits。`additionalProperties:false`。recheck時のみ model/proposalProfilePath に null 可）と `pilot-input.schema.json`（schemaVersion=3、inputId、scope=synthetic-pilot、sourceRoot、sourceManifestHash、approvalReference）を書く。`request.schema.json` は `schemaVersion` が1なら既存定義、3なら v3 定義（caller、sourceRoot、objective、acceptanceCriteria、extraInputPaths、任意 recheck{previousResultPath,testPaths}）を適用する。
- [ ] v3検査を実装する。未知キー、数字の文字列表現、旧 `pids` キー、`cpus`≠2 / `memoryMiB`≠2048、`proposalSeconds`/`replaySeconds`>`totalSeconds`、相対パス、存在しない実行ファイルを blocked にする。`Test-VerificationJsonDuplicateKeys` は JSON を字句走査して同一オブジェクト内の重複キーを検出する（`ConvertFrom-Json` は重複を黙って上書きするため）。
- [ ] 固定入力記録を照合する。`Request.sourceRoot` の正規化パスと `Get-VerificationSourceManifest` の正規化ハッシュを記録の `sourceRoot`/`sourceManifestHash` と比較し、不一致は blocked（VM未作成）。記録は `control/pilot-input.json` へ複製し、`pilotInputId/Path/Hash` を PreparedRunV3 に保持する。
- [ ] run配置を作る。`runsRoot/<runId>/{baseline,proposal-input,quarantine,accepted,replay-inputs,temp,control/{empty-template,runtime,proposal,replay}}`。既存の `work` は v3 で作らない。`control/request.json`（受理した依頼）と `control/source-manifest.json`（v3 正規化形式）を書き、`sourceManifestPath`・`sourceManifestHash` を保持する。baselineへ実体コピーし、既存 `Initialize-VerificationHistory`（`control/empty-template` と `control/history.bundle` を使う）で独立Gitを作る。baseline全通常ファイル（.git含む）の `control/baseline-manifest.json` を書き、`baselineManifestHash` を保持する。
- [ ] proposal-input を baseline のファイル単位コピーで作り、その `.git` が自分の proposalInputRoot 内を指すこと（`rev-parse --absolute-git-dir`）を検査する。原本の `.verification-tests`/`.verification-control` 衝突と、原本内 runsRoot を拒否する。
- [ ] recheck を実装する。`previousResultPath` は runsRoot 内で解決し、schemaVersion=3・runId・`execution.replayAllStopped=true`・`artifacts` 掲載・ハッシュ一致を確認して `accepted/tests/<path>` へ通常ファイルとしてコピーし、`control/recheck-manifest.json` と `recheckArtifacts`（kind=test、path、size、sha256、previousRunId）を作る。停止未確認・timed_out の前回結果は拒否する。
- [ ] 準備後に原本を再列挙して files/head/headRef/historyRefs を比較し、変化は `source_changed`。PreparedRunV3 に `startedAt`（引数）、`deadlineAt`（+totalSeconds）、`cleanupDeadlineAt`（deadlineAt + cleanupSeconds）、各 manifest の期待hashを保持する。
- [ ] `tests/RequestCopyV3.Tests.ps1` を書く。正常（新規・recheck）、未知キー、`"3"`、重複キー（生JSON文字列を `Test-VerificationJsonDuplicateKeys` に通す）、pidsキー、cpus=4、相対sbxPath、固定入力のhash不一致、原本内runsRoot、予約名衝突、コピー中の原本変更（source_changed）、recheckの改変テスト・範囲外パス・停止未確認、baselineとproposal-inputのGitが互いを指さないこと、`control/request.json`・`source-manifest.json`・`baseline-manifest.json` の存在とhash一致を扱う。期待: 全ケース成功、失敗ケースは `Data['status']` が期待値。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/RequestCopyV3.Tests.ps1` と既存 `RequestCopy.Tests.ps1`・`History.Tests.ps1` の成功を確認し、差分を読み直してコミットする。

## タスク2: 対象stdinへの転送・合算出力上限・背景起動を持つプロセス実行を追加する

**依存:** なし。**対象:** `Execution.psm1`、`ProcessHost.ps1`、`tests/ExecutionV3.Tests.ps1`、`tests/fixtures/ProcessFixtureV3.ps1`。

**インターフェース:** `Invoke-VerificationProcessV3([Diagnostics.ProcessStartInfo]$StartInfo,[byte[]]$StdinBytes,[hashtable]$OutputPaths,[hashtable]$RunBudget) -> hashtable`。`OutputPaths` は `stdoutPath`/`stderrPath`（新規絶対パス）。`RunBudget` は `startedAt`/`deadlineAt`/`cleanupDeadlineAt`/`limits`（`maxOutputBytes`、当該コマンドの `commandSeconds`）/`phase`（`work` または `cleanup`）。戻り値は `started`、`exitCode`、`timedOut`、`outputExceeded`、`processTreeStopped`、`stdoutBytes`、`stderrBytes`、`stdoutHash`、`stderrHash`、`finishedAt`、`refusedReason`（未起動時。`deadline-reached` 等）。背景起動: `Start-VerificationBackgroundProcess([Diagnostics.ProcessStartInfo]$StartInfo,[hashtable]$OutputPaths,[hashtable]$RunBudget) -> BackgroundHandle`（`processId`、`jobToken`、`markerPath`、`startedAt`）、`Stop-VerificationBackgroundProcess([hashtable]$Handle,[int]$GraceSeconds) -> hashtable`（`exitCode`、`processTreeStopped`）。既存 `Invoke-VerificationProcess` は変更しない。

- [ ] `ProcessHost.ps1` に制御要求の版を足す。1行目の制御JSON（`version=3`、`stdinBytesLength`）は標準入力の生ストリームから LF まで1バイトずつ読み（StreamReader の先読みで後続バイトを失わないため）、続く `stdinBytesLength` バイトを対象stdinへ転送してEOFを渡す。制御JSONを対象stdinへ混ぜない。版なしの要求は従来どおり。
- [ ] 出力コピーを容量監視つきに変える。stdout/stderr の合計が `maxOutputBytes` を超えた時点で `outputExceeded=true` にし、ジョブを停止する。切詰めて成功にしない。
- [ ] 残時間は `phase=work` なら `min(commandSeconds, deadlineAt-now)`、`phase=cleanup` なら `min(commandSeconds, cleanupDeadlineAt-now)` とする。それぞれの期限到達後は新規起動を拒否する（`started=false`、`refusedReason=deadline-reached`）。停止系コマンドだけが `phase=cleanup` を使う。
- [ ] 背景起動を実装する。`Start-VerificationBackgroundProcess` は同じジョブ機構で対象を起動し、開始マーカー確認後に待たずに戻る（ジョブは module 内の辞書に `jobToken` で保持）。`Stop-VerificationBackgroundProcess` はジョブを停止して `processTreeStopped` を返す。プロセス終了時にジョブが自動解放されるよう `Dispose` の責務を明記する。
- [ ] `ProcessFixtureV3.ps1` に動作を作る: stdinを反響して終了0、stdinを読まずに終了7、無限出力、指定秒 sleep、存在しない実行ファイル（StartInfoで指定）。
- [ ] `tests/ExecutionV3.Tests.ps1` で、反響が一致・終了0、stdin未読でもdeadline/cleanupを超えずに終了7、出力洪水は `outputExceeded=true` かつ `processTreeStopped=true`、時間超過は `timedOut=true`、起動失敗は `started=false`、`phase=work` で deadline 経過後は `refusedReason=deadline-reached` だが `phase=cleanup` は起動できる、背景起動した sleep を `Stop-VerificationBackgroundProcess` で止めて `processTreeStopped=true`、ハッシュがファイル実体と一致することを確認する。
- [ ] 既存 `Execution.Tests.ps1` の成功を保ち、コミットする。

## タスク3: sbx実行基盤を外側の記録で管理する

**依存:** タスク1・2。**対象:** 新規 `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-evidence.schema.json`、`activation-record.schema.json`、`tests/SbxRuntimeV3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`。

**インターフェース（仕様02の公開操作）:** `Test-VerificationRuntimeProfile([hashtable]$Profile,[string]$Role)`、`Acquire-VerificationPilotLease([hashtable]$PreparedRun) -> Lease`、`Release-VerificationPilotLease([hashtable]$Lease)`、`New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile,[hashtable]$Lease) -> SandboxHandle`、`Copy-VerificationSandboxInput($Handle,[string]$TrustedInputRoot,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Confirm-VerificationSandboxInput($Handle,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Invoke-VerificationSandboxCommand($Handle,[string[]]$Argv,[byte[]]$StdinBytes,[string]$WorkingDirectory,[hashtable]$Environment,[hashtable]$RunBudget) -> CommandRecord`、`Stop-VerificationSandbox($Handle,[int]$CleanupSeconds) -> hashtable`、`Stop-VerificationRecordedSandboxes([string]$RunRoot,[hashtable]$Settings) -> hashtable`（ADR-0194。control/runtime の記録済みIDだけを名指しで停止し、結果を `control/runtime/recovery-<時刻>.json` に残す復旧操作）。Roleは proposal/replay-before/replay-after。SandboxHandleは runId、role、name、id、createdAt、profileHash、effectiveSettingsHash、activationRecordPath、activationRecordHash、keepAliveHandle。

- [ ] 偽sbxを「ファイルと責務」の記述どおりに作る。用意する応答: `daemon status --json` の stopped/running、`ls --json`、`create` の成功と500（synthetic）、`cp`、`exec`（0・7・127〈synthetic〉・137）、`stop`、`inspect --json`、`policy ls <name> --json`、`policy log <name> --json`、`settings get --json clipboard.imagePaste`、`mcp ls --json`。
- [ ] `runtime-profile.schema.json`（schemaVersion=3、role、sbxVersion、templateDigest、agent、startupArgv、executableInVm、policyExpectation、mountExpectation、scope=synthetic-pilot、acceptedLimitations、activationEvidencePath、activationEvidenceHash。`additionalProperties:false`）と `activation-evidence.schema.json`（checkedAt、binaries、profileHash、checks{条件名: {verdict, evidencePath, evidenceHash}}、transportContrast{exit0, exit7, exit127, timeout, disconnect の各観測}）を書く。`Test-VerificationRuntimeProfile` は profile の schema、role整合（proposal→agent=codex、replay→agent=shell）、digest固定、evidence ファイルの hash 一致、evidence の schema と `profileHash` の一致、全 checks の verdict=verified、`transportContrast` の全項目の存在を検査し、`profileHash`（evidence 2項目を除いた正規化JSONのSHA256）を返す。
- [ ] `effectiveSettingsHash` を定義する: `{role, agent, templateDigest, cpus, memoryMiB, denyNetwork:"*", shareSkills:false, workspace:"none", limits}` の正規化JSONのSHA256。作成時に SbxRuntime が計算して activationRecord と SandboxHandle に載せ、Replay の記録と Result の照合はこの値を使う。
- [ ] デーモン確認と世代取得を実装する。`daemon status --json` が running でなければ blocked（利用者の通常起動が必要と理由に書く）。`logs` から状態ディレクトリを導き、`sandboxd.pid`・`daemon.log` の最後の `starting sandboxd` 行・`Get-Process -Id` の StartTime を `daemonInstance`（pid、startedAt、version、socket）として保持する。取得不能は blocked。
- [ ] pilot排他を実装する。`Local\iv-sbx-pilot-<ユーザー名とsocketのSHA256先頭16>` の名前付きMutex（同一ログオンセッション内の排他。`Global\` は権限が要るため使わない）を取得し、`Lease{runId,daemonKey,leaseId}` を返す。取得競合は待たずに blocked（create 0回）。放棄されたMutexを取得した場合も一覧確認を省略しない。
- [ ] `New-VerificationSandbox` を実装する。順序: (1) Lease の有効性検査（`Lease.runId` が `PreparedRun.runId` と一致し、Mutex を保持中）、(2) VM作成前の再照合（`PreparedRun.pilotInputHash` と `control/pilot-input.json` 現物、記録の sourceRoot/sourceManifestHash と PreparedRun、`Settings.limits.cpus`=2・`memoryMiB`=2048）、(3) 排他内で `ls --json` を読み、running/starting/停止未確認のVMがあれば作らず blocked、同名があれば blocked、(4) 固定argv `create shell --name <name> --cpus 2 --memory 2g --no-share-skills --deny-network '*' --template <digest>`（proposal は agent=codex）。sbx CLIの環境は `SystemRoot`、`PATH`（sbxの親ディレクトリのみ）、`USERPROFILE`、`LOCALAPPDATA`、`APPDATA`、`TEMP` の明示辞書で、`SSH_AUTH_SOCK` を含めない。create 応答と `ls --json` から id を確定し、`control/runtime/<role>-sandbox.json` へ保存してから activation を作る。
- [ ] activationRecord を作る（runId、sandboxId、role、daemonInstance、profileHash、effectiveSettingsHash、checkedAt、checks{policy, mount, resource, credentialExposure, sshForwarding, clipboardImagePaste, mcpServers}）。実効値の取得元: `inspect --json`（state・image_digest・network_policy・secrets・mcp_gateway）、`policy ls <name> --json`（deny `*` の存在）、状態ディレクトリの `runtimes/<name>.json`（CPUs=2、Memory=2g、ShareSkills=false、WorkspaceDir=""、SSHAgentSocketPath=""）、`daemon.log` の当該runtime行に `started SSH agent forwarder` が無いこと、`settings get --json clipboard.imagePaste` が false、`mcp ls --json` の登録サーバー0件（ADR-0195。`mcp_gateway` と `mcpgateway` secret は製品挙動として記録し、`credentialExposure` は inspect の secrets 欄とVM内環境変数で利用者の資格情報の有無を判定する）。1つでも取れなければ作成済みIDを保持して停止を試み、`runtimeFailure{creationState=created,stopState}` を例外に載せる。
- [ ] セッション保持を実装する。作成確認後、`exec <name> sh -c 'sleep <cleanupDeadlineAt までの秒数>'` を `Start-VerificationBackgroundProcess` で起動して `keepAliveHandle` に保持し、`Stop-VerificationSandbox` の冒頭で `Stop-VerificationBackgroundProcess` する。保持プロセスの終了を VM 停止の証拠にしない。
- [ ] `Copy-`/`Confirm-` を実装する。cp は `cp <src> <name>:<Destination>` を1回、続けて `exec -u root <name> chown -R agent:agent <Destination>`。Confirm は `exec <name> sh -c 'cd <Destination> && find . -type f -print0 | sort -z | xargs -0 sha256sum'` の出力を外側の ExpectedManifest（path・size・sha256）と照合し、相違・欠落・予定外ファイルは blocked。
- [ ] `Invoke-VerificationSandboxCommand` を実装する。直前に `daemonInstance`（PID・StartTime）と `ls --json` の同一ID/running を再確認し、さらに `daemon.log` の当該runtime行に create 以後の `auto-stopped runtime` が無いことを確認する。変化・自動停止の痕跡があれば実行せず失敗（理由 `sandbox-restarted`）。argv は `exec -w <WorkingDirectory> [-e K=V...] <name> <argv...>` に固定し、stdin は `Invoke-VerificationProcessV3`（`phase=work`）で転送する。CommandRecord に commandId、startedAt/finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、transportVerified を持たせる。`transportVerified` の定義: profile の `transportContrast` が揃っており（`Test-VerificationRuntimeProfile` で確認済み）、かつ sbx クライアントの開始マーカーがあり、かつ stderr が evidence に記録された transport 失敗の型（デーモン未接続・`no sandbox named`・切断）のいずれにも一致しない場合に true。これは「exitCode を VM 内コマンドの終了値として読んでよい」という意味で、コマンド単位のマーカーは要求しない。
- [ ] `Stop-VerificationSandbox` を実装する。`phase=cleanup` で、保持セッションを止め、`stop <name>` を1回、cleanupSeconds 内に `ls --json` で同一IDの stopped を確認する。証拠は stop 発行時刻以後の `daemon.log` 当該runtime行の `stopped runtime container`（自動停止の `auto-stopped runtime after last session disconnected` は外側停止の証拠にしない）と、世代不変。未確認は `stopState=unverified`。他VMには触れない（`calls.jsonl` で当該名以外への stop が0件であることを試験する）。
- [ ] `Stop-VerificationRecordedSandboxes` を実装する（ADR-0194）。`control/runtime/*-sandbox.json` の id/name だけを対象に、`ls --json` で running なら `stop` を発行して確認する。記録に無いVMには触れない。
- [ ] `tests/SbxRuntimeV3.Tests.ps1` で、デーモン停止時 blocked、running/同名ありで create 0回、Lease 不一致で create 0回、VM作成前の固定入力不一致で create 0回、create 500 で not-created、id確定後の inspect 失敗で停止試行と `runtimeFailure.creationState=created`、Mutex競合で blocked、clipboard.imagePaste=true で blocked、mcp 登録サーバー1件で blocked、Confirm の欠落・予定外ファイル、exec 前の世代変化・自動停止痕跡で実行拒否、出力超過での停止、stop 未確認で unverified、自動停止行だけでは stopped と判定しない、`calls.jsonl` に `SSH_AUTH_SOCK` が無く当該名以外への stop が無いこと、記録済みID復旧停止が記録外のVMに触れないことを確認する。すべて偽sbxで、実VMは作らない。
- [ ] 試験成功後にコミットする。偽sbxの成功を実機の保護実証に数えない。

## タスク4: 提案VMの起動・回収・未信頼Envelopeの検査を実装する

**依存:** タスク1・3。**対象:** 新規 `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py`、`tests/ProposalV3.Tests.ps1`。

**インターフェース:** `Invoke-VerificationProposal([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Lease) -> ProposalResultV3`（schemaVersion、runId、status、origin、sandbox、summary、findings、artifacts、manifestPath、manifestHash、testsManifestHash、stopState、failure）。内部: `Test-VerificationProposalEnvelope([byte[]]$Wire,[hashtable]$PreparedRun) -> hashtable`（検査済み一覧）、`Write-VerificationAcceptedFiles`。

- [ ] recheck 経路を先に実装する。`recheckArtifacts` が非空なら VM・モデルを起動せず、`origin=reused-tests`、`sandbox=null`、`stopState=not-created`、`artifacts` は前回hashのまま、`manifestPath` は `control/proposal/manifest.json` を新規作成して返す。
- [ ] `proposal-export.py` を書く。VM内で `/home/agent/workspace/proposal/` 配下の `tests/test_*.py`・`tests/__init__.py`・`replacements/**/*.py` と `proposal.json`（summary、findings）を読み、`{"schemaVersion":3,"runId":...,"summary":...,"findings":[...],"files":[{"kind","path","contentBase64"}]}` を stdout へ1行で出す。自身は標準ライブラリだけを使い、上限を超えるファイルは含めずに `truncated` を立てる（外側はそれを拒否理由にする）。
- [ ] 提案経路を実装する。`New-VerificationSandbox proposal` → `Copy-`/`Confirm-`（proposal-input を `/home/agent/workspace/source` へ）→ 依頼文（目的・合格条件・作業先 `/home/agent/workspace/proposal`・書式・禁止事項・残り時間〈proposalSeconds と全体期限から算出した秒数。助言であり強制は外側の上限で行う〉）を `startupArgv` の Codex へ stdin で渡す `Invoke-VerificationSandboxCommand`（proposalSeconds）→ `proposal-export.py` を cp して `python3` で実行（stdout 上限 maxWireBytes）→ 停止。子の実行イベントと最終応答は `quarantine/` に未信頼データとして保存する。
- [ ] `Test-VerificationProposalEnvelope` を実装する。wire容量→重複キー・深さ・未知キー・型→runId→件数（maxProposalFiles）→path規則（UTF-8 POSIX相対、絶対・ドライブ・UNC・空成分・`.`・`..`・バックスラッシュ・コロン・NUL・末尾空白/ドット・Windows予約名、大小文字無視の重複、親子衝突、`.git`/`.codex`/`.claude`/`.agents`/`.mcp.json` 配下）→kind（test は `tests/` 接頭辞なしの相対名で `test_*.py`/`__init__.py`、replacement は baseline に存在する `.py` 通常ファイル）→base64正規性→復号後サイズ（maxFileBytes・maxProposalBytes）→UTF-8テキスト、の順に検査し、最初の違反で全体を拒否する。test 0件は拒否、replacement 0件は再現のみとして許す。
- [ ] `accepted/tests/<path>`・`accepted/replacements/<path>` を CreateNew で生成し、祖先にリンク・再解析ポイント・既存ファイルがあれば拒否する。外側でサイズ・SHA256を計算して `control/proposal/manifest.json` に保存し、`manifestHash` を返す。`testsManifestHash`（testの相対パス・サイズ・SHA256をパス順に正規化したSHA256）も保存する。
- [ ] 停止確認後に `status=ready`。停止未確認は受信済みでも `incomplete`（`stopState=unverified`）。時間超過は `timed_out`。`runtimeFailure` は捕捉して `sandbox` に確定済みhandleを残す。
- [ ] `tests/ProposalV3.Tests.ps1` で、recheck が VM 0回、正常Envelope が ready、架空runId、リンク相当パス、`..`、予約名、大小文字重複、過大wire、復号後超過、途中切断（不完全JSON）、test 0件、replacement が baseline に無い、非.py、停止未確認 → incomplete、`quarantine` 保存を確認する。実Codex・実VMは起動しない。
- [ ] コミットする。

## タスク5: 通信なしVMでの修正前後の再実行と外側記録を実装する

**依存:** タスク1・3・4。**対象:** 新規 `Replay.psm1`、`replay-record.schema.json`、`tests/ReplayV3.Tests.ps1`、`tests/fixtures/pilot-source/`（`calc.py` に既知の欠陥、`test_calc.py` が before で非0・after で0 になる合成題材と、その `replacement` 版）。

**インターフェース:** `Invoke-VerificationReplay([hashtable]$PreparedRun,[hashtable]$ProposalResult,[hashtable]$Profile,[hashtable]$Lease) -> ReplayResultV3`（schemaVersion、runId、status、mode、sandboxes、before、after、allStopped、failure）、`New-VerificationReplayNotRun([hashtable]$PreparedRun,[hashtable]$Failure) -> ReplayResultV3`。

- [ ] 合成題材を確認する。ホストに Python 3 があれば `pilot-source` で before（原文）が非0、after（replacement 適用）が 0 になることを1回実行して記録する（無ければ未確認と記し、タスク8で確認する）。ホストでの実行は固定の題材に限り、回収物には適用しない。
- [ ] 入力検査を実装する。`ProposalResult.status=ready`、runId一致、`manifestHash` と `accepted` 現物の再照合、origin ごとの sandbox/stopState 条件、baseline の全ファイル manifest と期待hash の照合。不成立は blocked。
- [ ] `replay-inputs/before` と `after` を外側で作る。before は baseline の作業ファイル（`.git` を除く）、after は同じファイルへ検査済み replacement を適用したもの。生成後に before と after の全ファイル差分を取り、差分のパス集合が replacement 一覧と完全一致することを確認する（不一致は incomplete）。両方の `.verification-tests/` に同じ tests を置き、各入力の manifest（path・size・sha256）と `testsManifestHash` を保存する。mode は replacement なしで `reproduction-only`、ありで `candidate-comparison`、recheck で `recheck`（現在版を after とし before=null）。
- [ ] 標準ライブラリ検査を実装する。accepted の tests と replacements の `import` 対象を静的に列挙し、VM 内で `python3 -c 'import sys; print("\n".join(sorted(sys.stdlib_module_names)))'` の出力（初回に取得し `control/replay/stdlib-modules.txt` へ保存）と照合して、標準ライブラリ外・題材外のモジュールがあれば blocked。実行中に依存を取得しない。
- [ ] 役割ごとに新規VMを順に使う。`New-VerificationSandbox replay-before` → Copy/Confirm（`/home/agent/workspace/source`）→ 固定argv `["python3","-m","unittest","discover","-s",".verification-tests","-p","test_*.py","-v"]` を `WorkingDirectory=/home/agent/workspace/source`、Environment は profile の最小辞書で実行（replaySeconds）→ 停止確認 → after を同様に。before の停止未確認なら after を作らず返す。
- [ ] 各コマンドを `control/replay/<role>/<commandId>.json` へ `replay-record.schema.json` どおり保存する（runId、role、sandboxId、profileHash、effectiveSettingsHash、templateDigest、sourceManifestHash、inputManifestHash、testsManifestHash、argv、workingDirectory、startedAt、finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、stopVerified、transportVerified、activationRecordPath/Hash、limits）。
- [ ] `New-VerificationReplayNotRun` を実装する（status=not_run、sandboxes=[]、before/after/allStopped=null、failure に上流段階）。作成成否不明は not_run へ丸めず `failure.reason=creation-unresolved` で incomplete。
- [ ] `tests/ReplayV3.Tests.ps1` で、偽sbx が before（VM名 `-before`）に終了1・after（`-after`）に終了0 を返すケースで `completed`（合否は付けない）、before 0 の非再現、after 非0、テスト集合が before/after で異なる入力の拒否、after の差分が replacement 一覧と一致しない入力の拒否、標準ライブラリ外 import の blocked、別 digest の profile 拒否、before 停止未確認で after 未作成かつ incomplete、偽成功文字列（stdout に "OK" だが終了1）が終了コードを覆さないこと、出力洪水で incomplete、時間超過で timed_out かつ停止コマンドが `phase=cleanup` で発行されること、`not_run` の書式、各役割の sandbox id が相異なること、当該名以外への stop が0件であることを確認する。
- [ ] コミットする。

## タスク6: 3入力を外側の記録で照合し結果を返す

**依存:** タスク1・4・5。**対象:** `Result.psm1`、`result.schema.json`（v1/v3を `if/then` で分岐）、`tests/ResultV3.Tests.ps1`。

**インターフェース:** `Complete-VerificationRun` は2引数で既存 `Complete-LegacyVerificationRun`、3引数（PreparedRunV3、ProposalResultV3、ReplayResultV3）で v3 照合。`New-VerificationFailureResult([hashtable]$RequestContext,[hashtable]$Failure) -> VerificationResultV3`。

- [ ] `result.schema.json` に v3 定義（schemaVersion、runId、status、summary、sourceState、baselineState、proposalVerdict、replayVerdict、checks、findings、artifacts、unverified、execution、previousRunId、runRoot、sourceManifestPath、scope、limitations。`additionalProperties:false`）を足し、v1 定義は保つ。
- [ ] 照合手順1〜7（仕様03）を実装する。順序は schemaVersion/runId → activationRecord と profileHash/effectiveSettingsHash/sandboxId/daemonInstance → manifest 期待hash と現物（source・baseline・recheck・proposal） → 原本再列挙 → accepted・replay input・testsManifestHash → before/after の差分が replacement 一覧に限られること → 外側記録（runId/role/VM id/argv/時刻/hash/transportVerified/停止）→ 停止記録の必須化 → 観測分類。証拠パスは control 内だけを許す。
- [ ] status の優先順位（timed_out → incomplete〈作成不明・作成済みの停止未確認・基準版改変〉→ blocked → source_changed → incomplete〈その他〉→ completed）と、Proposal/Replay の status 写像、`not_run` の上流追従を実装する。scope 付与前に pilotInputHash と記録現物、sourceRoot/sourceManifestHash を再照合する。
- [ ] `replayVerdict` の観測分類（candidate-supported / not-reproduced / still-failing / reproduced / current-pass / current-fail / undetermined）と、completed 時の CLI終了値（0/1）を `execution.exitCodeForCli` として返す。
- [ ] `New-VerificationFailureResult` を実装する（runId/runRoot/sourceManifestPath/previousRunId=null、sourceState/baselineState=unreadable、proposalVerdict=null、replayVerdict=undetermined、空配列、execution は proposalCreated=false・replayCreatedCount=0・停止値null・失敗段階、判明済みVM情報があれば保持）。
- [ ] `control/result.json` を CreateNew で一度だけ保存し、既存があれば例外にして保全する。
- [ ] `tests/ResultV3.Tests.ps1` で、正常（candidate-supported、終了0）、still-failing（終了1）、reproduction-only、recheck の current-pass/current-fail、架空 commandId、別 sandboxId/世代/effectiveSettingsHash、自己申告 pass だけの入力、基準Git改変（incomplete）、原本更新（source_changed）、出力欠落、同一テストでない比較、after の差分が replacement 一覧を超える入力、停止未確認（incomplete かつ blocked より優先）、not_run 追従、失敗結果の null 書式、既存 result.json 保全、schema 適合を確認する。
- [ ] 既存 `Result.Tests.ps1` の成功を保ち、コミットする。

## タスク7: 共通CLIで4責務を結合し、既存試験群へ組み込む

**依存:** タスク1〜6。**対象:** 新規 `Invoke-IsolatedVerification.ps1`、`tests/CliV3.Tests.ps1`、変更 `README.md`、`tests/Run-IndependentTests.ps1`。

**インターフェース:** `pwsh -NoProfile -File scripts/verification/Invoke-IsolatedVerification.ps1 -RequestPath <json> -SettingsPath <json>`。stdout に VerificationResultV3 の JSON 1件、stderr に診断。終了値は completed なら判定（0/1）、それ以外 2。復旧用の別入口 `-StopRecorded -RunRoot <path> -SettingsPath <json>` を持つ（ADR-0194。VMを作らず、記録済みIDだけを停止して結果を stdout に返す）。CLIは開始直後に runRoot を stderr へ表示し、結果JSONが返らなくても復旧操作に必要なパスが分かるようにする。

- [ ] 入力読込（`Test-VerificationJsonDuplicateKeys` で重複キー検査）→ `startedAt` 確定 → `New-VerificationRun`（失敗は `New-VerificationFailureResult`）→ `Test-VerificationRuntimeProfile`（replay は常に、proposal は非recheck時）→ `Acquire-VerificationPilotLease` → `Invoke-VerificationProposal` → ready なら `Invoke-VerificationReplay`、非ready なら `New-VerificationReplayNotRun` → `Complete-VerificationRun` → `finally` で作成済みVMの停止確認（未停止があれば `Stop-VerificationSandbox` を `phase=cleanup` で再試行）と `Release-VerificationPilotLease`。準備後の例外は判明済みVM情報を RequestContext に足して失敗結果へ。
- [ ] 開始時に scope と acceptedLimitations（clipboard文字列書込の可能性・プロセス数上限なし）を stderr に表示する。clipboard の読取・退避・復元・消去はしない。
- [ ] 全体 deadline を単調時計で監督し、到達後は新規VM作成・搬入・execを行わず停止処理だけ `cleanupDeadlineAt` まで許す。
- [ ] `tests/CliV3.Tests.ps1` で、偽sbx と `tests/fixtures/pilot-source` を使い、正常往復（stdout JSON 1件・終了0）、still-failing（終了1）、固定入力不一致（blocked・終了2）、デーモン停止（blocked・理由に通常起動）、Lease競合（blocked）、提案非ready→replay not_run、途中失敗時の Lease 解放と作成済みVMの停止発行、deadline 到達後に stop だけが発行されること、`-StopRecorded` が記録済みIDだけを停止し記録外のVMに触れないこと、開始直後の stderr に runRoot が出ることを確認する。
- [ ] `Run-IndependentTests.ps1` に v3 の7群（RequestCopyV3、ExecutionV3、SbxRuntimeV3、ProposalV3、ReplayV3、ResultV3、CliV3）を足し、出力を「11 suites passed」にする。README に v3 の使い方、前提（利用者起動のデーモン）、既知の制約（自動停止・clipboard例外・pilot限定・残置VMの後片付けは利用者承認の `sbx rm`）を書く。
- [ ] 11群成功を確認してコミットする。

## タスク8: AIなしで実VMの再実行・停止・記録を実証する（個別承認）

**依存:** タスク7。**対象:** 新規 `tests/Invoke-SbxPilotProbe.ps1`、replay 用 profile と activationEvidence（`control` 外の固定ファイル、`docs/records/experiments/2026-09-14-v3-capability-test-methods.md` の証拠を参照）、実験記録。

- [ ] 提示する: VM名（規則どおり `iv-<runId8>-before/after`）、固定argv、搬入する `pilot-source` の内容とhash、実行コマンド、停止手順、transport 対照（終了0・固定7・存在しないコマンド127・時間超過・切断〈CLI プロセスの強制終了〉）、取得する証拠、所要見込み。デーモン停止中なら利用者の通常起動を先に依頼する。承認後にだけ進む。
- [ ] `Invoke-SbxPilotProbe.ps1` で `Invoke-VerificationReplay` を実sbxに対して1回動かし、before 非0・after 0、各役割の新規 id、停止確認、他VM（試験VM2台）の状態不変、transport 対照の各観測を取る。対照の観測結果（stderr の型・終了コード）を `activation-evidence.json` の `transportContrast` に保存し、偽sbxの synthetic 応答を実測形式へ差し替える。
- [ ] 連続保持の確認（ADR-0193）: VM 1台を保持用 exec で約30分（totalSeconds に相当）保ち、その間に数回 `ls --json` で running を読み、終了後に daemon.log の当該runtime行に自動停止・切断の記録が無いことを確認する。切れた場合は保持方式の見直しへ戻す。
- [ ] 実験記録へ結果と限界（1回の成立、負荷なし）を書き、replay profile の activationEvidence を固定版・固定設定の能力試験記録として保存する。コミットする。

逸脱記録は実施後に残す。

## タスク9: 最小モデル往復（個別承認、認証方式の実測が前提）

**依存:** タスク8。**対象:** proposal 用 profile、`docs/records/experiments/`。

- [ ] sbx の資格情報の渡し方（プロキシによるヘッダー注入、`sbx secret`）を読み取りで調べ、raw の認証値を VM に渡さない構成が成立するかを提示する。成立しなければ blocked のまま相談する。
- [ ] 承認後、`pilot-source` で Claude Code・Codex 双方の主担当から1往復（依頼→提案→再実行→結果→主担当の修正→recheck）を行い、記録する。送信範囲・最大時間・モデルは承認どおり。
- [ ] 記録をコミットし、サイクル全体整合検査と最終レビューへ進む（ADR-0162・0192 と (d)・(e) の ADR の昇格を含む）。

## 完了基準と検証期待値の対応

| 仕様 | 所有タスク | 正常対照と失敗対照 |
|---|---|---|
| V1 | 1 | v3の baseline・proposal-input・履歴コピー・control記録／未知キー・リンク・範囲外・recheck改変・予約名衝突・原本内runsRoot |
| V2 | 3・8・9 | activationRecord の実効値一致（policy・mount・resource・sshForwarding・clipboardImagePaste・mcpServers）／デーモン停止・同名・500・inspect失敗・SSH forwarder 行の存在・`SSH_AUTH_SOCK` の混入・画像読取true・MCP登録あり |
| V3 | 4 | 正常Envelope が accepted へ／パス逸脱・重複・予約名・過大・切断・test 0件・baseline に無い replacement |
| V4 | 5・8 | before 非0/after 0 を別VM・通信なしで記録／非再現・after 非0・テスト差・replacement外の差分・別digest・標準ライブラリ外 |
| V5 | 2・3・5・7・8 | 出力超過・時間超過・停止確認・deadline後の停止許可・CLI異常時の停止経路（ADR-0194）・対象外VMの継続／停止未確認・世代変化・自動停止痕跡・偽成功文字列・当該名以外への stop |
| V6 | 1・6 | manifest 期待hash と現物の一致／原本更新・baseline改変・証拠欠落・別runId・別effectiveSettingsHash・自己申告pass |
| V7 | 7・9 | 両主担当からの往復（実モデルは9）／caller 文字列だけでは未実証 |

計画検証では、この表と各タスクの編集内容・試験内容を照合する。ランナーの期待値は既存4群＋新規7群＝11群。タスク8・9の実機試験は群数に含めない。

## 確定前の確認状況

仕様は静的フル1回＋差分2回、試作条件は差分2回で確定済み。本計画はその写像で通常型。

2026-09-14 の初回確定前レビュー（1体4観点兼務、claude-opus-5、フル実施）: 走査対象はタスク9・チェック項目63・仕様31節。指摘は Critical 2・Major 9・Minor 6。採否は次のとおり（すべて採用。保護条件に関わる3件は2026-09-15にユーザーが確定し、ADR-0193〜0195に記録）。

- C1（deadline 到達後に停止処理も起動拒否される）: 採用。`cleanupDeadlineAt` と `phase=cleanup` を RunBudget の契約に足し、停止系だけが使う。
- C2（セッション保持 exec の起動手段が無い）: 採用。タスク2に背景起動の公開操作を足し、タスク3が使う。(d) は設計の変更として ADR-0193 で確定（2026-09-15）。
- M2（transportVerified の定義がコマンド単位で成立しない）: 採用。profile の `transportContrast` と stderr の失敗型による定義へ改め、タスク8で対照を取る。
- M3（起動前確認の4件が未割当）: 採用。VM作成前の再照合・Lease検査・clipboard 画像読取・MCP登録0件をタスク3に足した。MCP の解釈は ADR-0195 で確定（2026-09-15）。
- M4（V5 の切断時停止・対象外VM継続の欠落）: 採用。復旧操作と実機確認を ADR-0194 で確定（2026-09-15）。対象外VMの継続は偽sbxの `calls.jsonl` とタスク8の他VM状態で確認する。
- M5（VM名の規則が無い）: 採用。`iv-<runId8>-<role>` に固定し、偽sbxは役割接尾辞で応答を分ける。
- M6（最小環境辞書で偽sbxが起動できない）: 採用。偽sbxは pwsh の絶対パスを埋め込み PATH に依存しない。
- M7（未観測の応答形式を創作しない規則と偽sbxの矛盾）: 採用。正常応答は実測、エラー応答は synthetic と明示してタスク8で差し替える。
- M8（自動停止と外側停止の区別が無い）: 採用。stop 発行時刻以後の `stopped runtime container` だけを証拠にし、run 途中の自動停止は `sandbox-restarted` で失敗にする。
- M9（(d) を実体合わせに分類したのは誤り）: 採用。設計の変更に分類し直し、ADR で確定する。
- M10（`Global\` Mutex は非昇格で作成できない可能性）: 採用。`Local\` にする（同一ログオンセッション内の排他で仕様の要求を満たす）。
- m1（重複キー検査の所有者不在）: 採用。タスク1の公開関数に足し、生JSONで試験する。
- m2（`control/request.json`・`source-manifest.json`・`empty-template` の欠落）: 採用。配置に足した。
- m3（`effectiveSettingsHash` 未定義）: 採用。タスク3で定義し、記録と照合で共用する。
- m4（after の差分が replacement 一覧に限られる照合の欠落）: 採用。タスク5の生成時とタスク6の照合に足した。
- m5（stdin 転送の細部）: 採用。生ストリームの1バイト読みと `stdinBytesLength` に改めた。
- m6（合成題材の事前確認が無い）: 採用。タスク5の冒頭でホスト Python による任意の確認を足した。
- 写像確認で指せなかった項目のうち上記以外: activationEvidence の内部項目の検査（タスク3の `Test-VerificationRuntimeProfile` に足した）、標準ライブラリのみで成立しない題材の blocked（タスク5に足した）。

相談事項3件は2026-09-15に確定した（ADR-0193〜0195）。改訂後の再レビュー（反復）の提示は同日に行う。改訂差分は git（bd3beca との diff）で追える。計画特有の未確認範囲は、セッション保持exec の副作用、`ProcessHost` の stdin 転送、`Local\` Mutex の実動、`inspect --json`・`mcp ls --json` の項目が版で変わる可能性、Codex 起動 argv（タスク9で実測）。
