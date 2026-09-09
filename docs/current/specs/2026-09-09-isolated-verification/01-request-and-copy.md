# 依頼受付と検証用コピーの準備

## 対象ファイル

- `scripts/verification/Invoke-IsolatedVerification.ps1`: 共通CLIと3ブロックの呼び出し。
- `scripts/verification/RequestCopy.psm1`: 入力検査・コピー準備。
- `scripts/verification/request.schema.json`: 依頼の書式。
- `scripts/verification/README.md`: 両依頼元の呼び出し例、導入設定、失敗時の操作。

## 責務とインターフェース

共通CLIは `-RequestPath <JSONの絶対パス> -SettingsPath <導入設定JSONの絶対パス>` を受け取る。受付後は `New-VerificationRun(Request, Settings) -> PreparedRun`、実行、回収の順に処理する。標準出力は最終結果JSON1件、途中の説明は標準エラーへ出す。

依頼のキーは以下に限定し、未知キーと型不一致を拒否する。

| キー | 型・条件 |
|---|---|
| `schemaVersion` | 整数1 |
| `caller` | `claude-code` または `codex`。実起動の証拠ではなく依頼元の申告 |
| `sourceRoot` | 存在するGit作業ディレクトリの絶対パス |
| `objective` | 空でない検証目的の文字列 |
| `acceptanceCriteria` | 空でない文字列の配列。最低1件 |
| `extraInputPaths` | Gitで無視されたファイル等を追加する相対パスの配列。空配列可 |

導入設定は `codexPath`・`pwshPath`・`runsRoot`・`model`・`timeoutSeconds` を持つ。実行ファイルと出力先は絶対パス、時間上限は正の整数。導入設定に汎用の追加コマンド引数を持たせない。権限制限は実行ブロックが生成する。利用者の設定確認を経たファイルを用い、検証担当には更新させない。

`PreparedRun`のキーは `runId, sourceRoot, runRoot, workRoot, tempRoot, controlRoot, request, settings, sourceManifest`。パスは解決済みの絶対パス。`sourceManifest`は相対パス・サイズ・SHA256の配列とHEADの値（存在しなければnull）、対象の総数、除外一覧を含む。

## 処理とデータ配置

1. `git ls-files -z --cached --others --exclude-standard`で追跡済みと未追跡を列挙する。削除済みの追跡ファイルはコピーせず、対象状態には削除を記録する。追加対象と統合し、重複を除く。
2. `.git`の実体、共通実行領域、起動設定を自動でコピーしない。無視された依存・テストデータが必要な場合は`extraInputPaths`で明示し、除外した結果として未検証なら報告する。
3. 入力・出力・それらの祖先の再解析ポイントを検査し、リンクを辿らない。追加パスの親移動・絶対パス・原本外への参照を拒否する。
4. `runsRoot/<runId>/`を新規作成し、`work/`へファイルの内容を複製する。既存ファイルへのリンクやハードリンクを作らない。`temp/`は専用一時領域、`control/`は依頼・設定の非秘密部分・元の対象一覧・実行記録・最終結果の保存先。
5. コピー前後の入力一覧とハッシュ、コピー先のハッシュを比較する。入力の増減・内容変更があれば`source_changed`で止め、半端なコピーを実行しない。無制限の自動再試行はしない。
6. 空のテンプレートを指定して`work/`へ新しいGit管理領域を初期化する。`git rev-parse --show-toplevel`と`git rev-parse --absolute-git-dir`の結果が、それぞれ`work/`と`work/.git`へ一致することを確認する。原本のGit管理領域・設定・フックをコピーしない。新しい管理領域の読み取り専用化は、`02-isolated-execution.md`の実行ブロックが、検証担当を起動するときの権限プロファイルで行う。原本の履歴やインデックス状態が必要な検査は未検証として報告する。

実行領域が原本配下にある場合は、設定した`runsRoot`全体を列挙から除外する。原本と同じ場所、原本を包含する出力先、入力として選択された出力先は拒否する。既存の共有一時領域の内容は変更しない。

## 固有の制約と検証

新しい実行番号はUUIDで作り、既存領域があれば再利用せず受付エラーにする。失敗した実行の作成物も保存先を報告する。自動削除をしない。コピーの整合性はハッシュ照合で確認するが、コピーしたこと自体を権限制限の証拠にしない。

V1・V2を担当する。未知キー、追加パスの`..`、junction、出力先の入れ子、削除済みファイル、コピー中の変更、未追跡ファイルをテストに含める。原本配下と原本外の両配置でGitの探索先がコピー自身であることを確認する。

## 関連ADR

ADR-0145・0146・0147・0148。全体の目的と承認範囲は`00-overview.md`を参照する。
