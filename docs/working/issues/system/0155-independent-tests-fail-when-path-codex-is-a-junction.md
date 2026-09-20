# Issue-0155: PATH上のcodexがジャンクション経由だと、独立試験のv1起動検査が失敗する

- **Status**: open
- **Opened**: 2026-09-18
- **起票元**: `docs/records/retrospectives/system/2026-09-18-isolated-verification.md` 課題#1
- **関連**: `scripts/verification/tests/Run-IndependentTests.ps1` / `scripts/verification/README.md`「部品の独立試験」 / RequestCopy.Tests.ps1（v1の起動検査）

## 課題内容

Claude Codeのセッションから独立試験を実行すると、PATH上のcodexがジャンクション（standalone方式の `bin`）経由のため、v1の起動検査がリンクを拒否して最初の群で失敗する。実体パスをPATHの先頭に足すと11群とも合格する。主担当の環境によって試験の成否が変わる。詳細は起票元を参照。

## 検討状況

- 2026-09-18: 起票。今回は実行時にPATHを補って回避した（ログ `.worktrees/isolated-verification/.tmp/c9/independent-tests-20260918-r2.log`）。対策の採否は次サイクル以降の利用者判断
- 2026-09-20: ADR-0206により隔離検証は試作で止め、追加投資をしない。本課題は保留とし、隔離検証を再開するとき（ADR-0205の再検討条件、開始は利用者の指示）に扱う

## 結論

（open）
