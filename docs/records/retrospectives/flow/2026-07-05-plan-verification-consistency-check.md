# Flow Feedback: plan 検証整合規範の追加（Issue-0013 対策）

開発フロー/ガイドラインに関する課題の記録。配布先システム開発repoでは、このファイルがガイドラインrepo（ai-driven-dev-principles）への申し送りバックログになる。

- **Subject**: plan の検証ステップ期待値と各タスク編集内容の整合を確認する規範の追加（Issue-0013 対策）
- **Period**: 2026-07-05 〜 2026-07-05
- **対応する system 振り返り**: [system/2026-07-05-plan-verification-consistency-check.md](../system/2026-07-05-plan-verification-consistency-check.md)
- **Facilitator**: メインエージェント (Claude Opus 4.8)

## 開発フロー/ガイドライン課題

各課題は抽出と分類までにとどめる。**対策の設計・採否判断・ADR 化は行わない**（次サイクルでユーザーが対策要と判断した時点で着手。ADR-0021）。

- **課題 #1**: マルチライン文字列をツールのシェル種別に合わせる規範・チェックがない
  - **事象**: 最初のコミットで、メッセージ先頭・末尾に `@` が混入した（`[... ] @ feat: ...`）。amend で修正した（手戻り1回）
  - **原因**: Bash ツール（POSIX sh / Git Bash）に対し、PowerShell 形式の here-string `@'...'@` を渡した。POSIX sh では `@'` `'@` がリテラルとして扱われる
  - **影響**: 軽微。未 push・未 merge の feature ブランチ上で `git commit --amend -F <file>` により修正、実害なし。ただし気づかなければ壊れたメッセージが履歴に残った
  - **なぜフロー課題か**: 特定システムの問題ではなく、複数のシェル種別のツールを併用する開発フローに共通する落とし穴。恒常的な防止は規範/チェックリスト側に置くべきで、その採否判断は次サイクルに委ねる（ADR-0021）。Tech Notes（system 振り返り）はサイクル固有の記録であり将来のコミット組み立て時には参照されないため、恒常対策の受け皿にはならない
  - **関連**: system 振り返りの Tech Notes「マルチライン文字列はツールのシェル種別に合わせて渡す」、コミットメッセージ運用
  - **起票**: Issue-0015（`../../working/issues/flow/0015-multiline-string-shell-syntax-mismatch.md`）
