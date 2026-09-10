# 編集成立と原本保護を両立する実行方法の調査

状態: 2026-09-11、ADR-0179の通常起動成功後、ユーザーの「OKです。進めてください」に基づく実現可能性調査。候補は未採用。インストール・Windows機能変更・VM/コンテナ作成・モデル起動は行っていない。

追記による訂正: 本文の初回調査は別worktreeの既存実証を見落としていた。Windows機能有効化・再起動・初回Dockerログインを次の必須作業とした提案は撤回する。最新の根拠と次手は末尾「子セッション隔離の既存知見との照合」を参照。初回の観測値は当時の記録として残す。

## 判断に使う事実

通常ユーザー権限では固定プラグイン2件を読み込んでRead/Write成功、従来のCodexサンドボックス付きでは拒否された。通常起動では.claude.jsonが更新されるため、これをそのまま本比較の保護条件成立とは扱わない。結果は `2026-09-10-model-discretion-preflight-results.md` の最終節、条件は比較仕様00〜03を参照。

Claude公式の[Bashサンドボックス](https://code.claude.com/docs/en/sandboxing)はmacOS/Linux/WSL2用で、Windowsネイティブ非対応。内蔵Read/Edit/WriteはそのOS隔離を通らず、権限規則で判定する。[権限資料](https://code.claude.com/docs/en/permissions)のRead/Edit拒否規則だけでは、Bashから実行するコードを同じ境界で制限できない。したがって通常起動へdeny規則を足すだけの案は、今回の原本・採点・任意コード実行の保護を満たした根拠にならない。

このPCの実測:

- Win32_OperatingSystem: Windows 11 Home、10.0.26200、64bit。Get-ComputerInfoのWindowsProductNameはWindows 10 Homeと表示されたため、前者で実版を確認した。
- WSL一覧はUbuntuとdocker-desktop、いずれもversion 2。取得時の状態はStopped。Docker API取得とは別時点の表示で、これをエンジン不在とは解釈しない。
- Docker Desktop 4.81.0、Linuxエンジン29.6.1が応答。desktop-linuxを明示した接続先で、loopforalpha-sandbox:latestのID `sha256:b6f82765069d11212af2e11631bc70c45dd6bf438a3e6581df915e6aecd6f97c` を個別参照できた。初回の暗黙contextによる参照はNo such imageで、原因は未確定。今後はcontextとIDを固定する。
- 既存イメージのConfig.Userは空、WorkingDirは/work、Cmdはpython3。構築元候補 `D:/Dev/001_Trade/LoopForAlpha/loop/sandbox/Dockerfile` はPython3.12・uv・製品依存用で、Claude導入手順はない。Dockerfileとイメージ全レイヤーの一致やCLI実在は未実測。新規モデル用の完成イメージとは扱わない。
- `docker sandbox --help` は旧機能削除とDocker Sandboxesへの移行を案内した。`sbx` はPATHでは見つからなかったが、`C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe` が存在し、`sbx version` はv0.42.1。追加導入は現時点で不要。
- Win32_OptionalFeatureのHypervisorPlatformはInstallState=2。[Microsoftの値定義](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-optionalfeature)ではDisabled。DISM系の読み取りは管理者特権不足だったが、CIM読み取りで状態を確認できた。Windows機能は変更していない。

## 候補の比較

| 候補 | 得られること | 負担・未確認 |
|---|---|---|
| Docker SandboxesのローカルmicroVM | 公式機能としてホストとのファイル・通信・Docker制御・認証境界を持つ。独自の隔離基盤を増やさずに済む可能性が高い | HypervisorPlatformの有効化、必要なら再起動、DockerとClaudeの初回ログイン。固定CLI版・指示分離・停止・共有設定の実測は必要 |
| 通常のDockerコンテナ | 既存エンジンを使い、作業コピーだけ共有する構成を作れる | Claude導入・専用認証・通信制限等を自分で組む必要がある。構築元候補はテスト用でそのまま使える証拠なし |
| Windows通常起動の権限規則だけ | 現在の認証・CLIを再利用できる | 任意コード実行と通常状態保存の保護が未成立。現行要求を維持する案として勧めない |

推奨候補はDocker Sandboxes。採用判断はまだしていない。中断中のIssue-0136の再検討メモは認証・通信の論点確認にのみ参照し、当該worktreeの再開や独自MCP基盤の実装には入っていない。

## Docker Sandboxesを使う場合の構成案

[Docker公式の隔離説明](https://docs.docker.com/ai/sandboxes/security/isolation/)は、独立したmicroVMとホスト側の通信・認証プロキシを説明する。[既定動作](https://docs.docker.com/ai/sandboxes/security/defaults/)では共有した作業ディレクトリへ書けるため、元リポジトリやcontrol・採点原本・通常ホームを共有しない。作業はVM内部のコピーを使い、固定プラグインは専用複製を必要な範囲で渡す。読み取り専用指定と前後ハッシュ照合を実測してから比較へ採用する。

共有スキルストアは既定で読み書き可能であり、公式の `--no-share-skills` を使用する案。v0.42.1で同フラグを付けたcreateのヘルプは終了0だったが、作成時の実効マウント検証は未実施。[スキル共有仕様](https://docs.docker.com/ai/sandboxes/workflows/agent-skills/)を参照。ホストMCPやホストDockerソケットも渡さない。既存のグローバル通信許可を無条件で継承せず、実効ルールと試験単位の制限を確認する。

[Claude向け既定起動](https://docs.docker.com/ai/sandboxes/agents/claude-code/)はbypassPermissionsを含むため、そのまま使わない。createとexecを分け、明示したClaudeコマンド・acceptEdits・固定モデル/effort/プラグインで起動する案。外側のVM保護と内蔵ツール判定の双方を確認する。単純にsbx runへフラグを足すだけで既定bypassを外せたと扱わない。

Docker公式は[Claude契約のOAuthログイン](https://docs.docker.com/ai/sandboxes/get-started/)と[認証プロキシ](https://docs.docker.com/ai/sandboxes/configuration/credentials/)を案内している。ホストのClaude認証ファイルをコピーする案ではない。Docker用に保持されるログイン状態への影響を提示し、利用者自身の初回ブラウザログインが必要なら依頼する。ローカル版を対象にし、クラウド版やAPI従量課金へ切り替えない。

まずClaudeの成立可否を確認する。採用する場合は同じモデル内の2条件を同じ環境へ揃える。Codexも移すかは既存結果と比較仕様への影響を踏まえて別途決める。LinuxでのCLI・Python・パス・既存テスト・親子の停止・利用量回収を未検証のまま合格へ移さない。

## 利用者へ提示する次の段階

1. この方式を試すかを判断する。次の管理者操作と再起動・ログインの負担を伴う。
2. 採用後、管理者PowerShellで `Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart` を実行する。これは[Dockerの前提条件](https://docs.docker.com/ai/sandboxes/install/)に対応するWindows機能の変更。RestartNeededを確認し、再起動は利用者の都合で行う。AIから自動再起動しない。
3. 機能が利用できる状態になったら、モデルを呼ばずに実効設定・作成/停止/コピー・原本と共有領域の境界を確認するための最小操作を具体化する。作成はローカルmicroVMとテンプレート取得を伴うため、起動範囲を明示する。
4. DockerとClaudeのログインが必要なら、利用者にブラウザ認証だけを依頼する。認証情報を会話へ貼り付けさせず、既存ファイルから抽出・転送しない。
5. その後に無害なRead/Writeと保護拒否を限定実測する。比較条件・新規モデル起動は個別判断のまま。成立が見込めなければ独自構築へ自動移行せず、保留も含めて判断する。

所要時間は機能有効化・再起動・ログイン・テンプレート取得に左右されるため、まだ準備完了時刻を約束しない。今回の調査は約01:00〜01:06に実施し、モデル追加0回。本比較0回、診断累計17回を維持する。公式資料は提供元の仕様であり、このPCでの動作実証とは区別する。

## 子セッション隔離の既存知見との照合（2026-09-11）

ユーザーが9月9〜10日のsbx検討記録の探索を指示した。masterが参照していた `.worktrees/isolated-verification/docs/working/handoff/codex_isolated-verification.md` と最新実験記録を読まず、古いコンテナ再検討メモだけを選んで先の再調査を進めたことが見落としの原因。関連タスク「sbx内部接続障害の調査を継続」「能力試験の具体化を継続」も確認した。今回の訂正は既存成果の発見・照合であり、隔離検証プロジェクトの再開ではない。

以下の参照はすべて `.worktrees/isolated-verification/` 内。未統合の知見として所在を固定する。

| 既存資料 | 確認した知見・今回への影響 |
|---|---|
| `docs/records/experiments/2026-09-09-sbx-preflight.md` | 9月9日にWHvGetCapabilityがHRESULT=0、HypervisorPresent=1、writtenBytes=4を返した。sbx 0.42.1の署名・ハッシュ検証とユーザー導入も完了。今回のOptionalFeature=2だけで機能変更が必要とは断定できない |
| `docs/records/experiments/2026-09-09-sbx-smoke.md` 20:21節 | ユーザーの通常PowerShellからデーモンを起動すると内部接続が成立。以後Codex側CLIからVM作成・合成ファイルとGit履歴の搬入・出力回収・停止に成功。Codexから起動したデーモンでは内部socket障害が再発していた |
| 同smoke記録と `.tmp/sbx-socket-20260909-02/` | CPU2・memory2g・固定shell digest・workspaceなし・共有skillsなしで試験。保存済みvms-final.jsonは既存VM `iv-sbx-smoke-20260909-01` / `de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae` のstopped、expected-seven.exit.txtは7、vm-policy-verified.jsonは当該VMのnetwork deny `*`。元ファイル不変とroundtrip-okの回収hashを記録 |
| 同smoke記録の補正点 | sbx cp搬入先はroot所有でagentのGit/書き込みに問題が出た。VM内の搬入コピーだけ所有者をagentへ調整して成立。ホストのACLやglobal Git設定を変えていない |
| `docs/records/decisions/0155-initialize-sbx-network-with-deny-all.md` | Dockerログインと全体network deny-all初期化は実施済み。再ログイン・全体policy再初期化を前提にしない。モデル通信へ必要な許可は現在の実効規則に照らして別途扱う |
| `docs/records/experiments/2026-09-10-v3-capability-followup.md` 00:53節 | SSH転送false/source=overrideを保存し、停止・利用者による通常起動後にも反映を確認。clipboard画像読取false。既存VM同一ID/stopped。動的なSSH拒否は未実証 |
| `docs/working/issues/flow/0136-inspection-delegation-does-not-fire-destructive-verification-row/0136-note-sbx-after-smoke-design-options.md` とADR-0157 | VM内のsudo保有・書き換え可能なGit/ログを信頼側記録と同一視しない。提案作成と、外側基準版を使う別の通信なし環境での採否用再実行を分ける方針が合意済み。今回も採点原本・管理ログを作成側へ渡さない検討に使える |

未確認として残っていたものは実モデル認証・モデル通信、負荷中の強制停止、切断と自動起動の競合、その他ホスト経路など。pids128の外側強制とホストclipboard文字列書込の遮断も未確認で、別プロジェクトではCPU/メモリと外側停止、合成題材限定のclipboard例外を承認していた。この例外や過去の実機承認を今回の比較へ自動移植しない。

**今回の次手の訂正**: 初期導入・Windows機能変更へ進まず、過去の成功した通常起動経路と現在の状態を、起動副作用のない読み取りで照合する。過去記録のrunning/stoppedやログイン済みを現在の状態と断定しない。デーモン停止中はsettings/ls/exec等が自動起動する可能性があるため、通常ユーザー側のdaemon statusを先に確認する。必要になった場合の通常PowerShell起動だけを利用者へ具体的に依頼し、AI内部からstart/restart/resetを代行しない。既存VM・取得イメージ・旧状態退避02/03・試験資材は保全する。

今回、既存VM・デーモン・Windows設定への操作はしていない。Windows機能値と既存API/VM成功記録の差の原因も未確定。管理者操作や再起動が不要であるとの逆方向の断定もせず、変更の必要性を先に確認する。ユーザーによる見落としの指摘と訂正は作業ログ `MakeAiInstructions-2026-09-11-01` に記録した。
