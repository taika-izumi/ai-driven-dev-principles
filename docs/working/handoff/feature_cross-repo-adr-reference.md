# Handoff: 配布物における ADR 参照表記の規範化（Issue-0067 対策）

- **Branch**: feature/cross-repo-adr-reference
- **Last Updated**: 2026-08-07 19:36 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張 / brainstorming 完了・feature-block-design 起動前

## 作業の目的・背景

ガイドラインの配布先プロジェクトへ届く成果物が、本リポジトリ固有の ADR 番号を無修飾（`ADR-NNNN`）で参照している。配布先では同じ表記がその配布先自身の ADR を指すため、参照は無関係な決定を指し、配布先が ADR を書き進めれば番号は必ず重複する。

実測（2026-08-07）: `template/` に 19 箇所（2 ファイル）、プラグイン配布の `skills/` に 159 箇所（16 ファイル・ユニーク 46 本）。合計 178 箇所（出現回数。行数ではない）。

本サイクルの目的は、配布物における ADR 参照の表記規則を定め、配布物全体へ適用すること。既存の ADR-0068 が課題番号について `<repo>#Issue-NNNN` 形式のクロスリポジトリ修飾を定めており、ADR 番号への同等の規則が無い状態を埋めることになる（ADR-0068 の拡張とするか置換とするかは未決定）。

## 関連ドキュメント

- 対象課題: `docs/working/issues/system/0067-distributed-artifacts-reference-repo-local-adr-numbers.md`
- 本サイクルの決定（いずれも Proposed・未コミット）:
  - ADR-0081 `docs/records/decisions/0081-distributed-artifact-adr-reference-scope.md`（対象範囲＝配布物全体 190 箇所）
  - ADR-0082 `docs/records/decisions/0082-distribute-generated-artifact-not-source.md`（注記を除去した生成物を配布する体制）
  - ADR-0083 `docs/records/decisions/0083-provenance-notation-convention-enforced-by-generator.md`（記法規約 R1〜R4 と、生成器が検査を兼ねる設計）
- 前提となる既存決定: ADR-0027（テンプレート初期セットの基準・「説明文は保持」）/ ADR-0016（skills を template から除外しプラグイン配布へ）/ ADR-0068（クロスリポジトリの課題参照）/ ADR-0073（規範項目に根拠と世代を添える）
- 拡張ルール: `CONTRIBUTING.md` / 生成スクリプト: `scripts/sync-template.ps1` / 同期対象定義: `template.manifest` / プラグイン定義: `.claude-plugin/marketplace.json`

## 完了済みタスク

- [x] 事象の実測と原因の切り分け（2026-08-07 完了）— `template/` は ADR-0027 の「説明文は保持」の残余、`skills/` は ADR-0016 で template 同期の検査対象外
- [x] Issue-0067 起票（2026-08-07 完了）
- [x] ADR-0081 ドラフト作成・設計収束にあわせ書き直し（2026-08-07。Proposed・未コミット）
- [x] 参照の全件型別分類（2026-08-07 完了）— `skills/` 171（括弧単独 82 / 括弧内混在 51 / 出所リスト 22 / 本文溶け込み 12 / フェンス内 4）、`template/` 19（7/3/8/1/0）
- [x] 配布経路の実機確認（2026-08-07 完了）— マーケットプレイス登録は `"source":"directory"` で repo 直下を指し、プラグインキャッシュにリポジトリ全体 743KB の完全コピーが存在する
- [x] brainstorming 完了・設計承認（2026-08-07）— 配布体制（ADR-0082）と記法規約（ADR-0083）をユーザー承認

## 進行中のタスク

- [ ] **現在の作業**: `feature-block-design` による spec 作成
  - 状態: 設計方針は承認済み。構成要素が 3 つ以上（生成器 / 記法規約 / 検査 / 移行 / CONTRIBUTING 配線）のため分割仕様書の作成対象
  - 残り: `docs/current/specs/2026-08-07-<topic>/` にディレクトリ分割形式で spec を作成し、過剰適合点検ブロックを spec へ記録する

