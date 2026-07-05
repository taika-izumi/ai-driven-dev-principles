# Issue-0012: 構造化質問ツールのタイムアウト時にエージェントがどこまで自走してよいかの基準がない

- **Status**: open
- **Opened**: 2026-07-05
- **起票元**: retrospectives/flow/2026-07-05-record-process-norms.md 課題#1
- **関連**: ADR-0024、ADR-0029、Issue-0005、原則4（人間の関与）

## 課題内容

AskUserQuestion 等の構造化質問ツールは無応答約60秒でタイムアウトし「ベストジャッジで進めよ」となるため、不在時に確認プロセスが実質スキップされる。操作の重要度に応じた自走可否・待機の基準がガイドラインにない（要約。事象/原因/影響の詳細は起票元参照）。

## 検討状況

- 2026-07-05: Issue-0013 対策サイクルで再発。AskUserQuestion が約60秒でタイムアウトし、エージェントが可逆作業（feature ブランチ上の編集・template 同期・検証）を best judgment で進め、不可逆な master merge の手前で停止・報告する判断を実際に行った。実害はなかったが、自走可否・待機の基準が未定義である状態は継続（起票元: retrospectives/system/2026-07-05-plan-verification-consistency-check.md）

## 結論

（open）
