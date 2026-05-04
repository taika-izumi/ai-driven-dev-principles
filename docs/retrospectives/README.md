# Retrospectives

サブプロジェクトクローズ時に `retrospective` スキルで作成された振り返り記録の一覧。

## 運用規約（ADR-0011）

- **配置**: `docs/retrospectives/YYYY-MM-DD-<topic>.md`（YYYY-MM-DD は振り返り実施日、`<topic>` はサブプロジェクト識別子）
- **粒度**: 1ファイル = 1サブプロジェクト
- **編集ポリシー**: 一度書いたら原則上書き禁止。例外は typo / リンク切れ修正のみ。事象や判断の改変は禁止
- **インデックス（本ファイル）**: **行追加のみ**、過去行の編集は禁止
- 訂正が必要な場合は次回 retrospective 内で「前回振り返りの訂正」として記述する

ADR-0008 のスナップショット規約（spec / handoff 用）は適用しない。retrospective は時系列の学習素材として永続保管する。

## 一覧

| 実施日 | サブプロジェクト | Branch | Plan | Spec | Reviewer | 備考 |
|--------|----------------|--------|------|------|----------|------|
| 2026-05-01 | C: 振り返りフェーズ導入 | feature/retrospective-phase (merge: 49906e8) | [plan](../plans/2026-05-01-retrospective-phase-plan.md) | [spec](../specs/2026-05-01-retrospective-design.md) | rubber-duck | 初回ドッグフーディング。採用提案2件 → ADR-0013/0014 起票 |
| 2026-05-05 | Copilot CLI プラグイン配布化 | feature/plugin-distribution (merge: a92dc81) | （探索型・なし） | （なし） | rubber-duck | 採用提案1件 → ADR-0018 起票。ADR-0015→0017 連鎖が事実上の plan として機能 |

## 関連

- スキル: `skills/retrospective/SKILL.md`
- テンプレート: `skills/retrospective/template.md`
- ADR-0010: 振り返りフェーズ導入
- ADR-0011: 振り返り出力の保管規約
