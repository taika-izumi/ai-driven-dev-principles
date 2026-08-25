# Handoff: Codex（OpenAI Codex CLI）対応

- **Branch**: feature/codex-support
- **Last Updated**: 2026-08-25 16:10 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装（subagent-driven-development・plan Task 4 完了）

## 作業の目的・背景

本ガイドライン（Layer 1 原則 / Layer 2 行動指示 / Layer 3 skills）は GitHub Copilot CLI / Claude Code 前提で整備されてきた。これを OpenAI Codex（Codex CLI）でも利用可能にする。スコープはフル対応（Layer 2 の AGENTS.md 経路 + Layer 3 の Codex 向けプラグイン配信 + README/CONTRIBUTING/スキル本文の中立化）で確定（ADR-0110 Accepted）。

2026-08-25 の公式ドキュメント調査で確認済み: Codex のスキル機構（`.agents/skills`、SKILL.md 同形）、一覧予算は description のみに適用、marketplace 探索先に `.claude-plugin/marketplace.json`（legacy 互換）、プラグインマニフェストは `.codex-plugin/plugin.json`、Codex は AGENTS.md を読み CLAUDE.md は読まない。

## 関連ドキュメント

- Spec: `docs/current/specs/2026-08-25-codex-support-design.md`（確定済み）
- Plan: `docs/working/plans/2026-08-25-codex-support-implementation.md`（確定済み・12 タスク / 90 ステップ）
- ADR-0110: スコープ決定（Accepted）
- ADR-0113: コード品質レビュー指摘の反映先と採用基準（Proposed。Task 11 通過後に昇格）
- ADR-0114: Layer 2 参照の中立化の仕上げ（Proposed。Task 11 通過後に昇格）
- Issue-0108: 採用を見送った指摘 4 群の受け皿（open）
- ADR-0023: 先例（Copilot CLI → Claude Code 併対応。Layer 2 一本化。部分改訂の見込み）
- 先例 spec: `docs/current/specs/2026-06-16-claude-code-support-design.md`
- 拡張ルール: `CONTRIBUTING.md`（過剰適合点検・新設の評価可能性・執行点 4 手順）

## 完了済みタスク

- [x] Codex 公式ドキュメント調査（2026-08-25。結果は ADR-0110 Context）
- [x] スコープ決定（フル対応。ADR-0110 Accepted・`74e495f` コミット済み）（2026-08-25 完了）
- [x] brainstorming（設計承認済み: Layer 2 AGENTS.md 正本化 / Layer 3 生成器導出 / superpowers は Codex 実機検証で導入成功）（2026-08-25 完了）
- [x] feature-block-design 適用要否判定（不適用: 主要機能 1・新規モジュールなし）（2026-08-25 完了）
- [x] spec 作成: `docs/current/specs/2026-08-25-codex-support-design.md`（未コミット・過剰適合点検ブロック含む）（2026-08-25）
- [x] ADR-0111/0112 ドラフトコミット（`29b88cc`・Proposed）（2026-08-25 完了）
- [x] 確定前レビュー（spec 確定点 (b)）: フル巡 2＋差分確認巡 1＋機械検証 1・指摘 53 件全採用・補助実測 6 件・設計縮小 1 件（分割コミット機構の除去）・実質収束で確定（2026-08-25 完了）
- [x] Issue-0107 起票（反復レビュー推奨の乖離記録。フォルダ昇格形態・乖離事例 3＋一般観察 1 を検討経緯ログへ）（2026-08-25 完了）
- [x] writing-plans: 実装計画作成（`docs/working/plans/2026-08-25-codex-support-implementation.md`。12 タスク / 90 ステップ）（2026-08-25 完了）
- [x] 確定前レビュー（plan 確定点）: フル巡 2＋機械検証 1＋差分確認巡 2＋機械検証 1・指摘 44 件全採用・提示後確定（2026-08-25 完了）
- [x] 実行方式の選択: `superpowers:subagent-driven-development`（Task 3・11 は実機操作のためインライン）（2026-08-25 完了）
- [x] plan Task 1 完了: build-dist に version 一致検査を追加（`29bc6ff`。仕様適合レビュー ✅ 要求 12/12）（2026-08-25 完了）
- [x] plan Task 2 完了: Codex 向け 2 生成物の導出生成（`1f24a02`。仕様適合 ✅ 18/18・コード品質 ✅ 承認）（2026-08-25 完了）
- [x] Issue-0108 起票: レビューで採用を見送った指摘 4 群の受け皿（2026-08-25 完了）
- [x] plan Task 3 完了: Layer 2 を AGENTS.md 正本へ切替（`13d4106`。仕様適合 ✅ 38/38・コード品質 ✅ 承認）（2026-08-25 完了）
- [x] plan Task 4 完了: skills の Layer 2 参照とローカルスキルパスを中立化（`7b71c5d`。仕様適合 ✅ 46/46＋11/11・ADR-0114 の 4 点を反映）（2026-08-25 完了）

