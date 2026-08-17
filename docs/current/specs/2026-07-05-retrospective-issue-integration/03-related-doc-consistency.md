# ブロック03: related-doc-consistency — 周辺文書の整合

## 1. 対象ファイル

- `skills/decision-log/SKILL.md` — 「未決事項（open questions）の扱い / 起票」節
- `CONTRIBUTING.md` — シナリオ「未決事項・課題を記録するとき」「振り返りで抽出された課題に対策するとき」「振り返りスキル（retrospective）を変更するとき」
- `docs/records/retrospectives/README.md` — 運用規約（template 対象）
- `docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md` — 課題管理・データモデル節（スナップショット規約に従い書き換え）

## 2. 責務

課題管理の構造を参照するすべての既存文書を、ブロック01の新規約と一致させる。参照の不一致（旧パス `docs/working/issues/NNNN-<slug>.md` 直下形式）を残さない。

## 3. ファイル別の更新内容

### 3.1 skills/decision-log/SKILL.md

- 起票手順のパスを `docs/working/issues/system|flow/NNNN-<slug>.md` に更新する
- 分類の判断を1行追加する: 「対象システム固有の課題は `system/`、開発の進め方・スキル・原則・ガイドラインに関する課題は `flow/` に置く。議論由来の未決事項は大半が `system/`」
- 採番・フォーマットは課題管理定義（`docs/overview/issue-management.md`）の起票・採番の定義を参照する形とする（定義が見つからない場合はインデックス全体〈両セクション〉の最大番号+1 を既定として提案する）

### 3.2 CONTRIBUTING.md

- 「未決事項・課題を記録するとき」: 手順1の起票パスとインデックス操作を新構造に更新する
- 「振り返りで抽出された課題に対策するとき」: 前提を「課題は retrospective 実行時に issues へ起票済み」に書き換える。手順を「issues インデックス（または振り返りファイル）から対策する課題を選ぶ → 対策サイクル完了時に ADR を結論として close する」流れに更新する。チェックリストに「対策した issue を close したか」を追加する
- 「振り返りスキル（retrospective）を変更するとき」: 背景・チェックリストの記述に起票統合（ADR-0028）を反映する

### 3.3 docs/records/retrospectives/README.md

- 運用規約に1項目追加する: 「抽出した課題は retrospective 実行時に全件 `docs/working/issues/system|flow/` へ起票される（ADR-0028）。振り返りファイルの課題詳細が正、issue はライフサイクル管理を担う」

### 3.4 docs/current/specs/2026-07-04-project-folder-structure/01-folder-structure-definition.md

- 「課題（issue）管理」概要と「5. データモデル（課題ファイル）」節を新構造（system/flow フォルダ・起票元フィールド・2セクションインデックス・通し採番）へ書き換える（スナップショット規約: 差分節を作らず現在形で更新。変更理由は ADR-0028 参照を追記）

## 4. このブロック固有の制約・前提

- CLAUDE.md は「課題（`docs/working/issues/`）として起票」というルートパス参照のみのため**変更不要**（確認済み）
- `skills/organize-inbox/SKILL.md` のインデックス例示（`docs/working/issues/README.md`）はルート README を指しており**変更不要**
- `scripts/sync-template.ps1` は変更不要（ブロック01参照）
- CONTRIBUTING.md・retrospectives/README.md は template 対象。同期はブロック04

## 5. 関連 ADR

- ADR-0028 / ADR-0019（未決事項の分離 — 手順の更新対象）/ ADR-0008（spec のスナップショット規約 — 3.4 の書き換え根拠）
