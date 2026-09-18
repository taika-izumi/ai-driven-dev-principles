# ADR-0192: 残るsbx能力試験を新規VM1台で順に実施する

- **Status**: Accepted
- **Date**: 2026-09-14

## Context

確定仕様（`docs/current/specs/2026-09-09-isolated-verification/02-isolated-execution.md`「実行設定と起動前確認」）は、SSH転送等の追加ホスト経路の拒否、CPU/メモリ割当の実効値、有限負荷中の外側停止、daemon起動世代の特定を、runtime profileをverifiedにする条件としている。ADR-0162で転送設定はfalseへ変更済みだが、動的な拒否の実証と残る能力試験は未実施だった。`docs/records/experiments/2026-09-10-v3-capability-followup.md` は各試験の「実行までに残る事項」として、SSH代用ソケットの方式、外側の資源・起動世代の取得元、非自動起動の接続方法を挙げていた。

2026-09-14の読み取り調査（`docs/records/experiments/2026-09-14-v3-capability-test-methods.md`）で、転送の実体（daemonがVMごとにゲートウェイ:3129へ立てるSSH agent forwarderと、ゲストの `/run/ssh-agent.sock`）、資源割当の外側記録（`state/sandboxd/runtimes/<VM名>.json`）、起動世代の取得元（PIDファイル・daemon.logの起動行・OSプロセスのStartTime）を特定し、非自動起動の専用フラグが無いことを確認した。同記録の試験案A〜Dを提示し、ユーザーは「1で」と回答して、試験A〜Dを提示した範囲で個別承認した（ユーザーの個別承認）。sbx daemonは提示時点でstoppedであり、利用者の通常PowerShellからの起動を前提に含めた。

## Considered Alternatives

1. 試験A（SSH転送拒否）・B（CPU/メモリ実効値）・C（有限負荷中の外側停止）・D（起動世代と競合検知）を、新規VM1台 `iv-sbx-capability-20260914-01` で順に実施する。
2. 負荷を伴うCを除いてA・B・Dだけ実施し、Cは別途判断する。
3. 調査記録のコミットと引き継ぎ更新にとどめ、実機試験は次回以降に回す。

## Decision

案1を選択する。承認済みの固定create引数（CPU2・memory 2g・共有スキルなし・workspaceなし・deny-network '*'・固定digest）から名前だけを変えた新規VM1台を作り、A〜Dを順に実施する。同時稼働は1VMを守り、既存VM `iv-sbx-smoke-20260909-01` は起動・削除しない。

- 前提: 利用者が通常PowerShellで `sbx daemon start -d` を実行し、AIが `daemon status` でrunningを確認する。転送false/source=override、既存VMの同一ID/stopped、起動世代を先に記録する。設定変更は行わない。
- A: 新VMのdaemon.logに `started SSH agent forwarder` が無いこと、ゲストで `/run/ssh-agent.sock` 不在・`SSH_AUTH_SOCK` 未設定・ゲートウェイ:3129への接続拒否（対照: 3128は接続可）を、agentとrootの両方で確認する。実鍵の一覧・署名は使わない。
- B: runtimeファイルとdaemon.logの外側値（2 vCPU・2048MiB）とゲストの `nproc`・`MemTotal` を対応付ける。ゲスト値だけで外側強制としない。
- C: 固定スクリプト（最大2 worker・合計256MiBまで・20秒で自己終了・ログ1MiB以下。本文とハッシュは実行前に提示）を搬入して開始し、開始確認の5秒後に外側から `sbx stop`。30秒以内に同一IDのstoppedを外側で確認する。fork bomb・資源枯渇は含めない。
- D: 各操作の前後で起動世代（PID・StartTime・起動行の時刻）を比較し、変化があれば当該結果を不採用にする。daemon停止を伴う競合注入は含めない。

## Consequences

- 承認範囲は、新規VM1台のcreate、固定スクリプトのcp、exec（負荷・照会）、stop、外側記録の読み取りに限る。設定変更、既存VMの操作、VMの削除・reset、モデル起動・認証、別イメージ、daemon停止を伴う競合試験、clipboard操作は含まない。これらは別承認とする。
- 停止後もVMとログを残す。試験の作業領域は `.tmp/sbx-capability-20260914/` に置き、採用する証拠だけを実験記録へ転記する。
- 試験の成否はruntime profileのverified判定の材料であり、本ADRは判定そのものではない。不合格・中止の場合も結果を記録し、未確認をverifiedにしない。
- ADR-0157/0158/0160/0161/0162の仕様と設定を実行環境で実証する操作決定であり、これらを置換しない。Proposedで個別承認を保存し、サイクル全体整合検査を伴う次の確定チェックポイントで昇格する。承認回答は再取得しない。
