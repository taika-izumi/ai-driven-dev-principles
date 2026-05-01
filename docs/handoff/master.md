# Handoff: AI駆動開発メタ・ガイドラインの段階的整備

- **Branch**: master
- **Last Updated**: 2026-05-01 15:58 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: サブプロジェクトA完了 / サブプロジェクトB完了 / サブプロジェクトC未着手（未定）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。プロジェクト全体は複数のサブプロジェクトに分割して段階的に進行している。

- **サブプロジェクトA「記録の強化」**: 完了済み。意思決定の即時検出ルール（ADR）と、セッション継続のためのハンドオフファイル方式、そしてそれらを束ねる起点スキル `start-work` を導入した。
- **サブプロジェクトB「機能ブロック駆動の設計＋仕様書分割」**: 完了済み。brainstorming と writing-plans の間で機能ブロック分割を行う新スキル `feature-block-design` を導入し、原則2「関心の分離」をエージェント設計だけでなくコード・ドキュメント・仕様書に拡張し、`copilot-instructions.md` に「分割設計」と「仕様書スナップショット規約」を常時ルールとして追加した。
- **サブプロジェクトC**: 未定。次セッションで brainstorming から開始する。

## 関連ドキュメント

- 原則: `docs/principles.md`（原則2は ADR-0009 により拡張済み）
- サブプロジェクトA plan: `docs/plans/2026-04-27-record-strengthening-plan.md`
- サブプロジェクトB plan: `docs/plans/2026-05-01-feature-block-design-plan.md`
- サブプロジェクトB spec: `docs/specs/2026-05-01-feature-block-design/`（00-overview.md + 01〜04 ブロック詳細）
- 関連ADR: ADR-0004（start-work導入）, ADR-0005（ハンドオフファイル方式採用）, ADR-0006（継続的ADR検出ルール）, ADR-0007（feature-block-design導入）, ADR-0008（仕様書ディレクトリ分割形式とスナップショット規約）, ADR-0009（原則2の適用範囲拡張）
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

- [x] サブプロジェクトB: 全14タスク完了（2026-05-01）
  - ADR-0007 / 0008 / 0009 作成・Accepted 化
  - `skills/feature-block-design/` 新規作成（適用要否判定 + 機能ブロック抽出 + 分割仕様書出力）
  - `docs/principles.md` 原則2を拡張（エージェント設計だけでなくコード・ドキュメント・仕様書にも適用）
  - `.github/copilot-instructions.md` に「タスク構造」追記（高凝集・疎結合・単一責任、feature-block-design 適用ルール）と「ドキュメント運用」セクション新設（スナップショット規約）
  - `skills/start-work/SKILL.md` の Phase 2 ナビゲーション表に新スキル追加
  - `template.manifest` / `template/` 同期（再実行で差分ゼロ確認済み）
  - `README.md` / `CONTRIBUTING.md` 更新
  - 設計仕様書を `docs/specs/2026-05-01-feature-block-design/` にディレクトリ分割形式で配置（ドッグフーディング）
  - `feature/feature-block-design` を master に `--no-ff` マージ済み、push 済み

## 進行中のタスク

なし（サブプロジェクトBは完全クローズ）

## 未着手のタスク

- [ ] **サブプロジェクトC（仮）**
  - 状態: 未定。要件・スコープは未定義。
  - 残り: 別セッションで brainstorming から開始。

## 既知のブロッカー・懸念

- サブプロジェクトCの具体的なゴール・スコープが未言語化。次セッションの brainstorming で何を扱うか擦り合わせる必要がある。
- `docs/conversation_log.md` および `docs/images/` が untracked のまま残っている（サブプロジェクトA 開始前から存在する作業外ファイル、扱い未確認）。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフファイルを read してくれる）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `README.md`（プロジェクト全体像）
   - `docs/principles.md`（5原則の現行版、原則2拡張済み）
   - `.github/copilot-instructions.md`（「ドキュメント運用」セクション含む現行版）
   - `skills/feature-block-design/SKILL.md`（B で導入された新スキルの仕様）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -15` で直近の変更を確認
   - `git status` で untracked ファイルの扱いを判断
4. **次に走らせるスキル**: `superpowers:brainstorming`（次サブプロジェクトの要件定義から開始）
5. **留意点**:
   - サブプロジェクトBで導入した `feature-block-design` スキルが実運用初回となる。中規模以上のシステムを設計する際は brainstorming 後に必ず使うこと（適用要否判定はスキル内で実施）。
   - 仕様書はスナップショット規約に従い、差分仕様書を作らず常に書き換えで更新すること（ADR-0008）。
   - master 直接作業は禁止。次サブプロジェクトも feature ブランチ（例: `feature/<topic>`）を切ること。
   - brainstorming 中に2案以上比較したらルール通り decision-log を即時呼び出すこと（ADR-0006）。

## 重要な意思決定の履歴

- ADR-0004: ワークフロー起点スキル（start-work）の導入（2026-04-27, Accepted）
- ADR-0005: セッション継続のためのハンドオフファイル方式の採用（2026-04-27, Accepted）
- ADR-0006: 意思決定の継続検出ルールの導入（2026-04-27, Accepted）
- ADR-0007: 機能ブロック駆動の設計スキル（feature-block-design）の導入（2026-05-01, Accepted）
- ADR-0008: 仕様書のディレクトリ分割形式とスナップショット規約の採用（2026-05-01, Accepted）
- ADR-0009: 原則2「関心の分離」の適用範囲拡張（2026-05-01, Accepted）
