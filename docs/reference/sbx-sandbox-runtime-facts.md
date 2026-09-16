# Docker Sandboxes（sbx）の実測挙動と隔離環境設計への含意

隔離検証の共通起動処理（仕様 `docs/current/specs/2026-09-09-isolated-verification/`）の準備で、本PC（Windows 11、sbx 0.42.1）で実測した sbx の挙動をまとめる。将来、独立レビュー以外の用途（複数のAIエージェントを隔離環境で協働させる構成など）で隔離環境を設計するときに、最初に読み返す前提知識として置く。数値・挙動は実測した版・環境のものであり、将来版や別OSの保証ではない。各項目の一次証拠は末尾の関連記録にある。

## 確認済みの隔離能力

| 要件 | 確認内容 | 状態 |
|---|---|---|
| 原本を隔離環境から変更できない | workspace を渡さずに作った VM にはホストのマウントが無い（/proc/mounts に resolv.conf と hosts の読み取り専用だけ）。VM は別カーネル（Windows Hypervisor Platform 上）で動く | 実測済み（2026-09-09、09-14） |
| 複製を読める・編集できる | 外側で作った独立コピーを `sbx cp` で搬入し、所有者を agent に調整すれば VM 内で Git 照会・ファイル生成ができる。VM 内では sudo が使える | 実測済み（2026-09-09） |
| 成果物を外へ取り出せる | `sbx cp VM:PATH ホスト` で回収できる。仕様は、子が改変しうる回収物を tar 展開せずデータ列として検査する経路を要求しており、こちらは未実装 | 取り出しは実測済み、安全な検査経路は設計のみ |
| 通信の拒否 | 作成時の `--deny-network '*'` で、HTTP プロキシは 403、任意ポートへの接続は policy log に拒否として記録される。許可リスト方式の設定も製品にあるが未実測 | 拒否は実測済み（2026-09-14） |
| SSH エージェント転送の拒否 | 設定 `ssh.agentForwardingEnabled=false` の新世代では VM ごとの forwarder が作られず、ゲストの `/run/ssh-agent.sock` も無い | 実測済み（2026-09-14、ADR-0162） |
| クリップボード | ホストの画像読取は既定で無効。VM からホストへの文字列書込は製品機能で、遮断する設定が見つからない。試作限定の例外として受容（ADR-0161） | 遮断不可と判断 |
| 資源割当 | `--cpus 2 --memory 2g` は外側の runtime ファイルと daemon.log（vcpu_count 2・total_mb 2048）に記録され、ゲストの nproc と MemTotal が対応する。プロセス数上限は製品に無い | 実測済み（2026-09-14、ADR-0160） |
| 外側からの停止 | 負荷実行中に `sbx stop` すると数秒で同一 ID が stopped になり、VM 内のプロセスは強制終了（終了コード 137）される | 実測済み（2026-09-14） |

## 設計に直接効く挙動

### 30秒の自動停止と、クライアント操作による自動起動

- VM に接続している全セッション（`exec`・`cp` などのクライアント接続）が切れると、デーモンは 30 秒の猶予後に VM を停止する。daemon.log の順序は `session disconnected, deferring auto-stop`（delay=30s）→ `auto-stop grace period expired, stopping runtime` → `auto-stopped runtime after last session disconnected`。
- 停止してもディスクは残る。失われるのはメモリ上の状態と実行中のプロセス。
- 外側から `stop` で停止したあとも、約30秒後に同じ VM の `auto-stopped runtime after last session disconnected` 行が出る（2026-09-16 のタスク8b で2台とも実測。停止でクライアント接続が切れ、遅延停止のタイマーが停止済みの VM に発火するため）。含意: 停止の証拠は「stop 発行時刻以後の `stopped runtime container` 行」で判定し、あとから出る自動停止行を停止失敗や再起動の痕跡と読まない。
- 停止した VM は勝手には起動しない。次の `exec`・`cp` が「停止中なので先に起動する」と動く（出力に `Sandbox ... started successfully`）。停止完了と新セッションが重なった場合は `auto-stop complete, new session waiting` として停止完了後に起動し直す。
- `exec` に「停止中なら起動しない」指定は無い。
- 含意: エージェントを VM 内で走らせる間はクライアント接続を保持する。接続を切って 30 秒以上空けると次の操作は再起動を伴うため、背景プロセスに依存しない。停止確認では、自動停止と外側からの停止を daemon.log の行で区別する。30 秒が設定で変えられるかは未確認。

