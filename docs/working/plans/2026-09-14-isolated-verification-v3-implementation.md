# 隔離検証 v3（提案と通信なし再実行）実装計画

> **実装担当へ:** `superpowers:subagent-driven-development`（推奨）または `superpowers:executing-plans` でタスク単位に進める。各ステップは `- [ ]` で追跡する。VMを作る操作（タスク8・9）は本計画の作成承認に含まれず、区切りごとの個別承認が必要。

**目的:** Claude CodeまたはCodexの主担当が共通CLI 1本で、独立コピー上のsbx内Codexに再現テストと修正候補を提案させ、別の通信なしVMで採否用の再実行を取り、外側の記録で照合した結果を受け取れるようにする。

**構成:** 準備（01）→提案（02）→再実行（04）→照合（03）の4責務を `scripts/verification/` の既存v1部品の上に足す。v1の公開契約と4試験群は保持し、v3はschemaVersion=3だけを受理する。VMを使う部分は `SbxRuntime.psm1` に閉じ、他ブロックはその公開操作だけを呼ぶ。VMなしで検査できる契約・拒否・停止の試験を先に揃え、実VM・実モデルは個別承認の区切りで行う。

**技術:** Windows 11、PowerShell 7、Git、sbx 0.42.1（利用者が通常端末で起動したデーモン）、固定テンプレート `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`（Python 3・unittest。版はタスク8で確定）。ホスト側の Python 3 は合成題材の事前確認にだけ任意で使う。新規パッケージ・常駐サービスは追加しない。

**仕様:** `docs/current/specs/2026-09-09-isolated-verification/00-overview.md`、`01-request-and-copy.md`、`02-isolated-execution.md`、`03-result-collection.md`、`04-offline-replay.md`（`5259d22` で確定した試作条件を含む現行版）。

