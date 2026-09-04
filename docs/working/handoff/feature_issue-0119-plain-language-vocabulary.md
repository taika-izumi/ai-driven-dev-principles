# Handoff: ガイドライン文書の分かりにくい語を平易表現規約へ合わせる（Issue-0119）

- **Branch**: feature/issue-0119-plain-language-vocabulary（master `d11c38b` から分岐。マージ未実施）
- **Last Updated**: 2026-09-05 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/設計確定済み。次は実装計画の作成（writing-plans）

## 作業の目的・背景

Issue-0119 の対策サイクル。`AGENTS.md`「コンテキスト管理」の平易表現規約は対話・成果物ドキュメントを対象とし、配信スキルの本文は対象外だった。AI はスキル本文を読んで作業するため、その語彙（突合・消化・母数・消し込み・巡・格下げ など）と記号的ラベル（`A 群 / B 群`・`採用基準 (i)`・`観点 4`・`spec 確定点 (a)`）が配布先の対話・成果物へ写っている。配布先 LoopForAlpha の 8 セッション観測から申し送られた。

方針（ADR-0123。確定前レビュー 2 回と設計縮小を経て確定）: 分かりにくい語を 3 型（語自体型・目的語省略型・記号的ラベル）で定め、AI が読み今後も書き換える文書 4 群（`skills/`・template 対象 6・CONTRIBUTING と README と docs/reference・現用仕様書）を書き換える。再流入は配布する置き換え表（`docs/reference/wording-replacements.md` 新設）と `AGENTS.md` の 1 行（編集時に見つけたら置き換えを提案する）で防ぎ、**自動検査は設けない**。名前を変えるときは古い名前を列挙せず「書式と実ファイルが食い違ったら報告して判断を仰ぐ」の汎用 1 文で受ける。記録型文書は本文を据え置きタイトルのみ置き換える。ユーザーは申し送り側の推奨順（Issue-0123 → 0118 → 0122）を後回しにし、本課題を先に選んだ。

## 関連ドキュメント

- 設計書: `docs/current/specs/2026-09-04-plain-language-vocabulary-design.md`（Draft・26,903B。置き換え表・置き換え表ファイルと提案の規範・名前の変更・記録型文書のタイトル・完了条件 12 項・過剰適合点検ブロック）
- 決定: ADR-0123（Proposed・17,694B。`docs/records/decisions/0123-plain-language-vocabulary-in-normative-documents.md`。決定 7 項・新設の評価可能性の記載を含む）
- 対象課題: `docs/working/issues/flow/0119-guideline-wording-violates-its-own-plain-language-norm/`（課題本体＋配布先の観測資料 `lfa-0130-*` 10 本）
- 問われている規約: `AGENTS.md`「コンテキスト管理」/ その設計: `docs/current/specs/2026-06-15-naming-clarity-discipline-design.md`・ADR-0022
- 隣接課題: Issue-0043 / Issue-0120 / LoopForAlpha#Issue-0131（配布先文書側の同型。配布先が所有）
- 拡張ルール: `CONTRIBUTING.md`（執行点 4 手順・SKILL.md のサイズと分割・過剰適合点検・新設の評価可能性）
- master の申し送り（本ブランチでも有効）: `docs/working/handoff/master.md`
- 改訂前退避と差分: `~/.ai-dev-review-snapshots/MakeAiInstructions/2026-09-04-adr-0123-spec/`（r1・r2 と、r1→r2・r2→r3 の差分ファイル）

## 完了済みタスク

- [x] Issue-0119 の特定と feature ブランチ作成（2026-09-04）
- [x] extend-guidelines → brainstorming: 対象の定義（3 型）・規約の置き場（CONTRIBUTING）・置き換え範囲・互換処理・自動検査の型を決定。設計 4 節をユーザー承認（2026-09-04）
- [x] 設計書と ADR-0123 ドラフトの作成とコミット（`ffff282`）。feature-block-design は不適用と判定し spec 確定点 (b)〈設計文書型〉に到達（2026-09-04）
- [x] 確定前レビュー第 1 回（全観点レビュー・4 体・claude-opus-5）。指摘 43 件（重複統合後）を集約し、機械修正 34 件を採用、設計変更 8 点をユーザーと 1 点ずつ決定、1 件不採用。設計書と ADR を改訂（未コミット。2026-09-04）
- [x] 確定前レビュー第 2 回（全観点レビュー・4 体・claude-opus-5・新規レビュアー）。指摘 47 件。性質は本体由来 5・自動検査 9・名前の変更の波及 12・実測表 13・文書の書き方 10（2026-09-04）
- [x] 設計縮小の適用（反復規範の前置 1 に該当）。自動検査を範囲から外し、名前の変更方式を「古い名前を列挙しない」形へ統一。ユーザーと 8 論点を 1 つずつ決定（2026-09-05）
- [x] 設計書と ADR-0123 の全面改訂。設計書 37,992→26,903B・ADR 23,515→17,694B。ADR タイトルも平易化し一覧を更新（2026-09-05）
- [x] 確定前レビュー第 3 回（全観点レビュー・2 体・観点兼務・claude-sonnet-5）。指摘 14 件（重複除く）。重いものは「縮小の結果、既存の仕組みとの突き合わせが漏れた」型 2 件（2026-09-05）
- [x] 第 3 回の指摘 14 件を反映（`出所識別子`・`安定識別子` の対象外化／節名を引用する他 5 スキル 7 箇所の追加／置き換え表の置き場を `docs/overview/` へ／振り返り規約の例外拡張の明示／タイトル件数 24→29 ほか数値訂正）（2026-09-05）
- [x] 機械検証。数値の齟齬 2 件（識別子 群A 14→9・採用基準ラベルの実体不一致）を検出し修正。再検証で全一致（2026-09-05）
- [x] **spec 確定点 通過・設計確定**（提示後確定。設計書 30,723B・ADR 19,336B。2026-09-05）

