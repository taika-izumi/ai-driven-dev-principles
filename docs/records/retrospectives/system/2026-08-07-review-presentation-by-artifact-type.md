# Retrospective: 確定前レビューの提示規則の導入

- **Subject**: 確定前レビューの提示点の一般化と、成果物の性質に応じた推奨順位の規範化（Issue-0062 対策 / ADR-0080）
- **Branch**: feature/review-recommendation-by-artifact-type（merge済み: `afed223`）
- **Period**: 2026-08-07（単一セッション）
- **Plan**: `docs/working/plans/2026-08-07-review-presentation-by-artifact-type.md`
- **Spec**: なし（ADR-0080 が設計文書を兼ねる型。CONTRIBUTING.md「spec を作らない拡張」）
- **Related ADRs**: ADR-0080（新規・Accepted）、ADR-0067 / ADR-0072 / ADR-0075（いずれも部分修正を追記・Accepted 維持）
- **Facilitator**: メインエージェント (claude-fable-5 → claude-opus-5)

## 1. 達成サマリ

- Issue-0062（確定前レビューの次手提示が成果物の性質を問わず中立で、安全網の無い成果物でも非推奨側に倒れる）に対し、ADR-0072 の骨格（発動はユーザー指示のみ・提示は毎回）を維持したまま提示規則を定めた（ADR-0080・`437083e` → `75bc098` → `d046a37` で Accepted）
- 提示点を「spec 確定点（3 通り）＋ plan 確定点」へ一般化し、成果物の変更対象に未レビューの規範・手順文書の新設・改定が含まれる場合はフルレビューを推奨側に置く片方向規範を実装（`32ad810` / `5be7aa0`）。判定規則の正本は `start-work` Phase 2 に置き、`pre-finalization-review` は実施手順と適用例を担う（`9919a21`）
- 判定材料の記録経路を `session-handoff` の read / update / finalize に配線し、記録が無い場合は安全側（未レビュー扱い）へ倒す設計とした（`c943422` / `9d4f27b`）。`feature-block-design` の「writing-plans 直行を推奨」文言と `decision-log` の ADR コミット経路にも提示のフックを置いた（`9bb54c2` / `29a5088` / `e5475e2`）
- 設計段階で採用しかけた軽量レビュー枝（spec レビュー済みの写像 plan への単観点突合）は、独立レビューで根拠の崩壊が実証されたため撤回した（直接実測ゼロの機構は規範化しない。ADR-0080 Considered Alternatives 6）
- 5 段階のレビューを実施: 設計に 3 観点フル（Critical 5/Major 18/Minor 16）、計画に 2 本（Major 2/Minor 1、Critical 2/Major 5/Minor 3）、実装の各タスクに spec 準拠＋品質、実装全体に最終レビュー（Major 4/Minor 7）。すべて反映済み（`4b5e35c` / `db1c14d` / `e5475e2`）
- Issue-0062 を close。Issue-0006 は対象外判定の根拠を追記して open 維持（`913f1ca`）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。

本サイクルで抽出した課題はいずれも開発フロー/ガイドライン側に属し、対象システム固有の課題は無し。

> 開発フロー課題 2 件は [`flow/2026-08-07-review-presentation-by-artifact-type.md`](../flow/2026-08-07-review-presentation-by-artifact-type.md) 参照。worklog 送りとした delta 型候補 1 件（起票なし。ADR-0056 の振り分け規則。worklog `MakeAiInstructions-2026-08-07-11` に記録済み）。

## 3. 既存課題の再発・進展

- Issue-0042（検出器の検出力）: **再発**。実装計画に書いた検証コマンドが、節見出しの存在だけを見て中核段落の欠落を検出できない状態だった。写経実行レビュー（正しい状態と 28 の欠陥状態を構築して両方に実行）で実証（ADR-0031）
- Issue-0020（コミット巻き込み）: **再発**。サブエージェントが `git commit` にパス指定を付け忘れ、委譲元管理の handoff ファイルを巻き込んだ。`git reset --soft` で是正され、reflog で検証済み（ADR-0031）
- Issue-0056（計画の検証コマンドの実行可能性検査）: **進展**。「正しい実装後の状態と、意図的に不完全な状態の両方を構築して全検証コマンドを実行する」方式の有効性を実測（24 コマンド × 28 欠陥状態で Critical 2・Major 5 を検出）
- Issue-0057（サブエージェント報告識別子の検証）: **進展**。全コミットハッシュを `git cat-file -t` で検証し、サブエージェントが申告した `git reset --soft` の是正も reflog で裏取りした。運用として機能することを確認
- Issue-0044（スキル改定後の `/plugin marketplace update`）: **進展**。実装着手前にユーザーが実行し、以降のスキル供給が正しく行われた
