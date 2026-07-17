# Issue-0029: worklog エントリスキーマの細部改善（corrections の誤答側・friction 型非対称・損失規模）

- **Status**: open
- **Opened**: 2026-07-17
- **起票元**: 2026-07-17 セッションでのエントリフォーマットレビュー（設計意図ドキュメント `docs/inbox/2026-07-17-worklog-entry-format-rationale.md` 作成後の対話レビュー指摘 #5〜#7。同一のスキーマ改訂パスで一括判断できる細部のため 1 件に束ねて起票）
- **関連**: `skills/worklog-record/references/store-format.md`、ADR-0045、`docs/working/skill1-entry-schema-strawman.md`

## 課題内容

エントリスキーマの細部に関する 3 点。いずれも単独では軽微だが、スキーマ改訂の機会があれば一括で検討する:

1. **corrections は「正解側」しか残らない**: friction は AI の失敗という「誤答側」を含むが、corrections は人間の指示（正解側）のみで「指示がなければ AI が何をしようとしていたか」が残らない。スキル化時の「〜するな、〜せよ」という対比構造の前半（するな側）の素材が欠落する。対処候補: context に AI の当初挙動を書く運用ガイドの明文化、または任意フィールドの追加
2. **friction（string）と corrections（string[]）の型非対称**: 1 作業に複数の躓きがあった場合、friction は文字列連結するしかない。統一するなら friction も string[] へ（スキーマ変更を伴うため Issue-0026 のバージョン管理と関連）
3. **抽出ランキングの「delta 重み」の判断材料が薄い**: worklog-extract のクラスタ評価は再発回数・出所プロジェクト数・delta の重みを使うが、損失規模（この躓きで何分ロスしたか等）の記録がなく優先順位付けの材料が限られる。任意フィールド追加は記録コストとのトレードオフのため要検討

## 検討状況

（未着手）

## 結論

（open）
