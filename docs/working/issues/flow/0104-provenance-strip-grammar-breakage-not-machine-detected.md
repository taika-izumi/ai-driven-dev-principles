# Issue-0104: 識別子除去後の文法破綻（R1-a 型）を機械検出できない

- **Status**: open
- **Opened**: 2026-08-18
- **起票元**: `docs/records/retrospectives/flow/2026-08-18-issue-0098-iterative-review-criteria.md` 課題#1
- **関連**: CONTRIBUTING「執行点」「機械判定が届かない領域」、`scripts/lib/strip-provenance.ps1`、Issue-0070（隣接・対象領域が異なる）

## 課題内容

配布物生成時、識別子（ADR-NNNN 等）が文の文法要素になっている行は、除去後に破綻文（「（の骨格を維持）」「　による」型）として dist へ出力される。機械判定は括弧の内外のみを見るため違反 0 件で通過し、検出は CONTRIBUTING の目視工程のみに依存する（2026-08-18 の実測: 3 件が build を通過し目視で検出・修正）。検出手段の機械化（例: 除去後テキストの破綻パターン検査）の要否・設計は次サイクル以降のユーザー判断。

## 検討状況

- 2026-08-18: 起票。

## 結論

（open）
