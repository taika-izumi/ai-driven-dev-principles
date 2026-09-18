# Linux試作の起動前確認経路の読み取り調査

- 日付: 2026-09-09。
- 対象: v2計画タスク0。ユーザーが「主担当でタスク0から進める（推奨）」へ「１で」と回答した後の読み取り調査。
- 判定: **blocked**。調査したCLIヘルプ・生成済みプロトコル・公式文書から、内蔵機能を含む全実効ツール集合を自由依頼の解放前に取得する経路を特定できなかった。
- 意味: 保護の成立条件が未確認なので後続実装へ進まない。CLI内部に取得方法が絶対に存在しないと証明したものではない。
- 実施していないこと: モデル起動、固定入力による拒否試験、Docker起動、ユーザー設定変更、認証情報の読取・送信、リポジトリ本文の外部モデルへの新規送信。

## 実体と証拠

Codexは`C:/Users/d12an/AppData/Local/OpenAI/Codex/bin/fd4c151a749f3ab4/codex.exe`、`codex-cli 0.153.4`。SHA256は`CCDC9EB9DD71FBCFB03AD42C4ECA2B0D6FF6FBD32EBE9416550E6244561E559B`。

生ログとmanifestは、当該worktreeの`.tmp/linux-pilot-activation-readonly-f05ab93d498c439da98c05fe961f4ce4/`。manifestには実行した6コマンドのargv・終了コード・出力SHA256、調査した6プロトコルファイルのSHA256、ClientRequestの155メソッド名を保存した。6コマンドはすべて終了コード0。

1. `codex --version`
2. `codex exec --help`
3. `codex app-server --help`
4. `codex debug --help`
5. `codex debug prompt-input --help`
6. `codex features list`

生成済みプロトコルは`.tmp/codex-protocol-linux-pilot/`。既存の仕様レビューr2で0.153.4から生成した資料を使用し、今回も導入版が一致することを確認した。ランタイムの観測結果ではなく、プロトコル定義の調査である。実効設定の読取RPCやセッション開始RPCは実行していない。

## 確認した経路と限界

| 経路 | 確認した内容 | 全実効一覧の証拠にしない理由 |
|---|---|---|
| execのヘルプ | `--ignore-user-config`、`--ignore-rules`、`--strict-config`、`--json`、stdin入力が存在 | 読込抑制や未知設定の拒否は有用だが、全ツールの列挙・除去を保証する機能ではない |
| features list | shell_tool以外にもunified_exec、code_mode_host、view_image、apps、hooks、browser_use、computer_use等のフラグを確認 | 機能の有効値は実際にモデルへ公開された全ツール集合ではない。モデル・設定・実行形態による生成を観測していない |
| debug prompt-input | ヘルプはモデルに見せる入力リストのJSON化と説明 | 全ツール定義を出力するという契約を確認できない。本体は未実行であり、出力を推測しない |
| ClientRequest | 155メソッドを列挙。MCP状態一覧、config/read、model/list等がある | 内蔵を含む全ツール一覧の取得として使える契約を特定できない |
| ThreadStartResponse | sandbox、権限、model、thread等のトップレベル項目 | 全実効ツール集合を返す項目は確認できない。thread内の呼出履歴を利用可能一覧に置き換えない |
| ThreadStartParams | dynamicTools、selectedCapabilityRoots、config等 | 追加ツールや選択した機能の入力であり、実効集合全体の観測結果ではない |
| TurnStartParams | input、permissions、model、toolOutput等 | toolOutputは出力の受渡しであって全ツール一覧ではない |
| ListMcpServerStatusResponse | data内にMcpServerStatusのtools、resources、runtimeStatus等 | MCPサーバーごとの集合であり、内蔵編集・画像読取・コード実行等を含む保証がない |
| ConfigReadResponse | config、layers、origins | 設定の層を解決した結果であり、モデルへ渡すツール集合の観測ではない |

`features list`はそのコマンドの読み込んだ構成の状態であり、将来の子Codex専用構成の確認済み設定として再利用しない。CLIの`--ignore-user-config`だけで認証・プロジェクト設定・プラグイン・フック等がすべて隔離されたとも認定しない。

## 公式文書との照合

一次資料としてOpenAI公式文書を参照した。一般公開の機能名だけで検索し、プロジェクト資料は送信していない。

- [Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference): shell_toolとunified_execを別項目として説明。MCPのenabled_toolsはそのサーバーのツールに適用する許可リスト。code modeの除外対象も全ホスト操作の除去と同義とは認定できない。
- [Codex App Server](https://learn.chatgpt.com/docs/app-server): mcpServerStatus/listはMCPサーバーのツール・リソース・認証状態の一覧、config/readは設定の層を解決した読取として説明されている。

上記の範囲では全内蔵ツールの起動前列挙方法を確認できなかった。検索で見つかるResponses APIのallowed_tools等を、そのままCodex CLIの対応機能へ読み替えていない。公開文書と導入版の差もあり得るため、不在の断定には使わない。

## タスク0の判定と次手

仕様02は、取得経路が無い、または許可外ツールが残る場合はblockedと規定する。今回は取得経路の特定に至らず、拒否試験へ移る前提を満たしていない。そのためactivation.jsonのverified記録は作成せず、タスク1以降を停止した。実MCPイベントのfixtureも未取得である。

考えられる次手は次の2案。いずれも現時点では採用していない。

1. **子Codex本体も隔離する構成を再検討する。** ホスト上の全機能の除去へ依存する構造を見直す。モデル通信・認証・コピー搬入・停止方法を設計し直す必要がある。利用者の認証準備が必要になるかも設計時に確認する。コンテナの通信なしをそのまま適用できるとは主張しない。
2. **現構成を維持して調査を深める。** 導入版に対応する実装ソースや診断経路を確認し、ツール集合の生成箇所・取得時点・execとの一致を追う。対応ソースが特定できない場合や独自ビルドが必要な場合は、その時点で相談する。方法が見つかる保証はなく、取得不能のままモデルを自由起動しない。

逸脱照合: 一致。計画の取得不能時の停止条件を適用した。設計・保護条件・必須依存の変更は実施していない。
