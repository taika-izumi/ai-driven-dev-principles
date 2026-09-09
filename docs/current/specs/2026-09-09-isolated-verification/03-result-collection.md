# 検証結果の回収と照合

## 対象ファイル

- `scripts/verification/Result.psm1`: 状態判定・成果物検査・結果JSON作成。
- `scripts/verification/result.schema.json`: 主担当へ返す結果の書式。

## 責務とインターフェース

`Complete-VerificationRun(PreparedRun, ExecutionResult) -> VerificationResult`。Codexの最終応答をデータとして読み、起動側が保存したイベント・実ファイル・原本状態と照合する。原本への自動適用を行わない。

`VerificationResult`は `schemaVersion, runId, status, summary, sourceState, agentVerdict, checks, findings, artifacts, unverified, execution, runRoot` を持つ。`schemaVersion=1`、`execution`には実行側の開始・終了・停止結果を保持する。`sourceState`は`unchanged / changed / unreadable`。

| status | 意味 | CLI終了コード |
|---|---|---|
| `completed` | 実行・記録・応答・対象版の照合が完了 | 合格0、不合格1 |
| `incomplete` | 一部未検証、根拠欠落、応答不正等 | 2 |
| `blocked` | 受付・起動・保護条件・認証等が成立しない | 2 |
| `source_changed` | 準備中または検証中に原本の選択対象が更新された | 2 |
| `timed_out` | 時間超過で停止処理を行った | 2 |

`completed`自体はテスト合格を意味しない。`agentVerdict`を併記する。未起動なら`agentVerdict=null`。停止未確認など複数の問題は`unverified`と`execution`へすべて残し、単一のstatusで隠さない。

## 判定と照合

1. 起動・終了・時間超過・プロセス群の停止状態を確認する。終了コード0だけで完了にしない。
2. JSONLの終了イベントと最終応答の書式・実行番号を照合する。失敗イベント、応答欠落、未知の必須値、別実行の番号は合格不可。
3. 検証担当が挙げた成果物のパスを当該実行領域内へ解決する。範囲外・再解析ポイント・存在しないものを拒否する。成果物は相対パス・サイズ・SHA256とともに返す。
4. 各検査の証拠ファイルと保存済み実行イベントを照合する。CLI 0.153.4では`type=item.completed`かつ`item.type=command_execution`の`item.id, item.command, item.exit_code, item.aggregated_output`を使う。`checks[].command`は実際に呼ばれたコマンド全文、`exitCode`は実終了コードと照合する。途中・終了の同一itemは`item.id`で対応付ける。文字列を都合よく補正して別の実行と同一視せず、一意に対応付けられない検査やその版で必要なイベントが取得できない場合は`incomplete`。回収結果の各checkに対応する`eventId`を付す。既知の不合格を示す実出力と`pass`が矛盾する場合も`incomplete`として説明する。意図した失敗を確かめる検査は、依頼の成功条件と照らし、非ゼロ終了だけで不合格にしない。任意のテスト内容の妥当性まで機械的に保証するものではない。
5. コピー準備時と同じ選択規則で原本を再列挙・再計算する。ファイル追加・削除・内容変更があれば`source_changed`。誰が変えたかを根拠なく断定せず、元の対象版に対する結果として返す。原本へ書き戻さない。
6. `control/result.json`を当該実行について一度だけ作成する。同じ実行の既存結果を上書きせず、再試行は新しい実行番号を使う。JSONと結果の場所を主担当へ返す。

本番の共有ツール全域を毎回ハッシュ監視しない。保護は実行境界で担い、導入検証では共有ツール・既存記録・起動処理の代用品を起動側で照合する。原本の選択対象の前後比較は毎回行う。

## 主担当への提示

主担当は結果を読み、指摘・再現テスト・実行された検査と残る未検証範囲を利用者へ示す。追加テストを本体へ採用する場合は、その内容を確認して通常の変更工程で取り込む。検証担当の生成物を無条件に実行・適用しない。

## 関連ADRと検証

ADR-0141・0145・0146・0147。V5・V6・V7の回収側を担当する。応答の欠落・不正JSON・別実行番号・偽の合格・範囲外成果物・原本更新・既存結果の上書き拒否をAI呼び出しなしで検査する。
