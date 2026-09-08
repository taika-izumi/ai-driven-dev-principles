# 参照知識（reference）

プロジェクト固有の運用ノウハウ・既知の落とし穴を集める置き場（`docs/overview/folder-structure.md` の配置基準、ADR-0086 の種類別対応表に基づく）。handoff の申し送りが教訓型に膨らんだとき、独立手順「移設」（`skills/session-handoff/references/relocation-procedure.md`）でここへ正本を移す。

## 索引

| ドキュメント | 内容 |
|---|---|
| [inspection-isolation-costs.md](inspection-isolation-costs.md) | 検査の書き込み隔離と16GB環境の導入・実行負担。公式仕様とローカル確認、未実証事項（Issue-0136） |
| [ai-team-tooling.md](ai-team-tooling.md) | AI組織による開発に使う公式機能、独自に整備する範囲、導入前の確認事項（2026-09-08調査） |
| [codex-collaboration-mode-question-format.md](codex-collaboration-mode-question-format.md) | Codexのモード指示と選択肢提示が競合する場合の設定・確認・復元手順（Issue-0127） |
| [powershell-pitfalls.md](powershell-pitfalls.md) | シェル・PowerShell / .NET API の実測済みの落とし穴集（検索・集計・追記・作業ディレクトリ。`grep` の否定先読みと計数方式を含む。出所: Issue-0119） |
