# ADR-0090: スキル改定の配布反映にはプラグインのバージョン更新を必須手順とする

- **Status**: Accepted
- **Date**: 2026-08-14

## Context

本リポジトリのスキル群は、生成物 `dist/` を GitHub 経由のマーケットプレイスとして配布している（ADR-0082）。利用側の Claude Code は、プラグインをバージョン番号をキーとするキャッシュ（`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`）へインストールし、Skill ツールはそこから本文を供給する。

2026-08-13〜14 サイクルで改定した session-handoff / start-work をプラグインへ反映しようとしたところ、次の事実が実測で確定した（2026-08-14）:

- `/plugin marketplace update` はマーケットプレイスのクローンを最新化するが、プラグインの version が変わっていない場合、インストール済みキャッシュは再取得されない
- `/plugin update` は version 比較で更新要否を判定し、同一 version では「already at the latest version (0.1.0)」を返して再取得しない
- 結果として、`dist/` の内容が GitHub 上で更新されていても、version が据え置きの限り利用側には改定前の本文が供給され続ける

前サイクルまでは「`/plugin marketplace update` で改定が反映される」と実測されていた（Issue-0044）が、当時と条件が異なっていた可能性が高く、少なくとも version 据え置きでの反映は本セッションで再現しなかった。

## Considered Alternatives

1. **plugin.json / marketplace.json の version を上げて再配布する（採用）** — 版差分が生じるため `/plugin marketplace update` 1 コマンドでプラグイン更新まで一括実施される（出力「(1 plugin bumped)」で実測確認）。リポジトリ側の変更 3 行で済み、以後の改定でも同じ手順で再現できる
2. **アンインストール → 再インストール** — version 据え置きのまま反映できる可能性はあるが、利用側の手作業が毎回増え、インストール記録の残置など副作用の懸念もある。次回改定でも同じ詰まりが再発する
3. **何もしない（version 運用を変えない）** — 改定が配布に反映されない状態が外形上は成功（コマンドは正常終了）に見えるまま継続する。不採用

## Decision

配布対象（`dist/` に入るスキル・ファイル群）を改定して配布へ反映する際は、**同じ区切りで `.claude-plugin/plugin.json` と `.claude-plugin/marketplace.json` の version を上げる**（既定は patch 位置のインクリメント。`dist/.claude-plugin/plugin.json` は build-dist.ps1 がルートから複写するため直接編集しない）。

反映と確認の手順:

1. version を上げ、執行点 4 手順（CONTRIBUTING.md）を経て commit・push する
2. 利用側で `/plugin marketplace update ai-driven-dev-principles` を実行する（版差分があればプラグイン本体の更新まで一括で行われる。`/plugin update` の追加実行は不要）
3. 反映確認は「起動して返った本文と repo の `dist/` 実ファイルの突合」で行う（プラグインキャッシュのファイルを読むだけでは供給内容を判定できない）

## Consequences

- 良い影響: 改定の配布反映が 1 コマンドで再現可能になり、反映確認の手順も確定する。「update したのに旧本文が供給される」という外形上気づきにくい不整合を塞げる
- 悪い影響・負担: 配布対象の改定のたびに version が上がり、番号の意味論（semver 的な意味付け）は薄まる。version bump を忘れると旧本文の供給が継続するが、これを機械的に検出する仕組みは現状ない（bump 忘れ検出の要否は課題側で扱う）
- 追随が必要な記録: Issue-0044（スキル改定の同セッション反映）の検討状況に本実測を追記する。handoff の申し送り「`/plugin marketplace update` の実行を依頼」は「version bump + marketplace update」を前提とした記述へ更新する
- 本 ADR は実施済みの運用対処の記録であり、設計文書を兼ねる型（spec 確定点 (c)）には該当しない
