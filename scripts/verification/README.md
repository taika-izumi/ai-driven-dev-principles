# 隔離検証の共通起動処理

原本の Git 作業ツリーから独立したコピーを作り、sbx の VM 内の Codex に再現テストと修正候補を提案させ、別の通信なしの VM で修正前後のテストを取り直し、外側の記録で照合した結果を返す共通CLIです（schemaVersion=3、以下 v3）。Claude Code と Codex のどちらの主担当からも同じコマンドで使います。

現在使える範囲は、名指しで承認した小さな合成題材による試作（`scope=synthetic-pilot`）だけです。実プロジェクト・普段使いへの拡張、原本への自動適用、導入や公開は行いません。実VMでの証拠取得（計画のタスク8）と実モデルでの往復（タスク9）は個別承認の後に行うため、それまでは実行設定の証拠（`profiles/replay/`・`profiles/proposal/`）が無く、実際の run は実行設定の検査で blocked になります。Claude Code・Codex 双方の主担当からの往復の実証もタスク9で行います（依頼元を示す `caller` の文字列だけでは実証になりません）。

仕様は `docs/current/specs/2026-09-09-isolated-verification/` を参照してください。

## v3 共通CLI

### 前提

- Windows 11、PowerShell 7、Git、sbx 0.42.1。
- sbx のデーモンは利用者が通常の端末で起動しておきます。CLI はデーモンの起動・再起動・reset・設定変更を行いません。停止中なら、利用者の通常起動が必要という理由つきで blocked を返します。
- 名指しで承認した合成題材ごとに、外側の主担当が固定入力記録（`pilot-input.schema.json`）を用意し、`settings.pilotInputPath` に指定します。CLI は依頼からこの記録を作りません。
- 実行設定（`runtime-profile.schema.json`）と、その成立を示す証拠（`activation-evidence.schema.json`）を `settings.replayProfilePath`・`settings.proposalProfilePath` に指定します。`verified` の意味は `profiles/evidence-checks.md`（条件名と観測の対応表）が正本です。再実行用の一式は `profiles/replay/`、提案用は `profiles/proposal/` に置きます（どちらも実VM・実モデルでの証拠取得後に作成）。

### 通常の実行

```powershell
pwsh -NoProfile -File scripts/verification/Invoke-IsolatedVerification.ps1 -RequestPath <request.json> -SettingsPath <settings.json>
```

- 依頼（`request.schema.json` の v3）と設定（`settings.schema.json`）は schemaVersion=3 だけを受けます。重複キー・未知キー・数字の文字列表現は拒否します。
- 順序: 入力の読込と検査 → 受付時刻（startedAt）の確定 → 基準版と提案用コピーの準備 → 実行設定の検査（再実行用は常に、提案用は再検証〈recheck〉以外）→ pilot 排他（同じデーモンでの同時実行を1つにする Lease）の取得 → 提案 → 提案が ready なら再実行、そうでなければ未実行（not_run）の結果 → 照合 → 作成したVMの停止確認と Lease の解放。
- 全体の制限時間（`limits.totalSeconds`）は受付時刻から数え、準備の時間も含みます。壁時計の期限（deadlineAt）と、準備の開始時に始める単調増加時計のどちらかが到達したら到達とします（システム時刻が戻っても延びません）。到達後は新しいVMの作成・搬入・実行を始めず、停止だけを停止フェーズの予算（停止を始めた時刻 + `cleanupSeconds` × 停止対象の台数）の範囲で行います。

出力と終了値:

- stdout: 結果（`result.schema.json` の v3、VerificationResultV3）の JSON を1件だけ、1行で書きます。同じ内容を `<runRoot>/control/result.json` に一度だけ保存します（既にあれば上書きせず、stdout にだけ返します）。
- stderr: 診断です。最初の行が `runRoot: <パス>`（run の ID は準備の中で決まるため、準備の直後・VMを作る前に出します。準備で run を作れなかった場合は `(作成されていない)`）で、結果の JSON が返らなくても復旧操作に必要な場所が分かります。続けて `scope: synthetic-pilot`、`acceptedLimitations:`（clipboard 文字列書込の可能性・プロセス数上限なし・デーモン切断は未確認の3件）、clipboard の注意、期限、Lease の取得と解放、各段階の status、例外のメッセージを出します。
- 終了値: status が completed のときだけ観測分類の値（0: candidate-supported・current-pass、1: still-failing・not-reproduced・reproduced・current-fail）。それ以外（blocked・incomplete・timed_out・source_changed）はすべて 2 です。終了0でも修正の採否は主担当がテストの意味と十分性を見て判断します。

