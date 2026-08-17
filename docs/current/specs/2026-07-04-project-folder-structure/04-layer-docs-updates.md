# ブロック04: layer-docs-updates — Layer 1/2 文書と README の更新

## 1. 対象ファイル

- `CLAUDE.md`
- `docs/overview/principles.md`（ブロック06 で `docs/principles.md` から移動した後の内容更新。本ブロックは内容変更の仕様を定義する）
- `CONTRIBUTING.md`
- `README.md`

## 2. 責務

フォルダ構成定義を Layer 1（原則）・Layer 2（行動指示）・人間向け文書（CONTRIBUTING / README）に反映する。定義の詳細は `docs/overview/folder-structure.md`（ブロック01）に置き、各文書は要点と参照のみを持つ（二重管理の禁止）。

## 3. インターフェース（文書別の変更内容）

### CLAUDE.md

- 「ドキュメント運用」セクションを書き換え:
  - ドキュメントの配置と文書運用は `docs/overview/folder-structure.md` の分類基準（5分類）・配置判断基準・仕様書の運用規約に従う旨を記載（仕様書運用の 4 箇条〈スナップショット規約・書き換え更新・「なぜは ADR に、今どうなっているかは仕様書に」・ディレクトリ分割形式のパス `docs/current/specs/YYYY-MM-DD-<topic>/`〉の正本は同文書「7. 仕様書の運用規約」）
  - 配置に迷った場合は `docs/inbox/` に置き、organize-inbox スキルで処理する旨を追加
- 「検証」セクションの retrospective 起動箇条は起動を課す配線のみとする（出力先・スコープ・課題分類の定義は `retrospective` スキルが正）
- superpowers スキル（writing-plans 等）のデフォルト出力パスを上書きする指示を追加: 実装計画は `docs/working/plans/`、設計文書はプロジェクトの仕様書規約（`docs/current/specs/`）に従う
- プロジェクト固有の参照を含めない（template 対象の制約。フォルダパスはガイドライン自体の規約なので可）

### docs/overview/principles.md

- 原則3（コンテキスト管理）に情報分類の一文を追加する: 「プロジェクトの情報は、その性質（更新様式とライフサイクルの長さ）に基づいて分類・配置する」（表現は実装時に調整可。ツール非依存を維持）

### CONTRIBUTING.md

- 「シナリオ: 未決事項（open questions）を記録するとき」を「シナリオ: 未決事項・課題を記録するとき」に改訂: 分離先を課題ファイル（`docs/working/issues/`）に変更し、フォーマット・ライフサイクル記述を課題運用（ブロック01/03 と同一内容）に置き換える
- 「シナリオ: ADRを記録するとき」内の open-questions 参照を課題管理へ更新
- 各シナリオ内のパス表記（`docs/principles.md` → `docs/overview/principles.md`、`docs/specs/` → `docs/current/specs/`、`docs/retrospectives/` → `docs/records/retrospectives/` 等）を更新
- レイヤー表の Layer 1 ファイルパスを `docs/overview/principles.md` に更新

### README.md

- スキル一覧テーブルに `organize-inbox` を追加（1行サマリー付き）
- リポジトリ構成・ドキュメント配置に言及している箇所を新レイアウトに更新
- フォルダ構成定義（`docs/overview/folder-structure.md`）への案内を追加

## 4. サブ機能 / 内部構成

なし。

## 5. データモデル

なし。

## 6. このブロック固有の制約・前提

- 定義の本体はブロック01 のドキュメントに一元化し、本ブロックの各文書には**要点＋参照リンクのみ**書く（判断基準の全文を CLAUDE.md に複製しない）
- CLAUDE.md のカテゴリ構成（システム設定 / AI駆動開発ガイドライン）と日本語統一を維持
- CLAUDE.md / principles.md は template 対象のため、変更後にブロック05 の同期が必要

## 7. 関連 ADR

- ADR-0025（5分類体系・課題統合）
- ADR-0026（inbox 規範）
- ADR-0023（Layer 2 = CLAUDE.md 一本化）
- ADR-0019（未決事項の分離規律）
