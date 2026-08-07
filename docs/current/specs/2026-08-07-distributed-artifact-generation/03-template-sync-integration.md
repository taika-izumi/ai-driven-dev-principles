# 03: template 同期への変換組み込み

## 対象ファイル

- `scripts/sync-template.ps1` — 判定・変換ステップと `-Check` モードを追加する
- `template.manifest` — 変更しない（同期対象の定義は現状のまま）

## 責務

`template/` の生成に、ブロック 02 と同一の判定と変換を適用する。テンプレート配布物は配布先プロジェクトの**実ファイル**になるため、出所識別子の混入はプラグイン配布より直接的な害を持つ。

## インターフェース

```
scripts/sync-template.ps1 [-Check]
```

| モード | 動作 | 終了コード |
|---|---|---|
| 既定 | 規約を判定し、適合していれば `template/` を再生成する | 0 = 生成成功 / 1 = 規約違反（`template/` は変更しない） |
| `-Check` | 規約を判定し、ソースから再生成した内容と既存 `template/` を比較する。書き込みはしない | 0 = 一致 / 1 = 規約違反または不一致 |

`-Check` の一致判定はブロック 02 と同じ 2 条件（ソース由来の全ファイルが存在し内容一致／ソース由来でないファイルが存在しない）による。

## 動作

| ステップ | 処理 |
|---|---|
| 1 | `template.manifest` を読み、コメント行・空行を除いてファイル一覧を得る（現在 4 ファイル: `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md`） |
| 2 | 空インデックス生成対象 3 ファイル（`docs/records/decisions/README.md` / `docs/records/retrospectives/README.md` / `docs/working/issues/README.md`）について、テーブルのデータ行と直後の引用ブロックを除去した内容をメモリ上で生成する |
| 3 | ステップ 1・2 で得た**全 7 ファイル分の内容**へ `Test-ProvenanceConvention` を適用する。違反が 1 件でもあれば違反箇所と規約 ID を出力して非ゼロ終了する |
| 4 | `template/` を完全削除する |
| 5 | 各内容へ `Remove-ProvenanceNotation` を適用し、`template/` 配下の対応するパスへ書き出す |
| 6 | `template/` 配下に実在を指す出所識別子が 1 件も残っていないことを確認する（判定と同じ適用範囲・同じプレースホルダ判別を用いる）。残っていれば非ゼロ終了する |
| 7 | `scripts/check-claude-md-size.ps1` を呼び、CLAUDE.md の規模を計測する（警告のみ。同期はブロックしない） |

**判定（ステップ 3）を削除（ステップ 4）より先に行う。** 順序が逆だと、規約違反で停止したときに `template/` が消えたまま残る。

書き出し（ステップ 5）は `Copy-Item` によるバイト複製ではなく、テキスト書き出し（UTF-8 BOM なし・LF 固定）で行う。判定と変換を通した内容を書くため、複製では実現できない。

判定と変換のロジックは `scripts/lib/strip-provenance.ps1` を dot-source して共有し、`sync-template.ps1` 内へ複製しない。

## 影響を受けるファイル

単位は出所識別子の**出現回数**である（`00-overview.md` と `05` は行数で数えているため、突合時は単位に注意する）。

| ソース | ソース側 | 空インデックス化後 | 生成物側 |
|---|---|---|---|
| `docs/overview/folder-structure.md` | 8 | （対象外） | 0 |
| `docs/records/retrospectives/README.md` | 128（種別 1〜3 が 121、種別 4 が 7） | 12 | 0 |
| `docs/records/decisions/README.md` | 多数 | 0 | 0 |
| `docs/working/issues/README.md` | 多数 | 0 | 0 |
| `CLAUDE.md` / `docs/overview/principles.md` / `docs/inbox/README.md` | 0 | （対象外） | 0 |

`docs/records/retrospectives/README.md` のソース側 128 のうち 116 は一覧テーブルのデータ行にあり（種別 4 の 7 件はすべてここに含まれる）、空インデックス化で除去される。残る 12 が判定と変換の対象である。うち 1 行（21 行目）が R2 違反であり、ブロック 05 で先に是正する。

`docs/overview/folder-structure.md` にはこのほかプレースホルダが 7 箇所あるが、4 桁の数字を持たないため識別子ではなく、判定・変換いずれの対象にもならない。

## 順序上の制約

**ブロック 05（ソースの規約適合化）が先行しない限り、本ブロックの変更は `sync-template.ps1` を失敗させる。** 実装順序は 05 → 03 とする。

## ADR-0027 との関係

ADR-0027 は「説明文は保持し、インデックス行のみ除去する」と定めている。本ブロックは保持された説明文からも出所識別子を除去するため、ADR-0027 の Decision の適用範囲が変わる。ADR-0027 のファイルへ部分修正の注記を追加する（ステータスは Accepted のまま。`decision-log` の台帳監査における「部分修正あり（本体現役・状態変更なし）」の扱い）。これは `00-overview.md` の完了基準 7 で判定する。

## このブロック固有の制約・前提

- `template/` は git 管理下の生成物であり、この点は変更しない
- 空インデックス生成ロジック（`New-EmptyIndexContent`）自体は変更しない。判定と変換はその出力に対して適用する
- `check-claude-md-size.ps1` の呼び出しは末尾のまま維持する（警告のみで同期をブロックしない性質も変えない）

## 関連 ADR

- ADR-0027: テンプレート初期セットの基準を定義し、インデックス空生成を一般化する（本ブロックにより部分修正）
- ADR-0082: 保守者向けの根拠注記はソースに残し、注記を除去した生成物を配布する
- ADR-0033: 生成物は LF 固定で書き出す
