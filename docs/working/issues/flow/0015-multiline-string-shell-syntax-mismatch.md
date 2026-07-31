# Issue-0015: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-plan-verification-consistency-check.md 課題#1
- **関連**: Tech Notes（同振り返り）、コミットメッセージ運用、`worklog-extract` 走査（2026-07-31）候補4（本課題へ統合。下記「検討状況」2026-07-31 を参照）

## 課題内容

複数行文字列（コミットメッセージ等）を CLI へ渡す際、利用ツールのシェル種別（POSIX sh の Bash ツール / PowerShell ツール）に合わない構文を使うと文字列が壊れる。実例として PowerShell 形式の here-string `@'...'@` を POSIX sh の Bash ツールで使い、コミットメッセージ先頭・末尾に `@` が混入した（即 amend 修正、実害なし）。ツールのシェル種別に応じた安全な受け渡し方法（例: `git commit -F <file>`、POSIX heredoc）を促す規範・チェックがガイドラインにない（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

- 2026-07-05: Issue-0012 対策サイクル（ADR-0035）で、コミット・マージメッセージを `git commit -F <file>` / `git merge --no-ff -F <file>` のファイル経由で渡す回避策を意図的に適用し、here-string 誤用による文字列破損（前回のような `@` 混入）は発生しなかった。回避策の有効性は確認できたが、これを促す規範・チェックは依然として未整備で、適用はエージェントの都度判断に依存している（起票元: retrospectives/system/2026-07-05-question-tool-timeout-autonomy.md。rubber-duck 指摘#1 を受けた対称性の追記）
- 2026-07-06: シェル種別の不一致はマルチライン文字列に限らず、終了コード参照（PowerShell `$LASTEXITCODE` vs Bash `$?`）のような単行構文でも発生した（Issue-0018 対策サイクルの plan 初稿の期待値誤り。セルフレビュー＝ADR-0034 突合で実行前に捕捉、実害なし）。本課題の射程を「マルチライン文字列」から「シェル種別依存の構文全般」へ広げる材料になる（起票元: retrospectives/system/2026-07-06-claude-md-growth-governance.md）
- 2026-07-31: `worklog-extract` 初回走査の候補4「環境・ツール固有の文字・パス・記法の落とし穴を定型手順で回避する」を、同一系統として**本課題へ統合**した（重複起票を避けるため新規 Issue は立てず、`processed.jsonl` へ `adopted` として代表 id `LoopForAlpha-2026-07-28-02` を追記。`worklog-skillify` の入力は本課題）。中央ストア 94 エントリ中 9 件（LoopForAlpha 8・MakeAiInstructions 1）が該当し、**全 9 件が `friction`（AI 自力の手戻り。人間の指摘は 0）**、model は claude-opus-4-8 ×3 / claude-fable-5 ×3 / claude-opus-5 ×3 と 3 モデルに均等分布しておりモデル固有ではない。本統合により射程は「シェル種別依存の構文」から**「環境・ツール固有の書式および書き込み経路」**へさらに広がる。実測された具体パターン:
  - Bash ツールでの複数行コミットは `-m` でなく `git commit -F -` + heredoc（PowerShell の `@'...'@` を混同して件名に `@` が混入。2026-07-05 の再発）
  - 数百行の追記は heredoc でなく Write / Edit ツール（heredoc は `ENAMETOOLONG` で失敗する）
  - 不可視文字は `chr(0x2028)` 等でプログラム的に組み立てる（Edit / Write はエスケープ表記を生文字へ正規化してしまう）
  - バックスラッシュを含むコードはシェル経由で書かず、スクラッチへ Write してから実行する
  - PowerShell の配列返しは `,@(...)` でラップする（単一要素はスカラーへ展開される）
  - 作業ディレクトリ変更は `cd` でなく `env -C`（Bash ツールの cwd は呼び出し間で保持されない）
  - 構造化質問ツールへ長い日本語を渡すときは `\uXXXX` エスケープを使う
  - JSONL への追記は `utf8NoBOM` を明示し、`od` でバイト検証する
  - 補足: 不可視文字・改行を扱う編集は「バイト検証する／`splitlines` を使わない／書き戻しは `read_bytes` `write_bytes` のみ」を定型手順にする（根拠エントリ `LoopForAlpha-2026-07-28-02` の skillification_hint）
  - 根拠エントリ id: `LoopForAlpha-2026-07-19-03`, `-2026-07-19-06`, `-2026-07-22-04`, `-2026-07-24-05`, `-2026-07-26-07`, `-2026-07-26-10`, `-2026-07-28-01`, `-2026-07-28-02`, `MakeAiInstructions-2026-07-18-01`

## 結論

（open）