## 進行中のタスク

- [ ] **現在の作業**: 実装計画の作成（`superpowers:writing-plans`）
  - 状態: 設計確定済み。着手前に `skills/start-work/references/plan-deviation-defaults.md` を読み、計画へ逸脱判断の宣言欄を置く
  - 残り: 計画作成 → plan 確定点で確定前レビューを提示 → 実装

## 未着手のタスク

- [ ] 実装計画の作成（writing-plans。plan 確定点で確定前レビューを提示）
- [ ] 実装: 語とラベルの置き換え（4 群）・`docs/reference/wording-replacements.md` 新設と template 追加・`AGENTS.md` の 1 行・`CONTRIBUTING.md` の新節・見出しや書式の名前の変更・`session-handoff` の汎用 1 文・記録型文書のタイトル 24 件と一覧・`master.md` の 2 節・執行点 4 手順・version 0.1.19
- [ ] 完了処理（ADR-0123 の Accepted 昇格〈サイクル全体整合検査〉・Issue-0119 close・`--no-ff` マージ・retrospective・cycle-reset・push）

## 既知のブロッカー・懸念

- master の handoff の申し送りは本ブランチでも全件有効（配布経路・執行点 4 手順・SKILL.md サイズ警告・Python は `python` を使う など）
- 未追跡 4 件（`docs/conversation_log.md`・`docs/inbox/` 3 件）は本サイクルで触らない（Issue-0020）。コミットは pathspec 付きで行う
- **本サイクルの成果物自身を新しい語彙で書く**（設計書 完了条件 11）。AI の説明文と ADR の当初タイトルが置き換え対象語で書かれていた実測がある（worklog `MakeAiInstructions-2026-09-04-01`）
- **ユーザーへの判断要求は 1 論点ずつ、語の実際の用例を添えて**（同 worklog）。判断 8 点の一括提示は理解できないと指摘された
- 配布先の観測資料の実測値は自分で再実測してから使う（「素の 9 件」は誤ヒットだった。申し送りの表に無い語のほうが多かった）
- **ゲート付きの手順へ相乗りするときは、そのゲートが新しい対象を覆うかを先に確認する**（自動検査の発火点を 2 回設計し 2 回とも同じ指摘を受けた。worklog `MakeAiInstructions-2026-09-05-01`）
- 自リポジトリのハンドオフは本サイクルでは書き換えない（配布物経由で動くスキルがまだ古いため。設計書 6-1）。本ファイルの節見出しが旧名のままなのはこのため

## Post ラッパー消化記録

（形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照）

- 2026-09-05 spec 確定点 通過・設計確定: ADR=0123 / worklog=`MakeAiInstructions-2026-09-04-01`・`MakeAiInstructions-2026-09-05-01` / review=フル実施（claude-opus-5・2 回）＋フル実施（claude-sonnet-5・1 回）＋機械検証（1 回・提示後確定）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 設計書 `docs/current/specs/2026-09-04-plain-language-vocabulary-design.md`（確定済み。設計 2 の置き換え表と設計 6-3 の完了条件 12 項）
2. 最初に実行すべきコマンド/スキル: `start-work` → `superpowers:writing-plans`（着手直前に `skills/start-work/references/plan-deviation-defaults.md` を読む）
3. 留意点: 成果物は新しい語彙で書く。判断要求は 1 論点ずつ、語の実際の用例を添えて。実装計画では記録型文書のタイトルの対象一覧を機械的に出し直して件数を確定する

## 重要な意思決定の履歴

- ADR-0123: ガイドライン文書の分かりにくい語は、対象を 3 種類に定めて文書自体を書き換え、再流入は配布する置き換え表と提案の規範で防ぐ（自動検査は設けず、古い名前も列挙しない）（2026-09-04 起票・2026-09-05 改訂。Proposed）
