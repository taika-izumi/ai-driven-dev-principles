# Issue-0147: MSIX 版 pwsh を ProcessHost にすると非パッケージの子プロセスが VerificationJob に入らず、時間超過・出力超過・背景停止のジョブ停止が対象へ届かない

- **Status**: open（本サイクルで統合採用・修正中）
- **Opened**: 2026-09-15
- **起票元**: 隔離検証 v3 実装計画のタスク3 実装者報告の候補10（計画逸脱判断の既定「計画の範囲外の既存欠陥」。`docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md` タスク3 の逸脱記録行）
- **関連**: `scripts/verification/Execution.psm1`（`VerificationJob`・`Invoke-VerificationProcess`・`Invoke-VerificationProcessV3`・`Start-/Stop-VerificationBackgroundProcess`）/ `scripts/verification/ProcessHost.ps1` / ADR-0193（保持セッション）/ 計画の完了基準 V5

## 課題内容

`Execution.psm1` は ProcessHost（pwsh）を `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` のジョブへ割り当て、その子として対象を起動する。子プロセスはジョブを継承する前提で、時間超過・出力超過・背景停止は `TerminateJobObject` と `Active()==0` で「対象のプロセスツリーを止めた」と判定する。

2026-09-15 の実測（タスク3 実装者、スクラッチの `job-probe.ps1`・`job-probe2.ps1`）: この PC の pwsh は MSIX パッケージ版（`C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.6…\pwsh.exe`）で、それを ProcessHost として起動した子のうち、非パッケージの実行ファイル（cmd.exe・powershell.exe・ping.exe）は `IsProcessInJob`=false で `Active()` にも数えられなかった。パッケージ版 pwsh の子だけがジョブに入った。非パッケージの ping.exe を `AssignProcessToJobObject` で明示割当すると成功し、ジョブ停止で止まった。

実機の sbx クライアント `sbx.exe` は非パッケージの実行ファイルであるため、現状では時間超過・出力超過・保持セッション停止・`clientKilled` 対照でジョブを止めても `sbx.exe` が残り、`processTreeStopped` がホストの終了だけで true になりうる。

## 不在の根拠（計画逸脱判断の既定「検査の仕組みが無い場合の基準」）

走査した継続検査の資産と、この欠陥型を捕捉しない理由:

- `tests/Execution.Tests.ps1`（v1、7シナリオ）: 対象はすべて `tests/fixtures/ProcessFixture.ps1` を pwsh で起動するため、子は常にパッケージ版 pwsh でジョブに入る
- `tests/ExecutionV3.Tests.ps1`（v3、12ケース）: 対象は `tests/fixtures/ProcessFixtureV3.ps1` を pwsh で起動する。起動失敗ケースは存在しない実行ファイルで、非パッケージの実在 exe を対象にしたケースは無い
- `tests/SbxRuntimeV3.Tests.ps1`（タスク3、16ケース）: 偽 sbx は `fake-sbx.cmd`（cmd.exe）経由だが、試験側が PID 指定の後片付けで残存を吸収しており、ジョブに入らないことを失敗として検出しない
- 計画内の後続検査: タスク8a は実 sbx で transport 対照・出力洪水・保持停止を観測するが、承認済みの実機試験の前提そのものが崩れるため、そこで初めて検出するのでは遅い

同一領域（Execution.psm1・ProcessHost.ps1）を触るタスク（タスク2 の修正、タスク8a の前提）が計画内にあるため、既定に従い統合採用する。

## 対策（本サイクルで実施）

- ProcessHost.ps1 が起動した対象を、ProcessHost 自身が属するジョブへ明示的に割り当てるか、ProcessHost が自前の `KILL_ON_JOB_CLOSE` ジョブを作って対象を割り当てる。実装方式は修正担当が実測で選ぶ
- `tests/ExecutionV3.Tests.ps1` に、非パッケージの実在 exe（例: `%SystemRoot%\System32\ping.exe` や cmd.exe）を対象にした時間超過・背景停止のケースを追加し、対象 PID の消失で判定する

## 検討状況

- 2026-09-15: 起票。計画逸脱判断の既定に従い統合採用。タスク3 のレビューと並行して、Execution.psm1・ProcessHost.ps1 の修正を委譲した
- 2026-09-15: 修正（1ab11c6・2187ff3）。起動側が割当と確認の権限だけを持つジョブのハンドルをホストへ複製して渡し（子に継承しない）、ホストは対象の起動直後にジョブへ明示割当してから開始マーカーを書く。割当失敗は対象を止めてマーカーなしで失敗終了し、v3 は `refusedReason='launch-failed'` を返す。ホストはジョブハンドルの無い要求を拒否する。ExecutionV3 に非パッケージ exe（ping.exe・cmd.exe 経由）を対象にした5件を追加し、修正前のコードで失敗することを確認
- 残る制約: 対象の起動から割当までの間（実測 0.03〜0.7 ミリ秒）に対象が生んだ子はジョブに入らない。.NET の Process は一時停止状態での起動を持たないため、この窓は塞いでいない。実機の sbx.exe がこの間に子を生むかはタスク8a で確認する。conhost.exe はジョブに入らないが、対象の終了で自ら終わる
- 2026-09-15: 試験の足場に残る制約（タスク3 修正ラウンド1 の実測）。修正後も、ジョブ内の cmd.exe（偽 sbx の `fake-sbx.cmd`）が起動する MSIX 版 pwsh（偽 sbx の本体 `FakeSbx.ps1`）はジョブに入らず、`processTreeStopped=False` で pwsh が残った。実機の sbx.exe はパッケージ版ではないため製品の保護判定には及ばないが、偽 sbx を使う試験（タスク3・4・5・7）はジョブ停止だけでは偽 sbx の本体が止まらない。試験は自分が起動した偽 sbx の PID を後片付けする補助で吸収し、保持セッション停止の確認は「保持の対象プロセスの消失と後片付け後の残存 0」で行う。後片付けの補助はタスク4 の着手時に `tests/fixtures/FakeSbxScenario.psm1` へ移して共用する

- 2026-09-16: タスク8b の実機実証で、実 sbx.exe を対象にした保持セッションの停止が `exitCode=137` で成立し、プロセスツリーの停止が届くことを確認した。ジョブに入らない事象は偽 sbx の構成（ジョブ内の cmd.exe が MSIX 版 pwsh を起動する）に固有で、製品の保護判定には及ばないことが実機で裏づけられた。残る窓（対象の起動から割当までの 0.03〜0.7 ミリ秒に対象自身が生んだ子）は、実 sbx.exe が当該窓で子を生むかを観測していないため未確認のまま

## 結論

（open。実機で製品側の保護は成立。偽 sbx の構成に固有の制約と、割当前の窓の未確認だけが残る）