### 復旧操作（CLI が異常終了したときのVM停止）

CLI が強制終了などで停止確認まで進めなかった場合、stderr の最初の行に出た runRoot を使って、作成記録にあるVMだけを止めます（ADR-0194）。

```powershell
pwsh -NoProfile -File scripts/verification/Invoke-IsolatedVerification.ps1 -StopRecorded -RunRoot <runRoot> -SettingsPath <settings.json>
```

- `-SettingsPath` は通常の設定（SettingsV3）でも、`schemaVersion`・`sbxPath`・`pwshPath`・`runsRoot`・`limits` だけの縮約入力でもかまいません。CLI はこの5項目を取り出して `recovery-input.schema.json` で検査します（`schemaVersion` の欠落も拒否）。
- VMを作りません。`<runRoot>/control/runtime/<役割>-sandbox.json` に記録された名前と ID のVMだけを停止・確認し、記録に無いVMには触れません。別の run が Lease を持っていれば何もせず終了値 2 を返します。
- 読めない作成記録は、名前・ID を推定せず `(unreadable record: <ファイル名>)` として停止未確認（unverified）で列挙し、残りの記録の処理を続けます。
- stdout: `recovery-result.schema.json` の JSON 1件（同じ内容を `control/runtime/recovery-<時刻>.json` に保存）。入力・排他の拒否では stdout に何も書きません。Lease の取得後にデーモンの世代や一覧を照会できなかった場合は、停止を発行せず、全対象を `stateBefore=query-failed`・停止未確認（unverified）とした結果を返します（`recovery-<時刻>.json` にも保存。stdout に結果を出し、終了値は 2、照会失敗の説明文は stderr）。
- 終了値: 全対象の停止を確認できれば 0（記録0件も 0。`targetCount=0` を stdout と stderr に出します）、それ以外は 2。

### 既知の制約

- sbx のVMは最後のセッション切断から30秒で自動停止し、`cp`・`exec` は停止したVMを自動で起動します。CLI はVM作成から停止まで保持用の `exec` を1本保ち、途中の自動停止・再起動を検知したら当該 run を incomplete にします。
- clipboard 文字列書込だけは試作限定で受け入れた例外です。実行中・直後は clipboard の内容が変わりうるので、そのまま貼り付けず、必要な内容を信頼できる元からコピーし直してください。CLI は clipboard の読取・退避・復元・消去をしません。
- デーモンとの接続が途中で切れた場合の挙動は未確認です（`daemon-disconnect-unverified`。ADR-0196）。
- 対象は synthetic-pilot だけです。`scope` の文字列だけでは任意の原本を合成題材と認めず、固定入力記録と現物の hash で照合します。
- pilot 排他は同じログオンセッション内の名前付き Mutex です。別のログオンセッションからの同時実行は排他できません。
- VMの作成要求を送った後、ID を確定して作成記録を書く前に CLI が失われた場合、そのVMは復旧操作の対象になりません（記録が無いため）。後続の run は一覧の検査で blocked になりえます。
- 実行設定の証拠に使った実験記録（`docs/records/experiments/` のファイル）は後から追記しません。追記すると証拠の hash が変わるため、追記が必要なら profile を作り直します。
- 停止したまま残ったVMの後片付け（`sbx rm`）は CLI も復旧操作も行いません。利用者の承認を得てから実行します。
- runsRoot は短いパスにしてください。基準版の `.git/objects/pack` までのパスが Windows のパス長上限に達すると、履歴の取り込みに失敗します（Issue-0146）。
- 対象プロセスをジョブへ割り当てる前の数ミリ秒の間に対象が起動した子プロセスは、ジョブに入らず外側の停止が届きません（Issue-0147 の残り）。実際の `sbx.exe` での影響はタスク8aの実VM試験で確かめます。
- ジョブへの割当そのものに失敗した場合、起動側は対象（sbx クライアント）が起動済みでジョブ外にありうるものとして扱います（`refusedReason=assign-failed`・`processTreeStopped=false`）。VM の作成要求でこれが起きると、一覧に名前が無くても未作成とは確定せず、作成成否不明（incomplete）で返します。
- 再実行の unittest に渡す環境変数は空で固定しています（VM の既定の環境に何も足しません）。

