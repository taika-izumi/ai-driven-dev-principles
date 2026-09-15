# ADR-0198: 全体期限の後に pilot 排他を取得できない場合も、CLI は VM を作らない型付き結果を照合へ渡す

- **Status**: Proposed
- **Date**: 2026-09-16

## Context

隔離検証 v3 の共通 CLI（`scripts/verification/Invoke-IsolatedVerification.ps1`、実装計画 `docs/working/plans/2026-09-14-isolated-verification-v3-implementation.md` タスク7）は、準備の後に pilot 排他（Lease）を1回取得し、提案 → 再実行（または未実行の結果）→ 照合と進む。仕様 `docs/current/specs/2026-09-09-isolated-verification/00-overview.md` は「途中失敗で後段を実行できない場合も、CLIはnot_runの型付き結果を作って照合へ渡す」「準備後、CLIは02のAcquire-VerificationPilotLeaseでpilot共通の起動排他を取得する。通常提案とrecheckの両経路を覆い」「競合時はVMを作らずblocked」と定める。

タスク7 の実装時レビュー（2026-09-16、claude-opus-5）は、提案が ready になった後に全体期限へ達した場合に CLI が照合を通さず失敗結果を作っていた経路を、仕様00の上記の文に反すると指摘した。修正では、全体期限の後に呼ばれた提案・再実行が VM を作らず `timed_out` の型付き結果を返すようにし、CLI はそれを照合へ渡す形にした。あわせて、期限後の `sbx daemon status` の起動拒否が `daemon-not-running`（blocked）と誤表示されていた SbxRuntime の既存欠陥を `timed_out` に直した。

この結果、準備の直後に全体期限へ達していると、Lease の取得がデーモン照会の拒否により `timed_out` で失敗する。このときの CLI の扱いを決める必要が生じた。

## Considered Alternatives

1. **Lease を取得できなかった時点で、照合を通さず失敗結果を返す**（修正前の形）。追加の分岐は無いが、仕様00「not_runの型付き結果を作って照合へ渡す」に反し、固定入力の再照合・停止記録の照合・scope の判定を経ない結果が保存される。レビューが Important として指摘した形そのもの。
2. **Lease の取得失敗が期限到達（`timed_out`）によるものに限り、Lease を持たずに提案（VM を作らず timed_out を返す）→ 未実行の再実行結果 → 照合へ進む**。仕様00の「照合へ渡す」を満たす。Lease を持たない `New-VerificationSandbox` は SbxRuntime の Lease 検査で拒否されるため、Lease なしで VM が作られる経路は無い。仕様00の「Lease は両経路を覆う」の字面からは外れる。
3. **期限到達でもデーモン照会を許して Lease を取得し、その後で期限到達を返す**。仕様の字面に近いが、全体期限の後は新しい作業を始めず停止処理だけを許すという計画の共通制約に反する（期限後の照会を増やす）。

## Decision

案2を採用する。全体期限の後に Lease の取得が `timed_out` で失敗した場合に限り、CLI は Lease を持たずに提案と照合へ進み、VM を作らない型付き結果を照合へ渡す。Lease の取得が競合（`lease-conflict`）やデーモン停止など期限到達以外の理由で失敗した場合は、従来どおり VM を作らず blocked とする。

保護条件（同時稼働1VM、Lease を持たない VM 作成の拒否）は SbxRuntime の `New-VerificationSandbox` の Lease 検査で維持され、この決定で緩めない。そのため ADR-0158 の補助設計の委任（`00-overview.md`「判断の分担と参照」）の範囲として、主担当の判断で決めた（委任に基づくAI判断。保護の追加緩和には当たらない）。計画逸脱判断の既定では条件・分岐に触れる逸脱として「設計の変更」に分類し、本 ADR に記録する。

## Consequences

- 全体期限に達した実行は、準備直後か提案後かによらず照合を経た `timed_out` の結果になり、固定入力の再照合と停止記録の照合を経る。
- 期限到達で Lease を持たない実行の間は、別の CLI が同じデーモンで Lease を取得して VM を作りうる。この実行は VM を作らないため、同時稼働1VM の条件には影響しない。
- CLI の Lease の扱いに「期限到達による取得失敗」の分岐が1つ増える。分岐は `timed_out` の status で判定し、reason の符号では判定しない。
- 実装: 実装計画タスク7 の修正ラウンド1（コミット `36e93ce`・`3962738`）。実装時レビューの差分再確認で確認する。昇格は実装完了時のサイクル全体整合検査で行う。
