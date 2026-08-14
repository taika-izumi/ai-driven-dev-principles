# Issue-0083: session-handoff スキル文書にレビュー残の解釈揺れ箇所 5 点が残っている

- **Status**: open
- **Opened**: 2026-08-14
- **起票元**: retrospectives/system/2026-08-14-handoff-bloat-control.md 課題#1
- **関連**: ADR-0086 / ADR-0087 / ADR-0088、`skills/session-handoff/SKILL.md`、Issue-0079〜0081（closed。本課題は同対策の実装で残った品質改善候補）

## 課題内容

handoff 肥大化制御サイクルの実装品質レビュー（全文走査）が検出した、配布は妨げないが単体で読んだときに解釈の揺れを生みうる箇所 5 点（参照箇所列挙の網羅性・「必須工程」の強度差・finalize 手順 3 の前方参照・対応表の標準パス併記漏れ・`spec 確定点 (a)(b)(c)` の単体未定義）。詳細は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-14: 起票。いずれも 1 句〜 1 行の追記で解消する見込み。対応時は spec `2026-08-13-handoff-bloat-control/` と ADR-0086/0088 との同期、および執行点 4 手順（dist 再生成）が必要

## 結論

（open）
