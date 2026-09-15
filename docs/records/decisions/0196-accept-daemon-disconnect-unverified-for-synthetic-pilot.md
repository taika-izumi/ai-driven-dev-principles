# ADR-0196: 試作の間はデーモン切断の検知を未確認の制限として認め、検証済みの条件から外す

- **Status**: Proposed
- **Date**: 2026-09-15

## Context

仕様 `docs/current/specs/2026-09-09-isolated-verification/02-isolated-execution.md`「実行設定と起動前確認」は、verified とする実行設定の条件の一つに「time/output上限、外側CLI異常、デーモン切断、対象VMの停止と他VMの非停止、停止中の自動再起動防止」を挙げ、「監視不能な経路がある場合はverifiedにしない」と定める。デーモンとは sbx の常駐プロセス（sandboxd）で、VM の作成・実行・停止はすべてこれを経由する。

実装計画 `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md` は第2回確定前レビュー（2026-09-15、claude-opus-5、C-1）を受けて、activationEvidence の条件名を固定キー集合にし、全条件が verified でなければ blocked とした。第3回レビュー（同日、claude-opus-5、M-4）は、デーモン切断の実機注入が ADR-0192 の範囲外で、タスク8の承認依頼にも「デーモン停止を伴う競合注入」を含めていないため、このままでは全 run が blocked になるか、未確認のまま verified と書くかの二択になると指摘した。AI からデーモンを停止・再起動する操作は禁止している（内部ソケット障害の既往、ADR-0162）。

ユーザーは2026-09-15に選択肢1を選んだ（ユーザーの個別承認）。

## Considered Alternatives

1. synthetic-pilot の acceptedLimitations に `daemon-disconnect-unverified` を加え、条件名 `daemonDisconnect` を verified の必須対象から外す。補償として、各実コマンド直前のデーモン世代（PID・起動時刻）確認と daemon.log の自動停止痕跡の検知で、切断に気づかず続行しないことを保証する。
2. タスク8の承認依頼に、利用者が通常端末からデーモンを手動停止する注入試験を加え、確認できるまで全 run を blocked のままにする。仕様どおり厳密だが、利用者の作業が増え、停止後の CLI 応答形式が未観測のため試験設計の追加も要る。

## Decision

案1を採用する。synthetic-pilot の acceptedLimitations を `["clipboard-text-write-possible","pid-count-unbounded","daemon-disconnect-unverified"]` とし、仕様02・03の該当箇所を更新する。activationEvidence の条件名 `daemonDisconnect` は存在を必須とするが、verdict は `unverified` を許し、`Test-VerificationRuntimeProfile` はこの条件だけ verified を課さない。結果の `limitations` と CLI 開始時の診断表示に本制限を含め、成功時も省略しない。

補償の機構は既存のものを使う: `Assert-VerificationSandboxUnchanged`（各実コマンド直前の世代確認と自動停止痕跡の検知）で変化があれば実行せず失敗にし、停止確認は `ls --json` と daemon.log の行で行う。デーモンが落ちた場合に「落ちたことを検知できる」ことは保証するが、「落ちる直前のコマンドの結果が正しい」ことや「落ちた後の VM が停止している」ことは保証しない（停止未確認は `unverified` のまま incomplete へ写像する）。

## Consequences

- 保護の緩和であり、対象は synthetic-pilot（合成題材の試作）に限る。通常運用や実プロジェクトへ広げる場合は、デーモン切断の注入試験を別承認で行い、本制限を外してから verified の対象に戻す。
- 補償の機構自体は実機で未確認（偽の状態ディレクトリによる試験のみ）。タスク8の実 VM 試験は補償の動作を注入なしで確かめるだけで、切断時の挙動を実測しない。
- 制限の文字列が profileHash・結果に入るため、旧2件だけの profile・結果は本決定後に受理されない（試作中の変更で、既存の実 run 記録はまだ無い）。
- 本ADRは ADR-0160・0161 と同じく試作限定の例外であり、ADR-0157/0158/0192〜0195 を置換しない。Proposed で個別承認を保存し、サイクル全体整合検査を伴う次の確定チェックポイントで昇格する。