## 部品の独立試験（VMもモデルも起動しない）

```powershell
pwsh -NoProfile -File scripts/verification/tests/Run-IndependentTests.ps1
```

v1 の4群（RequestCopy・History・Execution・Result）と v3 の7群（RequestCopyV3・ExecutionV3・SbxRuntimeV3・ProposalV3・ReplayV3・ResultV3・CliV3）を順に実行し、1群でも失敗すればそこで止まります。成功すると最後に `Independent verification: 11 suites passed (no agent launched)` と表示します。各群の開始前に群名を、終了後に経過秒を表示します。全体の所要は約26分です（2026-09-16 の最終修正後の実測 1577 秒。SbxRuntimeV3 約11分、ReplayV3 約5.5分、ProposalV3 約4分、CliV3 約3.7分、他は各1分未満）。偽の sbx は1呼び出しに1秒前後かかるため、停止を確認するケースの停止猶予・照会上限・全体期限は、その所要に負荷の揺れを見込んだ値にしています。

試験群は手動で並行に実行しないでください（群どうしが同じ名前付き Mutex を使うため、Lease の競合で失敗します）。v3 の試験は記録済みの応答を返す偽の sbx（`tests/fixtures/FakeSbx.ps1`）を使い、実VM・実デーモンは使いません。実測の無い応答には `synthetic: true` の印を付けています。偽の sbx で合格しても実機の実証には数えません。

試験用データはこのworktreeの`.tmp/verification-tests/`に実行ごとに新規作成します。自動の後片付けは行いません。一部の試験は `codex` の実行ファイルが PATH にあることを前提にします（v1 の起動検査。モデルは起動しません）。

## v1 部品（先行実装）

- `RequestCopy.psm1`: 依頼検査、対象一覧・ハッシュ、ファイルとGit履歴の独立コピー。
- `Execution.psm1`と`ProcessHost.ps1`: 明示したプロセスの出力回収・時間超過・Windowsジョブによる子プロセスの停止。ジョブはプロセス管理用であり、ファイルや通信を隔離するものではありません。
- `Result.psm1`: 実行記録・最終応答・成果物・原本状態の照合。

v1 の公開関数と試験は v3 と並べて保持しています。ホスト上で Codex を起動する v1 の構成は通信条件が未解決のため、通常利用には使いません。依頼元を示す`caller`の文字列だけでは実証になりません。

コピーはスクリプトが作り、親AIによる本文転記は不要です。Gitの全参照とHEADから到達できる履歴をbundleファイル経由で独立した`.git`へ移します。子はコピー内で`git log`・`git show`・`git blame`を利用できます。原本の設定・フック・リモート接続設定・オブジェクトの共有は持ち込みません。履歴に残る過去のファイルも参照可能になります。reflogだけに残る履歴、参照から到達できないオブジェクト、Git LFSの外部実体は複製対象ではありません。

現在の未コミット内容・対象の未追跡ファイルはそのまま複製します。HEADのブランチ名（コミット前も含む）またはdetached状態も保持します。コピーのインデックスはHEADを基準に作り、原本のステージ済み／未ステージの区別は引き継ぎません。原本の参照先やHEADのブランチが準備中・実行中に変わった場合も対象版の変更として扱います。浅い履歴・部分クローンは、完全な履歴として扱わず準備を停止します。外部からの自動取得は行いません。Git各処理には30秒の上限があり、大きな履歴は準備を完了できない場合があります。

再解析ポイントとサブモジュールのディレクトリ入力は拒否します。`.codex`・`.claude`・`.agents`・`.mcp.json`の起動設定は通常の作業ファイルコピーから除外して理由を残します。Git履歴中の同ファイルは資料として参照できますが、自動適用はしません。現在の設定自体を検証するための保護された別入力や、導入設定ファイルの取扱いは、実エージェントの起動時に確認する必要があります。

部品テストの成功は、通信リスクの受容や隔離環境の完成を意味しません。現状の評価と条件はIssue-0136の`0136-note-network-risk-assessment.md`を参照してください。
