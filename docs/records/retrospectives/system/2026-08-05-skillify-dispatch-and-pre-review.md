# Retrospective: Issue-0033/0034 のスキル化（subagent-dispatch / pre-finalization-review）

- **Subject**: worklog パイプライン出口の 2 課題（Issue-0033 / 0034）のスキル authoring
- **Branch**: feature/skillify-subagent-dispatch-and-pre-review（merge済み: `da2d351`）
- **Period**: 2026-08-05（1 セッション）
- **Plan**: docs/working/plans/2026-08-05-dispatch-and-pre-review-skills.md（Task 1〜6 全完了）
- **Spec**: docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md
- **Related ADRs**: ADR-0070, ADR-0071, ADR-0072, ADR-0073（すべて Accepted）
- **Facilitator**: メインエージェント (claude-fable-5。設計前半は claude-opus-5[1m])

## 1. 達成サマリ

- 前サイクルが残した未決 2 点を解消: A 群の実装方式（規範文。フック機械注入は先行調査のうえ Issue-0047 へ繰り延べ。ADR-0070）、B 群発火判定の担保（5 行固定表の読み下ろし＋判定行。ADR-0071）、確定前レビューの発動条件（ユーザー指示のみ・提示は毎回。ADR-0072）— コミット `835db9d`
- 設計承認後のユーザーレビューで過剰適合の懸念が提起され、3 点を修正（ミューテーション 3 項目の適用例化・表構成の固定撤回・根拠/世代の記録と退役規範。ADR-0073）— コミット `d57c3b3`。退役検出の機械化は Issue-0048 へ
- `skills/subagent-dispatch/`・`skills/pre-finalization-review/` を新設し、`start-work` へ 2 箇所配線、README スキル一覧を更新（新規 2＋worklog 3 スキルの記載漏れ補完）— コミット `b544d3c`〜`766836e`
- Issue-0033 / 0034 を close し、台帳 `processed.jsonl` へ skillified 2 件を追記（31→33 行）。**`adopted` のまま 4 サイクル滞留していた両課題がパイプラインの出口へ到達** — コミット `8066080`

## 2. 課題（対象システム固有）

（新規なし）

> 開発フロー課題の新規起票なし。worklog 送りとした delta 型候補 1 件（起票なし。ADR-0056 の振り分け規則）:
> 「観測事例を規範へ昇格させる際、出所の偏り評価と退役経路をデフォルトで設計しない」— corrections として `MakeAiInstructions-2026-08-05-07` に記録済み。本 repo では ADR-0073 が受け皿として確定済みのため急がない。skillification_hint に worklog-skillify / extend-guidelines への定型観点化の候補を記載

## 3. 既存課題の再発・進展

- Issue-0044: 進展 2 点を「検討状況」へ追記（ADR-0031）。(a) 本環境の marketplace は directory 参照で、キャッシュ（2026-06-16 固定）に存在しない worklog スキルが available-skills 一覧に出ており、実行時はリポジトリ直読みの可能性が高い（同セッション検証不可の前提が本環境では崩れている可能性）。(b) 本サイクル新設の 2 スキルの availability は未確認（一覧がスキル作成前に更新されたもののため。次回 `/plugin marketplace update` 後に確認）
- Issue-0020: 再発 1 回を「検討状況」へ追記（ADR-0031）。plan コミット時、先にステージ済みだった handoff 更新が同一コミットへ混入（`git status` は確認していたがコミット対象の分離として扱わず。実害なし）
