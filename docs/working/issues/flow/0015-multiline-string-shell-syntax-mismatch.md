# Issue-0015: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-plan-verification-consistency-check.md 課題#1
- **関連**: Tech Notes（同振り返り）、コミットメッセージ運用

## 課題内容

複数行文字列（コミットメッセージ等）を CLI へ渡す際、利用ツールのシェル種別（POSIX sh の Bash ツール / PowerShell ツール）に合わない構文を使うと文字列が壊れる。実例として PowerShell 形式の here-string `@'...'@` を POSIX sh の Bash ツールで使い、コミットメッセージ先頭・末尾に `@` が混入した（即 amend 修正、実害なし）。ツールのシェル種別に応じた安全な受け渡し方法（例: `git commit -F <file>`、POSIX heredoc）を促す規範・チェックがガイドラインにない（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

（未着手）

## 結論

（open）