## 進行中のタスク

- [ ] **現在の作業**: 実装（plan の Task 5 から続行）
  - 状態: Task 1〜4 完了。計画からの逸脱は ADR-0113（6 点）と ADR-0114（4 点）に限られ、いずれも仕様適合レビューが逸脱ゼロを確認済み
  - 残り: Task 5〜12 を順に実行 → 検証 1〜5・8・9 → ADR-0111/0112/0113/0114 Accepted 昇格・ADR-0023 部分修正注記
  - **Task 5 は ADR-0114 の 4 点を先に適用した形で実装する**（8 番目の二段フォールバック箇所 `docs/overview/issue-management.md:44` を含む。計画 Task 5 Step 1 は同期済み）
  - Task 11 も実機操作を伴うため委譲せずインラインで扱う
  - 計画は本サイクルで複数回更新済み（Task 2 Step 13 を 3 → 7 ケース／Task 4 の Step 2〜6・8・前文／Task 5・9・11 の旧表現同期）

## 未着手のタスク

- [ ] Layer 2 設計・実装（AGENTS.md 経路）
- [ ] Layer 3 設計・実装（.codex-plugin 生成・marketplace.json の Codex 対応）
- [ ] README（Codex インストール節）・CONTRIBUTING・スキル本文の中立化
- [ ] 過剰適合点検・確定前レビュー提示・執行点 4 手順

## 既知のブロッカー・懸念

- ~~Claude Code の `@AGENTS.md` インポート挙動~~ → 公式ドキュメントで確認済み（公式推奨パターン。実機の `/context` 確認は実装後の検証 5 に残置）
- Copilot CLI は AGENTS.md/CLAUDE.md を両方読む（同一内容なら重複除去）。別内容にすると二重読み込みが再発する（ADR-0023 の懸念の再来）
- ~~superpowers の Codex 可用性~~ → 実機検証で解消（superpowers 6.3.0 導入成功・インストールは残置＝実運用状態。Codex CLI 0.149.0-alpha.4.3）
- 配布物生成の既知の落とし穴（ADR-0082/0084 の型・Issue-0104）。執行点 4 手順＋配布物目視を省略しない
- 改訂前退避 `~/.ai-dev-review-snapshots/2026-08-25-codex-support/`（round1/round2＋plan-round1〜4）が残置。掃除規定は Issue-0106（当面手動判断）
- 反復レビューの推奨乖離の記録は Issue-0107（本サイクルで 6 事例＋一般観察 2 件を記録済み。LoopForAlpha#Issue-0109 の移譲は未着手）
- ~~Task 1 のコミット `29bc6ff` 単体では JSON 入力異常の診断に一時的な間隙が残る~~ → Task 2（`1f24a02`）で解消
- `scripts/build-dist.ps1` にはレビューで採用を見送った指摘 4 群が残る（Issue-0108）。いずれも Task 11 の検証範囲外であり、捕捉されない前提で扱うこと
- `scripts/check-claude-md-size.ps1` 35 行目の警告文が案内する CONTRIBUTING 見出し「AGENTS.md を棚卸しするとき」は未作成（Task 7 で改題）。計画が「既知の中間不整合（許容）」とした箇所。Task 7 の着地時に解消を確認すること
- 未移行プロジェクトを検知して移行を促す機構は本サイクルでは設けない（ADR-0114 で受容）。移行の契機は Task 6 が新設する README の移行手順のみ

