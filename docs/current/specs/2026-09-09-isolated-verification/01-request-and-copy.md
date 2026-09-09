# 依頼と独立コピーの準備

## 対象と責務

- `scripts/verification/Invoke-IsolatedVerification.ps1`: CLI受付と3ブロックの呼び出し（未実装）。
- `RequestCopy.psm1`: 入力検査・ファイル・Git履歴・再検証入力のコピー。
- `request.schema.json`: v1とv2の識別可能な依頼書式。
- `README.md`: 実装済み範囲・導入条件・呼び出し例。

`New-VerificationRun(RequestV2, SettingsV2) -> PreparedRunV2`。既存v1のコピー処理を共用するが、v2の新しいキーを既存の厳密なv1検査へそのまま渡さない。v1部品試験は維持し、Linux共通CLIはv2のみ受け付ける。

版の振り分けと変換はRequestCopy.psm1が所有する。公開関数New-VerificationRunから、v1は既存処理を保持する内部関数New-LegacyVerificationRun、v2は新しい内部関数New-LinuxVerificationRunへ分岐する。v2側がRequestV2・SettingsV2を検査した後、Requestの共通6キー（schemaVersionだけ1へ設定）とSettingsの`codexPath, pwshPath, runsRoot, model, timeoutSeconds`を明示的に選んでv1内部処理を呼ぶ。recheckやDocker設定をv1検査へ流さない。

v1内部処理が返した同一runId・作業領域・manifestを再利用し、v2側で再検証入力と最後の原本照合を行う。PreparedRunV2には元のRequestV2・SettingsV2を保持する。Get-VerificationSourceManifestを呼ぶ際は必要なsourceRoot・extraInputPaths・runsRootを使い、外部の版検査をこの低水準関数へ任せない。現在のrequest.schema.jsonはschemaVersion=1に固定されており、この分岐・v2検査は未実装である。

## 依頼と設定

RequestV2の必須キーは`schemaVersion=2, caller, sourceRoot, objective, acceptanceCriteria, extraInputPaths`。callerは`claude-code / codex`。目的と条件は空不可。sourceRootはGit作業ツリーの絶対パス。extraInputPathsは原本内の相対パスで、通常Gitが無視するデータ等を明示追加する。未知のキー・型違いを拒否する。

任意の`recheck`は`previousResultPath, artifactPaths`を持つ。前者は前回のcontrol/result.jsonの絶対パス、後者はその結果に掲載された再現テストの相対パス配列。前回がfailであることは再検証の妨げではない。結果が実行未成立・停止未確認なら受理しない。

SettingsV2は`schemaVersion=2, runtime=linux-docker, codexPath, pwshPath, dockerPath, runsRoot, model, timeoutSeconds, commandTimeoutSeconds, imageId, limits`を持つ。limitsは`memoryMiB, cpus, pids, outputBytesPerCommand`。パスは絶対、時間・資源・容量は正、commandTimeoutSecondsは全体上限以下。imageIdはローカルの完全な不変IDを指定し、latestタグのまま実行しない。子へ汎用のDockerフラグ・接続先・ホストパスを指定する欄を公開しない。導入設定自体は通常の入力コピーに含めない。

小さな試作用の設定例は全体600秒・1操作60秒・メモリ1024MiB・CPU1・pids128・1操作出力合計16MiB。これらは性能保証値ではなく、正常例が通るか試験で確認する。必要量を超える題材へ無断で範囲を広げない。

## 出力データ

PreparedRunV2は`schemaVersion=2, runId, sourceRoot, runRoot, workRoot, tempRoot, controlRoot, request, settings, sourceManifest, recheckManifest`を持つ。sourceManifestの`files, head, headRef, historyRefs, total, exclusions`は既存処理を共用する。recheckManifestには前回runId・結果ファイルのハッシュ・元artifactパス・コピー先パス・サイズ・SHA256を記録し、原本由来のファイルと区別する。

```
runsRoot/runId/
  work/                 # 原本の独立コピー、子が変更できる
  temp/                 # ホスト制御処理専用の一時領域
  control/              # 子へ直接公開しない
    source-manifest.json
    recheck-manifest.json
    history.bundle
    execution/          # 実行ブロックの記録
    result.json         # 回収ブロックが一度だけ作成
```

## 準備手順

1. 入出力・祖先・選択対象のリンクと再解析ポイント、原本を包含するrunsRootを拒否する。新しいUUIDのrunIdだけを使用し、既存物へ上書きしない。
2. `git ls-files -z --cached --others --exclude-standard`とextraInputPathsでファイルを選ぶ。runsRoot全体、原本のGit管理領域、導入設定、起動設定（.codex/.claude/.agents/.mcp.json）を除外し理由を残す。一般の仕様・課題・記録を親の判断で選び抜かない。サブモジュール等のディレクトリ入力は初回対象外として拒否する。
3. コピー前の一覧・サイズ・SHA256・HEADコミット・headRef・全参照を記録し、ファイル内容を実体コピーする。削除済みを復活させない。ハードリンクで共有しない。
4. 空テンプレートで原本と同じオブジェクト形式のGit領域を作る。全参照と入力worktreeのHEADを`bundle create --single-worktree --all`で移す。verify・unbundle・参照復元・fsckを行う。原本の設定・フック・オブジェクト外部参照を持ち込まない。
5. ブランチ名またはdetached状態を復元する。HEADがあればread-treeでインデックスだけを作り、checkoutで作業ファイルを上書きしない。原本のステージ済み／未ステージの区別は再現しない。空履歴・コミット前のブランチも扱う。
6. 再検証入力がある場合、前回結果を現在のrunsRoot内で解決し、結果のrunId・停止状態・artifact一覧を照合する。選ばれたファイルが今も掲載ハッシュと一致し、リンクでないことを確認する。`work/.verification-recheck/<previousRunId>/`へコピーし、既存原本の同名領域と衝突したら拒否する。子への短い依頼にコピー先を記載する。元の記録は変更せず、テストをホスト上で実行しない。
7. コピーのハッシュと原本状態を再照合する。ファイル・HEAD・headRef・全参照が変わればsource_changed。再検証ファイルも前後ハッシュを照合し、不一致ならblocked。Gitのルートと管理領域がコピー自身を指すことを確認する。
8. manifestをcontrolへ保存する。子からのGit変更禁止は実行ブロックが実効権限として成立させ、コピーしただけで保護成功とはしない。

途中で失敗した実行領域は診断用に保持し、自動削除しない。作成済みならrunRootと失敗段階をCLIへ返し、未作成ならrunRoot=nullとする。CLIは回収ブロックの失敗応答書式で1件のJSONを返す。保存できたファイルやmanifestと未完成のものを区別し、存在しない記録を成功扱いしない。不要になったものの削除は、既存の名指し承認の手順に従う。新しい一覧化サービスや自動清掃は追加しない。

## 制約と検証

Git全参照から到達できる履歴を対象とする。reflogだけの履歴、到達不能オブジェクト、LFSの外部実体は含めない。浅い履歴・部分クローンは停止する。親のGit環境変数・ユーザー全体とシステム設定を継承せず、遅延取得と対話認証を無効にする。Git各処理は30秒を上限とする。大きな履歴や長いWindowsパスへの無条件対応を主張しない。

V1・V2を担当する。既存のコピー・履歴試験に加え、v2の型と未知キー、再検証元の範囲外・改変・未停止・runId違い・衝突、元ファイルの変更とコピー先の一致を検査する。原本内外のrunsRootと、同一コミットへのブランチ切り替えを含む。

関連ADR: 0145〜0148、0150〜0152。
