# 隔離検証 v3（提案と通信なし再実行）実装計画

> **実装担当へ:** `superpowers:subagent-driven-development`（推奨）または `superpowers:executing-plans` でタスク単位に進める。各ステップは `- [ ]` で追跡する。VMを作る操作（タスク8・9）は本計画の作成承認に含まれず、区切りごとの個別承認が必要。

**目的:** Claude CodeまたはCodexの主担当が共通CLI 1本で、独立コピー上のsbx内Codexに再現テストと修正候補を提案させ、別の通信なしVMで採否用の再実行を取り、外側の記録で照合した結果を受け取れるようにする。

**構成:** 準備（01）→提案（02）→再実行（04）→照合（03）の4責務を `scripts/verification/` の既存v1部品の上に足す。v1の公開契約と4試験群は保持し、v3はschemaVersion=3だけを受理する。VMを使う部分は `SbxRuntime.psm1` に閉じ、他ブロックはその公開操作だけを呼ぶ。VMなしで検査できる契約・拒否・停止の試験を先に揃え、実VM・実モデルは個別承認の区切りで行う。

**技術:** Windows 11、PowerShell 7、Git、sbx 0.42.1（利用者が通常端末で起動したデーモン）、固定テンプレート `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`（Python 3・unittest）。新規パッケージ・常駐サービスは追加しない。

**仕様:** `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`、`01-request-and-copy.md`、`02-isolated-execution.md`、`03-result-collection.md`、`04-offline-replay.md`（`5259d22` で確定した試作条件を含む現行版）。

