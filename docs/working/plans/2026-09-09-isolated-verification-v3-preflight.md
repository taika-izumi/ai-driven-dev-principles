# v3実装前のsbx能力確認計画

> **実装担当へ:** 本先行計画は主担当が実施する。後続のコード実装にはsuperpowers:executing-plansまたはユーザーが選択したsubagent-driven-developmentを用いる。本書はv3全体の実装計画ではない。

**目的:** 確定仕様の起動前条件に、sbx 0.42.1の実在する設定・検証方法を対応付け、実装へ進めるかを判定する。

**構成:** 読み取り確認→要件と実体の対応→不足条件の判断。未確認をverifiedにしない。成立しない設定を仮定してruntimeを先に作り込まない。

**技術:** 既存Windows/PowerShell 7、導入済みsbx、提供元の公式資料。新規パッケージなし。

**仕様:** b7941f3で確定したdocs/current/specs/2026-09-09-isolated-verification/00-overview.mdおよび01〜04。特に02「実行設定と起動前確認」。

**状態:** 読み取り確認を実施。現状判定はblocked。クリップボード書込拒否・pids外側強制の具体機構が見つからず、全体実装計画の確定に進んでいない。欠落機能の不存在を証明したという意味ではない。

2026-09-10追記: タスク3の変更案をユーザーが採用（ADR-0160/0161）。合成題材の試作ではpids128の厳密制限を外し、clipboard文字列書込を例外受容する仕様へ改訂した。以下の初回照会結果は当時の要件での実施記録として保持する。実装用の現在の条件は現行仕様を参照し、古いpids値を再導入しない。SSH等の残る能力確認と全体実装計画は未完。

## 共通制約

- 既存worktreeはD:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification、branch=codex/isolated-verification。
- 仕様schemaVersion=3、4責務、同一テストと外側の基準版・実行証拠を維持する。
- CPU2、メモリ2048MiB、pids128、全体1800秒、提案600秒、各再実行120秒、停止猶予30秒が仕様の基準。確認不能な上限を実効設定として記録しない。
- 原本・home・control・共有skills・ホストDockerを渡さず、クリップボード書込とSSH等のホスト作用も拒否する。
- 通常ターミナル起動済みdaemonを使う。daemon停止時に自動起動するsettings/ls/execを実行しない。reset/退避/再起動/認証/設定変更は本計画に含めない。
- 既存VM iv-sbx-smoke-20260909-01はstoppedを維持。他worktree・stash・.tmp・状態退避02/03を保全する。

## 判断の分担と逸脱

ADR-0158の補助設計委任による前提確認。保護の追加緩和、新規必須基盤、利用者作業、認証・費用・送信、削除・公開は個別相談。逸脱判断は導入版0.1.24のstart-work/references/plan-deviation-defaults.mdを適用する。先行確認では製品設定を変えず、現仕様のゲートがblockedを返すことを仕様逸脱と扱わない。

本先行段階は製品能力の読み取り確認で、コード実装をしない。後続の実装は動作テストを安全網とする方式を想定するが、型・関数・テストの詳細計画は本ゲート成立後に確定する。r1〜r3の指摘は全て解消、実装時へ残した不採用指摘はない。動的未実証は02の起動条件として維持する。

## タスク0: 版と利用できる操作を確認

**対象:** 既存sbx.exeのヘルプ。成果物はdocs/records/experiments/2026-09-09-v3-runtime-preflight.md。

- [x] create、settings、policy deny、execのヘルプを読む。これ自体でVMを起動しない。

```powershell
$sbxExe = 'C:/Users/d12an/AppData/Local/DockerSandboxes/bin/sbx.exe'
& $sbxExe create --help
& $sbxExe settings --help
& $sbxExe settings list --help
& $sbxExe policy deny --help
& $sbxExe exec --help
```

- [x] CPU/メモリ、pids、共有、設定照会の操作有無を区別する。期待値は「各能力の所在または未確認」が埋まること。すべての能力があると仮定しない。

**実測:** CPU/メモリ・共有等はヘルプにある。pids制御は見つからない。settingsはdaemonを自動起動しうると説明される。

## タスク1: 稼働中daemonの関連設定だけを読む

**対象:** daemon状態とsettingsのメタデータ。変更するファイル・設定なし。

