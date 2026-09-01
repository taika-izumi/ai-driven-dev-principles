# Issue-0111: merge-practice.md 冒頭の導入文が移設条文の書き出しと重複している

- **Status**: closed
- **Opened**: 2026-08-29
- **Closed**: 2026-09-01
- **起票元**: `retrospectives/system/2026-08-29-start-work-responsibility-split.md` 課題#1
- **関連**: ADR-0116（責務帰属による移設）、`skills/start-work/references/merge-practice.md`

## 課題内容

`skills/start-work/references/merge-practice.md` の導入文（L3「feature ブランチを既定ブランチへ取り込む完了処理の実行直前に適用する慣行判定の手順。…」）と、無改変移設した元条文の書き出し（L5「feature ブランチを既定ブランチへ取り込む完了処理の実行直前に、以下の慣行判定を行い、…」）が同じ内容を二度述べており、そのまま配布されている（dist 側にも伝播。実装時レビュー Minor 4）。plan 作成時に導入文と元条文冒頭の重複突合をしなかったことが原因で、実装は plan 指定どおり。機能影響はない。修正は導入文を発火点の説明（「`start-work` の完了処理の発火点から読まれる」）へ絞り込む方向で、条文本体に触れず無改変移設の検証状態を保てる。

## 検討状況

- 2026-08-29: 起票。対策の着手はユーザー判断（軽微修正。配布対象ソースのため執行点 4 手順・version bump の対象）
- 2026-09-01: ADR-0121 のサイクルへ同梱して修正（導入文を発火点の説明へ絞り込み、移設条文本体は無改変。執行点 4 手順と version bump 0.1.17 を共有）

## 結論

ADR-0121 のサイクルで同梱修正。
