# Handoff: Issue-0084 マージ方式規範（--no-ff）の完了フロー配線

- **Branch**: feature/issue-0084-wire-no-ff-merge
- **Last Updated**: 2026-08-18 02:10 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: ガイドライン拡張/plan 確定済み（設計 ADR-0106 `44ec363`・写像チェック済み）。次は実装（実行方式の選択から）

## 作業の目的・背景

Issue-0084 の対策サイクル。retrospective スキルは「feature ブランチを master へ `--no-ff` マージした直後の実施」を前提とするが、マージを実行する完了フロー（`superpowers:finishing-a-development-branch`）にこの規範が配線されておらず、手動適用 7 サイクルの後、8 サイクル目（Issue-0093/0094）で fast-forward マージが再発した（push 前に `be8d6bd` でやり直し）。手動適用の連鎖は担い手のコンテキスト依存と実証されたため、規範を完了フローへ恒久配線する対策を設計・実装する。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md`
- 起票元: `docs/records/retrospectives/flow/2026-08-14-handoff-bloat-control.md` 課題#1
- 関連スキル: `skills/retrospective/SKILL.md`「いつ使うか」、`superpowers:finishing-a-development-branch`（外部プラグイン・直接改変不可）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検 ADR-0079/0099・評価可能性 ADR-0102・配布の執行点）

## 完了済みタスク

- [x] 対策の設計・ADR-0106 起票（Proposed・`44ec363`。設計文書兼用型。2026-08-17 完了）
- [x] 確定前レビュー: 3 観点フル 5 巡＋差分再確認 1 巡（レビュアー claude-opus-5。最終巡 24/24 解消・新矛盾 0）

## 進行中のタスク

- [ ] **現在の作業**: plan の実装（`docs/working/plans/2026-08-17-adr-0106-merge-mode-wiring-plan.md`・全 10 タスク）
  - 状態: plan 確定済み（写像チェック 30 要件・欠落 0。指摘 3＋所見 2 を反映済み）。実行方式の選択待ち
  - 残り: Task 1〜10（skills 2 件＋template 改定・spec 同期・記録更新・git config・version bump・配布 4 手順・スモーク 11 状態）

## 未着手のタスク

- [ ] 実装・配布（`scripts/build-dist.ps1`・version bump 0.1.8→0.1.9・配布物目視・スモーク検証）
- [ ] Issue-0084 の faa9187 記載漏れ補正・start-work 旧 spec 乖離の flow 課題起票（ADR-0106 Consequences）
- [ ] ADR-0106 Accepted 昇格・Issue-0084 close → マージ・retrospective・cycle-reset

## 既知のブロッカー・懸念

- `superpowers:finishing-a-development-branch` は外部プラグインのスキルであり直接改変できない。配線先の設計はこの制約が中心論点
- 配布対象ソースを変更したら執行点 4 手順（`CONTRIBUTING.md`）。スキル改定は version bump 必須（ADR-0090。現行 0.1.8）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。

- 2026-08-17 ADR-0106 設計確定・spec 確定点 (c) 通過: ADR=0106 / worklog=`MakeAiInstructions-2026-08-17-07` / review=フル実施（claude-opus-5。3 観点×5 巡＋差分再確認 1 巡）
- 2026-08-17 実装 plan 作成・plan 確定点 通過: ADR=なし（ADR-0106 への追従のみで新規決定なし） / worklog=棄却（写像脱落 3 件は独立レビューの想定内で delta なし） / review=差分再確認（写像チェック 1 観点・claude-opus-5。推奨判定は偽・30 要件中欠落 0）
- 2026-08-17 セッション終了（実装着手前に区切り）: ADR=なし（新規決定なし） / worklog=棄却（plan 確定点以降はレビュー指摘反映のみで delta なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: `docs/working/plans/2026-08-17-adr-0106-merge-mode-wiring-plan.md`（確定済み・全 10 タスク）と設計の正本 ADR-0106
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ 実行方式（subagent-driven / inline）をユーザーに確認して実装開始。plan と ADR-0106 以外の経緯（レビュー 6 巡の詳細）は読み込み不要
3. 留意点: Task 1〜3 の skills 編集は dist・version と同一コミット（plan Task 10）。plan の old_string は編集前に実ファイルとの一致を必ず確認。完了後は ADR-0106 Accepted 昇格（サイクル全体整合検査つき）・Issue-0084 close → マージは新配線どおり `--no-ff`

## 重要な意思決定の履歴

- ADR-0106: マージコミット規範の再発防止＝予防・検出 2 層配線＋git 設定＋ff やり直し（2026-08-17 Proposed・`44ec363`）
