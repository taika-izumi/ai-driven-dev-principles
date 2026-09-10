# 編集成立と原本保護を両立する実行方法の調査

状態: 2026-09-11、ADR-0179の通常起動成功後、ユーザーの「OKです。進めてください」に基づく実現可能性調査。候補は未採用。インストール・Windows機能変更・VM/コンテナ作成・モデル起動は行っていない。

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
