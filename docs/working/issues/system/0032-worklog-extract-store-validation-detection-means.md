# Issue-0032: worklog-extract のストア健全性検証の具体的検出手段が未定義

- **Status**: open
- **Opened**: 2026-07-18
- **起票元**: worklog 実運用堅牢化サイクルの簡易 retrospective（2026-07-18）課題B
- **関連**: ADR-0054（読み側 loud validation）、`skills/worklog-extract/SKILL.md`（走査直前の健全性検証ステップ）、`skills/worklog-record/references/store-format.md`（エンコーディング契約）

## 課題内容

ADR-0054 と spec で「`worklog-extract` は走査直前に BOM・CRLF・非 UTF-8 を検出し、あれば報告して停止する」と規範化したが、**具体的な検出手段（例コマンド）を示していない**。extract を実行するエージェントが毎回検出方法を都度判断するため、再現性・網羅性にばらつきが出うる。

ADR-0032 の観測可能性（検出はストアファイルのバイトを読めば可能）自体は満たすが、可搬な例コマンドがないと検証品質が実行者依存になる。とくに以下の固有性を検出ロジックに反映する必要がある:

- 追記専用ゆえ BOM は**ファイル頭ではなく追記チャンク先頭（中途）に混入**しうる。「頭 BOM 除去」だけでは捕捉できない
- 全プラットフォーム共有のため、検出手段は POSIX / PowerShell 双方で可搬であることが望ましい

## 対処候補

- `worklog-extract` SKILL.md または `store-format.md` に、可搬な検出手段の例を注記する（例: `grep -lP '\xEF\xBB\xBF|\r' <files>` で BOM/CRLF を検出、非 UTF-8 は iconv / PowerShell での妥当性チェック）
- 中途 BOM も捕捉できる検出（行頭だけでなく全バイト走査）を明示する
- 正規化（opt-in）の具体手段（BOM 除去・CRLF→LF、内容不変）も併せて例示するか検討する
- 次に `worklog-extract` を実装・実運用する時に一括で具体化するのが効率的（小規模）

## 検討状況

- 2026-07-31: 再発（2例目。ADR-0031）。retrospective 再定義サイクルの worklog 追記後の健全性検証で、`od -c MakeAiInstructions/log.jsonl | grep -c '\r'` が **147 件という誤検出**を返した（実際は CR 0 件）。Python でバイトを直接カウント（`open(p,'rb').read().count(b'\r')`）したところ CR 0 / BOM なし / UTF-8 妥当と確定。前サイクル（2026-07-18）の `grep -P` ロケールエラーによる誤「clean」報告に続き、**grep 系の検出は環境依存で誤判定する**という同型の事象。対処候補の「例コマンド」は grep ベースを避け、バイトを直接数える手段（Python / PowerShell の `[System.IO.File]::ReadAllBytes`）を第一候補として例示すべき

## 結論

（open）
