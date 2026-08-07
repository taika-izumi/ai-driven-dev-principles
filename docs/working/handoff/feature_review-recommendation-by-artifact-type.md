# Handoff: 確定前レビューの次手提示への成果物性質の反映（Issue-0062）

- **Branch**: feature/review-recommendation-by-artifact-type
- **Last Updated**: 2026-08-07 13:50 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: 完了（master へ merge `afed223`・retrospective 実施済み）

## 作業の目的・背景

Issue-0062 の対策サイクル。ADR-0072 は確定前レビュー（`pre-finalization-review`）を writing-plans / feature-block-design 完了後に「毎回提示する」ことだけを定め、成果物の性質による推奨の強弱を定めていない。そのため AI は一般論から非推奨側へ倒しがちで、前サイクルではユーザー指示によるレビューが Critical 3 件・Major 8 件を検出し spec 全面改訂に至った（見落とされていた構造: ルール・規範・文書型の成果物にはコードの「最初の実行」に相当する安全網が無い）。

本サイクルでは、ADR-0072 の骨格（発動はユーザー指示のみ・AI は提示にとどめる）を維持したまま、提示の仕方に成果物の性質を反映する対処を設計・実装する。

## 関連ドキュメント

- 課題: `docs/working/issues/flow/0062-review-recommendation-ignores-artifact-safety-net.md`
- 一次資料（欠陥クラス 3 種と実例）: `docs/records/retrospectives/flow/2026-08-07-overfitting-check-for-extensions.md` 課題#1
- 対策先: ADR-0072 / `skills/pre-finalization-review/SKILL.md` / `skills/start-work/SKILL.md`（Phase 2 の提示規範）
- 設計制約: ADR-0032（判定条件は観測可能な事実で）/ ADR-0079（過剰適合点検を本対策自身に適用）

## 完了済みタスク

- [x] extend-guidelines → brainstorming で対処設計・設計承認（2026-08-07）
- [x] ADR-0080 ドラフト起票・コミット `437083e`（Proposed 据え置き。実装完了後に Accepted 昇格）（2026-08-07）
- [x] 過剰適合点検を設計承認前に実施（点検ブロックは ADR-0080 末尾）（2026-08-07）
- [x] 確定前レビュー（`pre-finalization-review`・3 観点フル・レビュアーは claude-opus-5）実施。Critical 5 / Major 18 / Minor 16 を検出（2026-08-07）
- [x] レビュー指摘を反映し ADR-0080 を改訂・コミット `75bc098`（軽量レビュー枝を撤回。Proposed 維持）（2026-08-07）
- [x] 実装計画を作成・コミット `e74207e`（8 タスク）（2026-08-07）
- [x] plan 確定点のレビュー 2 本を実施し指摘を反映・コミット `4b5e35c`（ADR-0080 に Decision 3-2 を追加。全 8 タスクの検証を検出力のある形へ書き換え）（2026-08-07）
- [x] Task 1〜8 を subagent-driven-development で実装（各タスク: 実装者 → spec 準拠＋品質レビュー → 指摘反映）。5 スキル＋README＋ADR 3 件＋issue 3 件を変更（2026-08-07）
- [x] タスク単位レビューの指摘 13 件を反映（`5be7aa0` / `29a5088` / `9d4f27b` / `db1c14d`）（2026-08-07）
- [x] ADR-0080 を Accepted へ昇格 `d046a37`（粒度点検で 6 決定すべてがタイトルの問いに収まると判定）。Issue-0062 を close・Issue-0006 に対象外判定の根拠を追記 `913f1ca`（2026-08-07）
- [x] 実装全体の最終レビュー（3 シナリオの机上実行・6 文書 15 組の突合・既存規範 38 項目との照合）→ Major 4・Minor 7 を反映 `e5475e2`（2026-08-07）
- [x] `scripts/sync-template.ps1` を実行し template 配下に差分が出ないことを確認（CLAUDE.md 11345 bytes / 38 bullets で閾値内）（2026-08-07）

