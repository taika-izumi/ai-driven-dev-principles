# Issue-0040: CONTRIBUTING.md のテンプレート同期指示が現行構成と矛盾している

- **Status**: closed
- **Opened**: 2026-08-04
- **Closed**: 2026-08-05
- **起票元**: `docs/records/retrospectives/flow/2026-08-04-adr-granularity-norms.md` 課題#1
- **関連**: `CONTRIBUTING.md`（start-work / feature-block-design / retrospective の各変更シナリオ）、`template.manifest`、ADR-0016（skills を template から除外）、ADR-0015（プラグイン配布）

## 課題内容

`CONTRIBUTING.md` の複数シナリオに「テンプレート対象なので `scripts/sync-template.ps1` を実行する」とあるが、`template.manifest` の対象は `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` の4件のみで、skills は ADR-0016 により除外されている。ADR-0016 の際に手順書側が追従しなかったことが原因で、スキルだけを改定するサイクルでは手順書の記述が判断材料として使えない。同種の追従漏れが他シナリオにも潜在する可能性がある。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

- 2026-08-05: 3 シナリオ（start-work L216 / feature-block-design L246 / retrospective L281）の「テンプレート対象なので実行する」を、`template.manifest` の実態に合わせた条件付き記述へ置換した。他シナリオの追従漏れも点検し、**追加の漏れは 0 件**（L73 / L102 は CLAUDE.md 自体が manifest 対象で正しい。L128 / L139 は「manifest に追加しない」と正しく書かれている。L280 の `docs/records/retrospectives/README.md` は空インデックス生成対象で正しく、`template/` 側の実在も確認した）。なお L272 / L278 の `skills/retrospective/template.md` / `flow-template.md` は実在し `sync-template.ps1` とは無関係のスキル内テンプレートである。誤りではないが「同期」の語が紛らわしく、改善余地として記録するにとどめた

## 結論

Task 1 で対処済み（コミット `359835d`）。起票経路・クロスリポジトリ参照形式・close トリガーを含む課題管理規範の整備は ADR-0063。
