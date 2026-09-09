# 共通CLIで要求する保護条件が実際に成立するか

問い: Codex CLI 0.153.4の採用予定の起動経路で、書き込み先の制限とテストコマンドの通信拒否を同時に成立させられるか。

## 現在の結論

2026-09-09、タスク0は未完了。通常ユーザーから`codex sandbox -P inspection`を起動すると、親子のファイル書き込み制限と新規junction経由の保護は観測できた。一方、`network.enabled=false`でも親子ともループバックTCPへ接続でき、計画の正負対照に失敗した。タスク1〜4、execのAI試験、導入・公開へは進んでいない。

コードは`codex/isolated-verification`ブランチの`scripts/verification/tests/`。初回の3ファイルは試験準備段階で、`-IncludeAgentProbe`は明示的に未実装のエラーを返す。sandbox単体が成功してもタスク0完了にはしない。

## 試験環境と実行結果

- 作業領域: `D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。
- Codex: `codex-cli 0.153.4`、PowerShell: `7.6.5`。CLI実行ファイルと引数は各実行のJSONに保存。
- 試験領域は実行ごとに新規作成。既存原本・共有ツール・既存記録そのものを試験対象にせず、代用品を用いた。モデル呼び出し、外部サービス送信、削除は未実施。
- 既存の`build-dist.ps1 -Check`と`sync-template.ps1 -Check`は作業開始時に成功。
- 保存前に試験3ファイルのPowerShell構文解析、補助関数の正負対照、新規Git試験領域の内容・追跡対象、実測JSONの保護対象6件を読み直して確認した。共通CLI本体は未実装のため本体の動作確認ではない。

| 実行 | 結果 | 判断 |
|---|---|---|
| Codexの制限環境から起動 | 通常親子の書き込み・ループバック接続は前後とも成功。sandboxは`CreateRestrictedToken failed: 87`、終了1 | 制限付き試験自体の起動失敗。拒否成功ではない |
| 通常ユーザー側から新規領域で起動 | sandbox終了0、親子起動成功。work/tempへ書き込み成功、保護代用品5件への書き込み拒否 | ファイル境界は今回の対象で成立 |
| 同上、新規junction | 親子ともwork内に新規junctionを作成し、その先のsource代用品への書き込みは拒否 | 動的なリンク経由でも今回の対象は保全 |
| 同上、ループバックTCP | 通常親子で前後とも接続成功。制限付き親子でも接続成功 | `network.enabled=false`による通信拒否条件は未達。試験スクリプトは終了2 |
| 原本等の保全照合 | sentinel5件と試験スクリプトの計6件で前後SHA256一致 | 今回の試験対象が不変。全ファイル・全経路への一般化はしない |

正の対照は同じ待受を稼働させたまま前後で行った。TcpClientで127.0.0.1の使い捨てポートへ接続し、HTTPプロキシの動作は試していない。外部インターネットへの到達性も未検証であり、ループバック成功から外部接続可能とは結論しない。

## 証拠の所在

以下は作業領域からの相対パス。各controlには`environment-result.json`、`sandbox-boundary.json`、`normal-before.json`、`normal-after.json`、CLIヘルプと版、生成プロファイルを保存した。`environment-result.json`には前後ハッシュと全プロセスのstdout/stderrを保持する。

- 制限環境での起動: `.tmp/verification-probes/433f3649-d3a6-4b39-b01a-2fb4c9d6aed1/control/`。
- 通常ユーザー側での起動: `.tmp/verification-probes/host-da0d51e5-fe73-4445-a09b-c745bc18a2d5/control/`。

試験領域とjunctionは証拠として残す。領域の一括ステージや後片付けは行わない。

## 原因の切り分けと残る判断

OpenAIの[Windows sandbox公式説明](https://learn.chatgpt.com/docs/windows/windows-sandbox)は、`unelevated`が制限トークンと環境変数によるオフライン制御を使い、`elevated`の専用ユーザー向けファイアウォールとは異なることを説明している。実機のsandboxヘルプはWindows restricted tokenを明記している。今回の直接TCP接続成功はこの違いと整合するが、今回の内部経路の確定には至っていない。

[設定の公式リファレンス](https://learn.chatgpt.com/docs/config-file/config-reference)では`permissions.<name>.network.enabled`はコマンドの通信許可を制御し、プロキシを起動する設定ではない。資料は現行の説明であり、この実機の動作成功を保証する証拠には用いない（2026-09-09閲覧、OpenAIの一次情報）。

次に確認する候補は、同じ保護条件を維持したWindowsの実行方式・通信制御の適用経路と、exec用の起動前確認の方法。仕様02が要求する明示的なWindows設定を含め、sandbox単体とexecの違いを切り分ける。設定名の追加だけで成功扱いにしない。

通信要求の緩和、別の隔離機構の導入、ユーザー環境の設定変更は未選択。現行計画は「事前試験が不成立なら後続へ進まない」を要求するため、実装を止めて判断を求める。