## 進行中のタスク

（なし。master へ merge `afed223` 済み）

## 未着手のタスク

（なし。以降のバックログは `docs/working/handoff/master.md` と `docs/working/issues/README.md` を参照）

## 既知のブロッカー・懸念

- 一次資料の欠陥クラス 3 種は単一サイクル・単一成果物種別（ルール文書）由来。クラス列挙をそのまま拘束的規範へ昇格させない（Issue-0062 留意・ADR-0079 観点 1）
- スキルを改定したら同セッションで使う前に `/plugin marketplace update` をユーザーへ依頼（Issue-0044）
- inbox 残置 3 件＋ conversation_log.md はユーザー手動移動予定。organize-inbox 提案不要。`git add` で巻き込まない（Issue-0020）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。
形式: `- <日付> <マイルストーン>: ADR=<番号 or なし（理由）> / worklog=<エントリ id or 棄却（理由）> / review=<フル実施（レビュアーのモデル） or 差分再確認 or 見送り or 非発火（推奨判定が偽）>`（`review=` は確定点を通過したマイルストーンのみ）

- 2026-08-07 brainstorming 完了・spec 確定点 (c)（設計承認・ADR 起票 `437083e`）: ADR=0080（Proposed） / worklog=`MakeAiInstructions-2026-08-07-07` / review=フル実施（claude-opus-5・3 観点。Critical 5/Major 18/Minor 16 を検出し `75bc098` で反映。軽量レビュー枝を撤回）
- 2026-08-07 pre-finalization-review 完了（ADR-0080 改訂 `75bc098`）: ADR=0080 改訂（Proposed 維持・軽量枝撤回） / worklog=`MakeAiInstructions-2026-08-07-08` / review=差分再確認（前行のレビュー指摘の反映差分のみのため見送り。ユーザー判断）
- 2026-08-07 writing-plans 完了・plan 確定点（plan 確定 `e74207e` → レビュー反映 `4b5e35c`）: ADR=0080 に Decision 3-2「反対材料の併記」を追加（Proposed 維持） / worklog=`MakeAiInstructions-2026-08-07-09`（反対材料の併記）・`MakeAiInstructions-2026-08-07-10`（検証の検出力） / review=フル実施（claude-fable-5＝新条項の単独レビュー・条件付き可・Major 2/Minor 1、claude-opus-5＝検証設計の検出力を写経実行で検査・Critical 2/Major 5/Minor 3。全件反映済み）
- 2026-08-07 実装完了（Task 1〜8・最終レビュー反映 `e5475e2`）: ADR=0080 を Accepted へ昇格 `d046a37`（新規 ADR なし。実装中の判断はすべて ADR-0080 の実装詳細） / worklog=`MakeAiInstructions-2026-08-07-11` / review=フル実施（claude-opus-5・実装全体に対する最終レビュー。Major 4/Minor 7 を検出し全件反映）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、Issue-0062、一次資料（上記）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点:
   - ADR-0072 の骨格は維持。判定条件は観測可能な事実で書く（ADR-0032）
   - 実装は 4 スキル＋README＋ADR 2 件の追記に及ぶ。変更対象の全量は ADR-0080 Decision 末尾の「変更対象」を参照
   - **規範の根拠に issue / worklog を引くときは、症状名の一致ではなく実文の機構まで確認する**（本サイクルで軽量枝の根拠が崩壊した。worklog `MakeAiInstructions-2026-08-07-08`）
   - スキル改定後、同セッションで使う前に `/plugin marketplace update` をユーザーへ依頼（Issue-0044）

## 重要な意思決定の履歴

- ADR-0080: 確定前レビューは spec/plan 確定点で提示し、未レビューの規範内容を含む成果物では推奨側に倒す（2026-08-07・Proposed）
