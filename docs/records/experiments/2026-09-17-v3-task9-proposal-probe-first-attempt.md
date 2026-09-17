# タスク9: 提案用VMの初回試験と通信規則の前提訂正

## 結果

2026-09-17、利用者の操作承認「1で」とOAuth登録完了連絡を受け、limitsAndTransport用VMを1台作成した。通信規則の確認で前提の誤りを検出し、試験を中断して対象VMを停止した。2台目・モデル往復・proposal profileの生成は未実施。認証登録自体は成功している。

既定キットの静的宣言を実効規則と同一視し、「443番限定には専用キットが必要、既定キットは全ポート許可」と説明したのは主担当の調査・判断の誤りだった。今回の実効規則は2接続先とも明示的な`:443`で、8443番は暗黙拒否となった。現行版で専用キットが必要という以前の説明は撤回する。ADR-0199の全ポート方針はまだ改訂承認を得ていないため、修正案と確定済み方針を区別する。

## 実行条件と証拠

- 実装: 5fc8a80。sbx v0.42.1 cc6e400a4a3ce3ce5e0b2b77b8ee352aac854c64。実装ファイルはこの実験中に変更していない。
- 操作承認: `docs/working/plans/2026-09-17-task9-proposal-probe-approval.md`。CPU2、2GiB、全体3600秒、既存5台を保全。
- OAuth: `secret ls`のopenaiに`(oauth configured)`を確認。秘密の値・ホスト側認証ファイルは読んでいない。
- runId: `f107bb84-4dde-402f-ad72-b58057ee5451`。
- VM: `iv-f107bb84-proposal`、ID `4dbf7166-62fa-49b5-8985-a353d066fb66`。
- 原文: `.tmp/probe-9/f107bb84/`の`probe-state.json`、`calls.jsonl`、`obs/`、`cli/`。
- 開始前/終了後一覧: `.tmp/task9-probe-approval/20260917-091924-vms-before.json`、`vms-after-first-probe.json`。
- 停止後の規則診断: 同ディレクトリの`diagnostic-policy-summary.json`と`diagnostic-*.json`。policy checkと一覧読取りだけを実施し、停止後のexec/cp/runは発行していない。
- 時刻: 作成開始09:19:32、停止要求09:22:03、停止確認09:22:10（JST、原文はUTC）。daemonは利用者が前日開始したPID25888の世代を維持。

## 確認できたこと

| 項目 | 観測 |
|---|---|
| 作成直後 | create成功、inspect sessions=0、観測時のcodexプロセス数=0。過去全域の未起動を保証するものではない |
| Python | Python 3.14.4、標準ライブラリ297件 |
| 搬入 | 承認済み2ファイルのSHA256一致。cp再試行・親ディレクトリ追加は不要 |
| unittest | 不具合を含む固定題材が想定どおり1件失敗、終了1、要約はstderr |
| 終了コード | 正常終了0、明示終了7、存在しないコマンド127を取得 |
| 時間超過・外側強制終了 | いずれも終了コードnull、外側から子プロセスを終了 |
| 出力上限 | 16,777,216バイトの閾値で打切り、読取り単位による到達値16,781,312バイト。outputExceeded=true、終了コードnull |
| 停止 | エラー経路から当該名へstopを発行、同一IDのstoppedを確認 |
| 既存VM保全 | 既存5台の名前・ID・状態が開始前と一致、全台stopped。今回の1台を含め6台stopped |

## 実効通信規則と不一致

`cli/024-policy-ls.out`のkit由来allowは13件で、HTTPS系10件は明示的な`:443`、Ubuntu系3件は`:80`。作成時の他11ホストへのポートなしdenyも存在する。

| 対照 | 実測allowed | 終了コード |
|---|---|---|
| auth.openai.com:443 / chatgpt.com:443 | true | 0 |
| auth.openai.com:8443 / chatgpt.com:8443 | false（implicit deny） | 1 |
| 残るキット宣言11ホストの宣言ポート | false（local deny） | 1 |
| example.com:443 | false（implicit deny） | 1 |

これはsbxの認可器の判定であり、外部接続の実通信成功を測定したものではない。宣言ポート外の全ポートを総当たりした試験でもない。

初回中断点は`auth.openai.com:8443`。プローブはJSONを読む前に終了1を失敗として例外化した。保存済みJSONには正常な`allowed=false`と拒否理由がある。さらに規則の比較処理はポートなしallowを期待しているため、終了コードだけ直しても不一致が残る。

同じ欠陥は製品側`Get-VerificationProposalPolicyChecks`にもある。汎用の`Invoke-VerificationSbxJson`が終了0だけを受け入れるため、期待どおりの拒否もquery-failedにしてしまう。偽sbxは拒否応答にも終了0を返しており、既存試験ではこの相違を検出できなかった。

## 未確認

05-queriesは完了前に中断した。VM内部のOAuthセンチネル5項目、SSH否定確認・ゲスト資源値・policy logの組合せは未取得。inspectのauth_modeはoauthであるが、これだけでcredentialMethodをverifiedにしない。異常終了後の自動停止と復旧は2台目の未実施項目。提案側の証拠一式は未完成。

## 修正案（未承認）

推奨は既定キットを維持し、実効許可の契約を`auth.openai.com:443`・`chatgpt.com:443`へ訂正すること。新たなallowや専用キットは追加しない。

1. ADR-0199、仕様・計画・schema・policyExpectation・条件対応表を443番限定へ整合させる。許可一覧の比較は実測の`:443`/`:80`を使い、未知のallowと他11ホストのdeny欠落を引き続き拒否する。8443番の期待値はfalse。
2. 製品とprobeのpolicy check専用経路で、終了0かつallowed=true／終了1かつallowed=falseを正常判定として扱う。その他の照会へ終了1の受理を広げず、壊れたJSON・不整合・時間超過・出力超過・別対象の応答は拒否する。
3. 偽sbxを実測原文と終了コードへ修正し、両経路の拒否判定・不正応答・規則不一致の回帰試験と必要なレビューを行う。
4. 修正と確認後、同じ承認条件（CPU2/2GiB、各3600秒、逐次実行）で新規VM2台の証拠取得をやり直す案とする。今回を含む既存6台は停止のまま保全。旧runのResumeは使わない。モデル往復・daemon操作・削除は含めない。

選択肢2を選んだ理由となった前提が変わったため、承認済み操作案の停止条件に従い利用者へ訂正と修正案を提示する。追加VMはまだ承認・実施していない。
