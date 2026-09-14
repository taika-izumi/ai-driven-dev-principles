# 残るsbx能力試験の未特定事項の調査と実機試験案

2026-09-14（Asia/Tokyo）。Issue-0136、`docs/records/experiments/2026-09-10-v3-capability-followup.md` の「実行までに残る事項」の継続調査。目的は、SSH転送拒否・資源実効値・起動世代の取得元と、非自動起動の接続方法を特定し、承認可能な実機試験へ具体化すること。本記録は読み取りだけで作成し、設定・daemon・VMは変更していない。全体実装計画の確定・実機試験の承認・runtimeのverifiedを意味しない。

## 引き継ぎと読み取り結果

- 作業はClaude Code 2.1.270（対話セッション・autoモード、親 claude-fable-5-1）で、既存worktree `.worktrees/isolated-verification`（branch codex/isolated-verification、e2e28c0）から行った。開始時の変更は未追跡 `.tmp/` だけ。
- masterの61ddef3（固定検査の対話セッション実行の実測、Issue-0136の結論）を先に読んだ。規範ADR-0143・0144に変更はなく、本案件の再開経路はIssue-0136が担う。
- `sbx daemon status` は本セッションで3回実行し、いずれも `Status: stopped`、socket `\\.\pipe\docker_kaname_sandboxd (not connected)`。`daemon status --json` の出力は停止中は `status` と `socket` の2項目だけ。statusは停止中でも自動起動しないことをこの3回で確認した（各回の直後も stopped）。
- 状態ディレクトリ `C:/Users/d12an/AppData/Local/DockerSandboxes/sandboxes/state/sandboxd/` の `sandboxd.pid` は3476（2026-09-10 00:52保存）だが、PowerShellの `Get-Process -Id 3476` は該当なし。sandboxd・sbx・nerdbox shimのプロセスも無い。`daemon.log` の末尾は2026-09-13 00:53の定期イベント送信で、停止メッセージが無いまま終わっている。PIDファイルは失効しており、停止理由（OS再起動等）はログから確定できない。
- 2026-09-10 00:52:58に利用者の通常起動で始まった世代（`starting sandboxd`、version v0.42.1 cc6e400）が最後の起動世代。同時刻の `crashes/crash-20260909T155258...-3476.log` は0バイトの空ファイル。
- 公式CLIリファレンス（`docs.docker.com/reference/cli/sbx/...`）は取得しても見出しだけで本文が得られなかったため、導入版0.42.1のローカルヘルプと実行ファイル内の文字列（`grep -a`）を一次資料にした。ヘルプはクライアント側で完結し、実行後もdaemonはstoppedのままだった。

資格情報の値・ホストSSH鍵（`state/sandboxd/docker_sandboxes_ssh_ed25519` は読んでいない）・clipboard内容は読んでいない。runtimeファイルにあるプロキシCA証明書の本文は記録へ複写しない。

## 特定した方式と取得元

| 未特定だった事項 | 特定した内容 | 根拠 |
|---|---|---|
| SSH転送のWindowsでの方式とゲストの入口 | クライアントCLIの `SSH_AUTH_SOCK`（設定 `ssh.agentSocketPath` が空なら各クライアントの現在値）をdaemonが中継し、VMごとにゲスト側ネットワークのゲートウェイ `172.17.0.0:3129`（IPv6も同ポート）に「SSH agent forwarder」を起動する。ゲストからの入口は `/run/ssh-agent.sock`（実行ファイル内の疎通確認文 `test -S /run/ssh-agent.sock && socat -u OPEN:/dev/null UNIX-CONNECT:/run/ssh-agent.sock`）。中継失敗時は `skipping ssh agent relay: SSH_AUTH_SOCK_GATEWAY failed` を出す。Windowsの名前付きパイプ（`\\.\pipe\openssh-ssh-agent`）を指す文字列は無い | daemon.log 223〜224行（2026-09-09 20:18:51、runtime iv-sbx-smoke-20260909-01 で `started SSH agent forwarder`）、sbx.exe の文字列、公式credentials資料 |
| 外側のVM資源割当の取得元 | daemon不要で読める `state/sandboxd/runtimes/<VM名>.json` の `Spec.CPUs`=2、`Spec.Memory`="2g"、`Spec.Template`（digest）、`Spec.ShareSkills`=false、`Spec.WorkspaceDir`=""、`Spec.SSHAgentSocketPath`=""、`ID`。起動時の実効値はdaemon.logのshim行 `guest RAM mapped ... total_mb: 2048` とvCPUスレッド数（`vcpu_idx` 0〜1、`total: 2`）。稼働中は `sbx inspect <VM名> --json`（状態・認証モード・workspace・ネットワークポリシー等）も使える | runtimeファイル、daemon.log 2126〜2130行、`sbx inspect --help` |
| daemon起動世代の取得元 | `state/sandboxd/sandboxd.pid` のPID、daemon.logの `starting sandboxd`（time・version）、OS側の `Get-Process sandboxd` のId・StartTime の3つを対応付ける。PIDファイルは失効しうるので単独では使わない。稼働中の `daemon status --json` の項目は未確認 | 本記録「読み取り結果」 |
| 非自動起動の接続方法 | 専用フラグは無い。`exec` は「停止VMを先に起動する」と明記され、`--no-start` 相当の文字列も無い。手順で代替する: (1) `daemon status`（自動起動しない）でrunningを確認、(2) runtimeファイル（daemon不要）で対象VMのIDと割当を読む、(3) 操作直前と直後に起動世代（PID・StartTime）を比較し、変化していれば結果を採用しない。`ls`・`inspect`・`settings` が停止中に自動起動するかは未確認のため、停止中は呼ばない | `sbx exec --help`、`sbx --help`、実行ファイル内文字列 |

