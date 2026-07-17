# Handoff: worklog v1.1 改訂サイクル（Issue-0023＋0025〜0029 一括対処）

- **Branch**: feature/worklog-v1.1
- **Last Updated**: 2026-07-17 22:37 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 改修/brainstorming（開始前）

## 作業の目的・背景

3スキルパイプライン（worklog-record → worklog-extract → worklog-skillify）の初回実装（2026-07-17 merge `7ed7b32`）後に起票された改善課題 6 件を「worklog v1.1 改訂サイクル」として一括対処する。いずれも同じスキーマ・スキル定義群（`skills/worklog-record/references/store-format.md`、spec `docs/current/specs/2026-07-17-worklog-skill-pipeline/`、ADR-0045 ほか）に触れるため、個別対処より一括改訂が効率的（前サイクルのハンドオフで推奨された次手）。

対象課題:

- **Issue-0023**（flow）: worklog-record の記録件数規範と複数 delta 候補時の優先順位付けが未明示
- **Issue-0025**（system）: エントリに delta 発生元モデルの記録フィールドがない
- **Issue-0026**（system）: エントリ・台帳にスキーマバージョンフィールドがない（早いほど安い）
- **Issue-0027**（system）: 並行セッションで id 採番が衝突しうる（採否は発生確率と対処コストの見合い）
- **Issue-0028**（system）: マルチユーザー・組織展開が未設計（v2 テーマ明記あり。今回はスコープ判断のみの可能性大）
- **Issue-0029**（system）: スキーマ細部 3 点（corrections の誤答側・friction 型非対称・損失規模）

## 関連ドキュメント

- 対象 Issue: `docs/working/issues/flow/0023-*.md`、`docs/working/issues/system/0025-*.md`〜`0029-*.md`
- スキーマ定義: `skills/worklog-record/references/store-format.md`
- spec: `docs/current/specs/2026-07-17-worklog-skill-pipeline/`（00-overview ＋ 01〜04）
- 関連 ADR: ADR-0044/0045/0046/0047（Accepted）
- 設計意図ドキュメント: `docs/inbox/2026-07-17-worklog-entry-format-rationale.md`（レビュー指摘の起票元。inbox 残置中・ユーザーが手動移動予定）
- 中央ストア実体: `$HOME/.ai-dev-worklog/MakeAiInstructions/log.jsonl`（1 件記録済み）

## 完了済みタスク

（なし）

## 進行中のタスク

- [ ] **現在の作業**: brainstorming（要件・設計の合意）
  - 状態: 開始前（対象 Issue 6 件の内容確認まで完了）
  - 残り: brainstorming → 必要なら feature-block-design → writing-plans → 実装

## 未着手のタスク

- [ ] 設計合意後の計画作成・実装・検証・spec/ADR 更新
- [ ] skills/ 改定後のプラグイン更新（`√ Updated 1 marketplace` の確認）

## 既知のブロッカー・懸念

- inbox 残置 3 件（`2026-07-11-session-continuation-criteria.md`、`2026-07-17-worklog-entry-format-rationale.md`、`flow_issue_memo.md`）と `docs/conversation_log.md`: **ユーザーが全て手動で別の場所へ移す予定と明言（2026-07-17）**。organize-inbox の提案は不要。ただし `2026-07-17-worklog-entry-format-rationale.md` は本サイクルの入力のため、移動された場合は所在をユーザーに確認すること
- スキーマ変更は中央ストア既存データ（1 件）との後方互換に留意（Issue-0026 の「v なし = v1」暗黙規約の固定化リスク）

## 次セッション開始時のアクション

1. 最初に呼ぶスキル: `start-work`（Phase 0 で本ハンドオフを read）
2. 最初に確認すべきファイル: 本ファイル、対象 Issue 6 件
3. 留意点: master 直接作業禁止 / skills/ 編集後はプラグイン更新 / ADR は 1 決定=1ADR（Issue-0022 参照）

## 重要な意思決定の履歴

（本サイクルではまだなし）
