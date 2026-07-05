# Handoff: 振り返り課題×issue管理統合サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 振り返り課題×issue管理統合サブプロジェクト完了（merge: b418d5d、retrospective 実施済み・新起票フロー初回実運用済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「振り返り課題と issue 管理の統合」（前サイクルのフロー課題 #4 対策）。retrospective で抽出した課題を**分類を問わず全件 `docs/working/issues/` に起票**する統合ルールと、issues の **system/（対象システム固有）・flow/（開発フロー/ガイドライン）フォルダ分割**を導入した（ADR-0028, Accepted）。採番は両フォルダ通し連番、インデックスはルート README 1つ（2セクション）。振り返り由来の課題は要約＋起票元参照で二重記述を避ける。既存課題は移行済みで、issues インデックスが唯一の課題一覧（現在 open 8件 / closed 2件）。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`
- 直近サイクルの spec: `docs/current/specs/2026-07-05-retrospective-issue-integration/`
- 直近サイクルの plan: `docs/working/plans/2026-07-05-retrospective-issue-integration-plan.md`
- 直近サイクルの ADR: ADR-0028（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system|flow/2026-07-05-retrospective-issue-integration.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0028）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **振り返り課題×issue管理統合サイクル**: merge `b418d5d`（2026-07-05）。ADR-0028 Accepted、Issue-0007 close。プラグイン更新済み。retrospective 実施済み（新起票フローの初回実運用として Issue-0009/0010 を起票）
- [x] （前サイクル）フォルダ構成定義: ADR-0025〜0027 Accepted（merge: a9c2fd1）

## 進行中のタスク

なし

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 8件）。参考の優先度観:

- [ ] **Issue-0002**（system）: sync-template.ps1 の改行コード非決定性 — 軽微・即修可能。毎回の同期で差分ノイズが出続けるため早めが楽
- [ ] **Issue-0009**（flow）: ADR ドラフトの起票タイミングと議論収束の緊張 — 今サイクルでも手戻りが発生。decision-log 規範の調整
- [ ] **Issue-0010**（flow）: 既存 open 課題の再発の記録方法が未定義 — 課題管理運用の残りピース（Issue-0004/0006 の再発記録が実施者依存になっている）
- [ ] Issue-0004 / 0005 / 0006（flow）: 質問ツール表示特性 / 誤操作の即確定 / 計画網羅漏れ（0004 と 0006 は今サイクルでも再発を確認）
- [ ] Issue-0003（system）: conversation_log.md の分類（ユーザー判断待ち） / Issue-0008（system）: 旧型式 spec 8本の維持方針
- [ ] Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 持ち越し（課題ではなく作業テーマのため issues 対象外。推奨フロー: `start-work` → `extend-guidelines` → brainstorming）
- [ ] （別件・低優先）ADR-0013 / ADR-0014 / ADR-0018: Proposed のまま

## 既知のブロッカー・懸念

- ユーザー環境では AskUserQuestion と同一ターンのテキストが表示されない（Issue-0004、再発確認済み）。説明が必要な相談はテキストのみのターン＋番号付き選択肢で行うこと
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read。Phase 1 で inbox 検知が走る）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`（課題バックログの一元管理先）
3. **次に走らせる作業（候補）**: 上記バックログからユーザーが選択
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **課題管理の新構造**: issues は `system/` `flow/` の2フォルダ＋ルート README（2セクション、通し採番）。振り返り課題は retrospective が全件起票する（ADR-0028）。議論由来の未決事項は decision-log の手順で起票
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（生成3インデックスは自動空生成。issues は2セクション形式で生成される）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない（今サイクルの Tech Notes 参照）
   - ADR-0019（決定のみ記載・Proposed→確定で Accepted）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票・system/flow 分割）を守る

## 重要な意思決定の履歴

- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- ADR-0027: テンプレート初期セットの基準を定義し、インデックス空生成を一般化（2026-07-04, Accepted）
- ADR-0026: inbox フォルダと organize-inbox スキルによる情報分類の仕組みを導入（2026-07-04, Accepted）
- ADR-0025: 情報の5分類体系を導入し、ドキュメント構成を全面再配置（2026-07-04, Accepted）
- （ADR-0001〜0024 は `docs/records/decisions/README.md` 参照）
