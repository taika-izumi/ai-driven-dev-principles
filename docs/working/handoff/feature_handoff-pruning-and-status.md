# Handoff: ハンドオフ剪定規約と Status 値整合（Issue-0049 + 0051）

- **Branch**: feature/handoff-pruning-and-status
- **Last Updated**: 2026-08-06 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: 完了（master merge `1eba4c3`・retrospective 実施済み・feature ブランチ削除済み）

## 作業の目的・背景

Issue-0049（ハンドオフが単一ファイルへの時系列追記で肥大し、完了情報の剪定規約がない）と Issue-0051（`retrospective` が要求する Status 値 `ready-for-next-cycle` を `session-handoff` が未定義）を同時対処する。0051 の対処案 (c)「サイクル完了時はハンドオフをアーカイブして新規作成」が 0049 の剪定設計と自然に重なるため、1 サイクルで一括設計する（スコープ確定はユーザー判断、2026-08-06）。

Issue-0053（セッション再起動での振り返り素材消失）はスコープ外だが、剪定と逆方向のリスクを持つため設計時の留意事項として参照する。

**設計上の制約（Issue-0049 の留意より）**: 単純に短くする方向で解かないこと。ハンドオフの記述の多くは実測済みの申し送りであり、削ると再発する。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0049-handoff-single-file-growth-no-pruning-rules.md` / `docs/working/issues/flow/0051-handoff-status-value-mismatch-between-skills.md`
- 留意参照: `docs/working/issues/flow/0053-retrospective-material-loss-across-session-restart.md`
- 対象スキル: `skills/session-handoff/SKILL.md`（フォーマット・操作定義）、`skills/retrospective/SKILL.md`（Phase 3 の Status 遷移指示）
- 設計 spec: `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md`（設計承認済み・コミット `7572776`）
- 本サイクルの ADR: ADR-0074（受け皿 git 履歴のみ）/ 0075（二段階剪定）/ 0076（Status 4 値化）/ 0077（安定識別子参照）。すべて Proposed・コミット `cb8f8d9`。昇格は実装完了・検証後
- 関連 ADR: ADR-0057（Post ラッパー消化記録の finalize 時削除 — 既存の唯一の剪定規約）

## 完了済みタスク

- [x] スコープ確定: 0049+0051 同時対処、0053 は留意参照のみ（2026-08-06）
- [x] brainstorming: 設計承認・ADR-0074〜0077 起票（Proposed・コミット済み）・spec コミット `7572776`（2026-08-06）
- [x] writing-plans: 実装計画 `docs/working/plans/2026-08-06-handoff-pruning-and-status.md` 作成・コミット `1e92e61`。pre-finalization-review は提示のうえユーザーが不実施を選択（2026-08-06）
- [x] 実装（executing-plans・全 5 タスク）: session-handoff / retrospective 改定（`4b9bd80` `f83e69b`）、整合突合パス、プラグイン更新後の同セッション反映を実測し Issue-0044 追記（`6070dd6`）、ADR-0074〜0077 Accepted 昇格＋Issue-0049/0051 close（`531b3cd`）（2026-08-06）

## 進行中のタスク

（なし。master merge `1eba4c3` → retrospective（cycle-reset 初回実運用で master.md の Status 不整合注記を除去）まで完了）

## 未着手のタスク

（なし）

## 既知のブロッカー・懸念

- inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- スキル改定サイクルのため、Issue-0044（スキル改定の同セッション検証可否の実測）の実測機会になり得る

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。

- 2026-08-06 設計承認・spec コミット（brainstorming 完了相当）: ADR=0074/0075/0076/0077（Proposed・コミット済み） / worklog=`MakeAiInstructions-2026-08-06-02`
- 2026-08-06 plan 実行完了（executing-plans 全 5 タスク）: ADR=なし（新規決定なし。0074〜0077 の昇格は計画どおり） / worklog=棄却（計画どおりの実行で delta なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ、設計 spec `docs/current/specs/2026-08-06-handoff-pruning-and-status-design.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ スペックレビュー状況の確認 → `superpowers:writing-plans`
3. 留意点: 剪定設計では Issue-0053（素材消失）と逆方向のリスクに注意。単純な短縮で解かない（基準付き圧縮の基準は spec 変更 3 参照）

## 重要な意思決定の履歴

- ADR-0074: 剪定の受け皿は git 履歴のみ（2026-08-06）
- ADR-0075: 二段階剪定（セッション境界で基準付き圧縮、サイクル境界で初期状態への書き換え）（2026-08-06）
- ADR-0076: Status に ready-for-next-cycle を正式追加（2026-08-06）
- ADR-0077: handoff の外部参照は安定識別子で書く（2026-08-06）
