# Issue-0055: 仕様書内から ADR を相対パスで参照しているリンクが壊れている

- **Status**: open
- **Opened**: 2026-08-07
- **起票元**: `retrospectives/system/2026-08-07-rename-to-ai-driven-dev-guideline.md` 課題#1
- **関連**: 原則1（追跡可能性）、`docs/overview/folder-structure.md`「7. 仕様書の運用規約」の「仕様書は現時点のシステム全容が分かるスナップショットとして維持する」規約、ADR-0077（外部参照は安定識別子で書く）

## 課題内容

`docs/current/specs/2026-04-12-meta-guidelines-design.md` L179 の Markdown リンク `[0001](0001-adopt-layered-guidelines.md)` は、specs ディレクトリからの相対パスとして解決されるためリンク先が存在しない（実在するのは `docs/records/decisions/0001-adopt-layered-guidelines.md`）。ADR インデックスの表を転記したまま、相対パスの起点が変わったことに追従していないと見られる。

仕様書からの ADR 追跡が切れており、原則1（追跡可能性）が部分的に成立していない。同種のリンクが他の仕様書にもあるかは未調査。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-07: 起票。改名サイクル（ADR-0078）のマージ前最終レビューが pre-existing 事項として検出し、`Test-Path` でリンク先の不在を確認した。本改名作業自体への影響はない

## 結論

（open）
