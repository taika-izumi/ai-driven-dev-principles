# Handoff: SKILL.md サイズ・分割規範の設計（Issue-0105）＋ merge-practice 導入文重複の解消（Issue-0111）

- **Branch**: feature/issue-0105-skill-size-norm
- **Last Updated**: 2026-08-31 22:16 (Asia/Tokyo)
- **Status**: paused
- **Current Phase**: 新規開発・改修/設計確定済み（spec 確定点 (c) 通過）。次は writing-plans

## 作業の目的・背景

主テーマは Issue-0105（flow）: スキルファイルにサイズの目安値・分割/移設の規約が無く、規範追加が常に既存スキルへの追記になる問題への対処。ADR-0120 実装で `skills/pre-finalization-review/SKILL.md` が 41,539B に達し、start-work の分割前サイズ（34,676B）を超過。前サイクルが予告した「分割判断の発生条件」が成立した状態。サイズ・分割の一般規範の設計と、（設計結果次第で）pre-finalization-review の分割実施を行う。

同梱テーマは Issue-0111（system）: `skills/start-work/references/merge-practice.md` 冒頭の導入文が移設条文の書き出しと重複（軽微・機能影響なし）。0105 の分割実施が配布物変更＋version bump を伴うため、同じく配布対象の 0111 を相乗りさせ、執行点 4 手順・bump を 1 回で済ませる（2026-08-31 ユーザー選択）。

## 関連ドキュメント

- 主課題: `docs/working/issues/flow/0105-skill-md-size-growth-no-norm.md`
- 同梱課題: `docs/working/issues/system/0111-merge-practice-duplicate-intro.md`
- 分割の先行実例: ADR-0115/0116（start-work の責務分割。34,676B → 14,456B）
- 類例規範: ADR-0087（handoff 側のサイズ実測トリガー。session-handoff スキル）
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検・評価可能性・執行点 4 手順）

## 完了済みタスク

（なし）

## 進行中のタスク

- [ ] **現在の作業**: ADR-0121 設計確定（spec 確定点 (c) 通過・実質収束）
  - 状態: 確定前レビュー反復が終了（フル 5 巡＋差分確認 1 巡＋機械検証 1 回・実質収束）。ADR-0121 ドラフトをコミットし spec 確定点 (c) を通過
  - 残り: writing-plans で実装計画を作成（分割実施・build-dist 改修・CONTRIBUTING 共通節・課題 2 件起票・0111 修正・執行点 4 手順・bump 0.1.17）→ plan 確定点の提示へ
  - 改訂前退避: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-08-31-adr-0121-spec/r1`〜`r6`（掃除は Issue-0106 の管轄・手動判断）
  - Accepted 済み ADR 本文の改訂: 予定あり（ADR-0116 Consequences へ存置判定＋改訂記録の計 2 行。実装時・未記入）
  - 不採用 8 件の主要判断は ADR-0121 本文へ吸収済み（25KB 回帰 = CA4・基準ファイル/references 別閾値 = CA5・当初のシナリオ内配置 = CA7・テーブル上限/頻度別閾値/陳腐化検知の受容 = 決定 2〜3 と Consequences・0111/決定 6 の粒度判断 = Consequences/決定 6）。plan 作成時に CA・受容記述を実装時レビューの引き継ぎ材料として参照する

## 未着手のタスク

- [ ] Issue-0105: brainstorming → （必要なら feature-block-design 判定）→ 設計確定 → ADR → 実装（規範の常設先の改定＋pre-finalization-review の分割判断）
- [ ] Issue-0111: merge-practice.md 導入文の絞り込み修正（条文本体は触らない）
- [ ] 配布反映: 執行点 4 手順＋version bump（0.1.16 → 次版）を 1 回で実施

## 既知のブロッカー・懸念

- **配布元は `dist/`**（ADR-0082）。`skills/` 編集後は `scripts/build-dist.ps1` で再生成し生成物も同じコミットへ。ルート `.agents/plugins/marketplace.json` も生成物
- **ガイドライン拡張時は過剰適合点検＋新設の評価可能性が必須**（ADR-0079/0099/0102）
- **確定点では 2 型分類の凍結＋確定前レビュー提示**（ADR-0080/0107/0117/0120）。本テーマは規範文の新設を含むため規範改定型（観点分離 4 体）になる見込み
- **計画作成・実装着手の直前に `skills/start-work/references/plan-deviation-defaults.md` を読む**（ADR-0119）
- inbox 未整理 3 件＋conversation_log 未追跡はユーザーが手動移動予定（organize-inbox 提案不要）。`git add` はディレクトリ巻き込み禁止・pathspec 付き（Issue-0020）

## Post ラッパー消化記録

- 2026-08-31 設計承認・ADR-0121 Proposed 起票・レビュー 1 巡目完了: ADR=0121 / worklog=棄却（計測誤り delta はレビュー工程が捕捉済み・スキル化余地なし）
- 2026-08-31 ADR-0121 設計確定・spec 確定点 (c) 通過: ADR=0121 / worklog=棄却（パッチ増設の棘輪は前置 1 規範が発火済み・共通節誤判断はレビュー工程が捕捉済み） / review=フル実施（claude-opus-5・5 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と ADR-0121（`docs/records/decisions/0121-skill-md-size-trigger-and-split-norm.md`。設計の正本・コミット済み `5fe9afc`）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本 handoff を read）→ `superpowers:writing-plans` で実装計画作成（出力先は `docs/working/plans/`）。**作成直前に `skills/start-work/references/plan-deviation-defaults.md` を読み、計画へ逸脱判断の宣言欄を置く**（ADR-0119）
3. 留意点: plan 確定点はレビュー済み上流（ADR-0121・実質収束）からの写像通常型 → 初回体数の既定は 1 体 4 観点兼務。決定 5 の張り替え (a)〜(e) は plan 作成時に全数走査で確定。配布反映は執行点 4 手順＋bump 0.1.17 を 1 回（Issue-0111 同梱）。session-handoff/decision-log の課題 2 件起票と ADR-0116 追記 2 行・Issue-0099/0105 の記録類更新も plan のタスクに含める

## 重要な意思決定の履歴

- ADR-0121: SKILL.md の肥大は build-dist のサイズ警告で検知し、分割判断の型と例外テーブルで制御する（ADR-0116 境界宣言は存置）（2026-08-31 Proposed・spec 確定点 (c) 通過済み・昇格は実装完了後）
