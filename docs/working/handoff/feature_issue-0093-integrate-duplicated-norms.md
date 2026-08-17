# Handoff: Issue-0093/0094 対策（二重定義 22 行の統合と高コスト様式 3 行の簡素化）

- **Branch**: feature/issue-0093-integrate-duplicated-norms
- **Last Updated**: 2026-08-17 13:42 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 対策サイクル/実装（plan 確定点通過・plan コミット済み。次セッションで Task 1 から実装開始）

## 作業の目的・背景

全数監査（ADR-0100/0101）で「統合」に分類された二重定義 22 行（Issue-0093。13 クラスタ）と「簡素化」3 行（Issue-0094。C-11/D-11/I-17）を単一サイクルで実装する。設計は ADR-0105（設計文書を兼ねる型）で確定: 実変更 15 行＋覆し 7 行（理由記録・Issue-0099 で backlog 化）＋簡素化 3 行。確定前レビューは 3 観点 × 7 巡で Critical/Major ゼロ収束（ユーザー指示による反復。巡別実測は Issue-0098 へ記録済み）。

## 関連ドキュメント

- Plan: `docs/working/plans/2026-08-17-issue-0093-0094-integration-plan.md`（15 タスク。コミット `d38f46b`）
- 決定: ADR-0103（スコープ）/ ADR-0104（設計方式）/ ADR-0105（設計本体。クラスタ別設計・付随編集 4 件・部分修正注記・掃き出し・過剰適合点検を含む）
- 課題: Issue-0093 / Issue-0094（対象）、Issue-0099（覆し 5 行の条件付き backlog）、Issue-0098（反復レビュー実測の追記先）
- 監査正本: `docs/records/audits/2026-08-16-guideline-process-audit/`（report 1-6・ledger。確定後不変・行番号は陳腐化ありのため実装は実体読みで特定）

## 完了済みタスク

- [x] brainstorming・設計承認・ADR-0103〜0105 起票（2026-08-17）
- [x] 確定前レビュー フル実施 7 巡・収束判定・指摘反映（2026-08-17）
- [x] Issue-0099 起票、Issue-0093/0094/0097/0098 への追記（2026-08-17）
- [x] plan 作成（部分修正注記 21 本の全数走査確定・掃き出し grep 14 系統の母集団確定を含む）・確定前レビュー 2 巡（フル 3 観点＋差分確認）・plan コミット `d38f46b`（2026-08-17）

## 進行中のタスク

- [ ] **現在の作業**: plan の実装（Task 1〜15）
  - 状態: plan 確定・コミット済み（`d38f46b`）。実装は未着手。実装方式（subagent-driven / インライン）は未選択
  - 残り: Task 1〜13（統合・簡素化・注記・version bump 0.1.8）→ Task 14 サイクル全体整合検査（旧 spec 追従・open 課題引用 4 件の個別判定を含む）→ Task 15 Accepted 昇格・Issue-0093/0094 close・Issue-0060 の close 判定

## 未着手のタスク

- [ ] 実装完了時: サイクル全体整合検査（旧 spec 追従の判定を含む）、Issue-0060 の close 判定（いずれも plan Task 14・15 に組込済み）

## 既知のブロッカー・懸念

- 配布対象ソース 10 ファイルに触れるため執行点 4 手順（build-dist / sync-template 両方＋ -Check ＋配布物目視 5 点）と plugin version bump（0.1.7 → 0.1.8）が必須
- 実装は台帳の行番号アンカーを使わない（CONTRIBUTING 最大 +23・decision-log +2 の陳腐化済み。ADR-0105 Consequences）
- inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定。`git add` で巻き込まないこと（pathspec コミット。Issue-0020）

## Post ラッパー消化記録

- 2026-08-17 設計確定・ADR-0103〜0105 コミット・spec 確定点 (c) 通過: ADR=0103/0104/0105（Proposed。昇格は実装完了時） / worklog=`MakeAiInstructions-2026-08-17-04` / review=フル実施（claude-opus-5。3 観点 × 7 巡で C/M ゼロ収束。巡別実測は Issue-0098）
- 2026-08-17 セッション終了処理: ADR=なし（設計確定後の新規決定なし） / worklog=棄却（`-04` 記録以降の delta なし）
- 2026-08-17 plan 作成完了・plan 確定点 通過: ADR=なし（ADR-0105 の写像のみ） / worklog=棄却（delta なし。反復実測は Issue-0098 へ一次記録） / review=フル実施（claude-opus-5。3 観点＋差分確認の 2 巡で C/M ゼロ収束。実測は Issue-0098）
- 2026-08-17 セッション終了処理（実装開始前の区切り）: ADR=なし（plan 確定以降の新規決定なし） / worklog=棄却（plan 確定点以降の delta なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: plan `docs/working/plans/2026-08-17-issue-0093-0094-integration-plan.md`（前提・実装原則の節を含む）と本 handoff
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ 実装方式をユーザーへ確認（推奨: superpowers:subagent-driven-development。plan は old/new 全明示の委譲向き自己完結型）→ plan の Task 1 から実装
3. 留意点: 各コミットで執行点（生成器＋`-Check`＋目視）。実装は実体読みで対象特定（plan の old_string は 2026-08-17 時点の実体）。コミットは pathspec 付き（inbox・conversation_log を巻き込まない）

## 重要な意思決定の履歴

- ADR-0103: Issue-0093 の統合 22 行と Issue-0094 の簡素化 3 行を単一サイクルで実施する（2026-08-17）
- ADR-0104: 統合仕様は監査の統合先案を既定とし、正本読み合わせで重複側固有の条件を写像してから確定する（2026-08-17）
- ADR-0105: 統合 22 行は配線化（共通規範の新設は見送り、7 行は覆し現状維持）、簡素化 3 行は手順の束ね直しと起票手順の参照化（2026-08-17）
