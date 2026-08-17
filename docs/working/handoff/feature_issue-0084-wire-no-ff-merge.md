# Handoff: Issue-0084 マージ方式規範（--no-ff）の完了フロー配線

- **Branch**: feature/issue-0084-wire-no-ff-merge
- **Last Updated**: 2026-08-17 21:21 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装中（subagent-driven-development。Task 1 完了・Task 2 実装中）

## 作業の目的・背景

Issue-0084 の対策サイクル。retrospective スキルは「feature ブランチを master へ `--no-ff` マージした直後の実施」を前提とするが、マージを実行する完了フロー（`superpowers:finishing-a-development-branch`）にこの規範が配線されておらず、手動適用 7 サイクルの後、8 サイクル目（Issue-0093/0094）で fast-forward マージが再発した（push 前に `be8d6bd` でやり直し）。手動適用の連鎖は担い手のコンテキスト依存と実証されたため、規範を完了フローへ恒久配線する対策を設計・実装する。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0084-merge-mode-norm-not-wired-into-finishing-flow.md`
- 起票元: `docs/records/retrospectives/flow/2026-08-14-handoff-bloat-control.md` 課題#1
- 関連スキル: `skills/retrospective/SKILL.md`「いつ使うか」、`superpowers:finishing-a-development-branch`（外部プラグイン・直接改変不可）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検 ADR-0079/0099・評価可能性 ADR-0102・配布の執行点）

## 完了済みタスク

- [x] 対策の設計・ADR-0106 起票（Proposed・`44ec363`。設計文書兼用型。2026-08-17 完了）
- [x] 確定前レビュー: 3 観点フル 5 巡＋差分再確認 1 巡（レビュアー claude-opus-5。最終巡 24/24 解消・新矛盾 0）
- [x] plan Task 1: start-work 予防配線（2026-08-17 完了。品質レビューで ADR-0106 継承の欠落 2 件を検出し、ADR・SKILL・plan の 3 ファイル同期補正＋差分再確認済み）
- [x] plan Task 2: retrospective 検出配線（2026-08-17 完了。品質レビューで継承ギャップ 2 件＋写像欠落等 2 件を検出し 3 ファイル同期補足＋差分再確認済み。plan Step 2-6 期待値も追随更新）
- [x] plan Task 3: template 方式欄改定（2026-08-17 完了。品質レビュー指摘＝記入指示コメントの自己削除指示欠落を 1 句追加で解消＋差分再確認済み。ADR 変更なし）
- [x] plan Task 4: 現行仕様書の同期（2026-08-17 完了・`4ac30d8`。spec 準拠✅・品質✅ Approved。Minor 4 件は要約形の設計意図内として据え置き）
- [x] plan Task 5: 関連記録更新（2026-08-17 完了・`126791e`＋レビュー反映 `469acc1`。Issue-0101↔0008 相互参照を追加。ADR-0056 注記の時制指摘は一過性として受容＝Task 10 着地が条件）
- [x] plan Task 6: 本リポジトリ git 設定（2026-08-17 完了。mergeoptions=--no-ff / pull.ff=true を適用・読み直し確認）
- [x] plan Task 7: version bump 0.1.8→0.1.9（2026-08-17 完了。plugin.json/marketplace.json の 2 行のみ・コントローラー diff 検分で確認。コミットは Task 10）
- [x] plan Task 8: 配布物生成と執行点検査（2026-08-17 完了。build-dist/-Check×2 とも exit 0・目視 5 型で違反なし＝(1)〜(5) 半角括弧は既存 (a)〜(c) 前例と同型で適合裁定・BOM なし確認済み）
- [x] plan Task 9: スモーク検証（2026-08-17 完了。13 項目全合格。結果は plan 末尾に記録。実リポジトリ無傷をコントローラーが独立比較で確認）
- [x] plan Task 10: skills＋dist＋version 同一コミット `082e1fb`＋ADR-0106 最終突合（2026-08-17 完了。18 箇条＋同期 4 件すべて対応・漏れ 0・-Check×2 exit 0）

## 進行中のタスク

- [ ] **現在の作業**: retrospective 完了・cycle-reset 前
  - 状態: master へ `--no-ff` マージ済み（`6333928`・新配線の初適用で ff なし確認）。retrospective 記録作成・Issue-0098/0073 進展追記・インデックス行追加まで完了
  - 残り: cycle-reset → finalize → push（ユーザー確認）

## 未着手のタスク

- [ ] 実装・配布（`scripts/build-dist.ps1`・version bump 0.1.8→0.1.9・配布物目視・スモーク検証）
- [ ] Issue-0084 の faa9187 記載漏れ補正・start-work 旧 spec 乖離の flow 課題起票（ADR-0106 Consequences）
- [ ] ADR-0106 Accepted 昇格・Issue-0084 close → マージ・retrospective・cycle-reset

## 既知のブロッカー・懸念

- Issue-0098 のファイルが 10.7KB で目安 10KB を超過（本サイクルの反復レビュー実測を追記したため）。フォルダ昇格はユーザー判断で Issue-0098 対策サイクル着手時に持ち越し（2026-08-17 確認済み・再提案不要）
- `superpowers:finishing-a-development-branch` は外部プラグインのスキルであり直接改変できない。配線先の設計はこの制約が中心論点
- 配布対象ソースを変更したら執行点 4 手順（`CONTRIBUTING.md`）。スキル改定は version bump 必須（ADR-0090。現行 0.1.8）

## Post ラッパー消化記録

マイルストーンごとに Post ラッパーの消し込み結果を1行残す（ADR-0057）。形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照。

- 2026-08-17 ADR-0106 設計確定・spec 確定点 (c) 通過: ADR=0106 / worklog=`MakeAiInstructions-2026-08-17-07` / review=フル実施（claude-opus-5。3 観点×5 巡＋差分再確認 1 巡）
- 2026-08-17 実装 plan 作成・plan 確定点 通過: ADR=なし（ADR-0106 への追従のみで新規決定なし） / worklog=棄却（写像脱落 3 件は独立レビューの想定内で delta なし） / review=差分再確認（写像チェック 1 観点・claude-opus-5。推奨判定は偽・30 要件中欠落 0）
- 2026-08-17 セッション終了（実装着手前に区切り）: ADR=なし（新規決定なし） / worklog=棄却（plan 確定点以降はレビュー指摘反映のみで delta なし）
- 2026-08-17 plan Task 1 完了（start-work 予防配線）: ADR=なし（ADR-0106 の欠落補正 2 件のみで新規決定なし。補正は ADR 本文へ反映） / worklog=棄却（検出・修正とも既存の 2 段レビュー実施内で AI 挙動の delta なし）
- 2026-08-17 plan Task 2 完了（retrospective 検出配線）: ADR=なし（ADR-0106 の継承ギャップ補足のみで新規決定なし） / worklog=棄却（既知 Issue-0073 の再実例＝plan 期待値の陳腐化で、既存レビュー工程内で捕捉・delta なし）
- 2026-08-17 plan Task 3 完了（template 方式欄改定）: ADR=なし（ADR-0106 の意図内の 1 句追加のみ） / worklog=棄却（既存の 2 段レビュー実施内で捕捉・delta なし）
- 2026-08-17 plan Task 4 完了（現行仕様書の同期・`4ac30d8`）: ADR=なし（写像同期のみ） / worklog=棄却（指摘 Minor のみで delta なし）
- 2026-08-17 plan Task 5 完了（関連記録更新・`126791e`＋`469acc1`）: ADR=なし（記録更新のみ） / worklog=棄却（相互参照漏れは既存レビュー工程内で捕捉・delta なし）
- 2026-08-17 plan Task 6 完了（git 設定適用）: ADR=なし（ADR-0106 決定 3 の実施のみ） / worklog=棄却（機械的適用で delta なし）
- 2026-08-17 plan Task 7 完了（version bump）: ADR=なし（機械的更新のみ） / worklog=棄却（delta なし）
- 2026-08-17 plan Task 8 完了（配布物生成・執行点検査）: ADR=なし（生成のみ） / worklog=棄却（既存の執行点手順内で delta なし）
- 2026-08-17 plan Task 9 完了（スモーク 13/13）: ADR=なし（検証のみ） / worklog=棄却（plan 規定の検証で delta なし。squash 出力の Fast-forward 語の落とし穴は plan 特記事項へ記録済み）
- 2026-08-17 plan Task 10 完了・実装完了・ADR-0106 Accepted 昇格（`082e1fb`・`aac79a0`）: ADR=0106（昇格・Issue-0084 close） / worklog=棄却（既存の昇格手順内で delta なし） / cyclecheck=実施（指摘なし）
- 2026-08-17 master マージ（`6333928`）・retrospective 完了: ADR=なし（retrospective は採否を決めない） / worklog=棄却（総ざらい突合 13 マイルストーン未消化 0・新規 delta なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: `docs/working/plans/2026-08-17-adr-0106-merge-mode-wiring-plan.md`（確定済み・全 10 タスク）と設計の正本 ADR-0106
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ 実行方式（subagent-driven / inline）をユーザーに確認して実装開始。plan と ADR-0106 以外の経緯（レビュー 6 巡の詳細）は読み込み不要
3. 留意点: Task 1〜3 の skills 編集は dist・version と同一コミット（plan Task 10）。plan の old_string は編集前に実ファイルとの一致を必ず確認。完了後は ADR-0106 Accepted 昇格（サイクル全体整合検査つき）・Issue-0084 close → マージは新配線どおり `--no-ff`

## 重要な意思決定の履歴

- ADR-0106: マージコミット規範の再発防止＝予防・検出 2 層配線＋git 設定＋ff やり直し（2026-08-17 Proposed・`44ec363`）
