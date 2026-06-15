# Handoff: Claude Code 対応（Layer 2 を CLAUDE.md に一本化）

- **Branch**: master
- **Last Updated**: 2026-06-16 01:19 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: Claude Code 対応サブプロジェクト完了・master merge & push 済（ADR-0023 Accepted）/ 今サイクルの retrospective 未実施（ユーザー判断待ち）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

今サイクルは「GitHub Copilot CLI 向けに作ったガイドライン/スキルを Claude Code でも使えるようにする」対応。調査の結果、プラグイン梱包（`.claude-plugin/`）とスキル（`skills/<name>/SKILL.md`）は元々 Claude Code ネイティブ形式で両ツール互換と判明し、対応が必要なのは **Layer 2 指示ファイルのみ**だった。`CLAUDE.md`（リポジトリルート）は Copilot CLI と Claude Code の双方が既定で読むため、Layer 2 をこれ1つに一本化した（ADR-0023）。

## 関連ドキュメント

- 今サイクルの spec: `docs/specs/2026-06-16-claude-code-support-design.md`
- 今サイクルの plan: `docs/plans/2026-06-16-claude-code-support-plan.md`
- 今サイクルの ADR: `docs/decisions/0023-unify-layer2-into-claude-md.md`（Accepted）
- 原則: `docs/principles.md`
- 拡張ルール: `CONTRIBUTING.md`
- ADR インデックス: `docs/decisions/README.md`（0001〜0023）
- 未決事項: `docs/open-questions.md`
- スキル一覧: `README.md`

## 完了済みタスク

- [x] **Claude Code 対応（Layer 2 を CLAUDE.md に一本化）**: master merge & push 済（merge: `1a3ff1b`）。ADR-0023 Accepted
  - ルート `CLAUDE.md` を新設（旧 `.github/copilot-instructions.md` の内容を中立化して移設）。`.github/copilot-instructions.md` は廃止
  - タイトル `# プロジェクトエージェント指示`、前提条件節を両ツール（GitHub Copilot CLI / Claude Code）向けに中立化。本文（5原則の行動指示）は不変
  - `template.manifest`（エントリ＋コメント）、`template/`（sync 実行で CLAUDE.md 化）、`README.md`（「Claude Code へのインストール」節追加・Layer 2 表記更新）、`CONTRIBUTING.md`、`skills/start-work`・`skills/extend-guidelines`、`.claude-plugin/plugin.json` を更新
  - 動作確認: `sync-template.ps1` は冪等、ルート CLAUDE.md と `template/CLAUDE.md` は完全一致、生きたファイルに `copilot-instructions` 残留参照ゼロ
- [x] （前サイクル）Theme A「retrospective スキル改善」: ADR-0021 Accepted
- [x] （前サイクル）Theme B「ADR記述規律」: ADR-0019 Accepted
- [x] （前サイクル）Theme C 問題B「AIの言葉遣いの明確性規範」: ADR-0022 Accepted

## 進行中のタスク

なし

## 未着手のタスク

- [ ] **今サイクル（Claude Code 対応）の retrospective**: 未実施。master merge 直後の振り返り（フロー/ガイドライン課題の抽出）。実施するかは次セッションのユーザー判断。実施する場合 ADR-0021 後の新フロー（課題抽出のみ・system/flow 2フォルダ出力）のドッグフーディング機会
- [ ] **Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」**: 前サイクルからの持ち越し。ハンドオフ等の成果物で使うドメイン用語を一元管理する用語集の置き場・作成タイミング・管理スキルを設計する（規模: 中）。推奨フロー: `start-work` → `extend-guidelines` → brainstorming
- [ ] （別件・低優先）ADR-0013（knowledge-distillation 新設）/ ADR-0014（親ディレクトリ先行確認）: Proposed のまま

## 既知のブロッカー・懸念

- ADR-0023 の留意点: `.github/copilot-instructions.md` を廃止したため、GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性がある。その用途が必要になれば AGENTS.md 併設の再検討が要る（ADR-0023 の「派生する将来 ADR 候補」）
- `docs/open-questions.md` に未解決1件: template同期の非対称性（`sync-template.ps1` はADRインデックスを空生成するが `docs/retrospectives/README.md` は repo固有行ごとコピーする）。小改善候補
- `docs/conversation_log.md` は untracked のまま（ユーザーのフィードバック記録。コミット対象外）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `docs/decisions/0023-unify-layer2-into-claude-md.md`（今サイクルの決定）
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -5` で merge `1a3ff1b` を確認
   - `git status` で untracked（conversation_log）の扱いを判断
4. **次に走らせる作業（候補）**:
   - 今サイクル（Claude Code 対応）の retrospective を実施するかユーザーに確認（任意）
   - もしくは Theme C 問題A「用語集の仕組み」に着手（`extend-guidelines` → brainstorming）
5. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **Layer 2 = ルート `CLAUDE.md`**（ADR-0023）。`.github/copilot-instructions.md` はもう存在しない
   - `CLAUDE.md` / `principles.md` / template対象スキルを変更したら `scripts/sync-template.ps1` を実行
   - **ADR-0019**（決定のみ記載・未決は open-questions・Proposed→確定で Accepted）、**ADR-0021**（retrospective は課題抽出のみ・system/flow 2フォルダ）、**ADR-0022**（説明的な用語を使う）を守る

## 重要な意思決定の履歴

- ADR-0023: Layer 2 を CLAUDE.md に一本化し Claude Code / Copilot CLI 両対応（2026-06-16, Accepted）
- ADR-0022: AIの言葉遣いの明確性規範を Layer 2 に追加（2026-06-15, Accepted）
- ADR-0021: retrospective を課題抽出に限定し出力を system/flow に分割（2026-06-15, Accepted）
- ADR-0020: responding-to-user 必須化の廃止 + ask-user-enforcer 撤去（2026-06-15, Accepted）
- ADR-0019: ADR記述規律 — 決定のみ記載・未決事項の分離・承認の遅延昇格（2026-06-15, Accepted）
- （ADR-0001〜0018 は `docs/decisions/README.md` 参照）
