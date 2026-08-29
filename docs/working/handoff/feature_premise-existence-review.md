# Handoff: 前提実在観点の新設と前提検査規範の追加（LoopForAlpha Issue-0125 還流）

- **Branch**: feature/premise-existence-review
- **Last Updated**: 2026-08-29 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装 plan 確定（plan 確定点通過）・実装実行へ移行

## 作業の目的・背景

LoopForAlpha の flow 課題（`LoopForAlpha#Issue-0125`）が実測した「検証を省いて出力する」型の設計ミス 2 種（実証つき指摘の前提検査なし採用・実体を読まない設計記述）を塞ぐため、同課題の提案書（改修 4 点＋任意 1 点）に基づきガイドラインを改修する。採用 = 提案 2-1〜2-4、見送り = 2-5。設計は ADR-0117（Proposed）が正本（設計文書兼用、spec 確定点 (c) の型）。改修完了後、worklog 中央ストアの処理済み台帳へ `LoopForAlpha-2026-08-29-01`/`-02`/`-03` を merged、`-04`/`-05` を deferred として記入する（ユーザー指示）。

## 関連ドキュメント

- 設計 ADR: ADR-0117（`docs/records/decisions/0117-premise-existence-viewpoint-and-premise-checks.md`。Proposed・未コミット）
- 源流提案書: `D:\Dev\001_Trade\LoopForAlpha\docs\working\issues\flow\0125-review-findings-adopted-without-premise-check-and-design-written-from-summaries\0125-2026-08-29-guideline-change-proposal.md`
- 改修対象: `skills/pre-finalization-review/SKILL.md` / `skills/subagent-dispatch/SKILL.md` / `skills/feature-block-design/SKILL.md`
- 部分修正注記の対象: ADR-0080 / ADR-0107（部分修正）、ADR-0067（注記のみ）
- 拡張規約: `CONTRIBUTING.md`（過剰適合点検・新設の評価可能性・記法規約・執行点 4 手順）

## 完了済みタスク

- [x] start-work Phase 0〜2・extend-guidelines・brainstorming（設計承認。2026-08-29）
- [x] ADR-0117 ドラフト作成・インデックス追記（Proposed 据え置き。昇格は実装完了後）
- [x] ADR-0117 の確定前レビュー反復（フル巡 2〈4 観点・claude-opus-5 各 4 体〉→ 設計縮小〈採否記録義務の撤回・delta 基準化〉→ 差分確認巡 1 → 精度修正 3 句で実質収束。改訂 r0→r4。退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-08-29-premise-existence-review-r0/`〜`-r3/`）

## 進行中のタスク

- [ ] **現在の作業**: plan の実装実行（`docs/working/plans/2026-08-29-premise-existence-review-implementation.md` の Task 1〜10）
  - 状態: plan 確定済み（フル巡 1〈2 体兼務〉＋差分確認巡 1・改訂 r0→r2・実質収束。退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-08-29-premise-existence-plan-r0/`・`-r1/`）。実行方式の選択待ち
  - 残り: Task 1〜10 の実行 → 完了前検証 → ADR-0117 Accepted 昇格（サイクル全体整合検査・`Accepted 昇格` を名称に含むマイルストーン）→ マージ → retrospective

## 未着手のタスク

- [ ] スキル 3 本の改修（実装対象の全列挙は ADR-0117 Consequences が正本）・ADR-0080/0107 部分修正注記・ADR-0067/0063 注記・現行 spec 3 件の同期・plugin 0.1.14・執行点 4 手順
- [ ] worklog 台帳記入（merged × 3・deferred × 2）
- [ ] ADR-0117 Accepted 昇格（サイクル全体整合検査）・マージ・retrospective

## 既知のブロッカー・懸念

- master の既知事項（inbox 3 件滞留・push 状況等）は `docs/working/handoff/master.md` 参照

## Post ラッパー消化記録

- 2026-08-29 ADR-0117 設計確定・spec 確定点 (c): ADR=0117 / worklog=`MakeAiInstructions-2026-08-29-02` / review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡・実質収束）
- 2026-08-29 実装 plan 確定・plan 確定点: ADR=なし（設計は ADR-0117 で確定済み・plan はその写像） / worklog=`MakeAiInstructions-2026-08-29-03` / review=フル実施（claude-opus-5・1 巡）＋差分再確認（claude-opus-5・1 巡・実質収束）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフと ADR-0117 ドラフト
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: ADR-0117 は未コミット（コミットは確定前レビュー収束後）。レビュー反復の状態は「進行中のタスク」参照

## 重要な意思決定の履歴

- ADR-0117: 確定前レビューに前提実在観点を新設し、指摘採否・提示・設計記述に前提と実在の検査を課す（2026-08-29 Proposed）