## Post ラッパー消化記録

- 2026-08-25 スコープ決定・ADR-0110 Accepted 昇格（`74e495f`）: ADR=0110 / worklog=棄却（delta なし） / cyclecheck=非該当（実装前昇格）
- 2026-08-25 設計承認・ADR-0111/0112 ドラフトコミット（`29b88cc`）: ADR=0111/0112（Proposed） / worklog=棄却（唯一の friction は codex サブコマンド乖離で自律解決・spec 正本に記録済み）
- 2026-08-25 spec 確定点 (b) 通過・spec 確定: ADR=なし（改訂は Proposed 0111/0112 へ反映済み） / worklog=`MakeAiInstructions-2026-08-25-01` / review=フル実施（claude-opus-5・2 巡）＋差分再確認（claude-opus-5・1 巡）＋機械検証（1 回・実質収束）
- 2026-08-25 Issue-0107 起票（推奨乖離の記録）: ADR=なし（記録のみ・対策設計は次サイクル以降のユーザー判断） / worklog=棄却（正本は Issue-0107 の検討経緯ログ）
- 2026-08-25 plan 確定点 通過・実装計画確定: ADR=なし（改訂は Proposed 0111/0112 の枠内。spec への反映は plan Task 9 Step 13） / worklog=`MakeAiInstructions-2026-08-25-02` / review=フル実施（claude-opus-5・2 巡）＋機械検証（1 回）＋差分再確認（claude-opus-5・2 巡）＋機械検証（1 回・提示後確定（実質収束せず））
- 2026-08-25 セッション終了処理（Issue-0107 へ plan 確定点の乖離事例 3 件＋一般観察 1 件を追記）: ADR=なし（記録のみ・対策設計は次サイクル以降のユーザー判断） / worklog=`MakeAiInstructions-2026-08-25-03`
- 2026-08-25 plan Task 1 完了（build-dist の version 一致検査・`29bc6ff`）: ADR=0113（Proposed・レビュー指摘の反映先） / worklog=`MakeAiInstructions-2026-08-25-04`・`-05`
- 2026-08-25 plan Task 2 完了（Codex 向け 2 生成物の導出・`1f24a02`。Issue-0108 起票）: ADR=0113（追加決定を追記・Proposed） / worklog=`MakeAiInstructions-2026-08-25-06`〜`-08`
- 2026-08-25 plan Task 3 完了（Layer 2 を AGENTS.md 正本へ切替・`13d4106`）: ADR=なし（決定は ADR-0111 の枠内。昇格は Task 12） / worklog=`MakeAiInstructions-2026-08-25-09`
- 2026-08-25 plan Task 4 完了（skills の中立化・`7b71c5d`）: ADR=0114（Proposed・受容残余まで記録） / worklog=`MakeAiInstructions-2026-08-25-10`〜`-12`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ → `docs/working/plans/2026-08-25-codex-support-implementation.md`（確定済み plan。Task 5 から順に実行する。冒頭「タスク間の順序制約」を先に読む）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:subagent-driven-development` を継続（Task 11 は実機操作を伴うため委譲せずインラインで扱う）
3. 留意点: 行番号は本計画未適用時が基準のため位置決めは引用テキストで行うこと。Task 9 は Task 2/3/4/7 の後、Task 11 は 1〜10 の後、Task 12 は 11 の後。検証 6・7・10 はユーザー確認事項として引き継ぐ

## 重要な意思決定の履歴

- ADR-0110: Codex 対応はフル対応を単一サイクルのスコープとする（2026-08-25 Accepted）
- ADR-0113: 生成器の JSON 入力異常に対する診断強化は、Codex 生成物の入力ガードと同じコミットへ統合する（2026-08-25 Proposed）
- ADR-0114: Layer 2 参照の中立化は、探索対象の明示・書き込み先の二段フォールバック・ツール列挙の開放で仕上げる（2026-08-25 Proposed）
