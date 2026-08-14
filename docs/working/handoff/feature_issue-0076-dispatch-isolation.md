# Handoff: Issue-0076 対策（破壊的検証委譲の隔離制約）

- **Branch**: feature/issue-0076-dispatch-isolation
- **Last Updated**: 2026-08-15 06:17 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 改修/設計確定（ADR-0093 レビュー反映済み）。次は実装

## 作業の目的・背景

破壊的検証をサブエージェントへ委譲した際に実リポジトリのファイルが 2 度壊れた事故（Issue-0076）への対策。`subagent-dispatch` の B 群へ発火条件「破壊的検証を委譲するとき」を追加し、隔離の作り方の指定・絶対パスの使用・前後状態比較（内容ハッシュ主体）・委譲側の受け取り時独立確認を課す。設計は ADR-0093（設計文書を兼ねる型）で確定し、フル 3 観点レビュー（claude-opus-5）の実証付き指摘を反映済み。

## 関連ドキュメント

- 対策対象課題: `docs/working/issues/flow/0076-dispatch-lacks-isolation-method-constraint.md`
- 設計 ADR: ADR-0093（`docs/records/decisions/0093-destructive-verification-dispatch-isolation-constraints.md`）
- 改定対象: `skills/subagent-dispatch/SKILL.md`（同期対象の全列挙は ADR-0093 Consequences 参照）
- 実測記録: worklog `MakeAiInstructions-2026-08-08-06` / `-09`（事故）、`MakeAiInstructions-2026-08-15-02`（レビューで判明した設計盲点）

## 完了済みタスク

- [x] 構造的解決の調査と対策案比較・方針決定（2026-08-15）
- [x] ADR-0093 ドラフト作成（2026-08-15）
- [x] フル 3 観点レビュー（敵対的・実装整合性・仕様適合、claude-opus-5）と指摘反映の改稿（2026-08-15）

## 進行中のタスク

- [ ] **現在の作業**: ADR-0093 ドラフトのコミット
  - 状態: 改稿完了・レビュー済み。コミット直前
  - 残り: コミット後、実装（`subagent-dispatch` 改定と同期対象の更新）へ進む

## 未着手のタスク

- [ ] `skills/subagent-dispatch/SKILL.md` の改定（B 群 6 条件化・判定行キー追加・手順節へ受け取り時確認・既存並列行へ絶対パス追記）
- [ ] 同期対象の更新: spec `docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md` / `docs/reference/powershell-pitfalls.md` / `skills/pre-finalization-review/SKILL.md` 手順 4
- [ ] 執行点 4 手順（`scripts/build-dist.ps1`・`-Check` 両方・`dist/` 同コミット・目視 5 点）と version bump（ADR-0090）
- [ ] 実装完了後: ADR-0093 Accepted 昇格（サイクル全体整合検査つき）・Issue-0076 close・master へマージ・retrospective

## 既知のブロッカー・懸念

- 前セッションからの継続: inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定（organize-inbox 提案不要。`git add` で巻き込まない。Issue-0020）
- plugin 0.1.3 の配布反映（ユーザーによる `/plugin marketplace update`）が未実施の可能性。本サイクルの改定はさらに bump が必要（ADR-0090）

## Post ラッパー消化記録

- 2026-08-15 ADR-0093 設計確定・spec 確定点 (c) 通過: ADR=0093 / worklog=`MakeAiInstructions-2026-08-15-02` / review=フル実施（claude-opus-5）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフと ADR-0093（Consequences の実装同期対象一覧）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ 実装へ
3. 留意点: 配布対象ソース変更時は執行点 4 手順＋version bump。例示はプレースホルダ（R5）。コミットは pathspec 付き

## 重要な意思決定の履歴

- ADR-0093: 破壊的検証の委譲には、隔離の作り方の指定・絶対パスの使用・前後状態比較・委譲側の独立確認を課す（2026-08-15 Proposed。実装完了後に Accepted 昇格予定）