**実測の前提:** `docs/reference/sbx-sandbox-runtime-facts.md`（自動停止30秒・cp/execの自動起動・透過プロキシ・SSH中継の実体・外側記録の所在）と `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（試験A〜D合格）。

## 共通制約と承認の境界

- 作業場所は `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`、ブランチ `codex/isolated-verification`。作成時HEADは `3385d24`。未追跡 `.tmp/`・他worktree・stash・試験VM2台（`iv-sbx-smoke-20260909-01`、`iv-sbx-capability-20260914-01`）を保全し、削除・再作成しない。
- v3は schemaVersion=3 のみ受理。v1公開関数（`New-VerificationRun` 2引数、`Complete-VerificationRun` 2引数、`Invoke-VerificationProcess`）の挙動と既存4試験群（RequestCopy・History・Execution・Result）を保持する。未実装v2は受理しない。
- synthetic-pilot固定: `cpus=2`、`memoryMiB=2048`、同時1VM、`scope=synthetic-pilot`、`acceptedLimitations=["clipboard-text-write-possible","pid-count-unbounded"]`。初期上限は全体1800秒・提案600秒・各再実行120秒・停止猶予30秒・100ファイル・1ファイル1MiB・合計8MiB・転送16MiB・1コマンド出力合計16MiB。pidsキーは未知キーとして拒否する。
- 原本・baseline・control・ホストホーム・資格情報をVMへ渡さない。VMにはproposal-input（提案用）と replay-inputs/before|after（再実行用）だけを `sbx cp` で搬入する。共有skills・workspace・MCPを与えない。
- sbx CLIは常に外側で固定argvを組み立てて起動する。子からホストコマンド・sbxフラグ・接続先を受け取らない。sbx CLIの環境は明示した最小辞書とし、`SSH_AUTH_SOCK` を渡さない。
- デーモンの起動・再起動・reset・設定変更はランナーの責務外。停止中なら「利用者が通常端末で起動する必要がある」と返してblocked。`sbx daemon status --json` だけは停止中でも呼んでよい（自動起動しないことを実測済み）。`ls`・`inspect`・`settings`・`cp`・`exec` は running 確認後だけ呼ぶ。
- VMは最後のセッション切断から30秒で自動停止し、`cp`・`exec` は停止VMを自動起動する。SbxRuntimeはVM作成直後から停止までセッション保持用のexecを1本保つ（下記）。停止確認は `ls --json` の同一ID・stopped と、操作前後のデーモン世代不変で行う。
- 接続成立（TCPハンドシェイク）を到達の証拠にしない。通信・SSHの拒否はプロトコル応答・policy log・daemon.logで判定する（試験Aの方式）。
- モデル自己申告、設定値の受理、sbx CLIの終了だけを保護・実行・停止の証拠にしない。原本へ自動適用しない。回収物をホストでimport・実行しない。
- 失敗領域・停止VMは診断用に残す。VM削除・イメージ変更・導入・公開・masterへの統合は本計画の承認に含めない。

### 判断の分担・逸脱判断の既定

判断の分担はADR-0158の補助設計委任（`00-overview.md`「判断の分担と参照」、承認時点 `b7941f3`）。補助機能の仕様・内部構造・対策方法は委任範囲。保護の追加緩和、新たな必須基盤・利用者作業、認証・利用費・送信範囲、削除・公開は相談する。実機・設定・モデル操作の承認はADR-0162・ADR-0192の範囲に限り、本計画のタスク8・9は個別承認を別に得る。

逸脱判断は `ai-driven-dev-principles` 導入版 **0.1.29** の `skills/start-work/references/plan-deviation-defaults.md` に従う。計画確定時に基準を固定する。委任された局所仕様変更（補助設計）は既定の型分類で扱い、保護条件・外部契約（Request/Settings/Result/ProposalEnvelopeのschema、固定argv）に触れるものは「設計の変更」側へ倒す。動作テストを安全網とする通常の実装計画で、コード全文の書き写し方式ではない。タスク別の仕様適合レビューを置く工程（subagent-driven-development）を既定とし、置かない場合は設計変更で独立レビューへ切り替える。各タスク末尾に必要な `逸脱記録:` を残す。

確定前レビューからの引き継ぎ一覧: 本計画の確定前レビュー実施後、その記録のパスをここへ書く（未実施の間は「なし」）。仕様レビュー（`docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`、`2026-09-10-synthetic-pilot-scope-r2.md`）の不採用指摘を再提案する場合は、実装後の実体で以前の理由が覆る証拠を要する。

本計画が仕様に対して加える実体合わせの調整（設計の変更ではない）: (a) 共通の正規化・ハッシュ・新規作成書込の補助関数を `RequestCopy.psm1` から公開する（新モジュールを増やさない）。(b) 固定入力記録のschemaを `pilot-input.schema.json` として01の所有に置く。(c) デーモン世代の取得元は `daemon status --json` の `logs` パスから状態ディレクトリを導き、PIDファイル・`daemon.log` の起動行・OSプロセスのStartTimeを対応付ける。(d) セッション保持のexecを設ける（自動停止への対処。02「停止中の自動再起動防止」の実現手段）。

### 実行承認を求める具体的な区切り

| 区切り | 提示する対象 | 承認に含めないもの |
|---|---|---|
| タスク8のAIなし実VM試験 | 使うVM名・固定argv・搬入する合成題材（内容とhash）・実行コマンド・停止手順・取得する証拠・所要見込み | モデル起動、認証、既存VMの操作、削除、イメージ変更 |
| タスク9の最小モデル往復 | 認証の渡し方（sbxの資格情報プロキシの実測結果を先に提示）・モデル・送信範囲・最大時間・題材・保存先 | 任意の別リポジトリ、通常導入・公開、clipboard操作 |

重い試験は1件ずつ。利用者の作業が必要なら（デーモン起動）、確定したコマンドと結果保存先を用意し、本文転記は求めない。

## ファイルと責務

特記しない限り `scripts/verification/` からの相対パス。

| ファイル | 操作・責務 | タスク |
|---|---|---|
| `RequestCopy.psm1`、`request.schema.json`、`settings.schema.json`、`pilot-input.schema.json` | 変更・新規。v1保持、v3の検査・固定入力照合・run配置・baseline/proposal-input・recheck。正規化JSON/ハッシュ/新規作成書込の公開 | 1 |
| `Execution.psm1`、`ProcessHost.ps1` | 変更。`Invoke-VerificationProcessV3`（対象stdinへのバイト転送・合算出力上限・RunBudget） | 2 |
| `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-record.schema.json` | 新規。実行設定検査、pilot排他、VM作成・搬入・照合・実行・停止、activationRecord、デーモン世代 | 3 |
| `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py` | 新規。提案VMの起動・依頼・固定エクスポーター・未信頼Envelopeの検査・accepted生成・停止 | 4 |
| `Replay.psm1`、`replay-record.schema.json` | 新規。before/after/recheck入力の生成、新規VMでの再実行、外側記録、未実行結果 | 5 |
| `Result.psm1`、`result.schema.json` | 変更。v1保持、v3の3入力照合、失敗結果、観測分類、CreateNew保存 | 6 |
| `Invoke-IsolatedVerification.ps1`、`README.md`、`tests/Run-IndependentTests.ps1` | 新規・変更。JSON入力、4責務の結合、pilot排他、終了コード、診断表示 | 7 |
| `tests/*V3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`、`tests/fixtures/ProcessFixtureV3.ps1`、`tests/fixtures/pilot-source/` | 新規。VMなしの契約・偽造・停止試験。偽sbxは記録済み応答を返す固定スクリプト | 1〜7 |
| `tests/Invoke-SbxPilotProbe.ps1` | 新規。個別承認後に実VMで再実行と停止を対照する | 8 |
| `docs/records/experiments/`（実VM・実モデルの記録） | 新規。タスク8・9の証拠 | 8・9 |

偽sbx（`fake-sbx.cmd` → `FakeSbx.ps1`）は、同じディレクトリの `scenario.json` から「コマンド列と返す出力・終了コード」を読み、呼ばれたargvと環境を `calls.jsonl` へ追記する。試験ケースごとに偽sbxをケース領域へ複製して `settings.sbxPath` に指定する。任意scriptblockや接続先をプロダクトのCLIへ公開しない。

## タスク1: v1互換を保ってv3の依頼・設定・固定入力を検査し、基準版と提案用コピーを準備する

**依存:** なし。**対象:** `RequestCopy.psm1`、`request.schema.json`（v1/v3を `if/then` で分岐）、新規 `settings.schema.json`、`pilot-input.schema.json`、`tests/RequestCopyV3.Tests.ps1`。

**インターフェース:** `New-VerificationRun([hashtable]$Request,[hashtable]$Settings)` は schemaVersion で分岐し、1は既存本体を抽出した `New-LegacyVerificationRun`、3は `New-ProposalReplayRun` を呼ぶ（戻り値 PreparedRunV3、失敗は例外 `Data['status']`/`['stage']`/`['runRoot']`）。公開追加: `ConvertTo-VerificationCanonicalJson($Object) -> string`（キー辞書順・UTF-8・空白なし）、`Get-VerificationCanonicalHash($Object) -> string`（SHA256大文字16進）、`Write-VerificationNewFile([string]$Path,[string]$Content)`（CreateNew・BOMなし）、`Get-VerificationUtcNow() -> string`（ISO8601 UTC）。

- [ ] 既存 `New-VerificationRun` 本体を `New-LegacyVerificationRun` へ抽出し、公開関数は分岐だけにする。既存4試験群を実行して成功数が変わらないことを確認する（`Run-IndependentTests.ps1` が「4 suites passed」）。
- [ ] `settings.schema.json`（必須: schemaVersion=3、sbxPath、pwshPath、runsRoot、model、proposalProfilePath、replayProfilePath、pilotInputPath、limits。`additionalProperties:false`。recheck時のみ model/proposalProfilePath に null 可）と `pilot-input.schema.json`（schemaVersion=3、inputId、scope=synthetic-pilot、sourceRoot、sourceManifestHash、approvalReference）を書く。`request.schema.json` は `schemaVersion` が1なら既存定義、3なら v3 定義（caller、sourceRoot、objective、acceptanceCriteria、extraInputPaths、任意 recheck{previousResultPath,testPaths}）を適用する。
- [ ] v3検査を実装する。未知キー、数字の文字列表現、重複JSONキー（CLIからの生JSONは `Test-VerificationJsonDuplicateKeys` で検出）、旧 `pids` キー、`cpus`≠2 / `memoryMiB`≠2048、`proposalSeconds`/`replaySeconds`>`totalSeconds`、相対パス、存在しない実行ファイルを blocked にする。
- [ ] 固定入力記録を照合する。`Request.sourceRoot` の正規化パスと `Get-VerificationSourceManifest` の正規化ハッシュを記録の `sourceRoot`/`sourceManifestHash` と比較し、不一致は blocked（VM未作成）。記録は `control/pilot-input.json` へ複製し、`pilotInputId/Path/Hash` を PreparedRunV3 に保持する。
- [ ] run配置を作る。`runsRoot/<runId>/{baseline,proposal-input,quarantine,accepted,replay-inputs,temp,control/{runtime,proposal,replay}}`。既存の `work` は v3 で作らない。baselineへ実体コピーし、既存 `Initialize-VerificationHistory` で独立Gitを作る。baseline全通常ファイル（.git含む）の `baseline-manifest.json` を書き、`baselineManifestHash` を保持する。
- [ ] proposal-input を baseline のファイル単位コピーで作り、その `.git` が自分の proposalInputRoot 内を指すこと（`rev-parse --absolute-git-dir`）を検査する。原本の `.verification-tests`/`.verification-control` 衝突と、原本内 runsRoot を拒否する。
- [ ] recheck を実装する。`previousResultPath` は runsRoot 内で解決し、schemaVersion=3・runId・`execution.replayAllStopped=true`・`artifacts` 掲載・ハッシュ一致を確認して `accepted/tests/<path>` へ通常ファイルとしてコピーし、`recheck-manifest.json` と `recheckArtifacts`（kind=test、path、size、sha256、previousRunId）を作る。停止未確認・timed_out の前回結果は拒否する。
- [ ] 準備後に原本を再列挙して files/head/headRef/historyRefs を比較し、変化は `source_changed`。PreparedRunV3 に `startedAt`（CLI受付時、引数で受け取る）、`deadlineAt`（+totalSeconds）、各 manifest の期待hashを保持する。
- [ ] `tests/RequestCopyV3.Tests.ps1` を書く。正常（新規・recheck）、未知キー、`"3"`、重複キー、pidsキー、cpus=4、相対sbxPath、固定入力のhash不一致、原本内runsRoot、予約名衝突、コピー中の原本変更（source_changed）、recheckの改変テスト・範囲外パス・停止未確認、baselineとproposal-inputのGitが互いを指さないことを扱う。期待: 全ケース成功、失敗ケースは `Data['status']` が期待値。
- [ ] `pwsh -NoProfile -File scripts/verification/tests/RequestCopyV3.Tests.ps1` と既存 `RequestCopy.Tests.ps1`・`History.Tests.ps1` の成功を確認し、差分を読み直してコミットする。

## タスク2: 対象stdinへの転送と合算出力上限を持つプロセス実行を追加する

**依存:** なし。**対象:** `Execution.psm1`、`ProcessHost.ps1`、`tests/ExecutionV3.Tests.ps1`、`tests/fixtures/ProcessFixtureV3.ps1`。

**インターフェース:** `Invoke-VerificationProcessV3([Diagnostics.ProcessStartInfo]$StartInfo,[byte[]]$StdinBytes,[hashtable]$OutputPaths,[hashtable]$RunBudget) -> hashtable`。`OutputPaths` は `stdoutPath`/`stderrPath`（新規絶対パス）。`RunBudget` は `startedAt`/`deadlineAt`/`limits`（`maxOutputBytes`、当該コマンドの `commandSeconds`）。戻り値は `started`、`exitCode`、`timedOut`、`outputExceeded`、`processTreeStopped`、`stdoutBytes`、`stderrBytes`、`stdoutHash`、`stderrHash`、`finishedAt`。既存 `Invoke-VerificationProcess` は変更しない。

- [ ] `ProcessHost.ps1` に制御要求の版を足す。1行目の制御JSONに `version=3`、`stdinBase64Length` を含め、続く標準入力の生バイトを対象stdinへ転送してEOFを渡す。制御JSONを対象stdinへ混ぜない。版なしの要求は従来どおり。
- [ ] 出力コピーを容量監視つきに変える。stdout/stderr の合計が `maxOutputBytes` を超えた時点で `outputExceeded=true` にし、ジョブを停止する。切詰めて成功にしない。
- [ ] 残時間は `min(commandSeconds, deadlineAt-now)` とし、`deadlineAt` 到達後は新規起動を拒否する（`started=false`、理由 `deadline-reached`）。
- [ ] `ProcessFixtureV3.ps1` に動作を作る: stdinを反響して終了0、stdinを読まずに終了7、無限出力、sleep、存在しない実行ファイル（StartInfoで指定）。
- [ ] `tests/ExecutionV3.Tests.ps1` で、反響が一致・終了0、stdin未読でもdeadline/cleanupを超えずに終了7、出力洪水は `outputExceeded=true` かつ `processTreeStopped=true`、時間超過は `timedOut=true`、起動失敗は `started=false`、ハッシュがファイル実体と一致することを確認する。
- [ ] 既存 `Execution.Tests.ps1` の成功を保ち、コミットする。

## タスク3: sbx実行基盤を外側の記録で管理する

**依存:** タスク1・2。**対象:** 新規 `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-record.schema.json`、`tests/SbxRuntimeV3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`。

**インターフェース（仕様02の公開操作）:** `Test-VerificationRuntimeProfile([hashtable]$Profile,[string]$Role)`、`Acquire-VerificationPilotLease([hashtable]$PreparedRun) -> Lease`、`Release-VerificationPilotLease([hashtable]$Lease)`、`New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile) -> SandboxHandle`、`Copy-VerificationSandboxInput($Handle,[string]$TrustedInputRoot,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Confirm-VerificationSandboxInput($Handle,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Invoke-VerificationSandboxCommand($Handle,[string[]]$Argv,[byte[]]$StdinBytes,[string]$WorkingDirectory,[hashtable]$Environment,[hashtable]$RunBudget) -> CommandRecord`、`Stop-VerificationSandbox($Handle,[int]$CleanupSeconds) -> hashtable`。Roleは proposal/replay-before/replay-after。SandboxHandleは runId、role、name、id、createdAt、profileHash、activationRecordPath、activationRecordHash。

- [ ] 偽sbxを作る。`fake-sbx.cmd` は同ディレクトリの `FakeSbx.ps1` を `pwsh -NoProfile` で呼ぶ。`FakeSbx.ps1` は `scenario.json` の配列から「argvの接頭辞一致」で応答（stdout/stderr/exitCode/遅延秒）を選び、呼び出しを `calls.jsonl` へ追記する。未定義のargvは終了3で `unexpected sbx call` を返す。`daemon status --json` の stopped/running、`ls --json`、`create` の成功と500エラー、`cp`、`exec`（終了0・7・137・存在しないコマンド127）、`stop`、`inspect --json`、`policy ls --json`、`policy log --json` を用意する。
- [ ] `runtime-profile.schema.json` を書く（schemaVersion=3、role、sbxVersion、templateDigest、agent、startupArgv、executableInVm、policyExpectation、mountExpectation、scope=synthetic-pilot、acceptedLimitations、activationEvidencePath、activationEvidenceHash。`additionalProperties:false`）。`Test-VerificationRuntimeProfile` は schema、role整合（proposal→agent=codex、replay→agent=shell）、digest固定、evidenceファイルのhash一致、`profileHash`（evidence 2項目を除いた正規化JSONのSHA256）の計算を行う。
- [ ] デーモン確認と世代取得を実装する。`daemon status --json` が running でなければ blocked（利用者の通常起動が必要と理由に書く）。`logs` から状態ディレクトリを導き、`sandboxd.pid`・`daemon.log` の最後の `starting sandboxd` 行・`Get-Process -Id` の StartTime を `daemonInstance`（pid、startedAt、version、socket）として保持する。取得不能は blocked。
- [ ] pilot排他を実装する。`Global\iv-sbx-pilot-<ユーザー名とsocketのSHA256先頭16>` の名前付きMutexを取得し、`Lease{runId,daemonKey,leaseId}` を返す。取得競合は待たずに blocked（create 0回）。放棄されたMutexを取得した場合も一覧確認を省略しない。
- [ ] `New-VerificationSandbox` を実装する。排他内で `ls --json` を読み、running/starting/停止未確認のVMがあれば作らず blocked。同名があれば blocked。固定argv `create shell --name <name> --cpus 2 --memory 2g --no-share-skills --deny-network '*' --template <digest>`（proposal は agent=codex）。sbx CLIの環境は `SystemRoot`、`PATH`（sbxの親ディレクトリのみ）、`USERPROFILE`、`LOCALAPPDATA`、`APPDATA`、`TEMP` の明示辞書で、`SSH_AUTH_SOCK` を含めない。create 応答と `ls --json` から id を確定し、`control/runtime/<role>-sandbox.json` へ保存してから activation を作る。
- [ ] activationRecord を作る（runId、sandboxId、role、daemonInstance、profileHash、effectiveSettingsHash、checkedAt、checks{policy,mount,resource,credentialExposure,sshForwarding}）。実効値は `inspect --json`（state・image_digest・network_policy・secrets）、`policy ls <name> --json`（deny `*` の存在）、状態ディレクトリの `runtimes/<name>.json`（CPUs=2、Memory=2g、ShareSkills=false、WorkspaceDir=""、SSHAgentSocketPath=""）、`daemon.log` の当該runtime行に `started SSH agent forwarder` が無いことから取る。1つでも取れなければ作成済みIDを保持して停止を試み、`runtimeFailure{creationState=created,stopState}` を例外に載せる。
- [ ] セッション保持を実装する。作成確認後、`exec <name> sh -c 'sleep <残時間>'` を `Invoke-VerificationProcessV3` で背景起動して Handle に保持し、`Stop-VerificationSandbox` の直前に停止する。保持プロセスの終了を VM 停止の証拠にしない。
- [ ] `Copy-`/`Confirm-` を実装する。cp は `cp <src> <name>:<Destination>` を1回、続けて `exec -u root <name> chown -R agent:agent <Destination>`。Confirm は `exec <name> sh -c 'cd <Destination> && find . -type f -print0 | sort -z | xargs -0 sha256sum'` の出力を外側の ExpectedManifest（path・size・sha256）と照合し、相違・欠落・予定外ファイルは blocked。
- [ ] `Invoke-VerificationSandboxCommand` を実装する。直前に `daemonInstance`（PID・StartTime）と `ls --json` の同一ID/running を再確認し、変化があれば実行せず失敗。argv は `exec -w <WorkingDirectory> [-e K=V...] <name> <argv...>` に固定し、stdin は `Invoke-VerificationProcessV3` で転送する。CommandRecord に commandId、startedAt/finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、transportVerified（開始マーカーとsbxの終了コードが 0/7/127 の対照で区別できた場合のみ true）を持たせる。
- [ ] `Stop-VerificationSandbox` を実装する。保持セッションを止め、`stop <name>` を1回、cleanupSeconds 内に `ls --json` で同一IDの stopped を確認し、`daemon.log` の当該runtimeの `stopped runtime container` 行と世代不変を記録する。未確認は `stopState=unverified`。他VMには触れない。
- [ ] `tests/SbxRuntimeV3.Tests.ps1` で、デーモン停止時 blocked、running/同名ありで create 0回、create 500 で not-created、id確定後の inspect 失敗で停止試行と `runtimeFailure.creationState=created`、Mutex競合で blocked、Confirm の欠落・予定外ファイル、exec 前の世代変化で実行拒否、出力超過での停止、stop 未確認で unverified、`calls.jsonl` に `SSH_AUTH_SOCK` が無いことを確認する。すべて偽sbxで、実VMは作らない。
- [ ] 試験成功後にコミットする。偽sbxの成功を実機の保護実証に数えない。

## タスク4: 提案VMの起動・回収・未信頼Envelopeの検査を実装する

**依存:** タスク1・3。**対象:** 新規 `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py`、`tests/ProposalV3.Tests.ps1`。

**インターフェース:** `Invoke-VerificationProposal([hashtable]$PreparedRun) -> ProposalResultV3`（schemaVersion、runId、status、origin、sandbox、summary、findings、artifacts、manifestPath、manifestHash、stopState、failure）。内部: `Test-VerificationProposalEnvelope([byte[]]$Wire,[hashtable]$PreparedRun) -> hashtable`（検査済み一覧）、`Write-VerificationAcceptedFiles`。

- [ ] recheck 経路を先に実装する。`recheckArtifacts` が非空なら VM・モデルを起動せず、`origin=reused-tests`、`sandbox=null`、`stopState=not-created`、`artifacts` は前回hashのまま、`manifestPath` は `control/proposal/manifest.json` を新規作成して返す。
- [ ] `proposal-export.py` を書く。VM内で `/home/agent/workspace/proposal/` 配下の `tests/test_*.py`・`tests/__init__.py`・`replacements/**/*.py` と `proposal.json`（summary、findings）を読み、`{"schemaVersion":3,"runId":...,"summary":...,"findings":[...],"files":[{"kind","path","contentBase64"}]}` を stdout へ1行で出す。自身は標準ライブラリだけを使い、上限を超えるファイルは含めずに `truncated` を立てる（外側はそれを拒否理由にする）。
- [ ] 提案経路を実装する。`New-VerificationSandbox proposal` → `Copy-`/`Confirm-`（proposal-input を `/home/agent/workspace/source` へ）→ 依頼文（目的・合格条件・作業先 `/home/agent/workspace/proposal`・書式・禁止事項）を `startupArgv` の Codex へ stdin で渡す `Invoke-VerificationSandboxCommand`（proposalSeconds）→ `proposal-export.py` を cp して `python3` で実行（stdout 上限 maxWireBytes）→ 停止。子の実行イベントと最終応答は `quarantine/` に未信頼データとして保存する。
- [ ] `Test-VerificationProposalEnvelope` を実装する。wire容量→重複キー・深さ・未知キー・型→runId→件数（maxProposalFiles）→path規則（UTF-8 POSIX相対、絶対・ドライブ・UNC・空成分・`.`・`..`・バックスラッシュ・コロン・NUL・末尾空白/ドット・Windows予約名、大小文字無視の重複、親子衝突、`.git`/`.codex`/`.claude`/`.agents`/`.mcp.json` 配下）→kind（test は `tests/` 接頭辞なしの相対名で `test_*.py`/`__init__.py`、replacement は baseline に存在する `.py` 通常ファイル）→base64正規性→復号後サイズ（maxFileBytes・maxProposalBytes）→UTF-8テキスト、の順に検査し、最初の違反で全体を拒否する。test 0件は拒否、replacement 0件は再現のみとして許す。
- [ ] `accepted/tests/<path>`・`accepted/replacements/<path>` を CreateNew で生成し、祖先にリンク・再解析ポイント・既存ファイルがあれば拒否する。外側でサイズ・SHA256を計算して `control/proposal/manifest.json` に保存し、`manifestHash` を返す。`testsManifestHash`（testの相対パス・サイズ・SHA256をパス順に正規化したSHA256）も保存する。
- [ ] 停止確認後に `status=ready`。停止未確認は受信済みでも `incomplete`（`stopState=unverified`）。時間超過は `timed_out`。`runtimeFailure` は捕捉して `sandbox` に確定済みhandleを残す。
- [ ] `tests/ProposalV3.Tests.ps1` で、recheck が VM 0回、正常Envelope が ready、架空runId、リンク相当パス、`..`、予約名、大小文字重複、過大wire、復号後超過、途中切断（不完全JSON）、test 0件、replacement が baseline に無い、非.py、停止未確認 → incomplete、offline時の `quarantine` 保存を確認する。実Codex・実VMは起動しない。
- [ ] コミットする。

## タスク5: 通信なしVMでの修正前後の再実行と外側記録を実装する

**依存:** タスク1・3・4。**対象:** 新規 `Replay.psm1`、`replay-record.schema.json`、`tests/ReplayV3.Tests.ps1`、`tests/fixtures/pilot-source/`（`calc.py` に既知の欠陥、`test_calc.py` が before で非0・after で0 になる合成題材）。

**インターフェース:** `Invoke-VerificationReplay([hashtable]$PreparedRun,[hashtable]$ProposalResult) -> ReplayResultV3`（schemaVersion、runId、status、mode、sandboxes、before、after、allStopped、failure）、`New-VerificationReplayNotRun([hashtable]$PreparedRun,[hashtable]$Failure) -> ReplayResultV3`。

- [ ] 入力検査を実装する。`ProposalResult.status=ready`、runId一致、`manifestHash` と `accepted` 現物の再照合、origin ごとの sandbox/stopState 条件、baseline の全ファイル manifest と期待hash の照合。不成立は blocked。
- [ ] `replay-inputs/before` と `after` を外側で作る。before は baseline の作業ファイル（`.git` を除く）、after は同じファイルへ検査済み replacement を適用したもの。両方の `.verification-tests/` に同じ tests を置き、各入力の manifest（path・size・sha256）と `testsManifestHash` を保存する。mode は replacement なしで `reproduction-only`、ありで `candidate-comparison`、recheck で `recheck`（現在版を after とし before=null）。
- [ ] 役割ごとに新規VMを順に使う。`New-VerificationSandbox replay-before` → Copy/Confirm（`/home/agent/workspace/source`）→ 固定argv `["python3","-m","unittest","discover","-s",".verification-tests","-p","test_*.py","-v"]` を `WorkingDirectory=/home/agent/workspace/source`、Environment は profile の最小辞書で実行（replaySeconds）→ 停止確認 → after を同様に。before の停止未確認なら after を作らず返す。
- [ ] 各コマンドを `control/replay/<role>/<commandId>.json` へ `replay-record.schema.json` どおり保存する（runId、role、sandboxId、profileHash、effectiveSettingsHash、templateDigest、sourceManifestHash、inputManifestHash、testsManifestHash、argv、workingDirectory、startedAt、finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、stopVerified、transportVerified、activationRecordPath/Hash、limits）。
- [ ] `New-VerificationReplayNotRun` を実装する（status=not_run、sandboxes=[]、before/after/allStopped=null、failure に上流段階）。作成成否不明は not_run へ丸めず `failure.reason=creation-unresolved` で incomplete。
- [ ] `tests/ReplayV3.Tests.ps1` で、偽sbx が before に終了1・after に終了0 を返すケースで `completed`（合否は付けない）、before 0 の非再現、after 非0、テスト集合が before/after で異なる入力の拒否、別 digest の profile 拒否、before 停止未確認で after 未作成かつ incomplete、偽成功文字列（stdout に "OK" だが終了1）が終了コードを覆さないこと、出力洪水で incomplete、時間超過で timed_out、`not_run` の書式、各役割の sandbox id が相異なることを確認する。
- [ ] コミットする。

## タスク6: 3入力を外側の記録で照合し結果を返す

**依存:** タスク1・4・5。**対象:** `Result.psm1`、`result.schema.json`（v1/v3を `if/then` で分岐）、`tests/ResultV3.Tests.ps1`。

**インターフェース:** `Complete-VerificationRun` は2引数で既存 `Complete-LegacyVerificationRun`、3引数（PreparedRunV3、ProposalResultV3、ReplayResultV3）で v3 照合。`New-VerificationFailureResult([hashtable]$RequestContext,[hashtable]$Failure) -> VerificationResultV3`。

- [ ] `result.schema.json` に v3 定義（schemaVersion、runId、status、summary、sourceState、baselineState、proposalVerdict、replayVerdict、checks、findings、artifacts、unverified、execution、previousRunId、runRoot、sourceManifestPath、scope、limitations。`additionalProperties:false`）を足し、v1 定義は保つ。
- [ ] 照合手順1〜7（仕様03）を実装する。順序は schemaVersion/runId → activationRecord と profileHash/sandboxId/daemonInstance → manifest 期待hash と現物 → 原本再列挙 → accepted・replay input・testsManifestHash → 外側記録（runId/role/VM id/argv/時刻/hash/transportVerified/停止）→ 停止記録の必須化 → 観測分類。証拠パスは control 内だけを許す。
- [ ] status の優先順位（timed_out → incomplete〈作成不明・作成済みの停止未確認・基準版改変〉→ blocked → source_changed → incomplete〈その他〉→ completed）と、Proposal/Replay の status 写像、`not_run` の上流追従を実装する。scope 付与前に pilotInputHash と記録現物、sourceRoot/sourceManifestHash を再照合する。
- [ ] `replayVerdict` の観測分類（candidate-supported / not-reproduced / still-failing / reproduced / current-pass / current-fail / undetermined）と、completed 時の CLI終了値（0/1）を `execution.exitCodeForCli` として返す。
- [ ] `New-VerificationFailureResult` を実装する（runId/runRoot/sourceManifestPath/previousRunId=null、sourceState/baselineState=unreadable、proposalVerdict=null、replayVerdict=undetermined、空配列、execution は proposalCreated=false・replayCreatedCount=0・停止値null・失敗段階、判明済みVM情報があれば保持）。
- [ ] `control/result.json` を CreateNew で一度だけ保存し、既存があれば例外にして保全する。
- [ ] `tests/ResultV3.Tests.ps1` で、正常（candidate-supported、終了0）、still-failing（終了1）、reproduction-only、recheck の current-pass/current-fail、架空 commandId、別 sandboxId/世代、自己申告 pass だけの入力、基準Git改変（incomplete）、原本更新（source_changed）、出力欠落、同一テストでない比較、停止未確認（incomplete かつ blocked より優先）、not_run 追従、失敗結果の null 書式、既存 result.json 保全、schema 適合を確認する。
- [ ] 既存 `Result.Tests.ps1` の成功を保ち、コミットする。

## タスク7: 共通CLIで4責務を結合し、既存試験群へ組み込む

**依存:** タスク1〜6。**対象:** 新規 `Invoke-IsolatedVerification.ps1`、`tests/CliV3.Tests.ps1`、変更 `README.md`、`tests/Run-IndependentTests.ps1`。

**インターフェース:** `pwsh -NoProfile -File scripts/verification/Invoke-IsolatedVerification.ps1 -RequestPath <json> -SettingsPath <json>`。stdout に VerificationResultV3 の JSON 1件、stderr に診断。終了値は completed なら判定（0/1）、それ以外 2。

- [ ] 入力読込（重複キー検査つき）→ `startedAt` 確定 → `New-VerificationRun`（失敗は `New-VerificationFailureResult`）→ `Test-VerificationRuntimeProfile`（replay は常に、proposal は非recheck時）→ `Acquire-VerificationPilotLease` → `Invoke-VerificationProposal` → ready なら `Invoke-VerificationReplay`、非ready なら `New-VerificationReplayNotRun` → `Complete-VerificationRun` → `finally` で `Release-VerificationPilotLease`。準備後の例外は判明済みVM情報を RequestContext に足して失敗結果へ。
- [ ] 開始時に scope と acceptedLimitations（clipboard文字列書込の可能性・プロセス数上限なし）を stderr に表示する。clipboard の読取・退避・復元・消去はしない。
- [ ] 全体 deadline を単調時計で監督し、到達後は新規VM作成・execを行わず停止処理だけ cleanupSeconds を許す。
- [ ] `tests/CliV3.Tests.ps1` で、偽sbx と `tests/fixtures/pilot-source` を使い、正常往復（stdout JSON 1件・終了0）、still-failing（終了1）、固定入力不一致（blocked・終了2）、デーモン停止（blocked・理由に通常起動）、Lease競合（blocked）、提案非ready→replay not_run、途中失敗時の Lease 解放を確認する。
- [ ] `Run-IndependentTests.ps1` に v3 の7群（RequestCopyV3、ExecutionV3、SbxRuntimeV3、ProposalV3、ReplayV3、ResultV3、CliV3）を足し、出力を「11 suites passed」にする。README に v3 の使い方、前提（利用者起動のデーモン）、既知の制約（自動停止・clipboard例外・pilot限定）を書く。
- [ ] 11群成功を確認してコミットする。

## タスク8: AIなしで実VMの再実行・停止・記録を実証する（個別承認）

**依存:** タスク7。**対象:** 新規 `tests/Invoke-SbxPilotProbe.ps1`、replay 用 profile と activationEvidence（`control` 外の固定ファイル、`docs/records/experiments/2026-09-14-v3-capability-test-methods.md` の証拠を参照）、実験記録。

- [ ] 提示する: VM名（`iv-sbx-replay-<日付>-01/02`）、固定argv、搬入する `pilot-source` の内容とhash、実行コマンド、停止手順、取得する証拠、所要見込み。デーモン停止中なら利用者の通常起動を先に依頼する。承認後にだけ進む。
- [ ] `Invoke-SbxPilotProbe.ps1` で `Invoke-VerificationReplay` を実sbxに対して1回動かし、before 非0・after 0、各役割の新規 id、停止確認、`transportVerified` の対照（終了0・固定7・存在しないコマンド127・時間超過）を取る。切断注入は本タスクに含めない。
- [ ] 実験記録へ結果と限界（1回の成立、負荷なし、切断未注入）を書き、replay profile の activationEvidence を固定版・固定設定の能力試験記録として保存する。コミットする。

逸脱記録は実施後に残す。

## タスク9: 最小モデル往復（個別承認、認証方式の実測が前提）

**依存:** タスク8。**対象:** proposal 用 profile、`docs/records/experiments/`。

- [ ] sbx の資格情報の渡し方（プロキシによるヘッダー注入、`sbx secret`）を読み取りで調べ、raw の認証値を VM に渡さない構成が成立するかを提示する。成立しなければ blocked のまま相談する。
- [ ] 承認後、`pilot-source` で Claude Code・Codex 双方の主担当から1往復（依頼→提案→再実行→結果→主担当の修正→recheck）を行い、記録する。送信範囲・最大時間・モデルは承認どおり。
- [ ] 記録をコミットし、サイクル全体整合検査と最終レビューへ進む（ADR-0162・0192 の昇格を含む）。

## 完了基準と検証期待値の対応

| 仕様 | 所有タスク | 正常対照と失敗対照 |
|---|---|---|
| V1 | 1 | v3の baseline・proposal-input・履歴コピー／未知キー・リンク・範囲外・recheck改変・予約名衝突・原本内runsRoot |
| V2 | 3・8・9 | activationRecord の実効値一致／デーモン停止・同名・500・inspect失敗・SSH forwarder 行の存在・`SSH_AUTH_SOCK` の混入 |
| V3 | 4 | 正常Envelope が accepted へ／パス逸脱・重複・予約名・過大・切断・test 0件・baseline に無い replacement |
| V4 | 5・8 | before 非0/after 0 を別VM・通信なしで記録／非再現・after 非0・テスト差・別digest |
| V5 | 2・3・5・8 | 出力超過・時間超過・停止確認／停止未確認・世代変化・偽成功文字列 |
| V6 | 1・6 | manifest 期待hash と現物の一致／原本更新・baseline改変・証拠欠落・別runId・自己申告pass |
| V7 | 7・9 | 両主担当からの往復（実モデルは9）／caller 文字列だけでは未実証 |

計画検証では、この表と各タスクの編集内容・試験内容を照合する。ランナーの期待値は既存4群＋新規7群＝11群。タスク8・9の実機試験は群数に含めない。偽sbxの応答は本計画時点の実測出力（`.tmp/sbx-capability-20260914/` の原文）に合わせ、未観測の応答形式を創作しない。

## 確定前の確認状況

仕様は静的フル1回＋差分2回、試作条件は差分2回で確定済み。本計画はその写像で通常型。計画特有の未確認範囲は、セッション保持exec の副作用（保持中の stop の挙動は試験Cで exit 137 を観測済み）、`ProcessHost` の stdin 転送、Mutex 名の衝突、`inspect --json` の項目が版で変わる可能性、Codex 起動 argv（タスク9で実測）。

2026-09-14 の自己確認: タスク1〜9、V1〜V7 の対応7行、参照ファイルの実在（仕様5件・記録2件・参照知識1件・v1部品4件）、試験群の期待値 4＋7＝11 を照合。これは文書の確認であり、コードの動作・実機の保護・モデル往復の実証ではない。
