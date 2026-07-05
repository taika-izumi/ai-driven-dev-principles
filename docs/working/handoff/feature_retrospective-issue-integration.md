# Handoff: 振り返り課題と issue 管理の統合（フロー課題 #4 対策）

- **Branch**: feature/retrospective-issue-integration
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 改修/feature-block-design 完了（spec 作成済み）→ ユーザーの spec レビュー待ち

## 作業の目的・背景

前サイクルのフロー課題 #4「retrospective の課題バックログと issue 管理の関係が未定義」への対策。振り返りで抽出した課題を全件 `docs/working/issues/` に起票する統合ルールと、issues の `system/`（対象システム固有）`flow/`（開発フロー/ガイドライン）フォルダ分割を導入する（ADR-0028, Proposed）。

主決定: 振り返り時に全件起票 / issues を system/flow に2分割（retrospectives と対称）/ 通し連番・ルート README 1つ（2セクション）/ 振り返り由来の課題は要約＋起票元参照 / 配布先 repo でも全件ローカル起票。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-07-05-retrospective-issue-integration/`（00-overview + 4ブロック）
- ADR: ADR-0028（Proposed。実装完了・検証後に Accepted へ昇格）
- 起点: `docs/records/retrospectives/flow/2026-07-05-project-folder-structure.md` 課題 #4

## 完了済みタスク

- [x] brainstorming（起票基準・分類表現・組み込み位置の決定、2026-07-05）
- [x] ADR-0028 起票（Proposed、commit 86ac618）
- [x] feature-block-design（4ブロック分割、ユーザー承認済み）
- [x] spec 作成・コミット（commit 3613917）

## 進行中のタスク

- [ ] **現在の作業**: ユーザーの spec レビュー
  - 状態: spec をコミットしレビュー依頼済み
  - 残り: 承認後 writing-plans → 実装

## 未着手のタスク

- [ ] writing-plans（実装計画。出力先 `docs/working/plans/`）
- [ ] 実装（ブロック01→02/03/04、詳細は spec 参照）
- [ ] sync-template 実行・プラグイン更新案内
- [ ] ADR-0028 Accepted 昇格・Issue-0007 close（実装完了時）

## 既知のブロッカー・懸念

- ユーザー環境では AskUserQuestion と同一ターンのテキストが表示されない（再発確認済み。説明が必要な相談はテキストのみのターンで行う。Issue-0004 として起票予定のフロー課題 #1 と同根）
- 旧型式 spec `docs/current/specs/2026-05-01-retrospective-design.md` が ADR-0021 以前の内容のまま stale（本サイクルのスコープ外。課題起票の要否はユーザー判断待ち）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、spec `00-overview.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ spec レビュー結果に応じて writing-plans
3. 留意点: master 直接作業禁止 / template 対象変更後は sync-template 実行 / スキル変更はプラグイン更新まで未反映

## 重要な意思決定の履歴

- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Proposed）
