# Handoff: フォルダ構成定義サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 01:00 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: フォルダ構成定義サブプロジェクト完了（merge: a9c2fd1、retrospective 実施済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「開発プロジェクトのフォルダ構成定義」。情報の性質（更新様式 × ライフサイクル）による**5分類体系**（オリエンテーション / 現在の正 / 進行中の作業 / 追跡型の記録 / 参照知識）を導入し、docs を全面再配置した（ADR-0025）。分類に迷う情報の受け皿として **inbox ＋ organize-inbox スキル**を新設し（ADR-0026）、テンプレート初期セットの基準とインデックス空生成の一般化を実装した（ADR-0027）。定義本体は `docs/overview/folder-structure.md`（template 対象）。本リポジトリ自身も新レイアウトへ移行済み（ドッグフーディング）。

## 関連ドキュメント

- フォルダ構成の定義本体: `docs/overview/folder-structure.md`
- 直近サイクルの spec: `docs/current/specs/2026-07-04-project-folder-structure/`
- 直近サイクルの plan: `docs/working/plans/2026-07-04-project-folder-structure-plan.md`
- 直近サイクルの ADR: ADR-0025 / ADR-0026 / ADR-0027（すべて Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system/2026-07-05-project-folder-structure.md`・`flow/` 同名
- 課題管理: `docs/working/issues/README.md`（Issue-0001 は closed）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0027）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **フォルダ構成定義サイクル**: merge `a9c2fd1`（2026-07-04）、体裁 fix `0f95f9b`。ADR-0025/0026/0027 Accepted。プラグイン更新で organize-inbox 反映済み。retrospective 実施済み（2026-07-05、system/flow 2フォルダ形式の初適用）
- [x] （前サイクル）選択肢＋推奨提示規範: ADR-0024 Accepted
- [x] （前サイクル）Claude Code 対応（Layer 2 一本化）: ADR-0023 Accepted

## 進行中のタスク

なし

## 未着手のタスク（バックログ。着手はユーザー判断）

- [ ] **フロー課題 #4「retrospective の課題バックログと issue 管理の関係が未定義」への対策**: 優先度高め（課題管理の運用が本格化する前に設計した方が二重管理を防げる）。起点: `docs/records/retrospectives/flow/2026-07-05-project-folder-structure.md`
- [ ] **システム課題 #2「sync-template.ps1 の改行コード非決定性」への対策**: 軽微・即修可能（WriteAllLines が CRLF で書き出し、LF 正規化されたコミット内容と食い違い、実行のたびに変更扱いになる）。起点: `docs/records/retrospectives/system/2026-07-05-project-folder-structure.md` 課題 #2
- [ ] その他のフロー課題3件（質問ツールの表示特性の規範化 / 誤操作の即確定 / 横断変更の計画網羅漏れ）とシステム課題 #1（conversation_log.md の分類）: 同上の振り返りファイル参照
- [ ] **Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」**: 持ち越し。新設した `docs/overview/`（用語集の置き場は確保済み）に管理スキルを設計する（規模: 中）。推奨フロー: `start-work` → `extend-guidelines` → brainstorming
- [ ] 前2サイクル（選択肢＋推奨規範 / Claude Code 対応）の retrospective: 未実施のまま持ち越し（実施するかはユーザー判断）
- [ ] （別件・低優先）ADR-0013 / ADR-0014: Proposed のまま

## 既知のブロッカー・懸念

- organize-inbox の実運用は未経験。初回実行時の挙動を次回 retrospective で確認したい
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（システム課題 #1。ユーザーの記録ファイルのためユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read。Phase 1 で inbox 検知が新たに走る）
2. **最初に確認すべきファイル**: 本ファイル、`docs/records/retrospectives/flow/2026-07-05-project-folder-structure.md`（課題バックログ）
3. **次に走らせる作業（候補）**: 上記バックログからユーザーが選択。推奨はフロー課題 #4（課題管理×retrospective 統合の設計）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **新レイアウト**: specs=`docs/current/specs/`、plans/handoff/issues=`docs/working/`、ADR/retrospective=`docs/records/`、原則=`docs/overview/principles.md`。配置判断は `docs/overview/folder-structure.md` に従い、迷ったら `docs/inbox/`
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（生成3インデックスは自動空生成）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - ユーザー環境では AskUserQuestion と同一ターンのテキストが表示されないことがある。説明は独立したテキストターンで送る
   - ADR-0019（決定のみ記載・未決は課題へ・Proposed→確定で Accepted）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）を守る

## 重要な意思決定の履歴

- ADR-0027: テンプレート初期セットの基準を定義し、インデックス空生成を一般化（2026-07-04, Accepted）
- ADR-0026: inbox フォルダと organize-inbox スキルによる情報分類の仕組みを導入（2026-07-04, Accepted）
- ADR-0025: 情報の5分類体系を導入し、ドキュメント構成を全面再配置（2026-07-04, Accepted）
- ADR-0024: 質問・意思決定要求時に選択肢と推奨を提示する規範を追加（2026-06-16, Accepted）
- ADR-0023: Layer 2 を CLAUDE.md に一本化し Claude Code / Copilot CLI 両対応（2026-06-16, Accepted）
- （ADR-0001〜0022 は `docs/records/decisions/README.md` 参照）
