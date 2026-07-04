# Handoff: 開発プロジェクトのフォルダ構成定義の追加

- **Branch**: feature/project-folder-structure
- **Last Updated**: 2026-07-04 23:00 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装完了（Task 1〜13、最終レビュー APPROVED）→ 残: プラグイン更新（ユーザー操作）と master への merge

## 作業の目的・背景

本リポジトリのAI開発ガイドラインに「開発プロジェクトのフォルダ構成の定義」を追加する。ユーザーが別プロジェクトで実践した「情報の更新頻度とライフサイクルの長さ」による情報分類を出発点に、brainstorming で以下を決定し、設計承認済み:

- **5分類体系**（オリエンテーション / 現在の正 / 進行中の作業 / 追跡型の記録 / 参照知識）＋境界判断基準3つ＋蒸留規則（ADR-0025, Accepted）
- 既存 docs は**全面再配置**（既存パス維持案はユーザーが明示的に否決）。`open-questions.md` は課題（issue）管理へ統合。本リポジトリ自身にも適用（ドッグフーディング）
- レイアウトは**分類トップレベル**: `docs/{overview, current, working, records, reference, inbox}`。種別サブフォルダはオンデマンド作成
- **inbox ＋ organize-inbox スキル**（移動・分割・既存ファイルへの追記統合を含む）＋ start-work Phase 1 での inbox 検知（提案のみ、強制なし）（ADR-0026, Accepted）。スキル名は sort/process と比較し organize を採用
- コード領域は抽象原則のみ（コードとドキュメントの領域分離、言語慣習に従う、AI駆動成果物＝プロンプト/エージェント定義/評価データはコード領域）
- 定義本体は `docs/overview/folder-structure.md`（新規・template対象）に置き、CLAUDE.md には数行の規範＋パス更新のみ

## 関連ドキュメント

- 今サイクルの ADR: `docs/records/decisions/0025-five-class-information-taxonomy.md`（Accepted）、`docs/records/decisions/0026-inbox-and-organize-inbox-skill.md`（Accepted）
- 拡張ルール: `CONTRIBUTING.md`
- 分割仕様書（これから作成）: `docs/current/specs/2026-07-04-project-folder-structure/`（新構成を先取り）

## 完了済みタスク

- [x] feature ブランチ作成・ハンドオフ作成（2026-07-04）
- [x] brainstorming: 要件確定・分類体系設計・レイアウト決定・設計承認（2026-07-04）
- [x] ADR-0025 / ADR-0026 作成・Accepted 昇格（2026-07-04, commit 437e442）
- [x] feature-block-design: 6ブロック構成をユーザー承認、分割仕様書 `docs/current/specs/2026-07-04-project-folder-structure/00〜06` 作成（2026-07-04, commit 582dbbd）
- [x] 仕様書レビュー指摘3点の反映＋ADR-0027（テンプレート初期セット基準, Proposed）作成（2026-07-04, commit 703c0f8）
- [x] writing-plans: 実装計画 `docs/working/plans/2026-07-04-project-folder-structure-plan.md` 作成（Task 1〜13。実行順序 01→03→02→04→06→05 を反映）

## 進行中のタスク

- [ ] **現在の作業**: 完了処理
  - 状態: Task 1〜13 実装完了（subagent-driven で実行、各タスク検証済み）。branch 全体の最終レビュー APPROVED（Minor 3件のみ、ブロッカーなし）。ADR-0027 Accepted 昇格済み（fdfb087）
  - 残り: プラグイン更新（ユーザー操作: `/plugin marketplace update ai-driven-dev-principles`）→ master への merge → retrospective 提案

## 未着手のタスク

- [ ] プラグイン更新で新スキル（organize-inbox）と修正済みスキルを反映（完了基準8。ユーザー操作）
- [ ] master への merge（--no-ff）と push
- [ ] merge 後の retrospective（前2サイクル分も未実施のまま持ち越し中）

## 既知のブロッカー・懸念

- 最終レビューの Minor 指摘: (a) `docs/conversation_log.md`（untracked のユーザー記録）が新レイアウト外に残置 — ユーザー判断待ち、(b) folder-structure.md の「inbox」「関連 ADR」セクションが番号なし（cosmetic、対応不要と判断）
- superpowers スキル（brainstorming/writing-plans）のデフォルト出力パスは外部プラグインのため変更不可。CLAUDE.md 側の指示で上書き済み
- master 側の持ち越し: retrospective 2サイクル分が未実施のまま（ユーザー判断待ち）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`docs/current/specs/2026-07-04-project-folder-structure/00-overview.md` の完了基準
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）。未 merge なら merge から再開
3. 留意点: スキル編集はプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで利用環境に反映されない。ユーザー環境では AskUserQuestion と同一ターンのテキストが表示されないことがある（説明は独立したテキストターンで送ること）

## 重要な意思決定の履歴

- ADR-0025: 情報の5分類体系を導入し、ドキュメント構成を全面再配置する（2026-07-04, Accepted）
- ADR-0026: inbox フォルダと organize-inbox スキルによる情報分類の仕組みを導入する（2026-07-04, Accepted）
- ADR-0027: テンプレート初期セットの基準を定義し、インデックス空生成を一般化する（2026-07-04, Accepted）
