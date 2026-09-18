# 2026-09-16 タスク8a: AIなしの実VMで再実行・停止・記録を実証した記録

隔離検証 v3 実装計画のタスク8a。利用者が 2026-09-16 に個別承認した範囲（probe 用の新規VM 1台・固定 argv・AIなし・既存VM2台は `ls --json` の一覧読取りのみ・削除もデーモン操作もなし）で、外側の記録だけを使って再実行・停止・記録の実体を測った。本記録は `scripts/verification/profiles/replay/activation-evidence.json` が (8a) の条件の証拠として SHA256 で指すファイルであり、**以後追記しない**（追記が必要なら profile を再生成する）。

## 実施条件

| 項目 | 値 |
|---|---|
| 実施日時 | 2026-09-16 09:27:50〜10:01:17（JST）。probe 1本目が (1)〜(6) と自己終了まで、2本目（`-Resume`）が (7) |
| 作業場所 | `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`（ブランチ `codex/isolated-verification`、着手時 HEAD `0c2e5eb`） |
| sbx 実行ファイル | `C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe` |
| デーモン | 利用者が通常端末で起動。PID 25888、プロセス開始 2026-09-16 08:59:47、`daemon.log` の最後の `starting sandboxd` 行の `version` は `v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64`、socket `\\.\pipe\docker_kaname_sandboxd` |
| 状態ディレクトリ | `C:\Users\d12an\AppData\Local\DockerSandboxes\sandboxes\state\sandboxd\` |
| 作成したVM | 名前 `iv-48830e99-probe`、ID `f0272f46-49bb-4d67-99ba-12468c153c6b`（runId `48830e99-55e7-4d2b-bacd-615d11eb29c3` の先頭8桁＋role）。**最終状態は stopped。削除していない** |
| 既存VM | `iv-sbx-capability-20260914-01`（`0baac92d-…`）・`iv-sbx-smoke-20260909-01`（`de1ba0ac-…`）。開始時・終了時とも stopped。`ls --json` 以外のコマンドを一切発行していない（発行記録は下記「発行した sbx コマンドの全件」） |
| 使った道具 | `scripts/verification/tests/Invoke-SbxPilotProbe.ps1`（本タスクで新規作成）と `tests/fixtures/probe-settings.json`。probe は `Invoke-IsolatedVerification.ps1` を通さず、自前の足場 run を作って sbx CLI を固定 argv で直接起動する |
| 観測の保存先 | `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/.tmp/probe-8a/48830e99/`（未追跡。`obs/` に手順ごとの観測 JSON、`cli/` に各コマンドの stdout/stderr 原文、`calls.jsonl` に発行した全 argv、`control/runtime/` に作成記録と復旧結果） |

起動コマンド:

```
pwsh -NoProfile -File D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/scripts/verification/tests/Invoke-SbxPilotProbe.ps1
pwsh -NoProfile -File D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/scripts/verification/tests/Invoke-SbxPilotProbe.ps1 -Resume D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification/.tmp/probe-8a/48830e99
```

1本目が (1)〜(6) と probe 自身の強制終了までを行い、2本目（`-Resume`）が強制終了後の観測と復旧操作を行う。

## (1) 版と標準ライブラリ

| 観測 | 値 | 出所 |
|---|---|---|
| `python3 --version` | `Python 3.14.4`（**stdout**。stderr は0バイト） | `obs/01-version-stdlib.json`、`cli/008-python3-version.out` |
| `python3 -c 'import sys;print(sys.version)'` | `3.14.4 (main, Jun 18 2026, 14:25:02) [GCC 15.2.0]` | `cli/009-python3-full-version.out` |
| `sys.stdlib_module_names` | 297 件。`profiles/replay/stdlib-modules.txt` として保存（SHA256 `3FEAAF08C67C2F492EE697B05673E39ADF71C0A3EAECD6B5A8BD0A6172CE275B`） | `obs/stdlib-modules.txt` |

`tests/fixtures/stdlib-modules.txt`（300件、試験専用）とは内容が異なる。fixture は試験専用で実 run には使わない旨が実装計画にあり、差し替えない。

## (2) 搬入・所有者調整・搬入照合・unittest 1本

発行した順序と argv（`Copy-VerificationSandboxInput` → `Confirm-VerificationSandboxInput` → 再実行の固定 argv と同一）:

```
cp <搬入元> iv-48830e99-probe:/home/agent/workspace/source
exec -u root iv-48830e99-probe chown -R agent:agent /home/agent/workspace/source
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "cd /home/agent/workspace/source && find . -type f -print0 | sort -z | xargs -0 sha256sum"
exec -w /home/agent/workspace/source iv-48830e99-probe python3 -m unittest discover -s .verification-tests -p test_*.py -v
```

搬入元は `tests/fixtures/pilot-source/` から組んだ `calc.py` と `.verification-tests/test_calc.py` の2ファイル。

| 観測 | 結果 |
|---|---|
| `cp` | 終了0。**親ディレクトリ `/home/agent/workspace` を先に作る必要はなかった**（probe に備えた再試行経路は発動していない） |
| `cp` の配置 | 搬入元ディレクトリの**中身**が `/home/agent/workspace/source` 直下に置かれる（入れ子にならない）。`Copy-VerificationSandboxInput`＋`Confirm-VerificationSandboxInput` の前提どおり |
| `chown` | 終了0 |
| 搬入照合 | `sha256sum` の出力は `<64桁小文字>  ./<相対パス>` 形式。`Confirm-VerificationSandboxInput` の正規表現 `^([0-9a-f]{64})  (?:\./)?(.+)$` と一致。欠落・予定外・相違なし |
| unittest | 終了1（合成題材の既知の欠陥を再現）。**要約行 `Ran 1 test in 0.001s` は stderr に出る。stdout は0バイト** |

`Replay.psm1` の出力署名 `@{pattern='Ran \d+ tests? in';stream='stderr'}` は実機と一致した。実測した stderr 原文は `tests/fixtures/fake-sbx-responses/unittest-fail.txt` へ差し替えた。

## (3) transport 対照5種

いずれも `exec -w /home/agent/workspace/source iv-48830e99-probe …` の固定形。外側が観測した値:

| 対照 | 発行した argv | 外側の exitCode | stderr | 記録した stderrKind |
|---|---|---|---|---|
| exit0 | `sh -c "exit 0"` | 0 | 0バイト | `empty` |
| exit7 | `sh -c "exit 7"` | 7 | **0バイト** | `empty` |
| exit127 | `sh -c "no-such-command-probe-8a"` | 127 | `sh: 1: no-such-command-probe-8a: not found` | `shell-not-found` |
| 時間超過 | `sh -c "sleep 300"`（上限 `replaySeconds`=120秒） | **null**（打ち切りで消す） | 0バイト | `none-client-killed-by-outside` |
| クライアント強制終了 | `sh -c "sleep 600"` を背景起動し、5秒後に外側から木ごと停止 | **null** | 0バイト（stdout も0バイト） | `none-client-killed-by-outside` |

時間超過は `timedOut=true`、クライアント強制終了は `processTreeStopped=true`。どちらも外側は終了コードを得ない。

## (4) 出力洪水

`exec -w … python3 -c 'import sys;list(iter(lambda: sys.stdout.write("x"*4096+chr(10)), None))'`、合算出力上限 `maxOutputBytes`=16,777,216 バイト。

| 観測 | 値 |
|---|---|
| 打ち切り | `outputExceeded=true` |
| 実際に書き出した合計 | 16,797,696 バイト（上限＋最後の読み出し1回分。上限は「超えたら止める」であり、切り詰めた出力を成功として渡さない） |
| exitCode | null（打ち切った実行の終了コードは採否に使わせない） |

## (5) 照会

| 照会 | 観測 |
|---|---|
| `inspect <name> --json` | `state=running`、`image_digest=sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476`（profile の `templateDigest` と一致）、`secrets` は `mcpgateway` の1件だけ、`mcp_gateway=true`、`network_policy.scope=sandbox` |
| `policy ls <name> --json` | `resource_type=network`・`decision=deny`・`resources=["*"]`・`scope=sandbox:iv-48830e99-probe`・`status=active` の規則が1件。ほかに `filesystem:read`／`filesystem:write` の全許可規則（`scope=global`）があるが、製品の既定であり `Get-VerificationNetworkRules` は network 以外を見ない |
| `settings get --json clipboard.imagePaste` | `value=false`、`source=default` |
| `settings get --json ssh.agentForwardingEnabled` | `value=false`、`source=override`、`default=true`、`requires_restart=true` |
| `settings get --json ssh.agentSocketPath` | `value=""`、`source=default` |
| `mcp ls --json` | `servers` は空配列。`gateway` は `LOCAL`（`local=true`、`operator=managed by you`。利用者識別子は本記録から除いた） |
| `runtimes/iv-48830e99-probe.json` | `ID=f0272f46-…`、`Spec.WorkspaceDir=""`、`Spec.ShareSkills=false`、`Spec.CPUs=2`、`Spec.Memory="2g"`、`Spec.SSHAgentSocketPath=""`、`Spec.Template` は上記 digest |
| `daemon.log` の当該 runtime 行 | 156行。`started SSH agent forwarder` は**0件**。MCP ゲートウェイの起動行（`mcp gateway started`・`mcp: registered gateway credential in secrets store`）は製品挙動として残る（ADR-0195） |

## (6) 約30分の連続保持

VM 作成直後から張っている保持 exec（`exec iv-48830e99-probe sh -c "sleep 7200"` を背景起動。ADR-0193）だけで、ほかのコマンドを1本も出さずに 1800 秒（2026-09-16 09:30:29〜10:00:32 JST）経過させた。保持中は sbx を叩かず（叩くと新しいセッションになる）、60秒ごとに daemon.log の読取りと保持プロセスの存否だけを見た（30回）。

| 観測 | 結果 |
|---|---|
| 保持プロセス（sbx クライアント PID 24628） | 30回の確認すべてで生存。保持終了時も生存 |
| 作成後の `auto-stopped runtime after last session disconnected` 行 | 保持中も保持終了後も **0件** |
| 保持終了後の `ls --json` | 同一 ID `f0272f46-…` が `running` |

実測の自動停止猶予は30秒なので、保持が無ければ最初の60秒の区間で停止していた。**セッション保持 exec 1本で約30分 VM を保てることを実証した。**

## (7) probe プロセスの強制終了と復旧操作

CLI の異常終了を模して、probe プロセス（PID 28344）を `Stop-Process -Id $PID -Force` で自らを落とした（10:00:34 JST）。保持 exec は probe プロセスが持つ Job オブジェクトに属するので、ハンドルが閉じると `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` で木ごと止まる。続きは別プロセス（`-Resume`）で観測した。

| 観測 | 結果 |
|---|---|
| probe プロセス（28344） | 消滅 |
| 保持プロセス（24628） | 消滅（外側が明示的に止めたのではなく、ジョブハンドルが閉じたため） |
| daemon.log の自動停止行 | `{"time":"2026-09-16T10:01:09.4858264+09:00",…,"msg":"auto-stopped runtime after last session disconnected","runtime":"iv-48830e99-probe"}` が1件。強制終了の約35秒後（猶予30秒＋検知） |
| 復旧操作 `Stop-VerificationRecordedSandboxes` | 対象1件（`control/runtime/probe-sandbox.json` の記録済み ID）。`stateBefore=stopped` → `stopState=stopped`。すでに停止していたので `stop` を**発行していない**。結果は `control/runtime/recovery-20260916T010117176.json` |
| 復旧操作が発行した sbx コマンド | `daemon status --json` ×2、`ls --json` ×1 のみ（`control/runtime/recovery/` の出力ファイルが全件）。記録に無いVMには一切触れていない |
| 既存VM2台 | 強制終了の直前・復旧操作の後とも `stopped` のまま不変 |
| 停止確認後の当該VM名へのコマンド | 0件（`calls.jsonl` で確認） |

停止済み対象の `stopState=stopped` は `ls --json` の同一 ID・`stopped` だけを根拠とし、停止証拠ファイル（`evidencePath`）は作らない。外側が `stop` を発行していないので `stopped runtime container` 行を照合対象にしないためで、設計どおり。

**この経路で実証していないこと**: 復旧操作が実際に `stop` を発行して止める経路（対象が running のまま残っている場合）は、今回は自動停止が先に完了したため実機では動いていない。偽sbx の試験（SbxRuntimeV3）では確認済み。

## 発行した sbx コマンドの全件

`calls.jsonl` の全27件（probe が発行したもの。復旧操作の3件は別。既存VM2台の名前を含む argv は0件）。

```
daemon status --json
ls --json
settings get --json clipboard.imagePaste
mcp ls --json
create shell --name iv-48830e99-probe --cpus 2 --memory 2g --no-share-skills --deny-network * --template docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476
ls --json
exec iv-48830e99-probe sh -c "sleep 7200"                          （保持。背景起動）
exec iv-48830e99-probe python3 --version
exec iv-48830e99-probe python3 -c "import sys;print(sys.version)"
exec iv-48830e99-probe python3 -c "import sys;print(chr(10).join(sorted(sys.stdlib_module_names)))"
cp <搬入元> iv-48830e99-probe:/home/agent/workspace/source
exec -u root iv-48830e99-probe chown -R agent:agent /home/agent/workspace/source
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "cd /home/agent/workspace/source && find . -type f -print0 | sort -z | xargs -0 sha256sum"
exec -w /home/agent/workspace/source iv-48830e99-probe python3 -m unittest discover -s .verification-tests -p test_*.py -v
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "exit 0"
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "exit 7"
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "no-such-command-probe-8a"
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "sleep 300"        （時間超過対照）
exec -w /home/agent/workspace/source iv-48830e99-probe sh -c "sleep 600"        （クライアント強制終了対照。背景起動）
exec -w /home/agent/workspace/source iv-48830e99-probe python3 -c "import sys;list(iter(lambda: sys.stdout.write(\"x\"*4096+chr(10)), None))"
inspect iv-48830e99-probe --json
policy ls iv-48830e99-probe --json
settings get --json clipboard.imagePaste
settings get --json ssh.agentForwardingEnabled
settings get --json ssh.agentSocketPath
mcp ls --json
ls --json
```

sbx CLI へ渡した環境は `SystemRoot`・`USERPROFILE`・`LOCALAPPDATA`・`APPDATA`・`TEMP`・`PATH`（sbx の親ディレクトリのみ）の明示辞書だけで、`SSH_AUTH_SOCK` は渡していない。

## 生成した実行設定（profiles/replay/）

本記録の観測から `scripts/verification/profiles/replay/` の3ファイルを作った。条件ごとの証拠の割り当ては `scripts/verification/profiles/evidence-checks.md`（verified の意味の正本）に従う。

| ファイル | 内容 |
|---|---|
| `stdlib-modules.txt` | (1) で取った 297 件の標準ライブラリ名 |
| `activation-evidence.json` | `binaries`（sbx の版・python3 の版）、`profileHash`、条件8件、`transportContrast` 5種（(3) の実測値） |
| `profile.json` | `role=replay`・`agent=shell`・`model=null`・`sbxVersion=0.42.1`・固定テンプレート digest・`scope=synthetic-pilot`・`acceptedLimitations` 3件・標準ライブラリ一覧と証拠の SHA256 |

条件ごとの証拠:

| 条件名 | verdict | 証拠ファイル | 根拠にした観測 |
|---|---|---|---|
| `daemonHealthAndTemplate` | verified | 本記録 | (5) の `inspect` の `image_digest` 一致、`daemon status` の running、daemon.log の `starting sandboxd` の版 |
| `noWorkspaceNoSkillsNoMcp` | verified | 本記録 | (5) の `runtimes/<名>.json` の `WorkspaceDir=""`・`ShareSkills=false`、`mcp ls --json` の `servers` 空 |
| `abnormalExitRecovery` | verified | 本記録 | (7) の保持消失・自動停止行・復旧操作・既存VM不変・停止後の未発行 |
| `hostPathIsolation` | verified | `2026-09-14-v3-capability-test-methods.md` | (5) の forwarder 行0件・`SSHAgentSocketPath=""`・`clipboard.imagePaste=false` に加え、ゲスト側の否定確認（試験A）は既存記録が正本 |
| `resourceAndOutsideStop` | verified | 同上 | (5) の `CPUs=2`・`Memory="2g"` に加え、ゲスト側実効値（試験B）と負荷中の外側停止（試験C）は既存記録が正本（`evidence-checks.md` の replay 列の定義どおり。ADR-0197 の例外は proposal 役の話で、ここには関係しない） |
| `replayNetworkDeny` | verified | 同上 | (5) の `policy ls` の deny `*` に加え、拒否応答の実証（試験A）は既存記録が正本 |
| `limitsAndTransport` | verified | 同上 | (3) の transport 対照5種と (4) の出力洪水に加え、外側 `stop` による停止確認（試験C）は既存記録が正本 |
| `daemonDisconnect` | **unverified** | 本記録 | ADR-0196。verified と書ける観測は対応表に無い。補償機構（実コマンド直前の世代確認・自動停止痕跡の検知）の偽 fixture 試験の結果は下記ランナー結果の SbxRuntimeV3 |

(8a) と (既存) の両方を根拠にする条件は、schema が条件あたり1つの証拠ファイルしか持てないため、**既存記録側を `evidencePath` に固定した**（委譲元の指示どおり）。(8a) 側の観測は本記録にあり、上表が対応を示す。

`credentialMethod`・`modelEndpointAllowOnly` は replay 役には不要なので入れていない（タスク9で proposal 用 profile を作るときに確定する）。

## 偽sbxの応答の差し替え

(3)(2) の実測で、これまで創作（`synthetic: true`）だった応答を差し替えた。

| 応答 | 変更 |
|---|---|
| `exec7`（`exec-7.txt`） | 創作の文言を削除し**0バイト**に。`synthetic: false` |
| `exec127`（`exec-127.txt`） | 実測の `sh: 1: no-such-command-probe-8a: not found` に差し替え。`synthetic: false` |
| `unittestFail`（`unittest-fail.txt`） | 実測の stderr 原文（Python 3.14.4 の `unittest -v` 出力）に差し替え。`synthetic: false` |
| `execClientKilled`（`exec-client-killed.txt`） | 出力が0バイトであることは実測できた（外側の観測は `exitCode=null`・`processTreeStopped=true`）。ただし偽sbxは「外側からのクライアント強制終了」自体を再現できず、`exitCode: -1` は偽sbxを終わらせるための創作値のまま。よって `synthetic: true` を維持し、`source` に実測内容を書いた |
| `unittestOk`（`unittest-ok.txt`） | `synthetic: true` を維持。要約行が stderr に出ることと出力の枠組みは実測したが、**成功時の出力そのものは未観測**（承認範囲の unittest は1本で、その1本は合成題材の欠陥で失敗した） |
| `python3 --version` の応答（`SbxRuntimeV3.Tests.ps1` 内に直接書いている） | `Python 3.12.3`（創作）→ `Python 3.14.4`（実測）。`synthetic: false` |

差し替えに伴う試験側の期待値のずれは2件だけ直した。

- `SbxRuntimeV3.Tests.ps1` の終了7の対照: stderr が空になったので、署名 `command failed with status 7` を `\S` に替え、期待を `transportVerified=true` → `false`（出力の無い終了は署名が現れない）へ直した。
- 同ファイルの終了127の対照とその応答登録: コマンド名を実測に合わせて `no-such-command` → `no-such-command-probe-8a` に替えた（署名 `not found$` はそのまま成立）。

`CliV3.Tests.ps1` の unittest 応答登録は、`synthetic` と `source` を応答テンプレートから引くように直した（固定文言の埋め込みをやめた）。

## 差し替え後のランナー結果

```
pwsh -NoProfile -File D:/.../scripts/verification/tests/Run-IndependentTests.ps1
→ Independent verification: 11 suites passed (no agent launched)   終了0、所要 1684 秒
```

| 群 | 件数（今回） | 件数（差し替え前の基準 `0c2e5eb`） | 所要 |
|---|---|---|---|
| RequestCopy | 26 | 26 | 5s |
| History | 23 | 23 | 9s |
| Execution | 7 | 7 | 11s |
| Result | 15 | 15 | 16s |
| RequestCopyV3 | 61 | 61 | 32s |
| ExecutionV3 | 18 | 18 | 24s |
| SbxRuntimeV3 | 24 | 24 | 706s |
| ProposalV3 | 16 | 16 | 259s |
| ReplayV3 | 17 | 17 | 347s |
| ResultV3 | 18 | 18 | 33s |
| CliV3 | 17 | 17 | 241s |

件数は基準と同じで、差し替えによる件数の増減は無い。`daemonDisconnect` の補償機構の証拠は SbxRuntimeV3 の 24 件に含まれる。

## 未実証のまま残ること

判定の限界。以下は本記録の観測からは主張できない。

1. **1回きりの実行**。すべての観測は 2026-09-16 の VM 1台・1回の実行によるもので、再現性・時間的な安定性は示していない。
2. **負荷試験を再実施していない**。承認範囲に試験A〜C の再実施を含めなかったため、ゲスト側の資源実効値（`nproc`・メモリ）・通信拒否のプロトコル応答・負荷中の外側停止は 2026-09-14 の記録を証拠にしている。今回の VM で取り直してはいない。
3. **デーモン切断の注入をしていない**（ADR-0196）。`daemonDisconnect` は `unverified` のまま。実コマンド直前の世代確認と自動停止痕跡の検知が働くことは偽 fixture の試験でしか確認していない。
4. **`Invoke-VerificationReplay` の統合を通していない**。8a は固定 argv を probe が直接組み立てる経路で、`New-VerificationSandbox`・`Copy-VerificationSandboxInput`・`Confirm-VerificationSandboxInput`・`Invoke-VerificationSandboxCommand`・`Stop-VerificationSandbox` という公開操作は実機で1度も呼んでいない（タスク8b の範囲）。搬入・照合・unittest は「同じ argv を probe が組み立てたもの」であって、製品コードが組み立てたものではない。
5. **他VMを止めないことは、停止中のVMに対してしか確認していない**。既存VM2台はもともと `stopped` で、復旧操作の後も `stopped` だった。running の別VMを止めないことは実機では確かめていない（同時1VM の試作条件下では作れない）。
6. **復旧操作が `stop` を発行して止める経路は実機で動いていない**。今回は自動停止が先に完了し、復旧操作は `ls --json` で `stopped` を確認しただけだった。
7. **`Stop-VerificationSandbox`（外側からの明示停止と停止証拠ファイルの作成）を実機で動かしていない**。今回のVMは自動停止で止まった。
8. **unittest の成功時出力は未観測**。承認範囲の unittest は1本で、合成題材の欠陥により失敗した。`unittest-ok.txt` は創作のまま。
9. **profile の `startupArgv`・`executableInVm` は実測していない**。どちらも replay 役では製品コードが読まない宣言項目（`startupArgv` は Proposal だけが使い、`executableInVm` はどのコードも読まない）。`/usr/bin/python3` は「VM 内で `python3` が PATH から起動できる」ことしか確かめておらず、絶対パスは未確認。
10. **transport 対照は `sh -c` 経由の1形態**。`exec` が直接コマンドを起動した場合の終了コード・stderr の形は測っていない。出力洪水も 16MiB の1回のみ。
11. **保持は約30分1回**。より長い保持、複数VM同時の保持、保持プロセスが異常終了した場合の挙動は測っていない。
12. **`create` 失敗（500 など）・MCP 登録あり・`clipboard.imagePaste=true`・未観測の `ls` の status 値・`proposal-export.py` の出力**は、承認範囲外のため実測がなく、偽sbxの応答は創作のまま。デーモン停止時の接続失敗は実装計画により恒久的に創作のまま扱う。
