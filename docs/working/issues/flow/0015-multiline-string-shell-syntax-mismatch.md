# Issue-0015: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-plan-verification-consistency-check.md 課題#1
- **関連**: Tech Notes（同振り返り）、コミットメッセージ運用

## 課題内容

複数行文字列（コミットメッセージ等）を CLI へ渡す際、利用ツールのシェル種別（POSIX sh の Bash ツール / PowerShell ツール）に合わない構文を使うと文字列が壊れる。実例として PowerShell 形式の here-string `@'...'@` を POSIX sh の Bash ツールで使い、コミットメッセージ先頭・末尾に `@` が混入した（即 amend 修正、実害なし）。ツールのシェル種別に応じた安全な受け渡し方法（例: `git commit -F <file>`、POSIX heredoc）を促す規範・チェックがガイドラインにない（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

- 2026-07-05: Issue-0012 対策サイクル（ADR-0035）で、コミット・マージメッセージを `git commit -F <file>` / `git merge --no-ff -F <file>` のファイル経由で渡す回避策を意図的に適用し、here-string 誤用による文字列破損（前回のような `@` 混入）は発生しなかった。回避策の有効性は確認できたが、これを促す規範・チェックは依然として未整備で、適用はエージェントの都度判断に依存している（起票元: retrospectives/system/2026-07-05-question-tool-timeout-autonomy.md。rubber-duck 指摘#1 を受けた対称性の追記）
- 2026-07-06: シェル種別の不一致はマルチライン文字列に限らず、終了コード参照（PowerShell `$LASTEXITCODE` vs Bash `$?`）のような単行構文でも発生した（Issue-0018 対策サイクルの plan 初稿の期待値誤り。セルフレビュー＝ADR-0034 突合で実行前に捕捉、実害なし）。本課題の射程を「マルチライン文字列」から「シェル種別依存の構文全般」へ広げる材料になる（起票元: retrospectives/system/2026-07-06-claude-md-growth-governance.md）

## 結論

（open）