- [x] 通常起動済みrunningを確認。stoppedなら以後の照会を中止する。
- [x] 下記で関連設定だけ抽出する。秘密ストアの値・全環境変数は読まない。

```powershell
$state = @(& $sbxExe daemon status)
if (@($state | Where-Object { $_.Trim() -eq 'Status: running' }).Count -ne 1) {
    throw 'Daemon not running; no settings query'
}
$raw = & $sbxExe settings list --all --json
if ($LASTEXITCODE -ne 0) { throw 'Settings query failed' }
$settings = $raw | ConvertFrom-Json
$settings | Where-Object {
    ($_ | ConvertTo-Json -Depth 4 -Compress) -match 'clipboard|pids|ssh\.agent|auto.?start'
} | ConvertTo-Json -Depth 6
```

**実測:** 配列で3設定。clipboard.imagePaste=false、ssh.agentForwardingEnabled=true、ssh.agentSocketPath空。pidsとクリップボード書込無効化設定は抽出されない。この件数は0.42.1の今回観測値で、将来版の恒久期待値にしない。

- [x] 一覧で既存VMが同一ID・stoppedであることを確認する。期待値は1台を保全し、作成・execを行わないこと。

## タスク2: 提供元資料と実機結果を対応付ける

**対象:** Docker公式のisolation、faq、create、release-notes。結果の出力書式は要件/実在する機構/実測/未確認/判定。

- [x] クリップボード画像読取と文字列書込を区別する。imagePaste=falseだけで書込拒否と扱わない。
- [x] Docker Engineの--pids-limitをsbx createの機能と取り違えない。VM内sudoで変更できる設定を外側の強制と認定しない。
- [x] SSH転送の設定が既定trueで、変更の反映に再起動が関係することを記録。設定は変更しない。
- [x] 読み取り確認済みと実際の拒否試験未実施を分離して判定する。

**実測:** クリップボード書込は公式の機能として記載。拒否設定は確認不能。pidsも外側での強制方法を確認不能。したがって現構成のactivationをverifiedにできない。

## タスク3: 不足条件の扱いを決める

2026-09-10の継続調査と未実施の操作案は`docs/records/experiments/2026-09-10-v3-capability-followup.md`。SSH設定の影響・通常起動手順、残る試験の方法と未特定事項を整理した。設定操作は個別承認後に通常起動後の照合まで完了（ADR-0162）。動的拒否・残る試験方法は未完で、以下の実機試験案の完了欄はまだ閉じない。

**対象:** Issue-0136の0136-note-v3-capability-gaps.md。これは採用前の判断材料で、設定変更手順ではない。

- [x] 保護目的に照らして再検討し、試作限定の資源保護変更とclipboard例外をユーザーが採用（2026-09-10）。
- [ ] 機構が特定できた場合だけ、対象VM・代用品・具体コマンド・停止・保全の実機試験案を作る。実機試験の操作は既存の固定smoke承認へ混ぜない。
- [x] 保護条件の変更をADR-0160/0161と全体仕様へ反映し、差分再確認2回で確定（2026-09-10）。動的な能力証拠はまだ未作成。

タスク3の採否と改訂後の差分確認は完了し、SSH等の残る実機検証は未完。全体実装の残る責務は下表のとおり保持し、後続を完了・実装計画確定扱いにしない。

| 後続の実装対象 | 関係する成功基準 |
|---|---|
| v3入力と独立baseline・再利用テスト | V1/V6 |
| 制限付きプロセス入出力とSbxRuntime | V2/V5 |
| 未信頼Envelopeの受信・検査と提案 | V2/V3 |
| 別環境のbefore/after/recheckと停止 | V4/V5 |
| 最終結果・短絡失敗・CLI結合 | V6/V7 |
| AIなし保護実証と個別承認後の最小モデル往復 | V2〜V7 |

## 計画の自己確認

タスク0〜2は読み取りのみで、記載コマンドと実測が対応する。settings関連の3件は今回版の観測値、VM1台stoppedは今回の既存状態であり、一般的な機能要件と混ぜていない。コードの新規実装・モデル起動・設定変更を期待値へ含めていない。旧v2計画は保存し、実行対象にしない。

本書は先行ゲートの計画と実施記録。全体plan確定点には到達していないため、全体計画のレビュー・実装方法選択へ進んでいない。
