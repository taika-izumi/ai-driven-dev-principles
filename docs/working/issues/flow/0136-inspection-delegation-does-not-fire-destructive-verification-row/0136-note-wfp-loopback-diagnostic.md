# WFPの遮断フィルターがあるのにループバック接続が成功する理由

問い: CodexSandboxOfflineのTCPループバック接続が、対応するWindows Filtering Platform（WFP）の遮断フィルターが存在しても成功する理由は何か。

## 現在の結論

2026-09-09、ユーザーがWindows側の通信フィルター診断を「1で」で選択。管理者権限でのフィルター採取と、接続直前の親子の状態採取まで実施した。遮断フィルターの欠落・対象ユーザーの相違は観測されなかった。制限付きトークンによる単純なDACL不一致もメモリ内の対照検査で支持されなかった。どのフィルターが最終的な通信判定を行ったかは未特定。

ファイアウォール規則・監査設定・WFP設定を変更せずに調査した。通信キャプチャは開始していない。タスク0の通信拒否条件は未達のままであり、後続実装へ進まない。

## 実測

| 確認 | 結果 | 判断の限界 |
|---|---|---|
| 通常ユーザー権限でnetsh wfp show filters | ERROR_ACCESS_DENIED、管理者権限が必要 | Codexツールの通常ユーザー実行許可とWindowsの管理者権限は別 |
| UACを通して同じ一覧取得 | 成功。Codex用TCPループバック遮断フィルター278474を確認 | 保存時点の一覧であり、過去の接続の判定履歴ではない |
| 試験の親子を接続直前で待機して採取 | 親PID18964・子PID22876、双方SID末尾1003、宛先127.0.0.1:51980。両時点にフィルター278474が存在 | 起動途中に規則が消える仮説は、この2時点では支持されない |
| 待機解除後の通信 | 親子ともTcpClientの接続成功。前後の通常実行も成功 | バイト列の往復やインターネット到達は未検査 |
| ファイル保護 | 親子で保護代用品5件とjunction経由の書き込み拒否、保護対象6件の前後ハッシュ一致 | 通信判定の成功を意味しない |
| 同じAPIの制限付きトークンでAccessCheck | isRestricted=true。ユーザーSIDだけを許可するDACLでaccess=1を許可、制限SIDを追加したDACLでも許可。空DACLでは拒否。API呼出はすべて成功 | WFP内部の判定トレースではない。AccessCheckの要件を満たすためgroupをメモリ内だけで補った |

フィルター278474は`FWPM_LAYER_ALE_AUTH_CONNECT_V4`、`FWPM_SUBLAYER_MPSSVC_WF`、`FWP_ACTION_BLOCK`。条件は127.0.0.0〜127.255.255.255、オフラインユーザーSID、TCP、宛先ポート1〜65535だった。

同じ層にはAppContainerLoopbackとQuarantine Default Inbound Loopback Exceptionの許可フィルターも存在する。しかし、別サブレイヤーの許可フィルターが一覧にあるだけでは、この接続に対して遮断を上書きしたとは断定しない。

## 証拠

作業領域は`D:/Dev/002_AiDev/MakeAiInstructions/.worktrees/isolated-verification`。以下はそこからの相対パス。

- `.tmp/wfp-diagnostics/d0f4509e-3bd0-4644-b496-8583f37aa948/diagnostic.json` — 権限不足を明示して停止した診断スクリプトの結果。
- `.tmp/wfp-diagnostics/a734c923-0463-481d-b867-60951d2ed855/` — 管理者権限での成功記録とloopback-filters.xml。
- `.tmp/verification-probes/wfp-live-f3b75720-8722-4c6e-b6d6-2fbbef16a7cf/control/` — 接続直前の親子フィルターXML、SID・PID・ポート、API要求・応答、通信の前後対照、保全ハッシュ。
- `.tmp/verification-probes/token-c08b089c-abdc-4885-b8ef-0af0ef959f9c/control/app-server-events.jsonl` — 制限付きトークンとAccessCheckの正負対照。

再現コードは`scripts/verification/tests/Invoke-WfpDiagnostic.ps1`、`Invoke-EnvironmentProbe.ps1 -CaptureWfp`、`fixtures/BoundaryProbe.ps1`、`AppServerBoundary.ps1`、`TokenConditionProbe.ps1`。すべて診断用であり、共通CLI本体への新機構採用ではない。

## 参照した一次情報

- [Microsoft: netsh wfp](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/netsh-wfp) — 条件を絞ったフィルター・既存イベントの表示。実機ヘルプでも引数を確認した。
- [Microsoft: ユーザー・アプリによるフィルター](https://learn.microsoft.com/en-us/windows/win32/fwp/permitting-and-blocking-applications-and-users) — ユーザーのセキュリティ記述子はアクセス判定で条件一致を判断し、アクセス許可自体が通信許可を意味するわけではない。
- [Microsoft: 制限付きトークン](https://learn.microsoft.com/en-us/windows/win32/secauthz/restricted-tokens) — 制限SIDがある場合の二段階のアクセス判定。

いずれも2026-09-09閲覧。一般仕様の説明と、この実機の成功・失敗の実測は区別する。

## 残る確認

ポート51980に関係する既存のWFPイベントを、監査設定を変更せず取得する管理者起動を試みた。Windowsから「この操作はユーザーによって取り消されました」が返り、診断本体は未実行。実行セッション97586は終了し、待機中プロセスは残していない。取消が手動か確認画面の期限切れかは判定しない。自動承認レビューによる拒否ではない。

再実行にはWindowsの管理者確認が必要。準備した`Invoke-WfpDiagnostic.ps1 -RemotePort 51980`はフィルター一覧と既存のイベントだけを読む。取得できても記録が無い場合は原因を確定せず、次の観測方法を判断する。管理者起動を自動で再試行しない。

保存前にPowerShell6ファイルの構文解析、接続直前の親子フィルターXML、保護対象6件の前後ハッシュを再照合した。実装全体の動作確認ではない。

## 管理者起動の再試行（2026-09-09 11:44〜11:45）

ユーザーが「今ならすぐ対応できる」と再試行を明示許可。UAC経由の起動と既存イベント取得は成功した。`NETEVENTS = on`だったが、過去のポート51980に対応するXMLは`<netEvents/>`（0件）。過去の管理者起動取消が何に由来したかは、この再試行の成功からは確定しない。

古い記録の消失だけが理由かを切り分けるため、同じ保護条件で新規試験を行い、直後に実際の試験ポート・プログラム・ユーザーに絞って既存イベントを取得した。親子のTCP接続は引き続き成功し、直後のイベントも0件。取得コマンドは終了0でXMLを生成しているため、権限不足や取得失敗を0件と扱った結果ではない。

- `.tmp/wfp-diagnostics/efa79437-b788-4f3f-884a-0610b2547894/` — 再試行成功、NETEVENTSの既存設定、過去接続のイベント0件。
- `.tmp/verification-probes/wfp-immediate-1ed53c42-3171-44e3-ade2-b40f5485f81e/control/` — 新規試験、接続直前の親子フィルター、実応答、`wfp-immediate-netevents.xml`と取得終了コード。

管理者起動待ちは解消。原因特定には、既存イベント取得以外の観測が必要である。イベントが無いことを通信拒否の根拠にはしない。監査設定の変更・新規キャプチャ・規則の変更は引き続き未実施。
