# Issue-0002: sync-template.ps1 の改行コード非決定性

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/system/2026-07-05-project-folder-structure.md 課題#2
- **関連**: ADR-0027

## 課題内容

sync-template.ps1 が WriteAllLines で CRLF 書き出しを行い、LF 正規化されたコミット内容と食い違うため、実行のたびに template/ 配下が変更扱いになる（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

2026-07-05: 記録プロセス規範対策サイクル（feature/record-process-norms）の template 同期でも改行のみ差分が再発（template/docs/records/retrospectives/README.md と template/docs/working/issues/README.md）、git restore で回避

## 結論

（open）
