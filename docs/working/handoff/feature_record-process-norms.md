# Handoff: 記録プロセス規範の一括対策（Issue-0009 / 0010 / 0011）

- **Branch**: feature/record-process-norms
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了（merge: 71d383c、retrospective 実施済み、プラグイン更新済み）

## 作業の目的・背景

retrospective で抽出された「記録プロセス規範」に関するフロー課題3件を、同一サイクルで一括対策する。

- **Issue-0009**: ADR ドラフトの起票タイミングが「即時」ルール（ADR-0006）と議論の収束度で緊張する。「ドラフト作成」と「コミット」の区別や、関連論点の収束確認が規範に含まれていない
- **Issue-0010**: 既存 open 課題が再発した場合の記録方法（issue の検討状況 / 振り返りファイル / 両方）が未定義で、実施者依存になっている
- **Issue-0011**: 規範・ADR 起草時に「その判定条件・動作をエージェントが実際に観測・実行できるか」を確認する観点が decision-log スキル / CONTRIBUTING のチェックリストに定式化されていない

3件とも意思決定・課題の記録プロセス自体の規範に関わるため、一括で設計・対策する（前サイクル担当エージェントの推奨をユーザーが採択）。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0009-adr-draft-timing.md` / `0010-issue-recurrence-recording.md` / `0011-norm-executability-check.md`
- 起票元: `docs/records/retrospectives/flow/2026-07-05-retrospective-issue-integration.md`（課題#1, #2）、`docs/records/retrospectives/flow/2026-07-05-question-tool-display-norm.md`（課題#1）
- 関連ADR: ADR-0006（継続的ADR検出）、ADR-0019（決定のみ記載）、ADR-0028（課題全件起票・system/flow 分割）、ADR-0029（実行不能な撤去基準の書き直し事例）
- 関連ガイドライン: `CLAUDE.md`「意思決定の即時記録」、skills/decision-log、skills/retrospective、CONTRIBUTING.md、`docs/overview/folder-structure.md` §7

## 完了済みタスク

- [x] ブランチ作成・対象課題3件と起票元 retrospective の内容確認（2026-07-05）
- [x] 設計（spec: `docs/current/specs/2026-07-05-record-process-norms-design.md`、ユーザー承認済み）・plan（`docs/working/plans/2026-07-05-record-process-norms-plan.md`）作成（2026-07-05）
- [x] 実装 Task 1-6 完了（2026-07-05）: ADR-0030（decision-log 手順4 / CLAUDE.md / start-work）、ADR-0031（folder-structure §7 / retrospective）、ADR-0032（decision-log 記述規律 / CONTRIBUTING ×2）、sync-template 実行（改行のみ差分2件は git restore で回避し Issue-0002 検討状況へ再発を記録＝ADR-0031 規範の初適用）、ADR 3本 Accepted 昇格、Issue-0009/0010/0011 close

## 進行中のタスク

なし（サイクル完了。merge 71d383c、プラグイン更新済み、retrospective は `docs/records/retrospectives/system|flow/2026-07-05-record-process-norms.md`。以降の状態は `master.md` ハンドオフが正）

## 未着手のタスク

なし

## 既知のブロッカー・懸念

- AskUserQuestion と同一ターンのテキストが表示されない事象（ADR-0029 の規範に従い対処）
- skills/ を編集した場合、プラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、対象課題3件
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: master 直接作業禁止。ADR-0019 / 0021 / 0022 / 0024 / 0028 を遵守

## 重要な意思決定の履歴

（このサイクルではまだなし）
