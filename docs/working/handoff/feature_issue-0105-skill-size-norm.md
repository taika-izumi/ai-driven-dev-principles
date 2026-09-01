# Handoff: SKILL.md サイズ・分割規範の設計（Issue-0105）＋ merge-practice 導入文重複の解消（Issue-0111）

- **Branch**: feature/issue-0105-skill-size-norm
- **Last Updated**: 2026-09-01 (Asia/Tokyo)
- **Status**: completed
- **Current Phase**: サイクル完了。master へ `--no-ff` で取り込み（マージコミット `2accc29`）・push 済み。retrospective と cycle-reset は `master.md` 側で実施済み

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
- [x] 第 5 巡の記録欠落を計画へ補完（2026-09-01。`dc0323c`。退避 r5 との差分と `2b4458f` の件数から復元）
- [x] 実装工程の型を選択（2026-09-01。前倒し型＝タスク別独立レビューを置かず、`git diff` と逸脱記録行の自己検査＋格下げ安全弁）
- [x] 計画 Task 1〜8 完了（2026-09-01。課題起票・サイズ警告機構・CONTRIBUTING 共通節と配線・分割本体・参照張り替え・ADR 注記 8 件・Issue-0111）

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の実行（全 13 タスク中 Task 9 から）
  - 状態: Task 1〜8 完了（`d07efad` / `d38d43c` / `a25110b` / `64a9875` / `2404e6c` / `4bad0ad` / `bee637d`）。`skills/` の編集はすべて完了し、SKILL.md は 42,643B → 17,539B
  - 残り: Task 9（Issue-0099 追記）→ Task 10（spec 02 追従）→ **Task 11（例外テーブル登録値のユーザー承認。AI 単独で完了させない）** → Task 12（bump 0.1.17・執行点 4 手順）→ Task 13（close・Accepted 昇格・サイクル全体整合検査）
- [ ] **実装時の申し送り**
  - **不採用 2 件のうち 1 件（R1-a 該当性）は Task 5 で突合済み・不採用のまま維持**。残り 1 件（執行点手順 1 の解釈判断）の引き継ぎ先は Task 12 preamble の記述
  - 計画中の日付リテラルはすべて実装当日へ読み替える（規則は計画の宣言欄。歴史的事実の実測日は対象外）
  - Accepted 済み ADR 本文の改訂: **実施済み**（ADR-0116 Consequences へ存置判定＋改訂記録の計 2 行。`4bad0ad`）
  - Step 12-5 の Expected「0 件」は実体と食い違う（正当な入れ子括弧にもヒットする）。是正は Task 12 で適用する
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
- 2026-09-01 実装 Task 1〜8 完了（skills/ 編集の完了）: ADR=なし（確定済み計画の実行で新規の決定なし。ADR-0116 の改訂は decision-log の改訂記録規定に従い同 ADR 本文へ記載） / worklog=`MakeAiInstructions-2026-09-01-03`・`MakeAiInstructions-2026-09-01-04`

## 次セッション開始時のアクション

1. 本 handoff は役目を終えた（`completed`）。次サイクルの起点は `docs/working/handoff/master.md`
2. 本サイクルの経緯を追う場合: 実装計画 `docs/working/plans/2026-08-31-adr-0121-skill-size-norm-implementation.md`（各タスク末尾の逸脱記録行 11 件と末尾「確定前レビューの記録」5 巡分）→ 振り返り `docs/records/retrospectives/system/2026-09-01-adr-0121-skill-size-norm.md`
3. 留意点: 残余の分割候補は Issue-0115 / Issue-0116 が追跡する（例外テーブルへ暫定登録済み）

## 重要な意思決定の履歴

- ADR-0121: SKILL.md の肥大は build-dist のサイズ警告で検知し、分割判断の型と例外テーブルで制御する（ADR-0116 境界宣言は存置）（2026-08-31 Proposed・spec 確定点 (c) 通過済み・昇格は実装完了後）
