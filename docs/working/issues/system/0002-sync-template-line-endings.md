# Issue-0002: sync-template.ps1 の改行コード非決定性

- **Status**: closed
- **Opened**: 2026-07-05
- **Closed**: 2026-07-05
- **起票元**: retrospectives/system/2026-07-05-project-folder-structure.md 課題#2
- **関連**: ADR-0027

## 課題内容

sync-template.ps1 が WriteAllLines で CRLF 書き出しを行い、LF 正規化されたコミット内容と食い違うため、実行のたびに template/ 配下が変更扱いになる（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

2026-07-05: 記録プロセス規範対策サイクル（feature/record-process-norms）の template 同期でも改行のみ差分が再発（template/docs/records/retrospectives/README.md と template/docs/working/issues/README.md）、git restore で回避

2026-07-05: 対策サイクル（feature/sync-template-line-endings）で調査。index 側は LF のみ・生成後のワークツリーは CRLF・clean フィルタ後の内容は一致（差分ゼロの「見かけの modified」）であることをバイトレベルで確認

## 結論

ADR-0033 のとおり、空インデックス生成の書き出しを LF 固定（`WriteAllText` + 行を LF 連結 + 末尾改行）に変更して解消。旧実装での再現（3ファイル modified・CRLF 混入）と修正版でのクリーン維持（pwsh 7 / Windows PowerShell 5.1 の双方、再実行含む）を検証済み。