### 透過プロキシは TCP 接続をいったん受ける

- deny-all でも、ゲートウェイの任意ポートへの TCP 接続は成立してから拒否される（データは返らず、policy log に拒否が残る）。接続成立を「到達できた」証拠にしない。到達可否はプロトコル応答と policy log で判定する。
- ゲストの `SSH_AUTH_SOCK` は転送無効でも `/run/ssh-agent.sock` に設定されている。環境変数の有無で判定しない。

### SSH エージェント転送の実体

- クライアント CLI の `SSH_AUTH_SOCK`（設定 `ssh.agentSocketPath` が空なら各クライアントの現在値）をデーモンが中継し、VM ごとにゲートウェイ（例: 172.17.0.2）の 3129 番に forwarder を立てる。ゲスト側の入口は `/run/ssh-agent.sock`。
- 設定変更はデーモン再起動後に反映される。転送を戻すには設定を既定へ戻す操作と再起動が別途必要。

### デーモンの起動元と世代

- デーモンは `sbx.exe` のプロセスとして動く。起動世代は状態ディレクトリの `sandboxd.pid`、daemon.log の `starting sandboxd` 行（時刻・版）、OS プロセスの StartTime の 3 つを対応付けて識別する。PID ファイルは失効しうるので単独では使わない。
- `sbx daemon status` は停止中でも自動起動しない（2026-09-14 に 3 回確認）。`ls`・`inspect`・`settings` が停止中に自動起動するかは未確認のため、running を確認してから呼ぶ。
- 本PCでは、AI ツールの制限付きプロセスから起動したデーモンが内部ソケット障害を起こした記録があり、利用者の通常端末からの起動を前提にしている（ADR-0162、smoke 記録）。

### 外側の記録の所在

- 状態ディレクトリ `C:/Users/<user>/AppData/Local/DockerSandboxes/sandboxes/state/sandboxd/`。VM ごとの `runtimes/<VM名>.json`（ID・CPUs・Memory・Template digest・ShareSkills・WorkspaceDir・SSHAgentSocketPath）はデーモン停止中でも読める。`daemon.log` に起動・ネットワーク・shim（vCPU 数・メモリ）・停止の行がある。
- 稼働中は `sbx inspect <VM名> --json`、`sbx policy ls <VM名> --json`、`sbx policy log <VM名> --json` が使える。
- 同ディレクトリにデーモンの SSH 鍵や資格情報の結び付け設定があるため、記録へ複写しない。

## 未実測の製品機能（設計候補）

- `sbx create --clone`: 原本の Git リポジトリを VM 内に読み取り専用でクローンして作業させ、エージェントのコミットをホスト側の `sandbox-<name>` という git remote から取り出す。現行仕様は採用していない。
- ワークスペースの `:ro` 指定（読み取り専用マウント）。
- モデル接続先だけを許す許可リストと、プロキシによる API キーのヘッダー注入（raw の認証値を VM に渡さない方式）。runtime ファイルに設定の痕跡はあるが未実測。
- 複数 VM の同時稼働。現行仕様の「同時 1 VM」は本プロジェクトの試作条件であり、製品の制限ではない。

## 費用感

- VM 作成は取得済みイメージで約 1 分、メモリは指定値をホストから確保する。エージェント 1 体につき 1 VM なら台数分の資源が要る。
- 有限負荷（2 worker・256MiB・20 秒）中の外側停止は約 6 秒で完了した。

## 関連記録

- 実測: `docs/records/experiments/2026-09-14-v3-capability-test-methods.md`（試験A〜D、申し送り）、`2026-09-10-v3-capability-followup.md`、`2026-09-09-v3-runtime-preflight.md`、`2026-09-09-sbx-smoke.md`、`2026-09-09-sbx-preflight.md`
- 決定: ADR-0157〜0162、ADR-0192
- 仕様: `docs/current/specs/2026-09-09-isolated-verification/`