## 未着手のタスク

- [ ] 過剰適合点検（ADR-0079。spec 確定前に 4 観点。**引用元のゲート脱落も見る**。Issue-0066）
- [ ] spec 確定点 (a) の通過 → 確定前レビューの提示（ADR-0080）→ 結果を消化記録へ `review=` で記録
- [ ] ADR-0081/0082/0083 の粒度点検・Accepted 昇格・コミット
- [ ] 実装計画の作成（手作業 約 31 箇所 ＋ 生成器・検査の実装をどう分割・検証するか）
- [ ] マーケットプレイスの `source` にサブディレクトリを指定できるかの実機検証（構造 A の成立条件。不成立なら構造 B へフォールバック）
- [ ] 配布物への適用と `dist/` 生成
- [ ] 隣接論点の採否: `docs/overview/folder-structure.md` 149/151/153 行の他リポジトリ実課題名の例示

## 既知のブロッカー・懸念

- **`skills/` は二重の読者を持つ**: 配布先向けの文書であると同時に、本リポジトリ内での作業指示でもある。修飾形式が本リポジトリでの可読性を下げないかが設計上の制約（ADR-0081 Consequences）
- **`skills/` 側に機械的な検出経路が無い**: `sync-template.ps1` の検査対象は `template/` に限られる。規則違反の再発防止をどこに置くかが論点になる
- **`docs/working/issues/README.md` を変更済み** — 空インデックス生成対象のため、コミット前に `scripts/sync-template.ps1` の実行が必要（本ファイルは行データが除去されるため template の出力自体は変わらない見込みだが、実行して差分を確認すること）
- **inbox 残置 3 件＋ `docs/conversation_log.md` はユーザーが手動移動予定**。organize-inbox 提案は不要。`git add <ディレクトリ>` で巻き込まないこと（Issue-0020）
- master 由来の申し送り（PowerShell の検索・集計の落とし穴、`Add-Content` 禁止、プラグイン update の必要性など）は `docs/working/handoff/master.md` の「既知のブロッカー・懸念」を参照

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照（確定点を通過したマイルストーンには `review=` を併記する。ADR-0080）。

- 2026-08-07 brainstorming 完了（配布物の記録参照の扱いを設計）: ADR=0081（設計収束にあわせ書き直し）・0082（配布体制）・0083（記法規約と検査） / worklog=`MakeAiInstructions-2026-08-07-13`・`MakeAiInstructions-2026-08-07-14`（確定点ではないため `review=` は省略。spec 確定点 (a) は `feature-block-design` 完了時）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: `docs/working/issues/system/0067-distributed-artifacts-reference-repo-local-adr-numbers.md` と `docs/records/decisions/0081-distributed-artifact-adr-reference-scope.md`
2. 最初に実行すべきコマンド/スキル: `start-work` → `extend-guidelines`（本サイクルはガイドライン拡張シナリオ）
3. 留意点:
   - ガイドライン拡張には過剰適合点検が必須（ADR-0079。CONTRIBUTING.md「全シナリオ共通: 過剰適合の点検」）。**引用元の規範にゲート（条件節）がある場合、それを落としていないかも見ること**（Issue-0066）
   - spec 確定点・plan 確定点を通過したら確定前レビューを提示し、結果を消化記録へ `review=` で書く（ADR-0080）。提示では推奨の由来と反対材料も併記する
   - 本サイクルの成果物は規範文書（`CONTRIBUTING.md` / `skills/` / `docs/overview/`）の改定を含むため、確定点での推奨判定は真になる見込み

## 重要な意思決定の履歴

- ADR-0081: 配布先へ届く成果物の記録参照問題は、template とプラグイン配布の skills の両方を対象に扱う（2026-08-07・Proposed）
- ADR-0082: 保守者向けの根拠注記はソースに残し、注記を除去した生成物を配布する（2026-08-07・Proposed）
- ADR-0083: 配布対象ソースの根拠注記は位置で規約化し、生成器が規約適合の検査を兼ねる（2026-08-07・Proposed）
