# Handoff: 配信スキルの語彙を平易表現規約へ適合させる（Issue-0119）

- **Branch**: feature/issue-0119-plain-language-vocabulary（master `d11c38b` から分岐。マージ未実施）
- **Last Updated**: 2026-09-04 (Asia/Tokyo)
- **Status**: in_progress
- **Current Phase**: ガイドライン拡張/extend-guidelines → brainstorming（設計着手前）

## 作業の目的・背景

Issue-0119 の対策サイクル。`AGENTS.md`「コンテキスト管理」は「文章だけで意味が推測できる説明的な表現を用い、その場限りの略号・記号的呼称は使わない」と定めるが、配信スキル自身の文面がこれに反する語（正本・消化・突合・母数・消し込み など）と記号的ラベル（`A 群` / `B 群`・`採用基準 (i)`・`観点1〜5`・`spec 確定点 (a)`）を多用し、AI がそれを写して配布先の対話・成果物へ伝播している。配布先 LoopForAlpha の 8 セッション観測から申し送られた。

固まっている知見: 規約より読み込んだ文書の語彙のほうが強い（出所を直さない限り頻度は下がらない）／「専門用語を避けよ」型の禁止指示は括弧説明を誘発するため対策案から外す／供給源スキルは局面ごとに入れ替わるため合計回数だけで優先度を決めない／フィールド名「Post ラッパー消化記録」の改名は配布先の移行を伴う。

着手時に最初に決めるのは規約の射程（略号・記号的呼称のみか、一般語の非一般的用法・業界用語・英字フィールド名も含むか）で、置き換えの粒度・フィールド名互換性・簡潔さとのトレードオフはそれに従属する。ユーザーは申し送り側の推奨順（Issue-0123 → 0118 → 0122）を後回しにし、本課題を先に選んだ。

## 関連ドキュメント

- 対象課題: `docs/working/issues/flow/0119-guideline-wording-violates-its-own-plain-language-norm/0119-guideline-wording-violates-its-own-plain-language-norm.md`（12,007B。フォルダ昇格済み。配布先の観測資料 `lfa-0130-*` 9 本を同フォルダに保持）
- 問われている規約: `AGENTS.md`「コンテキスト管理」の平易表現規約 / その設計: `docs/current/specs/2026-06-15-naming-clarity-discipline-design.md`
- 隣接課題: Issue-0043（意思決定要求で用語を先に実物提示）/ Issue-0120（昇格済み課題ファイルの縮小機構）/ LoopForAlpha#Issue-0131（配布先文書側の同型。配布先が所有）
- 拡張ルール: `CONTRIBUTING.md`（執行点 4 手順・SKILL.md のサイズと分割・過剰適合点検）
- master の申し送り（本ブランチでも有効）: `docs/working/handoff/master.md`

## 完了済みタスク

- [x] Issue-0119 の特定と feature ブランチ作成（2026-09-04）

## 進行中のタスク

- [ ] **現在の作業**: extend-guidelines → brainstorming で設計（射程 → 粒度 → 互換性の順）
  - 状態: 未着手（ブランチ作成直後）
  - 残り: 3 論点の決定と ADR ドラフト、設計確定後に確定前レビュー提示 → writing-plans

## 未着手のタスク

- [ ] 現行 0.1.18 の `skills/` で出現回数・供給源ファイルを再実測（実測は 0.1.16 時点。ADR-0122 で 2 スキルが分割済み）
- [ ] 実装計画の作成と実行（スキル本文の書き換え・`build-dist.ps1`・version bump 0.1.19）
- [ ] 完了処理（`--no-ff` マージ・retrospective・cycle-reset・push）

## 既知のブロッカー・懸念

- master の handoff の申し送りは本ブランチでも全件有効（配布経路・執行点 4 手順・SKILL.md サイズ警告・Python は `python` を使う など）
- 未追跡 4 件（`docs/conversation_log.md`・`docs/inbox/` 3 件）は本サイクルで触らない（Issue-0020）。コミットは pathspec 付きで行う
- 配布先の handoff・計画に「Post ラッパー消化記録」「消し込み」が構造名として実在する。フィールド名を改名する場合は配布先の移行手順（README への記載など）が要る

## Post ラッパー消化記録

（形式は `skills/session-handoff/SKILL.md` のフォーマット節を参照）

## 次セッション開始時のアクション

1. 最初に確認すべきファイル: 本 handoff と Issue-0119 の課題ファイル（「現在地の要約」「未解決の論点」節）
2. 最初に実行すべきコマンド/スキル: `start-work` → `extend-guidelines`（brainstorming へ接続）
3. 留意点: 規約の射程を最初に決める。「専門用語を避けよ」型の指示は対策から外す

## 重要な意思決定の履歴

（なし）
