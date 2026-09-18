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

## 追加調査（2026-09-09）

ユーザーが「通信遮断できる起動経路を追加調査する」を「１で」で選択。同じ保護条件を保ち、一時的な設定指定とモデルを呼ばないAPIで切り分けた。環境設定やファイアウォール規則は変更していない。

| 調査 | 結果・意味 |
|---|---|
| sandboxに`-c windows.sandbox="elevated"`を追加 | 親子ともループバックTCP接続成功。明示指定だけでは通信拒否にならない |
| CLI 0.153.4からAPIスキーマを生成 | `command/exec`はスレッド・ターンを作らずコマンドを実行でき、`permissionProfile`を受け取る。比較経路として使う。本実装への採用は未決定 |
| 専用stdio app-serverから同じプロファイルでcommand/exec | Windows方式はelevatedを明示。親子の書き込み制限とjunction拒否は成立したが、親子のループバックTCPは成功。試験終了2 |
| 同じAPIと設定でwhoami /userだけを実行 | 実行ユーザーは`spring\codexsandboxoffline`。専用オフラインユーザーが使われていることを確認 |
| 既存Windows通信制御を読み取り | Domain・Private・Publicすべて有効、BFE・mpssvcはRunning。Codex用の3遮断規則は有効・Block・Outboundで、対象SIDはwhoamiと一致。TCP規則は127.0.0.0/8と全ポートを含む |

規則のEnforcementStatusは`ProfileInactive Enforced`。一覧の有効表示・SID・アドレスの一致から、パケット単位の適用成功まで推定しない。通信が通った内部原因は未特定であり、設定漏れやファイアウォール全体の無効化だけでは説明できない。調べた2経路で要求を満たす起動方法は得られなかった。実モデルのexec経路を検証済みとは扱わない。

API比較の途中で、既定プロファイル未指定による起動拒否と、Windowsでは任意の`outputBytesCap`が非対応という2件のエラーを観測した。`default_permissions="inspection"`の明示と任意指定の除去で解消。試験用`AppServerBoundary.ps1`に反映した。サーバーは標準入力を閉じて終了し、専用プロセス以外の停止・常駐登録は行わない。

追加の証拠（上記作業領域からの相対パス）:

- `.tmp/verification-probes/elevated-6243cc02-f736-4512-8e36-2c72fab43d74/control/` — sandboxへのWindows方式明示。
- `.tmp/verification-probes/appserver-f216affb-a53d-4526-ba2c-b81ea6cfc1b5/control/` — 既定プロファイル未指定の失敗。
- `.tmp/verification-probes/appserver-0d5fbcad-ff1c-4331-8223-cffd241b1a8e/control/` — 出力上限指定の拒否。
- `.tmp/verification-probes/appserver-9d1a79e1-7465-4561-8c7a-5a574f64379c/control/` — API比較の要求、全応答、前後対照、保全ハッシュ。
- `.tmp/verification-probes/identity-04b24aa8-ae09-4220-a298-c57701918a58/control/` — 実行ユーザーの応答と`network-state.json`。
- `.tmp/codex-protocol-01534/v2/CommandExecParams.json`等 — 当該CLIから生成したAPI定義。現行Web資料から推測した引数ではない。

次の論点はWindows側のパケットフィルターがループバックに適用されない理由の診断か、別の隔離構成の設計である。いずれも未選択。通信禁止要求を緩めて試験を合格へ変更する案は採用していない。

その後ユーザーがWindows側の診断を選択した。接続直前のWFPフィルター採取とトークン条件の検査結果は`0136-note-wfp-loopback-diagnostic.md`を参照。通信拒否は引き続き未達。
