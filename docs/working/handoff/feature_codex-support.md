# Handoff: Codex（OpenAI Codex CLI）対応

- **Branch**: feature/codex-support
- **Last Updated**: 2026-08-25 20:50 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/実装（subagent-driven-development・plan Task 10 完了）

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
- [x] plan Task 5 完了: docs/overview の 2 箇所を中立化（`bc51327`。仕様適合 ✅ 16/16・品質 ✅ 承認）（2026-08-25 完了）
- [x] plan Task 6 完了: README に Codex インストール節と移行手順を追加（`57f5cec`。仕様適合 ✅ 12/12・品質 ✅ 承認）（2026-08-25 完了）
- [x] plan Task 7 完了: CONTRIBUTING を AGENTS.md 正本と新生成物構成へ追随（`dcb2e81`。21 箇所→4 箇所、Task 3 の中間不整合を解消。歴史的記述の是正 `5be9a90`）（2026-08-25 完了）
- [x] plan Task 8 完了: version 0.1.12 へ bump・description を AGENTS.md 基準へ（`a9e3432`。仕様適合 ✅ 8/8・品質 ✅ 承認）（2026-08-25 完了）
- [x] plan Task 9 完了: 仕様スナップショット 10 ファイルを同期（`5f84c65`。仕様適合 ✅ 47/47・品質 ✅ 承認）（2026-08-25 完了）
- [x] plan Task 10 完了: ADR-0023 へ部分修正注記（`ec4b994`＋指示対象の明示 `2201ef3`。Status は Accepted 維持）（2026-08-25 完了）

## 進行中のタスク

- [ ] **現在の作業**: 実装（plan の Task 11 から続行）
  - 状態: Task 1〜10 完了。残るのは Task 11（検証・実機操作のためインライン）と Task 12（ADR 昇格・handoff 更新）
  - **Task 12 で handoff へ残す母数は 15**（`CLAUDE.md` 参照を持つが本サイクルが直接触らない spec。実装者とレビュアーが独立に数え直して一致。総数 19 − 同期対象で参照が残る 4）
  - Task 11 では検証 1〜5・8・9 を実施し、6・7・10 はユーザー確認事項として引き継ぐ
  - Task 7 では `check-claude-md-size.ps1` の警告文が案内する CONTRIBUTING 見出しの改題（既知の中間不整合の解消）を確認すること
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
- 未移行プロジェクトを検知して移行を促す機構は本サイクルでは設けない（ADR-0114 で受容）。移行の契機は README の移行手順のみ（Task 6 で新設済み）
- README の Codex 節で `codex plugin marketplace list` / `plugin remove` / `marketplace upgrade` は実測記録が無い。Task 11 で確認し、通れば README の実測範囲の記述を強められる
- ~~`check-claude-md-size.ps1` の警告文が案内する CONTRIBUTING 見出しが未作成~~ → Task 7（`dcb2e81`）で改題し解消
- Task 7 の見出し改題により `docs/working/issues/flow/0018-claude-md-norm-growth-monitoring.md` の 7・16 行が旧見出し名を指すようになった。issues は spec 検証 9 の網羅性チェック対象（生きたファイル 8 種）に含まれずスコープ外。次サイクルで追随を判断すること
- `docs/current/specs/2026-08-07-distributed-artifact-generation/03-template-sync-integration.md:70,74` の識別子数（128/121/7/116）が振り返り記録の追記で時間経過により乖離（現在は約 210/13）。本サイクル起因でなく同期基準の対象外。「継続的に陳腐化する実測値を仕様書へどう書くか」は振り返りの課題候補

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
- 2026-08-25 plan Task 5 完了（docs/overview の中立化・`bc51327`）: ADR=なし（決定は ADR-0111/0114 の枠内） / worklog=`MakeAiInstructions-2026-08-25-13`
- 2026-08-25 plan Task 6 完了（README の 3 ツール化・`57f5cec`）: ADR=なし（逸脱は上流正本との整合であり新規の決定ではない） / worklog=`MakeAiInstructions-2026-08-25-14`
- 2026-08-25 plan Task 7 完了（CONTRIBUTING の追随・`dcb2e81`＋`5be9a90`）: ADR=なし（計画どおり。歴史的記述の是正は事実誤りの訂正） / worklog=`MakeAiInstructions-2026-08-25-15`
- 2026-08-25 plan Task 8 完了（version 0.1.12 bump・`a9e3432`）: ADR=なし（決定は ADR-0090/0111 の枠内） / worklog=`MakeAiInstructions-2026-08-25-16`
- 2026-08-25 plan Task 9 完了（仕様スナップショット同期・`5f84c65`）: ADR=なし（計画どおり。出力例の数値是正は実測との整合） / worklog=`MakeAiInstructions-2026-08-25-17`
- 2026-08-25 plan Task 10 完了（ADR-0023 部分修正注記・`ec4b994`＋`2201ef3`）: ADR=0023（部分修正注記のみ。decision-log の改訂記録規定は対象外） / worklog=`MakeAiInstructions-2026-08-25-18`

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本ハンドオフ → `docs/working/plans/2026-08-25-codex-support-implementation.md`（確定済み plan。Task 11 から順に実行する。冒頭「タスク間の順序制約」を先に読む）
2. 最初に実行すべきコマンド/スキル: `start-work`（Phase 0 で本ハンドオフを read）→ `superpowers:subagent-driven-development` を継続（Task 11 は実機操作を伴うため委譲せずインラインで扱う）
3. 留意点: 行番号は本計画未適用時が基準のため位置決めは引用テキストで行うこと。Task 9 は Task 2/3/4/7 の後、Task 11 は 1〜10 の後、Task 12 は 11 の後。検証 6・7・10 はユーザー確認事項として引き継ぐ

## 重要な意思決定の履歴

- ADR-0110: Codex 対応はフル対応を単一サイクルのスコープとする（2026-08-25 Accepted）
- ADR-0113: 生成器の JSON 入力異常に対する診断強化は、Codex 生成物の入力ガードと同じコミットへ統合する（2026-08-25 Proposed）
- ADR-0114: Layer 2 参照の中立化は、探索対象の明示・書き込み先の二段フォールバック・ツール列挙の開放で仕上げる（2026-08-25 Proposed）
