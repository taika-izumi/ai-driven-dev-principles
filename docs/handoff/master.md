# Handoff: AI駆動開発メタ・ガイドラインの段階的整備

- **Branch**: master
- **Last Updated**: 2026-05-01 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: サブプロジェクトA完了 / サブプロジェクトB完了 / サブプロジェクトC実装完了（master merge 済み、retrospective 未実施）

## 作業の目的・背景

本リポジトリ `taika-izumi/ai-driven-dev-principles` は、AIエージェント駆動開発のメタ・ガイドライン（5原則 + スキル群 + ADR）を整備するプロジェクト。プロジェクト全体は複数のサブプロジェクトに分割して段階的に進行している。

- **サブプロジェクトA「記録の強化」**: 完了済み。意思決定の即時検出ルール、ハンドオフファイル方式、起点スキル `start-work` を導入。
- **サブプロジェクトB「機能ブロック駆動の設計＋仕様書分割」**: 完了済み。`feature-block-design` スキル導入、原則2の適用範囲拡張、仕様書スナップショット規約導入。
- **サブプロジェクトC「振り返りフェーズ導入」**: 実装完了・master merge 済み。サブプロジェクト末尾で `retrospective` スキルを起動し、Done / Went Well / Struggled / Tech Notes / Improvement Drafts を抽出、採用提案を ADR ドラフト化する仕組みを導入した。**ただしドッグフーディング（C 自身に対する初回 retrospective）は未実施**。次セッションの最初のアクションとして実行する。

## 関連ドキュメント

- 原則: `docs/principles.md`（原則5に振り返り運用を追記済み）
- サブプロジェクトA plan: `docs/plans/2026-04-27-record-strengthening-plan.md`
- サブプロジェクトB plan: `docs/plans/2026-05-01-feature-block-design-plan.md`
- サブプロジェクトC plan: `docs/plans/2026-05-01-retrospective-phase-plan.md`
- サブプロジェクトC spec: `docs/specs/2026-05-01-retrospective-design.md`
- 関連ADR: ADR-0004〜0009（A/B 由来）, ADR-0010（振り返りフェーズ導入）, ADR-0011（振り返り出力の保管規約）, ADR-0012（ドメイン知識抽出は次サイクル課題）
- スキル一覧: `README.md` のテーブル参照（`retrospective` 追加済み）

## 完了済みタスク

- [x] サブプロジェクトA: 全12タスク完了（2026-04-27 〜 2026-04-28）— master merge 済み（`6bd8a08`）
- [x] サブプロジェクトB: 全14タスク完了（2026-05-01）— master merge 済み（`6e3a845`）
- [x] サブプロジェクトC: 全16タスク完了（2026-05-01、Task 17 = 初回 retrospective 実行を除く）— master merge 済み（`<merge-commit-sha>`、Task 16 で確定）
  - ADR-0010 / 0011 / 0012 作成・Accepted 化
  - `skills/retrospective/` 新規作成（SKILL.md + template.md）
  - `docs/retrospectives/` 初期化（README.md + .gitkeep）
  - `docs/principles.md` 原則5に振り返り運用1文追記
  - `.github/copilot-instructions.md` 「検証」セクションに振り返り運用1文追記
  - `skills/start-work/SKILL.md` Phase 2 マッピング表に retrospective 追加 + セッション終了処理に retrospective 起動提案を組込
  - `skills/decision-log/SKILL.md` 強トリガーに「振り返りで採用された改善提案」を追加
  - `template.manifest` / `template/` 同期（再実行で差分ゼロ確認済み）
  - `README.md` / `CONTRIBUTING.md` 更新

## 進行中のタスク

なし

## 未着手のタスク

- [ ] **サブプロジェクトC Task 17: 初回 retrospective の実行**
  - 対象: 本サブプロジェクトC 自身
  - 出力: `docs/retrospectives/<実施日>-retrospective-phase.md`
  - 期待される副成果物: 採用された Improvement Draft → ADR-0013 ドラフト起票（実装は別セッションで `start-work` から）
  - ドッグフーディングを兼ねるため、フォーマット・運用上の違和感を観察し Improvement Drafts に積極的に記録する

