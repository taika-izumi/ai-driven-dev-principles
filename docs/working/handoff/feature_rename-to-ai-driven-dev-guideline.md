# Handoff: 体系呼称の改名（メタ・ガイドライン → AI駆動開発ガイドライン）

- **Branch**: feature/rename-to-ai-driven-dev-guideline
- **Last Updated**: 2026-08-06 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン改定/実装計画の作成完了（`superpowers:writing-plans` 完了）・実装未着手

## 作業の目的・背景

体系の呼称「メタ・ガイドライン」は初見の読者に意味が伝わらないというユーザーの問題提起を受け、名称を **「AI駆動開発ガイドライン」** に改めることを決定した（ADR-0078・Proposed。候補比較と誤読リスク評価の経緯は ADR 参照）。初出箇所には一行定義（「AIエージェントと協働して開発を進めるための原則・行動指示・スキルの体系」等）を添える。

決定は 2026-08-06 のセッションで確定済み。同日の後続セッションで書き換え対象を確定し実装計画を作成した。**実装（書き換え作業）は未着手**で、計画の Task 1 から実行する段階にある。

## 関連ドキュメント

- 決定: ADR-0078（`docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md`）
- 実装計画: `docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md`（Task 1〜9・未コミット）
- 命名規律: ADR-0022 / `docs/current/specs/2026-06-15-naming-clarity-discipline-design.md`
- 記録の書き換え禁止規約: ADR-0011（追記型）

## 完了済みタスク

- [x] 名称の決定と ADR-0078 起票（Proposed）、出現調査（2026-08-06）。plan 作成時の再実測では 103 箇所・49 ファイル（うち書き換え対象 37 箇所、追記型の記録として据え置き 66 箇所）
- [x] 表記揺れの網羅確認（2026-08-06 完了）: 日本語の変種（中点なし・半角中黒・スペース区切り等）は 0 件、英語は `Meta-Guidelines` / `meta-guidelines` のみ。詳細は worklog `MakeAiInstructions-2026-08-06-05`
- [x] 書き換え対象の確定と実装計画の作成（2026-08-06 完了）: `docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md`。`docs/current/specs/` は「本文を書き換え・ファイル名は維持」とユーザーが決定し、ADR-0078 の Consequences へ追記済み

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の実行
  - 状態: 計画は Task 1〜9 で確定済み（未コミット）。実装は 1 タスクも未着手
  - 残り: Task 1（README）から順に実行する。実行方式（サブエージェント委譲 / インライン）はユーザー未選択

## 未着手のタスク

- [ ] Task 1〜9 の実行（計画ファイル参照。README / CLAUDE.md / CONTRIBUTING / principles.md / skills 2 件 / プラグインメタデータ / specs 10 件 / template 同期 / 全体検証と ADR-0078 Accepted 昇格）
- [ ] master マージ時に `docs/working/handoff/master.md` の背景説明にある旧名称 1 箇所を更新する
- [ ] master マージ後の `retrospective` 起動

## 既知のブロッカー・懸念

- inbox 残置 3 件＋ `docs/conversation_log.md` はユーザーが手動移動予定（untracked のまま。コミットに巻き込まないこと）
- プラグイン説明文（plugin.json / marketplace.json）の変更はプラグイン update の再実行が必要になる可能性（ADR-0055）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-06 名称決定・ADR-0078 起票（サイクル準備）: ADR=0078（Proposed・コミット済み） / worklog=`MakeAiInstructions-2026-08-06-04`
- 2026-08-06 `superpowers:writing-plans` 完了（実装計画の確定）: ADR=0078（specs の扱いと英語表記の対象化を Consequences へ追記。Proposed 据え置き・未コミット） / worklog=`MakeAiInstructions-2026-08-06-05`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、実装計画 `docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md`、ADR-0078
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:subagent-driven-development` または `superpowers:executing-plans` で計画の Task 1 から実行（実行方式はユーザー選択）
3. 留意点:
   - 追記型の記録（ADR / retrospective / 完了 plan / 過去 handoff / issue）は書き換えない（ADR-0011）
   - `template/` 配下は直接編集せず `scripts/sync-template.ps1` の実行で反映する（計画の Task 8）
   - 素朴な一括置換は禁止。修飾語が重複する 8 箇所は計画に旧新文字列を個別明記してある
   - コミットはパス指定で行う（`docs/inbox/` の untracked 3 件と `docs/conversation_log.md` を巻き込まないこと。Issue-0020）
   - ADR-0078 の Accepted 昇格は計画 Task 9 に含まれる（実装完了・検証後）

## 重要な意思決定の履歴

- ADR-0078: 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める（2026-08-06・Proposed）
