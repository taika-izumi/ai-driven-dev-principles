# 2026-09-16 タスク8b: SbxRuntime の公開操作を実VM 2台で実証した記録

隔離検証 v3（提案と通信なし再実行）実装計画のタスク8b「公開操作の実証」の結果。個別承認（2026-09-16、8a と同時）を得た
実機試験で、`SbxRuntime.psm1` の公開操作だけを使って修正前後の再実行を別々の通信なしVMで取り、外側の記録に残した。

**なぜ 8a の記録（`2026-09-16-v3-task8a-probe.md`）に追記せず別ファイルにしたか**: 8a の記録の SHA256 は
`scripts/verification/profiles/replay/activation-evidence.json` に証拠ファイルのハッシュとして固定されている。
追記するとハッシュが変わり、`Test-VerificationRuntimeProfile` が「evidence hash mismatch」で落ちる。
本記録は profile から参照されない独立した記録として置く。

## 実証した範囲と、できていないこと

**実証した**: `Acquire-VerificationPilotLease` → `New-VerificationSandbox`（replay-before / replay-after）→
`Copy-VerificationSandboxInput` → `Confirm-VerificationSandboxInput` → `Invoke-VerificationSandboxCommand`（固定 argv の
unittest 1本）→ `Stop-VerificationSandbox` → `Release-VerificationPilotLease` を、製品コードが組み立てた argv で実機に通した。
V4 の「別VM・通信なしで修正前が非0・修正後が0」を公開操作の直接呼び出しで取った。

**できていない（限界）**:

1. **1回きりの成立**。再現性・時間的な安定性は示していない。
2. **負荷は掛けていない**。資源の実効値・負荷中の挙動は 2026-09-14 の記録（試験B・C）が証拠。
3. **デーモン切断は注入していない**（ADR-0196。`daemonDisconnect` は unverified のまま）。
4. **`Invoke-VerificationReplay` の統合は未実証**。本記録は公開操作を1本ずつ呼んだもので、Replay の入力生成・差分照合・
   外側記録・未実行結果の経路は通っていない（タスク9）。
5. **他VMを止めないことは、停止中のVMに対してしか確認していない**。実行中の別VMを止めないことは未実証
   （同時1VM の試作条件下では作れない）。
6. 作成失敗（500 等）・時間超過・出力超過・維持確認の不成立といった失敗経路は実機では通っていない（偽sbxの試験のみ）。

## 環境

| 項目 | 値 |
|---|---|
| デーモン | running / PID 25888 / 起動 2026-09-16 08:59:47 JST / `v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64` |
| socket | `\\.\pipe\docker_kaname_sandboxd` |
| daemon.log | `C:\Users\d12an\AppData\Local\DockerSandboxes\sandboxes\state\sandboxd\daemon.log` |
| sbx CLI | `C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe` |
| テンプレート | `docker.io/docker/sandbox-templates@sha256:16a88c7321c130de9aa8410ffd0865ea22dd051ebb7f58103fbf41ec50057476` |
| 実行 | `pwsh -NoProfile -File scripts/verification/tests/Invoke-SbxPublicOperationProbe.ps1`（既定引数）。終了0 |
| 所要 | 受付 2026-09-16T01:52:26Z → 判定 01:53:50Z（約84秒。VM 2台の作成・搬入・実行・停止を含む） |
| 発行した sbx コマンド | 67本（うち `stop` は各役1本ずつの計2本） |

実機に触る前に、偽sbx（記録済み応答）で同じスクリプトを最初から最後まで1回通してある（空撃ち）。実機は1回で通った。

## 足場（run の準備）

| 項目 | 値 |
|---|---|
| 雛形 | `scripts/verification/tests/fixtures/pilot-run/{request,settings,pilot-input}.json`（差込み記号つき） |
| 実体化先 | `.tmp/p8b/cfg-af3b78ab/`（runsRoot の外） |
| runsRoot | `.tmp/p8b/runs` |
| sourceRoot | `.tmp/p8b/src-af3b78ab`（`fixtures/pilot-source/source/` を複製した独立 Git 作業ツリー。HEAD `fc4dd128`） |
| runId | `420e848c-ac84-4d19-b9a2-784051a8599b` |
| runRoot | `.tmp/p8b/runs/420e848c-ac84-4d19-b9a2-784051a8599b` |
| sourceManifestHash | `417CD110BEE976D0B895247584449B67ADA0EE8D77722EB17DDDB128C0D087F5`（固定入力記録の値と PreparedRun の値が一致） |
| pilotInputId | `task8b-pilot-source` |
| limits | 実装計画の初期上限（全体1800秒・提案600秒・各再実行120秒・停止猶予30秒・cpus 2・memoryMiB 2048・他は仕様どおり） |
| profileHash | `66A6A4B01BA9456AC4472BA813681FE1D3760D00EECF4F2E352E2C73E3740DD9`（replay-before / replay-after とも同じ） |
| effectiveSettingsHash | `62B57EDDD7202B538ABDC1B71DDF9642E1411F9AFE0F951000C7B40651F2DC46`（両役で一致。V6 の「before/after の実効設定一致」） |