`sbx policy check network`（読み取り専用でdaemon側の認可器を評価）と `sbx policy log [VM名] --json`（プロキシの許可・拒否記録）は、通信拒否試験の外側証拠として使える。

## 実機試験案（提示時点は未承認・未実施）

すべて新規VM1台 `iv-sbx-capability-20260914-01` を順に使い、同時1VMを守る。既存VM `iv-sbx-smoke-20260909-01`（ID de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae）は起動・削除しない。create引数は承認済みの固定argvから名前だけ変える。

```powershell
sbx create shell --name iv-sbx-capability-20260914-01 --cpus 2 --memory 2g --no-share-skills --deny-network '*' --template docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476
```

前提: 利用者が通常PowerShellで `daemon start -d` を実行し、AIが `daemon status` でrunningを確認する。転送false/source=overrideの再照会、既存VMの同一ID/stoppedの確認、起動世代の記録を先に行う。設定変更は行わない（ADR-0162の結果を使う）。

### 試験A: SSH転送拒否の動的実証

| 観点 | 方法 | 合格条件 | 不合格条件 |
|---|---|---|---|
| 外側 | 新VMのcreate直後にdaemon.logを検索する | 当該runtime名で `started SSH agent forwarder` が出ない。対照として2026-09-09の旧VMには同行がある | 同行が出る |
| ゲスト | `test -S /run/ssh-agent.sock`、`printenv SSH_AUTH_SOCK`、Pythonで `172.17.0.0:3129` へTCP接続 | ソケット不在、変数未設定、3129は接続拒否。対照として同ホストの3128（プロキシ）には接続できる（ネットワーク経路自体は生きている証拠） | ソケットが存在、または3129へ接続できる。空の鍵一覧は接続できた可能性があるので不合格 |
| クライアント側 | create/exec時のCLI環境に `SSH_AUTH_SOCK` を実在しない試験用パスに設定する | 中継が起きず上記のゲスト結果が変わらない | ゲスト側に転送が現れる |

実鍵の `ssh-add -L`・署名は使わない。ゲストのagent・root両方で確認する。

### 試験B: CPU・メモリ実効値

runtimeファイルの `Spec.CPUs`/`Spec.Memory`、daemon.logの `total_mb` と vCPU数、ゲストの `nproc` と `/proc/meminfo` の `MemTotal` を対応付ける。合格は外側2048MiB・2vCPUと、ゲストnproc=2。MemTotalは予約領域で減るため完全一致を要求しない。ゲスト値だけで外側強制としない。

### 試験C: 有限負荷中の外側停止

固定スクリプト（最大2 worker、合計256MiBまでの明示確保、20秒で自己終了、ログ1MiB以下）をsbx cpで搬入し、`exec -d` で開始。開始を確認してから5秒後に外側から `sbx stop iv-sbx-capability-20260914-01`。合格は30秒以内に `ls --json` で同一IDのstopped、daemon.logに `vCPU thread exiting` / `joined 2/2`。負荷開始前の失敗を停止成功に数えない。停止未確認・ホスト応答低下は中止。fork bomb・資源枯渇は含めない。スクリプトの本文とhashは承認前に提示する。

### 試験D: 起動世代と競合の検知

A〜Cの各操作の前後で（PID, StartTime, `starting sandboxd` の時刻）を記録し、変化が無いことを確認する。変化があれば当該結果を不採用にする。daemon停止を伴う競合注入は本案に含めず、別承認とする。

停止後はVMとログを残し、削除しない。試験の記録は `.tmp/sbx-capability-20260914/` に置き、採用する証拠だけを本記録へ転記する。

## 承認が必要な操作と含めないもの

- 利用者: 通常PowerShellでの `daemon start -d` 1回と起動完了の返信。
- AI: 新規VM1台のcreate、固定スクリプトのcp、exec（負荷・照会）、stop、runtimeファイル・daemon.log・policy logの読み取り。
- 含めない: 設定変更、既存VMの操作、VMの削除・reset、モデル起動・認証、別イメージ、daemon停止を伴う競合試験、clipboard操作。

## 根拠と信頼性

- 導入版sbx 0.42.1のローカルヘルプと実行ファイル内文字列、状態ディレクトリのruntimeファイル・daemon.logが当該PCの一次証拠。ログの該当行番号は本記録に示した。実行ファイル内文字列は機能の存在を示す傍証であり、動作の証明ではない。
- [Docker公式の資格情報設定](https://docs.docker.com/ai/sandboxes/configuration/credentials/): 転送の既定有効、クライアントの `SSH_AUTH_SOCK` の中継、固定socket設定、変更後の再起動。Windows固有の方式は公式資料に記載が無く、本記録のゲート・ゲスト入口の特定はローカル証拠による。
- [Docker公式のトラブルシュート](https://docs.docker.com/ai/sandboxes/troubleshooting/): 鍵一覧が空でもagentへ到達している場合がある。空一覧を拒否と扱わない根拠。
- 公式CLIリファレンスの各ページは本文が取得できなかった（2026-09-14）。将来版で確認する場合は再取得する。
