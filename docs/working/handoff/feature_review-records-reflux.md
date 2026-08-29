# Handoff: LoopForAlpha レビュー記録の一括委譲と計画逸脱判断の既定づくり

- **Branch**: feature/review-records-reflux
- **Last Updated**: 2026-08-30 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 第 2 段（委譲材料の精読 → Issue-0110 対策設計）。第 1 段は完了・コミット済み

## 作業の目的・背景

LoopForAlpha プロジェクトに蓄積されたレビュー関連の flow 型 Issue 4 件（LoopForAlpha#Issue-0043 / 0096 / 0109 / 0117。合計約 180KB の実測記録）を本リポジトリへ一括委譲し、受け皿（既存課題への統合か新設か）を設計する。そのうえで委譲した記録を材料に、Issue-0110（確定済み計画からの逸脱判断に既定が無い）の対策設計へ接続する。スコープ決定は ADR-0118（Proposed・未コミット）。

## 関連ドキュメント

- スコープ決定: ADR-0118（`docs/records/decisions/0118-bulk-reflux-of-lfa-review-flow-issues.md`。Proposed・未コミット）
- 本サイクルの主テーマ: Issue-0110（`docs/working/issues/flow/0110-plan-deviation-decision-has-no-default.md`）
- 委譲元（LoopForAlpha リポジトリ `D:\Dev\001_Trade\LoopForAlpha`）: `docs/working/issues/flow/` の 0043 / 0096 / 0109 / 0117
- 受け皿候補: Issue-0107（`docs/working/issues/flow/0107-iterative-review-recommendation-divergence/`。LoopForAlpha#Issue-0109 の移譲先として予定済み）/ Issue-0103（反復のコスト予算）
- 課題一覧: `docs/working/issues/README.md` / ADR インデックス: `docs/records/decisions/README.md`（0001〜0118）

## 完了済みタスク

- [x] 次サイクルテーマ選定（Issue-0110）と委譲スコープ決定（4 件一括）・ADR-0118 ドラフト作成（2026-08-30）
- [x] 第 1 段委譲実施設計の確定（spec 確定点 (b) 通過。設計は ADR-0118 Decision の「委譲の実施方式」節が正本）（2026-08-30）
- [x] 第 1 段＝委譲の実施完了（受け皿 Issue-0112/0113/0114 新設・LFA#0109→Issue-0107 統合・コピー 11 ファイル検証済み・インデックス 3 行・LFA 側 4 課題へ追記〈未コミット残置〉）（2026-08-30）

## 進行中のタスク

- [ ] **現在の作業**: 第 2 段＝委譲材料の精読 → Issue-0110 対策設計（brainstorming 続行）
  - 状態: 未着手。精読対象 = Issue-0113 の `lfa-0096-*`（工程 2 型・逸脱時格下げの安全弁）、Issue-0114 の `lfa-0117-2026-08-27-marginal-utility-aggregation.md`（層別実測）、Issue-0107 の `lfa-0109-note-divergence-cases.md`（乖離事例）
  - 残り: 精読 → 対策設計（spec 確定点で確定前レビュー提示）→ 対策 ADR → plan（plan 確定点）→ 実装 → Accepted 昇格・Issue close

## 既知のブロッカー・懸念

- master の未 push 7 コミット（`52551b3` まで）が残っている。本ブランチはその先端から分岐
- **LoopForAlpha リポジトリに委譲済み追記 4 ファイルが未コミットで残置**（`feature/stage7-part2-design` の作業ツリー上。ユーザーが LFA セッションで LFA 側の流儀によりコミット予定。本リポジトリからはコミットしない）
- 委譲対象は合計約 180KB。読み込み・整理の作業量が大きく、brainstorming でスコープの段階分けが必要になる可能性（ADR-0118 Consequences 参照）
- inbox に未整理 3 件滞留（ユーザーが手動移動予定。organize-inbox の提案不要）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。

- 2026-08-30 第 1 段委譲実施設計の確定・spec 確定点 (b): ADR=0118（ドラフト反映・Proposed 未コミット） / worklog=棄却（delta なし） / review=非発火（推奨判定が偽）
- 2026-08-30 第 1 段委譲実施完了・spec 確定点 (c)（ADR-0118 コミット）: ADR=0118（Proposed のままコミット） / worklog=棄却（delta なし） / review=非発火（推奨判定が偽。(b) 通過済み内容のみで未レビュー差分ゼロ）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ・ADR-0118・Issue-0110
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ extend-guidelines / brainstorming の続きへ
3. 留意点: 質問はテキストの番号付き選択肢のみ（ADR-0109）。配布対象ソースを変更したら執行点 4 手順＋version bump（現行 0.1.14）。確定点で確定前レビューを提示（ADR-0080/0107/0117）

## 重要な意思決定の履歴

- ADR-0118: LoopForAlpha のレビュー関連 flow 課題 4 件を一括委譲し、Issue-0110 対策設計と同一サイクルで扱う（2026-08-30 Proposed）