- [ ] **サブプロジェクトD（仮）**
  - 状態: 未定。retrospective 完了後の Improvement Drafts と ADR-0013 ドラフトを起点に決定する。

## 既知のブロッカー・懸念

- 初回 retrospective がまだ実施されていないため、振り返りスキルの実運用妥当性は未検証。
- `docs/conversation_log.md` および `docs/images/` が untracked のまま残っている（A 開始前から存在する作業外ファイル、扱い未確認）。

## 次セッション開始時のアクション

1. **最初に呼ぶスキル**: `start-work`（Phase 0 で本ハンドオフファイルを read してくれる）
2. **最初に確認すべきファイル**:
   - 本ファイル `docs/handoff/master.md`
   - `skills/retrospective/SKILL.md` と `skills/retrospective/template.md`（次に呼ぶスキルの仕様）
   - `docs/specs/2026-05-01-retrospective-design.md`（C の設計仕様）
   - `docs/plans/2026-05-01-retrospective-phase-plan.md`（C の plan、Task 17 詳細含む）
   - `docs/decisions/0010-introduce-retrospective-phase.md` / `0011-retrospective-storage-policy.md` / `0012-domain-knowledge-out-of-scope-for-c.md`
3. **最初に実行すべきコマンド**:
   - `git --no-pager log --oneline -20` で C の merge までを確認
   - `git status` で untracked ファイルの扱いを判断
4. **次に走らせるスキル**: `retrospective`（Task 17 = 初回ドッグフーディングを実行）
   - 対象サブプロジェクトの一文サマリ: 「サブプロジェクトC『AI駆動開発フローの末尾に振り返りフェーズを導入する』」
   - rubber-duck 呼び出しは Phase 3 で1回のみ
   - 採用された Improvement Draft があれば即 ADR ドラフト起票（ADR-0013〜）。実装は別セッションで `start-work` から開始する
   - 完了後、本ハンドオフファイルを再更新し master へ push する
5. **留意点**:
   - `retrospective` スキル自体はコミットを行わない。出力ファイル作成・ADR ドラフト起票・handoff 更新の各ステップで個別にコミットする
   - 出力規約は ADR-0011（時系列追記型・上書き禁止・インデックスは行追加のみ）。ADR-0008 のスナップショット規約（spec / handoff）とは別ポリシーであることに注意
   - ドメイン知識抽出は ADR-0012 により C のスコープ外。初回 retrospective の議題には載せず、Improvement Draft に「次サイクル候補」としてのみ記録する
   - master 直接作業は禁止。retrospective 出力 / ADR-0013 ドラフト / handoff 更新は新しい feature ブランチ（例: `feature/retro-c`）で行うこと
   - 検出した意思決定は ADR-0006（即時検出）に従い即ドラフト起票

## 重要な意思決定の履歴

- ADR-0004: ワークフロー起点スキル（start-work）の導入（2026-04-27, Accepted）
- ADR-0005: セッション継続のためのハンドオフファイル方式の採用（2026-04-27, Accepted）
- ADR-0006: 意思決定の継続検出ルールの導入（2026-04-27, Accepted）
- ADR-0007: 機能ブロック駆動の設計スキル（feature-block-design）の導入（2026-05-01, Accepted）
- ADR-0008: 仕様書のディレクトリ分割形式とスナップショット規約の採用（2026-05-01, Accepted）
- ADR-0009: 原則2「関心の分離」の適用範囲拡張（2026-05-01, Accepted）
- ADR-0010: 開発サイクル末尾の振り返りフェーズ導入（2026-05-01, Accepted）
- ADR-0011: 振り返り出力の保管規約（時系列追記型）（2026-05-01, Accepted）
- ADR-0012: ドメイン知識抽出は次サイクル課題（C 範囲外、ADR ベースのスコープ宣言）（2026-05-01, Accepted）
