# Handoff: ADR 粒度・文章量の規範整備（Issue-0022 対処）

- **Branch**: feature/adr-granularity-and-size
- **Last Updated**: 2026-08-04 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: 実装完了・検証済み。残りは master への merge と retrospective

## 作業の目的・背景

Issue-0022（flow）への対処サイクル。ADR 起票時に「1つの ADR に収める決定の単位」を確認する観点がなく、束ねた大型 ADR が生まれやすい。2026-08-03 の retrospective でユーザーが再提起し、論点が3つに拡張された（粒度の確認観点 / Proposed への追記継続による主題ドリフト / 文章量の上限目安）。本サイクルは3論点すべてを対象とする。

brainstorming で以下を実測し、設計を確定した:

- **後から分割するコストは repo の様式で大きく変わる**。本 repo は ADR 単位の参照が中心で分割が軽い（決定の序数参照は5回）。LoopForAlpha は spec/plan/テストが決定単位でトレースするため序数参照が275回あり、分割は序数の振り直しを伴う
- **先送りで影響面が拡大する**。LoopForAlpha の ADR-0034 を参照するファイルは分割時点（起草4時間20分後）で10、Accepted 昇格時点（5日後）で24、2週間後で40へ増えた
- **文章量は肥大の指標にならない**。肥大時の ADR-0034 は 5,545文字だが、分割後4本の合計は 13,918文字（約2.5倍）に増え、かつ LoopForAlpha には 5,545文字より大きい正常な ADR が複数ある（最大 7,558）

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0022-adr-granularity-check.md`
- 本サイクルの ADR: ADR-0059（粒度の基準）/ ADR-0060（点検の契機）— コミット `9ec6682`、Status: Proposed
- 実例の worklog: 中央ストア `LoopForAlpha-2026-07-19-02`
- 改定対象 spec: `docs/current/specs/2026-04-25-record-strengthening-design.md`（§7 decision-log / §5.3 Post ラッパー）
- 起票元の振り返り: `docs/records/retrospectives/flow/2026-07-07-adr-rejected-status-path.md` 課題#1

## 完了済みタスク

- [x] Issue-0022 の実データ調査（本 repo 58本・LoopForAlpha 99本の ADR 実測、分割コミット `6ea5d48` の実コスト測定）（2026-08-03）
- [x] brainstorming（判定軸 / 点検契機 / 文章量の3論点を決着、設計をセクション単位で承認）（2026-08-04）
- [x] ADR-0059 / ADR-0060 起票・コミット `9ec6682`（実装完了後に Accepted へ昇格済み）
- [x] 実装計画の作成・コミット `3125995`（Task1〜7、grep 期待値つき）
- [x] 実装（Task1〜6）: `decision-log` 3箇所 `aa5b686` / `94ff0a9` / `4bfca43`、`start-work` `f5bdb8e`、仕様書 `2f0520c`、ADR 昇格＋Issue-0022 close `f76b13b`
- [x] 受入チェック（5項目すべて期待値どおり）と仕様書・実装の read-back 突合

## 進行中のタスク

- [ ] **現在の作業**: 完了処理（Task 7）
  - 状態: 受入チェック完了、handoff 更新中
  - 残り: master への merge 方針決定（`finishing-a-development-branch`）→ merge → `retrospective` → プラグイン更新をユーザーへ依頼

## 未着手のタスク

- [ ] master へ merge
- [ ] merge 直後に retrospective
- [ ] プラグイン更新の依頼（`/plugin marketplace update ai-driven-dev-principles`）

## 既知のブロッカー・懸念

- **プラグイン更新が必要になる**: skills/ を2件改定するため、実装後に `/plugin marketplace update ai-driven-dev-principles`（ユーザー操作）まで実行環境へ反映されない（ADR-0055）
- **テンプレート同期は不要**: `template.manifest` の対象は CLAUDE.md / principles.md / folder-structure.md / docs/inbox/README.md の4件のみ。今回はいずれも変更しない
- **付随して見つかった不整合（未対処）**: `CONTRIBUTING.md` の「start-work を変更するとき」シナリオに「テンプレート対象なので `sync-template.ps1` を実行する」とあるが、ADR-0016 により skills は manifest 対象外。本サイクルのスコープ外
- **仕様書の既存ドリフト**: `2026-04-25-record-strengthening-design.md` §7 は現行スキル本文より古い記述を含む。変更箇所のみ訂正し、全面訂正は Issue-0008 の方針決定に委ねる（前サイクルの前例に従う）
- **inbox 残置 3 件＋ conversation_log.md はユーザーが手動移動予定**。organize-inbox 提案は不要
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` 確認済み。本セッションのモデルは Opus 5

## Post ラッパー消化記録

- 2026-08-04 brainstorming 完了（設計承認）: ADR=0059/0060（コミット `9ec6682`。Accepted 昇格は実装完了後） / worklog=`MakeAiInstructions-2026-08-04-01`
- 2026-08-04 writing-plans 完了: ADR=なし（設計済み方針の計画化のみで新規の意思決定なし） / worklog=棄却（delta なし。計画作成は既存スキル手順どおりで friction・corrections とも発生せず）
- 2026-08-04 実装完了（plan Task1〜6）: ADR=0059/0060 を Accepted へ昇格（`f76b13b`。昇格前の粒度点検を実施し両件とも分割不要と判定） / worklog=棄却（delta なし。計画の各ステップが期待値どおり通り、手戻り・指示注入なし）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ファイル、ADR-0059 / ADR-0060、`docs/working/issues/flow/0022-adr-granularity-check.md`
2. 最初に実行すべきスキル: `start-work`（Phase 0 で本ハンドオフを read）→ `writing-plans`（設計は承認済みなので brainstorming の再実行は不要）
3. 留意点:
   - 設計は承認済み。ADR-0059/0060 の Decision セクションが設計の正
   - 実装後にプラグイン更新をユーザーへ依頼する（ADR-0055）
   - 本サイクル自身がドッグフーディング。ADR を追記するときは ADR-0060 の突合手順を適用する
   - コミット・マージのマルチライン文字列は `git commit -F <絶対パスの一時ファイル>`（Issue-0015）

## 重要な意思決定の履歴

- ADR-0059: ADR の粒度は「後から探しに来るときの問い」で決め、文章量は基準にしない（2026-08-03, Proposed）
- ADR-0060: ADR 粒度の点検を決定追記の手順に組み込み、昇格前の一括点検を受け皿とする（2026-08-03, Proposed）
