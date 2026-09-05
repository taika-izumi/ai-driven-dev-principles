# Issue-0107: 反復レビューの推奨規範が状況要素を無視して推奨を決める（推奨と実選択の乖離記録）

- **Status**: open
- **Opened**: 2026-08-25
- **起票元**: feature/codex-support サイクルの確定前レビュー反復（spec 確定点 (b)・2026-08-25）でのユーザー観察
- **関連**: ADR-0107（反復推奨の現行規範）、Issue-0103（コスト・巡数の予算基準）、Issue-0098（closed・反復の発動基準）

## 課題内容

確定前レビューの反復規範（pre-finalization-review「指摘反映後の反復」の 2 段型・前置 1・前置 2）は、改訂の「型」と機械的な計数だけで推奨の向きを決めるため、その時々の状況に照らすと不適切な推奨を出すことがある（例: 縮小すべきでない機構まで設計縮小の推奨側に載る）。

feature/codex-support サイクルでは、ユーザーが計 4 度「規範に基づく推奨を置いて、状況を分析するとどうすべきか」と AI へ求め、いずれも規範既定と異なる選択が妥当という結論に至り、その選択が実際に機能した。5 例目以降は AI 側が求められる前に「規範既定」と「AI 自身の判断」を分けて提示するようになった。この乖離事例を記録し、将来の反復レビュー規範の改善（推奨判定への状況要素の取り込み）の参考情報とする。

LoopForAlpha でも同様の記録が LoopForAlpha#Issue-0109 に蓄積されており、将来こちらへ移譲される予定（情報量の増加が見込まれるため、本課題は起票時からフォルダ昇格形態とする）。

## 現在地の要約

2026-09-05: Issue-0124と同時対策中。設計レビューを終え、計画レビューの指摘2件を反映。ユーザー判断で追加レビューなしに計画を確定し、セッション中断。実装は次セッションからタスク1へ進む。ADR-0124・0125はProposed、課題は実装検証までopen。

## 関連資料

- `docs/working/plans/2026-09-05-review-judgment-and-cost-evaluation.md` — 確定した実装計画と追加レビューなしでの確定判断
- [0107-2026-09-05-plan-review-r1.md](0107-2026-09-05-plan-review-r1.md) — 実装計画の4観点レビュー第1回、指摘2件と修正内容
- [0107-2026-09-05-spec-review-r2.md](0107-2026-09-05-spec-review-r2.md) — 新規1体の差分再確認、モデル選定理由と4件全件OKの結果
- [0107-2026-09-05-spec-review-r1.md](0107-2026-09-05-spec-review-r1.md) — ADR-0124・0125の設計レビュー第1回、指摘4件と採否案・反映内容
- [0107-log.md](0107-log.md) — 乖離事例の時系列一次記録（事例・規範側の推奨とその由来・実選択・理由・結果）
- [lfa-0109-iterative-review-recommendation-norms-ignore-situational-evidence.md](lfa-0109-iterative-review-recommendation-norms-ignore-situational-evidence.md) — 移譲元 LoopForAlpha#Issue-0109 の課題本体（全文コピー。原因仮説・対策候補 6 案）
- [lfa-0109-note-divergence-cases.md](lfa-0109-note-divergence-cases.md) — 移譲元の乖離事例ノート（全文コピー。事例 8 件＋横断観測 2 組の判断材料つき詳細）
- [lfa-0109-log.md](lfa-0109-log.md) — 移譲元の検討経緯ログ（全文コピー）

## 結論

（open）