`Test-VerificationRuntimeProfile` は、8a が生成した `profiles/replay/profile.json` に対して `replay-before` と
`replay-after` の両方で通った（VM 作成前の検査。`New-VerificationSandbox` が作成直前にも同じ検査を再実行している）。

### 搬入した入力（VM の外で組んだ）

before は基準版の作業ファイル、after は同じ作業ファイルに `replacements/calc.py` を上書きしたもの。tests は両方とも
`.verification-tests/` 直下に平置き。`.git` は搬入していない。

| 役割 | ファイル | サイズ | manifest のファイル hash |
|---|---|---|---|
| replay-before | `calc.py`（欠陥版） / `.verification-tests/test_calc.py` | 270 / 383 | `DB11A49D8A092C21926F784910D12164E464102B5B2A956AA1FB56A112BA3DC8` |
| replay-after | `calc.py`（修正版） / `.verification-tests/test_calc.py` | 235 / 383 | `D21E71DD6CDA574CF7D772CE6EE97DCC38444C6AB2C235B9E3C82ABDA67CE1AF` |

tests のハッシュは両役で同一（`804B2B3C…`）。作業ファイルだけが違う。

## 作成したVMと結果

| 役割 | VM名 | ID | 作成時刻(UTC) | unittest 終了コード | transportVerified | 停止 | 最終状態 |
|---|---|---|---|---|---|---|---|
| replay-before | `iv-420e848c-before` | `29d60f42-49e5-45e0-bbf2-8d1567401407` | 01:52:31.99 | **1** | **true** | stopped | **stopped（削除していない）** |
| replay-after | `iv-420e848c-after` | `70b37670-a291-4444-83d0-2012c9905e59` | 01:53:12.82 | **0** | **true** | stopped | **stopped（削除していない）** |

- 2台の ID は互いに異なり、8a の probe VM（`f0272f46-…`）とも異なる。
- 固定 argv（両役とも同形）: `exec -w /home/agent/workspace/source <VM名> python3 -m unittest discover -s .verification-tests -p test_*.py -v`
- 作業ディレクトリ `/home/agent/workspace/source`、環境変数の追加なし（`-e` は1つも付かない）。
- 出力署名 `{pattern:'Ran \d+ tests? in', stream:'stderr'}`（8a の実測どおり）。両役とも stdout は **0バイト**。

### 搬入と搬入照合

- `Copy-VerificationSandboxInput`: 両役とも `copied=true`・`fileCount=2`。`cp` → `chown -R agent:agent` の順に終了0。
- `Confirm-VerificationSandboxInput`: 両役とも `confirmed=true`・`fileCount=2`。欠落・予定外・相違なし。
  固定コマンドの `sha256sum` 出力は 8a と同じ `<64桁小文字>  ./<相対パス>` 形式。

### unittest の出力（stderr 原文）

replay-before（終了1）:

```
test_add_returns_sum (test_calc.AddTest.test_add_returns_sum) ... FAIL

======================================================================
FAIL: test_add_returns_sum (test_calc.AddTest.test_add_returns_sum)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/agent/workspace/source/.verification-tests/test_calc.py", line 9, in test_add_returns_sum
    self.assertEqual(calc.add(1, 2), 3)
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^
AssertionError: -1 != 3

----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (failures=1)
```

replay-after（終了0）:

```
test_add_returns_sum (test_calc.AddTest.test_add_returns_sum) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

**成功時の出力はここで初めて実測した**（8a では承認範囲の unittest 1本が合成題材の欠陥で失敗したため未観測だった）。
偽sbxの応答 `tests/fixtures/fake-sbx-responses/unittest-ok.txt` をこの原文へ差し替え、`index.json` の
`synthetic` を false にした。

### activationRecord（両役とも同じ判定）

`control/runtime/<役割>-activation.json`。ハッシュは before `8E72A3A462E0BBAD49A91EC5630A924866160036F079D38FB5A623F921B9EBBB`、
after `AC6F33BC77E47395205750C3E4619E43F837653B9186D575CC436BD17830A4EC`。

| 条件 | verdict | 観測 |
|---|---|---|
| `policy` | verified | `decision=deny`・`resources=["*"]`・`scope=sandbox:<VM名>`、inspect の `network_policy.scope=sandbox` |
| `mount` | verified | `WorkspaceDir=""`・`ShareSkills=false`・`image_digest` が profile の digest と一致・`state=running` |
| `resource` | verified | `CPUs=2`・`Memory="2g"` |
| `credentialExposure` | verified | `secrets` は `mcpgateway`（source=uploaded）1件のみ |
| `sshForwarding` | verified | `SSHAgentSocketPath=""`・daemon.log の当該 runtime 行に `started SSH agent forwarder` 0件 |
| `clipboardImagePaste` | verified | false |
| `mcpServers` | verified | `servers` 0件（`mcp_gateway=true`・`mcpgateway` secret ありは製品挙動。ADR-0195） |
| `otherVmTraffic` | **not-applicable** | 他に running のVMが無い |

### 外側 `stop` による停止確認

**8a では取れなかった「外側からの `stop` の実機実行」をここで取った**（8a のVMは自動停止で止まり、復旧操作は `ls` の確認だけだった）。

| 役割 | stop 発行(UTC) | `ls` の観測 | daemon.log の停止行 | デーモン世代 | 保持セッション |
|---|---|---|---|---|---|
| replay-before | 01:53:00.48 | 同一IDで `stopped` | `{"time":"2026-09-16T10:53:06.399127+09:00",…,"msg":"stopped runtime container","runtime":"iv-420e848c-before"}` | PID 25888 で前後不変 | `stopped=true`・`exitCode=137` |
| replay-after | 01:53:41.11 | 同一IDで `stopped` | `{"time":"2026-09-16T10:53:46.9725278+09:00",…,"msg":"stopped runtime container","runtime":"iv-420e848c-after"}` | PID 25888 で前後不変 | `stopped=true`・`exitCode=137` |

停止証拠は `control/runtime/<役割>-stop-<UTC時刻>.json`。停止フェーズの予算は現在時刻起点の1台分（`cleanupSeconds`=30）。
`stop` を発行した名前は当該2台だけで、他の名前への `stop` は0本（`control/runtime/` の出力ファイルの tag が
`replay-before/0031-stop` と `replay-after/0063-stop` の2本だけ）。

**保持セッションの停止が実機で効いた**: `keepAlive.stopped=true`・`exitCode=137`。タスク3が報告した
「MSIX 版 pwsh の孫がジョブに入らない」欠陥は偽sbx（`fake-sbx.cmd` → MSIX 版 pwsh）の構成に固有で、
実機の `sbx.exe` は明示割当したジョブの停止で木ごと止まる。

### 自動停止の痕跡（安全規則の確認と、新たに分かったこと）

作成から停止までの各観測群の前に daemon.log の当該 runtime 行を読み、`auto-stopped runtime after last session disconnected`
が無いことを確かめた（両役とも3回ずつ。0件）。`Assert-VerificationSandboxUnchanged`（製品側の維持確認）も
各実コマンドの直前に同じ確認を行い、いずれも通った。

**新たに分かったこと**: 外側から `stop` した約30秒後に、当該VMの `auto-stopped runtime after last session disconnected` 行が出る
（before は停止行 10:53:06 → 自動停止行 10:53:36、after は 10:53:46 → 10:54:16）。停止で保持セッションが切れ、
猶予30秒の遅延停止タイマーが停止済みのVMに対して発火するため。**製品の判定には影響しない**（維持確認は runtime 名で
絞り込み、停止後は `sandbox already stopped` で実コマンドを拒否するため、この行を読む経路が無い）。
ただし daemon.log を人が読むときに「run 中に自動停止した」と誤読しうるので記録する。

保持セッションが効いていたことは `session connected count:2` → `session disconnected count:1` の繰り返しで確認できる
（各実コマンドが2本目のセッションとして接続・切断し、保持の1本が残る）。

## 他VM（既存の3台）の不変

| VM名 | ID | 開始時 | 終了時 |
|---|---|---|---|
| `iv-48830e99-probe` | `f0272f46-49bb-4d67-99ba-12468c153c6b` | stopped | stopped |
| `iv-sbx-capability-20260914-01` | `0baac92d-251c-4f34-9d8f-6f14a9c238c6` | stopped | stopped |
| `iv-sbx-smoke-20260909-01` | `de1ba0ac-ebb0-4cc4-a5f6-009dffd8baae` | stopped | stopped |

3台とも ID・状態とも不変。これらの名前を含む argv は `ls --json` を除いて1本も発行していない
（`inspect`・`exec`・`cp`・`stop` は0本）。**ただし、この確認は停止中のVMに対してのみ成立する**（上記の限界5）。

## 観測の原文の置き場（未追跡）

`.tmp/p8b/`（`runs/420e848c-…/obs8b/` の観測JSON、`runs/420e848c-…/control/runtime/` の各 sbx 呼び出しの stdout/stderr と
作成記録・activationRecord・停止証拠、`cfg-af3b78ab/` の実体化した設定と 00-preflight の観測、`src-af3b78ab/` の題材の複製）。

## 判定

| 完了基準 | 結果 |
|---|---|
| V4「before 非0・after 0 を別VM・通信なしで記録」（公開操作の直接呼び出し分） | **成立**（1 / 0、別ID、network deny `*`） |
| V2「activationRecord の実効値一致」 | **成立**（両役とも8条件。`otherVmTraffic` は非該当） |
| V5「外側 `stop` による停止確認」 | **成立**（`ls` の同一ID stopped・停止行・世代不変・保持停止） |
| V5「当該名以外への stop を出さない」 | **成立**（停止中のVMに対してのみ） |
| V6「before/after の effectiveSettingsHash 一致」 | **成立**（`62B57EDD…`） |
| `Invoke-VerificationReplay` の統合 | **未実証**（タスク9） |
