# Handoff: 開発プロジェクトのフォルダ構成定義の追加

- **Branch**: feature/project-folder-structure
- **Last Updated**: 2026-07-04 12:52 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/extend-guidelines → brainstorming（要件ヒアリング中）

## 作業の目的・背景

本リポジトリのAI開発ガイドラインに「開発プロジェクトのフォルダ構成の定義」を追加する。現状、ガイドラインは `docs/specs/`・`docs/decisions/`・`docs/handoff/`・`docs/retrospectives/` など個別ドキュメントの配置規約を断片的に定めているが、開発プロジェクト全体のフォルダ構成を体系的に定義した規範は存在しない。今サイクルでこれを追加する。

実現手段（原則追加 / CLAUDE.md 更新 / 新スキル / 参照ドキュメント）は brainstorming で検討する。

## 関連ドキュメント

- 拡張ルール: `CONTRIBUTING.md`
- Layer 1 原則: `docs/principles.md`
- Layer 2 指示: `CLAUDE.md`
- ADR インデックス: `docs/decisions/README.md`（0001〜0024）

## 完了済みタスク

- [x] feature ブランチ作成・ハンドオフ作成（2026-07-04）

## 進行中のタスク

- [ ] **現在の作業**: brainstorming（要件ヒアリング）
  - 状態: extend-guidelines で CONTRIBUTING.md 読み込み済み。要件の詳細（対象範囲・粒度・実現レイヤー）は未確定
  - 残り: ユーザーへの要件ヒアリング → 設計案の比較 → ADR ドラフト

## 未着手のタスク

- [ ] 設計（実現レイヤーの決定、ADR 起票）
- [ ] 実装（該当ファイルの更新）
- [ ] template 同期（`scripts/sync-template.ps1`、CLAUDE.md/principles.md 変更時）
- [ ] master への merge・ADR Accepted 昇格

## 既知のブロッカー・懸念

- master 側ハンドオフの持ち越し: retrospective 2サイクル分（選択肢＋推奨規範 / Claude Code 対応）が未実施のまま。ユーザー判断待ち

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、`CONTRIBUTING.md`
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）
3. 留意点: 要件ヒアリングが未完了。フォルダ構成定義の対象範囲（ガイドライン関連ドキュメントのみか、ソースコード含む全体か）をユーザーに確認すること

## 重要な意思決定の履歴

（まだなし）
