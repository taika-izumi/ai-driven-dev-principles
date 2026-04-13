# AI Agent Meta-Guidelines

AIエージェントを活用したシステム開発のためのメタ・ガイドライン。

## 概要

このリポジトリは、AIエージェントとの協働開発において有用な普遍的原則（メタ・ガイドライン）と、それを GitHub Copilot で実践するための仕組みを提供する。

対象とする「システム」には、通常のソフトウェア（Webアプリ、API、CLIなど）だけでなく、AIエージェントによる情報収集・分析・意思決定を含むワークフロー型システムも含む。

## 構造

3層のレイヤード方式で構成される:

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| Layer 1 | [`docs/principles.md`](docs/principles.md) | ツール非依存のメタ・ガイドライン原則集 |
| Layer 2 | [`.github/copilot-instructions.md`](.github/copilot-instructions.md) | Copilot向け行動指示 |
| Layer 3 | [`skills/`](skills/) | ワークフローを実装するスキル群 |

## 5つの原則

1. **意思決定の追跡可能性** — 「なぜそうしたか」を記録する
2. **関心の分離** — エージェントを「万能な1人」ではなく「責務を持った専門家」として設計する
3. **コンテキストの明示的管理** — エージェントが「何を知っているか」を明示的に制御する
4. **重要局面での人間の関与** — 重要な判断や不可逆操作の前に人間の確認を挟む
5. **漸進的な検証** — 作業を小さく区切り、各ステップで正しさを確認する

詳細は [`docs/principles.md`](docs/principles.md) を参照。

## スキル

| スキル | 説明 |
|--------|------|
| [`decision-log`](skills/decision-log/) | 意思決定をADR（Architecture Decision Record）として記録・管理する |
| [`pre-action-review`](skills/pre-action-review/) | 不可逆操作前にリスク評価と確認を実施する |
| [`extend-guidelines`](skills/extend-guidelines/) | ガイドラインの拡張作業をガイドするゲートウェイ |

## 新しいプロジェクトでの使い方

1. `template/` フォルダの中身を新プロジェクトのルートにコピーする
2. `copilot-instructions.md` にプロジェクト固有の指示を追記する

## 成長サイクル

1. 実践で「こういうルールがあればよかった」と発見する
2. `extend-guidelines` スキルを実行し、拡張作業を開始する
3. スキルのガイドに従い、原則・行動指示・スキルを追加する

詳細な拡張ルールと判定基準は [`CONTRIBUTING.md`](CONTRIBUTING.md) を参照。