**実測の前提:** `docs/reference/sbx-sandbox-runtime-facts.md`（自動停止30秒・cp/execの自動起動・透過プロキシ・SSH中継の実体・外側記録の所在）と `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（試験A〜D合格）。CLI照会の出力形式は `.tmp/sbx-capability-20260914/` の原文（`00` daemon status、`11`/`42` ls、`32` inspect、`34` policy log、`35` policy ls、`50` mcp ls、`51`/`52` settings get）。

## 共通制約と承認の境界

- 作業場所は `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`、ブランチ `codex/isolated-verification`。作成時HEADは `3385d24`。未追跡 `.tmp/`・他worktree・stash・試験VM2台（`iv-sbx-smoke-20260909-01`、`iv-sbx-capability-20260914-01`）を保全し、削除・再作成しない。
- v3は schemaVersion=3 のみ受理。v1公開関数（`New-VerificationRun` 2引数、`Complete-VerificationRun` 2引数、`Invoke-VerificationProcess`）の挙動と既存4試験群（RequestCopy・History・Execution・Result）を保持する。未実装v2は受理しない。
- synthetic-pilot固定: `cpus=2`、`memoryMiB=2048`、同時1VM、`scope=synthetic-pilot`、`acceptedLimitations=["clipboard-text-write-possible","pid-count-unbounded","daemon-disconnect-unverified"]`（3件目はADR-0196）。初期上限は全体1800秒・提案600秒・各再実行120秒・停止猶予30秒・100ファイル・1ファイル1MiB・合計8MiB・転送16MiB・1コマンド出力合計16MiB。pidsキーは未知キーとして拒否する。
- **時間上限の適用範囲**: limits のキー集合は仕様01のまま変えない。発行する全コマンドの上限を次の全域表で定め、limits の値に連動させない: 照会（`daemon status`・`ls`・`inspect`・`policy`・`settings`・`mcp`）と `stop` は60秒／作成・搬入・所有者調整・搬入照合・回収（`create`・`cp`・`chown`・Confirm の `exec … sha256sum`・`proposal-export.py` の `exec`）は240秒（取得済みイメージでの作成は約1分の実測）／Codex 実行の `exec` は `proposalSeconds`／unittest の `exec` は `replaySeconds`／タスク8a の probe が直接発行する `exec`（版・一覧取得、transport 対照、出力洪水、unittest）は `replaySeconds`（時間超過対照はこの値で打ち切る。`clientKilled` 対照だけは背景起動のため期限監督の対象外で、probe が明示的に止める）／セッション保持の `exec … sleep` は期限監督の対象外（`Start-VerificationBackgroundProcess` は work 相の期限で対象を打ち切らず、停止は `Stop-VerificationSandbox` の手順だけで行う。第4回 M-1）。保持以外はいずれも残時間との小さい方を使う（limits からの固定式は、`replaySeconds` を小さく設定すると作成が必ず時間超過する経路があるためやめた。第3回 M-1）。
- 原本・baseline・control・ホストホーム・資格情報をVMへ渡さない。VMにはproposal-input（提案用）と replay-inputs/before|after（再実行用）だけを `sbx cp` で搬入する。共有skills・workspace・追加MCPサーバーを与えない。
- sbx CLIは常に外側で固定argvを組み立てて起動する。子からホストコマンド・sbxフラグ・接続先を受け取らない。sbx CLIの環境は明示した最小辞書とし、`SSH_AUTH_SOCK` を渡さない。
- デーモンの起動・再起動・reset・設定変更はランナーの責務外。停止中なら「利用者が通常端末で起動する必要がある」と返してblocked。`sbx daemon status --json` だけは停止中でも呼んでよい（自動起動しないことを実測済み）。`ls`・`inspect`・`settings`・`mcp`・`cp`・`exec` は running 確認後だけ呼ぶ。
- VMは最後のセッション切断から30秒で自動停止し、`cp`・`exec` は停止VMを自動起動する。SbxRuntimeはVM作成直後から停止までセッション保持用のexecを1本保つ（タスク2の背景起動操作を使う。ADR-0193）。run途中の自動停止・自動再起動は daemon.log の行で検知し、当該runを `incomplete` にする。停止確認は `ls --json` の同一ID・`status: stopped`、stop発行後の時刻の `stopped runtime container` 行、操作前後のデーモン世代不変で行う。
- 接続成立（TCPハンドシェイク）を到達の証拠にしない。通信・SSHの拒否はプロトコル応答・policy log・daemon.logで判定する（試験Aの方式）。
- 全体 deadline 到達後は新しいVM作成・搬入・実行を開始しない。停止処理（`stop`・`ls` による停止確認・保持セッションの停止）だけは停止フェーズの予算 `cleanupDeadlineAt = now + cleanupSeconds × 停止対象台数`（停止フェーズ開始時の現在時刻を起点に確定。対象0台なら1台分。run途中の停止でも同じ式で、全体 deadline までの残時間を停止予算に繰り入れない）まで許す。停止1台の実測所要は約11秒。
- モデル自己申告、設定値の受理、sbx CLIの終了だけを保護・実行・停止の証拠にしない。原本へ自動適用しない。回収物をホストでimport・実行しない。
- 失敗領域・停止VMは診断用に残す。VMの名前はrunごとに一意（下記）にし、残置VMと衝突させない。VM削除（`sbx rm`）・イメージ変更・導入・公開・masterへの統合は本計画の承認に含めない。

### 判断の分担・逸脱判断の既定

判断の分担はADR-0158の補助設計委任（`00-overview.md`「判断の分担と参照」、承認時点 `b7941f3`）。補助機能の仕様・内部構造・対策方法は委任範囲。保護の追加緩和、新たな必須基盤・利用者作業、認証・利用費・送信範囲、削除・公開は相談する。実機・設定・モデル操作の承認はADR-0162・ADR-0192の範囲に限り、本計画のタスク8・9は個別承認を別に得る。

逸脱判断は `ai-driven-dev-principles` 導入版 **0.1.29** の `skills/start-work/references/plan-deviation-defaults.md` に従う。計画確定時に基準を固定する。委任された局所仕様変更（補助設計）は既定の型分類で扱い、保護条件・外部契約（Request/Settings/Result/ProposalEnvelopeのschema、固定argv）に触れるものは「設計の変更」側へ倒す。動作テストを安全網とする通常の実装計画で、コード全文の書き写し方式ではない。タスク別の仕様適合レビューを置く工程（subagent-driven-development）を既定とし、置かない場合は設計変更で独立レビューへ切り替える。各タスク末尾に必要な `逸脱記録:` を残す。

確定前レビューからの引き継ぎ一覧: 第1回〜第4回のフル実施（いずれも1体4観点兼務、claude-opus-5）と第5回〜第9回の差分再確認の指摘の採否は本計画末尾「確定前の確認状況」に記す。不採用は第5回 m-F の1件（理由は同節）。仕様レビュー（`docs/records/reviews/2026-09-09-proposal-replay-spec-r3.md`、`2026-09-10-synthetic-pilot-scope-r2.md`）の不採用指摘を再提案する場合は、実装後の実体で以前の理由が覆る証拠を要する。

本計画が仕様に対して加える実体合わせの調整（設計の変更ではない）: (a) 共通の正規化・ハッシュ・新規作成書込・重複キー検査の補助関数を `RequestCopy.psm1` から公開する（新モジュールを増やさない）。(b) 固定入力記録のschemaを `pilot-input.schema.json`、activationEvidenceのschemaを `activation-evidence.schema.json`、復旧操作の入力schemaを `recovery-input.schema.json`（schemaVersion=3・sbxPath・pwshPath・runsRoot・limits）、出力schemaを `recovery-result.schema.json` として置く。(c) デーモン世代の取得元は `daemon status --json` の `logs` パス（running時に実測済み）から状態ディレクトリを導き、PIDファイル・`daemon.log` の起動行・OSプロセスのStartTimeを対応付ける。(f) `New-VerificationRun` は第3引数 `StartedAt` を取る（CLI受付時刻を単一起点にするため。v1呼び出しは省略可）。(g) PreparedRunV3 に `cleanupSeconds` を保持し、停止フェーズの期限は停止時に計算する。(h) VerificationResultV3 の `execution` に `exitCodeForCli`・`pilotInputId`・`pilotInputPath`・`pilotInputHash` を持たせる（仕様03の「未知キー禁止」は結果のトップレベルに対する規定で、`execution` の項目集合は本計画が所有する `result.schema.json` の v3 定義で固定する）。(i) exec以外のコマンドの時間上限を SbxRuntime 内の定数で定める（上記）。(j) SbxRuntime/Proposal/Replay の公開操作へ仕様02の列挙に加えて Settings・Lease・RunBudget・OutputSignature（仕様04の transportVerified の実現手段）を渡し、SandboxHandle に `effectiveSettingsHash`・`keepAliveHandle` を持たせる（いずれもJSON化可能な値。Lease は仕様02「各New-VerificationSandboxは当該runの有効なLeaseがあることを検査する」の実現手段）。

本計画が仕様に足す設計（設計の変更として扱い、確定はADRで記録する）: (d) セッション保持のexec（ADR-0193）。(e) CLI異常終了時の停止経路（記録済みIDだけを止める復旧操作。ADR-0194）。(k) synthetic-pilot の acceptedLimitations に `daemon-disconnect-unverified` を追加（ADR-0196。仕様02・03へ反映済み）。(l) proposal 用 profile の「負荷中の外側停止」だけ再実行用の既存記録を証拠に使う（ADR-0197。仕様00の「保護条件を共用済みにしない」の試作限定の例外。仕様00へ反映済み）。

### 相談事項（1〜7とも2026-09-15に確定。ADR-0193・0194・0195、4はADR-0193の改訂、5はADR-0196、6・7はADR-0197）

1. **セッション保持exec（(d)）**: 確定済み（ADR-0193、Proposed）。実VM試験（タスク8）に約30分の連続保持の確認を含める。
2. **V5「CLI切断時の停止」「対象外VMの継続」の扱い**: 確定済み（ADR-0194、Proposed）。`finally` の停止に加え、control/runtime の記録済みIDだけを停止する復旧操作 `Stop-VerificationRecordedSandboxes`（CLI入口 `-StopRecorded`）を設け、タスク8でCLI強制終了後の自動停止と復旧操作を実機で確認する。
3. **MCPゲートウェイ**: 確定済み（ADR-0195、Proposed）。仕様02の「MCP登録なし」は `mcp ls --json` の `servers` が空であることで判定し、製品が常設するゲートウェイと `mcpgateway` secret は製品挙動として activationRecord と結果に明記する。

### 実行承認を求める具体的な区切り

| 区切り | 提示する対象 | 承認に含めないもの |
|---|---|---|
| タスク8のAIなし実VM試験 | 使うVM名（8a の probe 1台、8b の before/after 2台）・固定argv・搬入する合成題材（内容とhash）・実行コマンド・停止手順・transport対照（0/7/127/時間超過/sbx クライアント子プロセスの強制終了）・出力洪水の exec 1本・合成題材の unittest 1本（出力ストリームの実測）・約30分の連続保持・probe プロセス（CLI 相当）の強制終了と復旧操作・取得する証拠（`python3 --version`、標準ライブラリ一覧、各照会の出力、状態ディレクトリの当該ファイル・行）・所要見込み | モデル起動、認証、既存VMの操作（停止中の試験VM2台は `ls --json` の一覧読取りのみ。当該名への `inspect`・`exec`・`cp` は発行しない）、削除、イメージ変更、デーモン停止を伴う競合注入、試験A〜C（否定試験・負荷試験）の再実施 |
| タスク9の最小モデル往復 | 認証の渡し方（sbxの資格情報プロキシの実測結果を先に提示）・モデル・送信範囲・proposal 用固定argv・proposal 用 profile の証拠取得（proposal 用 VM 2台: 1台目で 8a と同じ手順＋ゲスト側の否定確認と実効値の数本のコマンド＋外側停止、2台目で保持開始・probe プロセス強制終了後の自動停止と復旧操作。ADR-0197）・使う VM 名（証拠取得の2台と往復の各役割）・最大時間・題材・保存先 | 任意の別リポジトリ、通常導入・公開、clipboard操作、proposal VM での負荷試験（既存記録を使う） |

重い試験は1件ずつ。利用者の作業が必要なら（デーモン起動）、確定したコマンドと結果保存先を用意し、本文転記は求めない。

## ファイルと責務

特記しない限り `scripts/verification/` からの相対パス。

| ファイル | 操作・責務 | タスク |
|---|---|---|
| `RequestCopy.psm1`、`request.schema.json`、`settings.schema.json`、`pilot-input.schema.json` | 変更・新規。v1保持、v3の検査・固定入力照合・run配置・baseline/proposal-input・recheck。正規化JSON/ハッシュ/新規作成書込/重複キー検査の公開 | 1 |
| `Execution.psm1`、`ProcessHost.ps1` | 変更。`Invoke-VerificationProcessV3`（対象stdinへのバイト転送・合算出力上限・RunBudget）と背景起動の `Start-VerificationBackgroundProcess`/`Stop-VerificationBackgroundProcess` | 2 |
| `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-evidence.schema.json`、`activation-record.schema.json`、`recovery-input.schema.json`、`recovery-result.schema.json` | 新規。実行設定検査、pilot排他、VM作成・搬入・照合・実行・停止、activationRecord、デーモン世代、記録済みIDの復旧停止 | 3 |
| `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py` | 新規。提案VMの起動・依頼・固定エクスポーター・未信頼Envelopeの検査・accepted生成・停止 | 4 |
| `Replay.psm1`、`replay-record.schema.json` | 新規。before/after/recheck入力の生成と差分照合、標準ライブラリ検査、新規VMでの再実行、外側記録、未実行結果 | 5 |
| `Result.psm1`、`result.schema.json` | 変更。v1保持、v3の3入力照合、失敗結果、観測分類、CreateNew保存 | 6 |
| `Invoke-IsolatedVerification.ps1`、`README.md`、`tests/Run-IndependentTests.ps1` | 新規・変更。JSON入力、4責務の結合、pilot排他、deadline監督、終了コード、診断表示、復旧入口 | 7 |
| `tests/*V3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`、`tests/fixtures/fake-state/`、`tests/fixtures/ProcessFixtureV3.ps1`、`tests/fixtures/pilot-source/`、`tests/fixtures/stdlib-modules.txt`、`tests/fixtures/activation-evidence.json` | 新規。VMなしの契約・偽造・停止試験。偽sbxは記録済み応答を返す固定スクリプト。`fake-state/` は偽の状態ディレクトリ（下記）。evidence と stdlib 一覧の fixture は試験専用で、実runには使わない | 1〜7 |
| `tests/Invoke-SbxPilotProbe.ps1`、`tests/fixtures/probe-settings.json`（8a 用の雛形。`recovery-input.schema.json`〈schemaVersion=3 を含む〉で検査）、`tests/fixtures/pilot-run/`（8b 用の request・settings・pilot-input 記録）、`profiles/replay/` | 新規。個別承認後に実VMで証拠取得（8a: 固定argv直接）と公開操作の実証（8b）を行い、実 run 用 replay profile 一式を生成する | 8 |
| `profiles/evidence-checks.md` | 新規。条件名と観測の対応表（verified の意味の正本） | 3 |
| `docs/records/experiments/`（実VM・実モデルの記録）、`profiles/proposal/` | 新規。タスク8・9の証拠、proposal 用 profile 一式（タスク9） | 8・9 |

**偽sbx**: `fake-sbx.cmd` は同ディレクトリの `FakeSbx.ps1` を、複製時に埋め込んだ pwsh の絶対パス（`(Get-Command pwsh).Source` を試験側が書き込む）で `-NoProfile` 起動する。PATH に依存しない（SbxRuntime が渡す環境辞書の PATH は sbx の親ディレクトリだけのため）。`FakeSbx.ps1` は同ディレクトリの `scenario.json` の配列から「argv 要素に対する正規表現パターン列の全一致」で応答（stdout/stderr/exitCode/遅延秒）を選び、呼び出しを `calls.jsonl` へ追記する。`calls.jsonl` の1行は argv・作業ディレクトリ・受け取った環境変数のキー一覧（値は記録しない）・時刻を持つ。before/after は VM 名の役割接尾辞（下記）で区別する。未定義の argv は終了3で `unexpected sbx call` を返す。試験ケースごとに偽sbx一式をケース領域へ複製して `settings.sbxPath` に指定する。任意 scriptblock や接続先をプロダクトの CLI へ公開しない。

**偽の状態ディレクトリ** (`tests/fixtures/fake-state/`): SbxRuntime は世代・実効値・停止証拠を CLI 応答ではなく状態ディレクトリの実ファイルから読む（`sandboxd.pid`、`daemon.log`、`runtimes/<VM名>.json`）ため、偽sbxだけでは試験できない。ケース領域に `fake-state/` を複製し、偽sbxの `daemon status --json` の `logs` をそこへ向ける。`daemon.log` は実測原文（`.tmp/sbx-capability-20260914/24-daemonlog-autostop.txt`、`44-daemonlog-stop.txt`）から取った行テンプレート3種（`starting sandboxd`、`auto-stopped runtime after last session disconnected`、`stopped runtime container`）をケースごとに並べて生成し、`sandboxd.pid` には試験プロセス自身の PID を書いて `Get-Process` の StartTime を成立させる。`runtimes/<VM名>.json` は `22-runtime-file.json` の形式に合わせる。

**偽sbxの応答の出所**: 正常応答（`daemon status --json`、`ls --json`〈`status` の観測値は running/stopped〉、`create`、`cp`、`exec` の 0/137、`stop`、`inspect --json`、`policy ls <name> --json`、`policy log <name> --json`、`settings get --json <キー>`、`mcp ls --json`）は `.tmp/sbx-capability-20260914/` の実測出力に合わせる。エラー応答（create の 500、exec の 127、デーモン停止時の接続失敗、クライアント強制終了、`ls --json` の未観測の status 値、`mcp ls --json` の登録1件ありの要素形式）は実測が無いため「創作した応答」として `scenario.json` に `synthetic: true` を付ける。exec の 127・クライアント強制終了・unittest の要約（ストリームと形式）はタスク8a の実機対照で確認して差し替える（それまで unittest 応答も synthetic）。実測出力に含まれる利用者の識別子（`mcp ls --json` の `signed_in_as` 等）は fixture では固定のダミー値に置き換える（判定に使わないため検出力は落ちない）。デーモン停止時の接続失敗は、停止中デーモンへの発行を本計画が禁じ、デーモン停止を伴う注入を承認に含めないため、実機対照の対象にせず恒久的に synthetic のまま扱う（判定には使わない。下記 `transportVerified`）。MCP 登録1件ありの判定は要素の中身ではなく `servers` の件数で行う。Envelope（提案の書式）は本仕様の契約であり、この規則の対象外。

**VM名の規則**: `iv-<runIdの先頭8桁>-<role>`（role は `proposal`/`before`/`after`、およびタスク8a 専用の `probe`。例 `iv-0baac92d-before`）。runId は UUID なので run ごとに一意で、残置VMと衝突しない（probe は 8a 用の足場 run の runId を使い、名前は `iv-<runId8>-probe`）。同名が `ls --json` にあれば当該 run を blocked にする（衝突は UUID 衝突か同一 run の再実行を意味する）。

## タスク1: v1互換を保ってv3の依頼・設定・固定入力を検査し、基準版と提案用コピーを準備する

**依存:** なし。**対象:** `RequestCopy.psm1`、`request.schema.json`（v1/v3を `if/then` で分岐）、新規 `settings.schema.json`、`pilot-input.schema.json`、`tests/RequestCopyV3.Tests.ps1`。

**インターフェース:** `New-VerificationRun([hashtable]$Request,[hashtable]$Settings,[string]$StartedAt)` は schemaVersion で分岐し、1は既存本体を抽出した `New-LegacyVerificationRun`（`$StartedAt` を無視）、3は `New-ProposalReplayRun` を呼ぶ（戻り値 PreparedRunV3、失敗は例外 `Data['status']`/`['stage']`/`['runRoot']`）。公開追加: `ConvertTo-VerificationCanonicalJson($Object) -> string`（キー辞書順・UTF-8・空白なし）、`Get-VerificationCanonicalHash($Object) -> string`（SHA256大文字16進）、`Write-VerificationNewFile([string]$Path,[string]$Content)`（CreateNew・BOMなし）、`Get-VerificationUtcNow() -> string`（ISO8601 UTC）、`Test-VerificationJsonDuplicateKeys([string]$Json) -> bool`（生JSONの重複キー検出。CLIが入力ファイルに適用し、本モジュールの試験は生JSON文字列で行う）。

- [x] 既存 `New-VerificationRun` 本体を `New-LegacyVerificationRun` へ抽出し、公開関数は分岐だけにする（第3引数は省略可）。既存4試験群を実行して成功数が変わらないことを確認する（`Run-IndependentTests.ps1` が「4 suites passed」）。
- [x] `settings.schema.json`（必須: schemaVersion=3、sbxPath、pwshPath、runsRoot、model、proposalProfilePath、replayProfilePath、pilotInputPath、limits。`additionalProperties:false`。recheck時のみ model/proposalProfilePath に null 可。replayProfilePath は仕様01どおり常に必須で、null は通常経路で blocked にする。復旧操作 `-StopRecorded` は SettingsV3 ではなく縮約入力（schemaVersion=3・sbxPath・pwshPath・runsRoot・limits の `recovery-input.schema.json`）を受け、タスク8a の probe は `tests/` 配下の probe 専用設定を使う——いずれも SettingsV3 の契約を緩めない）と `pilot-input.schema.json`（schemaVersion=3、inputId、scope=synthetic-pilot、sourceRoot、sourceManifestHash、approvalReference）を書く。`request.schema.json` は `schemaVersion` が1なら既存定義、3なら v3 定義（caller、sourceRoot、objective、acceptanceCriteria、extraInputPaths、任意 recheck{previousResultPath,testPaths}）を適用する。
- [x] v3検査を実装する。未知キー、数字の文字列表現、旧 `pids` キー、`cpus`≠2 / `memoryMiB`≠2048、`proposalSeconds`/`replaySeconds`>`totalSeconds`、相対パス、存在しない実行ファイルを blocked にする。`Test-VerificationJsonDuplicateKeys` は JSON を字句走査して同一オブジェクト内の重複キーを検出する（`ConvertFrom-Json` は重複を黙って上書きするため）。
- [x] 固定入力記録を照合する。`Request.sourceRoot` の正規化パスと `Get-VerificationSourceManifest` の正規化ハッシュを記録の `sourceRoot`/`sourceManifestHash` と比較し、不一致は blocked（VM未作成）。記録は `control/pilot-input.json` へ複製し、`pilotInputId/Path/Hash` を PreparedRunV3 に保持する。
- [x] run配置を作る。`runsRoot/<runId>/{baseline,proposal-input,quarantine,accepted,replay-inputs,temp,control/{empty-template,runtime,proposal,replay}}`。既存の `work` は v3 で作らない。`control/request.json`（受理した依頼）と `control/source-manifest.json`（v3 正規化形式）を書き、`sourceManifestPath`・`sourceManifestHash` を保持する。baselineへ実体コピーし、既存 `Initialize-VerificationHistory`（`control/empty-template` と `control/history.bundle` を使う）で独立Gitを作る。baseline全通常ファイル（.git含む）の `control/baseline-manifest.json` を書き、`baselineManifestHash` を保持する。
- [x] proposal-input を baseline のファイル単位コピーで作り、その `.git` が自分の proposalInputRoot 内を指すこと（`rev-parse --absolute-git-dir`）を検査する。原本の `.verification-tests`/`.verification-control` 衝突を拒否する。runsRoot の扱いは仕様01・v1 と同じ（`runsRoot ⊇ sourceRoot` を拒否し、原本内の runsRoot は列挙から除外する）。
- [x] recheck を実装する。`previousResultPath` は runsRoot 内で解決し、schemaVersion=3・runId・`execution.replayAllStopped=true`・`artifacts` 掲載・ハッシュ一致を確認して `accepted/tests/<path>` へ通常ファイルとしてコピーし、`control/recheck-manifest.json` と `recheckArtifacts`（kind=test、path、size、sha256、previousRunId）を作る。停止未確認・timed_out の前回結果は拒否する。
- [x] 準備後に原本を再列挙して files/head/headRef/historyRefs を比較し、変化は `source_changed`。PreparedRunV3 に `startedAt`（引数）、`deadlineAt`（+totalSeconds）、`cleanupSeconds`、各 manifest の期待hashを保持する。
- [x] `tests/RequestCopyV3.Tests.ps1` を書く。正常（新規・recheck）、未知キー、`"3"`、重複キー（生JSON文字列を `Test-VerificationJsonDuplicateKeys` に通す）、pidsキー、cpus=4、相対sbxPath、`replayProfilePath` が null の通常依頼の blocked、固定入力のhash不一致、`runsRoot ⊇ sourceRoot` の拒否と原本内 runsRoot の列挙除外、予約名衝突、コピー中の原本変更（source_changed）、recheckの改変テスト・範囲外パス・停止未確認、baselineとproposal-inputのGitが互いを指さないこと、`control/request.json`・`source-manifest.json`・`baseline-manifest.json` の存在とhash一致を扱う。期待: 全ケース成功、失敗ケースは `Data['status']` が期待値。
- [x] `pwsh -NoProfile -File scripts/verification/tests/RequestCopyV3.Tests.ps1` と既存 `RequestCopy.Tests.ps1`・`History.Tests.ps1` の成功を確認し、差分を読み直してコミットする。

逸脱記録: 実体に合わせる調整 / 採用 / 重複キー検出は手書きの字句解析器ではなく重複を保持する JsonDocument の再帰走査で実現、recheck の testPaths は前回結果の artifacts と同じ accepted 相対パス（複製先は accepted 配下の同パス）、v3 経路は StartedAt を必須にしモジュール側で現在時刻を補わない、profile パスは絶対性と再解析ポイントのみ検査し実在はタスク3の所有（2026-09-15 タスク1 実装者報告 1〜4）
逸脱記録: 実体に合わせる調整 / 採用 / recheck の前回結果で execution.proposalStopped が false のものを拒否（ブリーフの「停止未確認」の読みで仕様01 手順5「停止」照合と一致）、pilot-input の approvalReference を {path, version} のオブジェクトで定義（仕様01「パスと版またはハッシュ」の写像でタスク8b の記録雛形はこれに従う）、前回結果の status は timed_out と停止未確認のみ拒否し completed 要求は追加しない（ブリーフの列挙どおり、hash と停止の照合が拘束）（2026-09-15 タスク1 実装者報告 7〜9）
逸脱記録: 計画の範囲外の既存欠陥 / 不採用 / Issue-0146（git bundle unbundle が 260 文字に達するパックパスで失敗する v1 共有経路の欠陥、本サイクルは試験名 8 文字以下で回避し製品は変えない）

## タスク2: 対象stdinへの転送・合算出力上限・背景起動を持つプロセス実行を追加する

**依存:** なし。**対象:** `Execution.psm1`、`ProcessHost.ps1`、`tests/ExecutionV3.Tests.ps1`、`tests/fixtures/ProcessFixtureV3.ps1`。

**インターフェース:** `Invoke-VerificationProcessV3([Diagnostics.ProcessStartInfo]$StartInfo,[byte[]]$StdinBytes,[hashtable]$OutputPaths,[hashtable]$RunBudget) -> hashtable`。`OutputPaths` は `stdoutPath`/`stderrPath`（新規絶対パス）。`RunBudget` は `startedAt`/`deadlineAt`/`cleanupDeadlineAt`（work相では null 可）/`limits`（`maxOutputBytes`、当該コマンドの `commandSeconds`）/`phase`（`work` または `cleanup`）。戻り値は `started`、`exitCode`、`timedOut`、`outputExceeded`、`processTreeStopped`、`stdoutBytes`、`stderrBytes`、`stdoutHash`、`stderrHash`、`finishedAt`、`refusedReason`（未起動時。`deadline-reached` 等）。背景起動: `Start-VerificationBackgroundProcess([Diagnostics.ProcessStartInfo]$StartInfo,[hashtable]$OutputPaths,[hashtable]$RunBudget) -> BackgroundHandle`（`processId`、`jobToken`、`markerPath`、`startedAt`）、`Stop-VerificationBackgroundProcess([hashtable]$Handle,[int]$GraceSeconds) -> hashtable`（`exitCode`、`processTreeStopped`）。既存 `Invoke-VerificationProcess` は変更しない。

- [x] `ProcessHost.ps1` に制御要求の版を足す。1行目の制御JSON（`version=3`、`stdinBytesLength`）は標準入力の生ストリームから LF まで1バイトずつ読み（StreamReader の先読みで後続バイトを失わないため）、続く `stdinBytesLength` バイトを対象stdinへ転送してEOFを渡す（対象側の標準入力リダイレクトを有効にする）。制御JSONを対象stdinへ混ぜない。版なしの要求は従来どおり。
- [x] 出力コピーを容量監視つきに変える。stdout/stderr の合計が `maxOutputBytes` を超えた時点で `outputExceeded=true` にし、ジョブを停止する。切詰めて成功にしない。
- [x] 残時間は `phase=work` なら `min(commandSeconds, deadlineAt-now)`、`phase=cleanup` なら `min(commandSeconds, cleanupDeadlineAt-now)` とする。それぞれの期限到達後は新規起動を拒否する（`started=false`、`refusedReason=deadline-reached`）。停止系コマンドだけが `phase=cleanup` を使う。
- [x] 背景起動を実装する。`Start-VerificationBackgroundProcess` は同じジョブ機構（`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`）で対象を起動し、開始マーカー確認後に待たずに戻る（ジョブは module 内の辞書に `jobToken` で保持）。`RunBudget` は起動可否（期限到達後は起動しない）にだけ使い、起動後の対象を `deadlineAt`/`cleanupDeadlineAt` で打ち切らない（保持セッションが全体期限で切れると自動停止猶予と `stop` が競合するため。ADR-0193）。`Stop-VerificationBackgroundProcess` はジョブを停止して `processTreeStopped` を返す。プロセス終了時にジョブが自動解放されるよう `Dispose` の責務を明記する。
- [x] `ProcessFixtureV3.ps1` に動作を作る: stdinを反響して終了0、stdinを読まずに終了7、無限出力、指定秒 sleep、存在しない実行ファイル（StartInfoで指定）。
- [x] `tests/ExecutionV3.Tests.ps1` で、反響が一致・終了0、stdin未読でもdeadline/cleanupを超えずに終了7、出力洪水は `outputExceeded=true` かつ `processTreeStopped=true`、時間超過は `timedOut=true`、起動失敗は `started=false`、`phase=work` で deadline 経過後は `refusedReason=deadline-reached` だが `phase=cleanup` は起動できる、背景起動した sleep を `Stop-VerificationBackgroundProcess` で止めて `processTreeStopped=true`、背景起動した対象が `deadlineAt` 経過後も生きていること（期限で打ち切られない）、ハッシュがファイル実体と一致することを確認する。
- [x] 既存 `Execution.Tests.ps1` の成功を保ち、コミットする。

逸脱記録: 実体に合わせる調整 / 採用 / 背景起動の期限到達は started キーを持たない BackgroundHandle を返せないため理由 deadline-reached の例外にする（呼出し側のタスク3は例外として扱う）、refusedReason の値域を deadline-reached・launch-failed・host-failed の3種にする（host-failed はホスト側例外で、stderr ファイルへ理由を残しファイルを開けない場合は再送出）、期限拒否時は出力ファイルとマーカーを作らない、timedOut または outputExceeded のとき exitCode は null、背景起動には出力上限を適用しない（起動可否だけに予算を使う既定どおり）、Execution.psm1 が RequestCopy.psm1 を入れ子 import して Get-VerificationUtcNow を共用（調整 (a) の共通補助の再利用）（2026-09-15 タスク2 実装者報告）
逸脱記録: 実体に合わせる調整 / 採用 / Stop-VerificationBackgroundProcess の GraceSeconds はジョブ停止後にプロセスツリーの消失を待つ上限と解釈し自然終了は待たない（保持用 sleep は自然終了しないため）、モジュール除去時に残る背景ジョブを Dispose する OnRemove を置く（Dispose の責務の明記の実現手段、プロセス終了時の自動解放と同じ帰結）、背景起動の開始マーカー待ちは期限と切り離した固定定数 30 秒（レビュー指摘を受けた修正、RunBudget は起動可否の判定のみに使う）（2026-09-15 タスク2 実装者報告、型判定候補を主担当が調整と判定）
逸脱記録: 事実誤り・期待値の陳腐化の訂正 / 採用 / 背景起動の開始マーカー読取りが ProcessHost の書込みと競合し断続失敗する不具合をタスク2の成果物が持ち込んだため修正（読取り失敗の再試行、停止時の終了記録の読み直しも同様、タスク3 実装者報告 11 で検出、タスク3 は保持起動の1回再試行で暫定吸収、修正 2187ff3）

## タスク3: sbx実行基盤を外側の記録で管理する

**依存:** タスク1・2。**対象:** 新規 `SbxRuntime.psm1`、`runtime-profile.schema.json`、`activation-evidence.schema.json`、`activation-record.schema.json`、`recovery-input.schema.json`、`recovery-result.schema.json`、`profiles/evidence-checks.md`（条件名と観測の対応表）、`tests/SbxRuntimeV3.Tests.ps1`、`tests/fixtures/FakeSbx.ps1`、`tests/fixtures/fake-sbx.cmd`、`tests/fixtures/fake-state/`、`tests/fixtures/activation-evidence.json`。実 run 用の replay profile 一式（`profiles/replay/profile.json`、`activation-evidence.json`、`stdlib-modules.txt`）はタスク8で生成し、`Settings.replayProfilePath` が指す。

**インターフェース（仕様02の公開操作）:** `Test-VerificationRuntimeProfile([hashtable]$Profile,[string]$Role,[hashtable]$Settings)`、`Acquire-VerificationPilotLease([hashtable]$PreparedRun) -> Lease`（内部で `runId` と `daemonKey` だけを受ける経路を持ち、PreparedRun を持たない復旧操作はそれを使う）、`Release-VerificationPilotLease([hashtable]$Lease)`、`New-VerificationSandbox([hashtable]$PreparedRun,[string]$Role,[hashtable]$Profile,[hashtable]$Lease) -> SandboxHandle`、`Copy-VerificationSandboxInput($Handle,[string]$TrustedInputRoot,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Confirm-VerificationSandboxInput($Handle,[string]$Destination,[hashtable]$ExpectedManifest,[hashtable]$RunBudget)`、`Invoke-VerificationSandboxCommand($Handle,[string[]]$Argv,[byte[]]$StdinBytes,[string]$WorkingDirectory,[hashtable]$Environment,[hashtable]$RunBudget,[hashtable]$OutputSignature) -> CommandRecord`（`OutputSignature` は `{pattern, stream}` の hashtable〈stream は `stdout`/`stderr`〉または署名を要求しない場合は `$null`。仕様02の列挙に無い追加引数。調整 (j)）、`Stop-VerificationSandbox($Handle,[hashtable]$RunBudget) -> hashtable`（`RunBudget.phase=cleanup`）、`Stop-VerificationRecordedSandboxes([string]$RunRoot,[hashtable]$RecoveryInput) -> RecoveryResult`（ADR-0194。`RecoveryInput` は `recovery-input.schema.json`〈schemaVersion=3・sbxPath・pwshPath・runsRoot・limits〉で、SettingsV3 ファイルから4項目を読み取り schemaVersion を添えても作れる）。Roleは proposal/replay-before/replay-after（作成記録と復旧操作は足場用の `probe` も受ける）。SandboxHandleは runId、role、name、id、createdAt、profileHash、effectiveSettingsHash、activationRecordPath、activationRecordHash、keepAliveHandle。`control/runtime/<role>-sandbox.json` の作成記録は handle の JSON 化可能な項目（runId、role、name、id、createdAt、profileHash・effectiveSettingsHash・activationRecordPath・activationRecordHash は null 可。keepAliveHandle は含めない。仕様02が null 可とするのは activation 系2項目だが、profile 検査を通らない足場〈8a・タスク9の証拠取得〉の記録を同じ形式に載せるため profileHash・effectiveSettingsHash も null 可にする。復旧操作はこの2項目を参照せず、停止は name/id で行う）で、復旧操作はこの記録の runId を正本にし、keepAlive の無い handle で `Stop-VerificationSandbox` の手順を行う（保持ジョブの停止は無ければ省く）。

- [x] 偽sbxを「ファイルと責務」の記述どおりに作る。用意する応答: `daemon status --json` の stopped/running、`ls --json`、`create` の成功と500（synthetic）、`cp`、`exec`（0・7・127〈synthetic〉・137。unittest の応答は要約 `Ran N tests in …` を **stderr** に、`proposal-export.py` の JSON と Confirm の sha256 行は stdout に出す）、`stop`、`inspect --json`、`policy ls <name> --json`、`policy log <name> --json`、`settings get --json clipboard.imagePaste`（`51` の形式）、`mcp ls --json`（`50` の形式。`servers: []` は実測、1件ありは synthetic）。`daemon status --json` の `logs` はケース領域の `fake-state/` を指す。
- [x] `runtime-profile.schema.json`（schemaVersion=3、role、sbxVersion、templateDigest、agent、model〈proposalで必須、replayでnull〉、startupArgv、executableInVm、policyExpectation、mountExpectation、scope=synthetic-pilot、acceptedLimitations、stdlibModulesPath、stdlibModulesHash、activationEvidencePath、activationEvidenceHash。`additionalProperties:false`）と `activation-evidence.schema.json` を書く。evidence は checkedAt、binaries、profileHash、`checks`、`transportContrast` を持ち、**`checks` は条件名を固定した必須キー集合**とする: `daemonHealthAndTemplate`、`noWorkspaceNoSkillsNoMcp`、`hostPathIsolation`（SSH転送・ホームなど例外以外の追加ホスト経路。clipboard 画像読取無効を含む）、`resourceAndOutsideStop`、`credentialMethod`（proposalのみ必須）、`modelEndpointAllowOnly`（proposalのみ必須。承認されたモデル接続先だけを許す通信設定。タスク9で確定するまで evidence を作れない）、`replayNetworkDeny`（replayのみ必須）、`limitsAndTransport`（時間・出力上限、transport 対照、対象VMの停止確認）、`abnormalExitRecovery`（外側CLI異常後の自動停止と復旧操作、他VMの非停止、停止中の自動再起動防止）、`daemonDisconnect`（デーモン切断。存在は必須だが verdict は `unverified` を許し、verified を課さない唯一の条件。ADR-0196）。各値は `{verdict, evidencePath, evidenceHash}`。`transportContrast` は `exit0`、`exit7`、`exit127`、`timeout`、`clientKilled`（sbx クライアント子プロセスを外側から強制終了したときに**外側が観測する**終了コードと stderr の型。デーモン切断とは別）を必須とし、各値は観測した終了コードと stderr の型。
- [x] 条件名と観測の対応表を `profiles/evidence-checks.md` に置く（本タスクで作成。README からは参照だけ）。verified の意味は「表に書いた観測がすべて揃い、証拠ファイルの hash が一致する」に限る。表は**条件×役割（replay / proposal）**で、証拠の出所は3種を条件・役割ごとに明記する: (既存) 2026-09-14 の試験A〜Dの追跡済み記録 `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（同記録を evidencePath とし、そのファイルの hash を固定する。`.tmp/` の原文は追跡外なので evidencePath にしない。evidence に使った記録は以後追記せず、追記が必要なら profile を再生成する——README の既知の制約に書く）／(8a) タスク8a で固定argvにより取得／(9) タスク9で proposal VM を作る際に同じ手順で取得。replay 側の対応: `daemonHealthAndTemplate`＝`daemon status` running・`inspect` の `image_digest` が templateDigest と一致（8a）／`noWorkspaceNoSkillsNoMcp`＝`runtimes/<name>.json` の WorkspaceDir=""・ShareSkills=false、`mcp ls` の `servers` 空（8a）／`hostPathIsolation`＝daemon.log に `started SSH agent forwarder` 無し・SSHAgentSocketPath=""・`settings get clipboard.imagePaste` false（8a）と試験Aの拒否記録（既存）／`resourceAndOutsideStop`＝試験B・C（既存）と `runtimes/<name>.json` の CPUs=2・Memory=2g（8a）／`replayNetworkDeny`＝`policy ls` の deny `*`（8a）と試験Aの方式による拒否応答（既存）／`limitsAndTransport`＝transport 対照5種と出力洪水の打ち切り（8a）、外側 `stop` による停止確認（既存の試験C。同一固定argv・同一digest・sbx 0.42.1）／`abnormalExitRecovery`＝probe プロセス（CLI 相当）強制終了後の保持プロセス消失と自動停止、復旧操作による記録済みIDだけの停止、他VM（停止中の試験VM2台）の一覧上の不変、停止後に `exec`/`cp` を発行しないこと（8a。復旧操作は profile 検査を通らないため 8a で実行できる）／`daemonDisconnect`＝`unverified`（ADR-0196。証拠は補償機構の偽 fixture 試験の結果を指す）。proposal 側は、上記の (8a) にあたる観測をタスク9で proposal VM（agent=codex、タスク9で確定する `networkPolicy`）に対して同じ手順で取り直し、さらに試験Aのゲスト側の否定確認（SSHエージェントのソケット不在・透過プロキシの中継ポートへの応答・policy log）と試験Bのゲスト側の実効値（`nproc`・メモリ量）を数秒のコマンドで取り、`credentialMethod`・`modelEndpointAllowOnly` を加える。(既存) の流用は「負荷中の外側停止」（試験C）の1点だけとし、負荷なしの外側停止は proposal VM 自体の停止で観測する（ADR-0197。仕様00「保護条件を共用済みにしない」の例外はこの1点に限る）。`abnormalExitRecovery` も proposal VM で 8a の (1) の保持開始と (6)(7) と同じ手順（保持→probe プロセスの強制終了→保持消失→自動停止→復旧操作→他VM不変→停止後の未発行）を1回取る（役割非依存とはみなさない。replay 側の 8a の記録は proposal 側へ流用しない）。表に無い観測で verified にしない。試験A〜Cの再実施は本計画の承認に含めない（再実施を望む場合は承認区切りの拡大として利用者が指示する）。
- [x] `Test-VerificationRuntimeProfile` は、profile の schema、role整合（proposal→agent=codex、replay→agent=shell）、digest固定、`Settings.model` と profile.model の一致（proposal時）、evidence ファイルの hash 一致、evidence の schema と `profileHash` の一致、**必須条件名がすべて存在し、`daemonDisconnect` 以外は全て verified**（ADR-0196）、`transportContrast` の全項目の存在、`stdlibModulesPath` の hash 一致を検査し、`profileHash`（evidence 2項目を除いた正規化JSONのSHA256）を返す。1つでも欠ければ blocked。
- [x] `effectiveSettingsHash` を定義する: `{agent, templateDigest, cpus, memoryMiB, networkPolicy, shareSkills:false, workspace:"none", limits}` の正規化JSONのSHA256（**role を含めない**。before/after で一致すべき値。`networkPolicy` は replay で `deny *`、proposal はタスク9で通信許可が確定するまで `deny *`）。これは意図した実行条件のラベルであり、実効値の証拠は activationRecord の checks が担う。作成時に SbxRuntime が計算して activationRecord と SandboxHandle に載せ、Replay の記録と Result の照合はこの値を使う。
- [x] デーモン確認と世代取得を実装する。`daemon status --json` が running でなければ blocked（利用者の通常起動が必要と理由に書く）。`logs` から状態ディレクトリを導き、`sandboxd.pid`・`daemon.log` の最後の `starting sandboxd` 行・`Get-Process -Id` の StartTime を `daemonInstance`（pid、startedAt、version、socket）として保持する。取得不能は blocked。
- [x] pilot排他を実装する。`Local\iv-sbx-pilot-<ユーザー名とsocketのSHA256先頭16>` の名前付きMutex（同一ログオンセッション内の排他。`Global\` は非昇格プロセスで作れないため使わない）を取得し、`Lease{runId,daemonKey,leaseId}` を返す。取得競合は待たずに blocked（create 0回）。放棄されたMutexを取得した場合も一覧確認を省略しない。残余リスク: 同一ユーザーでも別ログオンセッション（別RDP・タスクスケジューラ等）からの同時実行は排他できない。`ls --json` の検査が第2の防壁だが検査と作成の間に競合窓がある。README の既知の制約に書く。
- [x] `New-VerificationSandbox` を実装する。順序: (1) Lease の有効性検査（`Lease.runId` が `PreparedRun.runId` と一致し、Mutex を保持中）、(2) VM作成前の再照合（`PreparedRun.pilotInputHash` と `control/pilot-input.json` 現物、記録の sourceRoot/sourceManifestHash と PreparedRun、`Settings.limits.cpus`=2・`memoryMiB`=2048）、(3) デーモン単位の確認（VM不要）: `settings get --json clipboard.imagePaste` の `value` が false、`mcp ls --json` の `servers` が空。不一致は VM 未作成の blocked、(4) 排他内で `ls --json` を読み、`status` が stopped 以外のVM（running、または未観測の値）があれば作らず blocked、同名があれば blocked、(5) 固定argv `create shell --name <name> --cpus 2 --memory 2g --no-share-skills --deny-network '*' --template <digest>`（proposal は agent=codex。proposal の通信許可は仕様02「承認されたモデル接続先だけの許可」に従いタスク9で確定し、それまで proposal の実VM作成は行わない。確定時に proposal 用の固定argv と `networkPolicy` を設計の変更として記録する）。sbx CLIの環境は `SystemRoot`、`PATH`（sbxの親ディレクトリのみ）、`USERPROFILE`、`LOCALAPPDATA`、`APPDATA`、`TEMP` の明示辞書で、`SSH_AUTH_SOCK` を含めない。create 応答と `ls --json` から id を確定し、`control/runtime/<role>-sandbox.json` へ保存してから activation を作る。
- [x] activationRecord を作る（runId、sandboxId、role、daemonInstance、profileHash、effectiveSettingsHash、checkedAt、checks{policy, mount, resource, credentialExposure, sshForwarding, clipboardImagePaste, mcpServers, otherVmTraffic}）。実効値の取得元: `inspect --json`（state・image_digest・network_policy・secrets・mcp_gateway）、`policy ls <name> --json`（deny `*` の存在）、状態ディレクトリの `runtimes/<name>.json`（CPUs=2、Memory=2g、ShareSkills=false、WorkspaceDir=""、SSHAgentSocketPath=""）、`daemon.log` の当該runtime行に `started SSH agent forwarder` が無いこと、(3) で取った clipboard・MCP の値の転記。`mcpServers` は ADR-0195 により登録0件で verified とし、`mcp_gateway` と `mcpgateway` secret の存在を記録する。`credentialExposure` は inspect の secrets 欄に `mcpgateway` 以外が無いことで判定する。`otherVmTraffic` は同時1VMの条件下では他に稼働VMが無いため「非該当（同時1VM）」と記録し、`ls --json` に他の running が無いことをその根拠にする。**取得できないか、期待値と一致しない場合は**、作成済みIDを保持して停止を試み（下記 Stop の手順）、`runtimeFailure{creationState=created,stopState}` を例外に載せる（停止できれば blocked、未確認なら incomplete へ写像される）。
- [x] セッション保持を実装する。作成確認後、`exec <name> sh -c 'sleep <deadlineAt + cleanupSeconds×3 までの秒数>'` を `Start-VerificationBackgroundProcess` で起動して `keepAliveHandle` に保持する。保持プロセスの終了を VM 停止の証拠にしない。
- [x] `Copy-`/`Confirm-` を実装する。cp は `cp <src> <name>:<Destination>` を1回、続けて `exec -u root <name> chown -R agent:agent <Destination>`（作成・搬入の上限式）。Confirm は `exec <name> sh -c 'cd <Destination> && find . -type f -print0 | sort -z | xargs -0 sha256sum'` の出力を外側の ExpectedManifest（path・size・sha256）と照合し、相違・欠落・予定外ファイルは blocked。
- [x] 実コマンド直前の維持確認を内部関数 `Assert-VerificationSandboxUnchanged` にまとめ、`Copy-`/`Confirm-`/`Invoke-VerificationSandboxCommand` の各呼び出し直前で実行する（仕様02「各実コマンド直前にも、同じVM id・デーモン起動世代・実効設定が維持されているか確認する」）。確認内容: `daemonInstance`（PID・StartTime）不変、`ls --json` の同一ID/running、`daemon.log` の当該runtime行に create 以後の `auto-stopped runtime` が無いこと、`inspect --json`（`state`・`image_digest`・`secrets`・`mcp_gateway`）と `policy ls <name> --json` が activationRecord の値と一致、`settings get clipboard.imagePaste` と `mcp ls` の値が作成時と一致。変化・取得不能・自動停止の痕跡があれば実行せず失敗（理由 `sandbox-restarted` または `settings-changed`）。費用は照会5本×約1〜2秒×1runあたり十数コマンドで、全体上限に対して小さい。
- [x] `Invoke-VerificationSandboxCommand` を実装する。argv は `exec -w <WorkingDirectory> [-e K=V...] <name> <argv...>` に固定し（`-w`・`-e`・`-u` はローカルヘルプで確認済み）、stdin は `Invoke-VerificationProcessV3`（`phase=work`）で転送する。CommandRecord に commandId、startedAt/finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、transportVerified を持たせる。`transportVerified` の定義: 直前の維持確認が成立し、profile の `transportContrast` が揃っており（`Test-VerificationRuntimeProfile` で確認済み）、かつ sbx クライアントの開始マーカーがあり、かつ sbx クライアント子プロセスが外側の打ち切り（`timedOut`・`outputExceeded`・`processTreeStopped`）なしに終了し、かつ**コマンド固有の出力署名**が署名の `stream` で指定したストリームに存在する場合に true（仕様04「区別できない終了は exitCode を採否へ用いず transportVerified=false」の実現手段。第5回 M-E）。出力署名は呼出し側が argv と一緒に渡す固定の `{pattern, stream}`（stream は stdout/stderr のどちらを探すか）で、unittest は **stderr** の末尾 `Ran \d+ tests? in` 行（`TextTestRunner` の既定ストリームは stderr で、成功・失敗のどちらでも出る。タスク8a の版取得でストリームを実測して確定する）、Confirm は stdout に sha256 形式の行が1行以上（件数の照合は ExpectedManifest との比較が担い、不一致は blocked のまま）、`proposal-export.py` は stdout の JSON 1行の parse 成功、`python3 --version` 等の取得系はその期待形式とする。提案本体の Codex 実行（タスク4）は出力形式が未信頼・未実測のため署名を要求せず、transport の確認は続く `proposal-export.py` の JSON で行う。cp・chown は `Copy-VerificationSandboxInput` が発行し本関数を通らないため CommandRecord を持たず、終了0以外を失敗として扱う（exitCode を観測値としては使わない）。`OutputSignature=$null` で本関数を通るのは提案本体の Codex 実行だけで、その CommandRecord は `transportVerified=null`（判定対象外）とし、`quarantine/` の診断記録に残して ready 条件・status 写像に用いない（ready 条件は仕様02のとおり Envelope の検査と停止確認で決まる）。replay 側で本関数を通るコマンド（Confirm・unittest）はすべて署名付きなので、replay-record（タスク5）の `transportVerified` は boolean のままで null は現れず、結果の照合（タスク6）は unittest の記録だけを transportVerified の判定に用いる。stderr の型との比較は行わない（実測できない基準値を判定に持ち込まないため。第4回 M-2。`transportContrast` は仕様04が求める実機対照の完備性の証拠であり、実行時の比較対象ではない）。ローカル接続失敗は署名が現れないため false になる。これは「exitCode を VM 内コマンドの終了値として読んでよい」という意味で、コマンド単位のマーカーは要求しない。
- [x] `Stop-VerificationSandbox` を実装する。呼出し側が停止フェーズの予算（`cleanupDeadlineAt = now + cleanupSeconds × 停止対象台数`。停止フェーズ開始時の現在時刻起点）を `RunBudget` に入れて渡す。`stop` 自体の上限は照会と同じ60秒。手順は「保持セッションを生かしたまま `stop <name>` を1回 → cleanupSeconds 内に `ls --json` で同一IDの `status: stopped` を確認 → 保持セッションのジョブを止める」（ADR-0193 改訂後の順序。保持を先に切ると自動停止猶予との競合が生じるため）。保持ジョブの停止は stop 確認の成否に関わらず行う。証拠は stop 発行時刻以後の `daemon.log` 当該runtime行の `stopped runtime container`（自動停止の `auto-stopped runtime after last session disconnected` は外側停止の証拠にしない）と、世代不変。未確認は `stopState=unverified`。他VMには触れない（`calls.jsonl` で当該名以外への stop が0件であることを試験する）。
- [x] `Stop-VerificationRecordedSandboxes` を実装する（ADR-0194）。手順: `daemon status --json` が running でなければ、記録済みの id/name を列挙だけして全対象 `stopState=unverified`・理由「利用者の通常起動が必要」で返す（停止中デーモンへ `ls` を発行しない。共通制約と同じ）→ `control/runtime/*-sandbox.json`（作成記録）の runId・id・name を読む → その runId と `daemonKey` で内部経路の `Acquire-VerificationPilotLease` を取る（競合時は「稼働中のrunがある」として何もせず blocked）→ 現在時刻を起点に新しい予算（`startedAt=now`、`deadlineAt=now`、`cleanupDeadlineAt=now + cleanupSeconds×対象台数`、`phase=cleanup`）を組む → `ls --json` で running の対象だけに `Stop-VerificationSandbox` の手順を適用 → Lease を解放 → 結果を `recovery-result.schema.json`（schemaVersion、runId、checkedAt、daemonRunning、targetCount、targets[{name,id,stateBefore,stopState,evidencePath}]、lease）どおりに `control/runtime/recovery-<時刻>.json` へ CreateNew で保存し、同じ内容を返す。記録が0件のときは `targetCount=0` を返し、「作成記録を書く前に失われたVMは対象外で、`ls` の検査で後続runが blocked になる場合は利用者が名指しで `sbx stop` する」を README の既知の制約に書く。VerificationResultV3 を名乗らない。記録に無いVMには触れない。
- [x] `tests/SbxRuntimeV3.Tests.ps1` で、デーモン停止時 blocked、running/同名ありで create 0回、Lease 不一致で create 0回、VM作成前の固定入力不一致・clipboard.imagePaste=true・mcp 登録1件で create 0回の blocked、create 500 で not-created、id確定後の inspect 失敗と policy 不一致の両方で停止試行と `runtimeFailure.creationState=created`、Mutex競合で blocked、evidence の必須条件名欠落・verdict 非 verified・model 不一致で profile 拒否、daemon.log に `started SSH agent forwarder` がある場合の blocked（作成済みなら停止試行）、Confirm の欠落・予定外ファイル、実コマンド前の世代変化・自動停止痕跡・`inspect`/`policy`/`settings`/`mcp` の値変化で実行拒否、出力超過での停止、stop 未確認で unverified、自動停止行だけでは stopped と判定しない、run途中の停止予算が現在時刻起点の台数分であること（全体期限までの残時間を含まない）、停止対象2台で予算が台数分に延びること、`calls.jsonl` に `SSH_AUTH_SOCK` が無く当該名以外への stop が無いこと、停止確認後に当該名への `exec`/`cp` が0件であること（停止中の自動再起動防止）、照会・作成の定数上限を超える遅延で `timedOut`・`runtimeFailure` になること（定数の時間上限。定数は SbxRuntime の script スコープ変数で、試験だけが小さい値へ差し替える。CLI 入力や子からは変更できない）、`Invoke-VerificationSandboxCommand` が署名を指定ストリームに持たない出力で `transportVerified=false` を返すこと（署名が別のストリームにだけある場合も false）、復旧操作がデーモン停止時に `ls` を発行せず unverified で返すこと・Lease 競合で何もしないこと・記録外のVMに触れないこと・記録0件で `targetCount=0` を返すこと・新しい予算で停止できることを確認する。すべて偽sbxと `fake-state/` で、実VMは作らない。
- [x] 試験成功後にコミットする。偽sbxの成功を実機の保護実証に数えない。

逸脱記録: 実体に合わせる調整 / 採用 / 偽sbxの応答組み立てを試験補助 FakeSbxScenario.psm1 と fake-sbx-responses に集約、runtimeFailure は Data の値を正規化JSON文字列で格納し reason は短い符号、profile と evidence 内の相対パスはそれぞれのファイルのディレクトリ基準で解決、作成記録は id 確定時に新規作成し activation 確定後に activation の2項目だけ書き足す、コマンド出力の置き場は署名ありで control/runtime 配下・署名なしで quarantine 配下、Stop の戻りに停止発行時刻と停止証拠ファイルを持たせる、試験用 evidence は雛形、試験は自分が起動した偽sbxの PID だけを後片付け（2026-09-15 タスク3 実装者報告 1〜8）
逸脱記録: 実体に合わせる調整 / 採用 / 公開補助 Write-VerificationSandboxRecord（タスク8a の probe が作成記録を同形式で書くため）と New-VerificationCleanupBudget（停止フェーズ予算の式をタスク4・5・7 で共有するため）を追加、Test-VerificationRuntimeProfile は各 check の evidencePath 実在と evidenceHash 一致まで検査（evidence-checks.md の verified の定義の機械化）、New-VerificationSandbox は作成前に profile 検査を再実行（仕様02「不一致なら作業解放前に blocked」の実現）。いずれも保護の緩和・schema・固定 argv・既存公開操作の署名に触れない（2026-09-15 タスク3 実装者報告 9・12・13、主担当が調整と判定）
逸脱記録: 実体に合わせる調整 / 採用 / 保持セッションの起動を1回だけ再試行（開始マーカー読取り競合の暫定吸収）、停止確認済みの handle への再 Stop は発行せず前回結果を返す、Copy は cp 前にホスト側の搬入元を ExpectedManifest と照合（不一致は input-changed）、create の成功判定に stdout の作成メッセージを要求、同じ役割の作成記録が既にあれば create 前に blocked、復旧操作は作成記録の runId が複数 run にまたがると blocked。いずれも保護を弱めない（2026-09-15 タスク3 レビュー本体側で記録外として検出、主担当が調整と判定）
逸脱記録: 実体に合わせる調整 / 採用 / 偽の状態ディレクトリは fake-state の複製ではなく応答雛形からケースごとに生成、runtime ファイルの雛形は判定に使わない Services.Domains・AuthConfig・ProxyEnvVars を削る、修正ラウンド1で create 発行直前に creationState を unknown にし未作成と推定するのは起動前の期限拒否と一覧で不在を確認しクライアントが確定終了した場合だけ（host-failed と出力超過も unknown）、runtime ファイルは ID と判定5キーの存在と型を必須化、偽sbxの calls.jsonl は書き手が共有 Read と再試行・読み手が共有 ReadWrite、保持セッション停止の試験確認は保持対象プロセスの消失と後片付け後の残存 0（偽sbx本体の MSIX 版 pwsh がジョブに入らないため、Issue-0147 に記録）（2026-09-15 タスク3 レビュー試験側の記録外指摘と修正ラウンド1 実装者報告、主担当が調整と判定）
逸脱記録: 計画の範囲外の既存欠陥 / 採用 / Issue-0147（MSIX 版 pwsh の ProcessHost で非パッケージの子がジョブに入らず停止が sbx.exe に届かない。不在の根拠は同 Issue、同一領域を触るタスク2修正とタスク8a が計画内にあるため統合採用し Execution.psm1・ProcessHost.ps1 を修正）

## タスク4: 提案VMの起動・回収・未信頼Envelopeの検査を実装する

**依存:** タスク1・3。**対象:** 新規 `Proposal.psm1`、`proposal.schema.json`、`proposal-export.py`、`tests/ProposalV3.Tests.ps1`。

**インターフェース:** `Invoke-VerificationProposal([hashtable]$PreparedRun,[hashtable]$Profile,[hashtable]$Lease) -> ProposalResultV3`（schemaVersion、runId、status、origin、sandbox、summary、findings、artifacts、manifestPath、manifestHash、testsManifestHash、stopState、failure）。内部: `Test-VerificationProposalEnvelope([byte[]]$Wire,[hashtable]$PreparedRun) -> hashtable`（検査済み一覧）、`Write-VerificationAcceptedFiles`。

- [ ] recheck 経路を先に実装する。`recheckArtifacts` が非空なら VM・モデルを起動せず、`origin=reused-tests`、`sandbox=null`、`stopState=not-created`、`artifacts` は前回hashのまま、`manifestPath` は `control/proposal/manifest.json` を新規作成して返す。
- [ ] `proposal-export.py` を書く。VM内で `/home/agent/workspace/proposal/` 配下の `tests/test_*.py`・`tests/__init__.py`・`replacements/**/*.py` と `proposal.json`（summary、findings）を読み、`{"schemaVersion":3,"runId":...,"summary":...,"findings":[...],"files":[{"kind","path","contentBase64"}]}` を stdout へ1行で出す。自身は標準ライブラリだけを使い、上限を超えるファイルは含めずに `truncated` を立てる（外側はそれを拒否理由にする）。
- [ ] 提案経路を実装する。`New-VerificationSandbox proposal` → `Copy-`/`Confirm-`（proposal-input を `/home/agent/workspace/source` へ）→ 依頼文（目的・合格条件・作業先 `/home/agent/workspace/proposal`・書式・禁止事項・残り時間〈proposalSeconds と全体期限から算出した秒数。助言であり強制は外側の上限で行う〉）を `startupArgv` の Codex へ stdin で渡す `Invoke-VerificationSandboxCommand`（proposalSeconds、`OutputSignature=$null`。CommandRecord は `transportVerified=null` で `quarantine/` に置き、ready 条件に使わない）→ `proposal-export.py` を cp して `python3` で実行（stdout 上限 maxWireBytes、署名は JSON 1行の parse 成功）→ 停止。子の実行イベントと最終応答は `quarantine/` に未信頼データとして保存する。
- [ ] `Test-VerificationProposalEnvelope` を実装する。wire容量→重複キー・深さ・未知キー・型→runId→件数（maxProposalFiles）→path規則（UTF-8 POSIX相対、絶対・ドライブ・UNC・空成分・`.`・`..`・バックスラッシュ・コロン・NUL・末尾空白/ドット・Windows予約名、大小文字無視の重複、親子衝突、`.git`/`.codex`/`.claude`/`.agents`/`.mcp.json` 配下）→kind（test は `tests/` 接頭辞なしの相対名で `test_*.py`/`__init__.py`、replacement は baseline に存在する `.py` 通常ファイル）→base64正規性→復号後サイズ（maxFileBytes・maxProposalBytes）→UTF-8テキスト、の順に検査し、最初の違反で全体を拒否する。test 0件は拒否、replacement 0件は再現のみとして許す。
- [ ] `accepted/tests/<path>`・`accepted/replacements/<path>` を CreateNew で生成し、祖先にリンク・再解析ポイント・既存ファイルがあれば拒否する。外側でサイズ・SHA256を計算して `control/proposal/manifest.json` に保存し、`manifestHash` を返す。`testsManifestHash`（testの相対パス・サイズ・SHA256をパス順に正規化したSHA256）も保存する。
- [ ] 停止確認後に `status=ready`。停止未確認は受信済みでも `incomplete`（`stopState=unverified`）。時間超過は `timed_out`。`runtimeFailure` は捕捉して `sandbox` に確定済みhandleを残す。
- [ ] `tests/ProposalV3.Tests.ps1` で、recheck が VM 0回、正常Envelope が ready、架空runId、リンク相当パス、`..`、予約名、大小文字重複、過大wire、復号後超過、途中切断（不完全JSON）、test 0件、replacement が baseline に無い、非.py、停止未確認 → incomplete、`quarantine` 保存を確認する。実Codex・実VMは起動しない。
- [ ] コミットする。

## タスク5: 通信なしVMでの修正前後の再実行と外側記録を実装する

**依存:** タスク1・3・4。**対象:** 新規 `Replay.psm1`、`replay-record.schema.json`、`tests/ReplayV3.Tests.ps1`、`tests/fixtures/pilot-source/`（`calc.py` に既知の欠陥、`test_calc.py` が before で非0・after で0 になる合成題材と、その `replacement` 版）、`tests/fixtures/stdlib-modules.txt`（試験専用。実runは profile の一覧を使う）。

**インターフェース:** `Invoke-VerificationReplay([hashtable]$PreparedRun,[hashtable]$ProposalResult,[hashtable]$Profile,[hashtable]$Lease) -> ReplayResultV3`（schemaVersion、runId、status、mode、sandboxes、before、after、allStopped、failure）、`New-VerificationReplayNotRun([hashtable]$PreparedRun,[hashtable]$Failure) -> ReplayResultV3`。

- [ ] 合成題材を確認する。ホストに Python 3 があれば `pilot-source` で before（原文）が非0、after（replacement 適用）が 0 になることを1回実行して記録する（無ければ未確認と記し、タスク8で確認する）。ホストでの実行は固定の題材に限り、回収物には適用しない。
- [ ] 入力検査を実装する。`ProposalResult.status=ready`、runId一致、`manifestHash` と `accepted` 現物の再照合、origin ごとの sandbox/stopState 条件、baseline の全ファイル manifest と期待hash の照合。不成立は blocked。
- [ ] `replay-inputs/before` と `after` を外側で作る。before は baseline の作業ファイル（`.git` を除く）、after は同じファイルへ検査済み replacement を適用したもの。生成後に before と after の全ファイル差分を取り、(i) 差分のパス集合が replacement 一覧に**含まれる**こと、(ii) 各 replacement の after 側の内容が accepted のバイトと一致すること、を確認する（内容が基準版と同一の replacement は差分に現れなくてよい。不成立は incomplete）。両方の `.verification-tests/` に同じ tests を置き、各入力の manifest（path・size・sha256）と `testsManifestHash` を保存する。mode は replacement なしで `reproduction-only`、ありで `candidate-comparison`、recheck で `recheck`（現在版を after とし before=null。recheck では (i)(ii) の差分照合を適用せず、`testsManifestHash` の一致と baseline manifest の照合だけを行う）。
- [ ] 標準ライブラリ検査を実装する（VM不要）。accepted の tests と replacements の `import` 対象を静的に列挙し、replay profile の `stdlibModulesPath`（テンプレート内 `python3` の `sys.stdlib_module_names` をタスク8で取得した固定一覧。`profileHash` の対象）と題材内モジュールの集合に照合して、外にあるモジュールがあれば VM 未作成の blocked。実行中に依存を取得しない。
- [ ] 役割ごとに新規VMを順に使う。mode で分岐する: candidate-comparison は before → after、reproduction-only は before のみ、recheck は after のみ（仕様04「修正候補がない初回は before のみ実行」、タスク6の照合と対称）。各役割は `New-VerificationSandbox replay-<role>` → Copy/Confirm（`/home/agent/workspace/source`）→ 固定argv `["python3","-m","unittest","discover","-s",".verification-tests","-p","test_*.py","-v"]` を `WorkingDirectory=/home/agent/workspace/source`、Environment は profile の最小辞書、出力署名 `{pattern: 'Ran \d+ tests? in', stream: stderr}` で実行（replaySeconds）→ 停止確認。before の停止未確認なら after を作らず返す。
- [ ] 各コマンドを `control/replay/<role>/<commandId>.json` へ `replay-record.schema.json` どおり保存する（runId、role、sandboxId、profileHash、effectiveSettingsHash、templateDigest、sourceManifestHash、inputManifestHash、testsManifestHash、argv、workingDirectory、startedAt、finishedAt、exitCode、stdout/stderr のパスとhash、timedOut、outputExceeded、stopVerified、transportVerified、activationRecordPath/Hash、limits）。
- [ ] `New-VerificationReplayNotRun` を実装する（status=not_run、sandboxes=[]、before/after/allStopped=null、failure に上流段階）。作成成否不明は not_run へ丸めず `failure.reason=creation-unresolved` で incomplete。
- [ ] `tests/ReplayV3.Tests.ps1` で、偽sbx が before（VM名 `-before`）に終了1・after（`-after`）に終了0 を返すケースで `completed`（合否は付けない）、reproduction-only で after VM が作られないこと・recheck で before VM が作られないこと、unittest の署名が stderr に無い出力（接続失敗の模擬。stdout にだけ署名がある場合を含む）で incomplete、before 0 の非再現、after 非0、テスト集合が before/after で異なる入力の拒否、after の差分が replacement 一覧に無いパスを含む入力の拒否、replacement が after に反映されていない入力の incomplete、内容が同一の replacement を含む入力が incomplete にならないこと、recheck で差分照合を行わないこと、標準ライブラリ外 import の VM 未作成 blocked、別 digest の profile 拒否、before 停止未確認で after 未作成かつ incomplete、偽成功文字列（stdout に "OK" だが終了1）が終了コードを覆さないこと、出力洪水で incomplete、時間超過で timed_out かつ停止コマンドが `phase=cleanup` で発行されること、`not_run` の書式、各役割の sandbox id が相異なり `effectiveSettingsHash` が一致すること、当該名以外への stop が0件であることを確認する。
- [ ] コミットする。

## タスク6: 3入力を外側の記録で照合し結果を返す

**依存:** タスク1・4・5。**対象:** `Result.psm1`、`result.schema.json`（v1/v3を `if/then` で分岐）、`tests/ResultV3.Tests.ps1`。

**インターフェース:** `Complete-VerificationRun` は2引数で既存 `Complete-LegacyVerificationRun`、3引数（PreparedRunV3、ProposalResultV3、ReplayResultV3）で v3 照合。`New-VerificationFailureResult([hashtable]$RequestContext,[hashtable]$Failure) -> VerificationResultV3`。

- [ ] `result.schema.json` に v3 定義（schemaVersion、runId、status、summary、sourceState、baselineState、proposalVerdict、replayVerdict、checks、findings、artifacts、unverified、execution、previousRunId、runRoot、sourceManifestPath、scope、limitations。`additionalProperties:false`）を足し、v1 定義は保つ。`execution` は proposalCreated、replayCreatedCount、proposalStopped、replayAllStopped、failureStage、exitCodeForCli、pilotInputId、pilotInputPath、pilotInputHash を持つ。
- [ ] 照合手順1〜7（仕様03）を実装する。順序は schemaVersion/runId → activationRecord と profileHash/effectiveSettingsHash/sandboxId/daemonInstance（before/after の effectiveSettingsHash 一致は before と after の両方がある mode=candidate-comparison のときだけ。reproduction-only は before のみ、recheck は after のみを照合）→ manifest 期待hash と現物（source・baseline・recheck・proposal） → 原本再列挙 → accepted・replay input・testsManifestHash → （mode=candidate-comparison のときだけ）before/after の差分が replacement 一覧に含まれ、各 replacement が適用されていること → 外側記録（runId/role/VM id/argv/時刻/hash/transportVerified/停止）→ 停止記録の必須化 → 観測分類。証拠パスは control 内だけを許す。
- [ ] status の優先順位（timed_out → incomplete〈作成不明・作成済みの停止未確認・基準版改変〉→ blocked → source_changed → incomplete〈その他〉→ completed）と、Proposal/Replay の status 写像、`not_run` の上流追従を実装する。scope 付与前に pilotInputHash と記録現物、sourceRoot/sourceManifestHash を再照合し、`execution` に pilotInputId/Path/Hash を載せる。
- [ ] `replayVerdict` の観測分類（candidate-supported / not-reproduced / still-failing / reproduced / current-pass / current-fail / undetermined）と、completed 時の CLI終了値（0/1）を `execution.exitCodeForCli` として返す。
- [ ] `New-VerificationFailureResult` を実装する（runId/runRoot/sourceManifestPath/previousRunId=null、sourceState/baselineState=unreadable、proposalVerdict=null、replayVerdict=undetermined、空配列、execution は proposalCreated=false・replayCreatedCount=0・停止値null・失敗段階・pilotInput 3項目は判明していれば値/なければ null、判明済みVM情報があれば保持）。
- [ ] `control/result.json` を CreateNew で一度だけ保存し、既存があれば例外にして保全する。
- [ ] `tests/ResultV3.Tests.ps1` で、正常（candidate-supported、終了0）、still-failing（終了1）、reproduction-only、recheck の current-pass/current-fail、架空 commandId、別 sandboxId/世代、before/after の effectiveSettingsHash 不一致、自己申告 pass だけの入力、基準Git改変（incomplete）、原本更新（source_changed）、出力欠落、同一テストでない比較、after の差分が replacement 一覧を超える入力、停止未確認（incomplete かつ blocked より優先）、not_run 追従、失敗結果の null 書式、既存 result.json 保全、schema 適合（execution の pilotInput 3項目を含む）を確認する。
- [ ] 既存 `Result.Tests.ps1` の成功を保ち、コミットする。

## タスク7: 共通CLIで4責務を結合し、既存試験群へ組み込む

**依存:** タスク1〜6。**対象:** 新規 `Invoke-IsolatedVerification.ps1`、`tests/CliV3.Tests.ps1`、変更 `README.md`、`tests/Run-IndependentTests.ps1`。

**インターフェース:** `pwsh -NoProfile -File scripts/verification/Invoke-IsolatedVerification.ps1 -RequestPath <json> -SettingsPath <json>`。stdout に VerificationResultV3 の JSON 1件、stderr に診断。終了値は completed なら判定（0/1）、それ以外 2。復旧用の別入口 `-StopRecorded -RunRoot <path> -SettingsPath <json>`（ADR-0194。`-SettingsPath` は SettingsV3 でも縮約入力でも受け、CLI が sbxPath・pwshPath・runsRoot・limits の4項目に schemaVersion=3 を添えて `recovery-input.schema.json` で検査し `RecoveryInput` を組む。VMを作らず、`Stop-VerificationRecordedSandboxes` の結果〈recovery-result〉を stdout に返す。終了値は全対象 stopped で 0〈記録0件も 0 だが `targetCount=0` を stdout の結果と stderr に出す〉、それ以外 2）。CLIは開始直後に runRoot を stderr へ表示し、結果JSONが返らなくても復旧操作に必要なパスが分かるようにする。

- [ ] 入力読込（`Test-VerificationJsonDuplicateKeys` で重複キー検査）→ `startedAt` 確定 → `New-VerificationRun`（失敗は `New-VerificationFailureResult`）→ `Test-VerificationRuntimeProfile`（replay は常に、proposal は非recheck時）→ `Acquire-VerificationPilotLease` → `Invoke-VerificationProposal` → ready なら `Invoke-VerificationReplay`、非ready なら `New-VerificationReplayNotRun` → `Complete-VerificationRun` → `finally` で作成済みVMの停止確認（未停止があれば停止フェーズの予算〈台数分〉を組んで `Stop-VerificationSandbox` を再試行）と `Release-VerificationPilotLease`。準備後の例外は判明済みVM情報を RequestContext に足して失敗結果へ。
- [ ] 開始時に scope と acceptedLimitations（clipboard文字列書込の可能性・プロセス数上限なし・デーモン切断は未確認）と runRoot を stderr に表示する。clipboard の読取・退避・復元・消去はしない。
- [ ] 全体 deadline を単調時計で監督し、到達後は新規VM作成・搬入・execを行わず停止処理だけ停止フェーズの予算まで許す。
- [ ] `tests/CliV3.Tests.ps1` で、偽sbx と `tests/fixtures/pilot-source`（ケース領域の独立 Git 作業ツリーへ複製して初期コミットしたもの）を使い、正常往復（stdout JSON 1件・終了0）、still-failing（終了1）、固定入力不一致（blocked・終了2）、デーモン停止（blocked・理由に通常起動）、Lease競合（blocked）、提案非ready→replay not_run、途中失敗時の Lease 解放と作成済みVMの停止発行、deadline 到達後に stop だけが台数分の予算で発行されること、`-StopRecorded` が記録済みIDだけを停止し記録外のVMに触れないこと・Lease競合時に何もしないこと・入力が recovery-input の schema で検査され不足キー（schemaVersion 欠落を含む）で終了2になること・出力が recovery-result の schema に適合すること、開始直後の stderr に runRoot が出ることを確認する。
- [ ] `Run-IndependentTests.ps1` に v3 の7群（RequestCopyV3、ExecutionV3、SbxRuntimeV3、ProposalV3、ReplayV3、ResultV3、CliV3）を足し、出力を「11 suites passed」にする。README に v3 の使い方、前提（利用者起動のデーモン）、既知の制約（自動停止・clipboard例外・デーモン切断未確認・pilot限定・別ログオンセッションからの同時実行は排他できない・作成記録前に失われたVMは復旧操作の対象外・evidence に使った実験記録は追記しない〈追記時は profile 再生成〉・残置VMの後片付けは利用者承認の `sbx rm`）、`profiles/evidence-checks.md`（verified の意味）と `profiles/replay/` への参照を書く。
- [ ] 11群成功を確認してコミットする。

## タスク8: AIなしで実VMの再実行・停止・記録を実証する（個別承認）

**依存:** タスク7。**対象:** 新規 `tests/Invoke-SbxPilotProbe.ps1`、`profiles/replay/`（`profile.json`、`activation-evidence.json`、`stdlib-modules.txt`。既存記録 `docs/records/experiments/2026-09-14-v3-capability-test-methods.md` を evidencePath に使う条件はその hash を固定する）、実験記録。

本タスクで実証できる範囲: SbxRuntime の公開操作（profile 検査を含む）を replay 用の2台で動かすところまで。`Invoke-VerificationReplay` 全体の実機実証は、ready な提案（origin=generated）が提案VM無しには作れないためタスク9で初めて成立する（recheck も前回結果を要するため同じ）。V4 の「別VM・通信なしで before 非0/after 0」は本タスクでは公開操作の直接呼び出しで取り、Replay の統合はタスク9で取る（第4回 C-1）。

- [ ] 提示する: VM名（8a は足場 run の `iv-<runId8>-probe`、8b は別の足場 run の `iv-<runId8>-before/after`）、固定argv、搬入する `pilot-source` の内容とhash、実行コマンド、停止手順、transport 対照（終了0・固定7・存在しないコマンド127・時間超過・sbx クライアント子プロセスの強制終了）、出力洪水の `exec` 1本（`maxOutputBytes` で打ち切る）、合成題材の搬入（`cp`・`chown`）と unittest 1本、約30分の連続保持、probe プロセス（CLI 相当）の強制終了と復旧操作（ADR-0194）、取得する証拠（`python3 --version`、`sys.stdlib_module_names` の一覧、unittest 要約行の出力ストリーム、`settings get`・`mcp ls`・`inspect`・`policy` の出力、`runtimes/<name>.json`、daemon.log の当該行）、所要見込み。他VM（停止中の試験VM2台）の状態は `ls --json` の一覧読取りだけで確認し、当該名への `inspect`・`exec`・`cp` は発行しない（停止VMへの `inspect` が自動起動するかは未実測のため）。試験A〜C（否定試験・負荷試験）は再実施せず既存記録を証拠にする。デーモン停止中なら利用者の通常起動を先に依頼する。承認後にだけ進む。
- [ ] **足場**: probe は 8a と 8b で**別々の** run を準備する（8a は約30分の保持で synthetic-pilot の totalSeconds=1800 を使い切るため、同じ PreparedRun を 8b に持ち越すと期限到達で作成・搬入・実行が拒否される）。8a 用: `tests/fixtures/probe-settings.json`（`recovery-input.schema.json` で検査する縮約入力の雛形。schemaVersion=3・sbxPath・pwshPath・runsRoot・limits。limits は synthetic-pilot の固定値に `totalSeconds=3600` を上書きした試験足場の値で、実 run には使わない）を読み、probe が UUID の runId を発番して `runsRoot/<runId>/` を作り、`control/probe-run.json`（schemaVersion、runId、startedAt。schema ファイルは置かず probe 内の固定形式）と `control/runtime/probe-sandbox.json`（作成記録の項目集合どおり。runId・role=probe・name・id・createdAt を持ち、profileHash・effectiveSettingsHash・activationRecordPath・activationRecordHash は null）を書く。復旧操作は sandbox 記録の runId を使うので、この runRoot でそのまま動く。probe が発行する全コマンドは `Invoke-VerificationProcessV3`（`phase=work`、予算 `startedAt=now`・`deadlineAt=now+3600`）で実行する。各観測は取得の都度 runRoot 配下へファイルとして書き、`-Resume <runRoot>` は保存済み観測を読み直して続きから進む（probe 強制終了で (1)〜(5) の観測を失わないため）。`-Resume` は当該VMへ `exec`/`cp` を発行せず保持も再開しない（daemon.log と `ls --json` の読取り、復旧操作だけを行う）。自動停止痕跡などでやり直す場合は新しい runId・新しい runRoot で最初から行い、旧 runRoot の観測は evidence に使わない（VM名の衝突と別ブートの観測の混入を避ける）。8b 用: 8a 完了後に `New-VerificationRun` で通常の SettingsV3 を使って run をもう1つ準備し、その runRoot・PreparedRun・Settings を公開操作へ渡す。8b 用の request・settings・pilot-input 記録は `tests/fixtures/pilot-run/` に**雛形**として置き、probe が実行時に絶対パス（sbxPath・pwshPath・runsRoot・profile パス・sourceRoot）と `sourceManifestHash` を埋めて `runsRoot` 配下の一時領域へ実体化する（仕様01「各パスは絶対」のため fixture に絶対パスを書けない。`probe-settings.json` も同じ雛形方式）。`pilot-source` は独立した Git 作業ツリーへ複製して初期コミットしてから sourceRoot にする（v1 の `sourceRoot must be Git worktree root` 検査と、リポジトリ本体の履歴の混入を避けるため。CliV3 試験も同じ扱い）。複製先は runsRoot の**外**（runsRoot の親ディレクトリ配下の `pilot-source-<runId8>/`。仕様01「runsRoot が sourceRoot を包含する設定を拒否する」のため）。（`replayProfilePath` は 8a が生成した `profiles/replay/`、`proposalProfilePath` はタスク9まで未生成の固定パス `profiles/proposal/profile.json`〈8b は CLI を通らず proposal の profile 検査を呼ばないため存在不要〉、`model` は 8b で使わない固定の識別子、request と pilot-input 記録の sourceRoot はどちらも上記の複製先の絶対パス〈probe が実行時に埋める。両者が一致しないと固定入力照合で blocked になる〉、approvalReference はタスク8の承認記録）。復旧操作は結果を返す前に Lease を解放する（タスク3の手順に明記）。
- [ ] **8a: 証拠の取得（SbxRuntime の公開操作を通さない）**。`Invoke-SbxPilotProbe.ps1` は承認済みの固定argvを直接組み立てて、probe VM 1台で次を順に取る: (1) create の直後に保持用 `exec … sleep` を probe のジョブ配下で起動し（`Start-VerificationBackgroundProcess`。以後の (2)〜(5) はこの保持の下で行い、非保持の区間で30秒自動停止・自動起動が挟まって別ブートの観測が混ざるのを防ぐ）、`python3 --version`・`sys.stdlib_module_names`、合成題材 `pilot-source` を `cp` で `/home/agent/workspace/source` へ搬入して `exec -u root … chown` し（固定argv、上限は全域表の作成・搬入240秒）、作業ディレクトリをそこにして `python3 -m unittest discover -s .verification-tests -p 'test_*.py' -v` を1本（要約 `Ran N tests in` がどのストリームに出るかを実測し、出力署名の `stream` を確定する。tests は `pilot-source` の `test_calc.py` を `.verification-tests/` に置いて搬入する）→ (2) transport 対照5種（終了0・固定7・存在しないコマンド127・時間超過〈replaySeconds で打ち切る〉・sbx クライアント子プロセスの強制終了〈この対照だけ `Start-VerificationBackgroundProcess` で発行し、開始マーカー確認後に `Stop-VerificationBackgroundProcess` でその `processId` だけを止め、戻り値の `exitCode` と `OutputPaths` の stderr を観測にする。(1) の保持セッションは対象にしない。この1本は背景起動のため期限監督の対象外で、打ち切りは probe 自身の停止呼び出しで行う〉）→ (3) 出力洪水の `exec` 1本を `Invoke-VerificationProcessV3` の `maxOutputBytes` で打ち切る（`outputExceeded=true`、当該 exec のプロセスツリーだけ停止。本番と同じ機構で観測する）→ (4) 各照会（`inspect`・`policy ls`・`settings get`・`mcp ls`・`runtimes/<name>.json`・daemon.log の当該行）。(1)〜(4) の各観測の前後で daemon.log の当該runtime行に create 以後の `auto-stopped runtime` が無いことを確認し、あれば 8a を新しいVMでやり直す → (5) 連続保持の確認（ADR-0193）: (1) で始めた保持の累積が約30分（totalSeconds 相当）に達するまで保ち、その間に数回 `ls --json` で running を読み、保持開始時刻以後の daemon.log 当該runtime行に自動停止・切断の記録が無いことを確認する（切れた場合は保持方式の見直しへ戻す）→ (6) **probe プロセス自体（CLI 相当）を外から強制終了**し、ジョブ配下の保持 exec が消えて約30秒後に `auto-stopped runtime` 行が出ることを、再起動した probe（`-Resume <runRoot>`）が観測する（ADR-0194 Decision「CLIプロセスの強制終了後の自動停止」。`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` の伝播の実証）→ (7) 再起動した probe が `control/runtime/probe-sandbox.json`（8a 開始時に書いた記録）を使って `Stop-VerificationRecordedSandboxes` を実行し、記録済みIDだけを扱うこと、自動停止済みなら `ls` で stopped を確認するだけであること、`recovery-result` が保存されること、停止中の試験VM2台が `ls --json` の一覧で不変であること、停止後に当該名へ `exec`/`cp` を発行していないことを外側の呼び出し記録で確認。得た観測から `profiles/replay/` の profile・`activation-evidence.json`（`transportContrast` と `evidence-checks.md` の対応どおり。既存記録を出所とする条件はそのファイル hash）・標準ライブラリ固定ファイルを生成する。`Test-VerificationRuntimeProfile` は evidence が揃う前に通らないため、この段だけは公開操作を使わない（未実測のまま verified を書き込まない。復旧操作は profile 検査を通らないため使える）。外側からの `stop` による停止確認は同一固定argv・同一digest の既存記録（試験C）を証拠にし、8a では取らない（自動停止の観測と同一VMで両立しないため）。偽sbxの synthetic 応答のうち exec 127・クライアント強制終了は実測形式へ差し替える。
- [ ] **8b: 公開操作の実証**。8a で生成した profile が `Test-VerificationRuntimeProfile` を通ることを確認し、8b 用に新しく準備した run（PreparedRun・runRoot・Settings）と probe が外側で組んだ入力（`pilot-source` の before と replacement 適用後の after、tests）を使って SbxRuntime の公開操作を直接呼ぶ: `Acquire-VerificationPilotLease` → `New-VerificationSandbox replay-before` → Copy/Confirm → unittest の `Invoke-VerificationSandboxCommand` → `Stop-VerificationSandbox`（`stop` → `ls` 確認 → 保持ジョブ停止の順）→ after を同様に → Lease 解放。before 非0・after 0、各役割の新規 id、activationRecord の生成、外側 `stop` による停止確認、他VM（試験VM2台）の一覧上の状態不変を取る。`Invoke-VerificationReplay` は呼ばない（上記の範囲の説明どおり）。
- [ ] 8a で取得した `python3 --version` と `sys.stdlib_module_names` の一覧を固定ファイル化し、replay profile の `stdlibModulesPath/Hash` に載せる（3.10 未満なら一覧の取得方法を見直し、記録する）。
- [ ] 差し替え後に `Run-IndependentTests.ps1` を再実行して11群成功を確認し、期待値の修正が必要なら同時に直す。
- [ ] 実験記録へ結果と限界（1回の成立、負荷なし、デーモン切断は未注入、`Invoke-VerificationReplay` の統合は未実証、他VMの非停止は停止中のVMに対してのみ確認）を書き、replay profile の activationEvidence を固定版・固定設定の能力試験記録として保存する。コミットする。

逸脱記録は実施後に残す。

## タスク9: 最小モデル往復（個別承認、認証方式の実測が前提）

**依存:** タスク8。**対象:** `profiles/proposal/`（`profile.json`、`activation-evidence.json`）、`tests/Invoke-SbxPilotProbe.ps1` の proposal 対応（role と固定argv を引数化）、`tests/fixtures/proposal-probe-settings.json`（proposal 用縮約入力の雛形。8a と同じ方式）、`docs/records/experiments/`。足場は証拠取得の1台目・2台目にそれぞれ別の runId（UUID）を発番し、VM 名は `iv-<runId8>-proposal` で互いに衝突しない。

- [ ] sbx の資格情報の渡し方（プロキシによるヘッダー注入、`sbx secret`）と、通信の許可リスト設定（承認されたモデル接続先だけを許す方法。`docs/reference/sbx-sandbox-runtime-facts.md` では未実測）を読み取りで調べ、raw の認証値を VM に渡さない構成と、接続先を限定した proposal 用の固定argv・`networkPolicy` が成立するかを提示する。どのホストへの送信を許すかは送信範囲の決定であり、利用者の判断で確定する（ADR-0158 の相談事項）。成立しなければ blocked のまま相談する。確定した固定argv・`networkPolicy`・evidence の `modelEndpointAllowOnly` の観測は設計の変更として記録する。
- [ ] 承認後、proposal 用 profile の証拠を取る: 確定した proposal 用固定argv で VM 1台を作り、タスク8a と同じ手順（版・照会・transport 対照・出力洪水）に加えて、ゲスト側の否定確認（SSHエージェントのソケット不在・透過プロキシの中継ポートへの応答・policy log。試験Aの方式）とゲスト側の実効値（`nproc`・メモリ量。試験Bの方式）を取り、`credentialMethod`・`modelEndpointAllowOnly` の観測を加え、最後に外側から `stop` → `ls` で停止確認を取る（1台目。`limitsAndTransport` の停止確認）。続けて proposal 用 VM をもう1台（別の足場 runId、名前は `iv-<runId8>-proposal`）作り、8a の (1) の保持開始と (6)(7)（probe プロセスの強制終了後の自動停止・復旧操作・他VM不変・停止後の未発行）だけを取る（2台目。`abnormalExitRecovery`。自動停止で終わる VM では外側 stop を観測できないため台を分ける。約30分の連続保持はタスク8で1回のみで、ここでは行わない〈ADR-0193〉）。これらから `profiles/proposal/` を生成する。この2台の名前はタスク9の承認区切りの「使うVM名」に含める（ADR-0197 の改訂記録参照）。既存記録の流用は負荷中の外側停止（試験C）だけで、replay 側の 8a の記録も流用しない（ADR-0197）。
- [ ] 承認後、`pilot-source` で Claude Code・Codex 双方の主担当から1往復（依頼→提案→再実行→結果→主担当の修正→recheck）を行い、記録する。ここで `Invoke-VerificationReplay` の統合（candidate-comparison と recheck の両 mode）が初めて実機で成立する。送信範囲・最大時間・モデルは承認どおり（profile.model と Settings.model の一致を含む）。
- [ ] 記録をコミットし、サイクル全体整合検査と最終レビューへ進む（ADR-0162・0192〜0195 の昇格を含む）。

## 完了基準と検証期待値の対応

| 仕様 | 所有タスク | 正常対照と失敗対照 |
|---|---|---|
| V1 | 1 | v3の baseline・proposal-input・履歴コピー・control記録・原本内 runsRoot の列挙除外／未知キー・リンク・範囲外・recheck改変・予約名衝突・`runsRoot ⊇ sourceRoot` |
| V2 | 3・8・9 | activationRecord の実効値一致（policy・mount・resource・credentialExposure・sshForwarding・clipboardImagePaste・mcpServers・otherVmTraffic〈非該当〉）・evidence の必須条件名と観測の対応表・実コマンド直前の維持確認／デーモン停止・同名・500・inspect失敗・値不一致時の停止・SSH forwarder 行の存在・`SSH_AUTH_SOCK` の混入・画像読取true・MCP登録あり・model不一致・実行中の設定変化 |
| V3 | 4 | 正常Envelope が accepted へ／パス逸脱・重複・予約名・過大・切断・test 0件・baseline に無い replacement |
| V4 | 5・8・9 | before 非0/after 0 を別VM・通信なしで記録（8は公開操作の直接呼び出し、9で Replay の統合）／非再現・after 非0・テスト差・replacement外の差分・未適用の replacement・別digest・標準ライブラリ外 |
| V5 | 2・3・5・7・8 | 出力超過・時間超過・停止確認・現在時刻起点の台数分の停止予算・exec以外の定数の時間上限・CLI異常時の停止経路（ADR-0194。デーモン停止時は unverified で返す）・対象外VMの継続・約30分の連続保持／停止未確認・世代変化・自動停止痕跡・偽成功文字列・当該名以外への stop |
| V6 | 1・6 | manifest 期待hash と現物の一致・before/after の effectiveSettingsHash 一致／原本更新・baseline改変・証拠欠落・別runId・自己申告pass |
| V7 | 7・9 | 両主担当からの往復（実モデルは9）／caller 文字列だけでは未実証 |

計画検証では、この表と各タスクの編集内容・試験内容を照合する。ランナーの期待値は既存4群＋新規7群＝11群。タスク8・9の実機試験は群数に含めない。

## 確定前の確認状況

仕様は静的フル1回＋差分2回、試作条件は差分2回で確定済み。本計画はその写像で通常型。

**第1回確定前レビュー（2026-09-14、1体4観点兼務、claude-opus-5、フル実施）**: 走査対象はタスク9・チェック項目63・仕様31節。指摘 Critical 2・Major 9・Minor 6。全件採用。要点: 停止専用期限（C1）、背景起動の公開操作（C2、ADR-0193）、transportVerified の定義（M2）、起動前確認4件（M3、ADR-0195）、CLI切断時の停止（M4、ADR-0194）、VM名規則（M5）、偽sbxの起動方法と応答の出所（M6・M7）、自動停止と外側停止の区別（M8）、(d) の分類（M9）、`Local\` Mutex（M10）、重複キー検査・run配置・effectiveSettingsHash・after差分照合・stdin転送・題材の事前確認（m1〜m6）。

**第2回確定前レビュー（2026-09-15、新規1体4観点兼務、claude-opus-5、フル実施）**: 走査対象はタスク9・チェック項目69・仕様31節。指摘 Critical 1・Major 7・Minor 6・写像欠落4。採否は次のとおり。

- C-1（evidence の必須条件名を誰も検査しない）: 採用。`activation-evidence.schema.json` の `checks` を固定キー集合にし、`Test-VerificationRuntimeProfile` で全必須キーの存在と verified を課す。
- M-1（`settings get`・`mcp ls` の照会形式が未実測のまま実測扱い）: 採用。2026-09-15 に running のデーモンで両照会を読み取り専用で実行して形式を確定（`.tmp/sbx-capability-20260914/50〜52`）。`exec` の `-w`/`-e`/`-u` はローカルヘルプで確認。`ls --json` の `status` の観測値を running/stopped に限定し、未観測の値は synthetic 側へ。
- M-2（停止予算が全体で1枠30秒）: 採用。停止フェーズの予算を `max(now, deadlineAt) + cleanupSeconds × 停止対象台数` にする（limits のキーは変えない。第3回 M-1 で `now + cleanupSeconds × 台数` に改めた）。
- M-3（復旧操作の予算・排他・出力契約が未定義）: 採用。現在時刻起点の新しい予算、Lease 取得、`recovery-result.schema.json` を定義。
- M-4（値不一致時の作成済みVMの始末）: 採用。不一致でも停止を試みて `runtimeFailure` を載せる。clipboard・MCP の照会は create 前へ移動。
- M-5（exec以外のコマンドに時間上限がない）: 採用。limits のキーは変えず、既存キーからの固定式（照会 `2×cleanupSeconds`、作成・搬入 `2×replaySeconds`）で導く（委任範囲内の対応。外部契約は変更しない。第3回 M-1 で定数に改めた）。
- M-6（標準ライブラリ検査の実行場所と Python 版）: 採用。一覧はタスク8で1回取得して profile の固定ファイルにし、検査は VM 不要にする。`python3 --version` を取得証拠に追加。
- M-7（タスク8の差し替え後に試験群を再実行しない）: 採用。再実行のステップを追加。
- m-1（after 差分の「完全一致」は過剰）: 採用。包含と適用確認の2条件に分ける。
- m-2（保持セッションを先に止める順序が実測と逆）: 採用（相談事項4、2026-09-15確定）。順序を「`stop` → 停止確認 → 保持セッションのジョブ停止」に変え、ADR-0193 の Decision を改訂（改訂記録あり）。タスク3の手順と共通制約の停止処理の記述を更新。
- m-3（effectiveSettingsHash に role が入り before/after 比較に使えない）: 採用。role を外し、before/after の一致照合を追加。意図値のラベルである旨を明記。
- m-4（`Local\` Mutex の残余リスク未記載）: 採用。計画と README に明記。
- m-5（calls.jsonl に環境変数のキーが無い）: 採用。キー一覧（値なし）を記録。
- m-6（仕様との差分3件が調整一覧に無い）: 採用。(f)(g)(h) として追記。
- 写像1（model 照合）: 採用。profile.model と Settings.model の一致を検査。写像2（execution の pilotInput 3項目）: 採用。写像3（他VM通信）: 採用。同時1VM下では非該当として記録。写像4（デーモン切断は未確認）: 採用。未確認範囲に明記。

相談事項4（VM停止時の順序）は2026-09-15に案 (i) で確定した。経緯と代替案は ADR-0193 の改訂記録を参照。

**第3回確定前レビュー（2026-09-15、新規1体4観点兼務、claude-opus-5、フル実施。重点は第2回反映箇所と停止順序）**: 走査対象はタスク9・チェック項目73・仕様31節。指摘 Critical 1・Major 7・Minor 5。採否は次のとおり（縮小余地の点検: レビュアーも委譲側も、保護を失わずに外せる機構は M-1 の定数化以外に見つけていない）。

- C-1（タスク8が自分の出力を前提にする循環。evidence と stdlib 一覧が無いと `Invoke-VerificationReplay` が通らない）: 採用。タスク8を 8a（公開操作を通さず固定argvで証拠を取得）と 8b（生成した profile で公開操作を実証）に分けた。骨格。
- M-1（時間上限の固定式に `stop` 欠落・停止予算の場面誤り・`replaySeconds` 連動の誤作動）: 採用。上限を SbxRuntime 内の定数（照会と `stop` 60秒、作成・搬入 240秒）にして limits との連動を外し、停止予算を現在時刻起点 `now + cleanupSeconds × 台数` に統一。機構は1つ減る。骨格。
- M-2（復旧操作にデーモン停止時の経路が無い）: 採用。先頭に `daemon status` を置き、停止中は `ls` を発行せず unverified で返す。骨格。
- M-3（proposal の通信許可が固定argv・条件名・タスク9に無い）: 採用。条件名 `modelEndpointAllowOnly`（proposalのみ必須）と `networkPolicy` を足し、タスク9で許可リストの調査と固定argvの確定を行う。どのホストへ送るかは送信範囲の決定で、タスク9の提示時に利用者が確定する（ADR-0158 の相談事項として計画に残す）。骨格。
- M-4（条件名と観測の対応が無く、`limitsAndAbnormalExit` が未確認のデーモン切断を含む）: 採用。対応表の追加と条件名の分割（`daemonDisconnect` を独立）。デーモン切断の扱いは相談事項5で確定（ADR-0196、2026-09-15）。骨格。
- M-5（`transportVerified` が取得できない失敗型を参照）: 採用。判定材料を直前の維持確認・開始マーカー・`transportContrast` の `disconnect` 型に限定し、デーモン未接続の応答は恒久 synthetic とした（第4回 M-2 で `disconnect` 型の比較も落とした）。骨格。
- M-6（偽の状態ディレクトリ fixture が無い）: 採用。`tests/fixtures/fake-state/` を追加し、偽sbxの `logs` をそこへ向ける。周辺（試験足場）。
- M-7（各実コマンド直前の実効設定確認が写像されていない）: 採用。`Assert-VerificationSandboxUnchanged` を Copy/Confirm/Invoke の直前に置き、`inspect`・`policy ls`・`settings get`・`mcp ls` を activationRecord と照合。費用は1runあたり数十秒。骨格。
- m-1（V2・V4 の失敗対照に試験が無い）: 採用。SSH forwarder 行の blocked と未適用 replacement の incomplete を試験に追加。周辺。
- m-2（復旧操作の Lease 取得の契約と対象0件の終了値）: 採用。runId/daemonKey だけを受ける内部経路と `targetCount` を定義。対象0件は終了値0のまま `targetCount=0` を出し、README に残余リスクを書く。周辺。
- m-3（recheck の差分照合が未定義）: 採用。周辺。
- m-4（`mcp ls` の1件あり応答が実測扱い）: 採用。synthetic にし、判定は件数。周辺。
- m-5（公開操作のシグネチャ変更が調整一覧に無い）: 採用。(j) を追加。周辺。

相談事項5（デーモン切断の扱い）は2026-09-15に案 (i) で確定した（ADR-0196。acceptedLimitations に `daemon-disconnect-unverified` を追加し、仕様02・03を更新）。

**第4回確定前レビュー（2026-09-15、新規1体4観点兼務、claude-opus-5、フル実施。重点は第3回反映箇所）**: 走査対象はタスク9・チェック項目76・仕様31節。指摘 Critical 2・Major 2・Minor 5。採否は次のとおり（全件採用。承認区切りの拡大を伴う案は採らず、既存記録の再利用で閉じた）。

- C-1（8b が `Invoke-VerificationReplay` に渡せる ready な提案を提案VM無しに作れず、タスク8→9→8 の循環）: 採用。8b を SbxRuntime の公開操作の直接呼び出し（replay 用2台）に縮小し、Replay の統合実証はタスク9へ移した。V4 の所有タスクに9を追加。骨格。
- C-2（対応表がタスク8に割り当てた観測のうち、試験A〜Cの再取得・復旧操作・他VM非停止・自動再起動防止が 8a の手順にも承認区切りにも無い）: 採用。証拠の出所を（既存記録／8a／9）で条件ごとに明記し、既存記録は追跡済みの実験記録ファイルを evidencePath にして hash を固定。`limitsAndAbnormalExit` を `limitsAndTransport` と `abnormalExitRecovery` に分け、後者の観測（保持プロセス強制終了→自動停止、復旧操作、他VM不変、停止後の未発行）を 8a に置いた（復旧操作は profile 検査を通らないため 8a で実行できる）。試験A〜Cの再実施は承認に含めない。骨格。
- M-1（保持用 exec・Confirm・export の時間上限が未割当で、保持が work 相の期限で切られると ADR-0193 の順序が崩れる）: 採用。全コマンドの上限を全域表にし、保持は期限監督の対象外と明記。タスク2に「背景起動は期限で打ち切られない」試験を追加。骨格。
- M-2（`transportContrast.disconnect` の実測手順が無く、`transportVerified` の基準値が未定義）: 採用。`disconnect` を 8a で観測できる `clientKilled` に置き換え、`transportVerified` から stderr 型の比較を落として外側の打ち切りの有無で定義した（機構が1つ減る）。骨格。
- m-1（タスク6の照合手順が mode 別に分岐していない）: 採用。周辺。
- m-2（定数の時間上限に試験が無い）: 採用。偽sbxの遅延で2ケース追加。周辺。
- m-3（`fake-state/`・対応表・実 run 用 profile 一式の配置先が対象一覧に無い）: 採用。`profiles/evidence-checks.md`・`profiles/replay/` を定義。周辺。
- m-4（原本内 runsRoot の扱いが仕様01・v1 と食い違う）: 採用。仕様どおり「包含は拒否・原本内は列挙除外」に直した。周辺。
- m-5（実測出力の利用者識別子が fixture に入る）: 採用。ダミー値に置換。周辺。
- 改善提案（他VMの非停止は停止中のVMに対してのみ確認できる）: 採用。タスク8の限界と未確認範囲に明記。

**第5回確定前レビュー（2026-09-15、差分再確認、新規1体、claude-opus-5。対象は第4回反映の差分13箇所と上流）**: 指摘 Critical 1・Major 6・Minor 7。第4回の指摘は「閉じた」6件・「部分的」4件。採否は次のとおり。

- C-A（ADR-0194 の「CLIプロセスの強制終了」試験を第4回反映で保持プロセスの強制終了に置き換えていた＝承認済み決定の縮小）: 採用。8a に probe プロセス（CLI 相当）自体の強制終了と `-Resume` による観測を戻し、ジョブ伝播の実証を含めた。骨格。
- M-A（外側 `stop` による停止確認を 8a では取れない）: 採用。出所を既存の試験C に付け替え、8b で公開操作による外側 stop を取る。骨格。
- M-B（`limitsAndTransport` の「出力上限」に観測が無い）: 採用。8a に出力洪水の `exec` 1本を追加し、承認区切りに明記。骨格。
- M-C（proposal 役割の evidence の出所が無い）: 採用。対応表を条件×役割にし、タスク9で proposal VM に対して同じ手順で取る工程と `profiles/proposal/` を追加。骨格。
- M-D（タスク5の実行手順が mode で分岐せず、タスク6・仕様04 と食い違う）: 採用。分岐と試験を追加。骨格。
- M-E（`transportVerified` から型比較を落とし、仕様04「区別できない終了は false」が満たされない）: 採用。仕様04 は変えず、コマンド固有の出力署名（unittest の `Ran N tests in` 行等）を実現手段にして「区別できない終了は false」を満たす形に再定義。`clientKilled` は仕様04の「切断」対照として evidence の完備性に使う。骨格。
- M-F（停止中の試験VM2台の状態読取り手段が未指定で、`inspect` の自動起動が未実測）: 採用。`ls --json` の一覧読取りのみに限定し承認区切りに明記。骨格。
- m-A（8a が直接発行する exec が全域表に無い）: 採用。周辺。
- m-B（連続保持の実施VMと順序が未定）: 採用。8a の (5) に同一 probe VM・強制終了の前・保持開始時刻以後の行で判定と固定。周辺。
- m-C（probe の足場: Lease 解放・PreparedRun・Settings の null）: 採用。足場のステップを追加し、復旧操作に Lease 解放を明記、settings schema に null 可の条件を追加。周辺。
- m-D（V1 行の失敗対照が改訂と食い違う）: 採用。周辺。
- m-E（VM名の role 列挙に probe が無い）: 採用。周辺。
- m-F（`transportContrast.clientKilled` は実行時に参照されないので必須キーから外す縮小案）: **不採用**。仕様04は「切断」を含む実機対照で確認した runtime 設定だけを使うと定めており、`clientKilled` はその「切断」対照にあたる（M-E の対策で位置づけを明記）。外すと仕様04の限定列挙を満たさない。周辺。
- m-G（定数上限の試験2件が実時間約5分を消費）: 採用。定数を script スコープ変数にし試験だけが差し替える。周辺。
- 付記（evidence に使う実験記録の追記で hash が変わる）: 採用。README の既知の制約に明記。

**第6回確定前レビュー（2026-09-15、差分再確認、新規1体、claude-opus-5。対象は第5回反映の差分14箇所と上流）**: 指摘 Critical 2・Major 4・Minor 4。第5回の指摘は「閉じた」10件・「部分的」4件（m-F 不採用の理由は妥当と判定）。採否は次のとおり。

- CR-1（unittest の要約行は stderr に出るため stdout の署名検査が常に偽）: 採用。署名を `{pattern, stream}` にし unittest は stderr、8a でストリームを実測。骨格。
- CR-2（8a・8b で足場の run を共用すると30分の保持で totalSeconds を使い切る）: 採用。8a は probe 専用設定と専用予算（3600秒、試験足場の値）、8b は別の run を新しく準備。骨格。
- MA-1（proposal 側の evidence が「既存記録の流用禁止」と「試験A〜Cの再実施は承認外」に挟まれ verified になり得ない）: 採用。相談事項6で案3を確定（ADR-0197）。数秒で取れる成分は proposal VM で取り直し、負荷中の外側停止だけ既存記録を使う。骨格。
- MA-2（probe 強制終了で (1)〜(5) の観測が失われる）: 採用。観測の都度 runRoot へ保存し `-Resume` が読み直す。骨格。
- MA-3（(1)〜(4) が非保持で自動停止・自動起動をまたぎうる）: 採用。保持を create 直後に開始し、各観測の前後で自動停止痕跡を確認。骨格。
- MA-4（settings schema の null 可が仕様01「replayProfilePath は常に必須」に反する）: 採用。SettingsV3 は緩めず、復旧操作は縮約入力 `recovery-input.schema.json`、probe は `tests/` 配下の専用設定にし、通常経路で null は blocked の試験を追加。仕様01 は変更しない。骨格。
- MI-1（probe の VM 名の表記不一致）: 採用。周辺。
- MI-2（Confirm の件数署名が blocked を incomplete に写像）: 採用。署名は sha256 行1行以上、件数は manifest 比較。周辺。
- MI-3（Codex 実行の署名未割当）: 採用。署名を要求せず export の JSON で確認。周辺。
- MI-4（出力洪水の打ち切り主体が未指定）: 採用。`Invoke-VerificationProcessV3` で発行。周辺。

相談事項6（proposal 側の証拠の出所）は2026-09-15に案3で確定した（ADR-0197。検討した代替案と懸念は同ADRを参照）。

**第7回確定前レビュー（2026-09-15、差分再確認、新規1体、claude-opus-5。対象は第6回反映の差分11箇所と上流）**: 指摘 Major 4・Minor 4。第6回の指摘は「閉じた」5件・「部分的」5件。全件が「本文の改訂を受ける側（引数の型・偽sbx・試験の期待文・他タスクの工程）が旧前提のまま」の写し漏れで、全件採用。

- A（出力署名の `{pattern, stream}` 化が引数型・偽sbx・試験の期待文に未反映）: 採用。引数を hashtable にし、偽sbxの unittest 応答を stderr、試験文面を「指定ストリームに無ければ false」に統一。骨格。
- B（proposal 側の `abnormalExitRecovery` の証拠が未割当）: 採用。相談6の原則「数分で取れるものは提案用 VM で取り直す」を適用し、タスク9で proposal VM で取る。ADR-0197 に改訂記録を追加（例外の拡張ではない）。台数は第8回の相談事項7で確定。骨格。
- C（8a の足場の所有者不在）: 採用。`tests/fixtures/probe-settings.json`（recovery-input schema で検査）、probe の runId 発番、`control/probe-run.json`、作成記録の runId を復旧操作が使うことを明記。骨格。
- D（`-Resume`・やり直し・強制終了の対象範囲が未定義）: 採用。`-Resume` は exec/cp・保持の再開をしない、やり直しは新 runId で旧観測を捨てる、強制終了は当該 exec のクライアント PID のみ。骨格。
- E（8b 用の request・settings・pilot-input の用意が未割当）: 採用。`tests/fixtures/pilot-run/` を定義。周辺。
- F（`recovery-input.schema.json` の登録と CLI の変換責務）: 採用。調整 (b)・責務表・CLI 入口・試験に反映。周辺。
- G（承認区切り表のセル重複）: 採用。周辺。
- H（(l) の例外が仕様00に未反映）: 採用。仕様00の該当文へ ADR-0197 の注記を追加。周辺。

**第8回確定前レビュー（2026-09-15、差分再確認、新規1体、claude-opus-5。対象は第7回反映の差分12箇所と上流、ADR-0197・仕様00の改訂）**: 指摘 Major 9・Minor 2。第7回の指摘は「閉じた」3件・「部分的」5件。全件が第7回反映の追随漏れで、新たな緩和・分担違反はなし。採否は次のとおり。

- 指摘1（`transportVerified` の定義文が stdout のまま）: 採用。「署名の `stream` で指定したストリーム」に修正。骨格。
- 指摘2（`OutputSignature=$null` の `transportVerified` が未定義で正常 run が incomplete になりうる）: 採用。`$null` は `transportVerified=null`（判定対象外）とし、判定に用いるのは署名を要求するコマンドだけと明記。骨格。
- 指摘3（proposal 2台目の手順範囲が3箇所で食い違い、承認提示に無い約30分の保持を含む）: 採用。2台目は 8a の (1)(6)(7) だけに統一し、約30分の保持はタスク8で1回のみ（ADR-0193）。骨格。
- 指摘4（ADR-0197 本文が「1台」「VM は増えない」のまま計画と食い違う）: 採用。相談事項7で2台構成を確定し、ADR-0197 の Decision・Consequences を訂正、説明の誤りを改訂記録に残した。骨格。
- 指摘5（タスク9の proposal 用 VM の足場が未割当、VM名の衝突）: 採用。probe スクリプトの role・固定argv の引数化と proposal 用縮約設定をタスク9の対象に追加（台数は相談事項7）。骨格。
- 指摘6（fixture に絶対パス・hash を置けない、`pilot-source` は Git 作業ツリーのルートでない）: 採用。`pilot-run/`・`probe-settings.json` は雛形とし probe が実行時に絶対パスと hash を埋めて実体化、`pilot-source` は独立した Git 作業ツリーへ複製してから sourceRoot にする（CliV3 試験も同じ）。骨格。
- 指摘7（当該 exec のクライアント PID を得る手段が無い）: 採用。当該対照だけ `Start-VerificationBackgroundProcess` で発行し `processId` を使う。周辺。
- 指摘8（`probe-sandbox.json` の「同形式」が成立せず role=probe が列挙外）: 採用。作成記録の項目集合を定義し、復旧操作は作成記録の runId を正本、role の値域に `probe` を含め、keepAlive 無しの handle を受ける。骨格。
- 指摘9（unittest 署名のストリームを 8a が実測しない）: 採用。8a (1) に unittest 1本を追加し、偽sbxの unittest 応答を synthetic→差し替え対象に。骨格。
- 指摘10（`recovery-input` に版キーが無い、`probe-run.json` に schema が無い）: 採用。schemaVersion=3 を追加、probe-run.json は probe 内の固定形式と明記。周辺。
- 指摘11（引き継ぎ一覧と節の順序の陳腐化）: 採用。周辺。

相談事項7（proposal 用の証拠取得 VM の台数）は2026-09-15に2台構成で確定した（ADR-0197 の改訂記録参照。内容上は2台が優り、当初の「VM は増えない」の説明が誤りだった）。

**第9回確定前レビュー（2026-09-15、差分再確認、新規1体、claude-opus-5。対象は第8回反映の差分10箇所と上流、ADR-0197 の訂正）**: 指摘 Major 5・Minor 3。第8回の指摘は「閉じた」3件・「部分的」8件。全件が追随漏れで、新たな緩和・分担違反・承認範囲の拡大はなし。`transportVerified=null` の解釈は仕様04と整合し委任範囲内と判定。全件採用。

- A（8b の sourceRoot が同一箇条内で矛盾、複製先が未定）: 採用。request・pilot-input とも複製先の絶対パスを probe が埋め、複製先は runsRoot の外と明記。骨格。
- B（`recovery-input` の schemaVersion=3 が他4箇所に未伝播）: 採用。責務表・settings 箇条・タスク3 IF・CLI 入口・8a 足場・CliV3 試験に反映。骨格。
- C（8a の unittest に題材の搬入手順が無く、提示箇条にも無い）: 採用。`cp`・`chown`・作業ディレクトリ・tests の配置を明記し、提示箇条に追加。骨格。
- D（`transportVerified=null` の受け手が未反映、例示の cp/chown は CommandRecord を作らない）: 採用。null になるのは提案本体の Codex 実行だけ、replay-record は boolean のまま null は現れないと整理し、タスク4に quarantine への記録を明記。骨格。
- E（`clientKilled` 対照を背景起動にしたときの終了コード取得と期限監督）: 採用。`Stop-VerificationBackgroundProcess` の戻り値と `OutputPaths` の stderr を観測にし、全域表に期限監督の対象外を明記。骨格。
- F（`probe-sandbox.json` に createdAt が無い、null 拡大の理由が未記載）: 採用。周辺。
- G（タスク9の足場 runId が単数、proposal 用縮約設定が対象に無い）: 採用。2つの runId と `proposal-probe-settings.json` を明記。周辺。
- H（対応表の proposal 側 `abnormalExitRecovery` に保持開始が無い）: 採用。周辺。

改訂差分は git（47109dc との diff）と退避 `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-15-v3-plan-before-r3/`・`-r4/`〜`-r9/` で追える。計画特有の未確認範囲は、セッション保持exec の長時間挙動（タスク8で確認）、`ProcessHost` の stdin 転送、`Local\` Mutex の実動、`inspect --json`・`mcp ls --json` の項目が版で変わる可能性、テンプレートの Python 版、実機のデーモン切断（ADR-0196 で未確認の制限として受容）、デーモン停止時の CLI 応答形式（恒久 synthetic）、`Invoke-VerificationReplay` の実機統合（タスク9まで未実証）、稼働中の他VMに対する非停止（設計上は他VMが稼働中なら作らないため、実機では停止中のVMに対してのみ確認）、sbx の通信許可リスト設定（タスク9で実測）、Codex 起動 argv（タスク9で実測）。
