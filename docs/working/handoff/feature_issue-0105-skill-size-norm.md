# Handoff: SKILL.md サイズ・分割規範の設計（Issue-0105）＋ merge-practice 導入文重複の解消（Issue-0111）

- **Branch**: feature/issue-0105-skill-size-norm
- **Last Updated**: 2026-09-01 07:10 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 新規開発・改修/実装計画を確定（plan 確定点 通過・実質収束）。次は実装工程の型を選んで実装へ

## 作業の目的・背景

主テーマは Issue-0105（flow）: スキルファイルにサイズの目安値・分割/移設の規約が無く、規範追加が常に既存スキルへの追記になる問題への対処。ADR-0120 実装で `skills/pre-finalization-review/SKILL.md` が 41,539B に達し、start-work の分割前サイズ（34,676B）を超過。前サイクルが予告した「分割判断の発生条件」が成立した状態。サイズ・分割の一般規範の設計と、（設計結果次第で）pre-finalization-review の分割実施を行う。

同梱テーマは Issue-0111（system）: `skills/start-work/references/merge-practice.md` 冒頭の導入文が移設条文の書き出しと重複（軽微・機能影響なし）。0105 の分割実施が配布物変更＋version bump を伴うため、同じく配布対象の 0111 を相乗りさせ、執行点 4 手順・bump を 1 回で済ませる（2026-08-31 ユーザー選択）。

## 関連ドキュメント

- 設計の正本: ADR-0121（`docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`。Proposed・コミット済み `5fe9afc`）
- 実装計画: `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`（全 13 タスク。plan 確定点の反復中で未確定）
- 本サイクルの乖離記録: `docs/working/issues/flow/0107-iterative-review-recommendation-divergence/`（事例 12・一般観察 4 を追記）
- 主課題: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`
- 同梱課題: `docs/working/issues/system/0111-merge-practice-duplicate-intro.md`
- 分割の先行実例: ADR-0115/0116（start-work の責務分割。34,676B → 14,456B）
- 類例規範: ADR-0087（handoff 側のサイズ実測トリガー。session-handoff スキル）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検・評価可能性・執行点 4 手順）

## 完了済みタスク

- [x] ADR-0121 設計確定・spec 確定点 (c) 通過（2026-08-31。フル 5 巡＋差分確認 1 巡＋機械検証 1 回・実質収束。ドラフトを `5fe9afc` でコミット）
- [x] 実装計画の作成（2026-09-01。`docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`。全 13 タスク・逸脱判断の宣言欄つき）
- [x] plan 確定点 通過（2026-09-01。フル巡 3＋差分確認巡 2＋機械検証 1 回・実質収束）

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の実行（全 13 タスク）
  - 状態: 計画は確定済み（plan 確定点 通過）。**実装工程の型（前倒し型 / タスク別独立レビュー往復）が未選択**で、これを決めてから実装系スキルへ delegate する
  - 残り: Task 1（課題 2 件起票）から Task 13（close と Accepted 昇格）まで順に実行。実装着手の直前に `skills/start-work/references/plan-deviation-defaults.md` を読み直す
- [ ] **実装時の申し送り**
  - **不採用 2 件あり**（実装時レビューへの引き継ぎ対象。`plan-deviation-defaults.md` 前処理 2. の突合対象）。所在は計画の「逸脱判断の既定」節と末尾「確定前レビューの記録」
  - 計画中の日付リテラルはすべて実装当日へ読み替える（規則は計画の宣言欄。歴史的事実の実測日は対象外）
  - Accepted 済み ADR 本文の改訂: 予定あり（ADR-0116 Consequences へ存置判定＋改訂記録の計 2 行。計画 Task 7 Step 7-8・未記入）
  - 改訂前退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-08-31-adr-0121-plan/` の `r1`〜`r5`（掃除は Issue-0106 の管轄・手動判断）。spec 確定点分は `.../2026-08-31-adr-0121-spec/r1`〜`r6`

## 未着手のタスク

- [ ] 実装計画の実行（全 13 タスク）。実装工程の型（前倒し型 / タスク別独立レビュー往復）は plan 確定後にユーザーが選ぶ
- [ ] 配布反映: 執行点 4 手順＋version bump 0.1.16 → 0.1.17 を 1 回で実施（計画 Task 12。Issue-0111 同梱）
- [ ] Issue-0105 / Issue-0111 の close と ADR-0121 の Accepted 昇格（計画 Task 13。サイクル全体整合検査・粒度の点検を含む）

## 既知のブロッカー・懸念

- **配布元は `dist/`**（ADR-0082）。`skills/` 編集後は `scripts/build-dist.ps1` で再生成し生成物も同じコミットへ。ルート `.agents/plugins/marketplace.json` も生成物
- **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
- **確定点では 2 型分類の凍結＋確定前レビュー提示**（ADR-0080/0107/0117/0120）。本サイクルの 2 確定点（spec (c)・plan）は通過済みで、いずれも規範改定型・観点分離 4 体で実施した。実装中に設計変更へ至れば新規 ADR で spec 確定点 (c) が再び生じうる
- **計画作成・実装着手の直前に `skills/start-work/references/plan-deviation-defaults.md` を読む**（ADR-0119）
- inbox 未整理 3 件＋conversation_log 未追跡はユーザーが手動移動予定（organize-inbox 提案不要）。`git add` はディレクトリ巻き込み禁止・pathspec 付き（Issue-0020）

## Post ラッパー消化記録

- 2026-08-31 設計承認・ADR-0121 Proposed 起票・レビュー 1 巡目完了: ADR=0121 / worklog=棄却（計測誤り delta はレビュー工程が捕捉済み・スキル化余地なし）
- 2026-08-31 ADR-0121 設計確定・spec 確定点 (c) 通過: ADR=0121 / worklog=棄却（パッチ増設の棘輪は前置 1 規範が発火済み・共通節誤判断はレビュー工程が捕捉済み） / review=フル実施（claude-opus-5・5 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-09-01 実装計画の確定・plan 確定点 通過: ADR=なし（ADR-0121 の決定範囲内の計画作成で新規の決定なし） / worklog=`MakeAiInstructions-2026-09-01-01` / review=フル実施（claude-fable-5・1 巡）＋フル実施（claude-sonnet-5・2 巡）＋差分再確認（claude-sonnet-5・2 巡）＋機械検証（1 回・実質収束）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff → 実装計画 `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`（末尾「確定前レビューの記録」に 4 巡分の経緯）→ 設計の正本 ADR-0121（`docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`。コミット済み `5fe9afc`）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ 実装工程の型を選んでから実装系スキル（`superpowers:subagent-driven-development` または `executing-plans`）へ delegate。**delegate の直前に `skills/start-work/references/plan-deviation-defaults.md` を読み直す**（ADR-0119）
3. 留意点: 計画は確定済み。実装時レビューの前処理で突合すべき**不採用 2 件**がある（所在は計画の宣言欄）。計画中の日付リテラルはすべて実装当日へ読み替える。レビュアーのモデルは作成側と変える（本サイクルの作成側は claude-opus-5、レビュアーは claude-sonnet-5 を使用）。規範推奨と実選択の乖離が 2 回あり Issue-0107 へ記録済み

## 重要な意思決定の履歴

- ADR-0121: SKILL.md の肥大は build-dist のサイズ警告で検知し、分割判断の型と例外テーブルで制御する（ADR-0116 境界宣言は存置）（2026-08-31 Proposed・spec 確定点 (c) 通過済み・昇格は実装完了後）
