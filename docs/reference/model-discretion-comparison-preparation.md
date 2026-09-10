# モデル裁量との比較の準備メモ

更新日: 2026-09-10。ADR-0166と開発ロードマップ4.0節に従う実行案の準備資料。基本設計・題材はユーザー承認済み、詳細仕様は機械検証まで終えて確定済み、実験は未実施。調査済みの事実と候補を再利用し、準備の重複を避けるために作成した。

## 確認した事実

- ローカルCLIの版表示: Codex 0.153.4、Claude Code 2.1.267。モデルへの問い合わせは実施していない。
- Claudeの認証状態は `loggedIn=true / authMethod=claude.ai / subscriptionType=max`。ユーザー設定は `opus[1m] / high`。Codexの設定は `gpt-6-astra / medium` で、ローカルモデル一覧にも同IDがある。設定・一覧の存在だけでは試験用CLIからの起動成功を意味しない。
- このサンドボックスで `codex login status` は `Not logged in`。一方、アプリの利用枠取得は成功し、取得時点のCodex枠は16%使用（残り84%）だった。アカウント共通の値であり、この比較の消費量でもCLIの認証成立証拠でもない。認証情報のコピーや設定変更は行っていない。
- LoopForAlphaの場所は `D:/Dev/001_Trade/LoopForAlpha`。確認時HEADは `86d89a8091de8366161569a7771affb0ff279607`。作業ツリーとHEADの一致は未確認であり、読んだ作業ファイルをこの版の確定内容とは扱わない。
- `tools/process_trace/` は会話履歴のJSONLから4種のCSVを作る開発用ツール。対応する `tests/test_process_trace_{records,session,tables}.py` が存在する。今回読んだのはコード・テスト・課題資料のみで、実会話履歴・製品認証情報・市場データは読んでいない。
- `records.py` の `parse_ts` は「tz付きdatetime」を返す説明だが、タイムゾーンなし入力もそのまま日時に変換する。`2026-09-01T00:00:00Z` と `2026-09-01T00:00:01` を同関数に渡すと、返り値のtzinfoはUTCとNoneになり、`min` で `TypeError: can't compare offset-naive and offset-aware datetimes` を再現した。`session.py` の `build_session` に同じmin/max経路がある。全体CLIでの再現・期待仕様の確定は実行準備で行う。
- 調べた `tools/process_trace/` と対応テスト3ファイルについて、Gitの未コミット差分はなかった。プロジェクト既存venvのPythonはこのサンドボックスで起動不能だったため、アプリ同梱Pythonから `-B` でモジュールを読み再現した。元コードへの変更・バイトコード出力は行っていない。
- `cli.py` は指定フォルダ直下の全JSONLを対象にする。セッション指定オプションは現行コードにない。
- LoopForAlpha#Issue-0010は取得CLIの失敗経路をテストが区別できない課題。純粋な製品不具合修正とは異なるため、ロードマップの不具合題材にそのまま充てるのは要検討。

## 承認済みの設計と次の作業

既存契約枠の利用はADR-0167、ログ解析2題材・代表2モデル・8実行・300分上限と判断の分担はADR-0168へ記録した。いずれも2026-09-10に本会話の選択肢1への回答で承認済み。確定した正本は [比較仕様](../current/specs/2026-09-10-model-discretion-comparison/00-overview.md)、作業順は [実行計画草案](../working/plans/2026-09-10-model-discretion-comparison.md) を参照する。

通常ユーザー権限での追加確認では `codex login status` は `Logged in using ChatGPT` だった。Codexも既存契約で認証済みで、追加ログインや認証情報のコピーは不要。サンドボックス内の未ログイン表示と、通常ユーザーの結果を区別する。

未実測なのは、試験専用設定の読み込み・親子への指示継承・書き込み境界・固定検査の保護・親子停止・実行結果回収。CLIの機能説明だけで成立済みとはしない。人工ログ・固定検査の内容は計画内に具体化したが、試験用ファイルの生成や比較モデルの起動は未実施。

## 参照した一次資料

- [OpenAIの認証資料](https://learn.chatgpt.com/docs/auth): ファイル・OS資格情報ストア・メモリ内の保存方式を照合。今回のユーザー権限による結果差の具体的原因は断定しない。
- [Claude Codeのモデル設定](https://code.claude.com/docs/en/model-config): エイリアスが更新されること、固定名と結果のmodelUsageによる実モデル確認を照合。
- [Claude CodeのCLI資料](https://code.claude.com/docs/en/cli-usage): safe-modeと設定読み込み元の説明を照合。Windowsでの保護・親子停止の成立証拠とはしない。

参照日: 2026-09-10。提供元の一次資料による機能説明、ローカルの版・認証・関数の再現結果を分けて記録する。
