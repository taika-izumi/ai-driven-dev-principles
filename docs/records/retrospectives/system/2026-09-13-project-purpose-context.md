# Retrospective: プロジェクトの目的・方針の参照

- **Subject**: プロジェクト目的の正本を開始・再開・委譲で参照する機能
- **Branch**: codex/project-purpose-context（取り込み方式: マージコミット fa9e6f9）
- **Period**: 2026-09-12 ～ 2026-09-13
- **Plan**: docs/working/plans/2026-09-13-project-purpose-context.md
- **Spec**: docs/current/specs/2026-09-12-project-purpose-context/
- **Related ADRs**: ADR-0190
- **Facilitator**: メインエージェント（gpt-6-astra）

## 1. 達成サマリ

- 目的の正本取得・変更・引き継ぎ・委譲を既存スキルへ接続し、このプロジェクトの目的関数を正本へ整理した（5350b9f）。
- Sol/highの設計レビューはフル1回＋差分2回で実質的な収束。実装計画4タスクを完了し、限定比較8題×2条件とSol/high 1体の実装レビューを実施した。
- 0.1.29の配布物を作成・検証し、masterへ統合した（0dee366、fa9e6f9）。公開・利用環境への導入と、最初の3件の実運用評価は未実施。

## 2. 課題（対象システム固有）

新規起票なし。ユーザーは分割判定の件をworklogのみとし、その後2026-09-13に保留中の後処理（Issue-0118への進展追記・文書整理と振り返り保存）の実施を指示した。

開発フローのdelta型2件は中央worklogへ記録済みで、新規Issueにはしない。

- MakeAiInstructions-2026-09-12-01「設定除外時も実行保護を明示する」: CLI設定除外でWindowsのsandbox設定も外れ、4実行が資料取得不能になった。明示設定で解消。原記録は設計レビューR1。
- MakeAiInstructions-2026-09-13-01「分割判定で既存構成を数え落とす」: 既存4スキルへの契約変更を分割判定から落とし、レビュー後に仕様を3責務へ再構成。振り返り案での挙げ漏れも含めて記録済み。成果物の修正と再発防止の効果は区別する。

比較入力の不足は `docs/records/experiments/2026-09-13-project-purpose-validation.md` に評価の限界として保存済み。動作の全モデル保証・実運用評価の完了とは扱わない。追加の独立振り返りレビューは実施していない。

worklog照合: 計画4タスク、設計・計画の確定、Accepted昇格、統合の節目をbranch/masterのhandoffおよびgit履歴と照合した。上記2件の中央ストアへの実在を確認し、その他は既存手順内の作業として棄却済み。後処理の記録・文書分割にも新規deltaはなく追加記録なし。詳細の受け皿は各レビュー・実験記録と本振り返り。

## 3. 既存課題の再発・進展

Issue-0118に、目的の正本への到達を実装した部分進展を追記した。情報到達全体の網羅性・役割分担・規模への対応は未解決のためopenを維持。追記時の元ファイルは12,383バイトで目安を超えており、既存規約に従って課題本文・検討経緯ログ・LoopForAlpha#Issue-0169の時点資料へ整理した。過去の検討経緯と申し送り全文は分割前と一致することを確認。

一次記録: [Issue-0118](../../../working/issues/flow/0118-information-reachability-mechanism-undesigned/0118-information-reachability-mechanism-undesigned.md)、同フォルダの0118-log.md。後続ADR-0191の整備候補提示は別サイクル（09cf903）であり、その実装・振り返りと本記録を混同しない。
