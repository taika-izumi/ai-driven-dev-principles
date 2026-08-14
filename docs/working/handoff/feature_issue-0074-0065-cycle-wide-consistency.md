# Handoff: Issue-0074/0065 サイクル全体整合検査の設計

- **Branch**: feature/issue-0074-0065-cycle-wide-consistency
- **Last Updated**: 2026-08-15 05:32 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装完了・ADR-0092 Accepted 済み → master へのマージ判断待ち

## 作業の目的・背景

Issue-0074（決定を Accepted へ昇格させる前に仕様が実装のスナップショットかを検査する工程がない）と Issue-0065（タスク単位のレビューでは複数文書にまたがる規範の経路が閉じているかを検出できない）を同時に扱い、対策を一度で設計する。両者は「タスク単位の検査では累積のずれ・経路の閉じを検出できない」という同じ根を持つ（Issue-0074 起票時に統合設計の余地が明記済み）。

実害の材料: Issue-0065 側は最終レビューが Major 4 件を検出（うち 2 件は ADR-0080 中核経路の空転）、Issue-0074 側は Accepted 化直後の全体レビューで仕様追従漏れ 3 件。

## 関連ドキュメント

- Plan: `docs/working/plans/2026-08-14-adr-0092-cycle-wide-consistency-check.md`（全 8 タスク。確定前レビュー反映済み）
- Issue: `docs/working/issues/flow/0074-spec-snapshot-check-missing-before-adr-promotion.md` / `docs/working/issues/flow/0065-task-scoped-review-misses-cross-document-paths.md`
- 一次資料（対処設計前に必読と指定）: `docs/records/retrospectives/flow/2026-08-07-review-presentation-by-artifact-type.md` 課題#1 / `docs/records/retrospectives/flow/2026-08-08-distributed-artifact-generation.md` 課題#2
- 関連 ADR: ADR-0092（本サイクルの設計文書を兼ねる。Proposed・コミット `2ae6712`）、ADR-0019（承認の遅延昇格）、ADR-0079（過剰適合点検。設計時に適用必須）、ADR-0080（確定前レビュー提示規則）、ADR-0032（判定条件は観測可能な事実で）
- 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] brainstorming（要件確定: AI 自身の必須検査・文書編集サイクルにゲート／設置場所 3 案比較→decision-log 昇格手順へ）（2026-08-14 完了）
- [x] ADR-0092 ドラフト作成・確定前レビューフル 3 観点（claude-opus-5）・指摘反映・設計承認・コミット `2ae6712`（2026-08-14 完了）

## 進行中のタスク

- [ ] **現在の作業**: master へのマージと後続（retrospective・finalize）
  - 状態: plan 全 8 タスク完了（実装 `954eabf`・昇格 `668c26f`）。検査の初回自己適用は指摘なし
  - 残り: master へ --no-ff マージ → retrospective → cycle-reset → finalize → push → ユーザーによる `/plugin marketplace update` で 0.1.3 反映

## 未着手のタスク

（なし。マージ以降は上記「進行中のタスク」の残りのとおり）

## 既知のブロッカー・懸念

- `superpowers:subagent-driven-development` は本リポジトリの編集対象外（ADR-0069 と同じ制約）。対処は本 repo 側スキル（start-work Post ラッパー、pre-finalization-review、decision-log 等）か subagent-dispatch に置く（Issue-0065 留意）
- Issue-0065 の知見は規範文書サイクル由来。コード実装サイクルで同じ死角が生じるかは未検証（ADR-0079 観点 1「出所の偏り」を設計時に適用）
- 発火条件をイベントで書くと経路依存になる型に注意（worklog `MakeAiInstructions-2026-08-07-11`）
- 配布対象ソース変更時はコミット前に執行点 4 手順＋version bump（CONTRIBUTING.md / ADR-0090）
- inbox 残置 3 件＋ conversation_log.md はユーザー手動移動予定。`git add` で巻き込まないこと（Issue-0020）

## Post ラッパー消化記録

- 2026-08-14 設計確定・spec 確定点 (c) 通過（ADR-0092 コミット `2ae6712`）: ADR=0092 / worklog=棄却（レビュー指摘は ADR-0092 正本へ反映済み・新規 delta なし） / review=フル実施（claude-opus-5）
- 2026-08-15 実装計画確定・plan 確定点 通過: ADR=なし（設計は 0092 で確定済み。計画は写像） / worklog=棄却（アンカー不一致 1 件は即時回収・指摘は plan/ADR 正本へ反映済み） / review=フル実施（claude-opus-5）
- 2026-08-15 実装完了（plan Task 1〜8）・ADR-0092 Accepted 昇格・Issue-0074/0065 close: ADR=0092（昇格。新規決定なし） / worklog=`MakeAiInstructions-2026-08-15-01`（フェンス内 R4 の躓き） / cyclecheck=実施（指摘なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff、両 Issue、一次資料 2 件
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: 上記「既知のブロッカー・懸念」参照

## 重要な意思決定の履歴

- ADR-0092: 仕様・規範文書を編集したサイクルでは Accepted 昇格前に AI 自身のサイクル全体整合検査を必須とする（2026-08-14。Accepted `668c26f`。Issue-0074/0065 を close）
