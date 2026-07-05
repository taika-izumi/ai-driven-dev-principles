# Handoff: 記録プロセス規範一括対策サイクル完了・次サイクル待機

- **Branch**: master
- **Last Updated**: 2026-07-05 (Asia/Tokyo)
- **Status**: ready-for-next-cycle
- **Current Phase**: 記録プロセス規範一括対策サイクル完了（merge: 71d383c、retrospective 実施済み・Issue-0012/0013 起票、プラグイン更新済み）/ 次サイクル未着手

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。

直近サイクルは「記録プロセス規範の一括対策」（Issue-0009/0010/0011 の同時対策）。(1) ADR ドラフトは即時作成・コミットは論点収束チェックポイントまで遅延可（ADR-0030）、(2) 既存 open 課題の再発・進展は issue の「検討状況」へ一次記録（ADR-0031）、(3) 規範・ADR の判定条件はエージェントが観測・実行可能な事実で書く（ADR-0032）を規範化し、decision-log / retrospective / start-work スキル、CLAUDE.md、folder-structure §7、CONTRIBUTING に反映した。3本とも Accepted、対象 issue 3件 close、プラグイン更新済み。

## 関連ドキュメント

- 課題一覧（唯一のバックログ）: `docs/working/issues/README.md`（open 7件 / closed 6件）
- 直近サイクルの spec: `docs/current/specs/2026-07-05-record-process-norms-design.md`
- 直近サイクルの plan: `docs/working/plans/2026-07-05-record-process-norms-plan.md`
- 直近サイクルの ADR: ADR-0030/0031/0032（Accepted）
- 直近サイクルの retrospective: `docs/records/retrospectives/system|flow/2026-07-05-record-process-norms.md`
- 課題管理の規約: `docs/overview/folder-structure.md` §7（再発記録ルール追加済み）
- ADR インデックス: `docs/records/decisions/README.md`（0001〜0032）
- 原則: `docs/overview/principles.md` / Layer 2: `CLAUDE.md` / 拡張ルール: `CONTRIBUTING.md`

## 完了済みタスク

- [x] **記録プロセス規範一括対策サイクル**: Issue-0009/0010/0011 を ADR-0030/0031/0032 として規範化・実装。merge `71d383c`、プラグイン更新済み、retrospective 実施済み（フロー課題2件を Issue-0012/0013 として起票。ADR-0031 を同サイクル内で初適用し Issue-0002 の再発を検討状況へ記録）（2026-07-05）
- [x] **Issue-0004 対策サイクル**: 質問ツール表示特性への対処規範（ADR-0029）。merge `18e0c85`（2026-07-05）
- [x] **振り返り課題×issue管理統合サイクル**: ADR-0028。merge `b418d5d`（2026-07-05）

## 進行中のタスク

なし

## 未着手のタスク（バックログ。着手はユーザー判断）

バックログは `docs/working/issues/README.md` に一元化済み（open 7件）。

**エージェント所見: 優先上位（2026-07-05 サイクル担当エージェントの推奨。採否はユーザー判断）**

1. [ ] **Issue-0002**（system）: sync-template.ps1 の改行コード非決定性 — 再発2回目を記録済み（検討状況参照）。数行で即修可能、template 同期のたびにノイズが出るため早期解消を推奨
2. [ ] **Issue-0012**（flow）: 質問ツールタイムアウト時の自走基準がない — 節目操作（merge 等）が不在時に確認なしで実行される構造的リスク。今サイクルで実際に発生した事象

その他（上記より後で良いと判断）:

- [ ] Issue-0013（flow）: plan 検証手順と編集内容の整合観点 — 軽微。writing-plans 運用規範の1行追加程度
- [ ] Issue-0005 / 0006（flow）: 誤操作の即確定 / 計画網羅漏れ — 実害が散発的
- [ ] Issue-0003（system）: conversation_log.md の分類 / Issue-0008（system）: 旧型式 spec 8本の維持方針 — ユーザーの方針決めが主
- [ ] Theme C 問題A「プロジェクト固有用語集（ユビキタス言語）の仕組み」: 持ち越し（課題ではなく作業テーマのため issues 対象外。推奨フロー: `start-work` → `extend-guidelines` → brainstorming）
- [ ] （別件・低優先）ADR-0013 / ADR-0014 / ADR-0018: Proposed のまま

## 既知のブロッカー・懸念

- AskUserQuestion の表示特性（同一ターンのテキスト非表示）と無応答タイムアウト（約60秒で自走指示）: 前者は ADR-0029 で規範化済み、後者は Issue-0012 として起票済み（未対策）
- ADR-0023 の留意点（継続）: GitHub.com の Copilot コーディングエージェント（CLI 以外）がルート `CLAUDE.md` を読まない可能性
- `docs/conversation_log.md` は untracked のまま docs/ 直下に残置（Issue-0003。ユーザー判断待ち）

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフを read。Phase 1 で inbox 検知が走る）
2. **最初に確認すべきファイル**: 本ファイル、`docs/working/issues/README.md`
3. **次に走らせる作業（候補）**: 上記バックログからユーザーが選択（エージェント所見の優先順: Issue-0002 → 0012。着手はユーザー判断。必ず次サイクルではない）
4. **留意点**:
   - master 直接作業は禁止。テーマごとに feature ブランチを切る
   - **新規範（今サイクル導入）**: ADR ドラフトは即作成・コミットは収束チェックポイントまで遅延可（ADR-0030）/ 既存 open 課題の再発は issue「検討状況」へ1行追記（ADR-0031）/ 規範の判定条件はエージェントが観測可能な事実で書く（ADR-0032）
   - `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` を変更したら `scripts/sync-template.ps1` を実行（改行のみ差分が出たら git restore で回避し Issue-0002 に再発を追記）
   - skills/ を編集したらプラグイン更新（`/plugin marketplace update ai-driven-dev-principles`）まで反映されない
   - ADR-0019（決定のみ記載・遅延昇格）、ADR-0021（retrospective は課題抽出のみ）、ADR-0022（説明的な用語）、ADR-0024（選択肢＋推奨）、ADR-0028（課題の全件起票）、ADR-0029（質問の自己完結）を守る

## 重要な意思決定の履歴

- ADR-0032: 規範・ADR の判定条件はエージェントが観測・実行可能な事実で書く（2026-07-05, Accepted）
- ADR-0031: 既存 open 課題の再発・進展は issue ファイルの「検討状況」へ一次記録する（2026-07-05, Accepted）
- ADR-0030: ADR ドラフトは即時作成・コミットは論点収束チェックポイントまで遅延可能とする（2026-07-05, Accepted）
- ADR-0029: 質問ツールの表示特性への対処規範をモデル条件付きで追加（2026-07-05, Accepted）
- ADR-0028: 振り返り課題を issue 管理へ全件起票し、issues を system/flow フォルダに分割する（2026-07-05, Accepted）
- （ADR-0001〜0027 は `docs/records/decisions/README.md` 参照）
