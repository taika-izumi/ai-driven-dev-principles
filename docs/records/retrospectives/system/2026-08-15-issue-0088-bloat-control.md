# Retrospective: Issue-0088 対策（Issue 肥大化抑制）

- **Subject**: Issue-0088 対策 — Issue など handoff 以外の成果物の肥大化抑制（課題管理定義の新設）
- **Branch**: feature/issue-0088-artifact-bloat-survey（merge済み: e4590bf）
- **Period**: 2026-08-15 〜 2026-08-15
- **Plan**: docs/working/plans/2026-08-15-issue-bloat-control-plan.md
- **Spec**: なし（ADR-0094〜0098 が設計文書を兼ねる型。正本は docs/overview/issue-management.md）
- **Related ADRs**: ADR-0094, ADR-0095, ADR-0096, ADR-0097, ADR-0098
- **Facilitator**: メインエージェント (claude-fable-5)

## 1. 達成サマリ

- 配布先実体験（マネジメント用途での Issue 肥大化）を起点に Issue-0088 を起票し、枠組みを「用途別対応でなく成長様式への対策」と決定（ADR-0094。起票 `f2ac91f`、設計 `8972765`）
- 配置モデル（検討中フォルダ集約・close 移設）・昇格条件の観測可能化・4 役割/番号接頭辞体系・粒度規範（1 Issue＝1 問題）・境界原則（挙動＝スキル/構造定義＝文書・複写禁止）を ADR-0095〜0098 で確定
- spec 確定点・plan 確定点の両方でフルレビュー（計 7 レビュアー・claude-opus-5）を実施。発火経路 0 本・README 名称矛盾・依拠先不在などを設計段階で捕捉し反映
- 実装（`6b5c419`）: 課題管理定義 `docs/overview/issue-management.md` 新設（template 配布 5 ファイル目）・folder-structure §7 早見表化（189→122 行）・スキル 4 本へフック配線（フォールバック付き）・CONTRIBUTING 3 箇所・仕様スナップショット 10 ファイル追従。plugin 0.1.5（`ea4d2e9`）
- ADR-0094〜0098 Accepted 昇格・Issue-0088 close（`c655868`。サイクル全体整合検査: 指摘なし）。Issue-0089/0090 を分離起票（`7f9f1dc`）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル）。このファイルには**対象システム固有**の課題のみを記載し、開発フロー/ガイドライン課題は `flow/<同名>.md` に記載してここにはポインタを残す。

- **課題 #1**: 完了済み移行 spec のひな形パス言及が課題管理定義の分離後と乖離した
  - **事象**: `docs/current/specs/2026-08-07-distributed-artifact-generation/05-source-migration.md` 153 行目の「書式例（folder-structure.md の課題ファイルひな形…）」が、ひな形の `docs/overview/issue-management.md` への移動により現状と乖離した（実装全体の最終レビューが検出）
  - **原因**: 完了済み・一回限りの移行手順 spec は「現在の正」のスナップショット追従の焦点から外れがちで、本サイクルの追従対象 10 ファイルの選定（旧規則文言の grep とレビュー指摘）にも掛からなかった
  - **影響**: 実害小（完了済み手順内の検証項目の記述が古くなるのみ）。ただし「完了済み spec の維持方針」という一般形は Issue-0008 と隣接する
  - **起票**: Issue-0091（`../../working/issues/system/0091-completed-migration-spec-stale-after-split.md`）

> 開発フロー課題の新規起票は 0 件（既存課題の再発 2 件は下記 3 節で追記済み）。起票を見送った構造観察型 1 件: decision-log 152 行目の昇格条件要約は定義側改定時に同時更新が必要（意図された設計であり ADR-0096 の配線節に記録済み・実害未観測のため監視点に留める）。worklog 送りとした delta 型候補 1 件（再レビュー委譲時に古い前提値を渡し誤判定を誘発。起票なし。振り分け規則による）。

## 3. 既存課題の再発・進展

- Issue-0073: 再発を「検討状況」へ追記（計画 Step 9-4 の期待値 0 件が、レビュー反映で追加された経過措置条項を織り込んでおらず、実行時に 2 件へ訂正）
- Issue-0056: 再発を「検討状況」へ追記済み（`fa7c184`。期待値の二重計上と死んだ grep 枝を plan 確定前レビューの写経実行が捕捉。worklog `MakeAiInstructions-2026-08-15-05`）
