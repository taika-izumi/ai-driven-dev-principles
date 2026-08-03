# Issue-0040: CONTRIBUTING.md のテンプレート同期指示が現行構成と矛盾している

- **Status**: open
- **Opened**: 2026-08-04
- **起票元**: `docs/records/retrospectives/flow/2026-08-04-adr-granularity-norms.md` 課題#1
- **関連**: `CONTRIBUTING.md`（start-work / feature-block-design / retrospective の各変更シナリオ）、`template.manifest`、ADR-0016（skills を template から除外）、ADR-0015（プラグイン配布）

## 課題内容

`CONTRIBUTING.md` の複数シナリオに「テンプレート対象なので `scripts/sync-template.ps1` を実行する」とあるが、`template.manifest` の対象は `CLAUDE.md` / `docs/overview/principles.md` / `docs/overview/folder-structure.md` / `docs/inbox/README.md` の4件のみで、skills は ADR-0016 により除外されている。ADR-0016 の際に手順書側が追従しなかったことが原因で、スキルだけを改定するサイクルでは手順書の記述が判断材料として使えない。同種の追従漏れが他シナリオにも潜在する可能性がある。

詳細（事象/原因/影響）は起票元の振り返りファイルが正。

## 検討状況

（なし）

## 結論

（open）
