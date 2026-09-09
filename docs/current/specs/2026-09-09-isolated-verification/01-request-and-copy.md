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

`PreparedRun`のキーは `runId, sourceRoot, runRoot, workRoot, tempRoot, controlRoot, request, settings, sourceManifest`。パスは解決済みの絶対パス。`sourceManifest`は相対パス・サイズ・SHA256の配列とHEADの値（存在しなければnull）、HEADの参照先を表す`headRef`（detached時はnull）、全参照のオブジェクトIDと名前を名前順に並べた`historyRefs`、対象の総数、除外一覧を含む。

## 処理とデータ配置

1. `git ls-files -z --cached --others --exclude-standard`で追跡済みと未追跡を列挙する。削除済みの追跡ファイルはコピーせず、対象状態には削除を記録する。追加対象と統合し、重複を除く。
2. `.git`の実体、共通実行領域、起動設定を自動でコピーしない。無視された依存・テストデータが必要な場合は`extraInputPaths`で明示し、除外した結果として未検証なら報告する。
3. 入力・出力・それらの祖先の再解析ポイントを検査し、リンクを辿らない。追加パスの親移動・絶対パス・原本外への参照を拒否する。
4. `runsRoot/<runId>/`を新規作成し、`work/`へファイルの内容を複製する。既存ファイルへのリンクやハードリンクを作らない。`temp/`は専用一時領域、`control/`は依頼・設定の非秘密部分・元の対象一覧・実行記録・最終結果の保存先。
5. 空のテンプレートと原本と同じオブジェクト形式を指定して、`work/`へ新しいGit管理領域を作る。履歴がある場合は`git bundle create --single-worktree --all`と入力側のHEAD指定で`control/history.bundle`を作り、空のコピー側でverify・unbundleを行う。全参照と入力worktreeのHEADから到達できる履歴を移し、原本の設定・フック・リモート設定・共有オブジェクト参照をコピーしない。他worktreeだけのHEAD、reflogだけに残る履歴、到達不能オブジェクト、Git LFSの外部実体は含まない。
6. 参照先とHEADをコピー内に復元し、元の一覧と一致することを確認する。ブランチ上のHEADは`headRef`で元のブランチ名へ戻し、detached時はコミットを直接指す状態を保つ。コミット前のブランチ名も保持する。HEADがある場合は`read-tree`でコピーのインデックスをHEAD基準にする。checkoutは行わず、複製した未コミット内容と削除状態を上書きしない。原本のステージ済み／未ステージの区別は再現しない。全オブジェクトを`git fsck --full --no-reflogs`で検査する。
7. ファイルと履歴の準備後に原本を再照合する。入力の増減・内容変更・HEAD・headRef・全参照の更新があれば`source_changed`で止め、半端なコピーを実行しない。同じコミットを指すブランチ間の切り替えも検出する。無制限の自動再試行はしない。
8. `git rev-parse --show-toplevel`と`git rev-parse --absolute-git-dir`の結果が、それぞれ`work/`と`work/.git`へ一致することを確認する。Git管理領域の読み取り専用化は、`02-isolated-execution.md`の実行ブロックが検証担当の起動時に行う。コピーの準備成功だけでは権限保護の成立としない。

実行領域が原本配下にある場合は、設定した`runsRoot`全体を列挙から除外する。原本と同じ場所、原本を包含する出力先、入力として選択された出力先は拒否する。既存の共有一時領域の内容は変更しない。

## 固有の制約と検証

新しい実行番号はUUIDで作り、既存領域があれば再利用せず受付エラーにする。失敗した実行の作成物も保存先を報告する。自動削除をしない。コピーの整合性はハッシュ照合で確認するが、コピーしたこと自体を権限制限の証拠にしない。

V1・V2を担当する。未知キー、追加パスの`..`、junction、出力先の入れ子、削除済みファイル、コピー中の変更、未追跡ファイルをテストに含める。原本配下と原本外の両配置でGitの探索先がコピー自身であることを確認する。

履歴の準備では、過去の本文・タグ・別ブランチ・detached HEAD・blame・参照先更新・worktree入力・空の履歴を検査する。浅い履歴と部分クローンは、完全な履歴として扱わず準備を停止する。Git操作はユーザー全体・システム設定と親のGit環境変数を継承せず、遅延取得と対話的な認証を無効にする。履歴を外部から自動取得しない。各Git処理は30秒を上限とし、超過時は不成立として返す。

## 関連ADR

ADR-0145・0146・0147・0148・0150。全体の目的と承認範囲は`00-overview.md`を参照する。
