# Retrospective: Issue-0076 対策（破壊的検証の委譲制約）

- **Subject**: 破壊的検証をサブエージェントへ委譲するときの隔離・パス・状態比較の制約導入
- **Branch**: feature/issue-0076-dispatch-isolation（merge済み: faa9187）
- **Period**: 2026-08-15 〜 2026-08-15
- **Plan**: docs/working/plans/2026-08-15-adr-0093-destructive-verification-dispatch.md
- **Spec**: docs/current/specs/2026-08-05-dispatch-and-pre-review-skills-design.md（既存 spec の更新。本サイクルの設計正本は ADR-0093）
- **Related ADRs**: ADR-0093（新規 Accepted）、ADR-0066 / ADR-0071（部分修正追記）
- **Facilitator**: メインエージェント (claude-fable-5 → claude-opus-5[1m]。セッション途中でモデル切替)

## 1. 達成サマリ

- 構造的解決の先行調査（ADR-0039 の手順）を実施し、ツールネイティブの隔離実行機構だけでは塞ぎきれないと判定したうえで、委譲プロンプト側の制約と併置する方針を決定（ADR-0093 Proposed、コミット `9ebc984`）
- spec 確定点 (c) でフル 3 観点の確定前レビューを実施（レビュアーは claude-opus-5。敵対的・実装整合性・仕様適合）。Critical 1・Major 9・Minor 14 の実証付き指摘を得て設計を改稿。検出器を `git status` 前後比較から内容ハッシュ比較主体へ変更し、委譲側の受け取り時独立確認を決定へ格上げした
- 実装（8 タスク）で `subagent-dispatch` B 群を 6 条件 12 項目へ拡張し、判定行へキーを追加、既存の並列書き換え行にも絶対パス項目を波及。spec・`powershell-pitfalls.md`・`pre-finalization-review` 手順 4・ADR-0066/0071 を同期し、`dist/` 再生成と plugin 0.1.4 への bump を実施（コミット `198b925`）
- Accepted 昇格前のサイクル全体整合検査（ADR-0092）を実施。観点 3（数値の整合）で ADR-0066 追記の項目数誤記を検出・是正し、ADR-0093 を Accepted へ昇格、Issue-0076 を close（コミット `84577cc`）

## 2. 課題（対象システム固有）

対象システム固有の新規課題は抽出されなかった。本サイクルの変更はガイドライン体系そのものへの改定であり、抽出された課題はすべて開発フロー/ガイドライン側に属する。

> 開発フロー課題 2 件は `flow/2026-08-15-issue-0076-dispatch-isolation.md` 参照。worklog 送りとした delta 型候補 1 件（起票なし。振り分け規則による。記録済みエントリ: `MakeAiInstructions-2026-08-15-02`）。

## 3. 既存課題の再発・進展

- Issue-0044: 本セッション開始時、`start-work` が 0.1.2、`session-handoff` 以降が 0.1.3 のキャッシュから読み込まれ、同一セッション内でスキルのバージョンが混在した（前サイクルの配布反映がユーザー側で未実施だったため）。「検討状況」へ追記
- ADR-0092（サイクル全体整合検査）: 前サイクルの初回自己適用は指摘 0 件だったが、本サイクルの 2 度目の適用で観点 3 が実際に誤記 1 件を検出した。検査が機能した実績として記録（課題ではない）
