# Retrospectives

サブプロジェクトクローズ時に `retrospective` スキルで作成された振り返り記録の一覧。

## 運用規約（ADR-0011 / ADR-0021）

- **配置**: 課題の分類に応じて2フォルダに分割する（ADR-0021）
  - `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md` — メイン振り返り記録（対象システム固有の課題を含む）
  - `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md` — 開発フロー/ガイドライン関連の課題（フロー課題がある場合のみ作成）
  - YYYY-MM-DD は振り返り実施日、`<topic>` はサブプロジェクト識別子。同一サイクルは両フォルダで同名ファイル
- **粒度**: 1ファイル = 1サブプロジェクト（フォルダごと）
- **スコープ**: retrospective は課題の抽出と分類までにとどめる。対策の採否・設計・ADR化は行わない（次サイクルでユーザー判断。ADR-0021）
- **編集ポリシー**: 一度書いたら原則上書き禁止。例外は typo / リンク切れ修正のみ。事象や判断の改変は禁止
- **インデックス（本ファイル）**: **行追加のみ**、過去行の編集は禁止
- `flow/` フォルダ全体が、配布先システム開発repoではガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる
- 訂正が必要な場合は次回 retrospective 内で「前回振り返りの訂正」として記述する

ADR-0008 のスナップショット規約（spec / handoff 用）は適用しない。retrospective は時系列の学習素材として永続保管する。

## 一覧

| 実施日 | サブプロジェクト | 配置 | Branch | 備考 |
|--------|----------------|------|--------|------|

## 関連

- スキル: `skills/retrospective/SKILL.md`
- テンプレート: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）
- ADR-0021: retrospective を課題抽出に限定し、出力を system/flow に分割
- ADR-0010: 振り返りフェーズ導入
- ADR-0011: 振り返り出力の保管規約
