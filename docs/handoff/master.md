# Handoff: AI駆動開発メタ・ガイドラインの段階的整備

- **Branch**: master
- **Last Updated**: 2026-04-28 00:35 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: サブプロジェクトA完了 / サブプロジェクトB未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。プロジェクト全体は複数のサブプロジェクトに分割して段階的に進行している。

- **サブプロジェクトA「記録の強化」**: 完了済み。意思決定の即時検出ルール（ADR）と、セッション継続のためのハンドオフファイル方式、そしてそれらを束ねる起点スキル `start-work` を導入した。
- **サブプロジェクトB「機能ブロック駆動の設計＋仕様書分割」**: 未着手。次セッションで brainstorming から開始する。

## 関連ドキュメント

- 原則: `docs/principles.md`
- サブプロジェクトA plan: `docs/plans/2026-04-27-record-strengthening-plan.md`
- 関連ADR: ADR-0004（start-work導入）, ADR-0005（ハンドオフファイル方式採用）, ADR-0006（継続的ADR検出ルール）
- スキル一覧: `README.md` のテーブル参照

## 完了済みタスク

- [x] サブプロジェクトA: 全12タスク完了（2026-04-27 〜 2026-04-28）
  - ADR-0004 / 0005 / 0006 作成・Accepted 化
  - `skills/start-work/` 新規作成（横断関心ゲートウェイ + 次手ナビゲーター）
  - `skills/session-handoff/` 新規作成（read/create/update/finalize の4操作）
  - `skills/decision-log/` 強化（検出トリガー一覧化、即時呼び出し誘導）
  - `.github/copilot-instructions.md` 更新（「作業の起点」「意思決定の即時記録」を常時ルール化）
  - `template/` 同期（sync-template.ps1 で再生成、差分ゼロ確認済み）
  - `CONTRIBUTING.md` / `README.md` 更新
  - `feature/record-strengthening` を master に `--no-ff` マージ済み、push 済み（`6bd8a08`）

## 進行中のタスク

なし（サブプロジェクトAは完全クローズ）

## 未着手のタスク

- [ ] **サブプロジェクトB: 機能ブロック駆動の設計＋仕様書分割**
  - 状態: 未着手。要件・スコープは未定義。
  - 残り: brainstorming スキルで要件と境界を明確化 → writing-plans → 実装。

## 既知のブロッカー・懸念

- サブプロジェクトBの具体的なゴール・スコープがまだ言語化されていない。次セッションの brainstorming で「機能ブロック駆動の設計とは何を指すか」「仕様書分割の粒度・配置・命名規則」「既存 `docs/specs/` との関係」をユーザーと擦り合わせる必要がある。
- `docs/conversation_log.md` が untracked のまま残っている（本作業外の既存ファイル）。扱いは未確認。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフファイルを read してくれる）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `README.md`（プロジェクト全体像）
   - `docs/principles.md`（5原則の現行版）
   - サブプロジェクトA plan `docs/plans/2026-04-27-record-strengthening-plan.md`（A の知見をBに転用するため）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -15` で直近の変更を確認
   - `git status` で untracked の `docs/conversation_log.md` の扱いを判断
4. **次に走らせるスキル**: `superpowers:brainstorming`（サブプロジェクトBの要件定義から開始）
5. **留意点**:
   - サブプロジェクトAで作った `start-work` / `session-handoff` / 強化版 `decision-log` を「使う側」として運用する初回となる。フローが期待通りか観察し、不備があれば修正タスクとして起票する。
   - master 直接作業は subagent-driven-development の red flag。サブプロジェクトBも feature ブランチ（例: `feature/spec-partitioning`）を切ること。
   - brainstorming 中に2案以上比較したらルール通り decision-log を即時呼び出すこと（ADR-0006）。

## 重要な意思決定の履歴

- ADR-0004: ワークフロー起点スキル（start-work）の導入（2026-04-27, Accepted）
- ADR-0005: セッション継続のためのハンドオフファイル方式の採用（2026-04-27, Accepted）
- ADR-0006: 意思決定の継続検出ルールの導入（2026-04-27, Accepted）
