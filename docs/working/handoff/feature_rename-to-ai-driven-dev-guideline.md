# Handoff: 体系呼称の改名（メタ・ガイドライン → AI駆動開発ガイドライン）

- **Branch**: feature/rename-to-ai-driven-dev-guideline
- **Last Updated**: 2026-08-06 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ガイドライン改定/名称決定済み（ADR-0078 起票済み）・実装未着手

## 作業の目的・背景

体系の呼称「メタ・ガイドライン」は初見の読者に意味が伝わらないというユーザーの問題提起を受け、名称を **「AI駆動開発ガイドライン」** に改めることを決定した（ADR-0078・Proposed。候補比較と誤読リスク評価の経緯は ADR 参照）。初出箇所には一行定義（「AIエージェントと協働して開発を進めるための原則・行動指示・スキルの体系」等）を添える。

決定は 2026-08-06 のセッションで確定済み。**実装（書き換え作業）は本ブランチで次セッションから着手する**（ユーザー判断で延期）。

## 関連ドキュメント

- 決定: ADR-0078（`docs/records/decisions/0078-rename-meta-guidelines-to-ai-driven-dev-guidelines.md`）
- 命名規律: ADR-0022 / `docs/current/specs/2026-06-15-naming-clarity-discipline-design.md`
- 記録の書き換え禁止規約: ADR-0011（追記型）

## 完了済みタスク

- [x] 名称の決定と ADR-0078 起票（Proposed）、出現調査: 「メタ・ガイドライン」94 箇所・46 ファイル（2026-08-06）

## 進行中のタスク

（なし。実装は未着手）

## 未着手のタスク

- [ ] 書き換え対象の確定と実装計画（`superpowers:writing-plans` 直行を推奨。名称は決定済みのため brainstorming 不要の小規模改定）
  - 書き換える: README / CLAUDE.md / `docs/overview/principles.md` / CONTRIBUTING / `skills/*` 本文 / `template/` 配下 / `.claude-plugin/plugin.json` `marketplace.json` の説明文
  - 書き換えない: `docs/records/decisions/` / `docs/records/retrospectives/` / 完了済み `docs/working/plans/` / 過去 handoff（ADR-0011 の追記型規約）
  - 判断が要る: `docs/current/specs/` 内の旧名称（過去サイクルの設計記録としての性格が強い。扱いを plan 時に決める）
- [ ] 初出箇所への一行定義の追加（README / CLAUDE.md）
- [ ] `scripts/sync-template.ps1` 実行（CLAUDE.md / principles.md が template 対象）と read-back 確認
- [ ] 検証（grep で規範文書に旧名称が残っていないこと）・ADR-0078 Accepted 昇格・master マージ・retrospective

## 既知のブロッカー・懸念

- inbox 残置 3 件＋ `docs/conversation_log.md` はユーザーが手動移動予定（untracked のまま。コミットに巻き込まないこと）
- プラグイン説明文（plugin.json / marketplace.json）の変更はプラグイン update の再実行が必要になる可能性（ADR-0055）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-06 名称決定・ADR-0078 起票（サイクル準備）: ADR=0078（Proposed・コミット済み） / worklog=`MakeAiInstructions-2026-08-06-04`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、ADR-0078
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:writing-plans`（brainstorming は不要。名称・方針は決定済み）
3. 留意点: 追記型の記録（ADR / retrospective / 完了 plan / 過去 handoff）は書き換えない。specs の扱いだけ plan 時にユーザーと確定する。旧名称の全出現は 94 箇所・46 ファイル（2026-08-06 実測。plan 時に再取得すること）

## 重要な意思決定の履歴

- ADR-0078: 体系の呼称を「メタ・ガイドライン」から「AI駆動開発ガイドライン」へ改める（2026-08-06・Proposed）
