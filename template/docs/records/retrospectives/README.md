# Retrospectives

サブプロジェクトクローズ時に `retrospective` スキルで作成された課題抽出記録の一覧。

## 運用規約

- **配置**: 課題の分類に応じて2フォルダに分割する
  - `docs/records/retrospectives/system/YYYY-MM-DD-<topic>.md` — メイン振り返り記録（対象システム固有の課題を含む）
  - `docs/records/retrospectives/flow/YYYY-MM-DD-<topic>.md` — 開発フロー/ガイドライン関連の課題（フロー課題がある場合のみ作成）
  - YYYY-MM-DD は振り返り実施日、`<topic>` はサブプロジェクト識別子。同一サイクルは両フォルダで同名ファイル
- **粒度**: 1ファイル = 1サブプロジェクト（フォルダごと）
- **スコープ**: retrospective は課題の抽出と分類までにとどめる。対策の採否・設計・ADR化は行わない（次サイクルでユーザー判断）
- **編集ポリシー**: 一度書いたら原則上書き禁止。例外は typo / リンク切れ修正のみ。事象や判断の改変は禁止
- **インデックス（本ファイル）**: **行追加のみ**、過去行の編集は禁止
- **課題の起票**: 抽出した課題は retrospective 実行時に全件 `docs/working/issues/system|flow/` へ起票される。振り返りファイルの課題詳細が正であり、issue は open/closed のライフサイクル管理を担う
- `flow/` フォルダ全体が、配布先システム開発repoではガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる
- **形式（2026-07-31 以降）**: 記録は「最小サイクル文脈（達成サマリ）＋課題詳細（事象/原因/影響）＋既存課題の再発・進展」で構成する。旧5観点の Went Well / Tech Notes は観点として廃止（知見は worklog パイプラインが捕捉）。rubber-duck レビューはユーザー要求時のみ（実施時に「Independent Review Notes」節を追加）。フロー課題は delta 型 / 構造観察型の振り分け規則に従う（詳細は `skills/retrospective/SKILL.md`）
- それ以前の記録（7セクション形式・非定型の簡易形式）は当時の形式のまま改変しない
- 訂正が必要な場合は次回 retrospective 内で「前回振り返りの訂正」として記述する

スナップショット規約（spec / handoff 用）は適用しない。retrospective は時系列の学習素材として永続保管する。

## 一覧

| 実施日 | サブプロジェクト | 配置 | Branch | 備考 |
|--------|----------------|------|--------|------|

## 関連

- スキル: `skills/retrospective/SKILL.md`
- テンプレート: `skills/retrospective/template.md`（メイン）/ `skills/retrospective/flow-template.md`（フロー）
