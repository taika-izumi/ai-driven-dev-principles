# Handoff: 振り返り課題と issue 管理の統合（フロー課題 #4 対策）

- **Branch**: feature/retrospective-issue-integration
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: 完了（merge: b418d5d、retrospective 実施済み。以後の状態は `master.md` を参照）

## 作業の目的・背景

前サイクルのフロー課題 #4「retrospective の課題バックログと issue 管理の関係が未定義」への対策。振り返りで抽出した課題を全件 `docs/working/issues/` に起票する統合ルールと、issues の `system/`（対象システム固有）`flow/`（開発フロー/ガイドライン）フォルダ分割を導入する（ADR-0028, Proposed）。

主決定: 振り返り時に全件起票 / issues を system/flow に2分割（retrospectives と対称）/ 通し連番・ルート README 1つ（2セクション）/ 振り返り由来の課題は要約＋起票元参照 / 配布先 repo でも全件ローカル起票。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-07-05-retrospective-issue-integration/`（00-overview + 4ブロック）
- ADR: ADR-0028（Proposed。実装完了・検証後に Accepted へ昇格）
- 起点: `docs/records/retrospectives/flow/2026-07-05-project-folder-structure.md` 課題 #4

## 完了済みタスク

- [x] brainstorming（起票基準・分類表現・組み込み位置の決定、2026-07-05）
- [x] ADR-0028 起票（Proposed、commit 86ac618）→ 実装完了により Accepted 昇格
- [x] feature-block-design（4ブロック分割、ユーザー承認済み）
- [x] spec 作成・コミット（commit 3613917、レビュー反映 7d154d1）
- [x] plan 作成（commit a106811）
- [x] 実装 Task 1: folder-structure.md §7 改定（6235d58）
- [x] 実装 Task 2: 課題移行・0002〜0008 起票・インデックス2セクション化（6c88d26）
- [x] 実装 Task 3: retrospective スキル起票統合（9175087）
- [x] 実装 Task 4: 周辺文書整合。旧サイクル spec 2ファイルの網羅漏れも追加回収（5239c63）
- [x] 実装 Task 5: template 同期（48248a3）
- [x] 実装 Task 6: ADR-0028 Accepted・Issue-0007 close・本ハンドオフ更新

## 進行中のタスク

なし（実装完了。merge 判断待ち）

## 未着手のタスク

- [ ] master への merge（ユーザー判断。superpowers:finishing-a-development-branch）
- [ ] merge 後: retrospective スキル起動（新起票フローの初回ドッグフーディング）
- [ ] merge 後: プラグイン更新（ユーザー操作: `/plugin marketplace update ai-driven-dev-principles`）。実行までスキル変更は未反映

## 既知のブロッカー・懸念

- ユーザー環境では AskUserQuestion と同一ターンのテキストが表示されない（再発確認済み。説明が必要な相談はテキストのみのターンで行う。Issue-0004 として起票予定のフロー課題 #1 と同根）
- 旧型式 spec `docs/current/specs/2026-05-01-retrospective-design.md` が ADR-0021 以前の内容のまま stale（本サイクルのスコープ外。課題起票の要否はユーザー判断待ち）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`docs/working/issues/README.md`（新2セクション構造の確認）
2. 最初に実行すべきコマンド/スキル: `start-work` → master への merge（superpowers:finishing-a-development-branch）→ merge 直後に `retrospective` スキル（本サイクルの振り返り。新起票フローの初回実運用になる）
3. 留意点: merge 後にプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）を実行するまで retrospective / decision-log スキルの変更は実行環境に反映されない / 実装中に Issue-0006（横断変更の計画網羅漏れ）の再現例あり（旧サイクル spec 2ファイルの漏れをレビューで回収）— 次回 retrospective のネタ

## 重要な意思決定の履歴

- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
