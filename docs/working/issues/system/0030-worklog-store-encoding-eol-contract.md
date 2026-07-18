# Issue-0030: 中央ストア（log.jsonl / processed.jsonl）の文字コード・改行コード規約と追記手段が未定義

- **Status**: closed
- **Opened**: 2026-07-18
- **Closed**: 2026-07-18
- **起票元**: worklog v1.1 改訂サイクル（2026-07-17）のスモークテストで発生した delta（friction）
- **関連**: `skills/worklog-record/references/store-format.md`（ストア契約）、`skills/worklog-record/SKILL.md`（追記手順）、ADR-0037（改行正規化は git 側固定＝リポジトリ内のみ）、ADR-0045/0048〜0053（スキーマ）

## 課題内容

`worklog-record` は「`<folderName>/log.jsonl` へ1行 append」と書くのみで、**追記時の文字コード（UTF-8 / BOM 有無）・改行コード（LF / CRLF）・具体的な追記手段**が規定されていない。`store-format.md` にもストアファイルのエンコーディング規約がない。

今回の worklog v1.1 スモークテストでは、Windows/PowerShell で追記する際に BOM や CRLF の混入を避けるため `Add-Content -Encoding utf8NoBOM` を明示的に選ぶ必要があった（結果は BOM なし・LF で正しく追記できたが、規約に基づく選択ではなくエージェントの都度判断だった）。

固有の構造的リスク:

- 中央ストアは**リポジトリ外**（`<home>/.ai-dev-worklog/`）にあり、`.gitattributes` による改行正規化（ADR-0037）の管轄外。git では守れない
- 中央ストアは**全プロジェクト・全プラットフォーム共有**。別ツール・別 OS の既定追記（例: Windows PowerShell 5.1 の `Add-Content`/`Out-File` 既定は UTF-16 や BOM 付き UTF-8）が混ざると、追記専用 JSONL の「連結して1パスで機械走査」という設計根幹が壊れうる（BOM が行頭に混入、CRLF がトリム前提を崩す等）
- 読み側規約「`v` なし = v1」の行判別や jq 走査も、BOM/エンコーディング不整合で誤動作しうる

## 対処候補

- `store-format.md` に「ストアファイルは UTF-8（BOM なし）・LF 固定」を契約として明記する（最小コスト）
- `worklog-record` の追記手順に、プラットフォーム別の安全な追記手段（例: PowerShell は `-Encoding utf8NoBOM`、POSIX は通常のリダイレクト append）を注記する
- 読み側（worklog-extract）に、先頭 BOM の除去・CRLF 許容などの防御的読み取りを持たせるか検討する

いずれも実装は 1〜数行級の追記。scope は worklog パイプライン固有（対象システム）のため system。

## 検討状況

（未着手）

## 結論

ADR-0054 で対処。ストアファイルを UTF-8/BOM なし/LF 固定の契約とし、書き側手段（PowerShell utf8NoBOM / POSIX >>）を注記、読み側 worklog-extract に走査直前の loud validation を追加した（silent tolerance は不採用）。
