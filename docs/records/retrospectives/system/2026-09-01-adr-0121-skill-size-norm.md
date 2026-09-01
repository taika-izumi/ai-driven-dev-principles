# Retrospective: SKILL.md のサイズ・分割規範の導入（ADR-0121）

- **Subject**: SKILL.md のサイズ警告と分割判断の型・例外テーブルの導入（Issue-0105）＋ merge-practice.md 導入文重複の解消（Issue-0111 同梱）
- **Branch**: feature/issue-0105-skill-size-norm（取り込み方式: マージコミット 2accc29）
- **Period**: 2026-08-31 〜 2026-09-01
- **Plan**: docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md
- **Spec**: 設計文書兼用 ADR のため独立 spec なし（docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md）
- **Related ADRs**: ADR-0121（新規・Accepted）、ADR-0116（退役判定＝存置）、ADR-0067 / 0080 / 0093 / 0107 / 0108 / 0117 / 0120（部分修正注記）
- **Facilitator**: メインエージェント (claude-opus-5)

## 1. 達成サマリ

- `scripts/build-dist.ps1` へ SKILL.md のサイズ計測を組み込み、目安値 20KB・例外テーブル・非ブロック警告を導入（`d38d43c`）。走査対象の収集直後に置き、通常実行と `-Check` の両モードで走ることを実測で確認
- `CONTRIBUTING.md` へ全シナリオ共通節「SKILL.md のサイズと分割」を新設し、5 シナリオのチェックリストへ配線（`d38d43c` / `a25110b`）。start-work シナリオは ADR-0116 決定 5 を維持して既存項目の文言拡張で受けた
- `pre-finalization-review` を references 型で分割（`64a9875`）。SKILL.md 42,643B → 17,539B、references 3 ファイル計 29,157B。確定点の初回提示が本文だけで履行できる状態を維持
- 分割に伴う参照の張り替え（skills 3 件・現用 spec 2 件。`2404e6c`）と ADR 8 件の注記・退役判定（`4bad0ad`）
- Issue-0111 を同梱解消し、version 0.1.17 で配布反映（`bee637d` / `b5b090d`）。Issue-0105 / 0111 を close し ADR-0121 を Accepted へ昇格（`fed3fd4`）

## 2. 課題（対象システム固有）

課題の抽出と分類まで（対策の設計・採否判断・ADR化は次サイクル。ADR-0021）。

**本サイクルの新規起票は 0 件**。抽出した候補はすべて既存 open 課題の再発・進展（下記 3 節）、または delta 型で worklog へ送った候補に振り分けられた。

ADR-0121 が明示的に受容したリスク 3 件（例外テーブル行の陳腐化検知が無い／`references/` が閾値対象外で退避による警告回避経路が残る／retrospective 19,042B が次の追記でほぼ確実に発火する）は、受容記載が正本にあるため課題化しない。

> 開発フロー課題の新規起票は 0 件のため `flow/` ファイルは作成していない。worklog 送りとした delta 型候補 2 件（起票なし。振り分け規則による。ADR-0056）: 確定前レビュー最終巡の記録が正本へ書かれないまま確定コミットされた件（`MakeAiInstructions-2026-09-01-03`）と、worklog の id 採番でストアの整形差により件数を誤読しかけた件。

## 3. 既存課題の再発・進展

- Issue-0106: 確定前レビュー第 5 巡の記録欠落を、改訂前退避 `r5` と確定コミットの件数算術のみで復元した。退避が掃除されていれば復元不能だった実測を追記（ADR-0031）
- Issue-0073: 計画の検証コマンド Expected（Step 12-5 の grep「0 件」）が実体と食い違い、実装時の逸脱判断で訂正した事例を追記。確定前レビュー 5 巡でも検出されなかった型である旨を併記（ADR-0031）
- Issue-0113: 実装工程 2 型のうち前倒し型を初めて完走した実測（全 13 タスク・逸脱記録 8 行・ユーザー介入 1 回・格下げ発火ゼロ）を、使い分け基準設計の一次材料として追記（ADR-0031）
- Issue-0100: 目安値が `build-dist.ps1` の定数 20000 と CONTRIBUTING の「既定 20KB」の 2 箇所に存在し、変更時に両方の更新を要する構造を追記（ADR-0031）
