# Retrospective: <サブプロジェクト名>

- **Subject**: <サブプロジェクトの正式名>
- **Branch**: feature/<name>（merge済み: <merge-commit-sha>）
- **Period**: <開始日> 〜 <完了日>
- **Plan**: docs/working/plans/<...>
- **Spec**: docs/current/specs/<...>
- **Related ADRs**: ADR-NNNN, ADR-NNNN
- **Facilitator**: メインエージェント (<モデル名>)

## 1. 達成サマリ

<plan の主要マイルストーンを3〜5行の箇条書きで。課題詳細を将来単独で読むための最小のサイクル文脈（対応コミット SHA を併記）>

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。このファイルには**対象システム固有**の課題のみを記載し、開発フロー/ガイドライン課題は `flow/<同名>.md` に記載してここにはポインタを残す。

- **課題 #N**: <一文タイトル>
  - **事象**: <何が起きたか>
  - **原因**: <分析>
  - **影響**: <時間損失・スコープ影響など>
  - **起票**: Issue-NNNN（`../../working/issues/system/NNNN-<slug>.md`）

> 開発フロー課題 N 件は `flow/<同名>.md` 参照。worklog 送りとした delta 型候補 N 件（起票なし。振り分け規則による。ADR-0056）。

## 3. 既存課題の再発・進展

- Issue-NNNN: <「検討状況」へ追記した内容の要約>（ADR-0031）

## 4. (任意) Independent Review Notes

rubber-duck レビューをユーザー要求で実施した場合のみ本セクションを追加する。

- **指摘 #N**（優先度: high / medium / low）: <指摘内容>
  - **メインの応答**: 採用 / 部分採用 / 反論
  - **反映先**: <更新したセクション / 起票した Issue>
