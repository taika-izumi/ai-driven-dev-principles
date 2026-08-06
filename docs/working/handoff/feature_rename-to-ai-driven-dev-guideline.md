# Handoff: 体系呼称の改名（メタ・ガイドライン → AI駆動開発ガイドライン）

- **Branch**: feature/rename-to-ai-driven-dev-guideline
- **Last Updated**: 2026-08-07 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン改定/実装・検証完了（ADR-0078 Accepted）・マージ前の最終レビュー中

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

- [x] 実装計画 Task 1〜9 の全実行（2026-08-07 完了。`superpowers:subagent-driven-development` でタスクごとにサブエージェント委譲＋仕様適合／品質レビュー）
  - コミット: `f9767e2`(README) / `3155b6a`(CLAUDE.md) / `4f830d2`(CONTRIBUTING) / `70fddf1`(principles・skills) / `17aa0c6`(プラグインメタデータ) / `7ffcdab`(specs 18 箇所) / `6836617`(specs 表記揺れ修正) / `94c9ef6`(template 同期) / `219b4bd`(ADR-0078 Accepted 昇格)
  - 検証結果: 書き換え対象スコープ 65 ファイルで旧名称 0 件（日本語・英語とも）、重複表現 0 件、表記揺れ 0 件、新名称 39 件（元の日本語 37 箇所＋一行定義 2 件）
- [x] ADR-0078 を Accepted へ昇格（`219b4bd`）

## 進行中のタスク

- [ ] **現在の作業**: マージ前の最終レビューと master へのマージ
  - 状態: 実装・検証は完了。全体最終レビューを実施中
  - 残り: 最終レビューの指摘対処 → `superpowers:finishing-a-development-branch` で master へマージ → `retrospective`

## 未着手のタスク

- [ ] master マージ時に `docs/working/handoff/master.md` の背景説明にある旧名称 1 箇所を更新する
- [ ] master マージ後の `retrospective` 起動

## 既知のブロッカー・懸念

- inbox 残置 3 件＋ `docs/conversation_log.md` はユーザーが手動移動予定（untracked のまま。コミットに巻き込まないこと）
- プラグイン説明文（plugin.json / marketplace.json）の変更はプラグイン update の再実行が必要になる可能性（ADR-0055）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-06 名称決定・ADR-0078 起票（サイクル準備）: ADR=0078（Proposed・コミット済み） / worklog=`MakeAiInstructions-2026-08-06-04`
- 2026-08-06 `superpowers:writing-plans` 完了（実装計画の確定）: ADR=0078（specs の扱いと英語表記の対象化を Consequences へ追記。Proposed 据え置き・未コミット） / worklog=`MakeAiInstructions-2026-08-06-05`
- 2026-08-07 サブエージェント委譲中の異常検知（実装報告のコミットハッシュが実在しない値だった）: ADR=なし（既存規範 ADR-0038 の読み直しで検出・対処。新たな決定なし） / worklog=`MakeAiInstructions-2026-08-07-01`
- 2026-08-07 実装計画 Task 1〜9 の全完了（`219b4bd`）: ADR=0078（Proposed → Accepted へ昇格。ADR-0019 の実装完了チェックポイント） / worklog=`MakeAiInstructions-2026-08-07-02`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、実装計画 `docs/working/plans/2026-08-06-rename-to-ai-driven-dev-guideline-plan.md`、ADR-0078
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:finishing-a-development-branch` で master へマージ → `retrospective`
3. 留意点:
   - **実装は完了済み**。残るのはマージと振り返りのみ
   - マージ時に `docs/working/handoff/master.md` の背景説明にある旧名称 1 箇所を新名称へ更新する（master 側の生きた文書のため）
   - コミットはパス指定で行う（`docs/inbox/` の untracked 3 件と `docs/conversation_log.md` を巻き込まないこと。Issue-0020）
   - マージ後、プラグイン説明文の変更を反映するにはユーザーによる `/plugin marketplace update ai-driven-dev-principles` の実行が必要になる可能性がある（ADR-0055。AI からは実行不可）
   - 検証コマンドを書くときの落とし穴 2 件を worklog `MakeAiInstructions-2026-08-07-02` に記録済み（`Select-String` に `-Recurse` は無い / ファイル名に `-Recurse` を付けるとフィルタ解釈で同名ファイルを巻き込む）

## 重要な意思決定の履歴

- ADR-0078: 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める（2026-08-06 起票・2026-08-07 Accepted）
