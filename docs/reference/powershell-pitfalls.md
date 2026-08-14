# PowerShell / .NET API の実測済みの落とし穴集

本プロジェクトの作業（Windows 11 / PowerShell 7）で実測した落とし穴と回避策。いずれも実害または手戻りが発生した実測に基づく。出典は各項の Issue / ADR 参照（handoff の申し送りから移設。移設元の経緯は git 履歴参照）。

## ファイル追記・書き込み

- **`Add-Content` は使わないこと**。Windows で CRLF を書き込み、中央ストア等の「UTF-8・BOM なし・LF 固定」契約に違反する。中央ストアへの追記は Python `open(path, "a", encoding="utf-8", newline="\n")` を使う（ADR-0064）
- **`Set-Location` は .NET の静的 API に効かない**。`[System.IO.File]::WriteAllText` 等はプロセスの作業ディレクトリが基準のため、`Set-Location` 後の相対パスは意図しない場所を指す。**絶対パスを使用すること**。サブエージェントへ破壊的検証を委譲するときの制約一式は `subagent-dispatch` B 群「破壊的検証」の行が定める（ADR-0093。出所: Issue-0076。同じ機構で 2 度の実害: 決定記録インデックス 92 行が空に／配布物に BOM 混入）

## 型・構文

- **`,@($list)` は List に対して型エラーになる**（実測）。単項カンマで包むときは `.ToArray()` を使う

## 検索・集計

- `Select-String` に `-Recurse` は無い。再帰検索は `Get-ChildItem -Recurse -File` とのパイプで書く
- `Get-ChildItem -Path <ファイル名> -Recurse` はファイル名をフィルタ解釈して同名ファイルを全て拾う。ルート直下ファイルは `Get-Item`、ディレクトリは `Get-ChildItem -Recurse -File` で別々に集めてパイプする（Issue-0056）
- `Group-Object Filename` は basename で束ねるため、同名ファイル（`SKILL.md` 等）のファイル別集計に使えない。`Group-Object Path` を使うか、最初からファイルごとに個別実行する
- **`Select-String` は行数を数えるため、複数語句を正規表現の OR でまとめると同一行にある場合に 1 件としか数えない**。語句ごとに個別実行して件数を確認すること（Issue-0042）
- **`Measure-Object -Line` は件数集計に使えない**（入力オブジェクトの行数を数える）。件数は `(… | Measure-Object).Count`
