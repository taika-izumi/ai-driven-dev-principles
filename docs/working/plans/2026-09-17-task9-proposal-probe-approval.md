# タスク9: 提案用VMの証拠取得2台の操作承認案

- 当初試験の結果: 承認済み操作の1台目で通信規則の不一致を検出し、中断・停止済み（runId: f107bb84-4dde-402f-ad72-b58057ee5451）。OAuth登録は確認済み。既存5台を含む6台すべてstopped。2台目は未実施。実測では2ホストは443番限定であり、全ポートという前提を訂正する必要がある。結果・修正案は `docs/records/experiments/2026-09-17-v3-task9-proposal-probe-first-attempt.md`。この停止条件に達したため、以下の当初承認をそのまま再試行へ流用しない。
- 前提の読取り確認（2026-09-17）: sbxデーモンrunning、既存VM5台はすべてstopped、secret lsは登録0件。更新通知は出たが、sbxは更新していない。
- 適用方針: 2026-09-17に再改訂したADR-0199。OAuthのセンチネル方式、auth.openai.com:443とchatgpt.com:443の2件を許可。その他11ホストを全ポート拒否。受信ポートの公開は追加しない。

## 2026-09-17の再試験承認

利用者は初回結果と具体的な修正案の提示に「1で」と回答した。443番限定へ設計・判定処理を訂正し、修正・検証後に新規VM2台で再試験することを承認済み。OAuth再登録は不要。以下の資源・時間制限・試験順序・停止条件を維持し、既存保全対象は今回の失敗VMを含む6台へ更新する。2台はそれぞれ新しいrunIdを発行し、失敗runのResumeは使わない。今回の承認でモデル往復・daemon操作・削除は行わない。

## 利用者が行うこと（初回承認時。登録済み）

承認後、通常の端末で次を実行し、sbxが示す認証手続きを行う。AIは秘密の値を受け取らない。

```powershell
& 'C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe' secret set openai --oauth
```

保存したOAuth情報は同じデーモンの全サンドボックスで共有され、単一VMへ限定できない。既存5台は停止のまま保全する。資格情報の後片付けは別の確認点で扱う。

## AIが承認後に行う操作

新規VMを2台、同時に1台だけ作る。VM名はスクリプトが発番する新規UUIDを使う `iv-<先頭8桁>-proposal`。2回で異なるrunIdを発番し、同名が一覧にあれば作成しない。既存名は再利用しない。

1. 1台目（limitsAndTransport）: 作成直後のagent/session状態、Pythonと標準ライブラリ、固定した小さな合成題材の搬入とunittest、終了0/7/127・時間超過・クライアント強制終了の対照、出力上限、通信規則・資格情報の真偽確認、SSH否定確認・資源値を取得し、外側stopと同一IDのstopped確認を行う。
2. 2台目（abnormalExitRecovery）: 作成直後を確認して保持セッションを開始し、probe自身を強制終了する。その後に保存済みrunRootで再開し、保持プロセス消失・自動停止・記録済みIDだけの復旧操作を確認する。停止後にexec/cpを出さない。

操作の上限: 各VMはCPU2・メモリ2GiB。各probeの全体上限は3600秒、個別execは120秒、照会・stopは60秒、作成・搬入等は240秒、停止猶予30秒、出力は各コマンド16MiBまで。所要は初期確認や時間超過対照を含め合計15〜25分程度の見込みで、実測ではない。

実行設定は `.tmp/task9-probe-approval/proposal-probe-settings.json`。記録先は `.tmp/probe-9/<runId先頭8桁>/`。固定テンプレートは既存の `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`。

```powershell
& 'C:/Users/d12an/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe' -NoProfile -File 'D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/scripts/verification/tests/Invoke-SbxPilotProbe.ps1' -Role proposal -ProposalPhase limitsAndTransport -SettingsPath 'D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/.tmp/task9-probe-approval/proposal-probe-settings.json'
```

2台目はProposalPhaseをabnormalExitRecoveryとして同じ設定で起動する。自己終了後の再開には、その実行が保存したrunRootをResumeに指定する。

## 境界と停止条件

この承認に通常のモデル依頼・修正候補の往復、任意のリポジトリの搬入、デーモン起動/停止/再起動/reset、更新・導入、既存VMの操作、VM削除、公開・統合を含めない。ただしcodexキットの作成直後の挙動は初回の実測対象であるため、認証・通信の設定は作成時から有効になる。

初回にagentが想定外に稼働している、規則・資格情報・資源値が要件と異なる、照会不能、想定外のVM稼働等があれば先へ進めず停止する。通信の許可をAIが追加しない。作成したVMは停止したまま診断用に残す。既存VMの保全は初回と最終の全一覧・ID・状態と発行コマンドで主担当が照合する。
## 搬入する固定題材の実体

| ファイル | バイト数 | SHA256 |
|---|---:|---|
| scripts/verification/tests/fixtures/pilot-source/source/calc.py | 270 | E40D22A2B4FD4ADD9465412538146029101FFF844DC0916D051C3FDBBF904DD8 |
| scripts/verification/tests/fixtures/pilot-source/tests/test_calc.py | 383 | 804B2B3C12EF71CF8F8B7A81934D717F299EBFE9EF1842DE8B9CAF6F240A727B |

搬入先は対象VM内の/home/agent/workspace/source。cp後にagent所有へ調整する。cpが親ディレクトリ欠落で失敗した場合は対象VM内の親ディレクトリを作成して再試行し、事実を記録する。ホスト側の所有者・権限は変更しない。

## 操作承認と開始前確認

2026-09-17、利用者が本操作案を示した確認に「1で」と回答し、記載したOAuth登録と提案用VM2台の実機確認を承認した。再確認時点でdaemonはrunning、既存5台はすべてstopped、secret lsはNo secrets found。認証登録完了後にこの承認範囲で続行し、同じ操作承認は取り直さない。新規VMはまだ作成していない。
